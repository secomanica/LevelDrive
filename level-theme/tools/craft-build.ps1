# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Roda etapas do Craft sobre ESTE repositório (tema Level já aplicado com apply-theme.ps1).
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage configure
#   etapas: configure | compile | install | qmerge | package | all
#     all = configure + compile + install + qmerge (sem package)
# -BuildType: tipo de build do nextcloud-client (as dependências continuam do cache binário RelWithDebInfo).
# Pré-requisito: level-theme\tools\craft-bootstrap.ps1 já rodado (C:\CraftRoot).
[CmdletBinding()]
param(
    # texto separado por vírgula (ex.: "configure,compile"): com powershell -File um array chega como uma string só
    [string]$Stage = 'configure',
    [ValidateSet('Release','RelWithDebInfo','Debug')][string]$BuildType = 'Release',
    [string]$Root = 'C:\CraftRoot',
    [string]$Target = 'windows-msvc2022_64-cl'
)
$ErrorActionPreference = 'Continue'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$override = Join-Path $repo 'level-theme\craft\level-overrides.ini'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
# WIX: exigido por admin/win/tools/NCMsiHelper (BUILD_WIN_MSI=ON); relê do sistema porque sessões abertas
# antes da instalação do WiX não herdam a variável
if (-not $env:WIX) { $env:WIX = [Environment]::GetEnvironmentVariable('WIX','Machine') }
if (-not $env:WIX) { throw 'Variável WIX não definida: instale o WiX Toolset 3.14.' }
# vcvarsall.bat precisa do vswhere.exe no PATH (senão o Craft quebra com JSONDecodeError)
$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;" + $env:Path

$stages = @($Stage -split '[,\s]+' | Where-Object { $_ })
foreach ($s in $stages) {
    if ($s -notin @('configure','compile','install','qmerge','package','all')) { throw "Etapa inválida: $s" }
}
# um valor por --options (o Craft trata o 2º valor solto como nome de pacote)
$options = @('--options', "nextcloud-client.srcDir=$repo", '--options', "nextcloud-client.buildType=$BuildType")
foreach ($s in $stages) {
    # @(...) obrigatório: sem ele um único valor vira string e o splatting a quebra em caracteres
    $stageArgs = @(switch ($s) {
        'configure' { '--configure' }
        'compile'   { '--compile' }
        'install'   { '--install' }
        'qmerge'    { '--qmerge' }
        'package'   { '--package' }
        'all'       { }   # sem etapa = até qmerge (fetch/unpack pulados porque srcDir aponta para cá)
    })
    # Bug do blueprint externo craft-blueprints-nextcloud (stable-35.0): nextcloud-client.py usa os.path em
    # createPackage() sem "import os" (NameError). Corrigido só durante o package e desfeito depois
    # (o blueprint é um checkout git; não deixamos alteração local que bloqueie atualizações).
    $bp = "$Root\$Target\etc\blueprints\locations\craft-blueprints-nextcloud\nextcloud-client\nextcloud-client.py"
    $bpPatched = $false
    if ($s -eq 'package' -and (Test-Path $bp)) {
        $bpText = [IO.File]::ReadAllText($bp)
        if ($bpText -notmatch '(?m)^import os\s*$') {
            [IO.File]::WriteAllText($bp, ($bpText -replace '(?m)^import info\r?$', "import info`r`nimport os"))
            $bpPatched = $true
            Write-Host '   (blueprint nextcloud-client.py: "import os" adicionado temporariamente)'
        }
    }
    Write-Host "== craft $s nextcloud-client ($BuildType, src: $repo)"
    python "$Root\CraftMaster\CraftMaster.py" --config "$Root\craftmaster.ini" --config-override $override --target $Target -c @options @stageArgs nextcloud-client
    $rc = $LASTEXITCODE
    if ($bpPatched) {
        & git -C (Split-Path $bp) checkout -- (Split-Path $bp -Leaf)
        Write-Host '   (blueprint restaurado)'
    }
    Write-Host "== craft $s terminou com código $rc"
    if ($rc -ne 0) { exit $rc }
}
exit 0

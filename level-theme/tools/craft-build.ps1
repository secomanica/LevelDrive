# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Roda uma etapa do Craft sobre ESTE repositório (tema Level já aplicado com apply-theme.ps1).
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\craft-build.ps1 -Stage configure
#   etapas: configure | compile | install | all
# Pré-requisito: level-theme\tools\craft-bootstrap.ps1 já rodado (C:\CraftRoot).
[CmdletBinding()]
param(
    [ValidateSet('configure','compile','install','all')][string]$Stage = 'configure',
    [string]$Root = 'C:\CraftRoot',
    [string]$Target = 'windows-msvc2022_64-cl'
)
$ErrorActionPreference = 'Continue'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
# WIX: exigido por admin/win/tools/NCMsiHelper (BUILD_WIN_MSI=ON); relê do sistema porque sessões abertas
# antes da instalação do WiX não herdam a variável
if (-not $env:WIX) { $env:WIX = [Environment]::GetEnvironmentVariable('WIX','Machine') }
if (-not $env:WIX) { throw 'Variável WIX não definida: instale o WiX Toolset 3.14.' }
# vcvarsall.bat precisa do vswhere.exe no PATH (senão o Craft quebra com JSONDecodeError)
$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;" + $env:Path

# @(...) obrigatório: sem ele o switch devolve uma string e o splatting a quebra em caracteres
$stageArgs = @(switch ($Stage) {
    'configure' { '--configure' }
    'compile'   { '--compile' }
    'install'   { '--install' }
    'all'       { }   # sem etapa = configure+compile+install (fetch/unpack pulados porque srcDir aponta para cá)
})
Write-Host "== craft $Stage nextcloud-client (src: $repo)"
# srcDir via --options (o --src-dir está obsoleto no Craft)
python "$Root\CraftMaster\CraftMaster.py" --config "$Root\craftmaster.ini" --target $Target -c --options "nextcloud-client.srcDir=$repo" @stageArgs nextcloud-client
$rc = $LASTEXITCODE
Write-Host "== craft terminou com código $rc"
exit $rc

# Bootstrap do KDE Craft para o build do cliente desktop (reproduz .github/workflows/windows-build-and-test.yml)
# Uso: powershell -ExecutionPolicy Bypass -File C:\CraftRoot\craft-bootstrap.ps1 [-SrcIni C:\suporte\level-desktop\craftmaster.ini]
param(
    [string]$SrcIni = 'C:\suporte\level-desktop\craftmaster.ini',
    [string]$Root = 'C:\CraftRoot',
    [string]$Target = 'windows-msvc2022_64-cl'
)
$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
# Armadilha: o vcvarsall.bat chama vswhere.exe e, se ele nao estiver no PATH, imprime erro que quebra o parse JSON do Craft
$env:Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;" + $env:Path
Set-Location $Root
Copy-Item $SrcIni "$Root\craftmaster.ini" -Force

function Get-IniValue($key) {
    $m = Select-String -Path "$Root\craftmaster.ini" -Pattern ("^\s*" + [regex]::Escape($key) + "\s*=\s*(.+?)\s*$")
    $m.Matches[0].Groups[1].Value
}
$kdeRef = Get-IniValue 'craft/craft-blueprints-kde.revision'
$ncRef  = Get-IniValue 'craft/craft-blueprints-nextcloud.revision'

if (-not (Test-Path "$Root\CraftMaster")) {
    git clone -q --depth=1 https://github.com/KDE/craftmaster.git "$Root\CraftMaster"
}
function craft { python "$Root\CraftMaster\CraftMaster.py" --config "$Root\craftmaster.ini" --target $Target -c @args; if ($LASTEXITCODE -ne 0) { throw "craft $args falhou ($LASTEXITCODE)" } }

craft --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-kde.git|$kdeRef|"
craft --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-nextcloud.git|$ncRef|"
craft craft
craft --install-deps nextcloud-client
"BOOTSTRAP OK $(Get-Date -Format s)"

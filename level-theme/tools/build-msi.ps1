# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Gera o instalador MSI do Level Drive a partir do pacote do Craft.
#
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\build-msi.ps1 [-Sign]
#
# Pré-requisitos (ver CLAUDE.md):
#   apply-theme.ps1  e  craft-build.ps1 -Stage "configure,compile,install,qmerge,package" -BuildType Release
#
# O que faz:
#   1. monta a pasta do aplicativo (HarvestAppDir) no layout plano que o Nextcloud.wxs espera
#      (executável na raiz de INSTALLDIR), a partir de <Craft>\build\nextcloud-client\archive:
#        archive\bin\*                    -> raiz (DLLs, plugins Qt, módulos QML, runtime MSVC app-local)
#        leveldrive.exe, leveldrivecmd.exe -> raiz (o blacklist do blueprint upstream remove todo .exe
#                                            que não comece com "nextcloud"; copiados do CraftRoot\bin)
#        archive\i18n\*.qm + qtkeychain_*  -> i18n\   (Application::translationPath() no Windows)
#        traduções do Qt em pt-BR          -> i18n\   (o blacklist remove translations/; fallback em
#                                            application.cpp:1314-1316)
#        config\<ShortName>\sync-exclude.lst -> raiz  (configfile.cpp:418)
#        etc\ssl\openssl.cnf               -> raiz    (application.cpp:244)
#        <IconName>.ico                     -> raiz    (Nextcloud.wxs:97, sem regra de install no CMake)
#   2. (opcional, -Sign) assina os binários da Level ANTES de empacotar (sign-level.ps1);
#   3. roda o make-msi.bat do upstream (heat/candle/light + transforms de idioma, incl. pt-BR — patch 0011);
#   4. (opcional, -Sign) assina o .msi;
#   5. copia o MSI para level-theme\build\out e imprime o SHA-256.
[CmdletBinding()]
param(
    [string]$CraftRoot = 'C:\CraftRoot\windows-msvc2022_64-cl',
    [string]$IconName = 'LevelDrive',     # APPLICATION_ICON_NAME
    [string]$ShortName = 'LevelDrive',    # APPLICATION_SHORTNAME
    [string]$Exe = 'leveldrive',          # APPLICATION_EXECUTABLE
    [switch]$Sign
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$work = Join-Path $repo 'level-theme\build\msi'
$app = Join-Path $work 'app'
$msiw = Join-Path $work 'msi'
$out = Join-Path $repo 'level-theme\build\out'
$archive = Join-Path $CraftRoot 'build\nextcloud-client\archive'

function Step($m) { Write-Host "`n== $m" }
function Copy-Tree($from, $to) {
    New-Item -ItemType Directory -Force $to | Out-Null
    & robocopy $from $to /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy falhou ($LASTEXITCODE): $from" }
}

# ---------------------------------------------------------------- verificações
foreach ($p in @("$archive\bin", "$archive\msi\make-msi.bat", "$CraftRoot\bin\$Exe.exe", "$CraftRoot\bin\${Exe}cmd.exe")) {
    if (-not (Test-Path $p)) { throw "Não encontrado: $p (rode craft-build.ps1 até a etapa package)" }
}
if (-not (Test-Path "$archive\msi\level-strings.pt-br.wxl")) { throw 'msi\ sem os .wxl da Level: o patch 0011 não estava aplicado no build.' }
$ico = Get-ChildItem 'C:\_' -Recurse -Filter "$IconName.ico" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like '*\src\gui\*' } | Sort-Object LastWriteTime | Select-Object -Last 1
if (-not $ico) { throw "$IconName.ico não encontrado no diretório de build do Craft (C:\_\...\build\src\gui)." }

$env:WIX = if ($env:WIX) { $env:WIX } else { [Environment]::GetEnvironmentVariable('WIX', 'Machine') }
$sdk = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'x64\wisubstg.vbs') } | Sort-Object { [version]$_.Name } | Select-Object -Last 1
if (-not $env:WIX -or -not $sdk) { throw 'WiX (variável WIX) ou Windows SDK (wisubstg.vbs/wilangid.vbs/uuidgen) não encontrados.' }
$sdkBin = Join-Path $sdk.FullName 'x64'
$env:WISUBSTG = Join-Path $sdkBin 'wisubstg.vbs'
$env:WILANGID = Join-Path $sdkBin 'wilangid.vbs'
$env:Path = "$sdkBin;" + $env:Path   # uuidgen.exe

# ---------------------------------------------------------------- 1. HarvestAppDir
Step "Montando a pasta do aplicativo em $app"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
Copy-Tree "$archive\bin" $app
Copy-Item "$CraftRoot\bin\$Exe.exe", "$CraftRoot\bin\${Exe}cmd.exe" $app
Copy-Tree "$archive\i18n" "$app\i18n"
Get-ChildItem "$archive\share\qt6keychain" -Recurse -Filter '*.qm' -ErrorAction SilentlyContinue | Copy-Item -Destination "$app\i18n"
foreach ($q in 'qt_pt_BR.qm', 'qtbase_pt_BR.qm', 'qtdeclarative_pt_BR.qm') {
    if (Test-Path "$CraftRoot\translations\$q") { Copy-Item "$CraftRoot\translations\$q" "$app\i18n" }
}
Copy-Item "$archive\config\$ShortName\sync-exclude.lst" $app
Copy-Item "$archive\etc\ssl\openssl.cnf" $app
Copy-Item $ico.FullName $app
$n = (Get-ChildItem $app -Recurse -File).Count
Write-Host "   $n arquivos; exe: $((Get-Item "$app\$Exe.exe").VersionInfo.ProductName) $((Get-Item "$app\$Exe.exe").VersionInfo.ProductVersion)"

# ---------------------------------------------------------------- 2. assinatura dos binários
if ($Sign) {
    Step 'Assinando binários da Level'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sign-level.ps1') -Path $app, "$archive\msi\NCMsiHelper64.dll"
    if ($LASTEXITCODE -ne 0) { throw 'Assinatura dos binários falhou.' }
}

# ---------------------------------------------------------------- 3. MSI
Step 'Gerando o MSI (make-msi.bat do upstream)'
Copy-Tree "$archive\msi" $msiw
# Start-Process com WorkingDirectory: Push-Location não muda o diretório do processo filho, e com
# ErrorActionPreference=Stop o stderr do WiX viraria erro fatal. A saída vai para make-msi.log.
$log = Join-Path $work 'make-msi.log'
# wrapper .cmd: evita as regras de aspas do "cmd /c" quando o caminho é passado via Start-Process.
# Caminhos COMPLETOS: com NoDefaultCurrentDirectoryInExePath=1 (definido em alguns ambientes) o cmd não
# executa nada da pasta atual pelo nome.
$runner = Join-Path $msiw 'run-make-msi.cmd'
[IO.File]::WriteAllText($runner, "@call `"%~dp0make-msi.bat`" `"$app`"`r`n@exit /b %ERRORLEVEL%`r`n", [Text.Encoding]::ASCII)
$proc = Start-Process cmd.exe -ArgumentList '/c', "`"$runner`"" -WorkingDirectory $msiw -NoNewWindow -Wait -PassThru `
    -RedirectStandardOutput $log -RedirectStandardError "$log.err"
Get-Content $log | Where-Object { $_ -match '^::' } | ForEach-Object { "   $_" }
if ($proc.ExitCode -ne 0) {
    Get-Content $log, "$log.err" -Tail 30 | ForEach-Object { "   $_" }
    throw "make-msi.bat falhou ($($proc.ExitCode)); ver $log"
}
# O make-msi.bat do upstream NÃO interrompe em erro dentro dos laços (%ERRORLEVEL% é expandido antes da
# execução) e termina com "Done" mesmo com idiomas faltando. Por isso conferimos o log.
$wixErrors = @(Get-Content $log, "$log.err" | Select-String -Pattern '(LGHT|CNDL|HEAT|TRCH)\d+|Msi API Error|error [A-Z]+\d+')
if ($wixErrors.Count) {
    $wixErrors | Select-Object -First 15 | ForEach-Object { "   $($_.Line)" }
    throw "WiX reportou $($wixErrors.Count) erro(s); ver $log"
}
$msi = Get-ChildItem $msiw -Filter "$ShortName-*.msi" | Where-Object { $_.Name -notmatch '^[a-z]{2}-[a-z]{2}_' } | Select-Object -First 1
if (-not $msi) { throw 'MSI não gerado.' }

# ---------------------------------------------------------------- 4. assinatura do MSI
if ($Sign) {
    Step 'Assinando o MSI'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sign-level.ps1') -Path $msi.FullName
    if ($LASTEXITCODE -ne 0) { throw 'Assinatura do MSI falhou.' }
}

# ---------------------------------------------------------------- 5. saída
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item $msi.FullName $out -Force
$final = Join-Path $out $msi.Name
Step 'Pronto'
Write-Host "   $final"
Write-Host ("   {0:N1} MB  SHA-256 {1}" -f ((Get-Item $final).Length / 1MB), (Get-FileHash $final -Algorithm SHA256).Hash)
if (-not $Sign) { Write-Host '   (NÃO assinado: use -Sign quando o certificado da Level estiver configurado em sign-level.ps1)' }

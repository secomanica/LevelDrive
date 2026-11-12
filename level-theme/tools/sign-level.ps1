# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Assinatura de código Authenticode do Level Drive (PREPARADO — ainda NÃO executado: falta o certificado).
#
# Uso (chamado por build-msi.ps1 -Sign, ou manualmente):
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\sign-level.ps1 -Path <arquivo-ou-pasta> [...]
#
# Ordem correta no build:
#   1. assinar os binários da Level na pasta do app (leveldrive.exe, leveldrivecmd.exe, leveldrive*.dll,
#      NC*.dll, CfApiShellExtensions.dll, NCMsiHelper64.dll) ANTES do heat/candle/light;
#   2. gerar o MSI;
#   3. assinar o .msi.
# DLLs de terceiros (Qt, OpenSSL…) já vêm assinadas pelos fornecedores ou não precisam; por padrão só os
# binários listados em $LevelBinaryPatterns são assinados.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Path,
    # Certificado: arquivo .pfx OU impressão digital de um certificado no repositório do Windows / token HSM
    [string]$CertificateFile = '<<PREENCHER: caminho do certificado .pfx da Level (ou deixe vazio e use -Thumbprint)>>',
    [string]$Thumbprint = '',
    # A senha NÃO deve ficar no repositório: use a variável de ambiente LEVEL_SIGN_PASSWORD (CI/cofre de segredos)
    [string]$TimestampUrl = '<<PREENCHER: URL do servidor de carimbo de tempo RFC 3161 da autoridade certificadora>>',
    [string]$Description = 'Level Drive',
    [string]$DescriptionUrl = '<<PREENCHER: site/suporte da Level>>'
)
$ErrorActionPreference = 'Stop'
$LevelBinaryPatterns = @('leveldrive*.exe', 'leveldrive*.dll', 'NC*.dll', 'CfApiShellExtensions.dll', '*.msi')

foreach ($v in @($TimestampUrl, $DescriptionUrl) + $(if (-not $Thumbprint) { @($CertificateFile) } else { @() })) {
    if ($v -like '*<<PREENCHER*') { throw "Assinatura não configurada: $v" }
}

$sdkBin = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'x64\signtool.exe') } |
    Sort-Object { [version]$_.Name } | Select-Object -Last 1
if (-not $sdkBin) { throw 'signtool.exe não encontrado (Windows SDK).' }
$signtool = Join-Path $sdkBin.FullName 'x64\signtool.exe'

$certArgs = if ($Thumbprint) { @('/sha1', $Thumbprint) } else {
    if (-not $env:LEVEL_SIGN_PASSWORD) { throw 'Defina LEVEL_SIGN_PASSWORD com a senha do .pfx.' }
    @('/f', $CertificateFile, '/p', $env:LEVEL_SIGN_PASSWORD)
}

$files = foreach ($p in $Path) {
    if (Test-Path $p -PathType Container) {
        Get-ChildItem $p -Recurse -File -Include $LevelBinaryPatterns
    } else { Get-Item $p }
}
foreach ($f in $files) {
    Write-Host "Assinando $($f.FullName)"
    & $signtool sign /fd sha256 /tr $TimestampUrl /td sha256 /d $Description /du $DescriptionUrl @certArgs $f.FullName
    if ($LASTEXITCODE -ne 0) { throw "signtool falhou em $($f.Name)" }
    & $signtool verify /pa /q $f.FullName
    if ($LASTEXITCODE -ne 0) { throw "Verificação da assinatura falhou em $($f.Name)" }
}
Write-Host "OK: $(@($files).Count) arquivo(s) assinados."

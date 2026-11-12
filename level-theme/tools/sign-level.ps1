# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Assinatura de código Authenticode do Level Drive (PREPARADO — ainda NÃO executado: falta configurar o certificado).
#
# Uso (chamado por build-msi.ps1 -Sign, ou manualmente):
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\sign-level.ps1 -Path <arquivo-ou-pasta> [...]
#
# O que é assinado (igual ao Nextcloud oficial, que assina os 129 .exe/.dll do seu pacote):
#   1. ANTES do heat/candle/light: TODOS os .exe/.dll da pasta do app que ainda não têm assinatura válida
#      (binários Level, Qt, OpenSSL, KDE, plugins…) e a NCMsiHelper64.dll (ação personalizada embutida no MSI).
#      Os que já vêm assinados (ex.: runtime do Visual C++, assinado pela Microsoft) são mantidos como estão.
#   2. gera o MSI;
#   3. assina o .msi (depois dos transforms de idioma embutidos; qualquer alteração posterior invalida a assinatura).
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Path,
    # Certificado: arquivo .pfx OU impressão digital (thumbprint) de um certificado no repositório do Windows,
    # que é o caso de token USB/HSM (a chave fica no token; o signtool usa o CSP/KSP do fabricante).
    [string]$CertificateFile = '<<PREENCHER: caminho do certificado .pfx da Level (ou deixe vazio e use -Thumbprint)>>',
    [string]$Thumbprint = '',
    # A senha NÃO deve ficar no repositório: use a variável de ambiente LEVEL_SIGN_PASSWORD (CI/cofre de segredos)
    [string]$TimestampUrl = '<<PREENCHER: URL do servidor de carimbo de tempo RFC 3161 da autoridade certificadora>>',
    [string]$Description = 'Level Drive',
    [string]$DescriptionUrl = 'https://leveltecnologia.com.br/'
)
$ErrorActionPreference = 'Stop'

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

$candidates = foreach ($p in $Path) {
    if (Test-Path $p -PathType Container) {
        Get-ChildItem $p -Recurse -File -Include '*.exe', '*.dll', '*.msi'
    } else { Get-Item $p }
}
# mantém o que já tem assinatura válida de terceiros (ex.: Microsoft); assina o resto
$files = @($candidates | Where-Object { (Get-AuthenticodeSignature $_.FullName).Status -ne 'Valid' })
$kept = @($candidates).Count - $files.Count
Write-Host "Para assinar: $($files.Count) arquivo(s); já assinados por terceiros (mantidos): $kept"
if ($files.Count -eq 0) { return }

# signtool aceita vários arquivos por chamada; lotes evitam linha de comando longa demais
# (e, com token USB, reduzem os pedidos de PIN)
$batchSize = 50
for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
    $batch = @($files[$i..([Math]::Min($i + $batchSize, $files.Count) - 1)] | ForEach-Object FullName)
    Write-Host "Assinando lote $([int]($i / $batchSize) + 1): $($batch.Count) arquivo(s)"
    & $signtool sign /fd sha256 /tr $TimestampUrl /td sha256 /d $Description /du $DescriptionUrl @certArgs @batch
    if ($LASTEXITCODE -ne 0) { throw "signtool falhou no lote que começa em $($batch[0])" }
    & $signtool verify /pa /q @batch
    if ($LASTEXITCODE -ne 0) { throw "Verificação da assinatura falhou no lote que começa em $($batch[0])" }
}
Write-Host "OK: $($files.Count) arquivo(s) assinados."

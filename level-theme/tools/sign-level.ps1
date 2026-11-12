# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Assinatura de código Authenticode do Level Drive — certificado SSL.com eSigner (nuvem) via eSigner CKA.
#
# Uso (chamado por build-msi.ps1 -Sign, ou manualmente):
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\sign-level.ps1 -Path <arquivo-ou-pasta> [...] [-Scope All|Level]
#
# Pré-requisito (uma vez por máquina): eSigner CKA (Cloud Key Adapter) da SSL.com instalado e logado.
#   Ele expõe o certificado de nuvem no repositório "Pessoal" do usuário; o signtool o usa pela impressão digital.
#   Para builds sem interação, configure o CKA em modo "Automated" (usuário, senha e segredo TOTP do eSigner).
# Configuração (fora do repositório):
#   LEVEL_SIGN_THUMBPRINT   impressão digital (SHA-1) do certificado de assinatura de código da Level
#
# O que é assinado:
#   -Scope All (padrão; igual ao Nextcloud oficial, que assina todos os .exe/.dll do pacote):
#      todos os .exe/.dll ainda sem assinatura válida (Level, Qt, OpenSSL, KDE, plugins…) ≈ 215 arquivos por build.
#   -Scope Level: só os binários da Level (leveldrive*.exe/.dll, NC*.dll, CfApiShellExtensions.dll, NCMsiHelper64.dll)
#      ≈ 15 arquivos — use se o plano do eSigner tiver cota de assinaturas.
#   O .msi é sempre assinado (passado explicitamente pelo build-msi.ps1, depois dos transforms de idioma).
#   Arquivos que já têm assinatura válida de terceiros (ex.: runtime VC++ da Microsoft) são mantidos.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Path,
    [ValidateSet('All', 'Level')][string]$Scope = 'All',
    [string]$Thumbprint = $env:LEVEL_SIGN_THUMBPRINT,
    [string]$TimestampUrl = 'http://ts.ssl.com',          # servidor RFC 3161 da SSL.com
    [string]$Description = 'Level Drive',
    [string]$DescriptionUrl = 'https://leveltecnologia.com.br/'
)
$ErrorActionPreference = 'Stop'

if (-not $Thumbprint) {
    throw 'Defina LEVEL_SIGN_THUMBPRINT com a impressão digital do certificado (ver CLAUDE.md, "Assinatura").'
}
$Thumbprint = ($Thumbprint -replace '[^0-9A-Fa-f]', '').ToUpper()
$cert = Get-ChildItem Cert:\CurrentUser\My, Cert:\LocalMachine\My | Where-Object Thumbprint -eq $Thumbprint | Select-Object -First 1
if (-not $cert) {
    throw "Certificado $Thumbprint não encontrado no repositório do Windows. O eSigner CKA está aberto e logado?"
}
if (-not ($cert.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.3')) {
    throw "O certificado $($cert.Subject) não é de assinatura de código."
}
Write-Host "Certificado: $($cert.Subject)  (válido até $($cert.NotAfter.ToString('yyyy-MM-dd')))"

$sdkBin = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'x64\signtool.exe') } |
    Sort-Object { [version]$_.Name } | Select-Object -Last 1
if (-not $sdkBin) { throw 'signtool.exe não encontrado (Windows SDK).' }
$signtool = Join-Path $sdkBin.FullName 'x64\signtool.exe'

$levelPatterns = @('leveldrive*.exe', 'leveldrive*.dll', 'NC*.dll', 'CfApiShellExtensions.dll', 'NCMsiHelper*.dll', '*.msi')
$candidates = foreach ($p in $Path) {
    if (Test-Path $p -PathType Container) {
        $include = if ($Scope -eq 'Level') { $levelPatterns } else { @('*.exe', '*.dll', '*.msi') }
        Get-ChildItem $p -Recurse -File -Include $include
    } else { Get-Item $p }   # arquivo passado explicitamente (ex.: o .msi) é sempre assinado
}
$files = @($candidates | Where-Object { (Get-AuthenticodeSignature $_.FullName).Status -ne 'Valid' })
$kept = @($candidates).Count - $files.Count
Write-Host "Escopo $Scope. Para assinar: $($files.Count) arquivo(s); já assinados por terceiros (mantidos): $kept"
if ($files.Count -eq 0) { return }

# vários arquivos por chamada do signtool (menos sessões com o eSigner); lotes evitam linha de comando longa demais
$batchSize = 50
for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
    $batch = @($files[$i..([Math]::Min($i + $batchSize, $files.Count) - 1)] | ForEach-Object FullName)
    Write-Host "Assinando lote $([int]($i / $batchSize) + 1): $($batch.Count) arquivo(s)"
    & $signtool sign /fd sha256 /tr $TimestampUrl /td sha256 /d $Description /du $DescriptionUrl /sha1 $Thumbprint @batch
    if ($LASTEXITCODE -ne 0) { throw "signtool falhou no lote que começa em $($batch[0])" }
    & $signtool verify /pa /q @batch
    if ($LASTEXITCODE -ne 0) { throw "Verificação da assinatura falhou no lote que começa em $($batch[0])" }
}
Write-Host "OK: $($files.Count) arquivo(s) assinados."

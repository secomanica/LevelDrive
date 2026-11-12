# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Aplica o tema Level Drive sobre a árvore upstream do Nextcloud Desktop.
#
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1          # aplica
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Check   # só verifica se aplicaria
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\apply-theme.ps1 -Revert  # volta a árvore upstream
#
# O que faz (nesta ordem):
#   1. copia level-theme\NEXTCLOUD.cmake sobre o NEXTCLOUD.cmake upstream;
#   2. aplica level-theme\patches\*.patch (ordem numérica) com git apply;
#   3. copia level-theme\overlay\** para a raiz do repositório (mesma estrutura de pastas).
# É idempotente: patches já aplicados são pulados.
# Os arquivos upstream alterados NÃO devem ser commitados na branch: o tema vive só em level-theme\.
[CmdletBinding()]
param(
    [switch]$Revert,
    [switch]$Check
)
# 'Continue' de propósito: no PowerShell 5.1, com 'Stop', qualquer saída do git no stderr vira erro fatal
# (mesmo com 2>$null). Cada chamada nativa confere $LASTEXITCODE e lança erro explicitamente.
$ErrorActionPreference = 'Continue'
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$theme = Join-Path $repo 'level-theme'
$patches = @(Get-ChildItem (Join-Path $theme 'patches') -Filter '*.patch' -ErrorAction SilentlyContinue | Sort-Object Name)
$overlayDir = Join-Path $theme 'overlay'
$overlayFiles = @()
if (Test-Path $overlayDir) {
    $overlayFiles = @(Get-ChildItem $overlayDir -Recurse -File | ForEach-Object {
        $_.FullName.Substring($overlayDir.Length + 1)
    })
}

function Test-PatchApplied($patch) {
    # aplicado = o reverso aplica limpo
    & git -C $repo apply --reverse --check $patch.FullName 2>$null
    return ($LASTEXITCODE -eq 0)
}

if ($Revert) {
    Write-Host '== Revertendo tema Level (voltando para upstream)'
    # arquivos tocados pelos patches
    $touched = @('NEXTCLOUD.cmake')
    foreach ($p in $patches) {
        $touched += (& git -C $repo apply --numstat $p.FullName | ForEach-Object { ($_ -split "`t")[2] })
    }
    # arquivos do overlay: os rastreados voltam ao upstream; os novos são apagados
    foreach ($rel in $overlayFiles) {
        $relGit = $rel -replace '\\','/'
        & git -C $repo ls-files --error-unmatch -- $relGit *> $null
        if ($LASTEXITCODE -eq 0) { $touched += $relGit }
        else {
            $target = Join-Path $repo $rel
            if (Test-Path $target) { Remove-Item $target -Force; Write-Host "  removido $relGit" }
        }
    }
    $touched = $touched | Sort-Object -Unique
    & git -C $repo checkout -- @touched
    if ($LASTEXITCODE -ne 0) { throw 'git checkout falhou' }
    $touched | ForEach-Object { Write-Host "  restaurado $_" }
    Write-Host 'OK: árvore upstream restaurada.'
    return
}

$mode = if ($Check) { 'Verificando' } else { 'Aplicando' }
Write-Host "== $mode tema Level em $repo"

# 1. NEXTCLOUD.cmake
$src = Join-Path $theme 'NEXTCLOUD.cmake'
if (-not $Check) { Copy-Item $src (Join-Path $repo 'NEXTCLOUD.cmake') -Force }
Write-Host '  [cmake]   NEXTCLOUD.cmake <- level-theme\NEXTCLOUD.cmake'

# 2. patches
foreach ($p in $patches) {
    if (Test-PatchApplied $p) { Write-Host "  [patch]   $($p.Name): já aplicado"; continue }
    & git -C $repo apply --check $p.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Patch $($p.Name) NÃO aplica nesta versão do upstream. Atualize o patch (ver LEVEL-BRANDING.md)."
    }
    if (-not $Check) {
        & git -C $repo apply $p.FullName
        if ($LASTEXITCODE -ne 0) { throw "git apply $($p.Name) falhou" }
    }
    Write-Host "  [patch]   $($p.Name): $(if ($Check) { 'aplica' } else { 'aplicado' })"
}

# 3. overlay
foreach ($rel in $overlayFiles) {
    $target = Join-Path $repo $rel
    if (-not $Check) {
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        Copy-Item (Join-Path $overlayDir $rel) $target -Force
    }
}
Write-Host "  [overlay] $($overlayFiles.Count) arquivo(s)"

Write-Host "OK: tema Level $(if ($Check) { 'aplicável' } else { 'aplicado' })."

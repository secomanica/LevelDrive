# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Gera todos os ícones e imagens do Level Drive a partir dos SVGs oficiais em ..\level-brand\
# e grava o resultado em level-theme\overlay\ (copiado para a árvore upstream por apply-theme.ps1).
#
#   powershell -ExecutionPolicy Bypass -File level-theme\tools\build-icons.ps1 [-BrandDir C:\suporte\level-brand]
#
# Regras (manual da marca):
#  - os SVGs originais nunca são editados; os <path> são copiados VERBATIM (mesmas cores) e só posicionados
#    com transform (translate/scale uniforme). Nada é recolorido nem redesenhado;
#  - "-cor" sobre fundo claro, "-cor-negativo" sobre fundo escuro (#103B40 / #222323);
#  - respiro ao redor da marca.
# Saída compatível com o renderizador SVG do Qt (SVG Tiny 1.2): só <path>, <rect>, <circle>, <g transform>.
# Requer: Inkscape 1.x (PNG) e ImageMagick 7 (BMP do MSI).
[CmdletBinding()]
param(
    [string]$BrandDir
)
$ErrorActionPreference = 'Continue'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $BrandDir) { $BrandDir = Join-Path (Split-Path $repo) 'level-brand' }
$out = Join-Path $repo 'level-theme\overlay'
$work = Join-Path $repo 'level-theme\build'   # intermediários (ignorado pelo git)
$inv = [Globalization.CultureInfo]::InvariantCulture

$inkscape = @('C:\Program Files\Inkscape\bin\inkscape.com', 'inkscape.com', 'inkscape') |
    Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
$magick = (Get-Command magick -ErrorAction SilentlyContinue).Source
if (-not $inkscape) { throw 'Inkscape não encontrado.' }
if (-not $magick) { throw 'ImageMagick (magick) não encontrado.' }

# ---------------------------------------------------------------- 1. conferir originais
$sourceMd = Join-Path $BrandDir 'SOURCE.md'
if (-not (Test-Path $sourceMd)) { throw "SOURCE.md não encontrado em $BrandDir" }
$expected = @{}
Get-Content $sourceMd -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\|\s*(\S+\.(svg|pdf))\s*\|\s*([0-9a-f]{64})\s*\|') { $expected[$Matches[1]] = $Matches[3] }
}
foreach ($f in $expected.Keys) {
    $h = (Get-FileHash (Join-Path $BrandDir $f) -Algorithm SHA256).Hash.ToLower()
    if ($h -ne $expected[$f]) { throw "Hash diferente do SOURCE.md: $f. O original foi alterado; abortando." }
}
Write-Host "Originais conferidos: $($expected.Count) arquivos batem com SOURCE.md"

# ---------------------------------------------------------------- 2. helpers
function F([double]$n) { $n.ToString('0.####', $inv) }

function Read-Logo([string]$file) {
    [xml]$x = Get-Content (Join-Path $BrandDir $file) -Raw -Encoding UTF8
    $vb = $x.svg.viewBox -split '\s+' | ForEach-Object { [double]::Parse($_, $inv) }
    $paths = foreach ($p in $x.svg.ChildNodes) {
        if ($p.LocalName -ne 'path') { continue }
        # copia literal de fill e d (únicos atributos dos originais)
        '<path fill="{0}" d="{1}"/>' -f $p.GetAttribute('fill'), $p.GetAttribute('d').Trim()
    }
    [pscustomobject]@{ File = $file; X = $vb[0]; Y = $vb[1]; W = $vb[2]; H = $vb[3]; Paths = ($paths -join "`n") }
}

# Posiciona o logo dentro da caixa (bx,by,bw,bh) mantendo proporção, alinhado pelo centro (ou como pedido)
function Place($logo, [double]$bx, [double]$by, [double]$bw, [double]$bh, [string]$align = 'center') {
    $s = [Math]::Min($bw / $logo.W, $bh / $logo.H)
    $w = $logo.W * $s; $h = $logo.H * $s
    $tx = switch ($align) { 'right' { $bx + $bw - $w } 'left' { $bx } default { $bx + ($bw - $w) / 2 } }
    $ty = $by + ($bh - $h) / 2
    "<g transform=`"translate($(F $tx) $(F $ty)) scale($(F $s)) translate($(F (-$logo.X)) $(F (-$logo.Y)))`">`n$($logo.Paths)`n</g>"
}

function Svg([double]$w, [double]$h, [string]$body, [string]$title) {
@"
<?xml version="1.0" encoding="UTF-8"?>
<!-- Gerado por level-theme/tools/build-icons.ps1 a partir dos SVGs oficiais da Level (não editar à mão) -->
<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny" width="$(F $w)" height="$(F $h)" viewBox="0 0 $(F $w) $(F $h)">
<title>$title</title>
$body
</svg>
"@
}

function Write-Text([string]$rel, [string]$text) {
    $path = Join-Path $out $rel
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
    Write-Host "  $rel"
    $path
}

function Export-Png([string]$svgPath, [string]$rel, [int]$w, [int]$h) {
    $png = Join-Path $out $rel
    New-Item -ItemType Directory -Force (Split-Path $png) | Out-Null
    & $inkscape $svgPath --export-type=png "--export-filename=$png" "--export-width=$w" "--export-height=$h" 2>$null | Out-Null
    if (-not (Test-Path $png)) { throw "Inkscape falhou: $rel" }
    Write-Host "  $rel ($w x $h)"
}

function Export-Bmp([string]$svgPath, [string]$rel, [int]$w, [int]$h) {
    $tmp = Join-Path $work ([IO.Path]::GetFileNameWithoutExtension($rel) + '.png')
    & $inkscape $svgPath --export-type=png "--export-filename=$tmp" "--export-width=$w" "--export-height=$h" 2>$null | Out-Null
    $bmp = Join-Path $out $rel
    New-Item -ItemType Directory -Force (Split-Path $bmp) | Out-Null
    # WiX exige BMP 24 bits sem alfa
    & $magick $tmp -background white -alpha remove -alpha off -type TrueColor "BMP3:$bmp"
    if ($LASTEXITCODE -ne 0) { throw "ImageMagick falhou: $rel" }
    Write-Host "  $rel ($w x $h, BMP 24 bits)"
}

# ---------------------------------------------------------------- 3. preparar
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force $out, $work | Out-Null

$simCor = Read-Logo 'level-simbolo-cor.svg'
$simNeg = Read-Logo 'level-simbolo-cor-negativo.svg'
$horCor = Read-Logo 'level-horizontal-cor.svg'
$horNeg = Read-Logo 'level-horizontal-cor-negativo.svg'
$horPreto = Read-Logo 'level-horizontal-preto.svg'
$horBranco = Read-Logo 'level-horizontal-branco.svg'

$ICON = 'LevelDrive'      # = APPLICATION_ICON_NAME (level-theme/NEXTCLOUD.cmake)
$EXE = 'leveldrive'       # = APPLICATION_EXECUTABLE

Write-Host 'Ícone do aplicativo, Menu Iniciar e pasta:'
# ícone do app: símbolo -cor centralizado no quadrado, respiro de 6% em cima/embaixo
Write-Text "theme\colored\$ICON-icon.svg" (Svg 1024 1024 (Place $simCor 0 61.44 1024 901.12) 'Level Drive') | Out-Null

# Menu Iniciar: símbolo -cor-negativo sobre a placa #103B40 (a placa vem do BackgroundColor do manifest);
# um pouco acima do centro porque o Windows escreve o nome do app na base do bloco 150x150
Write-Text "theme\colored\$ICON-w10startmenu.svg" (Svg 1024 1024 (Place $simNeg 0 205 1024 512) 'Level Drive') | Out-Null

# Pasta sincronizada (24 px ou mais; 16/20 px usam o ícone do app — src/gui/CMakeLists.txt:583-590)
$folder = @'
<path fill="#C9CCCB" d="M 61 225 Q 61 164 123 164 L 389 164 L 471 246 L 901 246 Q 963 246 963 307 L 963 348 L 61 348 Z"/>
<rect x="61" y="307" width="902" height="594" rx="72" ry="72" fill="#E4E6E5" stroke="#B9BDBC" stroke-width="12"/>
'@
Write-Text "theme\colored\icons\$ICON-icon-win-folder.svg" (Svg 1024 1024 ($folder + "`n" + (Place $simCor 0 420 1024 348)) 'Level Drive') | Out-Null

$manifest = @"
<Application xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
  <VisualElements
    BackgroundColor="#103B40"
    ForegroundText="light"
    ShowNameOnSquare150x150Logo="on"
    Square150x150Logo="visualelements\150-$ICON-w10startmenu.png"
    Square70x70Logo="visualelements\70-$ICON-w10startmenu.png"/>
</Application>
"@
Write-Text "theme\$EXE.VisualElementsManifest.xml" $manifest | Out-Null

# ---------------------------------------------------------------- 4. estados (bandeja e app)
# Opção A aprovada em 2026-11-11: black\ = barra CLARA (símbolo -cor), white\ = barra ESCURA (-cor-negativo).
# O patch 0003 faz a bandeja escolher white/black pelo tema da barra de tarefas. colored\ (usado dentro do app)
# recebe a versão clara.
$glyphs = @{
    check = { param($c) "<path d=`"M 64 79 L 71 86 L 84 72`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`" stroke-linejoin=`"round`"/>" }
    x     = { param($c) "<path d=`"M 66 70 L 82 86 M 82 70 L 66 86`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`"/>" }
    bang  = { param($c) "<path d=`"M 74 67 L 74 78`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`"/><circle cx=`"74`" cy=`"86`" r=`"3.2`" fill=`"$c`"/>" }
    pause = { param($c) "<path d=`"M 68.5 70 L 68.5 86 M 79.5 70 L 79.5 86`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`"/>" }
    slash = { param($c) "<circle cx=`"74`" cy=`"78`" r=`"8`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`"/><path d=`"M 68 84 L 80 72`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`"/>" }
    info  = { param($c) "<circle cx=`"74`" cy=`"69.5`" r=`"3.2`" fill=`"$c`"/><path d=`"M 74 76 L 74 87`" fill=`"none`" stroke=`"$c`" stroke-width=`"5.5`" stroke-linecap=`"round`"/>" }
    sync  = { param($c) "<path d=`"M 66 76 A 8.5 8.5 0 0 1 81 72.5 M 81 66.5 L 81 72.5 L 75 72.5 M 82 80 A 8.5 8.5 0 0 1 67 83.5 M 67 89.5 L 67 83.5 L 73 83.5`" fill=`"none`" stroke=`"$c`" stroke-width=`"4.6`" stroke-linecap=`"round`" stroke-linejoin=`"round`"/>" }
}
# estado -> glifo, [fundo, traço] na barra clara, [fundo, traço] na barra escura
# Regra da marca: sobre o verde #53AE93 o traço é #103B40 (nunca branco).
# Vermelho/âmbar/cinza: cores semânticas fora da paleta — <<PREENCHER: confirmar com a Level>>
$states = [ordered]@{
    'ok'      = @('check', '#53AE93', '#103B40', '#53AE93', '#103B40')
    'sync'    = @('sync',  '#103B40', '#EFEFEF', '#83C8B4', '#103B40')
    'error'   = @('x',     '#C8423B', '#FFFFFF', '#E0645C', '#1C1C1C')
    'warning' = @('bang',  '#E0A526', '#222323', '#E0A526', '#222323')
    'pause'   = @('pause', '#5B5C5C', '#FFFFFF', '#B6B6B6', '#1C1C1C')
    'offline' = @('slash', '#5B5C5C', '#FFFFFF', '#B6B6B6', '#1C1C1C')
    'info'    = @('info',  '#103B40', '#EFEFEF', '#83C8B4', '#103B40')
}
function StateSvg([string]$name, [string]$variant) {
    $st = $states[$name]
    if ($variant -eq 'dark') { $logo = $simNeg; $ring = '#1C1C1C'; $bg = $st[3]; $fg = $st[4] }
    else { $logo = $simCor; $ring = '#F3F3F3'; $bg = $st[1]; $fg = $st[2] }
    # anel na cor aproximada da barra de tarefas separa o indicador do símbolo (sem máscaras: SVG Tiny)
    $badge = "<circle cx=`"74`" cy=`"78`" r=`"21`" fill=`"$ring`"/><circle cx=`"74`" cy=`"78`" r=`"17`" fill=`"$bg`"/>" + (& $glyphs[$st[0]] $fg)
    Svg 100 100 ((Place $logo 0 3 100 94) + "`n" + $badge) "Level Drive - $name"
}
Write-Host 'Estados:'
foreach ($n in $states.Keys) {
    Write-Text "theme\black\state-$n.svg" (StateSvg $n 'light') | Out-Null
    Write-Text "theme\white\state-$n.svg" (StateSvg $n 'dark') | Out-Null
    if ($n -ne 'info') { Write-Text "theme\colored\state-$n.svg" (StateSvg $n 'light') | Out-Null }
}

# ---------------------------------------------------------------- 5. assistente
Write-Host 'Assistente:'
# wizard_logo.svg = cópia byte a byte do original horizontal -cor-negativo (usado sobre #103B40)
Copy-Item (Join-Path $BrandDir 'level-horizontal-cor-negativo.svg') (Join-Path $out 'theme\colored\wizard_logo.svg')
Write-Host '  theme\colored\wizard_logo.svg (cópia do original)'
# PNGs no mesmo enquadramento do upstream (132x63 e 2x), fundo transparente, respiro de 8%
$wl = Join-Path $work 'wizard_logo-canvas.svg'
[IO.File]::WriteAllText($wl, (Svg 132 63 (Place $horNeg 6 5 120 53) 'Level'), (New-Object Text.UTF8Encoding $false))
Export-Png $wl 'theme\colored\wizard_logo.png' 132 63
Export-Png $wl 'theme\colored\wizard_logo@2x.png' 264 126

# wizard-nextcloud.* (logo Nextcloud embutido no qrc mesmo sem ser exibido): trocado pela Level
foreach ($v in @(@('colored', $horCor), @('black', $horPreto), @('white', $horBranco))) {
    $svgText = Svg 200 100 (Place $v[1] 12 25 176 50) 'Level'
    $p = Write-Text "theme\$($v[0])\wizard-nextcloud.svg" $svgText
    Export-Png $p "theme\$($v[0])\wizard-nextcloud.png" 200 100
    Export-Png $p "theme\$($v[0])\wizard-nextcloud@2x.png" 400 200
}

# ---------------------------------------------------------------- 6. instalador MSI (WiX)
Write-Host 'Instalador MSI:'
# banner 493x58: WiX escreve título/descrição em preto à esquerda -> fundo branco, logo -cor à direita
$banner = Join-Path $work 'banner.svg'
[IO.File]::WriteAllText($banner, (Svg 493 58 ('<rect width="493" height="58" fill="#FFFFFF"/>' + (Place $horCor 360 13 121 32 'right')) 'banner'), (New-Object Text.UTF8Encoding $false))
Export-Bmp $banner 'admin\win\msi\gui\banner.bmp' 493 58
# dialog 493x314: faixa esquerda 164 px #103B40 com o símbolo -cor-negativo; texto do WiX à direita (fundo branco)
$dialog = Join-Path $work 'dialog.svg'
[IO.File]::WriteAllText($dialog, (Svg 493 314 ('<rect width="493" height="314" fill="#FFFFFF"/><rect width="164" height="314" fill="#103B40"/>' + (Place $simNeg 46 34 72 82)) 'dialog'), (New-Object Text.UTF8Encoding $false))
Export-Bmp $dialog 'admin\win\msi\gui\dialog.bmp' 493 314

Write-Host "OK: overlay gerado em $out"

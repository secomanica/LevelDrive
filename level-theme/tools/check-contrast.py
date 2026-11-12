# SPDX-FileCopyrightText: 2026 Level Tecnologia
# SPDX-License-Identifier: GPL-2.0-or-later
"""Confere o contraste WCAG 2.x de todos os pares texto/fundo do tema Level (Fase 4).

Uso: python -I level-theme/tools/check-contrast.py
Sai com código 1 se algum par de TEXTO ficar abaixo de 4,5:1 (ou um par de não-texto abaixo de 3:1).
Os pares espelham os valores de level-theme/patches/0004 (Style.qml) e 0006 (links/paleta).
"""
import sys


def lum(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

    def ch(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def ratio(a: str, b: str) -> float:
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# (tema, descrição, primeiro plano, fundo, mínimo)
TEXT, UI = 4.5, 3.0
PAIRS = [
    # ---- claro
    ("claro", "texto principal / janela", "#222323", "#EFEFEF", TEXT),
    ("claro", "texto principal / campo, linha", "#222323", "#FFFFFF", TEXT),
    ("claro", "texto secundário / janela", "#5B5C5C", "#EFEFEF", TEXT),
    ("claro", "texto secundário / campo", "#5B5C5C", "#FFFFFF", TEXT),
    ("claro", "placeholder / campo", "#5B5C5C", "#FFFFFF", TEXT),
    ("claro", "título / janela", "#103B40", "#EFEFEF", TEXT),
    ("claro", "texto / linha selecionada", "#222323", "#DCEFE8", TEXT),
    ("claro", "secundário / linha selecionada", "#5B5C5C", "#DCEFE8", TEXT),
    ("claro", "botão primário: texto / verde", "#103B40", "#53AE93", TEXT),
    ("claro", "botão primário: texto / hover", "#103B40", "#6FBDA5", TEXT),
    ("claro", "botão secundário: texto / fundo", "#222323", "#E4E6E5", TEXT),
    ("claro", "botão secundário: texto / hover", "#222323", "#D6D9D8", TEXT),
    ("claro", "seleção: texto / #103B40", "#FFFFFF", "#103B40", TEXT),
    ("claro", "assistente: texto / gradiente início", "#FFFFFF", "#103B40", TEXT),
    ("claro", "assistente: texto / gradiente fim", "#FFFFFF", "#2A6B6F", TEXT),
    ("claro", "aviso / campo", "#8A5200", "#FFFFFF", TEXT),
    ("claro", "erro / campo", "#B00020", "#FFFFFF", TEXT),
    ("claro", "link / campo", "#103B40", "#FFFFFF", TEXT),
    ("claro", "link / janela", "#103B40", "#EFEFEF", TEXT),
    ("claro", "cabeçalho: título / #103B40", "#EFEFEF", "#103B40", TEXT),
    ("claro", "InfoBox: texto / fundo", "#222323", "#E0E7E7", TEXT),
    ("claro", "foco/rádio (não-texto) / campo", "#103B40", "#FFFFFF", UI),
    ("claro", "borda de campo (não-texto) / campo", "#8E9191", "#FFFFFF", UI),
    # ---- escuro
    ("escuro", "texto principal / janela", "#EFEFEF", "#222323", TEXT),
    ("escuro", "texto principal / campo, linha", "#EFEFEF", "#2F3030", TEXT),
    ("escuro", "texto secundário / janela", "#B6B6B6", "#222323", TEXT),
    ("escuro", "texto secundário / campo", "#B6B6B6", "#2F3030", TEXT),
    ("escuro", "título / janela", "#83C8B4", "#222323", TEXT),
    ("escuro", "texto / linha selecionada", "#EFEFEF", "#1D4347", TEXT),
    ("escuro", "secundário / linha selecionada", "#B6B6B6", "#1D4347", TEXT),
    ("escuro", "botão primário: texto / verde", "#103B40", "#53AE93", TEXT),
    ("escuro", "botão primário: texto / hover", "#103B40", "#6FBDA5", TEXT),
    ("escuro", "botão secundário: texto / fundo", "#EFEFEF", "#3A3B3B", TEXT),
    ("escuro", "botão secundário: texto / hover", "#EFEFEF", "#454747", TEXT),
    ("escuro", "seleção: texto / #83C8B4", "#103B40", "#83C8B4", TEXT),
    ("escuro", "assistente: texto / gradiente início", "#103B40", "#83C8B4", TEXT),
    ("escuro", "assistente: texto / gradiente fim", "#103B40", "#6FBDA5", TEXT),
    ("escuro", "aviso / campo", "#F2B84B", "#2F3030", TEXT),
    ("escuro", "erro / campo", "#FF7B86", "#2F3030", TEXT),
    ("escuro", "link / janela", "#53AE93", "#222323", TEXT),
    ("escuro", "link / campo", "#53AE93", "#2F3030", TEXT),
    ("escuro", "InfoBox: texto / fundo", "#EFEFEF", "#24393B", TEXT),
    ("escuro", "foco/rádio (não-texto) / campo", "#83C8B4", "#2F3030", UI),
    ("escuro", "borda de campo (não-texto) / campo", "#7A7D7D", "#2F3030", UI),
]

fail = 0
for theme, desc, fg, bg, minimum in PAIRS:
    r = ratio(fg, bg)
    ok = r >= minimum
    fail += not ok
    print(f"{'OK ' if ok else 'FALHA'} {r:5.2f}:1 (mín {minimum}) [{theme}] {desc}: {fg} sobre {bg}")
print(f"\n{len(PAIRS) - fail}/{len(PAIRS)} pares atendem ao mínimo.")
sys.exit(1 if fail else 0)

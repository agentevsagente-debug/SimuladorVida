"""Versões fortes, para o dia, da fartura e do sonho (auditoria 10, Q1). De dia, sobre o capim,
a copa e o céu claro, os brilhos de 8 x 8 quase não se viam sem a mensagem da alça.

- A fartura usa a estrela de 12 x 12 das versões noturnas, com o contorno marrom-escuro (em
  vez do azul da noite), que separa o dourado do céu claro e do verde. A aura tem partículas
  de 2 px com a sombra marrom embaixo.
- O sonho é uma espiral maior (24 x 24), com pontos de 2 px em lilás e branco contornados de
  lilás escuro, que desce sobre quem sonha.

Ficam no lugar das de dia (`fartura_brilho_4q`, `fartura_aura_4q`, `sonho_4q` e
`sonho_brilho_4q`) do amanhecer ao entardecer; à noite, valem as `*_noite_*`.
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

from comum import PALETA, folha_quadros, gravar, para_imagem  # noqa: E402
from efeitos_noite import contornar, estrela, novo, put  # noqa: E402

CONTORNO_DIA = 23      # marrom-escuro: se lê sobre o céu claro, o capim e a copa


def fartura_aura_dia():
    """Partículas douradas de 2 px subindo da roça e das árvores frutíferas, com a sombra
    marrom embaixo e uma faísca branca de vez em quando (16x16)."""
    rng = random.Random(92)
    parts = [(rng.randint(1, 13), rng.randint(0, 14)) for _ in range(10)]
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        for i, (x, y) in enumerate(parts):
            yy = (y - k * 4) % 15
            xx = x + (1 if (yy // 4 + x) % 2 else 0)
            put(q, xx, yy, 31 if (i + k) % 5 == 0 else 22)
            put(q, xx, yy + 1, 21)
            put(q, xx + 1, yy + 1, CONTORNO_DIA)
        quadros.append(q)
    return quadros


def sonho_dia():
    """A espiral do sonho maior (24x24): 8 pontos de 2 x 2 em branco e lilás, contornados de
    lilás escuro, girando e descendo para o centro. A base (linha 23) vai 1 px acima da cabeça."""
    quadros = []
    cx, cy = 11.5, 11
    for k in range(4):
        q = novo(24, 24)
        for i in range(8):
            a = k * math.pi / 8 + i * 2 * math.pi / 8
            r = 9.5 - i * 0.9
            x, y = round(cx + math.cos(a) * r), round(cy + math.sin(a) * r * 0.6 + i * 0.9)
            cor = 31 if i < 2 else 29
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                put(q, x + dx, y + dy, cor if (dx, dy) != (1, 1) else 7)
        put(q, 11, 22, 31)
        put(q, 12, 22, 29)
        contornar(q, 5)
        quadros.append(q)
    return quadros


def gerar():
    return {
        "fartura_brilho_dia_4q": estrela(22, 31, 21, 21, contorno=CONTORNO_DIA),
        "fartura_aura_dia_4q": fartura_aura_dia(),
        "sonho_dia_4q": sonho_dia(),
        "sonho_brilho_dia_4q": estrela(29, 31, 7, 7, contorno=5),
    }


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    # amostra: a de antes (8x8 e 16x16) e a nova, sobre o céu, o capim e a copa de dia
    antes = {"fartura_brilho_dia_4q": "fartura_brilho_4q", "fartura_aura_dia_4q": "fartura_aura_4q",
             "sonho_dia_4q": "sonho_4q", "sonho_brilho_dia_4q": "sonho_brilho_4q"}
    W, H = 3 * 130, len(folhas) * 30 + 4
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    for i, cor in enumerate((1, 15, 14)):
        img.paste(PALETA[cor] + (255,), (i * 130, 0, (i + 1) * 130, H))
    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 30
        velha = Image.open(AQUI / f"{antes[nome]}.png")
        qv = velha.width // 4
        for i in range(3):
            x0 = i * 130 + 2
            img.alpha_composite(velha.crop((0, 0, qv, velha.height)), (x0, y))
            for n, q in enumerate(qs):
                img.alpha_composite(para_imagem(q), (x0 + qv + 4 + n * (len(q[0]) + 1), y))
    img.save(AQUI / "amostra_efeitos_dia.png")
    img.resize((W * 3, H * 3), Image.NEAREST).save(AQUI / "amostra_efeitos_dia_4x.png")
    print("efeitos de dia:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

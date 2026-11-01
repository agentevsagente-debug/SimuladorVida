"""Ruínas e marcas da memória: o que fica no mundo depois que as pessoas passam.

A cabana abandonada e a casa em ruína saem das próprias peças inteiras (estágio 1 e 2),
degradadas por código, para combinar exatamente com elas.
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI.parent / "estagio1"))
sys.path.insert(0, str(AQUI.parent / "estagio2"))
sys.path.insert(0, str(AQUI.parent / "terreno"))

from comum import PALETA, gravar, para_imagem, pont  # noqa: E402
import estagio1  # noqa: E402
import estagio2  # noqa: E402
import terreno  # noqa: E402

FOLHAS = (13, 14, 15, 16)


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


def mato(q, x, base, rng, n=3):
    for i in range(n):
        h = rng.randint(1, 3)
        for k in range(h):
            put(q, x + i, base - k, 15 if k == h - 1 else 14)


def cabana_abandonada():
    q = [l[:] for l in estagio1.gerar()[0]["cabana_galhos"]]
    rng = random.Random(301)
    for y in range(16):
        for x in range(16):
            c = q[y][x]
            if c is None:
                continue
            if c in FOLHAS:
                # folhas secaram ou caíram
                q[y][x] = None if rng.random() < 0.55 else (10 if c in (15, 16) else 9)
            elif c == 10 and rng.random() < 0.35:
                q[y][x] = 9
            # o topo cedeu: some a ponta e o lado direito afunda
            if y < 5 and x >= 7:
                q[y][x] = None
    # galhos caídos no chão e mato crescendo
    for x in range(10, 16):
        put(q, x, 15, 9 if x % 2 else 8)
    for i in range(4):
        put(q, 12 + i, 14 - i // 2, 10)
    mato(q, 1, 15, rng)
    mato(q, 12, 14, rng, 2)
    return q


def casa_ruina():
    parede = estagio2.casa_parede()
    rng = random.Random(302)
    q = novo(24, 24)
    # parede com o topo quebrado em degraus irregulares
    topo = [11 + int(abs(math.sin(x * 0.7)) * 4) + rng.randint(0, 2) for x in range(24)]
    for y in range(24):
        for x in range(24):
            c = parede[y][x]
            if c is None or y < topo[x]:
                continue
            if c == 10 and rng.random() < 0.25:
                c = 9
            if 10 <= x <= 13 and y >= 16:
                c = 30                       # porta sem folha
            q[y][x] = c
    # buracos na taipa, mostrando o trançado
    for cx, cy, forma in ((6, 17, ((0, 0), (1, 0), (0, 1), (-1, 1), (1, -1))), (17, 20, ((0, 0), (1, 0), (1, 1), (0, -1)))):
        for dx, dy in forma:
            put(q, cx + dx, cy + dy, 30)
        put(q, cx + 2, cy, 8)
        put(q, cx - 1, cy - 1, 8)
    # caibros que sobraram do telhado
    for i in range(7):
        put(q, 4 + i, 12 - i, 9)
        put(q, 19 - i // 2, 12 - i, 8)
    # entulho e mato
    for x in range(0, 24):
        if x < 3 or x > 20:
            if rng.random() < 0.7:
                put(q, x, 23, rng.choice((11, 12, 9, 8)))
            if rng.random() < 0.4:
                put(q, x, 22, rng.choice((11, 9)))
    mato(q, 1, 22, rng)
    mato(q, 20, 23, rng, 3)
    mato(q, 14, 23, rng, 2)
    return q


def tumulo():
    q = novo(16, 16)
    rng = random.Random(303)
    # pedra fincada atrás
    for y in range(4, 13):
        for x in range(6, 10):
            if y == 4 and x in (6, 9):
                continue
            c = 12 if x == 6 or y == 5 else 11
            if x == 9:
                c = 8
            put(q, x, y, c)
    put(q, 7, 7, 8)
    put(q, 8, 7, 8)
    put(q, 7, 8, 8)                         # marca riscada na pedra
    # monte de terra com grama rala
    for x in range(1, 15):
        u = (x - 7.5) / 7
        h = int(round(4 * math.sqrt(max(0.0, 1 - u * u))))
        for i in range(h):
            y = 15 - i
            c = 9 if i < h - 1 else 10
            if x > 10 and i == h - 1:
                c = 9
            put(q, x, y, c)
        if h and rng.random() < 0.5:
            put(q, x, 15 - h, 15 if x < 8 else 14)
    # flores
    for x, c in ((3, 22), (12, 20), (4, 20)):
        put(q, x, 11 if x != 12 else 12, c)
        put(q, x, 12 if x != 12 else 13, 14)
    return q


def pedra_erguida():
    q = novo(16, 32)
    for y in range(3, 30):
        alt = (y - 3) / 27
        meia = 2.5 + alt * 2.2
        cx = 7.5 + math.sin(y * 0.15) * 0.4
        for x in range(16):
            d = x - cx
            if abs(d) > meia:
                continue
            if d < -meia + 1.2:
                c = 12
            elif d > meia - 1.2:
                c = 8
            elif d > meia * 0.35:
                c = 11 if (x + y * 3) % 11 else 8
            else:
                c = 11 if (x * 5 + y) % 7 else 12
            put(q, x, y, c)
    put(q, 7, 2, 12)
    put(q, 8, 2, 11)
    # espiral entalhada
    for a in range(0, 340, 30):
        r = 0.6 + a / 160
        put(q, round(7.5 + math.cos(math.radians(a)) * r), round(14 + math.sin(math.radians(a)) * r), 8)
    # musgo na base e do lado da sombra
    for y in range(20, 30):
        put(q, 10 + (y % 2), y, 14 if y % 3 else 15)
    for x in range(3, 13):
        put(q, x, 30, 14 if x % 2 else 15)
        put(q, x, 31, 13)
    for x, c in ((2, 11), (13, 12), (14, 11)):
        put(q, x, 31, c)
    return q


def terra_queimada(semente):
    """Bloco de terreno 8x8 que substitui a grama: superfície na linha 2, como `grama_a`."""
    rng = random.Random(semente)
    b = terreno.terra(rng)
    b[0] = [None] * 8
    b[1] = [None] * 8
    for x in range(8):
        if rng.random() < 0.35:
            b[1][x] = 30                     # tocos de capim queimado
        b[2][x] = 30 if rng.random() < 0.6 else 8
        b[3][x] = 8 if rng.random() < 0.8 else 11
        if rng.random() < 0.12:
            b[3][x] = 20                     # brasa ainda acesa
        if rng.random() < 0.15:
            b[2][x] = 11                     # cinza
        b[4][x] = 8 if rng.random() < 0.5 else 9
    return b


def linha(q, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        put(q, round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)


def arvore_queimada():
    """Tronco carbonizado com galhos nus em forquilha e brasas ainda acesas."""
    q = novo(32, 32)
    for y in range(13, 32):
        larg = 2 if y < 27 else 3
        for x in range(15, 15 + larg + 1):
            c = 9 if x == 15 and y % 4 else 30 if x == 15 + larg else 8
            put(q, x, y, c)
    put(q, 14, 31, 8)
    put(q, 19, 31, 30)
    # galhos principais (8) e galhinhos (30), sempre em traço contínuo
    for (x0, y0, x1, y1), ramos in (
        ((15, 14, 7, 5), ((10, 8, 5, 6), (9, 7, 9, 2))),
        ((17, 14, 25, 6), ((22, 9, 27, 8), (24, 7, 23, 2))),
        ((16, 13, 17, 3), ((17, 7, 13, 2), (17, 5, 20, 1))),
        ((15, 20, 10, 16), ((11, 17, 9, 14),)),
    ):
        linha(q, x0, y0, x1, y1, 8)
        linha(q, x0, y0 + 1, x1, y1 + 1, 30) if abs(x1 - x0) > abs(y1 - y0) else None
        for a, b, c, d in ramos:
            linha(q, a, b, c, d, 30)
    for x, y in ((16, 22), (17, 26), (15, 17), (20, 10)):
        put(q, x, y, 20)
    put(q, 16, 18, 21)
    return q


def gerar():
    return {
        "tumulo": tumulo(),
        "cabana_abandonada": cabana_abandonada(),
        "casa_ruina": casa_ruina(),
        "pedra_erguida": pedra_erguida(),
        "terra_queimada_a": terra_queimada(307),
        "terra_queimada_b": terra_queimada(308),
        "arvore_queimada": arvore_queimada(),
    }


def amostra(pecas):
    terr = AQUI.parent / "terreno"
    grama = Image.open(terr / "grama_a.png")
    terra = Image.open(terr / "terra_a.png")
    W, H = 168, 56
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    chao = 40
    for x in range(0, W, 8):
        bloco = para_imagem(pecas["terra_queimada_a" if 124 <= x < 156 and x % 16 else
                                  "terra_queimada_b"]) if 124 <= x < 156 else grama
        img.alpha_composite(bloco, (x, chao - 2))
        img.alpha_composite(terra, (x, chao + 6))
        img.alpha_composite(terra, (x, chao + 14))
    x = 4
    for nome in ("tumulo", "cabana_abandonada", "casa_ruina", "pedra_erguida", "arvore_queimada"):
        p = para_imagem(pecas[nome])
        img.alpha_composite(p, (x, chao - p.height + 1))
        x += p.width + 6
    return img


def principal():
    pecas = gerar()
    for nome, px in pecas.items():
        gravar(px, AQUI / f"{nome}.png")
    img = amostra(pecas)
    img.save(AQUI / "amostra_memoria.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_memoria_4x.png")
    print("memória:", ", ".join(f"{n} {len(p[0])}x{len(p)}" for n, p in pecas.items()))


if __name__ == "__main__":
    principal()

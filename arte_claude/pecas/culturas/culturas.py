"""Variações de cultura: 3 paredes, 3 telhados e 3 símbolos de templo, que o jogo combina.

As peças têm o mesmo tamanho e o mesmo encaixe da casa (24x24) e do templo (32x32) do
estágio 2: parede primeiro, telhado por cima, símbolo por último. Porta e janela ficam
no mesmo lugar em todas, então qualquer parede combina com qualquer telhado.
"""
from pathlib import Path
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI.parent / "estagio2"))
sys.path.insert(0, str(AQUI.parent / "habitantes"))

from comum import PALETA, gravar, para_imagem, pont, trocar  # noqa: E402
import estagio2  # noqa: E402


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]) and c is not None:
        q[y][x] = c


def sobrepor(*camadas):
    out = [l[:] for l in camadas[0]]
    for cam in camadas[1:]:
        for y, l in enumerate(cam):
            for x, c in enumerate(l):
                if c is not None:
                    out[y][x] = c
    return out


# ---------------------------------------------------------------- paredes

def cor_parede(material, x, y, x0, x1, y0, rng):
    if material == "taipa":
        c = 10
        v = rng.random()
        if v < 0.1:
            c = 9
        elif v < 0.14:
            c = 12
        if x >= x1 - 2 and pont(x, y, 0.5):
            c = 9
        if x in (x0, x1) or y == y0:
            c = 8 if x == x1 else 9
        return c
    if material == "pedra":
        fiada = (y - y0) // 3
        junta_v = (x + fiada * 3) % 6 == 0
        if (y - y0) % 3 == 0 or junta_v:
            return 11 if x < x1 - 1 else 8
        c = 12
        if (y - y0) % 3 == 2 or x >= x1 - 1:
            c = 11
        return c
    # madeira: tábuas horizontais com esteios nos cantos
    if x in (x0, x1):
        return 9 if x == x0 else 8
    if (y - y0) % 3 == 0:
        return 8
    c = 10 if (y - y0) % 3 == 1 else 9
    if x >= x1 - 2 and c == 10 and pont(x, y, 0.5):
        c = 9
    if (x * 7 + y) % 13 == 0:
        c = 8                                   # nó da madeira
    return c


def casa_parede(material):
    if material == "taipa":
        return estagio2.casa_parede()
    q = novo(24, 24)
    rng = random.Random(401)
    x0, x1, y0 = 3, 20, 11
    for y in range(y0, 24):
        for x in range(x0, x1 + 1):
            put(q, x, y, cor_parede(material, x, y, x0, x1, y0, rng))
    for y in range(16, 24):
        for x in range(10, 14):
            put(q, x, y, 30 if y > 16 else 8)
    put(q, 13, 20, 9)
    for y in range(14, 17):
        for x in range(15, 18):
            put(q, x, y, 30)
    for x in range(14, 19):
        put(q, x, 17, 9 if material == "madeira" else 11)
        put(q, x, 13, 8)
    for x in range(x0, x1 + 1):
        put(q, x, 23, 8)
    return q


def templo_parede(material):
    if material == "pedra":
        return estagio2.templo_parede()
    q = estagio2.templo_parede()
    rng = random.Random(402)
    x0, x1, y0 = 6, 25, 15
    for y in range(y0, 27):
        for x in range(x0, x1 + 1):
            if q[y][x] in (30, 8) and 13 <= x <= 18 and y >= 18:
                continue                          # mantém a porta em arco
            if y == 18 and 13 <= x <= 18:
                continue
            put(q, x, y, cor_parede(material, x, y, x0, x1, y0, rng))
    return q


# ---------------------------------------------------------------- telhados

def telhado(estilo, larg, topo_y, alt, rng):
    q = novo(larg, topo_y + alt + 1)
    cx = (larg - 1) / 2
    for y in range(topo_y, topo_y + alt):
        r = y - topo_y
        hw = 1 + r * (larg / 2 - 1) / (alt - 1)
        for x in range(larg):
            dx = x - cx
            if abs(dx) > hw:
                continue
            ultima = y == topo_y + alt - 1
            if estilo == "palha":
                if ultima:
                    c = 8
                elif r == 0 or (abs(dx) > hw - 1 and dx > 0):
                    c = 9
                elif dx < 0:
                    c = 16 if (x + r // 2) % 3 else 10
                else:
                    c = 10 if (x + r // 2) % 3 else 9
            elif estilo == "telha":
                # fileiras de telhas de barro: cada 2 linhas, meia-lua clara e sombra embaixo
                linha_t = r % 2
                desloc = (r // 2) % 2 * 2
                if ultima:
                    c = 23
                elif r == 0:
                    c = 24
                elif linha_t == 0:
                    c = 20 if (x + desloc) % 4 != 3 else 24
                else:
                    c = 24 if (x + desloc) % 4 != 3 else 23
                if dx > 0 and c == 20 and pont(x, y, 0.5):
                    c = 24
                if abs(dx) > hw - 1 and dx > 0:
                    c = 23
            else:  # tábuas: telhado íngreme de madeira, tábuas verticais
                if ultima:
                    c = 8
                elif (x % 3) == 0:
                    c = 8 if dx > 0 else 9
                else:
                    c = 10 if dx < 0 else 9
                if abs(dx) > hw - 1:
                    c = 9 if dx < 0 else 8
            q[y][x] = c
    if estilo == "palha":
        for x in range(0, larg, 3):
            if rng.random() < 0.6:
                put(q, x, topo_y + alt, 16 if x < cx else 10)
    return q


ESTILO_TELHADO = {"palha": (11, 2), "telha": (9, 4), "tabuas": (12, 1)}   # altura, linha do topo


def casa_telhado(estilo):
    if estilo == "palha":
        return estagio2.casa_telhado()
    alt, topo = ESTILO_TELHADO[estilo]
    t = telhado(estilo, 24, topo, alt, random.Random(403))
    q = novo(24, 24)
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x, y, c)
    cx = 11
    if estilo == "tabuas":                       # tábuas cruzadas na cumeeira
        put(q, cx - 1, 0, 10)
        put(q, cx + 2, 0, 9)
    else:                                        # cumeeira de telhas
        for x in range(cx - 1, cx + 3):
            put(q, x, topo - 1, 23)
    return q


def templo_telhado(estilo):
    if estilo == "palha":
        return estagio2.templo_telhado()
    alt = {"telha": 10, "tabuas": 14}[estilo]
    topo = 15 - alt
    t = telhado(estilo, 30, topo, alt, random.Random(404))
    q = novo(32, 32)
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x + 1, y, c)
    if estilo == "tabuas":
        for i in range(3):
            put(q, 14 - i, topo - 1 - i, 10)
            put(q, 17 + i, topo - 1 - i, 9)
    else:
        for x in range(14, 18):
            put(q, x, topo - 1, 23)
    return q


# ---------------------------------------------------------------- símbolos do templo

def simbolo(nome):
    """Símbolo no alto do templo. Fica nas linhas 0-4 e se apoia num mastro (9) que
    desce até o telhado mais alto (o de tábuas, que começa na linha 1)."""
    q = novo(32, 32)
    if nome == "sol":
        return estagio2.templo_simbolo()
    cx = 15
    if nome == "lua":
        for dx, dy, c in ((0, 0, 31), (-1, 1, 31), (-1, 2, 31), (0, 3, 31), (1, 0, 0), (0, 1, 0),
                          (0, 2, 0), (1, 3, 0), (-2, 1, 19), (-2, 2, 19), (2, 0, 19), (2, 3, 19)):
            put(q, cx + dx, dy, c)
        put(q, cx + 1, 4, 9)
    else:  # árvore
        for dx, dy, c in ((0, 0, 15), (1, 0, 15), (-1, 1, 15), (0, 1, 14), (1, 1, 14), (2, 1, 13),
                          (-1, 2, 14), (0, 2, 13), (1, 2, 13), (2, 2, 13), (0, 3, 9), (1, 3, 8), (0, 4, 9),
                          (1, 4, 8)):
            put(q, cx + dx, dy, c)
    for y in range(4, 6):
        put(q, cx, y, 9)
        put(q, cx + 1, y, 8)
    return q


PAREDES = ("taipa", "pedra", "madeira")
TELHADOS = ("palha", "telha", "tabuas")
SIMBOLOS = ("sol", "lua", "arvore")
# Três povos de exemplo (cada um junta uma parede, um telhado, um símbolo e uma roupa)
POVOS = (("taipa", "palha", "sol", 28), ("pedra", "telha", "lua", 29), ("madeira", "tabuas", "arvore", 27))


def gerar():
    pecas = {}
    for m in PAREDES:
        pecas[f"casa_parede_{m}"] = casa_parede(m)
        pecas[f"templo_parede_{m}"] = templo_parede(m)
    for e in TELHADOS:
        pecas[f"casa_telhado_{e}"] = casa_telhado(e)
        pecas[f"templo_telhado_{e}"] = templo_telhado(e)
    for s in SIMBOLOS:
        pecas[f"templo_simbolo_{s}"] = simbolo(s)
    return pecas


def amostra(pecas):
    """Em cima, os 3 povos (casa, templo e um habitante); embaixo, as 9 casas possíveis."""
    import habitantes as hab
    terr = AQUI.parent / "terreno"
    grama = Image.open(terr / "grama_a.png")
    terra = Image.open(terr / "terra_a.png")
    W, H = 264, 96
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    for chao in (40, 86):
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, chao - 2))
            img.alpha_composite(terra, (x, chao + 6))
    pessoa = hab.folhas()["adulto_a_parado_2q"][0]
    x = 4
    for parede, telh, simb, roupa in POVOS:
        casa = sobrepor(pecas[f"casa_parede_{parede}"], pecas[f"casa_telhado_{telh}"])
        templo = sobrepor(pecas[f"templo_parede_{parede}"], pecas[f"templo_telhado_{telh}"],
                          pecas[f"templo_simbolo_{simb}"])
        img.alpha_composite(para_imagem(casa), (x, 40 - 23))
        img.alpha_composite(para_imagem(templo), (x + 26, 40 - 31))
        img.alpha_composite(para_imagem(trocar(pessoa, hab.troca(tecido=roupa))), (x + 60, 40 - 11))
        x += 88
    x = 4
    for parede in PAREDES:
        for telh in TELHADOS:
            casa = sobrepor(pecas[f"casa_parede_{parede}"], pecas[f"casa_telhado_{telh}"])
            img.alpha_composite(para_imagem(casa), (x, 86 - 23))
            x += 29
    return img


def principal():
    pecas = gerar()
    for nome, px in pecas.items():
        gravar(px, AQUI / f"{nome}.png")
    img = amostra(pecas)
    img.save(AQUI / "amostra_culturas.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_culturas_4x.png")
    print("culturas:", len(pecas), "peças")


if __name__ == "__main__":
    principal()

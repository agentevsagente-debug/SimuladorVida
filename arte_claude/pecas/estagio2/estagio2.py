"""Estágio 2 (agricultura): roças, casa de taipa, celeiro, cerca, altar, templo e o
habitante com enxada. Mesmo tratamento da cena-alvo: luz de cima e da esquerda,
contorno com o tom mais escuro do próprio material.

Casa e templo também saem em partes (parede e telhado separados), porque as culturas
trocam telhado e parede de forma independente.
"""
from pathlib import Path
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI.parent / "habitantes"))

from comum import PALETA, folha_quadros, gravar, para_imagem, pont  # noqa: E402
import habitantes as hab  # noqa: E402


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]) and c is not None:
        q[y][x] = c


def sobrepor(base, topo):
    out = [l[:] for l in base]
    for y, l in enumerate(topo):
        for x, c in enumerate(l):
            if c is not None:
                out[y][x] = c
    return out


# ---------------------------------------------------------------- roças (16x16, repetem na horizontal)

def solo_arado(q, seco=False):
    """Sulcos nas 4 últimas linhas, com período de 4 px (a roça repete sem emenda)."""
    for x in range(16):
        k = x % 4
        topo = 12 if k in (1, 2) else 13
        for y in range(topo, 16):
            if k == 0:
                c = 8 if y > 13 else 9
            elif y == topo:
                c = 10 if k == 1 else 9
            else:
                c = 9 if y < 15 else 8
            if seco and y == topo and k == 2:
                c = 30            # rachadura no solo seco
            put(q, x, y, c)


def roca(fase):
    q = novo(16, 16)
    solo_arado(q, seco=fase == "seca")
    for x0 in range(1, 16, 4):
        if fase == "broto":
            put(q, x0, 11, 14)
            put(q, x0, 10, 15)
            put(q, x0 + 1, 10, 15)
        elif fase == "crescida":
            for i in range(6):
                put(q, x0, 11 - i, 14 if i < 4 else 15)
            for dx, dy, c in ((-1, 8, 15), (1, 7, 14), (-1, 6, 15), (1, 9, 13), (2, 8, 14)):
                put(q, x0 + dx, dy, c)
        elif fase == "madura":
            for i in range(9):
                put(q, x0, 11 - i, 10 if i < 3 else 16)
            for dx, dy, c in ((-1, 9, 16), (1, 8, 10), (1, 6, 16)):
                put(q, x0 + dx, dy, c)
            # espiga dourada no alto, pendendo para a direita
            for dx, dy, c in ((0, 2, 22), (1, 2, 22), (0, 3, 22), (1, 3, 16), (1, 4, 22), (2, 4, 16), (1, 1, 31)):
                put(q, x0 + dx, dy, c)
        elif fase == "seca":
            for i in range(5):
                put(q, x0 + (1 if i > 2 else 0), 11 - i, 10 if i < 2 else 9)
            put(q, x0 + 2, 7, 9)
            put(q, x0 + 2, 8, 10)
            put(q, x0 - 1, 9, 10)
    return q


# ---------------------------------------------------------------- casa de taipa (24x24)

def casa_parede():
    q = novo(24, 24)
    rng = random.Random(201)
    x0, x1, y0 = 3, 20, 11
    for y in range(y0, 24):
        for x in range(x0, x1 + 1):
            c = 10
            v = rng.random()
            if v < 0.1:
                c = 9
            elif v < 0.14:
                c = 12
            if x >= x1 - 2 and pont(x, y, 0.5):
                c = 9                      # lado direito na sombra
            if x in (x0, x1) or y == y0:
                c = 8 if x == x1 else 9    # esteios e viga de madeira
            if x == x0 + 6 and y > y0:
                c = 9                      # esteio do meio
            put(q, x, y, c)
    # porta e janela
    for y in range(16, 24):
        for x in range(10, 14):
            put(q, x, y, 30 if y > 16 else 8)
    put(q, 13, 20, 9)                      # tranca
    for y in range(14, 17):
        for x in range(15, 18):
            put(q, x, y, 30)
    for x in range(14, 19):
        put(q, x, 17, 9)
        put(q, x, 13, 8)
    # barra de terra na base
    for x in range(x0, x1 + 1):
        put(q, x, 23, 8)
    return q


def telhado_palha(larg, alt, topo_y, rng, cores=(16, 10, 9, 8)):
    """Telhado de duas águas de palha: listras verticais de palha, beiral escuro."""
    claro, medio, escuro, beiral = cores
    q = novo(larg, topo_y + alt)
    cx = (larg - 1) / 2
    for y in range(topo_y, topo_y + alt):
        r = y - topo_y
        hw = 1 + r * (larg / 2 - 1) / (alt - 1)
        for x in range(larg):
            dx = x - cx
            if abs(dx) > hw:
                continue
            if y == topo_y + alt - 1:
                c = beiral
            elif r == 0 or (abs(dx) > hw - 1 and dx > 0):
                c = escuro
            elif dx < 0:
                c = claro if (x + r // 2) % 3 else medio
            else:
                c = medio if (x + r // 2) % 3 else escuro
            if y == topo_y + alt - 2 and pont(x, y, 0.5):
                c = escuro
            q[y][x] = c
    # palha solta no beiral
    for x in range(0, larg, 3):
        if rng.random() < 0.6:
            put(q, x, topo_y + alt, claro if x < cx else medio)
    return q


def casa_telhado():
    t = telhado_palha(24, 11, 2, random.Random(202))
    q = novo(24, 24)
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x, y, c)
    # cumeeira amarrada
    put(q, 11, 1, 9)
    put(q, 12, 1, 9)
    put(q, 10, 0, 9)
    put(q, 13, 0, 9)
    return q


# ---------------------------------------------------------------- celeiro (24x24, sobre esteios)

def celeiro():
    q = novo(24, 24)
    # esteios
    for x in (5, 11, 18):
        for y in range(18, 24):
            put(q, x, y, 9)
            put(q, x + 1, y, 8)
    # plataforma
    for x in range(3, 22):
        put(q, x, 17, 9 if x < 20 else 8)
        put(q, x, 18, 8)
    # corpo de tábuas
    for y in range(9, 17):
        for x in range(4, 21):
            c = 10 if (y - 9) % 3 else 9
            if x in (4, 20):
                c = 8 if x == 20 else 9
            if x >= 18 and c == 10 and pont(x, y, 0.5):
                c = 9
            put(q, x, y, c)
    # portinhola
    for y in range(11, 15):
        for x in range(11, 14):
            put(q, x, y, 30 if y > 11 else 8)
    # telhado cônico de palha
    t = telhado_palha(22, 9, 1, random.Random(203))
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x + 1, y, c)
    # escada encostada
    for i in range(7):
        put(q, 1 + i // 3, 23 - i, 10)
        put(q, 3 + i // 3, 23 - i, 9)
        if i % 2 == 0:
            put(q, 2 + i // 3, 23 - i, 10)
    return q


# ---------------------------------------------------------------- cerca (8x8, repete)

def cerca(com_trilho=True):
    q = novo(8, 8)
    for y in range(1, 8):
        put(q, 1, y, 10 if y < 7 else 9)
        put(q, 2, y, 9 if y < 7 else 8)
    put(q, 1, 0, 9)
    if com_trilho:
        for x in range(8):
            if x in (1, 2):
                continue
            put(q, x, 3, 10)
            put(q, x, 4, 9)
            put(q, x, 5, 10 if x % 3 else 9)
            put(q, x, 6, 8 if x % 2 else None)
    return q


# ---------------------------------------------------------------- altar e templo

def altar():
    q = novo(16, 16)
    # pés de pedra
    for x0 in (3, 10):
        for y in range(11, 16):
            for x in range(x0, x0 + 3):
                put(q, x, y, 12 if x == x0 and y < 14 else 11 if x < x0 + 2 else 8)
    # laje
    for x in range(1, 15):
        put(q, x, 9, 12 if x < 13 else 11)
        put(q, x, 10, 11 if x < 14 else 8)
        put(q, x, 11, 8 if 2 < x < 13 and x not in (3, 4, 5, 10, 11, 12) else q[11][x])
    put(q, 0, 10, 8)
    put(q, 15, 10, 8)
    # oferendas: tigela com frutos e duas chamas
    for x in range(6, 10):
        put(q, x, 8, 9 if x in (6, 9) else 10)
    put(q, 7, 7, 20)
    put(q, 8, 7, 22)
    put(q, 7, 6, 21)
    for x in (2, 13):
        put(q, x, 8, 12)
        put(q, x, 7, 21)
        put(q, x, 6, 22)
    return q


def templo_parede():
    q = novo(32, 32)
    # degraus de pedra
    for y, (a, b) in zip(range(27, 32), ((4, 27), (3, 28), (3, 28), (2, 29), (2, 29))):
        for x in range(a, b + 1):
            c = 12 if y in (27, 29) else 11
            if x == b or y == 31:
                c = 8
            put(q, x, y, c)
    # paredes de pedra clara com colunas de madeira
    for y in range(15, 27):
        for x in range(6, 26):
            c = 12 if (x + (y // 3) * 2) % 6 else 11
            if (y - 15) % 3 == 2:
                c = 11
            if x >= 23 and pont(x, y, 0.5):
                c = 11
            put(q, x, y, c)
        for x in (6, 7, 24, 25):
            put(q, x, y, 9 if x in (6, 24) else 8)
    # porta em arco
    for y in range(19, 27):
        for x in range(13, 19):
            if y == 19 and x in (13, 18):
                continue
            put(q, x, y, 30 if 13 < x < 18 or y > 19 else 8)
    for x in range(13, 19):
        put(q, x, 18, 9)
    return q


def templo_telhado():
    q = novo(32, 32)
    t = telhado_palha(30, 12, 3, random.Random(204), cores=(16, 10, 9, 8))
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x + 1, y, c)
    return q


def templo_simbolo():
    """Símbolo no alto do templo (o sol). A tarefa de culturas troca este símbolo."""
    q = novo(32, 32)
    for dx, dy, c in ((0, 0, 22), (-1, 1, 22), (0, 1, 31), (1, 1, 22), (0, 2, 22), (-2, 1, 21), (2, 1, 21),
                      (0, -1, 21), (0, 3, 9), (0, 4, 9)):
        put(q, 15 + dx, 1 + dy, c)
    put(q, 16, 1, 22)
    put(q, 16, 2, 22)
    put(q, 16, 3, 9)
    put(q, 16, 4, 9)
    return q


# ---------------------------------------------------------------- habitante com enxada

CORES = dict(hab.CORES, Z=12, z=11, d=8, n=10)      # c = cabo (9), Z/z = lâmina

# Quadros de 12x12: o corpo ocupa as colunas 0-7, como nos outros habitantes, e a
# enxada usa as colunas 8-11. Assim o motor alinha todos pelo canto esquerdo.
TRABALHAR = [
    [".......Zzz..", "..hhhh.c....", ".hHHhhhc....", ".hhhSeSc....", "..hsSSSS....", "..TTTbS.....",
     ".sTTbT......", ".sTbTT......", "..bbbb......", "..l..L......", "..l..L......", ".ff..FF....."],
    ["............", "..hhhh......", ".hHHhhh.....", ".hhhSeS.....", "..hsSSS.....", "..TTTbSSc...",
     ".sTTbT...c..", ".sTbTT....c.", "..bbbb....c.", "..l...L....Z", ".l....L....z", "ff....FF...."],
    ["............", "............", "...hhhh.....", "..hHHhhh....", "..hhhhSe....", ".TTThsSS....",
     "TTbTTTSSc...", ".TTbTT...c..", "..bbbb....c.", "..l..L.....c", "..l..L.....c", ".ff..FF..dZz"],
    ["............", "............", "...hhhh.....", "..hHHhhh....", "..hhhhSe....", ".TTThsS.....",
     "TTbTTTSc....", ".TTbTT.c...n", "..bbbb..c...", "..l..L..c...", "..l..L...c..", ".ff..FF.dZz."],
]


def andar_com_enxada():
    """Enxada no ombro: o cabo sai da mão da frente e sobe para a frente, com a lâmina
    pendurada na ponta."""
    quadros = []
    cabo = [(8, 6), (8, 5), (9, 4), (9, 3), (10, 2), (10, 1)]
    for m in hab.andando(hab.CABECA_A, hab.TRONCO_A, hab.PERNAS):
        m = [list(l + "....") for l in m]
        for x, y in cabo:
            m[y][x] = "c"
        m[1][11], m[2][11], m[3][11] = "Z", "z", "z"
        m[7][7] = "S" if m[7][7] == "." else m[7][7]
        quadros.append(["".join(l) for l in m])
    return quadros


def pintar(moldes):
    return [[[None if ch == "." else CORES[ch] for ch in l] for l in m] for m in moldes]


# ---------------------------------------------------------------- saída

def gerar():
    pecas = {
        "roca_arada": roca("arada"),
        "roca_broto": roca("broto"),
        "roca_crescida": roca("crescida"),
        "roca_madura": roca("madura"),
        "roca_seca": roca("seca"),
        "casa_taipa_parede": casa_parede(),
        "casa_taipa_telhado": casa_telhado(),
        "celeiro": celeiro(),
        "cerca": cerca(),
        "cerca_poste": cerca(False),
        "altar": altar(),
        "templo_parede": templo_parede(),
        "templo_telhado": templo_telhado(),
        "templo_simbolo": templo_simbolo(),
    }
    pecas["casa_taipa"] = sobrepor(pecas["casa_taipa_parede"], pecas["casa_taipa_telhado"])
    pecas["templo"] = sobrepor(sobrepor(pecas["templo_parede"], pecas["templo_telhado"]), pecas["templo_simbolo"])
    folhas = {
        "adulto_enxada_andar_4q": pintar(andar_com_enxada()),
        "adulto_enxada_trabalhar_4q": pintar(TRABALHAR),
    }
    return pecas, folhas


def amostra(pecas, folhas):
    """As peças sobre o chão da cena (blocos de grama e terra), de dia."""
    terreno = AQUI.parent / "terreno"
    grama = Image.open(terreno / "grama_a.png")
    terra = Image.open(terreno / "terra_a.png")
    W, H = 336, 64
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    chao = 48
    for x in range(0, W, 8):
        img.alpha_composite(grama, (x, chao - 2))
        img.alpha_composite(terra, (x, chao + 6))
        img.alpha_composite(terra, (x, chao + 14))
    x = 4
    for nome in ("roca_arada", "roca_broto", "roca_crescida", "roca_madura", "roca_seca"):
        img.alpha_composite(para_imagem(pecas[nome]), (x, chao - 15))
        x += 16
    x += 4
    for nome in ("casa_taipa", "celeiro"):
        img.alpha_composite(para_imagem(pecas[nome]), (x, chao - 23))
        x += 26
    for i in range(3):
        img.alpha_composite(para_imagem(pecas["cerca"]), (x + i * 8, chao - 7))
    img.alpha_composite(para_imagem(pecas["cerca_poste"]), (x + 24, chao - 7))
    x += 34
    img.alpha_composite(para_imagem(pecas["altar"]), (x, chao - 15))
    x += 18
    img.alpha_composite(para_imagem(pecas["templo"]), (x, chao - 31))
    x += 34
    for nome in ("adulto_enxada_andar_4q", "adulto_enxada_trabalhar_4q"):
        for q in folhas[nome]:
            img.alpha_composite(para_imagem(q), (x, chao - 11))
            x += 13
    # partes separadas embaixo, para conferência
    return img


def principal():
    pecas, folhas = gerar()
    for nome, px in pecas.items():
        gravar(px, AQUI / f"{nome}.png")
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    img = amostra(pecas, folhas)
    img.save(AQUI / "amostra_estagio2.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_estagio2_4x.png")
    print("estágio 2:", ", ".join(f"{n} {len(p[0])}x{len(p)}" for n, p in pecas.items()))


if __name__ == "__main__":
    principal()

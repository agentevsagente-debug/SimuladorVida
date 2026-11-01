"""Ferramentas comuns para as construções e os habitantes dos estágios 3 a 6.

- paredes, portas, janelas e telhados (os 3 telhados de cultura vêm de `culturas/`);
- `arruinar`: transforma qualquer construção na sua ruína (topo quebrado, buracos,
  telhado caído, entulho e mato), para cada estágio ter as ruínas das próprias peças;
- `vestir`: monta habitantes com a roupa de cada estágio sobre os moldes de `habitantes/`.
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

PECAS = Path(__file__).resolve().parent
for sub in ("", "culturas", "habitantes", "estagio2", "terreno"):
    sys.path.insert(0, str(PECAS / sub))

from comum import PALETA, folha_quadros, gravar, para_imagem, pont, trocar  # noqa: E402,F401
import culturas  # noqa: E402
import habitantes as hab  # noqa: E402

CULTURAS = culturas.TELHADOS          # palha, telha, tabuas
SIMBOLOS = culturas.SIMBOLOS          # sol, lua, arvore


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if c is not None and 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


def linha(q, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        put(q, round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)


def sobrepor(*camadas):
    out = [l[:] for l in camadas[0]]
    for cam in camadas[1:]:
        for y, l in enumerate(cam):
            for x, c in enumerate(l):
                if c is not None:
                    out[y][x] = c
    return out


def retangulo(q, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(q, x, y, c)


# ---------------------------------------------------------------- paredes

def cor_material(material, x, y, x0, x1, y0, rng):
    if material in ("taipa", "pedra", "madeira"):
        return culturas.cor_parede(material, x, y, x0, x1, y0, rng)
    if material == "pedra_lavrada":           # blocos grandes e regulares
        fiada = (y - y0) // 4
        if (y - y0) % 4 == 0 or (x + fiada * 4) % 8 == 0:
            return 11 if x < x1 - 1 else 8
        if x >= x1 - 1 or (y - y0) % 4 == 3:
            return 11
        return 12
    if material == "tijolo":
        fiada = (y - y0) // 2
        if (y - y0) % 2 == 0 or (x + fiada * 2) % 4 == 0:
            return 12 if x < x1 - 1 else 11  # argamassa clara
        return 24 if x < x1 - 2 else 23
    if material == "enxaimel":                # madeira aparente com reboco claro
        if x in (x0, x1) or (y - y0) % 6 == 0 or (x - x0) % 7 == 0:
            return 9 if x < x1 else 8
        if (x - x0 - (y - y0)) % 7 == 0 and (y - y0) % 6 < 6:
            return 9
        return 12 if x < x1 - 2 else 11
    raise ValueError(material)


def parede(q, x0, y0, x1, y1, material, semente=0):
    rng = random.Random(semente)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(q, x, y, cor_material(material, x, y, x0, x1, y0, rng))
    for x in range(x0, x1 + 1):
        put(q, x, y1, 8)


def porta(q, x0, y0, x1, y1, arco=False, moldura=9):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if arco and y == y0 and x in (x0, x1):
                continue
            put(q, x, y, 30)
    for x in range(x0 - 1, x1 + 2):
        if not arco or x in (x0 - 1, x1 + 1):
            put(q, x, y0 - 1, moldura)
    if arco:
        for x in range(x0, x1 + 1):
            put(q, x, y0 - 1 if x in (x0, x1) else y0 - 2, moldura)


def janela(q, x0, y0, larg=3, alt=3, peitoril=9, luz=False):
    for y in range(y0, y0 + alt):
        for x in range(x0, x0 + larg):
            put(q, x, y, 22 if luz else 30)
    for x in range(x0 - 1, x0 + larg + 1):
        put(q, x, y0 + alt, peitoril)
        put(q, x, y0 - 1, 8)


def telhado(q, estilo, x0, larg, topo, alt, semente=0):
    """Telhado de cultura (palha, telha ou tábuas) sobre a peça q, com o canto em x0."""
    t = culturas.telhado(estilo, larg, topo, alt, random.Random(semente))
    for y, l in enumerate(t):
        for x, c in enumerate(l):
            put(q, x0 + x, y, c)
    cx = x0 + larg // 2 - 1
    if estilo == "tabuas":
        put(q, cx, topo - 1, 10)
        put(q, cx + 1, topo - 1, 9)
    elif estilo == "telha":
        for x in range(cx - 1, cx + 3):
            put(q, x, topo - 1, 23)
    else:
        put(q, cx, topo - 1, 9)
        put(q, cx + 1, topo - 1, 9)


def simbolo_em(q, nome, cx, base_y):
    """Põe o símbolo de cultura (de `culturas/`) com o mastro terminando em base_y."""
    s = culturas.simbolo(nome)
    for y in range(6):
        for x in range(32):
            c = s[y][x]
            if c is not None:
                put(q, cx - 15 + x, base_y - 5 + y, c)


# ---------------------------------------------------------------- ruína

def arruinar(q, semente, telhado_ate=None):
    """Ruína de qualquer construção: o telhado (linhas acima de `telhado_ate`) cai e
    sobram caibros; o topo da parede quebra em degraus; aparecem buracos, entulho e mato."""
    rng = random.Random(semente)
    h, w = len(q), len(q[0])
    out = novo(w, h)
    ocupadas = [x for x in range(w) if any(q[y][x] is not None for y in range(h))]
    if not ocupadas:
        return out
    topo_original = min(y for y in range(h) for x in range(w) if q[y][x] is not None)
    corte_base = telhado_ate if telhado_ate is not None else topo_original + (h - topo_original) // 3
    perfil = [corte_base + int(abs(math.sin(x * 0.6 + semente)) * 4) + rng.randint(0, 2) for x in range(w)]
    for y in range(h):
        for x in range(w):
            c = q[y][x]
            if c is None or y < perfil[x]:
                continue
            if c in (22, 21, 20, 31) and y < h - 2:
                c = 30                          # janelas e fogos apagados
            elif c in (10, 12, 16) and rng.random() < 0.25:
                c = {10: 9, 12: 11, 16: 10}[c]  # desbotado
            out[y][x] = c
    # caibros que sobraram
    if telhado_ate is not None:
        meio = w // 2
        for i in range(min(8, telhado_ate)):
            put(out, meio - 6 + i, telhado_ate - i, 9)
            put(out, meio + 5 - i // 2, telhado_ate - i, 8)
    # buracos
    for _ in range(max(1, w // 12)):
        cx, cy = rng.randint(3, w - 4), rng.randint(max(corte_base + 3, 0), h - 4)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 1), (1, -1)):
            if out[cy + dy][cx + dx] is not None:
                put(out, cx + dx, cy + dy, 30)
    # entulho e mato
    for x in range(w):
        if rng.random() < 0.55:
            put(out, x, h - 1, rng.choice((11, 12, 9, 8)))
        if rng.random() < 0.25:
            put(out, x, h - 2, rng.choice((11, 9)))
        if rng.random() < 0.18:
            for k in range(rng.randint(1, 3)):
                put(out, x, h - 1 - k, 15 if k else 14)
    return out


# ---------------------------------------------------------------- habitantes

CORES = dict(hab.CORES, Z=12, z=11, d=8, n=10, m=21, M=24, k=20, K=22, w=31, q=23, o=9, j=19)


def vestir(moldes, sobreposicoes):
    """Aplica sobreposições {(x, y): caractere} a cada molde (lista de linhas)."""
    out = []
    for i, m in enumerate(moldes):
        m = [list(l) for l in m]
        sob = sobreposicoes[i] if isinstance(sobreposicoes, list) else sobreposicoes
        for (x, y), ch in sob.items():
            if 0 <= y < len(m) and 0 <= x < len(m[0]):
                m[y][x] = ch
        out.append(["".join(l) for l in m])
    return out


def alargar(moldes, colunas=4):
    return [[l + "." * colunas for l in m] for m in moldes]


def pintar(moldes):
    return [[[None if ch == "." else CORES[ch] for ch in l] for l in m] for m in moldes]


def amostra_pecas(itens, largura, altura=None, chao_y=None, escala=4, saida=None):
    """Folha de amostra: as peças sobre o chão da cena (grama e terra), lado a lado."""
    terr = PECAS / "terreno"
    grama = Image.open(terr / "grama_a.png")
    terra = Image.open(terr / "terra_a.png")
    alt_max = max(len(p) for _, p in itens)
    altura = altura or alt_max + 24
    chao = chao_y or altura - 14
    img = Image.new("RGBA", (largura, altura), PALETA[1] + (255,))
    for x in range(0, largura, 8):
        img.alpha_composite(grama, (x, chao - 2))
        img.alpha_composite(terra, (x, chao + 6))
    x = 4
    for _, p in itens:
        im = para_imagem(p)
        img.alpha_composite(im, (x, chao - im.height + 1))
        x += im.width + 4
    if saida:
        img.save(saida)
        img.resize((img.width * escala, img.height * escala), Image.NEAREST).save(
            saida.with_name(saida.stem + "_4x.png"))
    return img

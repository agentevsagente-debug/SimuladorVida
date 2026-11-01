"""Estações do ano. O verão é a arte de sempre; aqui saem as outras três.

Saída em `estacoes/<estacao>/<pasta>/<nome>.png`, com o mesmo nome, tamanho e encaixe
da peça original. O motor troca a pasta conforme a estação, e o que não tiver variação
usa a peça de verão.

- primavera: flores nas copas, nos arbustos, no capim e na borda da grama;
- outono: copas largas e arbustos alaranjados, capim e grama secando, folhas no chão;
- inverno: árvores de copa sem folhas, neve em cima de tudo (pinheiros, telhados,
  pedras, grama), montanhas com mais neve, lago congelado na borda.

Efeitos novos em `efeitos/`: neve caindo (`neve_4q`) e flocos (`floco_3v`).
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(PECAS / "montagem"))

from comum import PALETA, folha_quadros, gravar, pont  # noqa: E402

ESTACOES = ("primavera", "outono", "inverno")
INDICE = {rgb: i for i, rgb in enumerate(PALETA)}


def ler(caminho):
    img = Image.open(caminho).convert("RGBA")
    px = list(img.getdata())
    return [[None if px[y * img.width + x][3] == 0 else INDICE[px[y * img.width + x][:3]]
             for x in range(img.width)] for y in range(img.height)]


def h(x, y, s=0):
    """Sorteio fixo por pixel (mesmo resultado sempre)."""
    return ((x * 73856093) ^ (y * 19349663) ^ (s * 83492791)) % 997 / 997


# ---------------------------------------------------------------- transformações

def mapear(px, mapa):
    return [[mapa.get(c, c) if c is not None else None for c in l] for l in px]


def flores(px, cores=(31, 7, 22), taxa=0.08, so=(15, 16), semente=1):
    out = [l[:] for l in px]
    for y, l in enumerate(px):
        for x, c in enumerate(l):
            if c in so and h(x, y, semente) < taxa:
                out[y][x] = cores[int(h(y, x, semente) * len(cores))]
    return out


def neve_por_cima(px, grossa=True, claro=31, sombra=0):
    """Neve assentada: o pixel exposto para cima vira neve, e o de baixo vira neve
    pontilhada (se a neve for grossa). Vale para copas, telhados, pedras e grama."""
    hgt, w = len(px), len(px[0])
    out = [l[:] for l in px]
    for x in range(w):
        for y in range(hgt):
            if px[y][x] is None:
                continue
            exposto = y == 0 or px[y - 1][x] is None
            if not exposto:
                continue
            out[y][x] = claro
            if grossa and y + 1 < hgt and px[y + 1][x] is not None:
                out[y + 1][x] = claro if x % 3 else sombra
                if y + 2 < hgt and px[y + 2][x] is not None and pont(x, y + 2, 0.5):
                    out[y + 2][x] = sombra
    return out


OUTONO_COPA = {16: 22, 15: 21, 14: 24, 13: 23}
OUTONO_CAPIM = {15: 16, 14: 10, 13: 9}
OUTONO_GRAMA = {15: 16, 14: 15, 13: 14}


def outono_copa(px, semente=2):
    out = mapear(px, OUTONO_COPA)
    for y, l in enumerate(px):
        for x, c in enumerate(l):
            if c in (14, 15) and h(x, y, semente) < 0.12:
                out[y][x] = 16                 # algumas folhas ainda amarelando
    return out


def arvore_nua(w, hh, tronco_x, alt, semente):
    """Árvore de copa no inverno: tronco e galhos nus no mesmo encaixe da árvore de verão,
    com neve nos galhos."""
    rng = random.Random(semente)
    q = [[None] * w for _ in range(hh)]
    base = hh - 1

    def put(x, y, c):
        if 0 <= x < w and 0 <= y < hh:
            q[y][x] = c

    def linha(x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            put(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)

    topo_tronco = base - alt // 2
    for y in range(topo_tronco, base + 1):
        put(tronco_x, y, 9)
        put(tronco_x + 1, y, 9 if y < base - 3 else 8)
        put(tronco_x + 2, y, 8)
    put(tronco_x - 1, base, 9)
    put(tronco_x + 3, base, 8)
    alto = base - alt + 2
    galhos = [(-0.9, 0.55), (-0.45, 0.85), (0.1, 1.0), (0.55, 0.8), (1.0, 0.5)]
    for dx, dy in galhos:
        comp = alt * 0.55
        x0, y0 = tronco_x + 1, topo_tronco + 1
        x1, y1 = round(x0 + dx * comp), round(max(alto, y0 - dy * comp))
        linha(x0, y0, x1, y1, 9 if dx < 0.3 else 8)
        for _ in range(2):
            t = rng.uniform(0.45, 0.8)
            mx, my = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            linha(round(mx), round(my), round(mx + rng.choice((-1, 1)) * rng.randint(2, 4)),
                  round(my - rng.randint(2, 4)), 30 if dx > 0.3 else 8)
    return neve_por_cima(q, grossa=False)


# ---------------------------------------------------------------- catálogo

VEGETACAO_COPA = {"arvore_copa_a", "arvore_copa_b", "arbusto", "arbusto_frutas"}
PINHEIROS = {"pinheiro_a", "pinheiro_b", "pinheiro_fundo"}
ARVORES_NUAS = {"arvore_copa_a": (19, 30, 21), "arvore_copa_b": (14, 24, 22)}
GRAMAS = {"grama_a", "grama_b", "grama_seca", "chao_batido", "areia_superficie"}
SEM_NEVE = ("adulto_", "guerreiro", "ferreiro", "escriba", "crianca", "idoso", "amostra", "tabuletas",
            "variacoes", "canal", "fogueira_acesa", "forja_2q", "forja.png")
PASTAS_CONSTRUCAO = ("estagio1", "estagio2", "estagio3", "estagio4", "estagio5", "estagio6", "culturas", "memoria")


def variante(pasta, nome, px, estacao):
    """Devolve a peça na estação, ou None se ela não muda."""
    if pasta == "terreno":
        if nome not in GRAMAS:
            return None
        if estacao == "primavera":
            if nome in ("grama_a", "grama_b"):
                return flores(px, taxa=0.3, so=(15,), semente=3)
            return None
        if estacao == "outono":
            if nome == "areia_superficie":
                return None
            out = mapear(px, OUTONO_GRAMA)
            for x in range(8):
                if h(x, 2, 4) < 0.25:
                    out[2][x] = 21 if h(x, 3, 4) < 0.5 else 24      # folhas caídas
            return out
        # inverno: neve na superfície (a superfície fica na linha 2, ou 0 na areia)
        out = [l[:] for l in px]
        topo = 0 if nome == "areia_superficie" else 2
        for x in range(8):
            for y in range(0, topo):
                if out[y][x] is not None:
                    out[y][x] = 31
            out[topo][x] = 31
            out[topo + 1][x] = 0 if pont(x, topo + 1, 0.5) else 31
            if out[topo + 2][x] in (13, 14):
                out[topo + 2][x] = 0 if x % 2 else 13
        return out
    if pasta == "estagio1":
        if estacao == "primavera":
            if nome in VEGETACAO_COPA:
                return flores(mapear(px, {13: 14}), taxa=0.2, so=(15, 16, 14), semente=5)
            if nome == "capim":
                return flores(px, cores=(22, 7, 31), taxa=0.25, so=(15,), semente=6)
            return None
        if estacao == "outono":
            if nome in VEGETACAO_COPA:
                return outono_copa(px)
            if nome == "capim":
                return mapear(px, OUTONO_CAPIM)
            if nome == "cabana_galhos":
                return mapear(px, {15: 16, 14: 10, 13: 9})
            return None
        if nome in ARVORES_NUAS:
            tx, alt, s = ARVORES_NUAS[nome]
            return arvore_nua(len(px[0]), len(px), tx, alt, s)
        if nome in ("arbusto", "arbusto_frutas"):
            return neve_por_cima(mapear(px, {15: 13, 16: 13, 14: 13, 27: 13, 20: 13}))
        if nome in ("capim", "capim_seco", "alga", "juncos"):
            return neve_por_cima(mapear(px, OUTONO_CAPIM), grossa=False) if nome != "alga" else None
        if nome.startswith(("fogueira", "samambaia")):
            return None
        return neve_por_cima(px, grossa=nome not in PINHEIROS or True)
    # construções dos estágios, culturas e memória: só o inverno muda (neve por cima)
    if estacao != "inverno" or nome.startswith(SEM_NEVE) or (nome + ".png").startswith(SEM_NEVE):
        return None
    if nome.startswith(("roca_", "cerca")):
        return neve_por_cima(px, grossa=False)
    return neve_por_cima(px)


# ---------------------------------------------------------------- montanhas e gelo

def montanha_inverno(px, profundidade, hora):
    """Mais neve: uma calota que segue a crista de cada montanha, com `profundidade` px e a
    borda de baixo pontilhada. Branca do lado da luz, azul-clara na sombra."""
    claro, sombra = (31, 0) if hora != "noite" else (12, 5)
    luz = {"dia": {1: True, 18: True, 14: True, 2: False, 17: False, 13: False},
           "entardecer": {7: True, 5: False, 4: False, 3: False},
           "noite": {5: True, 4: False, 3: False, 30: False}}[hora]
    out = [l[:] for l in px]
    for x in range(len(px[0])):
        topo = next((y for y in range(len(px)) if px[y][x] is not None), None)
        if topo is None:
            continue
        for y in range(topo, min(len(px), topo + profundidade + 4)):
            c = px[y][x]
            if c is None or c in (31, 0):
                continue
            f = (topo + profundidade + 4 - y) / 6
            if y < topo + profundidade - 2 or pont(x, y, max(0.0, min(1.0, f))):
                out[y][x] = claro if luz.get(c, True) else sombra
    return out


def gelo():
    """Superfície do lago congelada (8x8), para as colunas de água perto da margem."""
    q = [[None] * 8 for _ in range(8)]
    for x in range(8):
        q[0][x] = 31 if x % 5 else None
        q[1][x] = 31
        q[2][x] = 0
        q[3][x] = 0 if x % 3 else 19
        for y in range(4, 8):
            q[y][x] = 18 if not (x + y) % 7 == 0 else 19
    q[3][5] = 12
    q[4][6] = 12                               # rachadura no gelo
    return q


def neve_caindo():
    """Neve caindo, 64x64 que repete nas duas direções, 4 quadros (descem 2 px e
    balançam 1 px por quadro)."""
    n = 64
    rng = random.Random(601)
    flocos = [(rng.randrange(n), rng.randrange(n), rng.random() < 0.25) for _ in range(34)]
    quadros = []
    for k in range(4):
        q = [[None] * n for _ in range(n)]
        for x0, y0, grande in flocos:
            y = (y0 + k * 2) % n
            x = (x0 + (1 if (y0 + k) % 4 < 2 else 0)) % n
            q[y][x] = 31
            if grande:
                q[y][(x + 1) % n] = 0
                q[(y + 1) % n][x] = 0
        quadros.append(q)
    return quadros


def flocos():
    out = []
    for f in ([(1, 1, 31)], [(1, 1, 31), (2, 1, 0), (1, 2, 0)], [(1, 0, 0), (0, 1, 0), (1, 1, 31), (2, 1, 0), (1, 2, 0)]):
        q = [[None] * 4 for _ in range(4)]
        for x, y, c in f:
            q[y][x] = c
        out.append(q)
    return out


def principal():
    contagem = {e: 0 for e in ESTACOES}
    for pasta in ("terreno",) + PASTAS_CONSTRUCAO:
        for f in sorted((PECAS / pasta).glob("*.png")):
            px = ler(f)
            for est in ESTACOES:
                v = variante(pasta, f.stem, px, est)
                if v is not None:
                    gravar(v, AQUI / est / pasta / f.name, ampliar=False)
                    contagem[est] += 1
    # montanhas, mata e gelo
    linhas = {"montanhas_longe": 16, "montanhas_perto": 6, "mata_distante": 0}
    for nome, ln in linhas.items():
        for hora in ("entardecer", "dia", "noite"):
            px = ler(PECAS / "montagem" / f"{nome}_{hora}.png")
            v = montanha_inverno(px, ln, hora) if nome != "mata_distante" else neve_por_cima(
                px, grossa=False, claro=31 if hora != "noite" else 12, sombra=0 if hora != "noite" else 5)
            gravar(v, AQUI / "inverno" / "montagem" / f"{nome}_{hora}.png", ampliar=False)
            contagem["inverno"] += 1
    # outono: a mata distante amarela e enferruja
    for hora, mapa in (("dia", {14: 24, 13: 23}), ("entardecer", {}), ("noite", {})):
        if mapa:
            px = ler(PECAS / "montagem" / f"mata_distante_{hora}.png")
            gravar(mapear(px, mapa), AQUI / "outono" / "montagem" / f"mata_distante_{hora}.png", ampliar=False)
    gravar(gelo(), AQUI / "inverno" / "terreno" / "gelo_superficie.png", ampliar=False)
    gravar(folha_quadros(neve_caindo()), PECAS / "efeitos" / "neve_4q.png")
    gravar(folha_quadros(flocos()), PECAS / "efeitos" / "floco_3v.png")
    print("estações:", contagem)


if __name__ == "__main__":
    principal()

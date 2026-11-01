"""Mundo vazio: a natureza retomando o que o povo deixou.

- toda ruína ganha 3 graus de mato e trepadeiras (`<ruina>_mato_1` a `_mato_3`), com o
  mesmo tamanho e encaixe da ruína;
- árvores jovens nascendo onde havia casas: muda, árvore jovem e pinheiro jovem;
- a fogueira apagada há muito tempo: pedras meio enterradas e capim por dentro.
"""
from pathlib import Path
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))

from comum import Deslocada, Folha, PALETA, cena, gravar, para_imagem, pont  # noqa: E402

INDICE = {rgb: i for i, rgb in enumerate(PALETA)}

RUINAS = [
    "memoria/cabana_abandonada", "memoria/casa_ruina", "estagio3/casa_pedra_ruina", "estagio3/templo_pedra_ruina",
    "estagio4/forja_ruina", "estagio4/casa_enxaimel_ruina", "estagio4/templo_colunas_ruina",
    "estagio5/biblioteca_ruina", "estagio5/casa_caiada_ruina", "estagio5/templo_escrita_ruina", "estagio6/moinho_ruina",
    "estagio6/muralha_ruina", "estagio6/muralha_torre_ruina", "estagio6/casa_tijolo_ruina",
    "estagio6/templo_cupula_ruina", "estagio6/barco_naufragado", "memoria/tumulo", "memoria/pedra_erguida",
]


def ler(caminho):
    img = Image.open(caminho).convert("RGBA")
    px = list(img.getdata())
    return [[None if px[y * img.width + x][3] == 0 else INDICE[px[y * img.width + x][:3]]
             for x in range(img.width)] for y in range(img.height)]


def cobrir(px, grau, semente):
    """Grau 1: capim na base e as primeiras trepadeiras. Grau 2: trepadeiras até o meio e
    musgo nos topos. Grau 3: trepadeiras por quase tudo, musgo e uma muda brotando em cima."""
    rng = random.Random(semente * 10 + grau)
    h, w = len(px), len(px[0])
    out = [l[:] for l in px]
    ocupado = lambda x, y: 0 <= x < w and 0 <= y < h and px[y][x] is not None  # noqa: E731
    topo = min((y for y in range(h) for x in range(w) if px[y][x] is not None), default=h - 1)
    altura = h - topo
    # capim na base
    for x in range(w):
        if rng.random() < (0.3, 0.55, 0.8)[grau - 1]:
            for k in range(rng.randint(1, 1 + grau)):
                if h - 1 - k >= 0:
                    out[h - 1 - k][x] = 15 if k == 0 or rng.random() < 0.3 else 14
    # trepadeiras subindo
    n = max(1, w * (1, 3, 7)[grau - 1] // 12)
    for _ in range(n):
        x = rng.randrange(w)
        alcance = int(altura * (0.35, 0.65, 0.95)[grau - 1] * rng.uniform(0.7, 1.0))
        y = h - 1
        for _ in range(alcance):
            if not ocupado(x, y):
                # procura parede ao lado para se agarrar
                for dx in (-1, 1):
                    if ocupado(x + dx, y):
                        x += dx
                        break
            if ocupado(x, y) or y >= h - 2:
                out[y][x] = 13 if rng.random() < 0.6 else 14
                if rng.random() < 0.65:
                    lado = x + rng.choice((-1, 1))
                    if ocupado(lado, y):
                        out[y][lado] = 15 if rng.random() < 0.5 else 14
            y -= 1
            if rng.random() < 0.3:
                x += rng.choice((-1, 1))
            x = max(0, min(w - 1, x))
            if y < 0:
                break
    # moitas encostadas na base
    if grau >= 2:
        for _ in range(w // (10 if grau == 2 else 5)):
            cx, r = rng.randrange(w), rng.uniform(1.5, 2.5 + grau * 0.5)
            for y in range(h - 1, max(-1, h - 1 - int(r * 1.6)), -1):
                for x in range(int(cx - r), int(cx + r) + 1):
                    if 0 <= x < w and (x - cx) ** 2 + ((y - (h - 1)) * 0.9) ** 2 <= r * r:
                        out[y][x] = 15 if (y - (h - 1)) < -r * 0.8 or (x < cx and pont(x, y, 0.4)) else 14 if x < cx + 1 else 13
    # musgo nos topos expostos
    if grau >= 2:
        for x in range(w):
            for y in range(h):
                if px[y][x] is not None and (y == 0 or px[y - 1][x] is None):
                    if rng.random() < (0, 0.35, 0.7)[grau - 1]:
                        out[y][x] = 15 if rng.random() < 0.5 else 14
                    break
    # uma muda no alto (grau 3)
    if grau == 3:
        cols = [x for x in range(2, w - 2) if any(px[y][x] is not None for y in range(h))]
        if cols:
            x = rng.choice(cols)
            y = next(y for y in range(h) if px[y][x] is not None)
            for k, c in ((1, 9), (2, 9), (3, 14), (4, 15)):
                if y - k >= 0:
                    out[y - k][x] = c
            for dx, dy, c in ((-1, 3, 15), (1, 3, 14), (-1, 4, 14), (1, 2, 15)):
                if 0 <= x + dx < w and y - dy >= 0:
                    out[y - dy][x + dx] = c
    return out


def peca(w, h, desenhar):
    f = Folha(w, h)
    desenhar(Deslocada(f))
    return f.recortar()


def muda(t):
    for y, c in ((7, 9), (6, 9), (5, 14)):
        t.put(4, y, c)
    for x, y, c in ((3, 4, 15), (5, 4, 14), (4, 3, 15), (2, 5, 14), (6, 5, 13), (4, 4, 14)):
        t.put(x, y, c)


def fogueira_antiga():
    q = [[None] * 16 for _ in range(16)]
    for x, c in ((2, 11), (3, 12), (5, 11), (10, 11), (12, 12), (13, 11)):
        q[15][x] = c
        if x in (3, 12):
            q[14][x] = 12
    for x in (7, 8):
        q[15][x] = 30
    q[15][9] = 8
    rng = random.Random(701)
    for x in range(1, 15):
        if rng.random() < 0.6:
            for k in range(rng.randint(1, 3)):
                q[15 - k][x] = q[15 - k][x] if q[15 - k][x] in (11, 12) and k == 0 else (15 if k else 14)
    return q


def principal():
    graus = {}
    for r in RUINAS:
        px = ler(PECAS / f"{r}.png")
        nome = Path(r).name
        for g in (1, 2, 3):
            v = cobrir(px, g, len(nome) + g)
            gravar(v, AQUI / f"{nome}_mato_{g}.png")
            graus[(nome, g)] = v
    jovens = {
        "muda": peca(8, 8, muda),
        "arvore_jovem": peca(16, 16, lambda t: cena.arvore_larga(t, 6, 15, 13, random.Random(702))),
        "pinheiro_jovem": peca(16, 16, lambda t: cena.pinheiro(t, 7, 15, 14, random.Random(703))),
        "fogueira_antiga": fogueira_antiga(),
    }
    for nome, px in jovens.items():
        gravar(px, AQUI / f"{nome}.png")
    # amostra: algumas ruínas nos 3 graus, mais as árvores jovens
    from construcao import amostra_pecas
    itens = []
    for nome in ("casa_ruina", "casa_pedra_ruina", "templo_colunas_ruina", "casa_tijolo_ruina"):
        caminho = next(r for r in RUINAS if r.endswith(nome))
        itens.append((nome, ler(PECAS / f"{caminho}.png")))
        itens += [(nome, graus[(nome, g)]) for g in (1, 2, 3)]
    amostra_pecas(itens, 4 + sum(len(p[0]) + 4 for _, p in itens), saida=AQUI / "amostra_natureza.png")
    amostra_pecas(list(jovens.items()), 80, saida=AQUI / "amostra_natureza_jovens.png")
    print("natureza:", len(RUINAS), "ruínas x 3 graus,", ", ".join(jovens))


if __name__ == "__main__":
    principal()

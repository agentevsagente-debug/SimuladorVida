"""Nuvens soltas para o céu vivo, e os céus de tempestade e de dilúvio.

- `nuvem_<clima>_<camada>_<p|m|g>.png`: 5 climas (dia, entardecer, noite, tempestade, seca)
  x 3 camadas de profundidade (longe, meio, perto) x 3 tamanhos. Corpo de vários
  "puffs" com base reta, luz em cima à esquerda e sombra embaixo, e fiapos curtos e
  irregulares sob a base (nunca uma linha pontilhada). Longe: menor, mais achatada e com
  menos contraste; perto: maior e mais marcada.
- `../montagem/ceu_tempestade.png` e `ceu_diluvio.png`: céus de 480x160 para o motor usar
  enquanto chove (tempestade) e no dilúvio (mais escuro e carregado).
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))

from comum import PALETA, cena, gravar, para_imagem, pont  # noqa: E402

TAMANHOS = {  # (largura, altura) de p, m, g por camada
    "longe": [(16, 8), (24, 8), (32, 8)],
    "meio": [(24, 8), (32, 12), (48, 12)],
    "perto": [(32, 12), (48, 16), (64, 16)],
}
# (luz, corpo, sombra, fiapo) por clima e camada
CORES = {
    "dia": {"longe": (0, 19, 19, 0), "meio": (31, 0, 19, 0), "perto": (31, 0, 1, 0)},
    "entardecer": {"longe": (6, 6, 5, 6), "meio": (6, 7, 5, 7), "perto": (22, 6, 7, 6)},
    "noite": {"longe": (4, 4, 3, 4), "meio": (5, 4, 3, 4), "perto": (5, 5, 4, 5)},
    "tempestade": {"longe": (5, 4, 3, 4), "meio": (11, 5, 4, 4), "perto": (11, 5, 3, 17)},
    "seca": {"longe": (12, 16, 16, 12), "meio": (31, 12, 16, 12), "perto": (31, 12, 16, 12)},
}


def nuvem(w, h, cores, semente, camada, clima):
    rng = random.Random(semente)
    luz, corpo, sombra, fio = cores
    q = [[None] * w for _ in range(h)]
    alt_corpo = h - (2 if camada != "longe" else 1) - (2 if clima == "tempestade" else 0)
    base = alt_corpo - 1
    n = max(2, w // 10)
    puffs = []
    for i in range(n):
        px = 3 + (i + 0.5) * (w - 6) / n + rng.uniform(-1.5, 1.5)
        pr = (w - 6) / n * rng.uniform(0.7, 1.05)
        meio = 1 - abs(i - (n - 1) / 2) / max(1, n)
        ph = (base - 0.5) * rng.uniform(0.75, 1.0) * (0.65 + 0.35 * meio) * (0.85 if camada == "longe" else 1)
        puffs.append((px, pr, ph))
    topo = []
    for x in range(w):
        t = None
        for px, pr, ph in puffs:
            u = (x - px) / pr
            if abs(u) < 1:
                hh = ph * math.sqrt(1 - u * u)
                t = hh if t is None else max(t, hh)
        topo.append(None if t is None or t < 0.6 else int(round(base - t)))
    for x in range(w):
        if topo[x] is None:
            continue
        # as pontas da base sobem um pouco: nada de quina reta
        fim = base - (1 if (x == 0 or topo[x - 1] is None or x == w - 1 or topo[min(w - 1, x + 1)] is None) else 0)
        for y in range(max(0, topo[x]), fim + 1):
            d = y - topo[x]
            if d == 0 or (d == 1 and x < w * 0.45):
                c = luz
            elif y >= fim:
                c = sombra
            elif y == fim - 1 and x > w * 0.4 and rng.random() < 0.35:
                c = sombra
            else:
                c = corpo
            q[y][x] = c
    # fiapos: traços curtos sob a base, de 2 a 6 px, separados por vãos sorteados
    cheios = [x for x in range(w) if topo[x] is not None]
    if cheios:
        y = base + 1
        x = cheios[0] + rng.randint(0, 3)
        while x < cheios[-1] + 4 and y < h:
            comp = rng.randint(2, 6 if camada != "longe" else 3)
            for i in range(comp):
                if 0 <= x + i < w:
                    q[y][x + i] = fio
            x += comp + rng.randint(3, 8)
        if camada == "perto" and y + 1 < h:
            x = cheios[0] + rng.randint(4, 8)
            while x < cheios[-1] - 2:
                comp = rng.randint(2, 4)
                for i in range(comp):
                    if 0 <= x + i < w:
                        q[y + 1][x + i] = fio
                x += comp + rng.randint(6, 12)
    if clima == "tempestade":
        # chuva saindo da base em riscos curtos, em colunas sorteadas
        for x in range(2, w - 2):
            if topo[x] is not None and rng.random() < 0.18:
                for i in range(rng.randint(1, 2)):
                    if base + 1 + i < h:
                        q[base + 1 + i][x] = 18 if i else 17
    return q


def ceu_tempestade(diluvio=False):
    """Céu carregado, sem sol: degradê escuro (mais escuro no dilúvio) coberto por nuvens
    pesadas de tempestade, feitas com as mesmas nuvens soltas (sem fiapo pontilhado)."""
    t = cena.Tela()
    if diluvio:
        cfg = {"ceu": [3, 4, 5], "faixas": [(56, 14), (100, 10)]}
    else:
        cfg = {"ceu": [3, 4, 5, 11], "faixas": [(28, 14), (68, 12), (106, 8)]}
    cena.pintar_ceu(t, cfg, None)
    rng = random.Random(611 if diluvio else 612)
    lista = []
    for linha, (camada, y0) in enumerate((("meio", 30), ("perto", 6), ("perto", 18))):
        x = rng.randint(-30, 0)
        while x < cena.W:
            tam = rng.choice((1, 2)) if camada == "perto" else rng.choice((0, 1, 2))
            w, h = TAMANHOS[camada][tam]
            lista.append((x, y0 + rng.randint(-3, 3), camada, w, h))
            x += w + rng.randint(-14, 6)
    for k, (x, y, camada, w, h) in enumerate(lista):
        cores = CORES["tempestade"][camada]
        if diluvio:
            cores = (5, 4, 3, 17)
        q = nuvem(w, h, cores, 700 + k, camada, "tempestade")
        for j2, l in enumerate(q):
            for i2, c in enumerate(l):
                if c is not None and 0 <= x + i2 < cena.W and 0 <= y + j2 < cena.H:
                    t.p[y + j2][x + i2] = c
    return t.p


def principal():
    pecas = {}
    s = 0
    for clima in CORES:
        for camada, tams in TAMANHOS.items():
            for (w, h), tam in zip(tams, "pmg"):
                s += 1
                q = nuvem(w, h, CORES[clima][camada], 620 + s, camada, clima)
                nome = f"nuvem_{clima}_{camada}_{tam}"
                gravar(q, AQUI / f"{nome}.png")
                pecas[nome] = q
    gravar(ceu_tempestade(), PECAS / "montagem" / "ceu_tempestade.png")
    gravar(ceu_tempestade(diluvio=True), PECAS / "montagem" / "ceu_diluvio.png")
    amostra(pecas)
    print("nuvens:", len(pecas), "e céus de tempestade e dilúvio")


def amostra(pecas):
    fundos = {"dia": 1, "entardecer": 7, "noite": 3, "tempestade": 5, "seca": 12}
    W, H = 4 + 9 * 68, len(fundos) * 22 + 4
    img = Image.new("RGBA", (W, H), PALETA[30] + (255,))
    for i, (clima, cor) in enumerate(fundos.items()):
        img.paste(PALETA[cor] + (255,), (0, i * 22, W, i * 22 + 21))
        x = 4
        for camada in TAMANHOS:
            for tam in "pmg":
                q = pecas[f"nuvem_{clima}_{camada}_{tam}"]
                img.alpha_composite(para_imagem(q), (x, i * 22 + 2))
                x += len(q[0]) + 4
    img.save(AQUI / "amostra_nuvens.png")
    img.resize((W * 3, H * 3), Image.NEAREST).save(AQUI / "amostra_nuvens_4x.png")


if __name__ == "__main__":
    principal()

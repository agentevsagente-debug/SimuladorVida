"""Efeitos dos poderes e do clima, em folhas horizontais de quadros.

Sufixo `_Nq`: N quadros de animação. Sufixo `_Nv`: N variações lado a lado (o motor
sorteia uma por partícula). O sumiço gradual é feito por pontilhado cada vez mais
ralo, nunca por semitransparência.
"""
from pathlib import Path
import math
import random
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import Deslocada, Folha, cena, clamp, folha_quadros, gravar, pont  # noqa: E402


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


# ---------------------------------------------------------------- chuva

def gotas():
    variacoes = []
    for pontos in (
        [(1, 2, 18), (1, 3, 19), (1, 4, 19), (1, 5, 31)],
        [(1, 0, 18), (1, 1, 18), (2, 2, 19), (2, 3, 19), (2, 4, 19), (2, 5, 31)],
        [(2, 4, 19), (2, 5, 31)],
    ):
        q = novo(4, 8)
        for x, y, c in pontos:
            put(q, x, y, c)
        variacoes.append(q)
    return variacoes


def respingo():
    quadros = []
    for pontos in (
        [(3, 7, 19), (4, 7, 19), (2, 6, 31), (5, 6, 31), (3, 5, 31)],
        [(1, 6, 19), (6, 6, 19), (2, 5, 31), (5, 5, 31), (2, 7, 18), (5, 7, 18), (3, 3, 19), (4, 2, 31)],
        [(0, 6, 18), (7, 6, 18), (1, 4, 19), (6, 4, 19), (4, 4, 19), (1, 7, 18), (6, 7, 18)],
        [(1, 7, 19), (3, 7, 18), (5, 7, 19), (6, 7, 18), (0, 7, 18), (7, 5, 18)],
    ):
        q = novo(8, 8)
        for x, y, c in pontos:
            put(q, x, y, c)
        quadros.append(q)
    return quadros


def nuvem_chuva():
    """Nuvem de chuva carregada (48x24): luz em cima à esquerda, base escura e reta."""
    quadros = []
    for k in range(2):
        rng = random.Random(40 + k)
        puffs = [(10, 15, 7), (19, 11, 9), (29, 10, 9), (38, 14, 7)]
        puffs = [(x + rng.uniform(-1, 1), y + rng.uniform(-1, 1), r) for x, y, r in puffs]
        q = novo(48, 24)
        for y in range(24):
            for x in range(48):
                melhor = None
                for cx, cy, r in puffs:
                    d = math.hypot(x - cx, y - cy) / r
                    if d <= 1 and (melhor is None or d < melhor[0]):
                        melhor = (d, (x - cx) / r, (y - cy) / r)
                if melhor is None or y > 19:
                    continue
                _, nx, ny = melhor
                luz = -(nx * 0.5 + ny * 0.85)
                if y >= 18:
                    c = 3 if pont(x, y, 0.5) or y == 19 else 4
                elif luz > 0.55:
                    c = 11 if pont(x, y, 0.6) else 5
                elif luz > 0.0:
                    c = 5
                elif luz > -0.45:
                    c = 4 if pont(x, y, 0.5) else 5
                else:
                    c = 4
                q[y][x] = c
        # fiapos de chuva saindo da base
        for x in range(6, 42, 3):
            for i in range(rng.randint(1, 3)):
                put(q, x + (k + i) % 2, 20 + i, 18 if i else 4)
        quadros.append(q)
    return quadros


# ---------------------------------------------------------------- raio

def caminho_raio(rng, x0, comprimento, larg, y0=0, direcao=0):
    """Zigue-zague: trechos de 3 a 9 linhas que andam de 1 a 4 px para o lado.
    `direcao` puxa os galhos para um lado; o tronco é puxado de volta ao centro."""
    pts, x, y = [], float(x0), y0
    while y < y0 + comprimento:
        passo = rng.randint(3, 9)
        if direcao:
            dx = direcao * rng.randint(1, 4) * (1 if rng.random() < 0.8 else -1)
        else:
            dx = rng.choice((-1, 1)) * rng.randint(1, 4)
            if abs(x + dx - larg / 2) > larg / 2 - 4:
                dx = -dx
        for i in range(passo):
            if y >= y0 + comprimento:
                break
            pts.append((int(round(x + dx * (i + 1) / passo)), y))
            y += 1
        x += dx
    return pts


def desenhar_raio(q, pts, forte=True, brilho_lados=True):
    larg = len(q[0])
    pts = [(min(max(x, 1), larg - 2), y) for x, y in pts if 0 <= y < len(q)]
    # liga os pontos de linhas vizinhas que pularam mais de 1 px (traço contínuo)
    cheio = []
    for k, (x, y) in enumerate(pts):
        cheio.append((x, y))
        if k + 1 < len(pts):
            nx, ny = pts[k + 1]
            for xx in range(min(x, nx) + 1, max(x, nx)):
                cheio.append((xx, y))
    if forte and brilho_lados:
        for x, y in cheio:
            for dx in (-1, 1):
                if q[y][x + dx] is None:
                    put(q, x + dx, y, 0)
    for x, y in cheio:
        put(q, x, y, 31 if forte else 0)


def raio(semente, galhos, alt=120, larg=32):
    rng = random.Random(semente)
    tronco = caminho_raio(rng, larg // 2, alt, larg)
    ramos = []
    for g in range(galhos):
        ini = rng.randint(alt // 6, alt * 2 // 3)
        x0 = tronco[ini][0]
        lado = 1 if x0 < larg / 2 else -1
        if g % 2:
            lado = -lado
        ramo = caminho_raio(rng, x0, rng.randint(12, 34), larg, y0=ini, direcao=lado)
        ramos.append([(x, y) for x, y in ramo if 1 <= x <= larg - 2])
    cheio, rastro = novo(larg, alt), novo(larg, alt)
    for r in ramos:
        desenhar_raio(cheio, r[: len(r) * 2 // 3], brilho_lados=False)
        desenhar_raio(cheio, r[len(r) * 2 // 3:], forte=False)
    desenhar_raio(cheio, tronco)
    # segundo quadro: o canal do tronco esfriando, mais fraco e com falhas
    desenhar_raio(rastro, [p for i, p in enumerate(tronco) if i % 11 < 8], forte=False)
    return [cheio, rastro]


def impacto_raio():
    quadros = []
    cx, cy = 8, 14
    for k in range(4):
        q = novo(16, 16)
        rng = random.Random(70 + k)
        if k == 0:
            for dx, dy, c in ((0, 0, 31), (-1, 0, 31), (1, 0, 31), (0, -1, 31), (0, -2, 22),
                              (-2, 0, 22), (2, 0, 22), (-1, -1, 22), (1, -1, 22), (0, 1, 22)):
                put(q, cx + dx, cy + dy, c)
        else:
            raio_k = 2 + k * 2
            for _ in range(10 - k * 2):
                a = rng.uniform(math.pi, 2 * math.pi)
                d = rng.uniform(raio_k - 1.5, raio_k)
                put(q, round(cx + math.cos(a) * d), round(cy + math.sin(a) * d * 0.8),
                    (22, 21, 20)[k - 1])
            for y in range(cy - k * 2, cy + 1):
                for x in range(cx - k, cx + k + 1):
                    if math.hypot(x - cx, (y - cy) * 1.2) < k * 1.6 and pont(x, y, 0.7 - k * 0.15):
                        put(q, x, y, 11 if y < cy - 1 else 8)
            if k == 1:
                put(q, cx, cy, 31)
                put(q, cx - 1, cy, 22)
                put(q, cx + 1, cy, 22)
        quadros.append(q)
    return quadros


# ---------------------------------------------------------------- fogo

def chamas(w, h, fase_q, altura, semente):
    rng = random.Random(semente)
    fases = [rng.uniform(0, 6.28) for _ in range(w)]
    q = novo(w, h)
    for x in range(1, w - 1):
        env = math.sin(math.pi * (x + 0.5) / w) ** 0.6
        hx = altura * env * (0.55 + 0.45 * abs(math.sin(x * 0.9 + fase_q * 1.57 + fases[x] * 0.3)))
        hx = int(round(hx))
        for i in range(hx):
            y = h - 1 - i
            rel = i / max(hx, 1)
            if rel < 0.2 and 0.25 < x / w < 0.75:
                c = 31
            elif rel < 0.45:
                c = 22
            elif rel < 0.75:
                c = 21
            else:
                c = 20
            if rel > 0.85 and not pont(x, y, 0.6):
                continue
            put(q, x, y, c)
    # línguas soltas acima
    for _ in range(w // 5):
        x = rng.randint(2, w - 3)
        topo = next((y for y in range(h) if q[y][x] is not None), h)
        y = topo - rng.randint(2, 4) - (fase_q % 2)
        put(q, x, y, 20 if fase_q % 2 else 21)
    return q


def brasas():
    quadros = []
    base = [(1, 7, 8), (2, 7, 20), (3, 7, 8), (4, 7, 20), (5, 7, 8), (6, 7, 20), (2, 6, 8), (4, 6, 8), (5, 6, 20)]
    acesos = [((2, 7), (5, 6)), ((4, 7),), ((2, 7), (6, 7)), ((5, 6), (4, 7))]
    for k in range(4):
        q = novo(8, 8)
        for x, y, c in base:
            put(q, x, y, c)
        for x, y in acesos[k]:
            put(q, x, y, 22 if k % 2 == 0 else 21)
        if k in (1, 3):
            put(q, 3 + k // 2, 4 - k // 2, 21)
        quadros.append(q)
    return quadros


def fumaca():
    quadros = []
    for k in range(6):
        q = novo(16, 16)
        r = 2 + k * 0.9
        cx, cy = 8 + k * 0.4, 13 - k * 1.7
        dens = 1.0 - k / 6
        for y in range(16):
            for x in range(16):
                d = math.hypot(x - cx, (y - cy) * 1.1)
                if d <= r and pont(x, y, dens):
                    luz = (x - cx) + (y - cy) < -r * 0.4
                    put(q, x, y, 12 if luz else 11)
        quadros.append(q)
    return quadros


# ---------------------------------------------------------------- terra

def terra_subindo():
    quadros = []
    w, h = 32, 24
    alturas = [3, 8, 13, 18]
    for k, hk in enumerate(alturas):
        q = novo(w, h)
        rng = random.Random(80)
        topo = []
        for x in range(w):
            u = (x - w / 2 + 0.5) / (w / 2 - 3)
            b = max(0.0, math.cos(clamp(abs(u)) * math.pi / 2)) ** 0.8 if abs(u) < 1 else 0
            topo.append(h - 1 - int(round(hk * b)))
        for x in range(w):
            t = topo[x]
            if t >= h - 1:
                continue
            esquerda = x < w / 2
            for y in range(t, h):
                d = y - t
                if d == 0:
                    c = 15
                elif d == 1:
                    c = 14
                elif d == 2:
                    c = 13
                else:
                    v = rng.random()
                    c = 10 if v < 0.08 else 8 if v < 0.15 else 9
                    if v > 0.96:
                        c = 11
                    if not esquerda and x > w / 2 + hk * 0.35 and pont(x, y, 0.5):
                        c = 8
                put(q, x, y, c)
            # lateral íngreme: borda escura de terra exposta
            if 0 < x < w - 1 and topo[x - 1] > t + 1 and esquerda:
                put(q, x, t + 1, 10)
        # torrões caindo e poeira na base
        if k > 0:
            for _ in range(2 + k):
                x = rng.randint(4, w - 5)
                y = topo[x] - rng.randint(1, 3)
                put(q, x, y, rng.choice((9, 8, 10)))
            for lado in (-1, 1):
                for i in range(2 + k):
                    x = w // 2 + lado * (w // 2 - 2 - i // 2)
                    y = h - 1 - rng.randint(0, 1 + k // 2)
                    put(q, x, y, 12 if i % 2 else 10)
        quadros.append(q)
    return quadros


def poeira():
    quadros = []
    for k in range(4):
        q = novo(16, 8)
        r = 2.5 + k * 1.6
        for y in range(8):
            for x in range(16):
                d = math.hypot(x - 7.5, (y - 7) * 1.8)
                if d <= r and pont(x, y, 0.9 - k * 0.22):
                    put(q, x, y, 12 if y < 6 - k // 2 else 10)
        quadros.append(q)
    return quadros


def rachadura():
    quadros = []
    caminho = [(7, 0), (8, 1), (7, 2), (6, 3), (7, 4), (8, 5), (9, 6), (8, 7)]
    ramos = [(5, 3), (4, 4), (10, 6), (11, 7), (3, 5)]
    for k in range(3):
        q = novo(16, 8)
        n = (3, 6, 8)[k]
        for x, y in caminho[:n]:
            put(q, x, y, 30)
            if k == 2:
                put(q, x + 1, y, 8)
                put(q, x - 1, y, 10 if y < 2 else 8)
        for x, y in ramos[:max(0, k * 2 + 1 - 1)]:
            put(q, x, y, 30 if k == 2 else 8)
        quadros.append(q)
    return quadros


# ---------------------------------------------------------------- fartura, sonho, natureza

def fartura_brilho():
    formas = [
        [(3, 3, 22)],
        [(3, 3, 31), (2, 3, 22), (4, 3, 22), (3, 2, 22), (3, 4, 22)],
        [(3, 3, 31), (2, 3, 22), (4, 3, 22), (3, 2, 22), (3, 4, 22), (1, 3, 16), (5, 3, 16),
         (3, 1, 16), (3, 5, 16)],
        [(3, 3, 22), (2, 2, 16), (4, 4, 16), (4, 2, 16), (2, 4, 16)],
    ]
    quadros = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        quadros.append(q)
    return quadros


def fartura_aura():
    rng = random.Random(90)
    particulas = [(rng.randint(1, 14), rng.randint(0, 15), rng.choice((16, 22, 15, 22))) for _ in range(9)]
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        for x, y, c in particulas:
            yy = (y - k * 4) % 16
            balanço = 1 if (yy // 4 + x) % 2 else 0
            put(q, x + balanço, yy, c)
            if yy > 11:
                put(q, x + balanço, yy, 15)          # perto do chão ainda é folha verde
            if c == 22 and yy < 8:
                put(q, x + balanço, yy + 1, 16)      # rastro
        quadros.append(q)
    return quadros


def sonho():
    quadros = []
    cx, cy = 7.5, 7.5
    for k in range(4):
        q = novo(16, 16)
        for i in range(5):
            a = k * math.pi / 8 + i * 2 * math.pi / 5
            r = 5.5 - i * 0.6
            x, y = round(cx + math.cos(a) * r), round(cy + math.sin(a) * r * 0.7)
            put(q, x, y, 31 if i == 0 else 29)
            ra = a - 0.45
            put(q, round(cx + math.cos(ra) * r), round(cy + math.sin(ra) * r * 0.7), 7 if i < 2 else 5)
        put(q, 7 + k % 2, 8 + (k // 2) * 2, 29)
        quadros.append(q)
    return quadros


def sonho_brilho():
    formas = [
        [(3, 3, 29)],
        [(3, 3, 31), (2, 3, 29), (4, 3, 29), (3, 2, 29), (3, 4, 29)],
        [(3, 3, 29), (1, 3, 7), (5, 3, 7), (3, 1, 7), (3, 5, 7)],
        [(3, 3, 7)],
    ]
    quadros = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        quadros.append(q)
    return quadros


def folha(claro, escuro):
    formas = [
        [(2, 4, claro), (3, 4, claro), (4, 4, escuro), (3, 3, claro), (5, 4, escuro)],
        [(2, 5, claro), (3, 4, claro), (4, 3, escuro), (3, 5, escuro), (4, 4, claro)],
        [(3, 2, claro), (3, 3, claro), (3, 4, escuro), (3, 5, escuro)],
        [(4, 5, claro), (3, 4, claro), (2, 3, escuro), (3, 5, escuro), (2, 4, claro)],
    ]
    quadros = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        quadros.append(q)
    return quadros


def vagalume():
    formas = [
        [(3, 3, 16)],
        [(3, 3, 22), (2, 3, 16), (4, 3, 16), (3, 2, 16), (3, 4, 16)],
        [(3, 3, 31), (2, 3, 22), (4, 3, 22), (3, 2, 22), (3, 4, 22), (2, 2, 16), (4, 4, 16),
         (4, 2, 16), (2, 4, 16)],
        [(3, 3, 22), (3, 4, 16)],
    ]
    quadros = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        quadros.append(q)
    return quadros


def gerar():
    return {
        "gotas_3v": gotas(),
        "respingo_4q": respingo(),
        "nuvem_chuva_2q": nuvem_chuva(),
        "raio_a_2q": raio(51, 0),
        "raio_b_2q": raio(52, 2),
        "raio_c_2q": raio(53, 4),
        "raio_impacto_4q": impacto_raio(),
        "chamas_4q": [chamas(16, 16, k, 13, 60) for k in range(4)],
        "chamas_grandes_4q": [chamas(24, 32, k, 28, 61) for k in range(4)],
        "brasas_4q": brasas(),
        "fumaca_6q": fumaca(),
        "terra_subindo_4q": terra_subindo(),
        "poeira_4q": poeira(),
        "rachadura_3q": rachadura(),
        "fartura_brilho_4q": fartura_brilho(),
        "fartura_aura_4q": fartura_aura(),
        "sonho_4q": sonho(),
        "sonho_brilho_4q": sonho_brilho(),
        "folha_verde_4q": folha(15, 13),
        "folha_seca_4q": folha(16, 10),
        "vagalume_4q": vagalume(),
    }


def amostra(folhas):
    """Folha de amostra: cada efeito sobre o céu de dia (esquerda) e sobre a noite (direita)."""
    from PIL import Image
    from comum import PALETA, para_imagem
    larg = max(len(qs[0][0]) * len(qs) for qs in folhas.values()) + 4
    alt = sum(len(qs[0]) + 4 for qs in folhas.values()) + 4
    img = Image.new("RGBA", (larg * 2 + 4, alt), PALETA[30] + (255,))
    img.paste(PALETA[1] + (255,), (0, 0, larg, alt))
    img.paste(PALETA[3] + (255,), (larg + 4, 0, larg * 2 + 4, alt))
    y = 4
    for qs in folhas.values():
        f = para_imagem(folha_quadros(qs))
        img.alpha_composite(f, (2, y))
        img.alpha_composite(f, (larg + 6, y))
        y += len(qs[0]) + 4
    return img


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    img = amostra(folhas)
    img.save(AQUI / "amostra_efeitos.png")
    from PIL import Image
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_efeitos_4x.png")
    print("efeitos:", ", ".join(f"{n} {len(q[0][0])}x{len(q[0])}" for n, q in folhas.items()))


if __name__ == "__main__":
    principal()

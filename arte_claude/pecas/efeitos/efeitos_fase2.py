"""Efeitos dos 5 poderes da fase 2: seca, dilúvio, terremoto, presságio (cometa e eclipse) e cura,
mais o fogo brando (o fogo em intensidade baixa, que acende a fogueira e aquece sem queimar).

Mesmas regras de `efeitos.py`: `_Nq` são quadros, `_Nv` variações, sumiço por pontilhado.
Os céus de seca e de eclipse são camadas de 480x160, como os céus de `montagem/`.
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, cena, clamp, folha_quadros, gravar, para_imagem, pont  # noqa: E402

W, H = cena.W, cena.H


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


def linha(q, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        put(q, round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)


# ---------------------------------------------------------------- seca

def seca_rachaduras():
    """Sobreposição de 32x8 para a superfície do chão: o capim amarela e o chão racha,
    em 4 etapas. A linha 2 é a superfície (como nos blocos de grama)."""
    rng = random.Random(501)
    rachas = []
    for _ in range(5):
        x = rng.randint(2, 29)
        rachas.append([(x, 2)] + [(x + rng.choice((-1, 0, 1)) * (i % 2), 2 + i) for i in range(1, rng.randint(3, 6))])
    quadros = []
    for k in range(4):
        q = novo(32, 8)
        for x in range(32):
            if k >= 1 and (x * 7 + k) % 5 < k + 1:
                put(q, x, 2, 16)                # o verde da grama seca
            if k >= 2 and (x * 3) % 4 == 0:
                put(q, x, 1, 10)                # tocos de capim seco
            if k >= 2 and x % 2:
                put(q, x, 3, 10)
        for i, r in enumerate(rachas):
            if i <= k + 1:
                for j, (x, y) in enumerate(r[: 2 + k * 2]):
                    put(q, x, y, 30)
                    if k == 3 and j < 2:
                        put(q, x + 1, y, 8)
        quadros.append(q)
    return quadros


def calor():
    """Tremor de calor: tracinhos ondulados curtos, em posições sorteadas (fixas), que
    sobem e somem. Nada de linhas inteiras nem pontilhado em grade."""
    rng = random.Random(510)
    tracos = [(rng.randrange(16), rng.randrange(16), rng.randint(2, 4)) for _ in range(7)]
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        for x0, y0, comp in tracos:
            y = (y0 - k * 3) % 16
            for i in range(comp):
                x = (x0 + i) % 16
                yy = y + (1 if (x + k) % 4 < 2 else 0)
                if 0 <= yy < 16:
                    put(q, x, yy, 16 if yy > 9 else 12)
        quadros.append(q)
    return quadros


def ceu_seca():
    """Céu de seca para o dia: degradê amarelado e um sol grande e branco."""
    t = cena.Tela()
    cfg = {"ceu": [1, 0, 12, 16], "faixas": [(24, 12), (60, 12), (96, 10)]}
    cena.pintar_ceu(t, cfg, None)
    cena.pintar_sol(t, {"sol": (70, 26, 9), "sol_cores": (31, 31, 22)})
    return t.p


# ---------------------------------------------------------------- dilúvio

def chuva_forte():
    variacoes = []
    for comp, incl in ((10, 0), (12, 1), (8, 1)):
        q = novo(4, 12)
        for i in range(comp):
            x = 1 + (i * incl) // 6
            put(q, x, 11 - comp + 1 + i, 18 if i < comp // 3 else 19 if i < comp - 1 else 31)
        variacoes.append(q)
    return variacoes


def cortina_chuva():
    """Cortina de chuva pesada, 32x32, que repete nas duas direções. O motor rola os
    4 quadros para baixo e põe a cortina sobre o mundo durante o dilúvio."""
    rng = random.Random(502)
    gotas = [(rng.randrange(32), rng.randrange(32), rng.randint(4, 8)) for _ in range(22)]
    quadros = []
    for k in range(4):
        q = novo(32, 32)
        for x0, y0, comp in gotas:
            for i in range(comp):
                y = (y0 + k * 8 + i) % 32
                x = (x0 + (y0 + k * 8 + i) // 4) % 32
                put(q, x, y, 19 if i < comp - 1 else 31)
        quadros.append(q)
    return quadros


def enchente_superficie():
    """Superfície da água da enchente (barrenta), bloco de 8x8 em 4 quadros, como
    `agua_superficie_4q`, para o nível subir por cima do terreno."""
    quadros = []
    for k in range(4):
        q = novo(8, 8)
        d = k * 2
        for x in range(8):
            kk = (x + d) % 8
            if kk in (1, 2):
                put(q, x, 0, 12 if kk == 2 else 10)
            put(q, x, 1, 12 if kk not in (5, 6) else 10)
            for y in range(2, 8):
                put(q, x, y, 10 if (y + (x + d) // 3) % 3 == 0 and (x + y) % 2 else 18)
        put(q, (3 + d) % 8, 4, 12)
        quadros.append(q)
    return quadros


def enchente_agua():
    q = novo(8, 8)
    for y in range(8):
        for x in range(8):
            q[y][x] = 9 if (y + x // 3) % 3 == 0 and (x + y) % 2 else 17
    return q


def destrocos():
    formas = [
        [(1, 4, 10), (2, 4, 10), (3, 4, 9), (4, 4, 10), (5, 4, 9), (2, 3, 9), (6, 5, 8)],
        [(2, 3, 14), (3, 3, 15), (3, 4, 13), (4, 4, 14), (2, 4, 9), (5, 3, 15)],
        [(2, 3, 10), (3, 3, 9), (2, 4, 8), (3, 4, 8), (4, 2, 10), (5, 1, 9)],
    ]
    out = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        out.append(q)
    return out


# ---------------------------------------------------------------- terremoto

def fenda():
    """Fenda funda que se abre no chão (16x16): a borda de grama cai para dentro."""
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        larg = (1, 2, 3, 4)[k]
        prof = (4, 8, 12, 15)[k]
        for y in range(prof):
            meia = larg * (1 - y / (prof + 1)) + 0.5
            cx = 7.5 + math.sin(y * 0.7) * 1.2
            for x in range(16):
                d = x - cx
                if abs(d) <= meia:
                    put(q, x, y, 30 if abs(d) < meia - 0.8 or y > 2 else 8)
                elif abs(d) <= meia + 1 and y < prof - 1:
                    put(q, x, y, 8 if d > 0 else 9)
        # borda e torrões caindo
        if k:
            for dx in (-larg - 2, larg + 2):
                put(q, round(7.5 + dx), 0, 13)
            for i in range(k):
                put(q, 6 + i, 3 + i * 3, 9)
                put(q, 9 - i, 5 + i * 2, 10)
        quadros.append(q)
    return quadros


def poeira_terremoto():
    """Nuvem de poeira (32x16) de contorno irregular: sobe, cresce e se desfaz pelas bordas
    em pedaços (sorteio fixo por pixel), sem bordas retas nem pontilhado em grade.
    Para cobrir uma área larga, o motor espalha várias, com deslocamentos e quadros
    diferentes."""
    rng = random.Random(503)
    bolhas = [(rng.uniform(5, 27), rng.uniform(9, 13), rng.uniform(3, 5)) for _ in range(6)]
    ruido = [[rng.random() for _ in range(32)] for _ in range(16)]
    quadros = []
    for k in range(4):
        q = novo(32, 16)
        for y in range(16):
            for x in range(32):
                melhor = None
                for bx, by, br in bolhas:
                    r = br + k * 1.1
                    d = math.hypot(x - bx, (y - (by - k * 1.4)) * 1.3) / r
                    melhor = d if melhor is None else min(melhor, d)
                if melhor > 1 or melhor > 1 - k * 0.13 or ruido[y][x] < k * 0.18 * (0.3 + melhor):
                    continue
                c = 12 if melhor < 0.45 and y < 10 else 10 if k < 2 else 11
                if melhor > 0.8 and ruido[y][x] < 0.5:
                    c = 9
                put(q, x, y, c)
        quadros.append(q)
    return quadros


def pedras_caindo():
    formas = [[(1, 1, 12), (2, 1, 11), (1, 2, 11), (2, 2, 8)], [(1, 1, 11), (2, 2, 8), (1, 2, 8)],
              [(1, 1, 9), (2, 1, 10), (1, 2, 8), (2, 2, 9)]]
    out = []
    for f in formas:
        q = novo(4, 4)
        for x, y, c in f:
            put(q, x, y, c)
        out.append(q)
    return out


# ---------------------------------------------------------------- presságio

def cometa():
    """Cometa (32x16) atravessando o céu da direita para a esquerda; a cauda tremula."""
    quadros = []
    for k in range(4):
        q = novo(32, 16)
        hx, hy = 4, 4
        for i in range(26):
            x = hx + 1 + i
            y0 = hy + i * 0.28
            esp = 0.6 + i * 0.12
            for y in range(16):
                d = abs(y - y0)
                if d <= esp:
                    dens = 1 - i / 26
                    if i < 3:
                        c = 31
                    elif d < esp * 0.4:
                        c = 0 if pont(x, y, dens) else 19
                    else:
                        c = 19 if pont(x + k, y, dens * 0.8) else None
                    if c is not None:
                        put(q, x, y, c)
        for dx, dy in ((0, 0), (-1, 0), (0, -1), (0, 1), (1, 0)):
            put(q, hx + dx, hy + dy, 31)
        put(q, hx - 1, hy - 1, 22 if k % 2 else 0)
        quadros.append(q)
    return quadros


def eclipse():
    """Eclipse (16x16) em 4 quadros: o disco escuro cobre o sol até sobrar a coroa."""
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        cx, cy, r = 7.5, 7.5, 4.5
        ox = 6 - k * 2                           # posição do disco escuro
        for y in range(16):
            for x in range(16):
                d = math.hypot(x - cx, y - cy)
                dl = math.hypot(x - cx - ox, y - cy)
                if dl <= r and d <= r + 0.5:
                    put(q, x, y, 3)
                elif d <= r - 1.2:
                    put(q, x, y, 31)
                elif d <= r:
                    put(q, x, y, 22)
                elif k == 3 and d <= r + 2.2 and pont(x, y, 1 - (d - r) / 2.2):
                    put(q, x, y, 22 if d < r + 1 else 21)
        quadros.append(q)
    return quadros


def ceu_eclipse():
    """Céu do eclipse total, de dia: escuro como a noite, com a coroa e um anel de
    entardecer no horizonte."""
    t = cena.Tela()
    cfg = {"ceu": [3, 4, 5, 6], "faixas": [(52, 14), (92, 8), (108, 4)]}
    cena.pintar_ceu(t, cfg, None)
    cx, cy, r = 70, 26, 7
    for y in range(cy - 14, cy + 15):
        for x in range(cx - 14, cx + 15):
            d = math.hypot(x - cx, y - cy)
            if d <= r:
                t.put(x, y, 3 if d < r - 0.8 else 22)
            elif d <= r + 5 and pont(x, y, 1 - (d - r) / 5):
                t.put(x, y, 22 if d < r + 2 else 21 if d < r + 3.5 else 5)
    rng = random.Random(504)
    for _ in range(30):
        x, y = rng.randrange(W), rng.randrange(0, 70)
        if t.p[y][x] in (3, 4):
            t.put(x, y, 12)
    return t.p


# ---------------------------------------------------------------- cura

def cura_luz():
    """Luz suave que desce sobre quem é curado (16x24): pontos claros caindo em espiral
    numa coluna de luz pontilhada."""
    quadros = []
    for k in range(4):
        q = novo(16, 24)
        rng = random.Random(505 + k)
        for y in range(24):
            for x in range(16):
                d = abs(x - 7.5)
                meia = 2 + y / 23 * 3
                if d <= meia and rng.random() < 0.07:
                    put(q, x, y, 0)
                elif abs(d - meia) < 0.6 and (y + k) % 3 == 0:
                    put(q, x, y, 19)
        for i in range(6):
            a = i * 1.05 + k * 0.5
            y = (i * 4 + k * 2) % 24
            x = round(7.5 + math.cos(a) * (2 + y / 10))
            put(q, x, y, 31)
            put(q, x, y - 1, 15 if i % 2 else 0)
        quadros.append(q)
    return quadros


def cura_brilho():
    formas = [
        [(3, 3, 15)],
        [(3, 3, 31), (2, 3, 15), (4, 3, 15), (3, 2, 15), (3, 4, 15)],
        [(3, 3, 0), (2, 2, 15), (4, 4, 15), (4, 2, 15), (2, 4, 15), (3, 1, 31)],
        [(3, 3, 15), (3, 2, 0)],
    ]
    out = []
    for f in formas:
        q = novo(8, 8)
        for x, y, c in f:
            put(q, x, y, c)
        out.append(q)
    return out


# ---------------------------------------------------------------- fogo brando

def fogo_brando_descer():
    """O fogo em intensidade baixa (o deus atende a prece de frio): uma coluna de luz morna que
    desce do céu sobre a fogueira (16x32), sem chama. As bordas são pontilhadas em âmbar, e
    fagulhas douradas descem em espiral com um rastro curto acima. A base (linha 31) é o
    centro da fogueira, onde a coluna se abre num brilho baixo."""
    quadros = []
    for k in range(4):
        q = novo(16, 32)
        rng = random.Random(611 + k)
        for y in range(29):
            meia = 1.5 + y / 28 * 3
            for x in range(16):
                d = abs(x - 7.5)
                if d <= meia - 0.6 and rng.random() < 0.05:
                    put(q, x, y, 22)
                elif abs(d - meia) < 0.6 and (y + k) % 3 == 0:
                    put(q, x, y, 21)
        for i in range(6):                       # fagulhas descendo em espiral
            a = i * 1.1 + k * 0.6
            y = (i * 5 + k * 3) % 28
            x = round(7.5 + math.cos(a) * (1.5 + y / 10))
            put(q, x, y, 31)
            put(q, x, y - 1, 22)
            if i % 2:
                put(q, x, y - 2, 21)
        # o brilho baixo na base, que pulsa
        larg = (3, 4, 5, 4)[k]
        for x in range(8 - larg, 8 + larg):
            if (x + k) % 2 == 0:
                put(q, x, 31, 22)
            if abs(x - 7.5) < larg - 1.5:
                put(q, x, 30, 21 if (x + k) % 3 else 22)
        put(q, 7, 29, 31)
        put(q, 8, 29, 22)
        quadros.append(q)
    return quadros


def fogo_brando_acender():
    """O instante em que a luz chega à fogueira (16x8): um ponto dourado, um anel de fagulhas,
    as fagulhas subindo e sumindo. A base (linha 7) é a base da fogueira. Depois, a fogueira
    acesa de sempre e o `calor_brando_4q`."""
    formas = [
        [(7, 6, 31), (8, 6, 22), (7, 5, 22)],
        [(7, 6, 31), (8, 6, 31), (4, 6, 22), (11, 6, 22), (5, 4, 21), (10, 4, 21), (7, 3, 22), (8, 4, 22)],
        [(3, 5, 21), (12, 5, 21), (4, 2, 22), (11, 2, 22), (6, 1, 31), (9, 1, 31), (7, 3, 21), (8, 6, 22)],
        [(2, 3, 21), (13, 3, 21), (5, 0, 22), (10, 0, 21), (8, 2, 21)],
    ]
    out = []
    for f in formas:
        q = novo(16, 8)
        for x, y, c in f:
            put(q, x, y, c)
        out.append(q)
    return out


def calor_brando():
    """O calor em volta da fogueira acesa pelo deus (32x16), enquanto ela queima: tracinhos
    ondulados mornos subindo dos dois lados (o meio, onde fica a fogueira, fica livre), uma
    fagulha clara de vez em quando e, no chão, um halo pontilhado que pulsa. É luz: não passa
    pela tabela da noite. A base (linha 15) é o chão da fogueira, com o centro na coluna 16."""
    rng = random.Random(612)
    tracos = []
    while len(tracos) < 9:
        x0 = rng.randrange(1, 30)
        if 12 <= x0 <= 18:                       # o meio fica para a fogueira
            continue
        tracos.append((x0, rng.randrange(14), rng.randint(2, 3)))
    quadros = []
    for k in range(4):
        q = novo(32, 16)
        for x0, y0, comp in tracos:
            y = (y0 - k * 3) % 14
            for i in range(comp):
                x = x0 + i
                yy = y + (1 if (x + k) % 4 < 2 else 0)
                put(q, x, yy, 21 if yy > 8 else 22)
        for i, (x, y) in enumerate(((5, 11), (26, 9), (9, 4), (23, 3))):
            if (i + k) % 4 == 0:
                put(q, x, (y - k) % 14, 31)
        larg = (10, 12, 13, 12)[k]               # o halo no chão, que pulsa
        for x in range(16 - larg, 16 + larg):
            if (x + k) % 3 == 0 and not 13 <= x <= 18:
                put(q, x, 15, 21)
            if (x + k) % 5 == 0 and abs(x - 16) < larg - 3 and not 12 <= x <= 19:
                put(q, x, 14, 22)
        quadros.append(q)
    return quadros


def gerar():
    return {
        "seca_rachaduras_4q": seca_rachaduras(),
        "calor_4q": calor(),
        "chuva_forte_3v": chuva_forte(),
        "cortina_chuva_4q": cortina_chuva(),
        "enchente_superficie_4q": enchente_superficie(),
        "enchente_agua_1q": [enchente_agua()],
        "destrocos_3v": destrocos(),
        "fenda_4q": fenda(),
        "poeira_terremoto_4q": poeira_terremoto(),
        "pedras_caindo_3v": pedras_caindo(),
        "cometa_4q": cometa(),
        "eclipse_4q": eclipse(),
        "cura_luz_4q": cura_luz(),
        "cura_brilho_4q": cura_brilho(),
        "fogo_brando_descer_4q": fogo_brando_descer(),
        "fogo_brando_acender_4q": fogo_brando_acender(),
        "calor_brando_4q": calor_brando(),
    }


def amostra(folhas):
    larg = max(len(qs[0][0]) * len(qs) + 2 * len(qs) for qs in folhas.values()) + 4
    alt = sum(len(qs[0]) + 4 for qs in folhas.values()) + 4
    img = Image.new("RGBA", (larg * 2 + 4, alt), PALETA[30] + (255,))
    img.paste(PALETA[1] + (255,), (0, 0, larg, alt))
    img.paste(PALETA[3] + (255,), (larg + 4, 0, larg * 2 + 4, alt))
    y = 4
    for qs in folhas.values():
        for i, q in enumerate(qs):
            f = para_imagem(q)
            x = 2 + i * (len(q[0]) + 2)
            img.alpha_composite(f, (x, y))
            img.alpha_composite(f, (larg + 4 + x, y))
        y += len(qs[0]) + 4
    return img


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    pasta_ceu = AQUI.parent / "montagem"
    gravar(ceu_seca(), pasta_ceu / "ceu_seca.png")
    gravar(ceu_eclipse(), pasta_ceu / "ceu_eclipse.png")
    img = amostra(folhas)
    img.save(AQUI / "amostra_efeitos_fase2.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_efeitos_fase2_4x.png")
    print("efeitos fase 2:", ", ".join(f"{n} {len(q[0][0])}x{len(q[0])}" for n, q in folhas.items()))


if __name__ == "__main__":
    principal()

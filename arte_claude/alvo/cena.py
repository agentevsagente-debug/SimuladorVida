"""Cena-alvo da direção C (Clássica 16 bits), pintada pixel a pixel por código.

Tudo é desenhado em índices da paleta de 32 cores (`arte/paleta/paleta.hex`).
O mundo (chão, plantas, cabanas, pessoas) é pintado uma vez com as cores "de dia"
e depois remapeado por tabela para o entardecer e para a noite. Céu, montanhas e
água são pintados por horário. À noite, a luz da fogueira é calculada por
distância e aplicada com pontilhado ordenado (Bayer 4x4).

Uso: `render("entardecer" | "dia" | "noite")` devolve uma imagem RGB 480x160.
"""
from pathlib import Path
import math
import random

from PIL import Image

AQUI = Path(__file__).resolve().parent
PALETA_ARQ = AQUI.parent.parent / "arte" / "paleta" / "paleta.hex"

W, H = 480, 160
SOLO = 120          # superfície do chão no centro (75% da altura)
NIVEL_AGUA = 121    # linha d'água
FOGO_X, FOGO_Y = 224, 119

# Etiquetas de cada pixel, usadas nos remapeamentos por horário.
CEU, MUNDO, PESSOA, FOGO, AGUA, FRENTE = 0, 1, 2, 3, 4, 5

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def carregar_paleta():
    linhas = [l.strip() for l in PALETA_ARQ.read_text().splitlines() if l.strip()]
    return [tuple(int(l[i:i + 2], 16) for i in (0, 2, 4)) for l in linhas]


def pont(x, y, f):
    """Pontilhado ordenado: verdadeiro quando a fração f 'vence' neste pixel."""
    return f * 16 > BAYER[y % 4][x % 4] + 0.5


def clamp(v, a=0.0, b=1.0):
    return a if v < a else b if v > b else v


def ruido1d(rng, n, passo, amp):
    """Ruído suave em 1D: nós aleatórios a cada `passo` px, interpolados."""
    nos = [rng.uniform(-amp, amp) for _ in range(n // passo + 3)]
    out = []
    for x in range(n):
        i, f = divmod(x, passo)
        f /= passo
        f = f * f * (3 - 2 * f)
        out.append(nos[i] * (1 - f) + nos[i + 1] * f)
    return out


class Tela:
    def __init__(self):
        self.p = [[0] * W for _ in range(H)]
        self.tag = [[CEU] * W for _ in range(H)]
        self.lado = [[0] * W for _ in range(H)]   # pessoas: 1 = lado voltado ao fogo

    def put(self, x, y, c, tag=None, lado=0):
        if 0 <= x < W and 0 <= y < H:
            self.p[y][x] = c
            if tag is not None:
                self.tag[y][x] = tag
            self.lado[y][x] = lado

    def get(self, x, y):
        return self.p[y][x] if 0 <= x < W and 0 <= y < H else None


# ---------------------------------------------------------------- horários

HORARIOS = {
    "entardecer": dict(
        ceu=[2, 5, 7, 6], faixas=[(18, 11), (38, 10), (58, 8)],
        sol=(92, 86, 11), sol_cores=(31, 22, 6),
        nuvem=(6, 7, 5), nuvens_baixas=(5,),
        longe=(7, 5), perto=(5, 4), mata=(4, 5),
        reflexo=(22, 6, 31), agua=(18, 17, 6), espuma=19,
    ),
    "dia": dict(
        ceu=[2, 1, 0], faixas=[(30, 14), (72, 12)],
        sol=(70, 24, 7), sol_cores=(31, 31, 0),
        nuvem=(31, 0, 1), nuvens_baixas=(1,),
        longe=(1, 2), perto=(18, 17), mata=(14, 13),
        reflexo=(31, 19, 31), agua=(18, 17, 19), espuma=19,
    ),
    "noite": dict(
        ceu=[3, 4, 5], faixas=[(90, 12), (106, 6)],
        lua=(118, 30, 6),
        nuvem=(5, 4, 3), nuvens_baixas=(3,),
        longe=(5, 4), perto=(3, 30), mata=(30, 3),
        reflexo=(12, 0, 31), agua=(17, 4, 5), espuma=0,
    ),
}

# Remapeamento do mundo pintado "de dia".
REMAP_ENTARDECER = {15: 16, 31: 22, 0: 12}
REMAP_NOITE = {
    0: 1, 1: 4, 8: 30, 9: 8, 10: 8, 11: 4, 12: 5, 13: 3, 14: 13, 15: 13, 16: 13,
    20: 8, 21: 20, 22: 21, 23: 30, 24: 23, 25: 24, 26: 25,
    27: 20, 28: 18, 29: 5, 18: 17, 5: 4, 31: 12, 30: 30, 6: 7, 7: 5,
    17: 3, 19: 18, 2: 4, 3: 3, 4: 3,
}
CONTORNO_SOL = {23: 24, 24: 25, 25: 26, 26: 22, 8: 24, 30: 23, 20: 27, 18: 28, 5: 29,
                27: 21, 28: 19, 29: 7, 9: 10, 12: 31}
# Luz da fogueira: perto (quente e clara) e média.
FOGO_PERTO = {
    8: 9, 9: 10, 10: 21, 11: 10, 12: 22, 13: 14, 14: 15, 15: 16, 16: 16,
    23: 24, 24: 25, 25: 26, 26: 22, 27: 21, 20: 27, 28: 12, 18: 28, 29: 7, 5: 7,
    30: 8, 31: 22, 3: 5, 4: 5,
}
FOGO_MEDIO = {
    8: 30, 9: 8, 10: 9, 11: 5, 12: 11, 13: 3, 14: 13, 15: 14, 16: 14,
    23: 23, 24: 24, 25: 24, 26: 25, 27: 27, 20: 20, 28: 18, 18: 17, 29: 29, 5: 5,
    30: 30, 31: 12, 3: 4, 4: 4,
}


# ---------------------------------------------------------------- céu

def pintar_ceu(t, cfg, rng):
    cores, faixas = cfg["ceu"], cfg["faixas"]
    for y in range(H):
        for x in range(W):
            c = cores[0]
            for i, (yb, larg) in enumerate(faixas):
                f = clamp((y - (yb - larg)) / (2 * larg))
                if pont(x, y, f):
                    c = cores[i + 1]
            t.p[y][x] = c


def pintar_sol(t, cfg):
    cx, cy, r = cfg["sol"]
    nucleo, borda, halo = cfg["sol_cores"]
    for y in range(cy - r - 8, cy + r + 9):
        for x in range(cx - r - 8, cx + r + 9):
            d = math.hypot(x - cx, (y - cy) * 1.05)
            if d <= r - 2.5:
                t.put(x, y, nucleo)
            elif d <= r:
                t.put(x, y, borda)
            elif d <= r + 7 and 0 <= y < H:
                if pont(x, y, 0.55 * (1 - (d - r) / 7)):
                    t.put(x, y, halo)


def pintar_lua(t, cfg, rng):
    cx, cy, r = cfg["lua"]
    for y in range(cy - r - 6, cy + r + 7):
        for x in range(cx - r - 6, cx + r + 7):
            d = math.hypot(x - cx, y - cy)
            d2 = math.hypot(x - cx - 3, y - cy + 2)
            if d <= r and d2 > r - 0.6:
                t.put(x, y, 31 if d > r - 1.3 or x < cx - 2 else 12)
            elif d <= r and d2 <= r - 0.6:
                if pont(x, y, 0.25):
                    t.put(x, y, 5)
            elif d <= r + 5 and pont(x, y, 0.3 * (1 - (d - r) / 5)):
                t.put(x, y, 5)
    # estrelas
    for _ in range(95):
        x, y = rng.randrange(W), rng.randrange(0, 96)
        if t.p[y][x] in (3, 4, 5) and abs(x - cx) + abs(y - cy) > r + 6:
            t.put(x, y, rng.choice((0, 12, 1, 1, 12)))
    for x, y in ((40, 14), (210, 22), (300, 9), (402, 30), (460, 12), (172, 46)):
        t.put(x, y, 31)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            t.put(x + dx, y + dy, 1)


def pintar_nuvem(t, cx, cy, comp, alt, cores, rng):
    luz, corpo, sombra = cores
    puffs = []
    n = max(3, comp // 12)
    for i in range(n):
        px = cx - comp // 2 + (i + 0.5) * comp / n + rng.uniform(-3, 3)
        pr = comp / n * rng.uniform(0.7, 1.1)
        ph = alt * rng.uniform(0.55, 1.0) * (1.0 - 0.5 * abs(i - (n - 1) / 2) / n)
        puffs.append((px, pr, ph))
    for x in range(cx - comp // 2 - 6, cx + comp // 2 + 7):
        topo = None
        for px, pr, ph in puffs:
            u = (x - px) / pr
            if abs(u) < 1:
                h = ph * math.sqrt(1 - u * u)
                topo = h if topo is None else max(topo, h)
        if topo is None or topo < 0.8:
            continue
        y0 = int(round(cy - topo))
        base = cy + (1 if abs(x - cx) < comp * 0.4 else 0)
        for y in range(y0, base + 1):
            if y - y0 < 1 or (y - y0 < 2 and x < cx):
                c = luz
            elif y >= base - 1:
                c = sombra
            else:
                c = corpo
                if y - y0 == 2 and pont(x, y, 0.5):
                    c = luz
                if y == base - 2 and pont(x, y, 0.5):
                    c = sombra
            t.put(x, y, c)
    # fiapo alongado embaixo
    for x in range(cx - comp // 2 - 10, cx + comp // 2 + 14):
        if pont(x, cy + 3, 0.5) or abs(x - cx) < comp * 0.3:
            t.put(x, cy + 3, sombra)


def pintar_nuvens(t, cfg, hora, rng):
    lista = [(64, 34, 46, 7), (196, 20, 70, 9), (330, 44, 40, 6), (418, 18, 54, 8)]
    if hora == "noite":
        lista = [(200, 20, 66, 6), (412, 40, 50, 5)]
    for cx, cy, comp, alt in lista:
        pintar_nuvem(t, cx, cy, comp, alt, cfg["nuvem"], rng)
    # nuvens finas e distantes perto do horizonte
    c = cfg["nuvens_baixas"][0]
    for cx, cy, comp in ((150, 66, 60), (280, 74, 80), (440, 70, 40)):
        if hora == "noite":
            cy -= 6
        for x in range(cx - comp // 2, cx + comp // 2):
            t.put(x, cy, c)
            if abs(x - cx) < comp // 3:
                t.put(x + 4, cy - 1, c)


# ---------------------------------------------------------------- montanhas

def cordilheira(t, picos, base, cor_luz, cor_sombra, rng, neve=None, aresta=None):
    ruido = ruido1d(rng, W, 7, 1.6)
    for x in range(W):
        melhor, pico = 1e9, None
        for px, py, incl in picos:
            h = py + abs(x - px) * incl
            if h < melhor:
                melhor, pico = h, (px, py)
        topo = int(round(melhor + ruido[x]))
        for y in range(max(0, topo), base):
            lado_luz = x < pico[0] - (y - pico[1]) * 0.15
            c = cor_luz if lado_luz else cor_sombra
            # transição pontilhada na crista entre luz e sombra
            dist = x - (pico[0] - (y - pico[1]) * 0.15)
            if -2 <= dist < 0 and pont(x, y, (dist + 2) / 2):
                c = cor_sombra
            if neve and y - pico[1] < neve and y < topo + 3 + neve // 2:
                c = 31 if lado_luz else 0
            t.put(x, y, c)
    # arestas secundárias: facetas descendo do pico pelo lado iluminado
    for px, py, incl in picos:
        for k, (desl, comp) in enumerate(((5, 11), (12, 8))):
            for i in range(comp):
                y = py + desl + i
                x = int(px - desl * 0.9 / incl * 0.5 - i * 0.55 / incl)
                if 0 <= x < W and 0 <= y < base and t.p[y][x] == cor_luz:
                    t.put(x, y, cor_sombra)
                    if 0 <= x + 1 < W and t.p[y][x + 1] == cor_luz and pont(x, y, 0.5):
                        t.put(x + 1, y, cor_sombra)


def lado_luz_at(x, picos):
    melhor, pico = 1e9, None
    for px, py, incl in picos:
        h = py + abs(x - px) * incl
        if h < melhor:
            melhor, pico = h, px
    return x < pico


def pintar_fundo(t, cfg, hora, rng):
    l1, s1 = cfg["longe"]
    l2, s2 = cfg["perto"]
    neve = 5 if hora == "dia" else None
    cordilheira(t, [(20, 70, 0.55), (150, 56, 0.62), (178, 64, 0.6), (262, 64, 0.55),
                    (356, 50, 0.6), (384, 58, 0.62), (456, 62, 0.58)], 122, l1, s1, rng, neve=neve)
    cordilheira(t, [(-10, 88, 0.45), (56, 94, 0.4), (204, 84, 0.42), (236, 88, 0.45),
                    (318, 90, 0.4), (430, 82, 0.45)], 122, l2, s2, rng)
    # linha de mata distante (copas arredondadas) atrás do mundo
    m1, m2 = cfg["mata"]
    ruido = ruido1d(rng, W, 5, 2.2)
    for x in range(108, W):
        copa = 2.6 * math.sqrt(abs(math.sin(x * 0.36))) + 2.2 * abs(math.sin(x * 0.11 + 1.3)) + ruido[x]
        topo = int(round(112 - copa))
        for y in range(topo, 122):
            c = m2 if y == topo or (y == topo + 1 and pont(x, y, 0.5)) else m1
            t.put(x, y, c)


# ---------------------------------------------------------------- terreno

def perfil(rng):
    """Altura da superfície por coluna e tipo de solo ('areia' ou 'grama')."""
    r = ruido1d(rng, W, 9, 1.4)
    r2 = ruido1d(rng, W, 23, 2.0)
    sup, tipo = [], []
    for x in range(W):
        if x < 104:                      # fundo do mar
            y = 124 + (104 - x) * 0.27 + r2[x] * 1.5
            tp = "areia"
        elif x < 150:                    # praia subindo
            u = (x - 104) / 46
            y = 124.5 - 4.5 * (u * u * (3 - 2 * u)) + r[x] * 0.3
            tp = "areia"
        elif x < 304:                    # clareira central
            y = SOLO + (r[x] * 0.7 if not 196 < x < 254 else 0)
            tp = "grama"
        else:                            # morro
            u = clamp((x - 304) / 92)
            y = SOLO - 27 * (u * u * (3 - 2 * u)) + r2[x] + r[x] * 0.6
            tp = "grama"
        sup.append(int(round(y)))
        tipo.append(tp)
    return sup, tipo


def voronoi_rocha(rng, x0, x1, y0, y1, n):
    return [(rng.uniform(x0, x1), rng.uniform(y0, y1)) for _ in range(n)]


def pintar_terreno(t, sup, tipo, rng):
    r_terra = ruido1d(rng, W, 11, 2.5)
    r_escura = ruido1d(rng, W, 13, 2.5)
    sementes = voronoi_rocha(rng, -10, W + 10, 138, 172, 150)
    camadas = []
    for x in range(W):
        s = sup[x]
        lim_terra = max(s + 7, int(round(129 + r_terra[x])))
        lim_escura = max(lim_terra + 5, int(round(142 + r_escura[x])))
        camadas.append((lim_terra, lim_escura))
        for y in range(s, H):
            if y >= lim_escura - 1 and (y >= lim_escura or pont(x, y, 0.5)):
                c = rocha(x, y, sementes)
            elif y >= lim_terra and (y > lim_terra or pont(x, y, 0.5)):
                c = 8
                v = rng.random()
                if v < 0.06:
                    c = 9
                elif v < 0.08:
                    c = 30
            else:
                d = y - s
                if tipo[x] == "areia":
                    c = 12
                    v = rng.random()
                    if d > 4 and v < 0.12:
                        c = 11
                    elif v < 0.05:
                        c = 10
                    elif v < 0.07 and d < 3:
                        c = 31
                    if y >= lim_terra - 3 and pont(x, y, 0.4):
                        c = 10
                else:
                    if d == 0:
                        c = 15
                    elif d == 1:
                        c = 14
                    elif d == 2 or (d == 3 and (x * 7) % 5 < 2):
                        c = 13
                    else:
                        c = 9
                        v = rng.random()
                        if v < 0.07:
                            c = 10
                        elif v < 0.13:
                            c = 8
                        if y >= lim_terra - 2 and pont(x, y, 0.35):
                            c = 8
            t.put(x, y, c, MUNDO)
    return camadas


def rocha(x, y, sementes):
    d1 = d2 = 1e9
    s1 = None
    for sx, sy in sementes:
        d = (x - sx) ** 2 + ((y - sy) * 1.5) ** 2
        if d < d1:
            d2, d1, s1 = d1, d, (sx, sy)
        elif d < d2:
            d2 = d
    borda = math.sqrt(d2) - math.sqrt(d1)
    fundo = clamp((y - 146) / 14)
    if borda < 1.0:
        return 30 if fundo > 0.5 and pont(x, y, 0.5) else 8
    dx, dy = x - s1[0], y - s1[1]
    if borda < 1.6 and dy < 0 and dx < 1.5:
        return 12 if fundo < 0.3 else 11
    if dy > 0.3 and pont(x, y, 0.45 + fundo * 0.4):
        return 8
    if pont(x, y, fundo * 0.35):
        return 8
    return 11


def pintar_raizes(t, sup, camadas, xs, rng):
    for x0 in xs:
        for _ in range(rng.randint(1, 2)):
            x, y = float(x0 + rng.randint(-2, 2)), sup[x0] + 3
            dx = rng.uniform(-0.8, 0.8)
            fundo = min(camadas[x0][0] + rng.randint(3, 9), camadas[x0][1] - 1)
            while y < fundo:
                xi = int(round(x))
                if 0 <= xi < W and t.tag[y][xi] == MUNDO:
                    t.put(xi, y, 10, MUNDO)
                    if t.get(xi + 1, y) in (8, 9):
                        t.put(xi + 1, y, 8 if t.p[y][xi + 1] == 9 else 30, MUNDO)
                if rng.random() < 0.15:
                    lado = rng.choice((-1, 1))
                    for k in range(1, rng.randint(2, 4)):
                        if 0 <= xi + lado * k < W and t.tag[y + k // 2][xi + lado * k] == MUNDO:
                            t.put(xi + lado * k, y + k // 2, 10 if k < 2 else 9, MUNDO)
                x += dx + rng.uniform(-0.6, 0.6)
                dx *= 0.9
                y += 1


def pintar_pedras_solo(t, camadas, rng):
    for _ in range(26):
        x = rng.randrange(4, W - 4)
        lt, le = camadas[x]
        y = rng.randint(lt + 1, le - 1)
        rx, ry = rng.randint(2, 4), rng.randint(1, 2)
        pedra(t, x, y, rx, ry)


def pedra(t, cx, cy, rx, ry, musgo=False, tag=MUNDO):
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            u, v = (x - cx) / (rx + 0.5), (y - cy) / (ry + 0.5)
            if u * u + v * v <= 1:
                borda = (u * u + v * v) > 0.55
                if v < -0.2 and u < 0.3:
                    c = 12
                elif borda and (v > 0.2 or u > 0.5):
                    c = 8
                else:
                    c = 11
                if musgo and v < -0.45 and u > -0.6:
                    c = 15 if u < 0.2 else 14
                t.put(x, y, c, tag)


def pintar_superficie(t, sup, tipo, rng):
    # borda irregular de grama: tufinhos acima da linha
    for x in range(W):
        if tipo[x] != "grama":
            continue
        s = sup[x]
        if 202 < x < 248:
            continue
        v = rng.random()
        if v < 0.35:
            t.put(x, s - 1, 15, MUNDO)
        if v < 0.08:
            t.put(x, s - 2, 15, MUNDO)
            t.put(x, s - 1, 14, MUNDO)
        # degrau do terreno: lateral visível quando sobe
        if x > 0 and sup[x - 1] > s:
            for y in range(s + 1, sup[x - 1] + 2):
                if t.p[y][x] in (14, 13):
                    pass
    # clareira de terra batida em volta da fogueira
    for x in range(196, 254):
        borda = min(x - 196, 254 - x)
        for y in range(SOLO, SOLO + 2):
            if borda > 3 or pont(x, y, borda / 4):
                c = 10 if y == SOLO else 9
                if rng.random() < 0.12:
                    c = 12 if y == SOLO else 10
                t.put(x, y, c, MUNDO)
        if borda > 3 and rng.random() < 0.1:
            t.put(x, SOLO + 2, 9, MUNDO)
    # transição areia/grama na praia
    for x in range(140, 156):
        s = sup[x]
        if x >= 146 or rng.random() < (x - 138) / 10:
            t.put(x, s, 15 if x % 3 else 16, MUNDO)
            if x >= 149:
                t.put(x, s + 1, 14, MUNDO)


# ---------------------------------------------------------------- água

def pintar_agua(t, sup, cfg, hora, rng):
    clara, escura, brilho = cfg["agua"]
    luz_reflexo, luz2, luz3 = cfg["reflexo"]
    ref_x = cfg["sol"][0] if "sol" in cfg else cfg["lua"][0]
    for x in range(W):
        fundo = sup[x]
        if fundo <= NIVEL_AGUA:
            continue
        for y in range(NIVEL_AGUA, fundo):
            d = y - NIVEL_AGUA
            if d == 0:
                c = cfg["espuma"] if (x // 3 + x // 7) % 3 else clara
            else:
                f = clamp((d - 6) / 14)
                c = escura if pont(x, y, f) else clara
                if hora != "noite" and d > 3 and (x - d * 2) % 23 in (0, 1) and pont(x, y, 0.45):
                    c = clara     # raios de luz descendo pela água
            t.put(x, y, c, AGUA)
    # reflexo em traços horizontais
    for y in range(NIVEL_AGUA + 1, NIVEL_AGUA + 12):
        d = y - NIVEL_AGUA
        larg = 3 + d * 1.6
        for _ in range(3):
            x0 = int(ref_x + rng.uniform(-larg, larg))
            comp = rng.randint(2, 6 if d < 6 else 4)
            for x in range(x0, x0 + comp):
                if 0 <= x < W and t.tag[y][x] == AGUA:
                    c = luz_reflexo if abs(x - ref_x) < larg * 0.5 else luz2
                    t.put(x, y, c, AGUA)
    # brilhos espalhados
    for _ in range(26):
        x, y = rng.randrange(0, 100), rng.randrange(NIVEL_AGUA + 1, NIVEL_AGUA + 8)
        if t.tag[y][x] == AGUA:
            for i in range(rng.randint(2, 4)):
                if t.tag[y][x + i] == AGUA:
                    t.put(x + i, y, brilho, AGUA)
    # ondinhas sobre a linha d'água
    for x in range(0, 104):
        if (x + 3) % 11 < 3:
            t.put(x, NIVEL_AGUA - 1, cfg["espuma"] if (x + 3) % 11 == 1 else clara, AGUA)
    # espuma batendo na areia
    for x in range(96, 106):
        if t.tag[NIVEL_AGUA][x] == AGUA or t.p[NIVEL_AGUA][x] == 12:
            if x % 2 == 0:
                t.put(x, NIVEL_AGUA, 31 if hora != "noite" else 0, AGUA)
    # algas e peixinhos
    for ax in (20, 27, 58, 66, 83):
        h = rng.randint(4, 8)
        for i in range(h):
            xx = ax + (1 if (i // 2) % 2 else 0)
            t.put(xx, sup[ax] - 1 - i, 14 if i % 3 else 13, AGUA)
    for fx, fy in ((40, 134), (48, 138), (74, 130)):
        t.put(fx, fy, brilho if hora != "dia" else 19, AGUA)
        t.put(fx + 1, fy, 12, AGUA)
        t.put(fx - 1, fy - 1, escura, AGUA)
        t.put(fx - 1, fy + 1, escura, AGUA)


# ---------------------------------------------------------------- vegetação

def pinheiro(t, x, base, alt, rng, escuro=False):
    tronco = 4 if alt > 20 else 3
    for y in range(base - tronco - 1, base + 1):
        t.put(x, y, 9 if not escuro else 8, MUNDO)
        t.put(x + 1, y, 8, MUNDO)
    camadas = max(3, alt // 7)
    topo = base - alt
    copa_alt = alt - tronco
    for i in range(camadas):
        ini = topo + int(i * copa_alt / camadas * 0.82)
        fim = topo + int((i + 1) * copa_alt / camadas) + 1
        larg_max = 2 + (i + 1) * (alt / 30 * 2.6)
        for y in range(ini, fim):
            u = (y - ini + 1) / (fim - ini)
            hw = larg_max * u
            if i == 0:
                hw = larg_max * u * 0.85
            for xx in range(int(x + 0.5 - hw), int(x + 1.5 + hw)):
                dx = xx - (x + 0.5)
                rel = dx / (hw + 0.01)
                if y == fim - 1 and (xx + i) % 3 == 0 and abs(rel) < 0.8:
                    continue              # pontas penduradas da camada
                if escuro:
                    c = 13 if rel < -0.55 else 3
                    if rel < -0.8:
                        c = 14
                else:
                    if rel < -0.7 or (y == ini and abs(rel) < 0.5):
                        c = 15
                    elif rel < -0.35:
                        c = 14 if not pont(xx, y, 0.3) else 15
                    elif rel < 0.3:
                        c = 14 if not pont(xx, y, 0.45) else 13
                    else:
                        c = 13
                    if y >= fim - 2 and rel > -0.5:
                        c = 13
                    if rel > 0.8 and y >= fim - 2:
                        c = 30 if False else 13
                t.put(xx, y, c, MUNDO)
    t.put(x, topo - 1, 15 if not escuro else 13, MUNDO)


def copa(t, circulos, rng, frutos=None, tag=MUNDO):
    xs = [c[0] for c in circulos]
    ys = [c[1] for c in circulos]
    rmax = max(c[2] for c in circulos)
    pixels = []
    for y in range(int(min(ys) - rmax - 1), int(max(ys) + rmax + 2)):
        for x in range(int(min(xs) - rmax - 1), int(max(xs) + rmax + 2)):
            melhor = None
            for cx, cy, r in circulos:
                d = math.hypot(x - cx, y - cy) / r
                if d <= 1 and (melhor is None or d < melhor[0]):
                    melhor = (d, (x - cx) / r, (y - cy) / r)
            if melhor is None:
                continue
            d, nx, ny = melhor
            luz = -(nx * 0.55 + ny * 0.85)
            if luz > 0.62:
                c = 16 if pont(x, y, 0.4) else 15
            elif luz > 0.25:
                c = 15 if pont(x, y, clamp((luz - 0.25) / 0.37 + 0.2)) else 14
            elif luz > -0.25:
                c = 14
            elif luz > -0.5:
                c = 13 if pont(x, y, clamp((-0.25 - luz) / 0.25 + 0.2)) else 14
            else:
                c = 13
            pixels.append((x, y, c))
    for x, y, c in pixels:
        t.put(x, y, c, tag)
    # contorno com o tom mais escuro só embaixo e à direita
    conj = {(x, y) for x, y, _ in pixels}
    for x, y, _ in pixels:
        if (x, y + 1) not in conj or (x + 1, y) not in conj:
            if t.p[y][x] != 15 and t.p[y][x] != 16:
                t.put(x, y, 13, tag)
    if frutos:
        for _ in range(frutos):
            x, y, c = rng.choice(pixels)
            if c in (14, 13):
                t.put(x, y, 27, tag)
                if (x + 1, y) in conj:
                    t.put(x + 1, y, 20, tag)


def arvore_larga(t, x, base, alt, rng):
    # tronco com galhos
    for y in range(base - alt // 2, base + 1):
        t.put(x, y, 9, MUNDO)
        t.put(x + 1, y, 9 if y < base - 3 else 8, MUNDO)
        t.put(x + 2, y, 8, MUNDO)
    t.put(x - 1, base, 9, MUNDO)
    t.put(x + 3, base, 8, MUNDO)
    for i in range(4):
        t.put(x - 1 - i // 2, base - alt // 2 - i, 9, MUNDO)
        t.put(x + 3 + i // 2, base - alt // 2 - i + 1, 8, MUNDO)
    cy = base - alt + alt // 3
    r = alt / 3.2
    circ = [(x + 1, cy, r), (x - r * 0.9, cy + r * 0.45, r * 0.8), (x + 2 + r * 0.95, cy + r * 0.4, r * 0.82),
            (x - r * 0.3, cy - r * 0.55, r * 0.7), (x + r * 0.8, cy - r * 0.3, r * 0.65)]
    copa(t, circ, rng)


def arbusto(t, x, base, larg, rng, frutos=0):
    r = larg / 2.6
    circ = [(x, base - r + 1, r), (x - r * 0.9, base - r * 0.6 + 1, r * 0.75),
            (x + r * 0.95, base - r * 0.55 + 1, r * 0.7)]
    copa(t, circ, rng, frutos=frutos)


def capim(t, x, base, rng, n=None, seco=False):
    n = n or rng.randint(3, 5)
    for i in range(n):
        xx = x + i - n // 2
        h = rng.randint(2, 4) if abs(i - n // 2) < 2 else rng.randint(1, 3)
        for k in range(h):
            inc = (k // 2) * (1 if i > n // 2 else -1 if i < n // 2 else 0)
            if seco:
                c = 16 if k >= h - 2 else 10
            else:
                c = 15 if k == h - 1 else 14 if k else 13
            t.put(xx + inc, base - 1 - k, c, MUNDO)


def junco(t, x, base, alt, tag=MUNDO):
    for k in range(alt):
        t.put(x, base - 1 - k, 16 if k > alt // 2 else 15 if k > 2 else 14, tag)
    t.put(x, base - alt - 1, 9, tag)
    t.put(x, base - alt - 2, 9, tag)
    t.put(x, base - alt - 3, 10, tag)
    t.put(x + 1, base - alt // 2, 16, tag)


def samambaia_frente(t, x, base, alt, rng, espelho=False):
    """Planta do primeiro plano: tufo cheio de frondes arqueadas que saem da base e caem nas
    pontas, com folíolos em todas as linhas. Borda de cima clara (14 e 15), miolo escuro (13)
    e a sombra (3) só junto da base. `rng` não é usado (a forma é fixa por `alt`)."""
    s = -1 if espelho else 1
    pontos = []   # (x, y, tipo) em ponto flutuante; tipo 2 = nervura, 1 = folíolo
    # (ângulo em graus a partir da vertical, comprimento relativo)
    frondes = ((-52, .70), (-30, .90), (-10, 1.0), (8, .96), (26, .88), (48, .72))
    for ang, rel in frondes:
        a = math.radians(ang * s)
        comp = alt * rel
        n = max(2, int(comp * 2))
        for i in range(n + 1):
            u = i / n
            d = comp * u
            px = x + math.sin(a) * d + (1 if ang * s > 0 else -1) * comp * 0.12 * u * u
            py = base - math.cos(a) * d + comp * 0.30 * u * u * abs(math.sin(a))
            pontos.append((px, py, 2))
            # folíolos dos dois lados, mais longos no meio da fronde
            lf = int(round((1 - u) * (0.5 + u) * alt * 0.13))
            if u > 0.12 and lf > 0:
                nx, ny = -math.cos(a), -math.sin(a)
                for k in range(1, lf + 1):
                    for lado in (1, -1):
                        pontos.append((px + nx * k * lado, py + ny * k * lado + k * 0.35, 1))
    # o tufo cabe em alt * 0,54 para cada lado (a peça de 16 px tem o pé na coluna 7)
    larg = max(abs(px - x) for px, _, _ in pontos)
    f = min(1.0, alt * 0.54 / larg)
    cheio = {}
    for px, py, tipo in pontos:
        chave = (int(round(x + (px - x) * f)), int(round(py)))
        cheio[chave] = max(cheio.get(chave, 0), tipo)
    for (cx, cy), tipo in cheio.items():
        if cy > base:
            continue
        acima = (cx, cy - 1) in cheio
        if (cy == base and abs(cx - x) <= 1) or (cy == base - 1 and cx == x):
            c = 3
        elif not acima:
            c = 15 if (cx * 3 + cy) % 3 == 0 else 14
        elif tipo == 2:
            c = 14 if (cx * 7 + cy * 3) % 5 == 0 and cy < base - 2 else 13
        else:
            c = 13
        t.put(cx, cy, c, FRENTE)


# ---------------------------------------------------------------- cabanas e fogo

def cabana(t, x0, base, rng):
    """Cabana de galhos 16x16: galhos inclinados, folhas na cobertura e porta escura."""
    cx = x0 + 7.5
    for y in range(base - 15, base + 1):
        r = y - (base - 15)
        hw = 1.0 + r * 0.47
        for x in range(int(cx - hw + 0.5), int(cx + hw + 0.5) + 1):
            if x < x0 or x > x0 + 15:
                continue
            dx = x - cx
            rel = dx / hw
            porta_hw = max(0, (r - 7) * 0.42)
            if r >= 8 and abs(dx + 0.5) < porta_hw:
                c = 30 if abs(dx + 0.5) < porta_hw - 1 or r > 13 else 8
                if r == 8:
                    c = 8
            else:
                # galhos inclinados alternando com faixas de folhas
                faixa = (int(round(x - cx * 0 + (y - base) * (0.55 if dx < 0 else -0.55))) % 4)
                if rel < -0.82:
                    c = 10
                elif rel > 0.82:
                    c = 8
                elif faixa == 0:
                    c = 10 if dx < 0 else 9
                elif faixa == 1:
                    c = 9 if dx < 0 else 8
                else:
                    folha = r < 11 or rng.random() < 0.4
                    if folha:
                        c = 15 if (dx < -1 and pont(x, y, 0.5)) else 14 if dx < 1.5 else 13
                    else:
                        c = 9 if dx < 0 else 8
            t.put(x, y, c, MUNDO)
    # pontas dos galhos cruzadas no topo
    for i, (dx, dy) in enumerate(((-1, -1), (-2, -2), (2, -1), (3, -2), (0, -1))):
        t.put(int(cx) + dx, base - 15 + dy, 10 if dx < 0 else 9, MUNDO)
    # beiral de folhas caídas e pedra na base
    for x in range(x0, x0 + 16):
        if rng.random() < 0.3:
            t.put(x, base, 14, MUNDO)


def fogueira(t, x, y, hora):
    chama = [
        "....r....",
        "...ro..r.",
        ".r.ror.r.",
        ".rroyorr.",
        "..royyor.",
        ".royywyor",
        ".roywwyor",
        "..oyyyyo.",
    ]
    if hora == "noite":
        chama = ["...r.....", "...rr..r."] + chama
    cores = {"r": 20, "o": 21, "y": 22, "w": 31}
    alt = len(chama)
    for j, linha in enumerate(chama):
        for i, ch in enumerate(linha):
            if ch in cores:
                t.put(x - 4 + i, y - alt - 1 + j, cores[ch], FOGO)
    # lenha cruzada
    for i in range(-4, 5):
        t.put(x + i, y - 1, 9 if i < 0 else 8, FOGO)
    t.put(x - 3, y - 2, 10, FOGO)
    t.put(x + 3, y - 2, 9, FOGO)
    t.put(x - 1, y - 1, 21, FOGO)
    t.put(x + 1, y - 1, 20, FOGO)
    # anel de pedras
    for px in (x - 6, x - 5, x + 5, x + 6):
        t.put(px, y, 11, MUNDO)
        t.put(px, y - 1, 12 if px < x else 11, MUNDO)
    for px in (x - 4, x - 3, x + 3, x + 4):
        t.put(px, y, 12, MUNDO)
    # fagulhas e fumaça
    if hora == "noite":
        for px, py in ((x - 2, y - 14), (x + 3, y - 17), (x, y - 21), (x + 1, y - 13)):
            t.put(px, py, 22, FOGO)
        t.put(x - 3, y - 19, 21, FOGO)
    else:
        for k, (px, py) in enumerate(((x, y - 11), (x + 1, y - 13), (x + 1, y - 14), (x + 2, y - 16),
                                       (x + 2, y - 17), (x + 3, y - 19), (x + 4, y - 21), (x + 5, y - 22),
                                       (x + 6, y - 24))):
            if pont(px, py, 0.6 - k * 0.04):
                t.put(px, py, 12 if k < 4 else 11, FOGO)
        t.put(x - 1, y - 12, 22, FOGO)


# ---------------------------------------------------------------- pessoas

ADULTO = [
    "..hhhh..",
    ".hHHhhh.",
    ".hhhSeS.",
    "..hsSSS.",
    "..tTTT..",
    ".stTTTS.",
    ".stTTtS.",
    ".s.tTt.S",
    "..tttt..",
    "..l..L..",
    "..l..L..",
    ".ff..FF.",
]
ADULTO_ANDA = [
    "..hhhh..",
    ".hHHhhh.",
    ".hhhSeS.",
    "..hsSSS.",
    "..tTTT..",
    ".stTTTS.",
    "s.tTTtS.",
    "s.tTTt.S",
    "..tttt..",
    ".l...L..",
    ".l....L.",
    "ff....FF",
]
ADULTO_APONTA = [
    "..hhhh..",
    ".hHHhhh.",
    ".hhhSeS.",
    "..hsSSS.",
    "..tTTTSS",
    ".stTTT..",
    ".stTTt..",
    ".s.tTt..",
    "..tttt..",
    "..l..L..",
    "..l..L..",
    ".ff..FF.",
]
ADULTO_LANCA = [
    "..hhhh.B",
    ".hHHhhhB",
    ".hhhSeSb",
    "..hsSSSb",
    "..tTTTSb",
    ".stTTtSb",
    ".stTTt.b",
    ".s.tTt.b",
    "..tttt.b",
    "..l..L.b",
    "..l..L.b",
    ".ff..FFb",
]
SENTADO = [
    "........",
    "........",
    "..hhhh..",
    ".hHHhhh.",
    ".hhhSeS.",
    "..hsSSS.",
    "..tTTT..",
    ".stTTTS.",
    ".stTTtS.",
    ".stTTSSS",
    "..llLLLS",
    ".BBBBBBf",
]
CRIANCA = [
    ".hhh..",
    "hHhSS.",
    "hhSeS.",
    ".sSS..",
    "stTTS.",
    ".tTt..",
    ".l.L..",
    ".f.F..",
]
CRIANCA_MAO = [
    ".hhh..",
    "hHhSS.",
    "hhSeS.",
    ".sSS.S",
    "stTTS.",
    ".tTt..",
    ".l.L..",
    ".f.F..",
]

SOMBRA_PELE = {26: 25, 25: 24, 24: 23, 23: 8}
SOMBRA_TECIDO = {27: 20, 28: 18, 29: 5}
LUZ_CABELO = {30: 8, 8: 9, 23: 24, 12: 31, 10: 16}


def pessoa(t, x, base, molde, pele, tecido, cabelo, espelho=False):
    cores = {
        "h": cabelo, "H": LUZ_CABELO[cabelo], "S": pele, "s": SOMBRA_PELE[pele], "e": 30,
        "T": tecido, "t": SOMBRA_TECIDO[tecido], "L": pele, "l": SOMBRA_PELE[pele],
        "F": 8, "f": 30, "B": 10, "b": 9,
    }
    alt, larg = len(molde), len(molde[0])
    for j, linha in enumerate(molde):
        if espelho:
            linha = linha[::-1]
        for i, ch in enumerate(linha):
            if ch == ".":
                continue
            px, py = x + i, base - alt + 1 + j
            lado = 1 if ((px + 0.5) - FOGO_X) * ((x + larg / 2) - FOGO_X) <= 0 or \
                abs((px + 0.5) - FOGO_X) < abs((x + larg / 2) - FOGO_X) else 0
            t.put(px, py, cores[ch], PESSOA, lado)


# ---------------------------------------------------------------- composição

def pintar_mundo(t, hora, rng):
    sup, tipo = perfil(random.Random(11))
    camadas = pintar_terreno(t, sup, tipo, random.Random(12))
    pintar_pedras_solo(t, camadas, random.Random(13))
    pintar_superficie(t, sup, tipo, random.Random(14))

    r = random.Random(15)
    # floresta do fundo no morro (pinheiros escuros, segundo plano do mundo)
    for x, alt in ((338, 24), (362, 30), (392, 28), (416, 33), (446, 29), (470, 31)):
        pinheiro(t, x, sup[x] - 2, alt, r, escuro=True)
    # pinheiros do plano principal
    for x, alt in ((322, 22), (350, 30), (378, 34), (404, 28), (432, 36), (458, 30), (478, 26)):
        pinheiro(t, x, sup[x], alt, r)
    arvore_larga(t, 306, sup[306], 30, r)
    arvore_larga(t, 444, sup[444] + 1, 24, r)
    arvore_larga(t, 160, sup[160], 26, r)
    # arbustos, alguns com frutinhas
    for x, l, fr in ((186, 10, 3), (296, 12, 4), (340, 9, 0), (418, 10, 2), (154, 7, 0), (466, 8, 0)):
        arbusto(t, x, sup[x], l, r, frutos=fr)
    # capim e juncos
    for x in (176, 258, 312, 330, 366, 392, 424, 452):
        capim(t, x, sup[x], r)
    for x in (122, 132, 140, 147):
        capim(t, x, sup[x], r, seco=True)
    for x, a in ((108, 7), (111, 9), (114, 6)):
        junco(t, x, sup[x], a)
    # pedras afloradas na superfície
    pedra(t, 144, sup[144], 3, 2)
    pedra(t, 314, sup[314] - 1, 4, 2, musgo=True)
    pedra(t, 386, sup[386], 3, 2, musgo=True)
    pedra(t, 290, sup[290], 2, 1)
    # tronco à deriva e conchas na praia
    for x in range(118, 128):
        s = sup[x]
        t.put(x, s - 1, 10 if x < 127 else 9, MUNDO)
        t.put(x, s - 2, 9 if x % 3 else 10, MUNDO)
    t.put(117, sup[117] - 2, 8, MUNDO)
    t.put(128, sup[128] - 2, 8, MUNDO)
    t.put(133, sup[133] - 1, 31, MUNDO)
    t.put(137, sup[137] - 1, 27, MUNDO)

    pintar_raizes(t, sup, camadas, [160, 186, 306, 322, 350, 378, 404, 432, 444, 458, 296],
                  random.Random(16))

    # cabanas e fogueira
    cabana(t, 164, SOLO - 1, random.Random(17))
    cabana(t, 268, SOLO - 1, random.Random(18))
    fogueira(t, FOGO_X, FOGO_Y, hora)

    # pessoas: 6 adultos e 2 crianças
    pessoa(t, 136, SOLO - 1 + (sup[136] - SOLO), ADULTO_LANCA, 24, 28, 30)          # pescador na praia
    pessoa(t, 188, 119, ADULTO_ANDA, 26, 27, 23)                                    # chega com a lança... caminhando
    pessoa(t, 198, 119, CRIANCA, 25, 29, 8)
    pessoa(t, 206, 119, SENTADO, 23, 28, 30)
    pessoa(t, 234, 119, ADULTO_APONTA, 25, 29, 8, espelho=True)
    pessoa(t, 244, 119, CRIANCA_MAO, 26, 27, 10, espelho=True)
    pessoa(t, 252, 119, ADULTO, 24, 27, 12, espelho=True)                           # anciã
    pessoa(t, 288, 119, ADULTO_ANDA, 25, 28, 23, espelho=True)

    # primeiro plano: plantas escuras na frente
    samambaia_frente(t, 2, 125, 14, r)
    samambaia_frente(t, 7, 127, 10, r, espelho=True)
    samambaia_frente(t, 474, sup[474] + 6, 15, r, espelho=True)
    samambaia_frente(t, 468, sup[468] + 8, 10, r)
    samambaia_frente(t, 316, sup[316] + 5, 9, r)
    return sup


def aplicar_horario(t, hora, sup):
    if hora == "entardecer":
        # luz de contorno: o sol baixo à esquerda acende a borda esquerda das pessoas
        borda = [(x, y) for y in range(H) for x in range(1, W)
                 if t.tag[y][x] == PESSOA and t.tag[y][x - 1] != PESSOA]
        for x, y in borda:
            t.p[y][x] = CONTORNO_SOL.get(t.p[y][x], t.p[y][x])
        for y in range(H):
            for x in range(W):
                if t.tag[y][x] in (MUNDO, FRENTE) and t.p[y][x] in REMAP_ENTARDECER:
                    # só bordas iluminadas por cima ficam douradas
                    if y > 0 and t.tag[y - 1][x] in (CEU,) or t.p[y][x] != 15:
                        t.p[y][x] = REMAP_ENTARDECER[t.p[y][x]]
        return
    if hora != "noite":
        return
    novo = [linha[:] for linha in t.p]
    for y in range(H):
        for x in range(W):
            c, tag = t.p[y][x], t.tag[y][x]
            if tag in (FOGO, AGUA):
                continue
            dx, dy = (x - FOGO_X), (y - (FOGO_Y - 5)) * 1.7
            d = math.hypot(dx, dy)
            noite = REMAP_NOITE.get(c, c)
            if tag == CEU:
                noite = c        # céu e montanhas já foram pintados com as cores da noite
                if noite in (30, 3, 4) and pont(x, y, clamp((40 - d) / 10)):
                    noite = {30: 3, 3: 4, 4: 5}[noite]
                novo[y][x] = noite
                continue
            if tag == FRENTE:
                novo[y][x] = 30 if c == 3 else 3
                continue
            if tag == MUNDO and y > sup[x] + 3:
                novo[y][x] = noite
                continue
            # anéis de luz com pontilhado só numa faixa estreita na borda
            nivel = clamp((62 - d) / 3) + clamp((34 - d) / 3)           # 2 = perto, 1 = médio, 0 = noite
            if tag == PESSOA and not t.lado[y][x]:
                nivel -= 1
            if nivel >= 1:
                perto = pont(x, y, clamp(nivel - 1))
                novo[y][x] = FOGO_PERTO.get(c, c) if perto else FOGO_MEDIO.get(c, c)
            else:
                novo[y][x] = FOGO_MEDIO.get(c, c) if pont(x, y, clamp(nivel)) else noite
    # sombras das pessoas no chão, projetadas para longe do fogo
    for x in range(W):
        y = sup[x] if 0 <= x < W else SOLO
        if not 150 < x < 300:
            continue
        acima = [t.tag[yy][x] == PESSOA for yy in range(y - 4, y)]
        if any(acima):
            lado = 1 if x > FOGO_X else -1
            for k in range(1, 4):
                xx = x + lado * k
                if t.tag[y][xx] == MUNDO and t.tag[y - 1][xx] != PESSOA:
                    novo[y][xx] = REMAP_NOITE.get(t.p[y][xx], t.p[y][xx])
    t.p = novo


def render(hora):
    cfg = HORARIOS[hora]
    rng = random.Random(7)
    t = Tela()
    pintar_ceu(t, cfg, rng)
    if hora == "noite":
        pintar_lua(t, cfg, random.Random(3))
    else:
        pintar_sol(t, cfg)
    pintar_nuvens(t, cfg, hora, random.Random(4))
    pintar_fundo(t, cfg, hora, random.Random(5))
    sup = pintar_mundo(t, hora, rng)
    pintar_agua(t, sup, cfg, hora, random.Random(6))
    aplicar_horario(t, hora, sup)
    pal = carregar_paleta()
    img = Image.new("RGB", (W, H))
    img.putdata([pal[c] for linha in t.p for c in linha])
    return img

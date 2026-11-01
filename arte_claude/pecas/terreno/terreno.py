"""Blocos de terreno 8x8 tirados da cena-alvo, e a montagem de teste só com eles.

Regra de montagem (a mesma que o motor deve seguir): o mundo é dividido em colunas de
8 px. Cada coluna tem uma altura de superfície livre (qualquer y) e uma pilha de blocos
que começa nessa altura. Como cada coluna tem um deslocamento diferente, as fronteiras
entre as camadas do solo ficam irregulares, como na cena.
"""
from pathlib import Path
import math
import random
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import cena, clamp, gravar, pont, folha_quadros  # noqa: E402

T = 8


def vazio():
    return [[None] * T for _ in range(T)]


def graos(rng, base, pares):
    """Preenche com a cor base e salpica grãos: pares = [(cor, probabilidade), ...]."""
    b = vazio()
    for y in range(T):
        for x in range(T):
            c = base
            v = rng.random()
            acum = 0
            for cor, prob in pares:
                acum += prob
                if v < acum:
                    c = cor
                    break
            b[y][x] = c
    return b


def terra(rng):
    return graos(rng, 9, [(10, 0.07), (8, 0.06)])


def terra_escura(rng):
    return graos(rng, 8, [(9, 0.06), (30, 0.025)])


def areia(rng, topo=False):
    b = graos(rng, 12, [(11, 0.10), (10, 0.05)])
    if topo:
        for x in range(T):
            b[0][x] = 31 if rng.random() < 0.25 else 12
            if b[1][x] == 11:
                b[1][x] = 12
    return b


def grama(rng, seca=False):
    """Superfície na linha 2; as linhas 0 e 1 têm só os tufos da borda irregular."""
    b = vazio()
    base = terra(rng) if not seca else areia(rng)
    for y in range(2, T):
        b[y] = base[y][:]
    claro, medio, escuro = (15, 14, 13) if not seca else (16, 15, 14)
    for x in range(T):
        b[2][x] = claro if not seca or x % 3 else 15
        b[3][x] = medio
        b[4][x] = escuro if not seca else (14 if x % 2 else base[4][x])
        if not seca and (x * 7 + rng.randint(0, 4)) % 5 < 2:
            b[5][x] = escuro
    # tufos acima da linha
    for x in range(T):
        v = rng.random()
        if v < 0.4:
            b[1][x] = claro
        if v < 0.12:
            b[0][x] = claro
            b[1][x] = medio
    return b


def chao_batido(rng):
    """Terra batida da clareira em volta da fogueira (superfície na linha 2, como a grama)."""
    b = vazio()
    base = terra(rng)
    for y in range(2, T):
        b[y] = base[y][:]
    for x in range(T):
        b[2][x] = 12 if rng.random() < 0.12 else 10
        b[3][x] = 10 if rng.random() < 0.12 else 9
        if rng.random() < 0.1:
            b[4][x] = 9
    return b


def com_pedra(b, cx, cy, rx=2, ry=1):
    for y in range(T):
        for x in range(T):
            u, v = (x - cx) / (rx + 0.5), (y - cy) / (ry + 0.5)
            if u * u + v * v <= 1:
                b[y][x] = 12 if v < -0.2 and u < 0.3 else 8 if (u * u + v * v) > 0.55 and v > 0.2 else 11
    return b


def transicao(rng, cima, baixo, linha=4):
    """Bloco com a fronteira entre duas camadas: pontilhado numa faixa de 2 px, com dentes."""
    a, z = cima(rng), baixo(rng)
    b = vazio()
    dentes = [linha + rng.choice((-1, 0, 0, 1)) for _ in range(T)]
    for y in range(T):
        for x in range(T):
            usar_baixo = y > dentes[x] or (y == dentes[x] and pont(x, y, 0.5))
            b[y][x] = z[y][x] if usar_baixo else a[y][x]
    return b


def raiz(b, rng, cor=10, sombra=30, fase=0.0):
    """Raiz que entra e sai do bloco na coluna 4: blocos de raiz empilhados formam uma
    raiz contínua, como as raízes longas do morro na cena."""
    import math as _m
    for y in range(T):
        xi = 4 + int(round(1.2 * _m.sin(y * 0.75 + fase)))
        if y in (0, T - 1):
            xi = 4
        b[y][xi] = cor
        b[y][xi + 1] = sombra if b[y][xi + 1] == 8 else 8
        if y == 3 + int(fase) % 3:
            lado = rng.choice((-1, 1))
            for k in (1, 2):
                b[y + k // 2][xi + lado * k] = cor if k < 2 else 9
    return b


def pedra_solo(rng):
    b = terra_escura(rng)
    rx, ry, cx, cy = 3, 2, 4, 4
    for y in range(T):
        for x in range(T):
            u, v = (x - cx) / (rx + 0.5), (y - cy) / (ry + 0.5)
            if u * u + v * v <= 1:
                borda = (u * u + v * v) > 0.55
                c = 12 if v < -0.2 and u < 0.3 else 8 if borda and (v > 0.2 or u > 0.5) else 11
                b[y][x] = c
    return b


ROCHA_W, ROCHA_H = 64, 16


def textura_rocha(rng, fundo=0.2):
    """Rocha da cena (lajes de Voronoi) num padrão de 64x16 que se repete sem emenda.
    É cortada em 16 blocos (rocha_1 a rocha_16) que o motor põe em grade fixa."""
    sementes = [(rng.uniform(0, ROCHA_W), rng.uniform(0, ROCHA_H)) for _ in range(10)]
    tex = [[11] * ROCHA_W for _ in range(ROCHA_H)]
    for y in range(ROCHA_H):
        for x in range(ROCHA_W):
            ds = []
            for sx, sy in sementes:
                for ox in (-ROCHA_W, 0, ROCHA_W):
                    for oy in (-ROCHA_H, 0, ROCHA_H):
                        ds.append(((x - sx - ox) ** 2 + ((y - sy - oy) * 1.5) ** 2, sx + ox, sy + oy))
            ds.sort()
            (d1, sx, sy), (d2, _, _) = ds[0], ds[1]
            borda = math.sqrt(d2) - math.sqrt(d1)
            dx, dy = x - sx, y - sy
            if borda < 1.0:
                c = 30 if pont(x, y, 0.25) else 8
            elif borda < 1.6 and dy < 0 and dx < 1.5:
                c = 12
            elif dy > 0.3 and pont(x, y, 0.45 + fundo * 0.4):
                c = 8
            elif pont(x, y, fundo * 0.35):
                c = 8
            else:
                c = 11
            tex[y][x] = c
    blocos = {}
    por_linha = ROCHA_W // T
    for k in range(por_linha * ROCHA_H // T):
        bx, by = (k % por_linha) * T, (k // por_linha) * T
        blocos[f"rocha_{k + 1}"] = [linha[bx:bx + T] for linha in tex[by:by + T]]
    return blocos


def borda_rocha(rng, linha=4):
    """Fim da terra escura: terra em cima, dentes irregulares e transparente embaixo,
    deixando aparecer a rocha da grade."""
    a = terra_escura(rng)
    b = vazio()
    dentes = [linha + rng.choice((-1, 0, 0, 1)) for _ in range(T)]
    for y in range(T):
        for x in range(T):
            if y < dentes[x] or (y == dentes[x] and pont(x, y, 0.5)):
                b[y][x] = a[y][x]
    return b


def agua(fracao_ini, fracao_fim, rng):
    b = vazio()
    for y in range(T):
        f = fracao_ini + (fracao_fim - fracao_ini) * y / (T - 1)
        for x in range(T):
            b[y][x] = 17 if pont(x, y, f) else 18
    return b


def agua_superficie(quadro):
    """Linha 0: ondinhas; linha 1: linha d'água com espuma. Desliza 2 px por quadro."""
    b = vazio()
    d = quadro * 2
    for x in range(T):
        k = (x + d) % T
        if k in (2, 3):
            b[0][x] = 19 if k == 3 else 18
        b[1][x] = 18 if k in (5, 6) else 19
        for y in range(2, T):
            b[y][x] = 18
    for gx, gy in ((1, 3), (5, 5)):
        b[gy][(gx + d) % T] = 19
        b[gy][(gx + d + 1) % T] = 19
    return b


def gerar_blocos():
    r = random.Random
    blocos = {
        "grama_a": grama(r(101)),
        "grama_b": grama(r(102)),
        "grama_seca": grama(r(103), seca=True),
        "terra_a": terra(r(104)),
        "terra_b": terra(r(105)),
        "terra_raiz": raiz(terra(r(106)), r(107), cor=10, sombra=8),
        "terra_raiz_b": raiz(terra(r(136)), r(137), cor=10, sombra=8, fase=3.1),
        "chao_batido": chao_batido(r(138)),
        "terra_escura_topo": transicao(r(108), terra, terra_escura),
        "terra_escura_topo_b": com_pedra(transicao(r(130), terra, terra_escura, linha=2), 4, 5),
        "terra_escura_topo_c": transicao(r(131), terra, terra_escura, linha=6),
        "terra_escura_a": terra_escura(r(109)),
        "terra_escura_b": terra_escura(r(110)),
        "terra_escura_raiz": raiz(terra_escura(r(111)), r(112), fase=1.6),
        "pedra_solo": pedra_solo(r(113)),
        "rocha_borda": borda_rocha(r(114)),
        "rocha_borda_b": borda_rocha(r(132), linha=2),
        "rocha_borda_c": com_pedra(borda_rocha(r(133), linha=6), 3, 2),
        "areia_superficie": areia(r(118), topo=True),
        "areia_a": areia(r(119)),
        "areia_b": areia(r(120)),
        "areia_base": transicao(r(121), areia, terra_escura, linha=1),
        "agua": agua(0.05, 0.5, r(122)),
        "agua_funda": agua(0.75, 1.0, r(123)),
    }
    blocos.update(textura_rocha(r(115)))
    quadros = [agua_superficie(q) for q in range(4)]
    return blocos, quadros


# ---------------------------------------------------------------- montagem por colunas

def perfil_colunas():
    sup, tipo = cena.perfil(random.Random(11))
    cols = []
    for c in range(cena.W // T):
        xs = range(c * T, c * T + T)
        s = int(round(sum(sup[x] for x in xs) / T))
        tp = tipo[c * T + 4]
        if 140 <= c * T + 4 < 156:
            tp = "seca"
        cols.append((s, tp))
    return cols


COLUNAS_RAIZ = {160 // 8, 186 // 8, 306 // 8, 322 // 8, 350 // 8, 378 // 8, 404 // 8, 432 // 8, 444 // 8, 458 // 8, 296 // 8}


def escolher(nome_a, nome_b, c, y):
    return nome_a if (c * 7 + y // 8 * 3 + (c * y) % 5) % 3 else nome_b


def pilha(c, s, tp):
    """Lista (y, nome do bloco) de uma coluna, de cima para baixo."""
    itens = []
    if tp == "areia" and s > cena.NIVEL_AGUA:
        for y in (y for y in (120, 128, 136, 144, 152) if y < s):
            itens.append((y, "agua_superficie" if y == 120 else "agua" if y == 128 else "agua_funda"))
    if tp == "grama" and 25 <= c <= 30:
        itens.append((s - 2, "chao_batido"))
        y = s + 6
    elif tp == "grama":
        itens.append((s - 2, escolher("grama_a", "grama_b", c, s)))
        y = s + 6
    elif tp == "seca":
        itens.append((s - 2, "grama_seca"))
        y = s + 6
    else:
        itens.append((s, "areia_superficie"))
        y = s + 8
    fase = "terra" if tp == "grama" else "areia"
    raizes = 3 if c in COLUNAS_RAIZ else 0
    while y < cena.H:
        centro = y + 4
        if fase == "areia" or (fase == "terra" and centro >= 130):
            var = ("", "_b", "_c")[(c * 5 + c // 3) % 3]
            itens.append((y, "terra_escura_topo" + var if fase == "terra" else "areia_base"))
            fase = "escura"
        elif fase == "escura" and centro >= 139:
            itens.append((y, "rocha_borda" + ("", "_b", "_c")[(c * 7 + c // 2) % 3]))
            break                       # daqui para baixo vale a grade fixa de rocha
        elif fase == "terra":
            if raizes:
                itens.append((y, "terra_raiz_b" if raizes == 2 else "terra_raiz"))
                raizes -= 1
            else:
                itens.append((y, escolher("terra_a", "terra_b", c, y)))
        elif fase == "areia":
            itens.append((y, escolher("areia_a", "areia_b", c, y)))
        elif fase == "escura":
            h = (c * 13 + y * 7) % 11
            if raizes:
                itens.append((y, "terra_escura_raiz"))
                raizes = 0
            elif h in (0, 4, 8):
                itens.append((y, "pedra_solo"))
            else:
                itens.append((y, escolher("terra_escura_a", "terra_escura_b", c, y)))
        y += 8
    return itens


def montar_terreno(blocos, quadros, quadro_agua=0, colunas=None):
    """Devolve (pixels 480x160 com None no vazio, etiquetas, superfície por coluna)."""
    W, H = cena.W, cena.H
    px = [[None] * W for _ in range(H)]
    tag = [[cena.CEU] * W for _ in range(H)]
    sup = [0] * W
    # rocha em grade fixa (y múltiplo de 8), por baixo das pilhas das colunas
    for y0 in range(128, H, T):
        for x0 in range(0, W, T):
            k = (x0 // T) % (ROCHA_W // T) + (ROCHA_W // T) * ((y0 // T) % (ROCHA_H // T))
            bloco = blocos[f"rocha_{k + 1}"]
            for j in range(T):
                for i in range(T):
                    px[y0 + j][x0 + i] = bloco[j][i]
                    tag[y0 + j][x0 + i] = cena.MUNDO
    for c, (s, tp) in enumerate(colunas or perfil_colunas()):
        for x in range(c * T, c * T + T):
            sup[x] = s
        for y0, nome in pilha(c, s, tp):
            bloco = quadros[quadro_agua] if nome == "agua_superficie" else blocos[nome]
            etiqueta = cena.AGUA if nome.startswith("agua") else cena.MUNDO
            for j in range(T):
                for i in range(T):
                    cor = bloco[j][i]
                    y, x = y0 + j, c * T + i
                    if cor is not None and 0 <= y < H:
                        px[y][x] = cor
                        tag[y][x] = etiqueta
    return px, tag, sup


def principal():
    blocos, quadros = gerar_blocos()
    for nome, b in blocos.items():
        gravar(b, AQUI / f"{nome}.png")
    gravar(folha_quadros(quadros), AQUI / "agua_superficie_4q.png")
    # prancha com todos os blocos, para conferência
    nomes = list(blocos)
    larg = 8
    linhas = (len(nomes) + larg - 1) // larg
    prancha = [[None] * (larg * 10) for _ in range(linhas * 10 + 10)]
    for k, nome in enumerate(nomes):
        ox, oy = (k % larg) * 10 + 1, (k // larg) * 10 + 1
        for j in range(T):
            for i in range(T):
                prancha[oy + j][ox + i] = blocos[nome][j][i]
    for q, b in enumerate(quadros):
        for j in range(T):
            for i in range(T):
                prancha[linhas * 10 + 1 + j][q * 10 + 1 + i] = b[j][i]
    gravar(prancha, AQUI / "blocos_prancha.png")
    px, _, _ = montar_terreno(blocos, quadros)
    gravar(px, AQUI / "terreno_teste.png")
    print("terreno:", len(blocos), "blocos + água 4 quadros")


if __name__ == "__main__":
    principal()

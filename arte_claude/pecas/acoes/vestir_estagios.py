"""Roupas dos estágios 3 a 6 nas ações de 1x, nas brincadeiras, na caçada e na pesca, para os povos
avançados não voltarem ao visual do estágio 1. O estágio 2 não tem roupa própria (usa a de
`acoes/`).

As roupas são as mesmas dos habitantes de cada estágio (`estagioN/adulto_eN_*`), mas aplicadas
pela forma de cada quadro, e não por coordenadas fixas, porque nas ações o corpo agacha,
ajoelha e cai. Em cada quadro, a cabeça é o cabelo (h, H), o tronco é a roupa (T, b) e as
pernas são l e L.
- estágio 3: capa de pele nos ombros (n, com as pontas o) e colar de pedra (Z);
- estágio 4: capacete de ferro (Z, z) e fivela de metal no cinto; criança, só a fivela;
- estágio 5: túnica longa: as pernas viram roupa até os pés;
- estágio 6: chapéu de aba larga (n, aba o) e calças (d, o).
Capacete e chapéu ficam de fora quando há um objeto em cima da cabeça (cesto, pote, lança).

Saída: `estagioN/<mesmo nome>.png`. O motor procura a folha na pasta do estágio e, se não
achar, usa a de `acoes/`. As de inverno saem depois, em `estacoes/inverno/estagioN/`.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
import brincar  # noqa: E402
import cacada  # noqa: E402
import forte  # noqa: E402
import pesca  # noqa: E402

FOLHAS = {**forte.FOLHAS, **brincar.FOLHAS, **cacada.FOLHAS, **pesca.FOLHAS}


def pontos(g, chars):
    return [(x, y) for y, l in enumerate(g) for x, ch in enumerate(l) if ch in chars]


def cabeca(g):
    """(linha do topo do cabelo, colunas do cabelo nessa linha e na seguinte) ou None."""
    cab = pontos(g, "hH")
    if not cab:
        return None
    y0 = min(y for _, y in cab)
    return y0, [x for x, y in cab if y == y0], [x for x, y in cab if y == y0 + 1]


def algo_em_cima(g, y0, xs):
    """Há um objeto acima do cabelo, nas colunas da cabeça?"""
    return any(g[y][x] != "." for y in range(0, y0) for x in range(min(xs) - 1, max(xs) + 2)
               if 0 <= x < len(g[0]))


def e3(g, crianca):
    tronco = pontos(g, "Tb")
    if not tronco:
        return g
    y0 = min(y for _, y in tronco)
    xs = sorted(x for x, y in tronco if y == y0)
    for x in xs:
        g[y0][x] = "n"
    for x in (xs[0] - 1, xs[-1] + 1):
        if 0 <= x < len(g[0]) and g[y0][x] == ".":
            g[y0][x] = "o"
    if not crianca:
        abaixo = sorted(x for x, y in tronco if y == y0 + 1)
        if len(abaixo) >= 2:
            g[y0 + 1][abaixo[-2]] = "Z"
    return g


def e4(g, crianca):
    c = cabeca(g)
    if c and not crianca and not algo_em_cima(g, *c[:2]):
        y0, topo, seg = c
        for i, x in enumerate(sorted(topo)):
            g[y0][x] = "z" if i in (0, len(topo) - 1) else "Z"
        if seg:
            g[y0 + 1][min(seg)] = "z"
            g[y0 + 1][max(seg)] = "z"
    # fivela: no cinto (a última linha do tronco com b), ou no b da criança
    cinto = pontos(g, "b")
    if cinto:
        yc = max(y for _, y in cinto)
        xs = sorted(x for x, y in cinto if y == yc)
        g[yc][xs[0]] = "Z"
        if len(xs) > 2 and not crianca:
            g[yc][xs[-1]] = "z"
    return g


def e5(g, crianca):
    pernas = pontos(g, "lL")
    tronco = pontos(g, "Tb")
    if not pernas:
        return g
    for x, y in pernas:
        g[y][x] = "T"
    # a saia: preenche o vão entre as pernas nas 2 linhas logo abaixo do tronco
    if tronco:
        yb = max(y for _, y in tronco)
        for y in (yb + 1, yb + 2):
            if y >= len(g):
                continue
            xs = [x for x, yy in pernas if yy == y]
            if len(xs) >= 2:
                for x in range(min(xs), max(xs) + 1):
                    if g[y][x] == ".":
                        g[y][x] = "T"
        if not crianca:
            xs = sorted(x for x, y in tronco if y == yb and g[y][x] == "b")
            for x in xs:
                g[yb][x] = "T"
            if xs:
                g[yb][xs[len(xs) // 2]] = "b"
    return g


def e6(g, crianca):
    c = cabeca(g)
    if c and not algo_em_cima(g, *c[:2]):
        y0, topo, seg = c
        for x in topo:
            g[y0][x] = "n"
        if seg:
            for x in range(min(seg) - 1, max(seg) + 2):
                if 0 <= x < len(g[0]) and g[y0 + 1][x] in "hH.":
                    g[y0 + 1][x] = "o"
    for x, y in pontos(g, "l"):
        g[y][x] = "d"
    for x, y in pontos(g, "L"):
        g[y][x] = "o"
    return g


ROUPAS = {3: e3, 4: e4, 5: e5, 6: e6}


def vestir(quadros, n):
    out = []
    for q in quadros:
        g = [list(l) for l in q]
        crianca = len(q) == 8
        g = ROUPAS[n](g, crianca)
        out.append(["".join(l) for l in g])
    return out


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    base = {nome: f() for nome, f in FOLHAS.items()}
    for n in ROUPAS:
        for nome, qs in base.items():
            k.gravar(k.folha_quadros(k.pintar(vestir(qs, n))), PECAS / f"estagio{n}" / f"{nome}.png")
    # amostra: o quadro 0 e o 2 de cada folha, do estágio 1 ao 6 (o 2 é o 1)
    nomes = list(base)
    W, H = 4 + len(nomes) * 2 * 13, 5 * 16 + 4
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    grama = Image.open(PECAS / "terreno" / "grama_a.png")
    troca = k.hab.troca(24, 23, 27)
    for linha, n in enumerate((1, 3, 4, 5, 6)):
        y = 2 + linha * 16
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, y + 10))
        for i, nome in enumerate(nomes):
            qs = base[nome] if n == 1 else vestir(base[nome], n)
            for j, f in enumerate((0, 2 % len(qs))):
                q = para_imagem(trocar(k.pintar([qs[f]])[0], troca))
                img.alpha_composite(q, (4 + (i * 2 + j) * 13, y + 12 - q.height))
    img.save(AQUI / "amostra_estagios.png")
    img.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_estagios_4x.png")
    print("roupas dos estágios 3 a 6 em", len(base), "folhas")


if __name__ == "__main__":
    principal()

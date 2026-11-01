"""Peças do estágio 1 (coletores), tiradas das funções de desenho da cena-alvo.

Cada peça fica com a base (o ponto que toca o chão) na última linha do quadro.
"""
from pathlib import Path
import random
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import Deslocada, Folha, cena, folha_quadros, gravar, pont  # noqa: E402


def peca(w, h, desenhar):
    f = Folha(w, h)
    desenhar(Deslocada(f))
    return f.recortar()


def cabana(t, rng):
    """A cabana de galhos da cena, com o corpo de 14 linhas para caber em 16x16 com as pontas."""
    base, x0, alt = 15, 0, 14
    cx = x0 + 7.5
    for y in range(base - alt + 1, base + 1):
        r = (y - (base - alt + 1)) * 15 / (alt - 1)
        hw = 1.0 + r * 0.47
        for x in range(int(cx - hw + 0.5), int(cx + hw + 0.5) + 1):
            if x < x0 or x > x0 + 15:
                continue
            dx = x - cx
            rel = dx / hw
            porta_hw = max(0, (r - 7) * 0.42)
            if r >= 8 and abs(dx + 0.5) < porta_hw:
                c = 30 if abs(dx + 0.5) < porta_hw - 1 or r > 13 else 8
            else:
                faixa = int(round(x + (y - base) * (0.55 if dx < 0 else -0.55))) % 4
                if rel < -0.82:
                    c = 10
                elif rel > 0.82:
                    c = 8
                elif faixa == 0:
                    c = 10 if dx < 0 else 9
                elif faixa == 1:
                    c = 9 if dx < 0 else 8
                elif r < 11 or rng.random() < 0.4:
                    c = 15 if (dx < -1 and pont(x, y, 0.5)) else 14 if dx < 1.5 else 13
                else:
                    c = 9 if dx < 0 else 8
            t.put(x, y, c)
    topo = base - alt + 1
    for dx, dy in ((-1, -1), (-2, -2), (2, -1), (3, -2), (0, -1)):
        t.put(int(cx) + dx, topo + dy, 10 if dx < 0 else 9)
    for x in range(16):
        if rng.random() < 0.3:
            t.put(x, base, 14)


CHAMAS = [
    ["....r....", "...ro..r.", ".r.ror.r.", ".rroyorr.", "..royyor.", ".royywyor", ".roywwyor", "..oyyyyo."],
    ["...r.....", "...rr..r.", "..ror.ro.", ".rroyor..", ".royyorr.", ".royywyor", ".roywwyor", "..oyyyyo."],
    [".....r...", ".r..or...", ".r.roor..", "..royyorr", ".royyyor.", "royywwyor", ".roywwyo.", "..oyyyyo."],
    ["....r....", "....or.r.", "..r.ro.r.", "..royorr.", ".rroyyor.", ".royywyor", ".roywwyor", "..oyyyyo."],
]


def fogueira(t, quadro, acesa=True):
    x, y = 8, 15
    cores = {"r": 20, "o": 21, "y": 22, "w": 31}
    if acesa:
        chama = CHAMAS[quadro]
        for j, linha in enumerate(chama):
            for i, ch in enumerate(linha):
                if ch in cores:
                    t.put(x - 4 + i, y - len(chama) - 1 + j, cores[ch])
        for i in range(-4, 5):
            t.put(x + i, y - 1, 9 if i < 0 else 8)
        t.put(x - 3, y - 2, 10)
        t.put(x + 3, y - 2, 9)
        t.put(x - 1, y - 1, 21)
        t.put(x + 1, y - 1, 20)
    else:
        # lenha queimada, cinza e uma brasa
        for i in range(-4, 5):
            t.put(x + i, y - 1, 30 if i % 2 else 8)
        for i in range(-2, 3):
            t.put(x + i, y - 2, 11 if abs(i) < 2 else 30)
        t.put(x - 1, y - 3, 12)
        t.put(x, y - 3, 11)
        t.put(x + 1, y - 2, 20)
        t.put(x - 3, y - 2, 8)
    for px in (x - 6, x - 5, x + 5, x + 6):
        t.put(px, y, 11)
        t.put(px, y - 1, 12 if px < x else 11)
    for px in (x - 4, x - 3, x + 3, x + 4):
        t.put(px, y, 12)


def tronco_deriva(t):
    for x in range(2, 12):
        t.put(x, 7, 10 if x < 11 else 9)
        t.put(x, 6, 9 if x % 3 else 10)
    t.put(1, 6, 8)
    t.put(12, 6, 8)


def alga(t):
    for i, h in ((2, 7), (5, 5)):
        for k in range(h):
            t.put(i + (1 if (k // 2) % 2 else 0), 7 - k, 14 if k % 3 else 13)


def juncos(t):
    for x, a in ((1, 7), (4, 9), (6, 6)):
        cena.junco(t, x, 16, a)


def gerar():
    r = random.Random
    pecas = {
        "cabana_galhos": peca(16, 16, lambda t: cabana(t, r(17))),
        "fogueira_apagada": peca(16, 16, lambda t: fogueira(t, 0, acesa=False)),
        "arvore_copa_a": peca(40, 32, lambda t: cena.arvore_larga(t, 19, 31, 30, r(21))),
        "arvore_copa_b": peca(32, 32, lambda t: cena.arvore_larga(t, 14, 31, 24, r(22))),
        "pinheiro_a": peca(40, 40, lambda t: cena.pinheiro(t, 19, 39, 36, r(23))),
        "pinheiro_b": peca(24, 32, lambda t: cena.pinheiro(t, 11, 31, 26, r(24))),
        "pinheiro_fundo": peca(32, 32, lambda t: cena.pinheiro(t, 15, 31, 30, r(25), escuro=True)),
        "arbusto": peca(16, 8, lambda t: cena.arbusto(t, 8, 6, 10, r(26))),
        "arbusto_frutas": peca(16, 8, lambda t: cena.arbusto(t, 8, 6, 10, r(27), frutos=4)),
        "capim": peca(8, 8, lambda t: cena.capim(t, 4, 8, r(28), n=5)),
        "capim_seco": peca(8, 8, lambda t: cena.capim(t, 4, 8, r(29), n=5, seco=True)),
        "pedra_pequena": peca(8, 8, lambda t: cena.pedra(t, 4, 5, 3, 2)),
        "pedra_grande": peca(16, 16, lambda t: cena.pedra(t, 8, 10, 6, 5, musgo=True)),
        "juncos": peca(8, 16, juncos),
        "tronco_deriva": peca(16, 8, tronco_deriva),
        "alga": peca(8, 8, alga),
        "samambaia_frente": peca(16, 16, lambda t: cena.samambaia_frente(t, 7, 13, 13, r(30))),
    }
    fogo = [peca(16, 16, lambda t, q=q: fogueira(t, q)) for q in range(4)]
    return pecas, fogo


def principal():
    pecas, fogo = gerar()
    for nome, px in pecas.items():
        gravar(px, AQUI / f"{nome}.png")
    gravar(folha_quadros(fogo), AQUI / "fogueira_acesa_4q.png")
    print("estágio 1:", ", ".join(f"{n} {len(p[0])}x{len(p)}" for n, p in pecas.items()), "+ fogueira 4q")


if __name__ == "__main__":
    principal()

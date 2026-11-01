"""Estágio 6 (engenharia): canal de irrigação, moinho de vento, muralha com torre, barco,
casa de tijolo de dois andares, templo de cúpula, habitantes do estágio e as ruínas."""
from pathlib import Path
import math
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

import construcao as k  # noqa: E402


# ---------------------------------------------------------------- irrigação (blocos 8x8)

def canal():
    """Bloco de superfície (como a grama, superfície na linha 2): canal de água com borda de
    pedra. Repete na horizontal."""
    q = k.novo(8, 8)
    for x in range(8):
        k.put(q, x, 2, 11 if x % 4 else 12)          # borda de pedra
        k.put(q, x, 3, 19 if (x + 1) % 4 else 18)    # linha d'água
        k.put(q, x, 4, 18)
        k.put(q, x, 5, 17 if x % 2 else 18)
        k.put(q, x, 6, 8)
        k.put(q, x, 7, 9)
    return q


def canal_comporta():
    q = canal()
    for y in range(0, 7):
        k.put(q, 3, y, 10)
        k.put(q, 4, y, 9)
    k.put(q, 2, 0, 9)
    k.put(q, 5, 0, 9)
    return q


def roca_irrigada():
    """A roça madura do estágio 2 com um rego d'água entre os sulcos (16x16)."""
    import estagio2
    q = estagio2.roca("madura")
    for x in range(16):
        if x % 4 == 0:
            k.put(q, x, 13, 18)
            k.put(q, x, 14, 17)
    return q


# ---------------------------------------------------------------- moinho

def moinho(quadro):
    """Moinho de vento (32x40): torre de pedra, teto de tábuas e 4 pás que giram 22,5° por
    quadro (4 quadros fecham o ciclo, porque as pás se repetem a cada 90°)."""
    q = k.novo(32, 40)
    # torre afunilada
    for y in range(14, 40):
        meia = 4 + (y - 14) * 2.5 / 25
        for x in range(32):
            d = x - 15.5
            if abs(d) <= meia:
                c = 12 if d < 0 else 11
                if (y - 14) % 4 == 0 and abs(d) < meia - 0.5:
                    c = 11
                if d > meia - 1:
                    c = 8
                k.put(q, x, y, c)
    k.porta(q, 14, 33, 17, 39, arco=True, moldura=8)
    k.janela(q, 15, 22, larg=2, alt=2, peitoril=11)
    # teto cônico de tábuas
    for y in range(8, 15):
        meia = (y - 7) * 0.9
        for x in range(32):
            d = x - 15.5
            if abs(d) <= meia:
                k.put(q, x, y, 10 if d < 0 and x % 2 else 9 if d < 1 else 8)
    # pás
    cx, cy = 15.5, 13
    ang0 = quadro * math.pi / 8
    for p in range(4):
        a = ang0 + p * math.pi / 2
        for i in range(2, 12):
            x, y = cx + math.cos(a) * i, cy + math.sin(a) * i
            k.put(q, round(x), round(y), 9)
            # pano da pá, de um lado da haste
            for j in (1, 2, 3):
                px = x + math.cos(a + math.pi / 2) * j
                py = y + math.sin(a + math.pi / 2) * j
                if i > 3:
                    c = 9 if j == 3 or i == 11 else 31 if (i + j) % 3 else 12
                    k.put(q, round(px), round(py), c)
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
        k.put(q, 15 + dx, 12 + dy, 8)
    return q


# ---------------------------------------------------------------- muralha e barco

def muralha():
    """Trecho de muralha de 8x16 que repete na horizontal: ameias em cima."""
    q = k.novo(8, 16)
    k.parede(q, 0, 4, 7, 15, "pedra_lavrada", 61)
    for x in range(8):
        if x < 4:
            k.put(q, x, 2, 12 if x < 3 else 11)
            k.put(q, x, 3, 11 if x < 3 else 8)
        k.put(q, x, 4, 11)
    k.put(q, 0, 2, 12)
    return q


def torre():
    q = k.novo(16, 32)
    k.parede(q, 1, 6, 14, 31, "pedra_lavrada", 62)
    for x in range(0, 16):
        if x % 4 < 2:
            k.put(q, x, 2, 12 if x < 14 else 11)
            k.put(q, x, 3, 12 if x < 14 else 11)
        k.put(q, x, 4, 11)
        k.put(q, x, 5, 8)
    k.janela(q, 7, 12, larg=2, alt=4, peitoril=11)
    k.porta(q, 6, 25, 9, 31, arco=True, moldura=8)
    return q


def barco(quadro):
    """Barco a vela (24x16). Os 2 quadros balançam 1 px na água."""
    q = k.novo(24, 16)
    d = quadro
    for y in range(10, 15):
        r = y - 10
        x0, x1 = 2 + r, 21 - r // 2
        for x in range(x0, x1 + 1):
            c = 10 if y == 10 else 9 if y < 13 else 8
            if y == 11 and x % 4 == 0:
                c = 8
            k.put(q, x, y - d, c)
    k.put(q, 1, 9 - d, 9)
    k.put(q, 22, 9 - d, 9)
    for y in range(1, 10):
        k.put(q, 11, y - d, 9)
    for y in range(2, 9):
        for x in range(12, 12 + (y - 1)):
            k.put(q, x, y - d, 31 if x < 12 + (y - 1) - 1 else 12)
    k.put(q, 11, 0 - d + 1, 20)
    k.put(q, 10, 1 - d, 20)
    return q


# ---------------------------------------------------------------- casa e templo

def casa_tijolo_parede():
    q = k.novo(32, 32)
    k.parede(q, 3, 12, 28, 31, "tijolo", 63)
    for x in range(3, 29):
        k.put(q, x, 21, 12)                           # cinta entre os andares
    k.porta(q, 14, 24, 17, 31, arco=True, moldura=12)
    for x in (6, 22):
        k.janela(q, x, 15, peitoril=12)
        k.janela(q, x, 25, peitoril=12)
    k.janela(q, 14, 15, larg=4, peitoril=12)
    return q


def casa_tijolo_telhado(estilo):
    q = k.novo(32, 32)
    topo, alt = {"palha": (1, 12), "telha": (4, 9), "tabuas": (0, 13)}[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 64)
    return q


def templo_cupula():
    """Templo de cúpula (32x32): base de pedra lavrada, colunata e cúpula; o símbolo vai
    no alto (linhas 0-5)."""
    q = k.novo(32, 32)
    for y, (a, b) in zip(range(27, 32), ((3, 28), (2, 29), (2, 29), (1, 30), (1, 30))):
        for x in range(a, b + 1):
            k.put(q, x, y, 12 if y in (27, 29) else 11 if x < b else 8)
    k.parede(q, 5, 17, 26, 26, "pedra_lavrada", 65)
    for cx in (6, 11, 19, 24):
        for y in range(18, 26):
            k.put(q, cx, y, 12)
            k.put(q, cx + 1, y, 11)
    k.porta(q, 14, 20, 17, 26, arco=True, moldura=11)
    for x in range(4, 28):
        k.put(q, x, 17, 11)
        k.put(q, x, 16, 12 if x < 27 else 8)
    # cúpula
    for y in range(6, 16):
        for x in range(32):
            u, v = (x - 15.5) / 10, (y - 15.5) / 10
            if u * u + v * v <= 1:
                luz = -(u * 0.6 + v * 0.8)
                c = 12 if luz > 0.45 else 11 if luz > -0.1 else 8
                if (x - 2) % 5 == 0 and c != 8:
                    c = 11 if c == 12 else 8              # gomos da cúpula
                k.put(q, x, y, c)
    return q


def templo_simbolo(nome):
    q = k.novo(32, 32)
    k.simbolo_em(q, nome, 15, 6)
    return q


# ---------------------------------------------------------------- habitantes

def vestir_e6(moldes):
    """Chapéu de aba larga e calças: as pernas viram tecido marrom (9 e 8)."""
    out = []
    for m in moldes:
        m = [list(l) for l in m]
        for x in range(1, 7):
            if m[0][x] in "hH":
                m[0][x] = "n"
        for x in range(0, 8):
            if m[1][x] in "hH." and 0 <= x <= 7:
                m[1][x] = "o"
        for y in (9, 10):
            for x in range(8):
                if m[y][x] == "l":
                    m[y][x] = "d"
                elif m[y][x] == "L":
                    m[y][x] = "o"
        out.append(["".join(l) for l in m])
    return out


def gerar():
    pecas = {
        "canal": canal(), "canal_comporta": canal_comporta(), "roca_irrigada": roca_irrigada(),
        "muralha": muralha(), "muralha_torre": torre(), "casa_tijolo_parede": casa_tijolo_parede(),
        "templo_cupula_base": templo_cupula(),
    }
    for e in k.CULTURAS:
        pecas[f"casa_tijolo_telhado_{e}"] = casa_tijolo_telhado(e)
    for s in k.SIMBOLOS:
        pecas[f"templo_cupula_simbolo_{s}"] = templo_simbolo(s)
    pecas["casa_tijolo"] = k.sobrepor(pecas["casa_tijolo_parede"], pecas["casa_tijolo_telhado_telha"])
    pecas["templo_cupula"] = k.sobrepor(pecas["templo_cupula_base"], pecas["templo_cupula_simbolo_sol"])
    pecas["moinho_ruina"] = k.arruinar(moinho(1), 66, telhado_ate=15)
    pecas["muralha_ruina"] = k.arruinar(pecas["muralha"], 67)
    pecas["muralha_torre_ruina"] = k.arruinar(pecas["muralha_torre"], 68)
    pecas["casa_tijolo_ruina"] = k.arruinar(pecas["casa_tijolo"], 69, telhado_ate=12)
    pecas["templo_cupula_ruina"] = k.arruinar(pecas["templo_cupula"], 70, telhado_ate=15)
    naufragio = k.novo(24, 16)
    b = barco(0)
    for y in range(16):
        for x in range(24):
            c = b[y][x]
            if c is not None and y >= 9:
                k.put(naufragio, x, min(15, y + 2 + x // 8), 30 if c == 8 else c)
    k.linha(naufragio, 11, 12, 17, 6, 9)
    pecas["barco_naufragado"] = naufragio
    folhas = {
        "moinho_4q": [moinho(i) for i in range(4)],
        "barco_2q": [barco(0), barco(1)],
        "adulto_e6_parado_2q": k.pintar(vestir_e6(k.hab.parado(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
        "adulto_e6_andar_4q": k.pintar(vestir_e6(k.hab.andando(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
    }
    return pecas, folhas


def principal():
    pecas, folhas = gerar()
    for nome, px in pecas.items():
        k.gravar(px, AQUI / f"{nome}.png")
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    itens = [("m", folhas["moinho_4q"][0]), ("r", pecas["moinho_ruina"]), ("c", pecas["casa_tijolo"]),
             ("c", pecas["casa_tijolo_ruina"]), ("t", pecas["templo_cupula"]), ("t", pecas["templo_cupula_ruina"]),
             ("w", k.sobrepor(*[pecas["muralha"]])), ("w", pecas["muralha"]), ("t", pecas["muralha_torre"]),
             ("t", pecas["muralha_torre_ruina"]), ("b", folhas["barco_2q"][0]), ("b", pecas["barco_naufragado"]),
             ("i", pecas["roca_irrigada"])]
    itens += [("p", folhas["adulto_e6_andar_4q"][0]), ("p", folhas["adulto_e6_parado_2q"][0])]
    k.amostra_pecas(itens, 380, saida=AQUI / "amostra_estagio6.png")
    print("estágio 6:", ", ".join(pecas), "+", ", ".join(folhas))


if __name__ == "__main__":
    principal()

"""Estágio 4 (metal): forja, casa de enxaimel, templo de colunas, habitantes com
armas e ferramentas de metal, e as ruínas."""
from pathlib import Path
import math
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

import construcao as k  # noqa: E402

ALT_TELHADO = {"palha": (2, 11), "telha": (5, 8), "tabuas": (1, 12)}


def forja(q_brasa):
    """Forno de pedra com a boca acesa, chaminé e bigorna (24x24). 2 quadros de brasa."""
    q = k.novo(24, 24)
    # forno em cúpula
    for y in range(8, 24):
        for x in range(1, 17):
            u = (x - 8.5) / 8
            v = (y - 23) / 15
            if u * u + v * v <= 1:
                pedra = 12 if (x + (y // 3) * 2) % 5 else 11
                if (y % 3) == 0:
                    pedra = 11
                if x > 12 and k.pont(x, y, 0.5):
                    pedra = 11
                if u * u + v * v > 0.86 and (u > 0.3 or v > 0):
                    pedra = 8
                k.put(q, x, y, pedra)
    # chaminé
    for y in range(1, 10):
        for x in range(7, 11):
            k.put(q, x, y, 11 if x < 10 else 8)
        k.put(q, 7, y, 12)
    for x in range(6, 12):
        k.put(q, x, 1, 8)
    # boca acesa
    brasas = ((21, 22, 31), (20, 21, 22))[q_brasa]
    for y in range(16, 23):
        for x in range(5, 12):
            d = abs(x - 8) + max(0, 17 - y) * 1.5
            if d <= 3.6:
                k.put(q, x, y, brasas[2] if d < 1.3 and y > 19 else brasas[1] if d < 2.5 else brasas[0])
    for x in range(4, 13):
        k.put(q, x, 23, 30)
    # bigorna e tenaz
    for x in range(16, 23):
        k.put(q, x, 18, 12 if x < 21 else 11)
        k.put(q, x, 19, 11 if x > 16 else 30)
    k.put(q, 23, 18, 11)
    for y in range(20, 24):
        for x in range(18, 21):
            k.put(q, x, y, 30 if x == 20 else 8)
    k.linha(q, 16, 17, 21, 14, 11)
    return q


def casa_enxaimel_parede():
    q = k.novo(32, 32)
    k.parede(q, 3, 13, 28, 31, "enxaimel", 41)
    k.porta(q, 14, 23, 17, 31)
    for x in (6, 22):
        k.janela(q, x, 16)
        k.janela(q, x, 24)
    return q


def casa_enxaimel_telhado(estilo):
    q = k.novo(32, 32)
    topo, alt = ALT_TELHADO[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 42)
    return q


def templo_colunas_parede(inscricao=False):
    q = k.novo(32, 32)
    for y, (a, b) in zip(range(27, 32), ((3, 28), (2, 29), (2, 29), (1, 30), (1, 30))):
        for x in range(a, b + 1):
            k.put(q, x, y, 12 if y in (27, 29) else 11 if x < b else 8)
    for y in range(14, 27):
        for x in range(6, 26):
            k.put(q, x, y, 8 if x < 24 else 30)      # interior escuro
    k.porta(q, 14, 19, 17, 26, arco=True, moldura=11)
    for cx in (4, 10, 20, 26):
        for y in range(14, 27):
            k.put(q, cx, y, 12)
            k.put(q, cx + 1, y, 11)
        for x in range(cx - 1, cx + 3):
            k.put(q, x, 13, 12)
            k.put(q, x, 26, 11)
    # arquitrave
    for x in range(2, 30):
        k.put(q, x, 12, 12 if x < 29 else 11)
        k.put(q, x, 11, 11)
    if inscricao:                                    # friso com escrita (estágio 5)
        for x in range(4, 28):
            k.put(q, x, 12, 8 if (x * 3) % 4 == 0 else 12)
    return q


def templo_colunas_telhado(estilo):
    q = k.novo(32, 32)
    topo, alt = {"palha": (6, 6), "telha": (6, 6), "tabuas": (6, 6)}[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 43)
    return q


def templo_simbolo(nome, topo):
    q = k.novo(32, 32)
    k.simbolo_em(q, nome, 15, topo)
    return q


# ---------------------------------------------------------------- habitantes

def vestir_e4(moldes):
    """Capacete de ferro e fivela de metal no cinto."""
    return k.vestir(moldes, {(2, 0): "z", (3, 0): "Z", (4, 0): "Z", (5, 0): "z", (1, 1): "z", (6, 1): "z",
                             (2, 8): "Z", (5, 8): "z"})


def guerreiro():
    """Andando com lança e escudo redondo (quadros 12x12)."""
    base = k.alargar(vestir_e4(k.hab.andando(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS)))
    sob = {}
    for y in range(1, 12):
        sob[(9, y)] = "c"
    sob[(9, 0)] = "Z"
    sob[(9, 1)] = "z"
    sob[(8, 6)] = "S"
    for (x, y) in ((0, 5), (0, 6), (0, 7), (1, 4), (1, 8), (1, 5), (1, 6), (1, 7)):
        sob[(x, y)] = "M" if x == 0 else "m"
    sob[(1, 6)] = "K"
    return k.vestir(base, sob)


FERREIRO = [
    [".....zz.....", "..hhhhzc....", ".hHHhhhc....", ".hhhSeSc....", "..hsSSSS....", "..ooooS.....",
     ".soooo......", ".sooooo.....", "..bZbz......", "..l..L......", "..l..L......", ".ff..FF....."],
    ["............", "..hhhh......", ".hHHhhh.....", ".hhhSeS.....", "..hsSSS..zz.", "..oooSSccz..",
     ".soooo......", ".sooooo.....", "..bZbz......", "..l..L......", "..l..L......", ".ff..FF....."],
    ["............", "..hhhh......", ".hHHhhh.....", ".hhhSeS.....", "..hsSSS.....", "..oooSSc....",
     ".soooo..c...", ".sooooo..zz.", "..bZbz...zzK", "..l..L.....", "..l..L......", ".ff..FF....."],
    ["............", "..hhhh......", ".hHHhhh.....", ".hhhSeS.....", "..hsSSS.....", "..oooSSc....",
     ".soooo..c...", ".sooooo..zz.", "..bZbz...zz.", "..l..L......", "..l..L......", ".ff..FF....."],
]


def gerar():
    pecas = {"forja": forja(0), "casa_enxaimel_parede": casa_enxaimel_parede(),
             "templo_colunas_parede": templo_colunas_parede()}
    for e in k.CULTURAS:
        pecas[f"casa_enxaimel_telhado_{e}"] = casa_enxaimel_telhado(e)
        pecas[f"templo_colunas_telhado_{e}"] = templo_colunas_telhado(e)
    for s in k.SIMBOLOS:
        pecas[f"templo_colunas_simbolo_{s}"] = templo_simbolo(s, 5)
    pecas["casa_enxaimel"] = k.sobrepor(pecas["casa_enxaimel_parede"], pecas["casa_enxaimel_telhado_tabuas"])
    pecas["templo_colunas"] = k.sobrepor(pecas["templo_colunas_parede"], pecas["templo_colunas_telhado_telha"],
                                         pecas["templo_colunas_simbolo_sol"])
    pecas["forja_ruina"] = k.arruinar(pecas["forja"], 44)
    pecas["casa_enxaimel_ruina"] = k.arruinar(pecas["casa_enxaimel"], 45, telhado_ate=13)
    pecas["templo_colunas_ruina"] = k.arruinar(pecas["templo_colunas"], 46, telhado_ate=12)
    andar = k.hab.andando(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS)
    folhas = {
        "forja_2q": [forja(0), forja(1)],
        "adulto_e4_parado_2q": k.pintar(vestir_e4(k.hab.parado(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
        "adulto_e4_andar_4q": k.pintar(vestir_e4(andar)),
        "guerreiro_andar_4q": k.pintar(guerreiro()),
        "ferreiro_trabalhar_4q": k.pintar(FERREIRO),
    }
    return pecas, folhas


def principal():
    pecas, folhas = gerar()
    for nome, px in pecas.items():
        k.gravar(px, AQUI / f"{nome}.png")
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    itens = [(n, pecas[n]) for n in ("forja", "forja_ruina", "casa_enxaimel", "casa_enxaimel_ruina",
                                     "templo_colunas", "templo_colunas_ruina")]
    itens += [("p", q) for nome in ("guerreiro_andar_4q", "ferreiro_trabalhar_4q") for q in folhas[nome][:2]]
    itens += [("p", folhas["adulto_e4_andar_4q"][0])]
    k.amostra_pecas(itens, 280, saida=AQUI / "amostra_estagio4.png")
    print("estágio 4:", ", ".join(pecas), "+", ", ".join(folhas))


if __name__ == "__main__":
    principal()

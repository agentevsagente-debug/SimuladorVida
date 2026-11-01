"""Estágio 3 (pedra): casa de pedra, templo de pedra em degraus, habitantes do estágio
e as ruínas. As culturas trocam o telhado da casa e o símbolo do templo."""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

import construcao as k  # noqa: E402

ALT_TELHADO = {"palha": (1, 11), "telha": (4, 8), "tabuas": (0, 12)}   # topo, altura


def casa_pedra_parede():
    q = k.novo(32, 24)
    k.parede(q, 3, 11, 28, 23, "pedra", 31)
    k.porta(q, 14, 16, 17, 23, moldura=11)
    k.janela(q, 7, 14, peitoril=11)
    k.janela(q, 22, 14, peitoril=11)
    return q


def casa_pedra_telhado(estilo):
    q = k.novo(32, 24)
    topo, alt = ALT_TELHADO[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 32)
    return q


def templo_pedra():
    """Templo em 3 degraus de pedra lavrada, com escada no meio e santuário no alto."""
    q = k.novo(32, 32)
    k.parede(q, 1, 24, 30, 31, "pedra_lavrada", 33)
    k.parede(q, 5, 17, 26, 24, "pedra_lavrada", 34)
    k.parede(q, 9, 10, 22, 17, "pedra_lavrada", 35)
    # escada
    for y in range(17, 32):
        for x in range(14, 18):
            k.put(q, x, y, 12 if y % 2 else 11)
        k.put(q, 13, y, 8)
        k.put(q, 18, y, 8)
    # porta do santuário e beirais escuros dos degraus
    k.porta(q, 14, 12, 17, 16, arco=True, moldura=8)
    for x0, x1, y in ((1, 30, 24), (5, 26, 17), (9, 22, 10)):
        for x in range(x0, x1 + 1):
            if not 13 <= x <= 18 or y == 10:
                k.put(q, x, y, 11 if x < x1 else 8)
    # braseiros nos cantos do alto
    for x in (10, 21):
        k.put(q, x, 9, 11)
        k.put(q, x, 8, 21)
        k.put(q, x, 7, 22)
    return q


def templo_simbolo(nome):
    q = k.novo(32, 32)
    k.simbolo_em(q, nome, 15, 9)
    return q


# habitante do estágio: capa de pele nos ombros e colar de pedra
def vestir(moldes):
    return k.vestir(moldes, {(1, 4): "o", (2, 4): "n", (3, 4): "n", (4, 4): "n", (5, 4): "n", (6, 4): "o",
                             (4, 5): "Z"})


def gerar():
    pecas = {"casa_pedra_parede": casa_pedra_parede()}
    for e in k.CULTURAS:
        pecas[f"casa_pedra_telhado_{e}"] = casa_pedra_telhado(e)
    pecas["casa_pedra"] = k.sobrepor(pecas["casa_pedra_parede"], pecas["casa_pedra_telhado_telha"])
    pecas["templo_pedra_base"] = templo_pedra()
    for s in k.SIMBOLOS:
        pecas[f"templo_pedra_simbolo_{s}"] = templo_simbolo(s)
    pecas["templo_pedra"] = k.sobrepor(pecas["templo_pedra_base"], pecas["templo_pedra_simbolo_sol"])
    pecas["casa_pedra_ruina"] = k.arruinar(pecas["casa_pedra"], 36, telhado_ate=11)
    pecas["templo_pedra_ruina"] = k.arruinar(pecas["templo_pedra"], 37)
    folhas = {
        "adulto_e3_parado_2q": k.pintar(vestir(k.hab.parado(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
        "adulto_e3_andar_4q": k.pintar(vestir(k.hab.andando(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
    }
    return pecas, folhas


def principal():
    pecas, folhas = gerar()
    for nome, px in pecas.items():
        k.gravar(px, AQUI / f"{nome}.png")
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    itens = [(n, pecas[n]) for n in ("casa_pedra", "casa_pedra_ruina", "templo_pedra", "templo_pedra_ruina")]
    itens += [(e, k.sobrepor(pecas["casa_pedra_parede"], pecas[f"casa_pedra_telhado_{e}"])) for e in ("palha", "tabuas")]
    itens += [("p", q) for q in folhas["adulto_e3_andar_4q"]]
    k.amostra_pecas(itens, 252, saida=AQUI / "amostra_estagio3.png")
    print("estágio 3:", ", ".join(pecas), "+", ", ".join(folhas))


if __name__ == "__main__":
    principal()

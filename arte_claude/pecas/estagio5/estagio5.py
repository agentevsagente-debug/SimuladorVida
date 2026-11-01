"""Estágio 5 (escrita): tabuletas, estela, biblioteca pequena (o arquivo), templo com
friso escrito, a casa caiada, habitantes com túnica longa, o escriba e as ruínas."""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI.parent / "estagio4"))

import construcao as k  # noqa: E402
import estagio4  # noqa: E402


def tabuletas():
    """4 variações de 8x8: tabuleta de barro, rolo, estela pequena e pilha de tabuletas."""
    q1 = k.novo(8, 8)
    k.retangulo(q1, 1, 1, 6, 6, 10)
    for y in (2, 3, 4, 5):
        for x in range(2, 6):
            if (x + y) % 2 == 0 or x == 2:
                k.put(q1, x, y, 9)
    k.retangulo(q1, 1, 6, 6, 6, 9)
    k.put(q1, 6, 1, 9)
    q2 = k.novo(8, 8)
    k.retangulo(q2, 1, 2, 6, 5, 12)
    for x in range(1, 7):
        k.put(q2, x, 2, 31)
        k.put(q2, x, 5, 11)
    for x in (2, 3, 5):
        k.put(q2, x, 3, 8)
        k.put(q2, x + (x % 2), 4, 8)
    for y in range(1, 7):
        k.put(q2, 0, y, 9)
        k.put(q2, 7, y, 9)
    q3 = k.novo(8, 8)
    k.retangulo(q3, 2, 0, 5, 7, 12)
    for y in range(0, 8):
        k.put(q3, 5, y, 11)
    k.put(q3, 2, 0, None)
    for y in (1, 3, 5):
        k.put(q3, 3, y, 8)
        k.put(q3, 4, y + 1, 8)
    q4 = k.novo(8, 8)
    for i, y in enumerate((6, 4, 2)):
        k.retangulo(q4, 1 + i % 2, y, 6 - (i == 2), y + 1, 10)
        k.put(q4, 6 - (i == 2), y + 1, 9)
        k.put(q4, 1 + i % 2, y + 1, 9)
    return [q1, q2, q3, q4]


def estela():
    q = k.novo(8, 16)
    for y in range(1, 16):
        for x in range(1, 7):
            if y == 1 and x in (1, 6):
                continue
            k.put(q, x, y, 12 if x < 5 else 11)
        k.put(q, 6, y, 8)
    for y in range(3, 13, 2):
        for x in range(2, 5):
            if (x * 5 + y) % 3:
                k.put(q, x, y, 8)
    for x in range(0, 8):
        k.put(q, x, 15, 11 if x < 7 else 8)
    return q


def biblioteca_parede():
    """O arquivo: pórtico de colunas e, no fundo, estantes com tabuletas e rolos."""
    q = k.novo(32, 32)
    k.parede(q, 2, 12, 29, 31, "pedra_lavrada", 51)
    # vão do pórtico com estantes
    for y in range(16, 30):
        for x in range(6, 26):
            k.put(q, x, y, 8)
    for y in (19, 23, 27):
        for x in range(6, 26):
            k.put(q, x, y, 9)
            k.put(q, x, y - 1, (10, 12, 31, 9)[(x * 3 + y) % 4] if x % 3 else 30)
    for cx in (5, 12, 19, 26):
        for y in range(15, 30):
            k.put(q, cx, y, 12)
            k.put(q, cx + 1, y, 11)
    for x in range(2, 30):
        k.put(q, x, 14, 11)
        k.put(q, x, 15, 12)
        k.put(q, x, 30, 12)
        k.put(q, x, 31, 11 if x < 29 else 8)
    for x in range(4, 28):
        k.put(q, x, 14, 8 if (x * 3) % 4 == 0 else 11)      # friso escrito
    return q


def biblioteca_telhado(estilo):
    q = k.novo(32, 32)
    topo, alt = {"palha": (2, 11), "telha": (5, 8), "tabuas": (1, 12)}[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 52)
    return q


def casa_caiada_parede():
    """A casa do estágio 5 (auditoria 7: antes, o estágio 5 usava a casa de enxaimel do 4 e não
    se distinguia dele). Paredes caiadas, brancas, com cunhais de pedra nos cantos, rodapé
    ocre, o friso escrito sob o telhado (o mesmo da biblioteca), porta em arco e janelas com
    postigos de madeira. Mesmo tamanho e encaixe da casa de enxaimel (32 x 32, parede da
    linha 13 à 31)."""
    q = k.novo(32, 32)
    x0, y0, x1, y1 = 3, 13, 28, 31
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if x in (x0, x0 + 1, x1 - 1, x1):                 # cunhais: pedras alternadas
                pedra = ((y - y0) // 2 + (x in (x0 + 1, x1 - 1))) % 2
                c = (12 if pedra else 11) if x < x1 else 8
            elif y >= y1 - 2:                                 # rodapé ocre
                c = 10 if x < x1 - 2 else 9
            elif x >= x1 - 3:                                 # o lado da sombra
                c = 12
            else:
                c = 31 if (x * 7 + y * 3) % 23 else 12        # cal com uma ou outra mancha
            k.put(q, x, y, c)
    for x in range(x0, x1 + 1):
        k.put(q, x, y1, 8)
    for x in range(x0 + 2, x1 - 1):                           # friso escrito
        k.put(q, x, y0 + 1, 8 if (x * 3) % 4 == 0 else 12)
        k.put(q, x, y0 + 2, 11)
    k.porta(q, 14, 23, 17, 31, arco=True, moldura=11)
    for x in (7, 21):
        for y in (17, 24):
            k.janela(q, x, y, peitoril=11)
            for yy in range(y, y + 3):                        # postigos abertos
                k.put(q, x - 1, yy, 10)
                k.put(q, x + 3, yy, 9)
    # a tabuleta com o nome da casa, ao lado da porta
    for x, y, c in ((19, 22, 10), (20, 22, 10), (19, 23, 8), (20, 23, 9)):
        k.put(q, x, y, c)
    return q


def casa_caiada_telhado(estilo):
    q = k.novo(32, 32)
    topo, alt = estagio4.ALT_TELHADO[estilo]
    k.telhado(q, estilo, 0, 32, topo, alt, 56)
    return q


# ---------------------------------------------------------------- habitantes

def vestir_e5(moldes):
    """Túnica longa até os pés (as pernas viram roupa) e faixa no ombro."""
    out = []
    for m in moldes:
        m = [list(l) for l in m]
        for y in (9, 10):
            for x in range(1, 7):
                if m[y][x] in "lL" or (2 <= x <= 5):
                    m[y][x] = "T"
        for x in range(2, 6):
            if m[8][x] == "b":
                m[8][x] = "T"
        m[8][3] = "b"
        out.append(["".join(l) for l in m])
    return out


def com_tabuleta(moldes):
    return k.vestir(moldes, {(7, 6): "n", (7, 7): "o", (6, 7): "n"})


ESCRIBA = [
    ["........", "........", "..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS.",
     "..TTTT..", ".sTTbTS.", ".sTbTTSc", ".sbbnnnn", "..llLLLo", ".CCCCCCF"],
    ["........", "........", "..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS.",
     "..TTTT..", ".sTTbTSc", ".sTbTTS.", ".sbbnnon", "..llLLLo", ".CCCCCCF"],
]


def gerar():
    pecas = {"estela": estela(), "biblioteca_parede": biblioteca_parede(),
             "templo_escrita_parede": estagio4.templo_colunas_parede(inscricao=True),
             "casa_caiada_parede": casa_caiada_parede()}
    for e in k.CULTURAS:
        pecas[f"biblioteca_telhado_{e}"] = biblioteca_telhado(e)
        pecas[f"casa_caiada_telhado_{e}"] = casa_caiada_telhado(e)
    pecas["casa_caiada"] = k.sobrepor(pecas["casa_caiada_parede"], pecas["casa_caiada_telhado_telha"])
    pecas["casa_caiada_ruina"] = k.arruinar(pecas["casa_caiada"], 55, telhado_ate=13)
    pecas["biblioteca"] = k.sobrepor(pecas["biblioteca_parede"], pecas["biblioteca_telhado_telha"])
    pecas["templo_escrita"] = k.sobrepor(pecas["templo_escrita_parede"],
                                         estagio4.templo_colunas_telhado("telha"),
                                         estagio4.templo_simbolo("sol", 5))
    pecas["biblioteca_ruina"] = k.arruinar(pecas["biblioteca"], 53, telhado_ate=12)
    # tabuletas espalhadas pela ruína
    for x, y in ((8, 30), (20, 31), (25, 30)):
        k.put(pecas["biblioteca_ruina"], x, y, 10)
        k.put(pecas["biblioteca_ruina"], x + 1, y, 9)
    pecas["templo_escrita_ruina"] = k.arruinar(pecas["templo_escrita"], 54, telhado_ate=12)
    folhas = {
        "tabuletas_4v": tabuletas(),
        "adulto_e5_parado_2q": k.pintar(com_tabuleta(vestir_e5(k.hab.parado(k.hab.CABECA_B, k.hab.TRONCO_A,
                                                                              k.hab.PERNAS)))),
        "adulto_e5_andar_4q": k.pintar(vestir_e5(k.hab.andando(k.hab.CABECA_A, k.hab.TRONCO_A, k.hab.PERNAS))),
        "escriba_sentado_2q": k.pintar(ESCRIBA),
    }
    return pecas, folhas


def principal():
    pecas, folhas = gerar()
    for nome, px in pecas.items():
        k.gravar(px, AQUI / f"{nome}.png")
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    itens = [(n, pecas[n]) for n in ("casa_caiada", "casa_caiada_ruina", "biblioteca", "biblioteca_ruina",
                                     "templo_escrita", "estela")]
    itens += [("t", q) for q in folhas["tabuletas_4v"]]
    itens += [("p", folhas[n][0]) for n in ("adulto_e5_parado_2q", "adulto_e5_andar_4q", "escriba_sentado_2q")]
    k.amostra_pecas(itens, 290, saida=AQUI / "amostra_estagio5.png")
    print("estágio 5:", ", ".join(pecas), "+", ", ".join(folhas))


if __name__ == "__main__":
    principal()

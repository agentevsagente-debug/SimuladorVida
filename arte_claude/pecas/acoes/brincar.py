"""Brincadeiras de crianças: pega-pega e ciranda, em quadros de 6x8 como a criança de sempre
(cores-base de `habitantes/trocas.json`, base na última linha). Movimento é o que mais chama o
olho em 1x: as duas brincadeiras se movem pela tela, e quem move é o motor.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from vida import crianca  # noqa: E402

# cabeça virada para trás (olhando para a esquerda), de boca aberta, rindo
CAB_TRAS = ["..hhh.", ".SShHh", ".SeShh", "..xSs."]
# de frente e de costas, para a roda
CAB_FRENTE = [".hhhh.", ".hHHh.", ".eSSe.", "..sx.."]
CAB_COSTAS = [".hhhh.", ".hHhh.", ".hhhh.", "..ss.."]
TRONCO_FRENTE = [".TTTT.", ".TbbT."]


def corpo(cab, tronco, pernas, pontos=(), desce=0):
    g = [list("......") for _ in range(8)]
    for y, l in enumerate(cab + tronco):
        for x, ch in enumerate(l):
            if ch != "." and y + desce < 8:
                g[y + desce][x] = ch
    for j, l in enumerate(pernas):
        for x, ch in enumerate(l):
            if ch != ".":
                g[6 + j][x] = ch
    for x, y, ch in pontos:
        if 0 <= x < 6 and 0 <= y < 8:
            g[y][x] = ch
    return ["".join(l) for l in g]


def pegapega_fugir():
    """Quem foge: corre de passada larga, olhando para trás e rindo, com os braços para o alto."""
    tronco = [".TTT..", ".TbT.."]
    return [
        corpo(CAB_TRAS, tronco, ["l...L.", "f....F"], [(0, 3, "s"), (5, 2, "S"), (4, 3, "S")]),
        corpo(CAB_TRAS, tronco, [".lL...", ".fF..."], [(0, 4, "s"), (5, 3, "S"), (4, 4, "S")], desce=0),
        corpo(CAB_TRAS, tronco, [".L..l.", "F....f"], [(0, 2, "s"), (5, 3, "S"), (4, 4, "S")]),
        corpo(CAB_TRAS, tronco, ["..Ll..", "..Ff.."], [(0, 3, "s"), (5, 2, "S"), (4, 3, "S")]),
    ]


def pegapega_pegar():
    """O pegador: corre inclinado para a frente com o braço esticado, tentando alcançar. No
    quadro 3 o braço chega à coluna 5: é o toque (o motor troca os papéis aí)."""
    return [
        crianca([(0, 5, "s"), (4, 4, "S"), (5, 4, "S")], ["l...L.", "f....F"]),
        crianca([(0, 4, "s"), (4, 4, "S"), (5, 3, "S")], [".lL...", ".fF..."]),
        crianca([(0, 5, "s"), (4, 4, "S"), (5, 4, "S")], [".L..l.", "F....f"]),
        crianca([(0, 3, "s"), (4, 3, "S"), (5, 3, "S"), (5, 2, "S")], ["l..L..", "f...F."]),
    ]


PERNAS_RODA = (["l...L.", "f...F."], [".lL...", ".fF..."], ["l...L.", "f...F."], ["..lL..", "..fF.."])


def ciranda(cab):
    """Na roda, de mãos dadas: braços abertos até as colunas 0 e 5 (as mãos), passo de lado.
    A 6 px uma da outra, as mãos das vizinhas se encostam e a fila vira uma corrente.
    Nos quadros 1 e 3 o corpo desce 1 px e as mãos sobem e descem com o balanço."""
    maos = ([(0, 4, "s"), (5, 4, "s")], [(0, 4, "s"), (5, 4, "s")], [(0, 4, "s"), (5, 4, "s")],
            [(0, 5, "s"), (5, 5, "s")])
    return [corpo(cab, TRONCO_FRENTE, pernas, mao, desce=1 if i % 2 else 0)
            for i, (pernas, mao) in enumerate(zip(PERNAS_RODA, maos))]


FOLHAS = {
    "crianca_pegapega_fugir_4q": pegapega_fugir,
    "crianca_pegapega_pegar_4q": pegapega_pegar,
    "crianca_ciranda_4q": lambda: ciranda(CAB_FRENTE),
    "crianca_ciranda_costas_4q": lambda: ciranda(CAB_COSTAS),
}


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    # amostra: as folhas, e embaixo as brincadeiras montadas nos 4 quadros
    roupas = ((26, 30, 28), (24, 23, 27), (23, 8, 29), (25, 8, 28), (26, 23, 29))
    W, H = 4 * 40 + 8, 2 + len(folhas) * 12 + 4 * 14 + 4
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")

    def chao(y):
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, y + 6))

    def crianca_em(q, t, x, y, espelho=False):
        im = para_imagem(trocar(q, k.hab.troca(*roupas[t % len(roupas)])))
        if espelho:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        img.alpha_composite(im, (x, y))

    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 12
        chao(y)
        for i, q in enumerate(qs):
            crianca_em(q, j, 4 + i * 10, y)
    y0 = 2 + len(folhas) * 12
    for i in range(4):
        y = y0 + i * 14
        chao(y + 2)
        # pega-pega: o pegador 7 px atrás de quem foge, os dois indo para a direita
        x = 4 + i * 6
        crianca_em(folhas["crianca_pegapega_pegar_4q"][i], 1, x, y + 2)
        crianca_em(folhas["crianca_pegapega_fugir_4q"][(i + 1) % 4], 2, x + 13, y + 2)
        # ciranda: 3 de costas atrás (2 px acima, deslocadas 3 px) e 4 de frente, a 6 px
        for c in range(3):
            crianca_em(folhas["crianca_ciranda_costas_4q"][(i + c) % 4], c + 3, 96 + c * 6 + 3, y)
        for c in range(4):
            crianca_em(folhas["crianca_ciranda_4q"][(i + c + 2) % 4], c, 96 + c * 6, y + 2)
    img.save(AQUI / "amostra_brincar.png")
    img.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_brincar_4x.png")
    print("brincadeiras:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

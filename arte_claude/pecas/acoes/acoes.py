"""Ações dos habitantes, em quadros de 8x12 como os habitantes de sempre (olhando para a
direita, base na última linha, cores-base de `habitantes/trocas.json`).

Cada quadro é montado com partes: cabeça, tronco sem braços, pernas, braços e o objeto.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

import construcao as k  # noqa: E402

CAB = ["..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS."]
CAB_BAIXA = ["..hhhh..", ".hHHhhh.", ".hhhhSe.", "..hsSSS."]     # olhando para baixo
TRONCO = ["..TTTb..", "..TTbT..", "..TbTT..", "..TTTT..", "..bbbb.."]
AVENTAL = ["..TTTb..", "..TTbT..", "..oooo..", "..oooo..", "..bbbb.."]
PERNAS = {
    "parado": ["..l..L..", "..l..L..", ".ff..FF."],
    "passo_a": ["..l..L..", ".l....L.", "ff....FF"],
    "meio_a": ["...lL...", "...lL...", "...fFF.."],
    "passo_b": ["..L..l..", ".L....l.", "FF....ff"],
    "meio_b": ["...Ll...", "...Ll...", "..FFf..."],
    "aberto": [".l....L.", "l......L", "f......F"],
    "dobrado": ["..l..L..", ".l..LL..", ".ff...FF"],
    "base": [".l...L..", ".l....L.", "ff....FF"],
    "nada": ["........", "........", "........"],
}


def quadro(pontos=(), cab=CAB, tronco=TRONCO, pernas="parado", desce=0):
    """Monta um quadro: `pontos` são (x, y, caractere) desenhados por cima (braços e objetos)."""
    g = [list("........") for _ in range(12)]
    partes = cab + tronco + PERNAS[pernas]
    for y, l in enumerate(partes):
        yy = y + desce if y < 9 else y
        if yy >= 12 or (desce and y == 9):
            continue
        for x, ch in enumerate(l):
            if ch != ".":
                g[yy][x] = ch
    for x, y, ch in pontos:
        if 0 <= x < 8 and 0 <= y < 12:
            g[y][x] = ch
    return ["".join(l) for l in g]


# braços prontos: costas (s) e frente (S)
BRACO_COSTAS = [(1, 5, "s"), (1, 6, "s"), (1, 7, "s")]
BRACO_FRENTE = [(6, 5, "S"), (6, 6, "S"), (7, 7, "S")]


def pescar():
    vara = lambda pts: [(x, y, "c") for x, y in pts]  # noqa: E731
    return [
        quadro(BRACO_COSTAS + [(6, 5, "S"), (7, 5, "S")] + vara([(7, 4), (7, 3), (7, 2), (7, 1), (7, 0)])),
        quadro(BRACO_COSTAS + [(6, 5, "S"), (7, 5, "S")] + vara([(7, 4), (7, 3), (7, 2), (6, 1), (6, 0)])),
        quadro(BRACO_COSTAS + [(6, 4, "S"), (6, 5, "S")] + vara([(6, 3), (5, 2), (5, 1), (4, 0)]), pernas="base"),
        quadro([(1, 5, "s"), (1, 6, "s"), (6, 5, "S"), (7, 6, "S"), (7, 7, "j"), (7, 8, "w"), (6, 8, "j"),
                (7, 9, "j")] + vara([(1, 4), (0, 3), (0, 2), (0, 1)])),
    ]


def lenha():
    # feixe de lenha nos braços, na frente do corpo
    feixe = [(x, y, "n" if (x + y) % 2 else "o") for x in range(3, 8) for y in (6, 7)] + [(7, 6, "d"), (7, 7, "d")]
    braco = [(1, 5, "s"), (2, 6, "s"), (6, 5, "S"), (6, 8, "S")]
    return [quadro(feixe + braco, pernas=p, desce=d) for p, d in
            (("passo_a", 1), ("meio_a", 0), ("passo_b", 1), ("meio_b", 0))]


def martelo(cab=CAB, tronco=TRONCO, faisca=False):
    q0 = [(1, 5, "s"), (1, 6, "s"), (6, 3, "S"), (6, 4, "S"), (6, 2, "c"), (6, 1, "c"), (5, 0, "z"), (6, 0, "z"),
          (7, 0, "Z")]
    q1 = [(1, 5, "s"), (1, 6, "s"), (6, 4, "S"), (7, 4, "S"), (7, 3, "c"), (7, 2, "z"), (6, 2, "Z")]
    q2 = [(1, 5, "s"), (1, 6, "s"), (6, 5, "S"), (6, 6, "S"), (7, 7, "c"), (7, 8, "z"), (6, 8, "z"), (7, 9, "Z")]
    if faisca:
        q2 = q2 + [(5, 9, "K"), (6, 10, "k")]
    return [quadro(q0, cab, tronco), quadro(q1, cab, tronco), quadro(q2, CAB_BAIXA, tronco, pernas="base"),
            quadro(q1, cab, tronco)]


def escrever():
    tabuleta = [(4, 6, "n"), (5, 6, "n"), (4, 7, "o"), (5, 7, "o")]
    costas = [(1, 5, "s"), (2, 6, "s"), (3, 6, "s")]
    estilete = [[(6, 5, "S"), (6, 6, "c")], [(6, 5, "S"), (5, 6, "c")], [(6, 6, "S"), (6, 5, "c")],
                [(6, 5, "S"), (5, 5, "c")]]
    return [quadro(costas + tabuleta + e, CAB_BAIXA) for e in estilete]


def remar():
    """Sentado no barco: só o tronco aparece; o remo atravessa para a água."""
    corpo = dict(pernas="nada", desce=2)
    remos = [
        [(5, 6, "S"), (6, 6, "S"), (6, 7, "c"), (6, 8, "c"), (7, 9, "c"), (7, 10, "o"), (7, 11, "o")],
        [(5, 6, "S"), (5, 7, "S"), (5, 8, "c"), (5, 9, "c"), (5, 10, "o"), (5, 11, "o")],
        [(4, 7, "S"), (4, 8, "S"), (3, 9, "c"), (3, 10, "c"), (2, 11, "o"), (1, 11, "o")],
        [(6, 5, "S"), (6, 6, "S"), (7, 7, "c"), (7, 8, "c"), (7, 9, "o")],
    ]
    return [quadro([(1, 7, "s"), (1, 8, "s")] + r, **corpo) for r in remos]


def lutar():
    escudo = [(5, 4, "m"), (6, 4, "M"), (5, 5, "M"), (6, 5, "K"), (7, 5, "M"), (5, 6, "M"), (6, 6, "M"),
              (7, 6, "m"), (6, 7, "m")]
    return [
        quadro(escudo + [(1, 5, "s"), (1, 0, "Z")] + [(1, y, "c") for y in range(1, 11)]),
        quadro(escudo + [(1, 4, "s"), (0, 4, "c"), (1, 3, "c"), (2, 3, "c"), (3, 3, "Z")], pernas="base"),
        quadro([(x, 4, "c") for x in range(0, 7)] + [(7, 4, "Z"), (7, 3, "z")] + [(2, 5, "s")] +
               [(4, 5, "m"), (5, 5, "M"), (4, 6, "M"), (5, 6, "K"), (4, 7, "m")], pernas="aberto"),
        quadro(escudo + [(1, 5, "s"), (1, 1, "Z")] + [(1, y, "c") for y in range(2, 11)], pernas="dobrado"),
    ]


def carregar_morto():
    """Andando devagar com um corpo envolto em mortalha nos ombros (cabeça baixa)."""
    mortalha = [(x, 3, "G" if x % 3 else "W") for x in range(0, 6)] + [(x, 4, "W" if x % 2 else "G") for x in range(0, 5)]
    mortalha = [(x, y, {"W": "w", "G": "Z"}[c]) for x, y, c in mortalha]
    braco = [(1, 5, "s"), (6, 4, "S"), (6, 5, "S"), (5, 3, "S")]
    return [quadro(mortalha + braco, CAB_BAIXA, pernas=p, desce=d) for p, d in
            (("passo_a", 1), ("meio_a", 1), ("passo_b", 1), ("meio_b", 1))]


def dancar():
    return [
        quadro([(1, 3, "s"), (0, 2, "s"), (6, 3, "S"), (7, 2, "S")], pernas="aberto"),
        quadro([(1, 4, "s"), (0, 3, "s"), (6, 5, "S"), (7, 6, "S")], pernas="dobrado", desce=1),
        quadro([(1, 6, "s"), (0, 7, "s"), (6, 3, "S"), (7, 2, "S")], pernas="aberto"),
        quadro([(1, 3, "s"), (0, 2, "s"), (6, 3, "S"), (7, 2, "S")], pernas="meio_a", desce=1),
    ]


def gerar():
    return {
        "pescar_4q": pescar(),
        "carregar_lenha_4q": lenha(),
        "construir_4q": martelo(),
        "forjar_4q": martelo(tronco=AVENTAL, faisca=True),
        "escrever_4q": escrever(),
        "remar_4q": remar(),
        "lutar_4q": lutar(),
        "carregar_morto_4q": carregar_morto(),
        "dancar_4q": dancar(),
    }


def principal():
    folhas = {n: k.pintar(m) for n, m in gerar().items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    # amostra: cada ação numa linha, com as 3 roupas
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    W = 4 * 10 * 3 + 8
    img = Image.new("RGBA", (W, len(folhas) * 20 + 4), PALETA[1] + (255,))
    terra = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 20
        for x in range(0, W, 8):
            img.alpha_composite(terra, (x, y + 10))
        for t, (pele, cab, roupa) in enumerate(((26, 30, 28), (24, 23, 27), (23, 8, 29))):
            for i, q in enumerate(qs):
                img.alpha_composite(para_imagem(trocar(q, k.hab.troca(pele, cab, roupa))), (4 + t * 42 + i * 10, y))
    img.save(AQUI / "amostra_acoes.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_acoes_4x.png")
    print("ações:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

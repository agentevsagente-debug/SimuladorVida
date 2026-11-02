"""Ações de 1x para a tarde (12h às 15h30), o período mais parado: a sesta à sombra, o
artesanato sentado (trançar cesto, moldar pote, afiar lança), ensinar uma criança e consertar
o telhado. Mesmo padrão das ações de 1x (`forte.py`): olhando para a direita, base na última
linha, cores-base de `habitantes/trocas.json`; os objetos não usam 8, 25, 26, 28 nem 30.
Quadros de 12x12 com o corpo nas colunas 0 a 7, e a criança em 6x8.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, quadro  # noqa: E402
from cotidiano import ajoelhado, largo, por  # noqa: E402
from forte import lanca  # noqa: E402
from vida import CAB_BOCA, crianca, sentado  # noqa: E402


def grade(*linhas):
    assert len(linhas) == 12 and all(len(l) == 12 for l in linhas), linhas
    return list(linhas)


# ---------------------------------------------------------------- sesta

def sesta():
    """Deitado de costas à sombra, a mão atrás da cabeça e um joelho dobrado; no quadro 1 o
    peito sobe (respira). Segure cada quadro 1,5 a 2 s. Ponha sob a copa de uma árvore."""
    vazio = ["............"] * 8
    q0 = grade(*vazio, "..s.........", ".shh.....lL.", "shhSSTTTTl.L", ".hSSTTbTlL.F")
    q1 = grade(*vazio, "..s.........", ".shh.TT..lL.", "shhSSTTTTl.L", ".hSSTTbTlL.F")
    return [q0, q1]


# ---------------------------------------------------------------- artesanato sentado

def trancar_cesto():
    """Sentado, trança um cesto no colo: o cesto (palha clara e escura) cresce à frente, e as
    mãos passam a fibra amarela por dentro e por fora."""
    cesto = [(x, y, "n" if (x + y) % 2 else "o") for x in range(7, 11) for y in (9, 10)] + \
            [(7, 8, "o"), (10, 8, "o")]
    fibra = [[(6, 7, "y"), (7, 6, "y")], [(8, 7, "y"), (9, 6, "y")], [(10, 7, "y"), (11, 6, "y")],
             [(9, 8, "y"), (8, 8, "y")]]
    maos = [[(6, 8, "S"), (7, 7, "S")], [(7, 8, "S"), (8, 7, "S")], [(8, 8, "S"), (10, 6, "S")],
            [(7, 8, "S"), (9, 7, "S")]]
    out = []
    for f, m in zip(fibra, maos):
        q = largo(sentado(2, [(1, 7, "s"), (1, 8, "s")], CAB_BAIXA))
        out.append(por(q, cesto + f + m))
    return out


def moldar_pote():
    """Sentado, molda um pote de barro (laranja) no chão à frente: as duas mãos sobem e descem
    dos lados do pote, que vai ganhando a boca."""
    pote = [(8, 8, "M"), (9, 8, "m"), (10, 8, "M"), (8, 9, "m"), (9, 9, "m"), (10, 9, "M"),
            (8, 10, "M"), (9, 10, "M"), (10, 10, "M")]
    boca = [[], [(9, 7, "M")], [(8, 7, "M"), (10, 7, "M")], [(8, 7, "M"), (9, 7, "j"), (10, 7, "M")]]
    maos = [[(7, 9, "S"), (11, 9, "S")], [(7, 8, "S"), (11, 8, "S")], [(7, 10, "S"), (11, 10, "S")],
            [(7, 8, "S"), (11, 8, "S")]]
    out = []
    for b, m in zip(boca, maos):
        q = largo(sentado(2, [(1, 7, "s"), (2, 8, "s"), (6, 8, "S")], CAB_BAIXA))
        out.append(por(q, pote + b + m))
    return out


def afiar_lanca():
    """Sentado, a lança de 2 px atravessada no colo, esfrega a pedra (cinza) na ponta; no
    quadro 2 sai um pozinho claro. Depois, olha a ponta contra a luz (quadro 3)."""
    out = []
    for i, x in enumerate((8, 9, 10, 9)):
        q = largo(sentado(2, [(1, 7, "s"), (1, 8, "s")], CAB_BAIXA if i < 3 else CAB))
        pts = lanca(0, 11, 8) + [(x, 7, "Z"), (x, 6, "S"), (x - 1, 7, "S")]
        if i == 2:
            pts += [(x + 1, 5, "w"), (x + 2, 6, "w")]
        if i == 3:
            pts = lanca(2, 11, 5) + [(6, 6, "S"), (5, 7, "S")]
        out.append(por(q, pts))
    return out


# ---------------------------------------------------------------- ensinar

def ensinar():
    """O adulto ensina: aponta para longe (quadros 0 e 1, de boca aberta) e depois mostra o
    gesto com um galho na mão (2 e 3). Ponha a criança (`crianca_imitar_4q`) a uns 8 a 10 px
    à frente, virada para ele, com os quadros juntos."""
    galho = lambda pts: [(x, y, "n") for x, y in pts]  # noqa: E731
    return [
        por(largo(quadro([(1, 5, "s"), (1, 6, "s")], CAB_BOCA)), [(6, 4, "S"), (7, 3, "S"), (8, 2, "S"), (9, 1, "S")]),
        por(largo(quadro([(1, 5, "s"), (1, 6, "s")], CAB)), [(6, 4, "S"), (7, 3, "S"), (8, 3, "S"), (9, 2, "S")]),
        por(largo(quadro([(1, 5, "s"), (1, 6, "s")], CAB_BAIXA)),
            [(6, 5, "S"), (7, 5, "S")] + galho([(8, 5), (9, 6), (10, 7), (11, 8)])),
        por(largo(quadro([(1, 5, "s"), (1, 6, "s")], CAB_BAIXA, pernas="base")),
            [(6, 4, "S"), (7, 3, "S")] + galho([(8, 2), (9, 1), (10, 0)])),
    ]


def crianca_imitar():
    """A criança imita o adulto: olha para onde ele aponta (0 e 1, o braço erguido) e repete o
    gesto com um galhinho (2 e 3). Mesmos quadros do `ensinar_apontar_4q`."""
    return [
        crianca([(0, 4, "s"), (4, 3, "S"), (5, 2, "S")], ["l..L..", "f..F.."]),
        crianca([(0, 4, "s"), (4, 3, "S"), (5, 2, "S")], [".lL...", ".fF..."]),
        crianca([(0, 4, "s"), (4, 4, "S"), (5, 5, "n")], ["l..L..", "f..F.."]),
        crianca([(0, 4, "s"), (4, 3, "S"), (5, 2, "n"), (5, 1, "n")], ["l..L..", "f..F.."]),
    ]


# ---------------------------------------------------------------- consertar o telhado

def consertar_telhado():
    """Ajoelhado em cima da casa, conserta o telhado: ergue o feixe de palha (amarelo), assenta
    o feixe, ergue a pedra de bater e bate (com um pozinho). A base (linha 11) vai na
    cumeeira ou na água do telhado; o motor desloca a pessoa ao longo do telhado de vez em
    quando."""
    feixe = lambda dx, dy: [(x + dx, y + dy, "y" if (x + y) % 2 else "n")  # noqa: E731
                            for x in range(0, 4) for y in range(0, 2)]
    return [
        por(largo(ajoelhado([(1, 6, "s"), (6, 4, "S"), (7, 3, "S")], CAB)), feixe(7, 1) + [(7, 3, "S")]),
        por(largo(ajoelhado([(1, 6, "s"), (6, 7, "S"), (7, 8, "S")])), feixe(8, 8) + [(7, 8, "S")]),
        por(largo(ajoelhado([(1, 6, "s"), (6, 4, "S"), (7, 3, "S")], CAB)),
            feixe(8, 9) + [(7, 2, "Z"), (8, 2, "z"), (7, 3, "S")]),
        por(largo(ajoelhado([(1, 6, "s"), (6, 7, "S"), (7, 8, "S")])),
            feixe(8, 9) + [(8, 8, "Z"), (9, 8, "z"), (10, 7, "w"), (11, 8, "w")]),
    ]


FOLHAS = {
    "sesta_forte_2q": sesta, "trancar_cesto_4q": trancar_cesto, "moldar_pote_4q": moldar_pote,
    "afiar_lanca_4q": afiar_lanca, "ensinar_apontar_4q": ensinar, "crianca_imitar_4q": crianca_imitar,
    "consertar_telhado_4q": consertar_telhado,
}


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    W, H = 4 * 14 + 8, len(folhas) * 16 + 4
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    roupas = ((26, 30, 28), (24, 23, 27), (23, 8, 29))
    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 16
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, y + 10 + (0 if len(qs[0]) == 12 else -4)))
        for i, q in enumerate(qs):
            im = para_imagem(trocar(q, k.hab.troca(*roupas[(i + j) % 3])))
            img.alpha_composite(im, (4 + i * 14, y + 12 - im.height))
    img.save(AQUI / "amostra_tarde.png")
    img.resize((W * 5, H * 5), Image.NEAREST).save(AQUI / "amostra_tarde_4x.png")
    print("ações da tarde:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

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
from cotidiano import ajoelhado, largo, m, por  # noqa: E402
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


# ---------------------------------------------------------------- 0.1.2: as cenas da tarde da A
# (sesta, ensinar a lança no alvo de capim, artesanato em roda)

CESTO = [(x, y, "n" if (x + y) % 2 else "o") for x in range(2, 7) for y in (0, 1)] + [(2, 2, "o"), (6, 2, "o")]
POTE = [(3, 0, "M"), (5, 0, "M"), (2, 1, "M"), (3, 1, "m"), (4, 1, "m"), (5, 1, "m"), (6, 1, "M"),
        (3, 2, "M"), (4, 2, "M"), (5, 2, "M")]


def mostrar_peca(peca):
    """De pé, ergue a peça pronta acima da cabeça com os dois braços, de boca aberta; no quadro
    1 a peça sobe 1 px (o gesto de mostrar). `peca`: cesto, pote ou lanca."""
    out = []
    for i in range(2):
        q = largo(quadro([], CAB_BOCA, pernas="base", desce=2))
        dy = -i
        bracos = [(1, 6, "s"), (1, 5, "s"), (2, 4 + dy, "s"), (6, 6, "S"), (6, 5, "S"), (5, 4 + dy, "S")]
        if peca == "lanca":
            obj = [(x, y + 2 + dy, c) for x, y, c in lanca(0, 11, 0)]
        else:
            obj = [(x, y + 1 + dy, c) for x, y, c in (CESTO if peca == "cesto" else POTE)]
        out.append(por(q, obj + bracos))
    return out


def ralhar():
    """Meio erguido do chão (acordado pela criança), apoiado no braço de trás, o punho da frente
    levantado e a boca aberta; no quadro 1 o punho sacode. Use o balão de raiva."""
    return [
        por(largo(sentado(1, [(0, 8, "s"), (0, 9, "s")], CAB_BOCA)), [(6, 5, "S"), (7, 4, "S"), (7, 3, "S")]),
        por(largo(sentado(1, [(0, 8, "s"), (0, 9, "s")], CAB_BOCA)),
            [(6, 5, "S"), (7, 4, "S"), (8, 3, "S"), (8, 2, "S")]),
    ]


def crianca_comemorar():
    """A criança pula de alegria: agacha, salta com os braços em V, abre as pernas no alto e
    pousa. O motor sobe a criança 2 a 3 px nos quadros 1 e 2."""
    agachada = ["......", ".hhh..", "hHhSS.", "hhSxS.", ".sSS..", "sTTTS.", ".TbT..", ".ffF.."]
    return [agachada,
            crianca([(0, 3, "s"), (0, 2, "s"), (4, 3, "S"), (5, 2, "S")], [".lL...", ".fF..."]),
            crianca([(0, 2, "s"), (0, 1, "s"), (5, 2, "S"), (5, 1, "S")], ["l...L.", "f...F."]),
            agachada]


def crianca_doze(g):
    """Põe a criança (6x8) num quadro de 12x12, embaixo à esquerda, para caber a lança."""
    q = [list("............") for _ in range(12)]
    for y, l in enumerate(g):
        for x, ch in enumerate(l):
            if ch != ".":
                q[4 + y][x] = ch
    return ["".join(l) for l in q]


def crianca_mirar():
    """A criança (8 a 13 anos) mira o alvo com a lança pequena erguida, de 2 px e ponta clara;
    no quadro 1 ajeita o braço. Quadro de 12x12, com a criança nas colunas 0 a 5."""
    out = []
    for i in range(2):
        q = crianca_doze(crianca([(0, 4, "s")], ["l..L..", "f..F.."]))
        out.append(por(q, lanca(i, 9 + i, 8) + [(4, 8, "S")]))   # na altura do peito, sem cobrir o rosto
    return out


def crianca_arremessar():
    """A criança arremessa: recolhe a lança atrás da cabeça, ergue, solta (a lança sai do
    quadro: use `lanca_voando`) e acompanha o movimento."""
    diag = [(0, 6, "n"), (1, 5, "n"), (2, 4, "n"), (3, 3, "Z"), (1, 6, "q"), (2, 5, "q"), (3, 4, "z")]
    return [
        por(crianca_doze(crianca([(0, 4, "s")], ["l..L..", "f..F.."])), diag + [(2, 6, "S")]),
        por(crianca_doze(crianca([(0, 5, "s")], [".l..L.", "f...F."])), lanca(0, 9, 2) + [(4, 3, "S"), (4, 4, "S")]),
        crianca_doze(crianca([(0, 5, "s"), (4, 4, "S"), (5, 4, "S")], [".l..L.", "f....F"])),
        crianca_doze(crianca([(0, 4, "s"), (4, 5, "S")], ["l..L..", "f..F.."])),
    ]


def buscar_lanca():
    """Abaixado, pega a lança caída no chão (quadro 0) e se ergue com ela na mão (quadro 1)."""
    return [
        por(largo(quadro([(1, 7, "s"), (6, 9, "S"), (7, 10, "S")], CAB_BAIXA, pernas="dobrado", desce=2)),
            lanca(3, 11, 10) + [(7, 10, "S")]),
        por(largo(quadro([(1, 5, "s"), (1, 6, "s")], CAB)), lanca(1, 11, 6) + [(6, 6, "S")]),
    ]


def sesta_lado():
    """Deitado de lado, encolhido, dormindo; no quadro 1 o ombro sobe (respira). A cabeça fica
    à esquerda: espelhe para ela ficar do lado da casa ou da árvore."""
    vazio = ["............"] * 8
    q0 = grade(*vazio, "............", ".hh...lL....", "hhSSTTTTlLF.", ".sSTbTTf.F..")
    q1 = grade(*vazio, "............", ".hh.TTlL....", "hhSSTTTTlLF.", ".sSTbTTf.F..")
    return [q0, q1]


def crianca_cutucar():
    """A criança, de pé e inclinada, cutuca quem dorme com um galhinho; no quadro 1 recolhe o
    braço, rindo. Ponha-a a 4 a 6 px de quem dorme, virada para ele."""
    return [
        crianca([(0, 4, "s"), (4, 4, "S"), (5, 5, "n")], [".l..L.", ".f..F."]),
        crianca([(0, 4, "s"), (4, 3, "S")], ["l..L..", "f..F.."]),
    ]


CAB_IDOSO = ["...gggg.", "..gGGgg.", "..ggggSe", "...gsSSS"]
CAB_IDOSO_BOCA = ["...gggg.", "..gGGgg.", "..ggggSe", "...gsSxS"]


def idoso(pontos, cab=CAB_IDOSO):
    """O velho de pé, com o corpo do `idoso_andar_4q` e a bengala na mão de trás (coluna 0);
    os braços e objetos vêm em `pontos`. Quadro de 12x12."""
    corpo = [".TTTT...", "TTTbTT..", ".TTTbT..", "..bbbb..", "..l..L..", "..l..L..", ".ff..FF."]
    g = [list(l) for l in (["........"] + cab + corpo)]
    for y in range(6, 12):
        g[y][0] = "c"
    g[6][1] = "s"
    for x, y, ch in pontos:
        if 0 <= x < 8 and 0 <= y < 12:
            g[y][x] = ch
    return largo(["".join(l) for l in g])


def idoso_mostrar():
    """O velho ensina: aponta o alvo com o braço esticado (0 e 1, de boca aberta no 0), faz o
    gesto do arremesso com a mão vazia (2) e volta a apontar (3)."""
    braco = [(5, 5, "S"), (6, 5, "S"), (7, 5, "S")]
    return [
        por(idoso([], CAB_IDOSO_BOCA), braco + [(8, 5, "S"), (9, 4, "S")]),
        por(idoso([]), braco + [(8, 5, "S"), (9, 5, "S")]),
        por(idoso([], CAB_IDOSO_BOCA), [(5, 5, "S"), (6, 4, "S"), (6, 3, "S"), (7, 2, "S")]),
        por(idoso([]), braco + [(8, 5, "S"), (9, 4, "S")]),
    ]


def idoso_aprovar():
    """O velho aprova: a mão da frente erguida e aberta (0), e balança a cabeça de boca
    aberta, com a mão mais alta (1)."""
    return [
        por(idoso([]), [(5, 5, "S"), (6, 4, "S"), (6, 3, "S"), (6, 2, "S"), (7, 2, "S")]),
        por(idoso([], CAB_IDOSO_BOCA), [(5, 5, "S"), (6, 4, "S"), (6, 3, "S"), (7, 2, "S"), (7, 1, "S")]),
    ]


def objetos_tarde():
    """O alvo de capim (8x14): um feixe de palha amarrado embaixo, fincado numa estaca, com um
    círculo de ocre vermelho e o miolo branco pintados na frente (auditoria 13: só com as faixas,
    de longe, ele se lia como um barril ou uma colmeia); o alvo com a lança cravada no miolo
    (12x14, a lança escura entrando pela esquerda); e a lança caída no chão (14x2), quando erra."""
    alvo = [
        ".y.yy.y.", "yonyynoy", "onyrryno", "oyrWWryo", "oyrWWryo", "onyrryno", "onyyyyno", "oqqqqqqo",
        "yonyynoy", ".y.oo.y.", "...on...", "...on...", "...on...", "..nonn..",
    ]
    cravada = []
    for y, l in enumerate(alvo):
        linha = "...." + l
        if y == 3:
            linha = "qqqqqqqq" + linha[8:]
        if y == 4:
            linha = "nnnn" + linha[4:]
        cravada.append(linha)
    no_chao = ["..nnnnnnnnnnZZ", "qqqqqqqqqqqqzz"]
    return {"alvo_capim": m(*alvo), "alvo_capim_lanca": m(*cravada), "lanca_no_chao": m(*no_chao)}


FOLHAS = {
    "sesta_forte_2q": sesta, "trancar_cesto_4q": trancar_cesto, "moldar_pote_4q": moldar_pote,
    "afiar_lanca_4q": afiar_lanca, "ensinar_apontar_4q": ensinar, "crianca_imitar_4q": crianca_imitar,
    "consertar_telhado_4q": consertar_telhado,
    "mostrar_peca_cesto_2q": lambda: mostrar_peca("cesto"), "mostrar_peca_pote_2q": lambda: mostrar_peca("pote"),
    "mostrar_peca_lanca_2q": lambda: mostrar_peca("lanca"), "ralhar_2q": ralhar,
    "crianca_comemorar_4q": crianca_comemorar, "crianca_mirar_2q": crianca_mirar,
    "crianca_arremessar_4q": crianca_arremessar, "buscar_lanca_2q": buscar_lanca, "sesta_lado_2q": sesta_lado,
    "crianca_cutucar_2q": crianca_cutucar, "idoso_mostrar_4q": idoso_mostrar, "idoso_aprovar_2q": idoso_aprovar,
}


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    objs = objetos_tarde()
    for nome, px in objs.items():
        k.gravar(px, AQUI.parent / "objetos" / f"{nome}.png")
    W, H = 4 * 14 + 8, len(folhas) * 16 + 24
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
    y = 4 + len(folhas) * 16
    for x in range(0, W, 8):
        img.alpha_composite(grama, (x, y + 12))
    x = 4
    for px in objs.values():
        im = para_imagem(px)
        img.alpha_composite(im, (x, y + 14 - im.height))
        x += im.width + 4
    img.save(AQUI / "amostra_tarde.png")
    img.resize((W * 5, H * 5), Image.NEAREST).save(AQUI / "amostra_tarde_4x.png")
    print("ações da tarde:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

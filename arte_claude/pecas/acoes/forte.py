"""Ações "de 1x": versões mais fortes das subações, para quem olha o jogo de canto de olho.
Silhueta aberta (braços longe do corpo, o corpo inclinado ou agachado) e objetos de 2 px de
espessura, com a borda de cima clara para não sumir no chão nem no mato.

Mesmo padrão das outras ações: olhando para a direita, base na última linha, cores-base de
`habitantes/trocas.json`. Quadros de 8x12, ou de 12x12 com o corpo nas colunas 0 a 7 e o
objeto passando para a direita. Os objetos soltos (a caça no pau mais grossa) vão em `objetos/`.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, quadro  # noqa: E402
from cotidiano import C, ajoelhado, largo, m, por  # noqa: E402
from vida import ANDAR, CAB_BOCA  # noqa: E402

OBJ = AQUI.parent / "objetos"


def grade(*linhas):
    assert all(len(l) == len(linhas[0]) for l in linhas), linhas
    assert len(linhas) == 12, len(linhas)
    return list(linhas)


def pau(x0, x1, y):
    """Galho ou feixe de 2 px na horizontal: em cima claro (n), embaixo escuro (q). Nas folhas
    de gente, nada de 8, 25, 26, 28 ou 30: são cores-base que a troca de pele e cabelo muda."""
    return [(x, y, "n") for x in range(x0, x1 + 1)] + [(x, y + 1, "q") for x in range(x0, x1 + 1)]


def inclinar(q, dx=1, ate=9):
    """Empurra a cabeça e o tronco (linhas 0 a `ate`-1) `dx` px para a frente."""
    out = []
    for y, l in enumerate(q):
        out.append(("." * dx + l[:-dx]) if y < ate else l)
    return out


# ---------------------------------------------------------------- catar lenha

def catar_lenha():
    """Agacha junto aos galhos, levanta com eles atravessados no peito e põe o feixe no ombro.
    Os galhos têm 2 px e passam da largura do corpo: o feixe é o que se lê de longe."""
    chao = pau(6, 11, 10)
    q0 = por(largo(quadro([(1, 7, "s"), (6, 9, "S"), (7, 10, "S")], CAB_BAIXA, pernas="dobrado", desce=2)),
             chao + [(7, 10, "S")])
    diag = [(4, 9, "n"), (5, 9, "n"), (6, 8, "n"), (7, 8, "n"), (8, 7, "n"), (9, 7, "n"), (10, 6, "n"), (11, 6, "n"),
            (4, 10, "q"), (5, 10, "q"), (6, 9, "q"), (7, 9, "q"), (8, 8, "q"), (9, 8, "q"), (10, 7, "q"), (11, 7, "q")]
    q1 = por(largo(quadro([(1, 6, "s"), (6, 8, "S"), (5, 8, "S")], CAB_BAIXA, pernas="dobrado", desce=1)),
             diag + [(6, 8, "S")])
    q2 = por(largo(quadro([(1, 5, "s"), (2, 6, "s"), (6, 5, "S")])), pau(1, 11, 6) + [(2, 6, "s"), (6, 6, "S")])
    q3 = por(largo(quadro([(1, 5, "s"), (1, 6, "s"), (6, 3, "S"), (6, 2, "S")])),
             pau(0, 10, 3) + [(6, 2, "S"), (11, 3, "q"), (11, 2, "n")])
    return [q0, q1, q2, q3]


# ---------------------------------------------------------------- cesto na cabeça

def carregar_cesto_cabeca():
    """Andando com um cesto de palha largo na cabeça (8 px, com frutas vermelhas e amarelas em cima),
    os dois braços erguidos segurando as bordas. O corpo vai 1 px mais baixo, com o peso."""
    cesto = ([(x, 0, "k" if x % 3 == 0 else "y" if x % 3 == 1 else "K") for x in range(1, 7)] +
             [(x, 1, "Z") for x in range(0, 8)] + [(x, 2, "n" if x % 2 else "o") for x in range(0, 8)])
    maos = [(0, 3, "s"), (0, 4, "s"), (1, 5, "s"), (7, 3, "S"), (7, 4, "S"), (6, 5, "S")]
    return [quadro(cesto + maos, pernas=p, desce=1 + d) for p, d in ANDAR]


# ---------------------------------------------------------------- espantar

FOLHA = "V"


def espantar():
    """Espanta um bicho abanando um galho cheio de folhas, de boca aberta e dando pulinhos.
    O galho (2 px) e as folhas passam do corpo: de longe, lê como alguém agitando algo."""
    def galho(pts, folhas):
        return [(x, y, "c") for x, y in pts] + [(x, y, "V" if (x + y) % 2 else "v") for x, y in folhas]
    alto = galho([(7, 4), (7, 3), (8, 2), (8, 3), (9, 1), (9, 2)],
                 [(9, 0), (10, 0), (10, 1), (11, 1), (11, 2), (10, 2), (11, 0)])
    baixo = galho([(7, 6), (8, 6), (8, 7), (9, 7), (9, 8), (10, 8)],
                  [(10, 9), (11, 9), (11, 8), (10, 10), (11, 10), (11, 11), (10, 11)])
    cima = galho([(7, 3), (7, 2), (8, 2), (8, 1)], [(8, 0), (9, 0), (9, 1), (10, 0), (10, 1), (7, 0)])
    return [
        por(largo(quadro([(1, 3, "s"), (0, 2, "s"), (6, 4, "S")], CAB_BOCA, pernas="aberto")), alto + [(6, 4, "S")]),
        por(largo(inclinar(quadro([(0, 5, "s"), (1, 4, "s"), (6, 6, "S")], CAB_BOCA, pernas="base", desce=1))),
            baixo + [(7, 6, "S")]),
        por(largo(quadro([(1, 3, "s"), (0, 2, "s"), (0, 1, "s"), (6, 3, "S")], CAB_BOCA, pernas="aberto")),
            cima + [(6, 3, "S")]),
        por(largo(inclinar(quadro([(0, 4, "s"), (1, 5, "s"), (6, 6, "S")], CAB, pernas="dobrado", desce=1))),
            baixo + [(7, 6, "S")]),
    ]


# ---------------------------------------------------------------- tropeçar e cair

def tropecar_cair():
    """Tropeça numa pedra (z), voa de braços abertos, cai de bruços levantando poeira e fica
    tonto no chão. 12x12; segure o quadro 3 por 1 a 2 s antes de `agachar_2q`."""
    q0 = por(largo(inclinar(quadro([(0, 3, "s"), (1, 4, "s"), (7, 4, "S"), (6, 5, "S")], CAB_BOCA,
                                   pernas="passo_a"), 1)),
             [(8, 11, "z"), (9, 11, "z"), (8, 10, "Z"), (0, 2, "s")])
    q1 = grade(
        "............",
        "..........S.",
        "s......hhhSS",
        "s.....hHhSe.",
        ".s...hhhSSx.",
        "..TTTThsSS..",
        ".TTbTTT.....",
        "LbbTT.......",
        "L...........",
        "F...........",
        "........zz..",
        "........zZ..",
    )
    q2 = grade(
        "............",
        "............",
        "............",
        "............",
        ".w........w.",
        "Z..........Z",
        ".........hhh",
        "Z..TTThTThHh",
        ".sTTbTTTShSe",
        "LlbbTT.SSSS.",
        "ff....zzZ.Zw",
        "Zw.wZ.....w.",
    )
    q3 = grade(
        "............",
        "............",
        "............",
        "............",
        "..........y.",
        ".........y.y",
        "..........y.",
        "............",
        "............",
        "........hhh.",
        "FfLlbbTTThHS",
        "..ll..sSS.Se",
    )
    return [q0, q1, q2, q3]


# ---------------------------------------------------------------- água

POTE = [(2, 0, "M"), (3, 0, "j"), (4, 0, "j"), (5, 0, "M"),
        (1, 1, "M"), (2, 1, "m"), (3, 1, "m"), (4, 1, "m"), (5, 1, "m"), (6, 1, "M"),
        (1, 2, "M"), (2, 2, "m"), (3, 2, "m"), (4, 2, "M"), (5, 2, "M"), (6, 2, "M")]


def pote_em(dx, dy, cheio=True):
    return [(x + dx, y + dy, "o" if ch == "j" and not cheio else ch) for x, y, ch in POTE] + \
           [(x + dx, 3 + dy, "M") for x in (2, 3, 4, 5)]


def carregar_agua():
    """Anda com o pote de barro cheio na cabeça, a mão da frente erguida segurando.
    O pote (6 x 3, laranja, com a água clara na boca) e o braço erguido são o que se lê."""
    out = []
    for p, d in ANDAR:
        q = quadro([(1, 5, "s"), (1, 6, "s"), (0, 7, "s") if d else (1, 7, "s")], pernas=p, desce=1 + d)
        q = por(q, POTE + [(7, 1, "S"), (7, 2, "S"), (7, 3, "S"), (6, 4, "S")])
        out.append(q)
    return out


def buscar_agua():
    """Na margem, com o pote grande: chega com ele no quadril, ajoelha e mergulha o pote na
    água (respingos), ergue o pote cheio e o põe na cabeça. Depois, `carregar_agua_forte_4q`."""
    q0 = por(largo(quadro([(1, 5, "s"), (1, 6, "s"), (6, 5, "S"), (6, 6, "S")])), pote_em(5, 6, cheio=False))
    q1 = por(largo(ajoelhado([(1, 6, "s"), (5, 7, "S"), (6, 8, "S")])),
             pote_em(6, 8, cheio=False) + [(10, 7, "j"), (11, 8, "j"), (11, 10, "j"), (10, 11, "j"), (11, 11, "j")])
    q2 = por(largo(ajoelhado([(1, 6, "s"), (6, 5, "S"), (6, 6, "S")], CAB)),
             pote_em(5, 3) + [(9, 6, "j"), (10, 8, "j"), (9, 9, "j")])
    q3 = por(largo(quadro([(1, 5, "s"), (1, 6, "s")], desce=1)), POTE + [(7, 1, "S"), (7, 2, "S"), (7, 3, "S"),
                                                                       (6, 4, "S")])
    return [q0, q1, q2, q3]


# ---------------------------------------------------------------- caça no pau

def carregar_caca():
    """Um dos carregadores da caça grossa: cabeça baixa com o peso, a mão da frente erguida no
    pau. Use 2 carregadores a 16 px (8 px de vão para a caça) e `objetos/caca_no_pau_*_forte`."""
    return [quadro([(1, 5, "s"), (1, 6, "s") if d else (0, 6, "s"), (6, 4, "S"), (7, 3, "S")], CAB_BAIXA,
                   pernas=p, desce=d) for p, d in ANDAR]


def caca_no_pau():
    """O pau de 2 px (24 de largura) com o bicho pendurado pelas patas amarradas (W, corda clara).
    As linhas 0 e 1 (o pau) vão nas linhas 3 e 4 dos carregadores."""
    porco = m(
        "nnnnnnnnnnnnnnnnnnnnnnnn",
        "ddddddddWddddddWdddddddd",
        "........dd....dd........",
        ".......dnnnnnnnnd.......",
        "......xdnnnnnnnnd.......",
        "......dddddddddd........",
        ".....Wdddddddddd........",
        "......dd..dddd..........",
        "........................",
    )
    ave = m(
        "nnnnnnnnnnnnnnnnnnnnnnnn",
        "dddddddddddWWddddddddddd",
        "...........nn...........",
        "..........ZZZZ..........",
        ".........ZZgZZZ.........",
        ".........ZggZZZZ........",
        "..........ZZZZZ.........",
        "...........ZGZ..........",
        "...........kGr..........",
    )
    return {"caca_no_pau_porco_forte": porco, "caca_no_pau_ave_forte": ave}


FOLHAS = {
    "catar_lenha_forte_4q": catar_lenha, "carregar_cesto_cabeca_forte_4q": carregar_cesto_cabeca,
    "espantar_forte_4q": espantar, "tropecar_cair_forte_4q": tropecar_cair,
    "carregar_agua_forte_4q": carregar_agua, "buscar_agua_forte_4q": buscar_agua,
    "carregar_caca_forte_4q": carregar_caca,
}


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    objs = caca_no_pau()
    for nome, px in objs.items():
        k.gravar(px, OBJ / f"{nome}.png")
    # amostra: cada folha numa linha, ao lado da versão antiga; no fim, a caça carregada montada
    antigas = {"catar_lenha_forte_4q": "catar_lenha_4q", "carregar_cesto_cabeca_forte_4q": "carregar_cesto_cabeca_4q",
               "espantar_forte_4q": "espantar_4q", "tropecar_cair_forte_4q": "tropecar_cair_4q",
               "carregar_agua_forte_4q": "buscar_agua_4q", "buscar_agua_forte_4q": "buscar_agua_4q",
               "carregar_caca_forte_4q": "carregar_caca_4q"}
    W = 2 * (4 * 14) + 16
    img = Image.new("RGBA", (W, (len(folhas) + 1) * 20 + 8), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    roupas = ((26, 30, 28), (24, 23, 27), (23, 8, 29))
    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 20
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, y + 10))
        troca = k.hab.troca(*roupas[j % 3])
        velha = Image.open(AQUI / f"{antigas[nome]}.png")
        n_velha = 4 if antigas[nome].endswith("4q") else 2
        qv = velha.width // n_velha
        for i in range(n_velha):
            img.alpha_composite(velha.crop((i * qv, 0, (i + 1) * qv, velha.height)), (4 + i * 14, y))
        for i, q in enumerate(qs):
            img.alpha_composite(para_imagem(trocar(q, troca)), (W // 2 + 8 + i * 14, y))
    y = 2 + len(folhas) * 20
    for x in range(0, W, 8):
        img.alpha_composite(grama, (x, y + 10))
    for n, (nome, px) in enumerate(objs.items()):
        x0 = 4 + n * (W // 2)
        q = folhas["carregar_caca_forte_4q"]
        for i, xx in ((0, x0), (2, x0 + 16)):
            img.alpha_composite(para_imagem(trocar(q[i], k.hab.troca(*roupas[i % 3]))), (xx, y))
        img.alpha_composite(para_imagem(px), (x0, y + 3))
    img.save(AQUI / "amostra_forte.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_forte_4x.png")
    print("ações de 1x:", ", ".join(folhas), "e", ", ".join(objs))


if __name__ == "__main__":
    principal()

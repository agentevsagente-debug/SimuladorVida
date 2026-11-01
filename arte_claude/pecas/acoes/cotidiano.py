"""Cotidiano: subações de trabalho, pequenos incidentes, animais de caça e objetos de cena.
Mesmo padrão das outras ações (8x12, criança 6x8, cores-base de `habitantes/trocas.json`).
Quadros de 12x12 só quando o corpo deitado ou o objeto passam da largura (o corpo fica nas
colunas 0 a 7). Animais vão em `criaturas/`, objetos em `objetos/`.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, PERNAS, TRONCO, quadro  # noqa: E402
from vida import CAB_BOCA, CAB_FRENTE, andar, crianca, sentado  # noqa: E402

OBJ = AQUI.parent / "objetos"
CRI = AQUI.parent / "criaturas"
COSTAS = [(1, 5, "s"), (1, 6, "s"), (1, 7, "s")]
AJOELHADO = ["..lLL...", "..lLL...", "fflllL.."]


def ajoelhado(pontos, cab=CAB_BAIXA):
    g = [list(l) for l in quadro(pontos, cab, TRONCO, pernas="nada", desce=1)]
    for j, l in enumerate(AJOELHADO):
        for x, ch in enumerate(l):
            if ch != ".":
                g[9 + j][x] = ch
    for x, y, ch in pontos:
        if 0 <= x < 8 and 0 <= y < 12:
            g[y][x] = ch
    return ["".join(l) for l in g]


def largo(m, colunas=4):
    return [l + "." * colunas for l in m]


def por(m, pontos):
    g = [list(l) for l in m]
    for x, y, ch in pontos:
        if 0 <= y < len(g) and 0 <= x < len(g[0]):
            g[y][x] = ch
    return ["".join(l) for l in g]


# ---------------------------------------------------------------- trabalho

CESTO_QUADRIL = [(5, 8, "N"), (6, 8, "N"), (7, 8, "N"), (5, 9, "o"), (6, 9, "n"), (7, 9, "o")]


def colher_arbusto():
    """Alcança no alto, pega a fruta e põe no cesto do quadril."""
    return [
        quadro(COSTAS + CESTO_QUADRIL + [(6, 4, "S"), (6, 3, "S"), (7, 2, "S"), (7, 1, "S")]),
        quadro(COSTAS + CESTO_QUADRIL + [(6, 4, "S"), (6, 3, "S"), (7, 2, "S"), (7, 1, "k")]),
        quadro(COSTAS + CESTO_QUADRIL + [(6, 5, "S"), (6, 6, "S"), (7, 7, "k")], CAB_BAIXA),
        quadro(COSTAS + CESTO_QUADRIL + [(6, 5, "S"), (6, 6, "S"), (6, 7, "S"), (6, 8, "k")], CAB_BAIXA),
    ]


def cavar_raiz():
    """Ajoelhado, cava com uma vara e tira a raiz."""
    return [
        ajoelhado([(1, 6, "s"), (5, 6, "S"), (6, 5, "S"), (7, 4, "c"), (7, 3, "c")]),
        ajoelhado([(1, 6, "s"), (5, 7, "S"), (6, 7, "S"), (7, 8, "c"), (7, 9, "c"), (7, 10, "c")]),
        ajoelhado([(1, 6, "s"), (5, 7, "S"), (6, 7, "S"), (7, 8, "c"), (7, 9, "c"), (6, 9, "d"), (7, 6, "n")]),
        ajoelhado([(1, 6, "s"), (6, 6, "S"), (7, 5, "S"), (7, 6, "M"), (7, 7, "M"), (6, 8, "d")], CAB),
    ]


def catar_lenha():
    """Abaixa, pega galhos do chão e levanta com eles no braço."""
    return [
        quadro(COSTAS + [(6, 5, "S"), (6, 6, "S"), (7, 7, "S")]),
        quadro([(1, 6, "s"), (6, 7, "S"), (7, 8, "S")], CAB_BAIXA, pernas="dobrado", desce=2),
        quadro([(1, 7, "s"), (6, 9, "S"), (7, 10, "S"), (5, 11, "n"), (6, 11, "o"), (7, 11, "n")], CAB_BAIXA,
               pernas="dobrado", desce=2),
        quadro([(1, 5, "s"), (6, 5, "S"), (5, 6, "S"), (3, 6, "n"), (4, 6, "o"), (5, 7, "n"), (6, 7, "o"), (7, 7, "d")]),
    ]


def carregar_cesto_cabeca():
    """Andando com o cesto na cabeça, seguro pelas duas mãos."""
    cesto = [(x, 0, "y" if x % 2 else "k") for x in range(2, 6)] + [(x, 1, "N") for x in range(1, 7)]
    maos = [(1, 2, "s"), (1, 3, "s"), (6, 2, "S"), (6, 3, "S")]
    return andar(cesto + maos)


def cacar_espreitar():
    """Anda agachado, devagar, com a lança na horizontal."""
    lanca = [(x, 6, "c") for x in range(0, 7)] + [(7, 6, "Z")]
    out = []
    for p in ("dobrado", "base", "dobrado", "aberto"):
        out.append(quadro(lanca + [(2, 7, "s"), (5, 7, "S")], CAB, pernas=p, desce=2))
    return out


def cacar_arremessar():
    """Recolhe a lança atrás do ombro, avança e arremessa. A lança solta voa como objeto
    (`objetos/lanca_voando`) a partir do quadro 2."""
    return [
        quadro([(0, 4, "Z")] + [(x, 4, "c") for x in range(1, 6)] + [(6, 4, "S"), (1, 5, "s")], pernas="base"),
        quadro([(x, 2, "c") for x in range(2, 7)] + [(7, 2, "Z"), (6, 3, "S"), (1, 6, "s")], pernas="base"),
        quadro([(6, 4, "S"), (7, 4, "S"), (1, 6, "s"), (0, 7, "s")], pernas="aberto"),
        quadro([(6, 5, "S"), (7, 6, "S"), (1, 5, "s"), (1, 6, "s")], pernas="dobrado"),
    ]


def carregar_caca():
    """Um dos dois carregadores da caça: o pau no ombro, seguro pela mão da frente.
    Use 2 carregadores a 12 px um do outro e `objetos/caca_no_pau_*` entre eles."""
    return andar([(1, 5, "s"), (1, 6, "s"), (6, 3, "S"), (6, 4, "S")], CAB_BAIXA)


def cozinhar_mexer():
    """Agachado diante da `objetos/panela`, mexe com uma colher de pau em círculo."""
    pontas = [[(7, 8, "c"), (7, 9, "c")], [(6, 9, "c"), (7, 8, "c")], [(7, 8, "c"), (7, 10, "c")],
              [(6, 8, "c"), (7, 9, "c")]]
    return [quadro([(1, 7, "s"), (6, 7, "S")] + p, CAB_BAIXA, pernas="dobrado", desce=2) for p in pontas]


def cozinhar_espeto():
    """Sentado ao lado do `objetos/espeto`, girando a manivela."""
    giro = [[(6, 8, "S"), (7, 8, "c")], [(6, 7, "S"), (7, 7, "c")], [(6, 8, "S"), (7, 9, "c")],
            [(6, 9, "S"), (7, 9, "c")]]
    return [sentado(2, [(1, 7, "s")] + g) for g in giro]


CUIA = [(6, 7, "N"), (7, 7, "N"), (6, 8, "o"), (7, 8, "o")]


def buscar_agua():
    """Na margem: abaixa, enche a cuia e levanta com ela cheia."""
    return [
        quadro(COSTAS + [(6, 5, "S"), (6, 6, "S")] + CUIA),
        quadro([(1, 6, "s"), (6, 8, "S"), (6, 9, "N"), (7, 9, "N")], CAB_BAIXA, pernas="dobrado", desce=2),
        quadro([(1, 7, "s"), (6, 9, "S"), (6, 10, "N"), (7, 10, "j"), (7, 11, "j")], CAB_BAIXA, pernas="dobrado",
               desce=2),
        quadro(COSTAS + [(6, 5, "S"), (6, 6, "S"), (6, 7, "N"), (7, 7, "j"), (6, 8, "o"), (7, 8, "o")]),
    ]


def banhar():
    """Na margem: joga água da cuia sobre a cabeça."""
    return [
        quadro(COSTAS + [(6, 5, "S"), (6, 6, "S")] + CUIA),
        quadro([(1, 5, "s"), (6, 3, "S"), (6, 2, "S"), (7, 1, "N"), (6, 1, "j")]),
        quadro([(1, 5, "s"), (6, 2, "S"), (5, 1, "S"), (5, 0, "N"), (2, 0, "j"), (6, 0, "j"), (0, 2, "j"), (7, 3, "j")]),
        quadro([(1, 5, "s"), (6, 5, "S"), (6, 6, "S"), (1, 1, "j"), (7, 4, "j"), (0, 8, "j")]),
    ]


def vigia():
    """Sentado com a lança em pé, de noite. No quadro 2 a cabeça pesa de sono."""
    lanca = [(7, y, "c") for y in range(1, 12)] + [(7, 0, "Z")]
    return [sentado(2, lanca + [(1, 7, "s"), (6, 7, "S")]), sentado(2, lanca + [(1, 8, "s"), (6, 8, "S")], CAB_BAIXA)]


def contar_historia():
    """De pé, gesticulando largo e de boca aberta."""
    return [
        quadro([(1, 4, "s"), (0, 3, "s"), (6, 4, "S"), (7, 3, "S")], CAB_BOCA),
        quadro([(1, 5, "s"), (0, 5, "s"), (6, 5, "S"), (7, 5, "S")], CAB),
        quadro([(1, 3, "s"), (1, 2, "s"), (6, 5, "S"), (7, 6, "S")], CAB_BOCA),
        quadro([(1, 5, "s"), (1, 6, "s"), (6, 3, "S"), (6, 2, "S"), (7, 1, "S")], CAB_BOCA),
    ]


def ouvir_sentado():
    """Ouvinte sentado de pernas cruzadas, balançando a cabeça."""
    return [sentado(2, [(1, 7, "s"), (6, 8, "S")]), sentado(3, [(1, 8, "s"), (6, 9, "S")], CAB_FRENTE)]


# ---------------------------------------------------------------- incidentes

def criancas_brigar():
    """Uma criança empurrando e puxando (6x8). O par fica de frente, espelhado, a 5 px."""
    return [crianca([(4, 4, "S"), (5, 4, "S"), (0, 4, "s")], [".l.L..", ".f.F.."]),
            crianca([(4, 3, "S"), (5, 3, "S"), (0, 5, "s")], ["l..L..", "f...F."]),
            crianca([(4, 4, "S"), (5, 5, "S"), (0, 3, "s")], [".l..L.", "f...F."]),
            crianca([(3, 4, "S"), (0, 4, "s")], [".lL...", ".fF..."])]


def tropecar_cair():
    """Tropeça, perde o equilíbrio e cai de bruços (12x12: no chão, o corpo vai até a coluna 11)."""
    q0 = largo(quadro([(1, 5, "s"), (6, 5, "S"), (7, 6, "S")], pernas="passo_a"))
    q1 = largo(por(quadro([(0, 4, "s"), (7, 4, "S")], pernas="aberto"), [(1, 3, "s")]))
    q2 = ["............"] * 5 + [
        ".....hhh....",
        "...TTThHh...",
        ".sTTbTThSe..",
        "LlbbTT.SS...",
        "L.......S...",
        "ff..........",
        "............",
    ]
    q3 = ["............"] * 9 + [
        "........hhh.",
        "FfLlbbTTThHS",
        "..ll..sSS.Se",
    ]
    return [q0, q1, q2, q3]


def espantar():
    """Espanta um bicho: abana os braços para cima e para os lados, dando pulinhos."""
    return [quadro([(1, 3, "s"), (0, 2, "s"), (6, 3, "S"), (7, 2, "S")], CAB_BOCA, pernas="aberto"),
            quadro([(0, 5, "s"), (1, 5, "s"), (6, 5, "S"), (7, 5, "S")], CAB, pernas="base", desce=1),
            quadro([(1, 3, "s"), (0, 2, "s"), (6, 3, "S"), (7, 2, "S")], CAB_BOCA, pernas="aberto"),
            quadro([(1, 6, "s"), (0, 7, "s"), (6, 4, "S"), (7, 3, "S")], CAB, pernas="base")]


def discutir():
    """Discussão: braços abertos e palmas para cima, inclinado para a frente. O par fica de
    frente, espelhado, a 9 px; os dois usam a mesma folha com quadros defasados."""
    return [quadro([(0, 5, "s"), (1, 5, "s"), (6, 5, "S"), (7, 4, "S")], CAB_BOCA),
            quadro([(0, 4, "s"), (1, 5, "s"), (6, 4, "S"), (7, 3, "S")], CAB_BOCA, pernas="base"),
            quadro([(1, 6, "s"), (1, 7, "s"), (6, 5, "S"), (7, 5, "S")], CAB),
            quadro([(0, 5, "s"), (1, 5, "s"), (6, 3, "S"), (7, 2, "S")], CAB_BOCA, pernas="base")]


def abraco():
    """Abraço de reencontro: braços estendidos que fecham. O par fica de frente, espelhado,
    a 5 px, e os braços se cruzam por trás das costas do outro."""
    return [quadro([(1, 5, "s"), (6, 4, "S"), (7, 4, "S")], pernas="passo_a"),
            quadro([(1, 4, "s"), (6, 4, "S"), (7, 4, "S"), (7, 5, "S")], pernas="meio_a"),
            quadro([(6, 4, "S"), (7, 4, "S"), (7, 5, "s"), (6, 6, "S"), (7, 6, "S")], CAB_BAIXA),
            quadro([(6, 4, "S"), (7, 4, "S"), (7, 5, "s"), (6, 6, "S"), (7, 6, "S")], CAB_BAIXA, desce=1)]


FOLHAS = {
    "colher_arbusto_4q": colher_arbusto, "cavar_raiz_4q": cavar_raiz, "catar_lenha_4q": catar_lenha,
    "carregar_cesto_cabeca_4q": carregar_cesto_cabeca, "cacar_espreitar_4q": cacar_espreitar,
    "cacar_arremessar_4q": cacar_arremessar, "carregar_caca_4q": carregar_caca,
    "cozinhar_mexer_4q": cozinhar_mexer, "cozinhar_espeto_4q": cozinhar_espeto,
    "buscar_agua_4q": buscar_agua, "banhar_4q": banhar, "vigia_2q": vigia,
    "contar_historia_4q": contar_historia, "ouvir_sentado_2q": ouvir_sentado,
    "criancas_brigar_4q": criancas_brigar, "tropecar_cair_4q": tropecar_cair, "espantar_4q": espantar,
    "discutir_4q": discutir, "abraco_4q": abraco,
}


# ---------------------------------------------------------------- animais e objetos

C = dict(k.CORES, W=31, r=20, g=11, G=12)   # cores locais dos animais e objetos


def m(*ls):
    return [[None if ch == "." else C[ch] for ch in l] for l in ls]


def animais():
    porco = [m(".........." , "..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", ".d.d..d.d."),
             m("..........", "..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", "d..d.d..d."),
             m("..........", "..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", ".d.d..d.d."),
             m("..........", "...dddddd.", "..dnndnddd", ".dnnnnnnnd", ".ddddddddW", "..d.d.d.d.")]
    ave = [m("......r.", ".....Gk.", "..ZZZG..", ".ZgZZZ..", "ZggZZ...", ".ZZZZ...", "..n.n...", "..n.n..."),
           m("........", "......r.", ".....Gk.", "..ZZZG..", ".ZgZZZ..", "ZggZZZ..", "..n..n..", ".n...n.."),
           m("........", "........", "......r.", "..ZZZZGk", ".ZgZZZ..", "ZggZZ...", "..n.n...", "..n.n..."),
           m("......r.", ".....Gk.", "..ZZZG..", ".ZgZZZ..", "ZggZZ...", ".ZZZZ...", "...nn...", "..n..n..")]
    porco_abatido = m("..........", "..........", "..dddddd..", "nnnnnnndd.", "dddddddxW.", ".dd..dd...")
    ave_abatida = m("........", "........", "........", "........", "r.ZZZZg.", "kGZgZZZn", ".ZZZZZ.n", "........")
    return {"porco_do_mato_4q": porco, "ave_grande_4q": ave}, {"porco_abatido": porco_abatido,
                                                                "ave_abatida": ave_abatida}


def objetos(abatidos):
    o = {
        "lanca_voando": m("cccccccccccZ", "...........z", "............"),
        "panela": m("........", "..qMMq..", ".qMqqMq.", ".MqqqqM.", "..MMMM..", ".Z.dd.Z.", "ZZ.dd.ZZ", "........"),
        "espeto": m("....c.......", "....c...M...", "cccccccMqMcc", "....c..MqM..", "....c...M...",
                    "....c...rk..", "...ZZ...kr..", "...ZZ..ZZZ.."),
        "cuia_cheia": m("NjjN", ".oo."),
    }
    for nome, bicho in abatidos.items():
        w = max(20, len(bicho[0]) + 6)
        q = [[None] * w for _ in range(len(bicho) + 1)]
        for x in range(w):
            q[0][x] = C["c"]
        ox = (w - len(bicho[0])) // 2
        for y, l in enumerate(bicho):
            for x, c in enumerate(l):
                if c is not None:
                    q[y + 1 - 2 if y >= 2 else y + 1][x + ox] = c
        q[1][ox + 1] = C["d"]
        q[1][ox + len(bicho[0]) - 2] = C["d"]
        o[f"caca_no_pau_{nome.split('_')[0]}"] = q
    return o


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    vivos, abatidos = animais()
    for nome, qs in vivos.items():
        k.gravar(k.folha_quadros(qs), CRI / f"{nome}.png")
    for nome, px in abatidos.items():
        k.gravar(px, CRI / f"{nome}.png")
    objs = objetos(abatidos)
    for nome, px in objs.items():
        k.gravar(px, OBJ / f"{nome}.png")
    # amostra: cada folha numa linha; animais e objetos no fim
    W = 4 * 14 + 8
    linhas = (len(folhas) + 1) // 2 + 2
    img = Image.new("RGBA", (W * 2 + 4, linhas * 20 + 4), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    for j, (nome, qs) in enumerate(folhas.items()):
        cx, cy = (j % 2) * (W + 4), 2 + (j // 2) * 20
        for x in range(cx, cx + W, 8):
            img.alpha_composite(grama, (x, cy + 10))
        for i, q in enumerate(qs):
            pele, cab, roupa = ((26, 30, 28), (24, 23, 27), (23, 8, 29))[j % 3]
            img.alpha_composite(para_imagem(trocar(q, k.hab.troca(pele, cab, roupa))),
                                (cx + 4 + i * 14, cy + 12 - len(q)))
    y = 2 + ((len(folhas) + 1) // 2) * 20
    x = 4
    for qs in vivos.values():
        for q in qs:
            img.alpha_composite(para_imagem(q), (x, y + 8 - len(q)))
            x += len(q[0]) + 3
    for px in list(abatidos.values()) + list(objs.values()):
        img.alpha_composite(para_imagem(px), (x, y + 8 - len(px) if len(px) <= 8 else y))
        x += len(px[0]) + 3
        if x > W * 2 - 20:
            x, y = 4, y + 16
    img.save(AQUI / "amostra_cotidiano.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_cotidiano_4x.png")
    print("cotidiano:", len(folhas), "folhas,", len(vivos), "animais,", len(objs), "objetos")


if __name__ == "__main__":
    principal()

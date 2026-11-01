"""Caçada em sequência: as peças que faltavam entre o espreitar e a volta com a caça.
- gente (`acoes/`): apontar a caça, comemorar o acerto e amarrar o bicho ao pau;
- bichos (`criaturas/`): o porco correndo (fugindo) e atingido pela lança, e a ave fugindo;
- objetos (`objetos/`): a lança cravada no chão (quando erra) e o pau no chão, ao lado do bicho.
O mapa da sequência inteira, com as distâncias, está na seção 24 do LEIA-ME.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, quadro  # noqa: E402
from cotidiano import ajoelhado, largo, m, por  # noqa: E402
from vida import CAB_BOCA, CAB_ESQ  # noqa: E402

OBJ = AQUI.parent / "objetos"
CRI = AQUI.parent / "criaturas"


# ---------------------------------------------------------------- gente

def apontar():
    """Agachado, com a lança em pé na mão de trás: aponta a caça com o braço esticado e vira a
    cabeça para trás, avisando os outros (quadro 1)."""
    lanca = [(0, y, "c") for y in range(1, 12)] + [(0, 0, "Z")]
    braco = [(5, 6, "S"), (6, 6, "S"), (7, 6, "S"), (1, 7, "s")]
    return [quadro(lanca + braco, CAB, pernas="dobrado", desce=2),
            quadro(lanca + braco, CAB_ESQ, pernas="dobrado", desce=2)]


def comemorar():
    """Acertou: pula com a lança erguida acima da cabeça com as duas mãos, de boca aberta.
    A lança tem 2 px (n em cima, c embaixo) e passa do corpo dos dois lados."""
    def lanca(y):
        return [(x, y, "n") for x in range(0, 11)] + [(x, y + 1, "c") for x in range(0, 11)] + \
               [(11, y, "Z"), (11, y + 1, "z")]
    alto = [(1, 2, "s"), (1, 3, "s"), (6, 2, "S"), (6, 3, "S")]
    baixo = [(1, 4, "s"), (2, 5, "s"), (6, 4, "S"), (5, 5, "S")]
    return [
        por(largo(quadro([], CAB_BOCA, pernas="aberto", desce=1)), lanca(0) + alto),
        por(largo(quadro([], CAB_BOCA, pernas="dobrado", desce=2)), lanca(2) + baixo),
        por(largo(quadro([], CAB_BOCA, pernas="meio_a", desce=1)), lanca(0) + alto),
        por(largo(quadro([], CAB, pernas="dobrado", desce=2)), lanca(2) + baixo),
    ]


def amarrar():
    """Ajoelhado ao lado do bicho caído (que fica à direita, no chão), passa a corda clara (Z)
    em volta das patas e puxa o nó. Use com `criaturas/porco_abatido` ou `ave_abatida` e
    `objetos/pau_no_chao`."""
    return [
        largo(ajoelhado([(1, 6, "s"), (5, 7, "S"), (6, 8, "S"), (7, 9, "Z"), (7, 8, "Z")])),
        por(largo(ajoelhado([(1, 6, "s"), (5, 8, "S"), (6, 9, "S")])), [(7, 9, "Z"), (8, 10, "Z"), (8, 8, "Z")]),
        por(largo(ajoelhado([(1, 6, "s"), (5, 7, "S"), (6, 7, "S")])), [(7, 7, "Z"), (8, 9, "Z"), (8, 10, "Z")]),
        por(largo(ajoelhado([(1, 6, "s"), (6, 6, "S"), (5, 5, "S")], CAB)), [(7, 6, "Z"), (8, 8, "Z"), (8, 9, "Z")]),
    ]


FOLHAS = {"cacar_apontar_2q": apontar, "cacar_comemorar_4q": comemorar, "cacar_amarrar_4q": amarrar}


# ---------------------------------------------------------------- bichos e objetos

def bichos():
    porco_correr = [
        m("..........", "..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", "d.d....d.d"),
        m("..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", "..dd..dd..", ".........."),
        m("..........", "..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", ".dd....dd."),
        m("..dddddd..", ".dnndnddd.", "dnnnnnnndx", "dddddddWd.", "...dddd...", ".........."),
    ]
    # 12x8: o porco nas colunas 2 a 11 e a lança cravada no lombo, saindo para trás
    porco_atingido = [
        m("cc..........", "..cc........", "....cdddddd.", "...dnrdnddd.", "..dnnnnnnndx", "..dddddddWd.",
          ".d.d....d.d.", "............"),
        m("............", "cc..........", "..cc........", "....cddddd..", "...dnrdnddd.", "..dnnnnnnndd",
          "..ddddddd.dx", "...d.d..d.W."),
        m("............", "............", "............", "cc..........", "..ccddddd...", "..dnrnndddd.",
          "..ddnnnnnddx", "..d.d.ddWd.."),
        m("............", "............", "............", "............", "cc..........", "..ccdddddd..",
          "..nnrnnnnddx", "..dddddddxW."),
    ]
    ave_fugir = [
        m(".Z......", "ZgZ...r.", ".ZZ..Gk.", "..ZZZG..", ".ZgZZZ..", "ZggZZ...", "..n..n..", ".n....n."),
        m("........", "......r.", ".....Gk.", "ZZZZZG..", "ZgZZZZ..", "ZggZZ...", "...nn...", "..n..n.."),
        m("........", "......r.", ".....Gk.", "..ZZZG..", ".ZgZZZ..", "ZggZZZ..", "ZgZn.n..", ".Z.n..n."),
        m("........", "......r.", ".....Gk.", "ZZZZZG..", "ZgZZZZ..", "ZggZZ...", "...nn...", "..n..n.."),
    ]
    return {"porco_correr_4q": porco_correr, "porco_atingido_4q": porco_atingido, "ave_fugir_4q": ave_fugir}


def objetos():
    return {
        # errou: a lança fica cravada no chão, inclinada (a ponta enterrada na última linha)
        "lanca_cravada": m("Zz......", ".nc.....", "..nc....", "...nc...", "....nc..", ".....nc.", "......c.",
                           "......d."),
        # o pau de 2 px no chão, ao lado do bicho caído, antes de amarrar
        "pau_no_chao": m("nnnnnnnnnnnnnnnnnnnnnnnn", "dddddddddddddddddddddddd"),
    }


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    vivos = bichos()
    for nome, qs in vivos.items():
        k.gravar(k.folha_quadros(qs), CRI / f"{nome}.png")
    objs = objetos()
    for nome, px in objs.items():
        k.gravar(px, OBJ / f"{nome}.png")

    # amostra: a sequência inteira, uma cena por linha, com as peças já existentes
    def abrir(rel, i=0):
        im = Image.open(AQUI.parent / f"{rel}.png").convert("RGBA")
        fim = rel.rsplit("_", 1)[1]
        n = int(fim[:-1]) if fim[-1] == "q" and fim[:-1].isdigit() else 1
        w = im.width // n
        return im.crop((i * w, 0, (i + 1) * w, im.height))

    roupas = ((26, 30, 28), (24, 23, 27), (23, 8, 29))

    def gente(rel, i, t):
        q = abrir(rel, i)
        px = [[None if a == 0 else PALETA.index((r, g, b)) for r, g, b, a in
               [q.getpixel((x, y)) for x in range(q.width)]] for y in range(q.height)]
        return para_imagem(trocar(px, k.hab.troca(*roupas[t % 3])))

    cenas = [
        # 1. espreitar: dois caçadores agachados atrás do porco que fuça
        [("g", "acoes/cacar_espreitar_4q", 0, 4, 0), ("g", "acoes/cacar_espreitar_4q", 2, 14, 1),
         ("b", "criaturas/porco_do_mato_4q", 1, 52, 0)],
        # 2. apontar
        [("g", "acoes/cacar_espreitar_4q", 1, 4, 0), ("g", "acoes/cacar_apontar_2q", 1, 16, 1),
         ("b", "criaturas/porco_do_mato_4q", 2, 48, 0)],
        # 3. arremessar, com a lança voando
        [("g", "acoes/cacar_espreitar_4q", 3, 4, 0), ("g", "acoes/cacar_arremessar_4q", 2, 16, 1),
         ("b", "objetos/lanca_voando", 0, 28, 4), ("b", "criaturas/porco_do_mato_4q", 0, 46, 0)],
        # 4. o porco atingido cai
        [("g", "acoes/cacar_espreitar_4q", 0, 4, 0), ("g", "acoes/cacar_arremessar_4q", 3, 16, 1),
         ("b", "criaturas/porco_atingido_4q", 1, 42, 0), ("b", "criaturas/porco_atingido_4q", 3, 58, 0)],
        # 5. errou: a lança cravada e o porco fugindo
        [("g", "acoes/cacar_espreitar_4q", 0, 4, 0), ("g", "acoes/cacar_arremessar_4q", 3, 16, 1),
         ("b", "objetos/lanca_cravada", 0, 38, 0), ("b", "criaturas/porco_correr_4q", 1, 56, 0)],
        # 6. comemorar
        [("g", "acoes/cacar_comemorar_4q", 0, 4, 0), ("g", "acoes/cacar_comemorar_4q", 3, 22, 1),
         ("b", "criaturas/porco_abatido", 0, 46, 0)],
        # 7. amarrar ao pau
        [("b", "objetos/pau_no_chao", 0, 40, 0), ("g", "acoes/cacar_amarrar_4q", 1, 26, 1),
         ("b", "criaturas/porco_abatido", 0, 34, 0)],
        # 8. volta com a caça no pau
        [("g", "acoes/carregar_caca_forte_4q", 0, 20, 0), ("g", "acoes/carregar_caca_forte_4q", 2, 36, 1),
         ("o", "objetos/caca_no_pau_porco_forte", 0, 20, 3)],
        # a ave: fugindo, abatida e no pau
        [("b", "criaturas/ave_fugir_4q", 0, 4, 0), ("b", "criaturas/ave_fugir_4q", 2, 16, 0),
         ("b", "criaturas/ave_abatida", 0, 30, 0), ("g", "acoes/carregar_caca_forte_4q", 1, 44, 0),
         ("g", "acoes/carregar_caca_forte_4q", 3, 60, 1), ("o", "objetos/caca_no_pau_ave_forte", 0, 44, 3)],
    ]
    W = 76
    img = Image.new("RGBA", (W, len(cenas) * 18 + 4), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    for j, cena in enumerate(cenas):
        y = 2 + j * 18
        for x in range(0, W, 8):
            img.alpha_composite(grama, (x, y + 10))
        for tipo, rel, i, x, extra in cena:
            if tipo == "g":
                im = gente(rel, i, extra)
                img.alpha_composite(im, (x, y + 12 - im.height))
            elif tipo == "o":
                img.alpha_composite(abrir(rel, i), (x, y + extra))
            else:
                im = abrir(rel, i)
                img.alpha_composite(im, (x, y + 12 - im.height - (extra if rel.endswith("voando") else 0)))
    img.save(AQUI / "amostra_cacada.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_cacada_4x.png")
    print("caçada:", ", ".join(list(folhas) + list(vivos) + list(objs)))


if __name__ == "__main__":
    principal()

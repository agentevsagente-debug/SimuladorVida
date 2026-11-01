"""Pesca e lavagem no lago, no padrão das ações "de 1x" (`forte.py`): silhueta aberta, lança
de 2 px com a ponta clara, e o que se lê de longe passando da largura do corpo.

Quem está na água rasa tem a linha 9 (adulto) ou 5 (criança) na superfície: ali ficam as
marolas (j) dos dois lados do corpo, e daí para baixo as pernas viram a sombra delas na água
(a, a cor da superfície do lago). Ponha a linha 9 (ou 5) na linha da superfície do lago,
isto é, a base do quadro 2 px abaixo dela. A lança e o peixe que entram na água também
viram sombra.

Os peixes nas folhas de gente usam 3 (dorso), 12 e 11 (corpo) e 31 (barriga): nada de 8,
25, 26, 28 ou 30, que a troca de pele e cabelo muda.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, quadro  # noqa: E402
from cotidiano import ajoelhado, largo, m, por  # noqa: E402
from forte import inclinar  # noqa: E402
from vida import ANDAR, CAB_BOCA, crianca  # noqa: E402

OBJ = AQUI.parent / "objetos"


def haste(x0, y0, x1, y1, ponta=True):
    """Lança de 2 px de (x0, y0) até a ponta (x1, y1): deitada, o lado de cima é claro (n) e o
    de baixo escuro (q); em pé, o da esquerda é claro. A ponta (2 px) é Z e z."""
    pts = []
    passos = max(abs(x1 - x0), abs(y1 - y0))
    deitada = abs(x1 - x0) >= abs(y1 - y0)
    for i in range(passos + 1):
        x = round(x0 + (x1 - x0) * i / passos)
        y = round(y0 + (y1 - y0) * i / passos)
        claro, escuro = ("Z", "z") if ponta and i >= passos - 1 else ("n", "q")
        if deitada:
            pts += [(x, y, claro), (x, y + 1, escuro)]
        else:
            pts += [(x, y, claro), (x + 1, y, escuro)]
    return pts


def peixe(x, y, vira=False):
    """Peixe de 6 x 3 com a cabeça na direita (x, y é o canto de cima à esquerda): rabo em
    forquilha, dorso escuro, corpo prateado, barriga clara e o focinho escuro. `vira`: o rabo
    batendo, para o peixe que se debate."""
    forma = ([".eeee.", "e.ZZZe", "...ww."] if vira else
             ["e..ee.", ".eZZZe", "e..ww."])
    return [(x + i, y + j, ch) for j, l in enumerate(forma) for i, ch in enumerate(l) if ch != "."]


def na_agua(g, linha):
    """Da linha `linha` para baixo, o corpo e o que mais houver viram a sombra na água (a);
    na própria linha, uma marola de cada lado."""
    g = [list(l) for l in g]
    for y in range(linha + 1, len(g)):
        for x, ch in enumerate(g[y]):
            if ch != ".":
                g[y][x] = "a"
    xs = [x for x, ch in enumerate(g[linha]) if ch != "."]
    if xs:
        for x, ch in ((xs[0] - 1, "j"), (xs[0] - 2, "a"), (xs[-1] + 1, "j"), (xs[-1] + 2, "a")):
            if 0 <= x < len(g[0]) and g[linha][x] == ".":
                g[linha][x] = ch
    return ["".join(l) for l in g]


def respingo(pontos):
    return [(x, y, ch) for x, y, ch in pontos]


# ---------------------------------------------------------------- pesca

def pescar_espreitar():
    """Na água rasa, curvado, a lança apontada para a água à frente, esperando o peixe. Os 2
    quadros só mexem a cabeça e a ponta: segure cada um por 1 a 3 s."""
    q0 = por(largo(inclinar(quadro([(2, 4, "s"), (6, 6, "S")], CAB_BAIXA, pernas="base"))),
             haste(0, 2, 11, 7) + [(2, 3, "s"), (6, 5, "S"), (7, 6, "S")])
    q1 = por(largo(inclinar(quadro([(2, 4, "s"), (6, 6, "S")], CAB_BAIXA, pernas="base"))),
             haste(0, 3, 11, 8) + [(2, 4, "s"), (6, 6, "S"), (7, 6, "S")])
    return [na_agua(q0, 9), na_agua(q1, 9)]


def pescar_arpoar():
    """Mira com a lança puxada para trás, arpoa (a ponta entra na água e espirra), ergue a lança
    com o peixe na ponta e mostra o peixe se debatendo, de boca aberta."""
    q0 = na_agua(por(largo(quadro([(1, 5, "s"), (6, 5, "S")], CAB_BAIXA, pernas="base")),
                     haste(0, 1, 9, 6) + [(1, 3, "s"), (1, 4, "s"), (6, 4, "S")]), 9)
    q1 = na_agua(por(largo(inclinar(quadro([(1, 5, "s"), (6, 6, "S")], CAB_BAIXA, pernas="base"), 2)),
                     haste(3, 3, 11, 11) + [(4, 5, "s"), (7, 6, "S"), (8, 7, "S")]), 9)
    q1 = por(q1, respingo([(9, 8, "j"), (11, 7, "w"), (10, 6, "j"), (8, 7, "j"), (11, 8, "j")]))
    q2 = na_agua(por(largo(quadro([(1, 5, "s"), (6, 5, "S")], pernas="base")),
                     haste(5, 9, 9, 2) + peixe(6, 0) + [(2, 6, "s"), (6, 5, "S"), (6, 6, "S")]), 9)
    q2 = por(q2, respingo([(9, 4, "j"), (11, 6, "j"), (10, 8, "j")]))
    q3 = na_agua(por(largo(quadro([(1, 4, "s"), (0, 3, "s"), (6, 5, "S")], CAB_BOCA, pernas="base")),
                     haste(5, 9, 9, 2) + peixe(6, 0, vira=True) + [(0, 2, "s"), (6, 5, "S"), (6, 6, "S")]), 9)
    q3 = por(q3, respingo([(11, 3, "j"), (6, 0, "j")]))
    return [q0, q1, q2, q3]


def carregar_peixe():
    """Volta da pesca andando, a lança no ombro e o peixe espetado na ponta, à frente e no alto."""
    out = []
    for p, d in ANDAR:
        q = largo(quadro([(1, 5, "s"), (1, 6, "s") if d else (0, 6, "s"), (6, 5, "S")], pernas=p, desce=d))
        out.append(por(q, haste(0, 7, 10, 2) + peixe(6, 0) + [(5, 4 + d, "S"), (6, 4 + d, "S")]))
    return out


# ---------------------------------------------------------------- lavagem

PANO_MOLHADO = "z"     # pano escuro de molhado (11) com a dobra clara (12)


def lavar_margem():
    """Ajoelhado na beira do lago, lava um pano: mergulha, esfrega, torce no alto (pingando) e
    bate na água (espirra). O pano e os respingos ficam à frente, nas colunas 8 a 11: ponha o
    quadro com a coluna 8 já sobre a água da margem."""
    q0 = por(largo(ajoelhado([(1, 6, "s"), (6, 7, "S"), (7, 8, "S")])),
             [(8, 9, "z"), (9, 9, "Z"), (10, 9, "z"), (8, 10, "z"), (9, 10, "z"), (10, 10, "z"),
              (11, 9, "j"), (11, 10, "j"), (7, 8, "S")])
    q1 = por(largo(ajoelhado([(1, 6, "s"), (6, 6, "S"), (7, 7, "S")])),
             [(8, 8, "Z"), (9, 8, "z"), (10, 8, "Z"), (8, 9, "z"), (9, 9, "z"), (10, 9, "Z"),
              (11, 8, "j"), (10, 10, "j"), (11, 10, "w"), (7, 7, "S")])
    q2 = por(largo(ajoelhado([(1, 5, "s"), (6, 4, "S"), (7, 3, "S")], CAB)),
             [(8, 1, "Z"), (8, 2, "z"), (9, 2, "Z"), (8, 3, "z"), (8, 4, "Z"), (9, 4, "z"), (8, 5, "z"),
              (7, 2, "S"), (8, 7, "j"), (9, 9, "j"), (8, 11, "j")])
    q3 = por(largo(ajoelhado([(1, 6, "s"), (6, 6, "S"), (7, 7, "S")])),
             [(8, 8, "z"), (9, 8, "Z"), (10, 8, "z"), (11, 8, "z"), (8, 9, "z"), (9, 9, "z"),
              (9, 6, "j"), (11, 6, "w"), (10, 5, "j"), (11, 10, "j"), (8, 11, "j"), (10, 11, "w")])
    return [q0, q1, q2, q3]


def crianca_banho():
    """Criança na água até a cintura (linha 5 na superfície): joga água para o alto, bate na
    água, mergulha (só o alto da cabeça fora) e volta sacudindo os pingos. Dá para pôr duas
    frente a frente (uma espelhada) a 6 ou 8 px: jogando água uma na outra."""
    q0 = crianca([(0, 4, "s"), (5, 2, "S"), (5, 1, "S")], ["l..L..", "f..F.."])
    q0 = por(na_agua(q0, 5), [(5, 0, "j"), (4, 0, "w"), (3, 0, "j")])
    q1 = crianca([(0, 4, "s"), (4, 4, "S"), (5, 5, "S")], ["l..L..", "f..F.."])
    q1 = por(na_agua(q1, 5), [(5, 3, "j"), (5, 4, "w")])
    cab = crianca([], ["......", "......"])[:4]
    q2 = ["......", "......", "......"] + [l if j < 2 else "".join("a" if ch != "." else "." for ch in l)
                                          for j, l in enumerate(cab)] + ["......"]
    q2 = por(na_agua(q2[:8], 4), [(0, 3, "j"), (5, 2, "j")])
    q3 = crianca([(0, 4, "s"), (4, 3, "S")], ["l..L..", "f..F.."], )
    q3 = por(na_agua(q3, 5), [(5, 1, "j"), (0, 0, "j"), (5, 3, "j")])
    return [q0, q1, q2, q3]


FOLHAS = {
    "pescar_espreitar_forte_2q": pescar_espreitar, "pescar_arpoar_forte_4q": pescar_arpoar,
    "carregar_peixe_forte_4q": carregar_peixe, "lavar_margem_forte_4q": lavar_margem,
    "crianca_banho_4q": crianca_banho,
}


def peixe_na_lanca():
    """Objeto: a lança de 2 px deitada (16 de largura), com o peixe espetado na ponta. Para a
    lança encostada ou no fogo, depois da pesca."""
    g = [["."] * 16 for _ in range(4)]
    for x, y, ch in haste(0, 1, 11, 1, ponta=False) + [(12, 1, "Z"), (12, 2, "z")] + peixe(10, 0):
        g[y][x] = ch
    return m(*["".join(l) for l in g])


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    k.gravar(peixe_na_lanca(), OBJ / "peixe_na_lanca_forte.png")
    # amostra: cada folha numa linha, sobre a água (as da água) ou a grama (a volta)
    W, H = 4 * 16 + 8, len(folhas) * 18 + 14
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    roupas = ((26, 30, 28), (24, 23, 27), (23, 8, 29))
    for j, (nome, qs) in enumerate(folhas.items()):
        y = 2 + j * 18
        crianca_ = len(qs[0]) == 8
        sup_y = y + (5 if crianca_ else 9)
        for x in range(0, W, 8):
            if nome.startswith(("carregar", "lavar")):
                img.alpha_composite(grama, (x, y + 10))
            else:
                img.paste(PALETA[18] + (255,), (x, sup_y, x + 8, y + 18))
                img.paste(PALETA[19] + (255,), (x + 2, sup_y, x + 5, sup_y + 1))
        for i, q in enumerate(qs):
            x0 = 4 + i * 16
            if nome.startswith("lavar"):
                img.paste(PALETA[18] + (255,), (x0 + 8, y + 10, x0 + 16, y + 18))
            img.alpha_composite(para_imagem(trocar(q, k.hab.troca(*roupas[(i + j) % 3]))), (x0, y))
    img.alpha_composite(para_imagem(peixe_na_lanca()), (4, H - 8))
    img.save(AQUI / "amostra_pesca.png")
    img.resize((W * 6, H * 6), Image.NEAREST).save(AQUI / "amostra_pesca_4x.png")
    print("pesca e lavagem:", ", ".join(folhas), "e peixe_na_lanca_forte")


if __name__ == "__main__":
    principal()

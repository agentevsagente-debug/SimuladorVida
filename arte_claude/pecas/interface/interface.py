"""Interface da alça: ícones (12x12 e 8x8), caixas em 9 partes, botões e a fonte em pixel.

A fonte é proporcional, com caixa de 11 linhas: linhas 0-1 para acento de maiúscula,
2-8 para a maiúscula (7 px), 4-8 para a minúscula, 9-10 para as descidas (g, j, p, q, y, ç).
Sai em formato BMFont (.fnt + .png), que o Godot 4 importa direto, em 3 cores da paleta.
"""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, gravar, para_imagem, pont  # noqa: E402

K = {"S": 26, "T": 28, "W": 31, "w": 0, "c": 19, "b": 18, "B": 17, "G": 12, "g": 11, "k": 4, "K": 5, "y": 22, "o": 21,
     "r": 20, "n": 10, "N": 9, "d": 8, "v": 15, "V": 14, "m": 13, "s": 16, "p": 29, "P": 7, "x": 30, "e": 3}


def molde(linhas):
    w = len(linhas[0])
    assert all(len(l) == w for l in linhas), linhas
    return [[None if ch == "." else K[ch] for ch in l] for l in linhas]


# ---------------------------------------------------------------- ícones 12x12

ICONES_12 = {
    "estante": [
        "............",
        ".nnnnnnnnnn.",
        ".nrrbbvvppn.",
        ".nrryyvvyyn.",
        ".nrrbbvvppn.",
        ".nyrbbyvppn.",
        ".nrrbbvvppn.",
        ".NNNNNNNNNN.",
        ".nvvpp...rn.",
        ".nvyp...r.n.",
        ".nvvp..r..n.",
        ".NNNNNNNNNN.",
    ],
    "criar_povo": [
        ".....y......",
        "....yWy.....",
        ".....y......",
        "...dd.......",
        "...SS.......",
        "..TTTT..dd..",
        "..TTTT..SS..",
        "...TT..TTT..",
        "...TT...TT..",
        "...S.S..S.S.",
        "vvvvvvvvvvvv",
        "VVVVVVVVVVVV",
    ],
    "rapido2": [
        "............",
        "............",
        "W...W...W...",
        "WW..WW..WW..",
        "WWW.WWW.WWW.",
        "WWWGWWWGWWWG",
        "WWG.WWG.WWG.",
        "WG..WG..WG..",
        "............",
        "............",
        "............",
        "............",
    ],
    "seca": [
        "...y..y..y..",
        "....yyyyy...",
        "...yyWWWyy..",
        "..yyWWWWWyy.",
        "...yyWWWyy..",
        "....yyyyy...",
        "...y..y..y..",
        "............",
        "nnnnnnnnnnnn",
        "NNxNNNNxNNNN",
        "NxNNNNNNxNNx",
        "dddxddddxddd",
    ],
    "diluvio": [
        "...GWWWG....",
        ".GWWWWWWWG..",
        "GGGGGGGGGGG.",
        ".c.c.c.c.c..",
        "c.c.c.c.c.c.",
        ".b.b.b.b.b..",
        "............",
        "cc..cc..cc..",
        "bbccbbccbbcc",
        "bbbbbbbbbbbb",
        "BBbBBbBBbBBb",
        "BBBBBBBBBBBB",
    ],
    "terremoto": [      # revisão dos 5 minutos: a metade direita do chão sobe, com a racha e o tremor
        "............",
        "W.g.....G..W",
        ".W...G....W.",
        "......vvvvvv",
        "vvvvv.VVVVVV",
        "VVVVVxNNNNNN",
        "NNNNxxNnNNNN",
        "NnNNNxxNNNnN",
        "NNNNxxNNNNNN",
        "NNnNNxNNnNNN",
        "dddddxxddddd",
        "ddddxxdddddd",
    ],
    "pressagio": [
        ".........y..",
        ".WW.........",
        "WWWww.....y.",
        ".Wwwcc......",
        "..wcccc.....",
        "...cccbb....",
        "....cbbb....",
        ".....bbBB...",
        "......bBBB..",
        ".......BB.B.",
        "........B..B",
        "............",
    ],
    "cura": [
        ".........v..",
        "........vWv.",
        ".PP.PP...v..",
        "PWPPPPP.....",
        "PPPPPPP.....",
        ".PPPPP......",
        "..PPP.......",
        "...P....v...",
        "..v....vWv..",
        ".vWv....v...",
        "..v.........",
        "............",
    ],
    "chuva": [
        "............",
        "....GWWG....",
        "..GWWWWWWG..",
        ".GWWWWWWWWG.",
        "GWWWWWWWWWWG",
        "GGGGGGGGGGGG",
        ".gggggggggg.",
        "............",
        "..c...c...c.",
        "..b...b...b.",
        "....c...c...",
        "....b...b...",
    ],
    "raio": [
        ".....yyyyy..",
        "....yWWyy...",
        "...yWWyy....",
        "..yWWyy.....",
        ".yWWWWWWWy..",
        ".yyyyWWWy...",
        "....yWWy....",
        "...yWWy.....",
        "...yWy......",
        "..yWy.......",
        "..yy........",
        ".y..........",
    ],
    "fogo": [
        ".....r......",
        ".....rr.....",
        "....rorr....",
        "...rroor.r..",
        "..rrooorrr..",
        "..roooyoor..",
        ".rrooyyoorr.",
        ".rooyyyyoor.",
        ".royyWWyyor.",
        ".royWWWWyor.",
        "..ryWWWWyr..",
        "...rrrrrr...",
    ],
    "fartura": [
        # feixe de trigo cheio, amarrado no meio, com um brilho: o fiapo de antes sumia em 1x
        "..y...y...W.",
        ".yoy.yoy.WyW",
        ".yoy.yoy..W.",
        "..yoyyoy....",
        "..yoyoyo....",
        "...yoyo.....",
        "....nnn.....",
        "....sns.....",
        "...s.s.s....",
        "..s..s..s...",
        ".s...s...s..",
        "............",
    ],
    "erguer_terra": [
        ".....W......",
        "....WWW.....",
        "...WWWWW....",
        ".....W......",
        ".....W......",
        "....vvv.....",
        "...vVVVv....",
        "..vVNNNVv...",
        ".vVNNdNNVv..",
        "vVNNNNNdNNv.",
        "NNNdNNNNNNdN",
        "dddddddddddd",
    ],
    "sonho": [
        ".........p..",
        "...ppp..pWp.",
        "..pWWp...p..",
        ".pWW........",
        ".pW.........",
        ".pW.....p...",
        ".pW....pWp..",
        ".pWW....p...",
        "..pWWp......",
        "...ppp......",
        "............",
        "............",
    ],
    "pausa": [
        "............",
        "............",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "...WG..WG...",
        "............",
        "............",
    ],
    "normal": [
        "............",
        "............",
        "...W........",
        "...WW.......",
        "...WWW......",
        "...WWWW.....",
        "...WWWWG....",
        "...WWWG.....",
        "...WWG......",
        "...WG.......",
        "............",
        "............",
    ],
    "rapido": [
        "............",
        "............",
        ".W....W.....",
        ".WW...WW....",
        ".WWW..WWW...",
        ".WWWW.WWWW..",
        ".WWWWGWWWWG.",
        ".WWWG.WWWG..",
        ".WWG..WWG...",
        ".WG...WG....",
        "............",
        "............",
    ],
    "salto": [
        "............",
        "............",
        ".W....W..WG.",
        ".WW...WW.WG.",
        ".WWW..WWWWG.",
        ".WWWW.WWWWG.",
        ".WWWWGWWWWG.",
        ".WWWG.WWWWG.",
        ".WWG..WWGWG.",
        ".WG...WG.WG.",
        "............",
        "............",
    ],
    "cronica": [
        "............",
        "............",
        ".GGGG..GGGG.",
        "GWWWWGGWWWWG",
        "GWnnWGGWnnWG",
        "GWWWWGGWWWWG",
        "GWnnnGGWnnWG",
        "GWWWWGGWWWWG",
        "GWnWWGGWnnWG",
        "GGGGGNNGGGGG",
        ".NNNNNNNNNN.",
        "............",
    ],
    "linhagem": [
        "............",
        ".....yy.....",
        "....yWWy....",
        ".....yy.....",
        ".....G......",
        "..GGGGGGG...",
        "..G.....G...",
        ".cc.....pp..",
        "cWWc...pWWp.",
        ".cc.....pp..",
        "............",
        "............",
    ],
    "esconder": [
        "............",
        "............",
        "..WG....WG..",
        "...WG..WG...",
        "....WGWG....",
        ".....WG.....",
        "............",
        "............",
        "..WWWWWWWW..",
        "..GGGGGGGG..",
        "............",
        "............",
    ],
}

ICONES_8 = {
    "estante": ["nnnnnnnn", "nrrbbvpn", "nryybypn", "nrrbbvpn", "NNNNNNNN", "nvvp..rn", "nvyp.r.n", "NNNNNNNN"],
    "criar_povo": ["...y....", "..yWy...", "..dd..d.", "..SS..S.", ".TTTT.TT", "..S.S.S.", "vvvvvvvv", "VVVVVVVV"],
    "rapido2": ["........", "W..W..W.", "WW.WW.WW", "WWGWWGWW", "WG.WG.WG", "........", "........", "........"],
    "seca": [".y.y.y..", "..yyy...", ".yWWWy..", "..yyy...", ".y.y.y..", "nnnnnnnn", "NxNNNxNN", "ddxdddxd"],
    "diluvio": [".GWWWG..", "GGGGGGG.", "c.c.c.c.", ".b.b.b..", "cc..cc..", "bbccbbcc", "bbbbbbbb", "BBBBBBBB"],
    "terremoto": ["W..G...W", ".W.g..W.", "....vvvv", "vvv.VVVV", "VVVxNNNN", "NNxxNnNN", "NnNxxNNN", "dddxdddd"],
    "pressagio": [".WW.....", "WWwc....", ".wcc....", "..cbb...", "...bbB..", "....bBB.", ".....BB.", "......B."],
    "cura": ["......v.", ".PP.PvWv", "PWPPP.v.", "PPPPP...", ".PPP....", "..P.....", "........", "........"],
    "chuva": [
        "..GWWG..",
        ".GWWWWG.",
        "GWWWWWWG",
        ".gggggg.",
        "........",
        "c..c..c.",
        "b..b..b.",
        "..c..c..",
    ],
    "raio": [
        "....yyy.",
        "...yWy..",
        "..yWy...",
        ".yWWWWy.",
        "...yWy..",
        "..yWy...",
        "..yy....",
        ".y......",
    ],
    "fogo": [
        "...r....",
        "...rr...",
        "..roor..",
        ".rooyor.",
        ".royyor.",
        "royWWyor",
        ".ryWWyr.",
        "..rrrr..",
    ],
    "fartura": [
        ".y.y..W.",
        "yoyoy.y.",
        "yoyoy...",
        ".yoy....",
        "..n.....",
        ".sns....",
        "s.s.s...",
        "........",
    ],
    "erguer_terra": [
        "...W....",
        "..WWW...",
        "...W....",
        "..vvv...",
        ".vVVVv..",
        "vVNNNVv.",
        "NNNdNNNN",
        "dddddddd",
    ],
    "sonho": [
        "..ppp...",
        ".pWW..p.",
        "pWW..pWp",
        "pW....p.",
        "pW......",
        "pWW.....",
        ".pWWp...",
        "..ppp...",
    ],
    "pausa": [
        "........",
        ".WG.WG..",
        ".WG.WG..",
        ".WG.WG..",
        ".WG.WG..",
        ".WG.WG..",
        ".WG.WG..",
        "........",
    ],
    "normal": [
        "........",
        ".W......",
        ".WW.....",
        ".WWW....",
        ".WWWG...",
        ".WWG....",
        ".WG.....",
        "........",
    ],
    "rapido": [
        "........",
        "W...W...",
        "WW..WW..",
        "WWW.WWW.",
        "WWWGWWWG",
        "WWG.WWG.",
        "WG..WG..",
        "........",
    ],
    "salto": [
        "........",
        "W..W..WG",
        "WW.WW.WG",
        "WWWWWWWG",
        "WWWGWWWG",
        "WWG.WWWG",
        "WG..WGWG",
        "........",
    ],
    "cronica": [
        "........",
        ".GG..GG.",
        "GWWGGWWG",
        "GnWGGnWG",
        "GWnGGWnG",
        "GWWGGWWG",
        "GGGNNGGG",
        ".NNNNNN.",
    ],
    "linhagem": [
        "...yy...",
        "...WW...",
        "...G....",
        ".GGGGG..",
        ".G...G..",
        "cc...pp.",
        "cW...pW.",
        "........",
    ],
    "esconder": [
        "........",
        ".WG..WG.",
        "..WGWG..",
        "...WG...",
        "........",
        ".WWWWWW.",
        ".GGGGGG.",
        "........",
    ],
}


# ---------------------------------------------------------------- caixas e botões

def caixa_cronica():
    """Pergaminho em 9 partes, 24x24, fatias de 6 px."""
    n = 24
    q = [[None] * n for _ in range(n)]
    for y in range(n):
        for x in range(n):
            canto = min(x, n - 1 - x) + min(y, n - 1 - y)
            borda = min(x, y, n - 1 - x, n - 1 - y)
            if canto == 0:
                continue
            if borda == 0 or canto == 1:
                c = 8
            elif borda == 1:
                c = 10 if (x < n - 2 and y < n - 2 and (x == 1 or y == 1)) else 9
            elif borda == 2:
                c = 31 if (x == 2 or y == 2) and x < n - 3 and y < n - 3 else 12
            else:
                c = 12
                if (x * 7 + y * 3) % 23 == 0:
                    c = 31
            q[y][x] = c
    # tachinhas de canto
    for x, y in ((3, 3), (n - 4, 3), (3, n - 4), (n - 4, n - 4)):
        q[y][x] = 9
    return q


def caixa_dica():
    """Caixa escura da dica do cursor, 12x12, fatias de 4 px."""
    n = 12
    q = [[None] * n for _ in range(n)]
    for y in range(n):
        for x in range(n):
            borda = min(x, y, n - 1 - x, n - 1 - y)
            canto = min(x, n - 1 - x) + min(y, n - 1 - y)
            if canto == 0:
                continue
            if borda == 0:
                c = 5
            elif borda == 1:
                c = 4 if y == 1 else 3
            else:
                c = 3
            q[y][x] = c
    return q


def ponteiro_dica():
    return molde([
        "KeeeeK",
        ".KeeK.",
        "..KK..",
    ])


def alca():
    """Fundo da alça (madeira escura), 12x12, fatias de 4 px."""
    n = 12
    q = [[None] * n for _ in range(n)]
    for y in range(n):
        for x in range(n):
            borda = min(x, y, n - 1 - x, n - 1 - y)
            if borda == 0:
                c = 30
            elif y == 1:
                c = 9
            elif y == n - 2:
                c = 30
            else:
                c = 8 if (x + y // 3) % 7 else 30
            q[y][x] = c
    return q


def botoes():
    """Botão 16x16 em 3 estados: normal, cursor por cima, selecionado. O ícone 12x12
    vai em (2, 2)."""
    estados = []
    for fundo, luz, sombra in ((4, 5, 3), (5, 7, 4), (3, 22, 21)):
        q = [[None] * 16 for _ in range(16)]
        for y in range(16):
            for x in range(16):
                borda = min(x, y, 15 - x, 15 - y)
                canto = min(x, 15 - x) + min(y, 15 - y)
                if canto == 0:
                    continue
                if borda == 0:
                    c = luz if (x == 0 or y == 0) else sombra
                else:
                    c = fundo
                q[y][x] = c
        estados.append(q)
    return estados


# ---------------------------------------------------------------- fonte

CAP = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
}
# minúsculas: (linha do topo, desenho)
MIN = {
    "a": (4, [".###.", "....#", ".####", "#...#", ".####"]),
    "b": (2, ["#....", "#....", "####.", "#...#", "#...#", "#...#", "####."]),
    "c": (4, [".###", "#...", "#...", "#...", ".###"]),
    "d": (2, ["....#", "....#", ".####", "#...#", "#...#", "#...#", ".####"]),
    "e": (4, [".###.", "#...#", "#####", "#....", ".###."]),
    "f": (2, ["..##", ".#..", "####", ".#..", ".#..", ".#..", ".#.."]),
    "g": (4, [".####", "#...#", "#...#", ".####", "....#", "....#", ".###."]),
    "h": (2, ["#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#"]),
    "i": (2, ["#", ".", "#", "#", "#", "#", "#"]),
    "j": (2, ["..#", "...", "..#", "..#", "..#", "..#", "..#", "#.#", ".#."]),
    "k": (2, ["#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#"]),
    "l": (2, ["#.", "#.", "#.", "#.", "#.", "#.", ".#"]),
    "m": (4, ["##.#.", "#.#.#", "#.#.#", "#.#.#", "#...#"]),
    "n": (4, ["####.", "#...#", "#...#", "#...#", "#...#"]),
    "o": (4, [".###.", "#...#", "#...#", "#...#", ".###."]),
    "p": (4, ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."]),
    "q": (4, [".####", "#...#", "#...#", ".####", "....#", "....#", "....#"]),
    "r": (4, ["#.##", "##..", "#...", "#...", "#..."]),
    "s": (4, [".####", "#....", ".###.", "....#", "####."]),
    "t": (2, [".#..", ".#..", "####", ".#..", ".#..", ".#..", "..##"]),
    "u": (4, ["#...#", "#...#", "#...#", "#...#", ".####"]),
    "v": (4, ["#...#", "#...#", "#...#", ".#.#.", "..#.."]),
    "w": (4, ["#...#", "#...#", "#.#.#", "#.#.#", ".#.#."]),
    "x": (4, ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"]),
    "y": (4, ["#...#", "#...#", "#...#", ".####", "....#", "....#", ".###."]),
    "z": (4, ["#####", "...#.", "..#..", ".#...", "#####"]),
    "ı": (4, ["#", "#", "#", "#", "#"]),
}
PONT = {
    " ": (2, ["...", "...", "...", "...", "...", "...", "..."]),
    ".": (8, ["#"]),
    ",": (8, [".#", "#."]),
    ":": (4, ["#", ".", ".", ".", "#"]),
    ";": (4, [".#", "..", "..", "..", ".#", "#."]),
    "!": (2, ["#", "#", "#", "#", "#", ".", "#"]),
    "?": (2, [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."]),
    "-": (5, ["###"]),
    "—": (5, ["#####"]),
    "'": (2, ["#", "#"]),
    '"': (2, ["#.#", "#.#"]),
    "(": (2, [".#", "#.", "#.", "#.", "#.", "#.", ".#"]),
    ")": (2, ["#.", ".#", ".#", ".#", ".#", ".#", "#."]),
    "«": (4, ["..#.#", ".#.#.", "#.#..", ".#.#.", "..#.#"]),
    "»": (4, ["#.#..", ".#.#.", "..#.#", ".#.#.", "#.#.."]),
    "/": (2, ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."]),
    "%": (2, ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"]),
    "+": (4, ["..#..", "..#..", "#####", "..#..", "..#.."]),
    "=": (5, ["####", "....", "####"]),
    "…": (8, ["#.#.#"]),
    "º": (2, [".#.", "#.#", ".#.", "...", "###"]),
    "ª": (2, [".##", "#.#", ".##", "...", "###"]),
}
ACENTOS = {
    "agudo": ["..#", ".#."],
    "grave": ["#..", ".#."],
    "circunflexo": [".#.", "#.#"],
    "til": [".#.#", "#.#."],
    "trema": ["...", "#.#"],
}
COMPOSTOS = {
    "á": ("a", "agudo"), "à": ("a", "grave"), "â": ("a", "circunflexo"), "ã": ("a", "til"),
    "é": ("e", "agudo"), "ê": ("e", "circunflexo"), "í": ("ı", "agudo"), "ó": ("o", "agudo"),
    "ô": ("o", "circunflexo"), "õ": ("o", "til"), "ú": ("u", "agudo"), "ü": ("u", "trema"),
    "Á": ("A", "agudo"), "À": ("A", "grave"), "Â": ("A", "circunflexo"), "Ã": ("A", "til"),
    "É": ("E", "agudo"), "Ê": ("E", "circunflexo"), "Í": ("I", "agudo"), "Ó": ("O", "agudo"),
    "Ô": ("O", "circunflexo"), "Õ": ("O", "til"), "Ú": ("U", "agudo"), "Ü": ("U", "trema"),
}
ALT = 11


def glifo_base(ch):
    if ch in CAP:
        return 2, CAP[ch]
    if ch in MIN:
        return MIN[ch]
    return PONT[ch]


def montar_glifo(ch):
    """Devolve a grade 11 x largura com '#' e '.'."""
    if ch in ("ç", "Ç"):
        topo, desenho = glifo_base("c" if ch == "ç" else "C")
        g = _colocar(topo, desenho)
        larg = len(desenho[0])
        meio = larg // 2
        g[9 if ch == "ç" else 9][meio] = "#"
        g[10][meio - 1] = "#"
        return g
    if ch in COMPOSTOS:
        base, acento = COMPOSTOS[ch]
        topo, desenho = glifo_base(base)
        marca = ACENTOS[acento]
        if base == "ı":
            # o i sem pingo tem 1 px: o acento de 3 px encostava na haste e o "í" lia como
            # "(" (auditoria 3c). Acento de 2 px, uma linha acima, com 1 linha de folga.
            marca = [".#", "#."]
        larg = max(len(desenho[0]), len(marca[0]))
        pad = (larg - len(desenho[0])) // 2
        desenho = ["." * pad + l + "." * (larg - len(l) - pad) for l in desenho]
        g = _colocar(topo, desenho)
        linha = 0 if base.isupper() else 1 if base == "ı" else 2
        ox = (larg - len(marca[0])) // 2
        for j, l in enumerate(marca):
            for i, p in enumerate(l):
                if p == "#":
                    g[linha + j][ox + i] = "#"
        return g
    topo, desenho = glifo_base(ch)
    return _colocar(topo, desenho)


def _colocar(topo, desenho):
    larg = len(desenho[0])
    g = [["."] * larg for _ in range(ALT)]
    for j, l in enumerate(desenho):
        for i, p in enumerate(l):
            g[topo + j][i] = p
    return g


CARACTERES = ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
              " .,:;!?-—'\"()«»/%+=…ºª" + "".join(COMPOSTOS) + "çÇ")


def fonte(cor):
    """Monta a folha da fonte (uma linha de glifos com 1 px de folga) e o .fnt."""
    glifos = [(ch, montar_glifo(ch)) for ch in CARACTERES]
    por_linha = 32
    linhas = [glifos[i:i + por_linha] for i in range(0, len(glifos), por_linha)]
    larg_folha = max(sum(len(g[0]) + 1 for _, g in l) for l in linhas)
    folha = [[None] * larg_folha for _ in range(len(linhas) * (ALT + 1))]
    chars = []
    for li, linha in enumerate(linhas):
        x = 0
        for ch, g in linha:
            w = len(g[0])
            for j in range(ALT):
                for i in range(w):
                    if g[j][i] == "#":
                        folha[li * (ALT + 1) + j][x + i] = cor
            avanco = w + 1 if ch != " " else 3
            chars.append((ord(ch), x, li * (ALT + 1), w, ALT, avanco))
            x += w + 1
    return folha, chars


def fnt(nome, chars, larg, alt):
    linhas = [
        f'info face="Simulador 5x7" size={ALT} bold=0 italic=0 charset="" unicode=1 stretchH=100 '
        f'smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
        f"common lineHeight=12 base=9 scaleW={larg} scaleH={alt} pages=1 packed=0",
        f'page id=0 file="{nome}.png"',
        f"chars count={len(chars)}",
    ]
    for cid, x, y, w, h, av in chars:
        linhas.append(f"char id={cid} x={x} y={y} width={w} height={h} xoffset=0 yoffset=0 "
                      f"xadvance={av} page=0 chnl=15")
    return "\n".join(linhas) + "\n"


def escrever(img, texto, x, y, chars_px, cor_folha):
    """Desenha texto numa imagem RGBA usando a folha da fonte (para a amostra)."""
    mapa = {chr(cid): (cx, cy, w, av) for cid, cx, cy, w, h, av in chars_px}
    for ch in texto:
        cx, cy, w, av = mapa[ch]
        img.alpha_composite(cor_folha.crop((cx, cy, cx + w, cy + ALT)), (x, y))
        x += av
    return x


def nove(q, n, fatia, w, h):
    """Estica uma caixa de 9 partes até w x h (para a amostra; o motor faz o mesmo)."""
    out = [[None] * w for _ in range(h)]
    def origem(v, total):
        if v < fatia:
            return v
        if v >= total - fatia:
            return n - (total - v)
        return fatia + (v - fatia) % (n - 2 * fatia)
    for y in range(h):
        for x in range(w):
            out[y][x] = q[origem(y, h)][origem(x, w)]
    return out


def principal():
    for nome, desenho in ICONES_12.items():
        gravar(molde(desenho), AQUI / "icones_12" / f"{nome}.png")
    for nome, desenho in ICONES_8.items():
        gravar(molde(desenho), AQUI / "icones_8" / f"{nome}.png")
    caixa, dica = caixa_cronica(), caixa_dica()
    gravar(caixa, AQUI / "caixa_cronica_9s.png")
    gravar(dica, AQUI / "caixa_dica_9s.png")
    gravar(ponteiro_dica(), AQUI / "dica_ponteiro.png")
    gravar(alca(), AQUI / "alca_9s.png")
    bts = botoes()
    from comum import folha_quadros
    gravar(folha_quadros(bts), AQUI / "botao_3q.png")
    folhas = {}
    # titulo: vinho escuro (23), para títulos sobre o pergaminho, onde a dourada some
    for nome_cor, cor in (("clara", 31), ("escura", 8), ("dourada", 22), ("titulo", 23)):
        folha, chars = fonte(cor)
        nome = f"fonte_5x7_{nome_cor}"
        folhas[nome_cor] = (gravar(folha, AQUI / f"{nome}.png"), chars)
        (AQUI / f"{nome}.fnt").write_text(fnt(nome, chars, len(folha[0]), len(folha)), encoding="utf-8")
    gravar(amostra(caixa, dica, bts, folhas), AQUI / "amostra_interface.png", ampliar=False)
    img = Image.open(AQUI / "amostra_interface.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_interface_4x.png")
    print("interface:", len(ICONES_12), "ícones 12x12,", len(ICONES_8), "ícones 8x8,",
          len(CARACTERES), "caracteres na fonte")


def amostra(caixa, dica, bts, folhas):
    W, H = 262, 150
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    # alça com os botões dos poderes e do tempo
    barra = para_imagem(nove(alca(), 12, 4, W - 8, 20))
    img.alpha_composite(barra, (4, 4))
    x = 7
    poderes = ["chuva", "raio", "fogo", "fartura", "erguer_terra", "sonho"]
    for i, nome in enumerate(poderes):
        img.alpha_composite(para_imagem(bts[2 if i == 1 else 1 if i == 3 else 0]), (x, 6))
        img.alpha_composite(para_imagem(molde(ICONES_12[nome])), (x + 2, 8))
        x += 17
    x += 6
    for nome in ("pausa", "normal", "rapido", "salto", "cronica", "linhagem", "esconder"):
        img.alpha_composite(para_imagem(bts[0]), (x, 6))
        img.alpha_composite(para_imagem(molde(ICONES_12[nome])), (x + 2, 8))
        x += 17
    # ícones 8x8 numa linha
    x = 6
    for nome in ICONES_8:
        img.alpha_composite(para_imagem(molde(ICONES_8[nome])), (x, 28))
        x += 11
    # caixa da crônica com texto
    clara, escura, dourada, titulo = (folhas[k] for k in ("clara", "escura", "dourada", "titulo"))
    img.alpha_composite(para_imagem(nove(caixa, 24, 6, 166, 72)), (4, 42))
    textos = ["Ano 12 do povo de Ardem", "«Que Rega, que a chuva volte.»",
              "No princípio, a família de Iara", "rezou no altar à noite.", "ÁGUA, PÃO, CORAÇÃO: É VIDA!"]
    for i, t in enumerate(textos):
        f = titulo if i == 0 else escura
        escrever(img, t, 11, 49 + i * 12, f[1], f[0])
    # dica do cursor
    img.alpha_composite(para_imagem(nove(dica, 12, 4, 84, 40)), (174, 42))
    escrever(img, "Iara, 34 anos", 179, 46, dourada[1], dourada[0])
    escrever(img, "devota, teimosa", 179, 58, clara[1], clara[0])
    escrever(img, "reza: chuva", 179, 70, clara[1], clara[0])
    img.alpha_composite(para_imagem(ponteiro_dica()), (212, 82))
    # alfabeto completo
    escrever(img, "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789", 4, 116, clara[1], clara[0])
    escrever(img, "abcdefghijklmnopqrstuvwxyz .,:;!?-()«»", 4, 127, clara[1], clara[0])
    escrever(img, "áàâãéêíóôõúü ÁÀÂÃÉÊÍÓÔÕÚÜ çÇ %+=/…ºª", 4, 138, clara[1], clara[0])
    return img


if __name__ == "__main__":
    principal()

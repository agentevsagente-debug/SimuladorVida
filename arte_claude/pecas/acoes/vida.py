"""Vida dos habitantes: microanimações de quem está parado, vida social e ações com objetos
de cena. Mesmo padrão de `acoes.py` (8x12, criança 6x8, cores-base de `trocas.json`).
Os objetos soltos (mortalha, bandeirolas, tambor, estandartes...) vão em `objetos/`.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA, PERNAS, TRONCO, quadro  # noqa: E402

OBJ = AQUI.parent / "objetos"

CAB_FRENTE = ["..hhhh..", ".hHHHHh.", ".heSSeh.", "..sSSs.."]
CAB_ESQ = [l[::-1] for l in CAB]
CAB_BOCA = ["..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSxS."]      # boca aberta
CAB_B = ["..hhhh..", ".hHHhhh.", ".hhhSeS.", ".hhsSSS."]
TRONCO_B = [".hTTTT..", ".hTbbT..", "..TTTT..", "..TTTT..", ".TTTTTT."]
PERNAS_B = {"parado": ["...lL...", "...lL...", "..ffFF.."], "passo_a": ["..l..L..", ".l....L.", "ff....FF"],
            "meio_a": ["...lL...", "...lL...", "...fFF.."], "passo_b": ["..L..l..", ".L....l.", "FF....ff"],
            "meio_b": ["...Ll...", "...Ll...", "..FFf..."]}
BRACOS = [(1, 5, "s"), (1, 6, "s"), (1, 7, "s"), (6, 5, "S"), (6, 6, "S"), (7, 7, "S")]
ANDAR = (("passo_a", 1), ("meio_a", 0), ("passo_b", 1), ("meio_b", 0))


def andar(pontos, cab=CAB, tronco=TRONCO):
    return [quadro(pontos, cab, tronco, pernas=p, desce=d) for p, d in ANDAR]


def adulto_b(pontos, pernas="parado", desce=0):
    """Quadro do adulto B (cabelo longo e vestido)."""
    g = [list("........") for _ in range(12)]
    partes = CAB_B + TRONCO_B + PERNAS_B[pernas]
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


# ---------------------------------------------------------------- 1. microanimações

def olhar_lados():
    return [quadro(BRACOS), quadro(BRACOS, CAB_FRENTE), quadro(BRACOS, CAB_ESQ), quadro(BRACOS, CAB_FRENTE)]


def esticar():
    return [
        quadro(BRACOS),
        quadro([(1, 4, "s"), (1, 3, "s"), (6, 4, "S"), (6, 3, "S")]),
        quadro([(1, 2, "s"), (1, 1, "s"), (0, 0, "s"), (6, 2, "S"), (6, 1, "S"), (7, 0, "S")], pernas="parado"),
        quadro([(1, 4, "s"), (1, 3, "s"), (6, 4, "S"), (6, 3, "S")]),
    ]


SENTADO = ["..llLL..", ".fllLLF."]


def sentado(desce, pontos=(), cab=CAB):
    g = quadro(pontos, cab, TRONCO, pernas="nada", desce=desce)
    g = [list(l) for l in g]
    for j, l in enumerate(SENTADO):
        for x, ch in enumerate(l):
            if ch != ".":
                g[10 + j][x] = ch
    return ["".join(l) for l in g]


def sentar_chao():
    """Quadros 0 e 1: sentando. Quadros 2 e 3: sentado de pernas cruzadas, respirando."""
    return [quadro(BRACOS, pernas="dobrado", desce=1),
            sentado(2, [(1, 7, "s"), (6, 8, "S")]),
            sentado(3, [(1, 8, "s"), (6, 9, "S")]),
            sentado(2, [(1, 7, "s"), (6, 8, "S")])]


def agachar():
    return [quadro([(1, 7, "s"), (6, 8, "S"), (7, 9, "S")], CAB_BAIXA, pernas="dobrado", desce=2),
            quadro([(1, 7, "s"), (6, 9, "S"), (7, 10, "S")], CAB_BAIXA, pernas="dobrado", desce=2)]


def cocar_cabeca():
    mao = [[(6, 4, "S"), (6, 3, "S"), (5, 1, "S")], [(6, 4, "S"), (6, 3, "S"), (6, 1, "S")]]
    return [quadro(BRACOS), quadro([(1, 5, "s"), (1, 6, "s")] + mao[0]), quadro([(1, 5, "s"), (1, 6, "s")] + mao[1]),
            quadro([(1, 5, "s"), (1, 6, "s")] + mao[0])]


def bocejar():
    return [quadro(BRACOS), quadro([(1, 4, "s"), (6, 4, "S"), (7, 3, "S")], CAB_BOCA),
            quadro([(1, 3, "s"), (0, 2, "s"), (6, 3, "S"), (7, 2, "S")], CAB_BOCA), quadro(BRACOS)]


def dormir():
    """Deitado de lado (12x12, a pessoa ocupa as linhas 8 a 11); 2 quadros de respiração."""
    q0 = ["............"] * 8 + [
        "..hhh.......",
        ".hHhSTTTbll.",
        ".hhSsTTTbllf",
        "nnnnnnnnnnnn",
    ]
    q1 = ["............"] * 8 + [
        "..hhh.TT....",
        ".hHhSTTTbll.",
        ".hhSsTTTbllf",
        "nnnnnnnnnnnn",
    ]
    return [q0, q1]


# ---------------------------------------------------------------- 2. vida social

def conversar_falar():
    gestos = [[(6, 5, "S"), (7, 4, "S")], [(6, 5, "S"), (7, 5, "S")], [(6, 4, "S"), (7, 3, "S")],
              [(6, 5, "S"), (6, 6, "S")]]
    cabs = [CAB_BOCA, CAB, CAB_BOCA, CAB]
    return [quadro([(1, 5, "s"), (1, 6, "s"), (1, 7, "s")] + g, c) for g, c in zip(gestos, cabs)]


def conversar_ouvir():
    cruzados = [(1, 5, "s"), (2, 6, "s"), (3, 6, "s"), (6, 5, "S"), (5, 6, "S"), (4, 6, "S")]
    return [quadro(cruzados), quadro(cruzados, desce=1), quadro(cruzados), quadro(cruzados, CAB_BAIXA)]


BEBE = [(4, 5, "G"), (5, 5, "w"), (6, 5, "w"), (5, 4, "S"), (4, 6, "S"), (6, 6, "S"), (7, 5, "G")]


def mae_bebe_parado():
    return [adulto_b(BEBE + [(1, 6, "s")]), adulto_b([(x, y + 1, c) for x, y, c in BEBE] + [(1, 7, "s")], desce=1)]


def mae_bebe_andar():
    return [adulto_b([(x, y + d, c) for x, y, c in BEBE] + [(1, 6 + d, "s")], pernas=p, desce=d) for p, d in ANDAR]


def crianca(pontos, pernas):
    g = [list(l) for l in [".hhh..", "hHhSS.", "hhSeS.", ".sSS..", ".TTT..", ".TbT..", "......", "......"]]
    for j, l in enumerate(pernas):
        for x, ch in enumerate(l):
            if ch != ".":
                g[6 + j][x] = ch
    for x, y, ch in pontos:
        if 0 <= x < 6 and 0 <= y < 8:
            g[y][x] = ch
    return ["".join(l) for l in g]


def crianca_correr():
    return [crianca([(0, 4, "s"), (4, 3, "S")], ["l...L.", "f....F"]),
            crianca([(0, 5, "s"), (4, 4, "S")], [".lL...", ".fF..."]),
            crianca([(4, 5, "S"), (0, 3, "s")], [".L..l.", "F...f."]),
            crianca([(0, 5, "s"), (4, 4, "S")], ["..Ll..", "..Ff.."])]


def crianca_pular():
    """Agacha, sobe com as pernas encolhidas, abre as pernas no alto e pousa. Quem sobe e
    desce é o motor (2 a 4 px nos quadros 1 e 2); o quadro não sai do lugar."""
    agachada = ["......", ".hhh..", "hHhSS.", "hhSeS.", ".sSS..", "sTTTS.", ".TbT..", ".ffF.."]
    return [agachada,
            crianca([(0, 3, "s"), (4, 3, "S")], [".lL...", "......"]),
            crianca([(0, 3, "s"), (4, 3, "S")], ["l...L.", "f...F."]),
            agachada]


def casal_esquerda():
    """Quem vai à esquerda no casal: a mão da frente (coluna 7) segura a do par."""
    return andar([(1, 5, "s"), (1, 6, "s"), (6, 6, "S"), (7, 7, "S")])


def casal_direita():
    """Quem vai à direita: o par é o adulto B, e a mão de trás (coluna 0) segura."""
    return [adulto_b([(1, 6, "s"), (0, 7, "s"), (6, 5, "S"), (6, 6, "S")], pernas=p, desce=d) for p, d in ANDAR]


def idoso_parado():
    """Velho de bengala parado: apoiado, respirando (o corpo desce 1 px no quadro 2)."""
    import habitantes as hab
    q = hab.IDOSO[0]
    return [q, ["........"] + q[:-3] + q[-2:]]


# ---------------------------------------------------------------- 3. ações com objetos

def funeral_carregar():
    """Carregador do funeral: as duas mãos erguidas no ombro (linha 3), segurando a
    mortalha (`objetos/corpo_mortalha`) que passa por cima. Use 2 carregadores, um atrás
    do outro, a 10 px de distância."""
    maos = [(1, 4, "s"), (1, 3, "s"), (6, 4, "S"), (6, 3, "S")]
    return [quadro(maos, CAB_BAIXA, pernas=p, desce=1) for p, _ in ANDAR]


def tocar_tambor():
    tambor = [(4, 8, "M"), (5, 8, "M"), (6, 8, "M"), (7, 8, "m"), (4, 9, "q"), (5, 9, "m"), (6, 9, "q"), (7, 9, "m"),
              (4, 7, "w"), (5, 7, "w"), (6, 7, "w"), (7, 7, "w")]
    batidas = [[(5, 5, "S"), (6, 5, "S")], [(5, 6, "S"), (5, 7, "S")], [(6, 5, "S"), (7, 5, "S")],
               [(6, 6, "S"), (7, 7, "S")]]
    return [quadro(tambor + [(1, 5, "s"), (1, 6, "s")] + b) for b in batidas]


def andar_trouxa():
    trouxa = [(0, 3, "n"), (1, 3, "N"), (0, 4, "N"), (1, 4, "n"), (0, 5, "n"), (1, 5, "N"), (0, 6, "o"), (1, 6, "o"),
              (2, 4, "o"), (3, 4, "o")]
    return andar(trouxa + [(6, 5, "S"), (6, 6, "S"), (7, 7, "S")], CAB_BAIXA)


def andar_cesto():
    cesto = [(0, 3, "N"), (1, 3, "N"), (0, 4, "n"), (1, 4, "o"), (0, 5, "o"), (1, 5, "n"), (0, 6, "n"), (1, 6, "o"),
             (0, 2, "v"), (1, 2, "y"), (2, 4, "o")]
    return andar(cesto + [(6, 5, "S"), (6, 6, "S"), (7, 7, "S")])


def carregar_cesto():
    cesto = [(5, 6, "N"), (6, 6, "N"), (7, 6, "N"), (5, 7, "o"), (6, 7, "n"), (7, 7, "o"), (6, 5, "k"), (7, 5, "y")]
    return andar(cesto + [(1, 5, "s"), (1, 6, "s"), (4, 6, "S")])


def segurar_peixe():
    peixe = [(7, 6, "g"), (7, 7, "G"), (7, 8, "g"), (6, 8, "w")]
    return [quadro([(1, 5, "s"), (1, 6, "s"), (1, 7, "s"), (6, 5, "S"), (6, 6, "S")] + peixe),
            quadro([(1, 5, "s"), (1, 6, "s"), (1, 7, "s"), (6, 5, "S"), (6, 6, "S")] + peixe, desce=1)]


def carregar_estandarte(cultura):
    """Andando com o estandarte da cultura (quadro 12x12: o pano usa as colunas 8-11)."""
    pano, simb = {"sol": ("T", "y"), "lua": ("T", "w"), "arvore": ("T", "v")}[cultura]
    quadros = []
    for p, d in ANDAR:
        g = [list(l + "....") for l in quadro([(1, 5, "s"), (1, 6, "s"), (6, 5, "S"), (6, 6, "S")], pernas=p, desce=d)]
        for y in range(0, 12):
            g[y][7] = "c" if g[y][7] == "." else g[y][7]
        for y in range(0, 5):
            for x in range(8, 12):
                g[y][x] = pano if not (y == 4 and x in (9, 11)) else "."
        g[2][9] = simb
        g[1][9] = simb if cultura == "sol" else g[1][9]
        g[2][10] = simb
        g[0][7] = "Z"
        quadros.append(["".join(l) for l in g])
    return quadros


# ---------------------------------------------------------------- objetos

def objetos():
    m = lambda *ls: [[None if ch == "." else k.CORES[ch] for ch in l] for l in ls]  # noqa: E731
    out = {
        "corpo_mortalha": m("..wwwwwwwwwwww..", ".wwZwwwwwZwwwwG.", ".ZZZZZZZZZZZZZZ.", "..d..........d.."),
        "bebe_enrolado": m(".SS...", "SeSww.", ".wwwwZ", "..ZZZ."),
        "tambor": m("..wwww..", ".wwwwww.", ".MmMmMm.", ".mqmqmq.", ".MmMmMm.", ".mqmqmq.", "..qqqq..", "........"),
        "coroa_flores": m("..vkvy..", ".v....v.", "y......k", "v......v", "k......y", ".v....v.", "..vyvk..", "........"),
        "coroa_flores_cabeca": m("vkvyvk", "........"[:6]),
        "trouxa": m("...NN...", "..NnnN..", ".NnnNnN.", ".nNnnNn.", ".NnoonN.", "..nnnn..", "........", "........"),
        "cesto_costas": m(".v.y.k..", "NNNNNN..", "NnonnoN.", "NonnonN.", "NnonnoN.", ".NNNNN..", "........", "........"),
        "cesto_cheio": m("..y.kv..", ".kyvyky.", "NNNNNNNN", "NonnonnN", "NnonnonN", ".NNNNNN.", "........", "........"),
        "peixe_mao": m("gGGw", ".gg."),
        "feixe_lenha": m("........", "dnonond.", "dononod.", "dnonond.", "..o..o..", "........", "........", "........"),
    }
    # bandeirolas: trecho de 16x8 que repete na horizontal
    b = [[None] * 16 for _ in range(8)]
    for x in range(16):
        b[1 + (abs(8 - x) // 4 == 0)][x] = 9
    for i, cor in enumerate((27, 22, 28, 29)):
        x0 = i * 4
        for j in range(4):
            for xx in range(x0 + j // 2, x0 + 3 - j // 2):
                b[2 + j][xx] = cor
    out["bandeirolas"] = b
    # estandartes e escudos das 3 culturas (pano na cor da roupa do povo de exemplo)
    for cult, pano, simb in (("sol", 28, 22), ("lua", 29, 31), ("arvore", 27, 15)):
        e = [[None] * 8 for _ in range(24)]
        for y in range(1, 24):
            e[y][1] = 9 if y < 23 else 8
        e[0][1] = 12
        for y in range(2, 11):
            for x in range(2, 8):
                if y == 10 and x in (3, 5, 7):
                    continue
                e[y][x] = pano
        for dx, dy in ((4, 5), (5, 5), (4, 6), (5, 6), (4, 4), (5, 7)):
            e[dy][dx] = simb
        out[f"estandarte_{cult}"] = e
        s = [[None] * 8 for _ in range(8)]
        for y in range(8):
            for x in range(8):
                d = ((x - 3.5) ** 2 + (y - 3.5) ** 2) ** 0.5
                if d <= 3.6:
                    s[y][x] = 9 if d > 2.7 else pano
        for dx, dy in ((3, 3), (4, 3), (3, 4), (4, 4)):
            s[dy][dx] = simb
        s[2][2] = 12
        out[f"escudo_{cult}"] = s
    return out


FOLHAS = {
    "olhar_lados_4q": olhar_lados, "esticar_4q": esticar, "sentar_chao_4q": sentar_chao, "agachar_2q": agachar,
    "cocar_cabeca_4q": cocar_cabeca, "bocejar_4q": bocejar, "dormir_2q": dormir,
    "conversar_falar_4q": conversar_falar, "conversar_ouvir_4q": conversar_ouvir,
    "mae_bebe_parado_2q": mae_bebe_parado, "mae_bebe_andar_4q": mae_bebe_andar,
    "idoso_parado_2q": idoso_parado, "crianca_correr_4q": crianca_correr, "crianca_pular_4q": crianca_pular,
    "casal_esquerda_andar_4q": casal_esquerda, "casal_direita_andar_4q": casal_direita,
    "funeral_carregar_4q": funeral_carregar, "tocar_tambor_4q": tocar_tambor,
    "andar_trouxa_4q": andar_trouxa, "andar_cesto_4q": andar_cesto, "carregar_cesto_4q": carregar_cesto,
    "segurar_peixe_2q": segurar_peixe,
    "carregar_estandarte_sol_4q": lambda: carregar_estandarte("sol"),
    "carregar_estandarte_lua_4q": lambda: carregar_estandarte("lua"),
    "carregar_estandarte_arvore_4q": lambda: carregar_estandarte("arvore"),
}


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    folhas = {n: k.pintar(f()) for n, f in FOLHAS.items()}
    for nome, qs in folhas.items():
        k.gravar(k.folha_quadros(qs), AQUI / f"{nome}.png")
    objs = objetos()
    for nome, px in objs.items():
        k.gravar(px, OBJ / f"{nome}.png")
    # amostra das folhas
    W = 4 * 14 + 8
    img = Image.new("RGBA", (W * 2 + 4, (len(folhas) + 1) // 2 * 20 + 4), PALETA[1] + (255,))
    grama = Image.open(AQUI.parent / "terreno" / "grama_a.png")
    for j, (nome, qs) in enumerate(folhas.items()):
        cx, cy = (j % 2) * (W + 4), 2 + (j // 2) * 20
        for x in range(cx, cx + W, 8):
            img.alpha_composite(grama, (x, cy + 10))
        for i, q in enumerate(qs):
            pele, cab, roupa = ((26, 30, 28), (24, 23, 27), (23, 8, 29))[j % 3]
            img.alpha_composite(para_imagem(trocar(q, k.hab.troca(pele, cab, roupa))),
                                (cx + 4 + i * 14, cy + 12 - len(q)))
    img.save(AQUI / "amostra_vida.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_vida_4x.png")
    k.amostra_pecas(list(objs.items()), 4 + sum(len(p[0]) + 4 for p in objs.values()),
                    saida=OBJ / "amostra_objetos.png")
    print("vida:", len(folhas), "folhas,", len(objs), "objetos")


if __name__ == "__main__":
    principal()

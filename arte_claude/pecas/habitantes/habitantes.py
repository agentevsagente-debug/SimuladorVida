"""Habitantes em folhas horizontais de quadros, olhando para a direita.

Cores-base, que o motor troca por tabela (veja `trocas.json`):
- pele 26 (sombra 25); cabelo 30 (brilho 8), idoso com cabelo 12 (brilho 31);
- roupa 28, só do grupo "tecidos". A roupa não tem tom de sombra: a forma vem da
  tira e do cinto de couro (9), dos braços e da silhueta;
- olho 3, pés 10/9 e couro 9/10 não entram nas trocas.
"""
from pathlib import Path
import json
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import folha_quadros, gravar, trocar  # noqa: E402

PELE, PELE_S = 26, 25
CABELO, CABELO_L = 30, 8
TECIDO = 28
CORES = {
    "h": CABELO, "H": CABELO_L, "S": PELE, "s": PELE_S, "L": PELE, "l": PELE_S,
    "e": 3, "T": TECIDO, "b": 9, "B": 10, "F": 10, "f": 9, "c": 9, "C": 10, "k": 20, "K": 22,
    "g": 12, "G": 31,
}

CABECA_A = ["..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS."]
CABECA_B = ["..hhhh..", ".hHHhhh.", ".hhhSeS.", ".hhsSSS."]

# braços: N neutros, F braço da frente para trás, R braço da frente para a frente
TRONCO_A = {
    "N": ["..TTTb..", ".sTTbTS.", ".sTbTTS.", ".s.TTT.S", "..bbbb.."],
    "F": ["..TTTb..", "..STbTs.", ".STbTT.s", ".S.TTT.s", "..bbbb.."],
    "R": ["..TTTb..", ".sTTbTS.", "s.TbTTS.", "s..TTT.S", "..bbbb.."],
}
TRONCO_B = {
    "N": [".hTTTT..", ".hTbbTS.", "..TTTTS.", "..TTTT.S", ".TTTTTT."],
    "F": [".hTTTT..", ".hSbbTs.", ".STTTT.s", ".STTTT.s", ".TTTTTT."],
    "R": [".hTTTT..", ".hTbbTS.", "s.TTTTS.", "s.TTTT.S", ".TTTTTT."],
}
PERNAS = {
    "parado": ["..l..L..", "..l..L..", ".ff..FF."],
    "passo_a": ["..l..L..", ".l....L.", "ff....FF"],
    "meio_a": ["...lL...", "...lL...", "...fFF.."],
    "passo_b": ["..L..l..", ".L....l.", "FF....ff"],
    "meio_b": ["...Ll...", "...Ll...", "..FFf..."],
}
PERNAS_B = {
    "parado": ["...lL...", "...lL...", "..ffFF.."],
    "passo_a": ["..l..L..", ".l....L.", "ff....FF"],
    "meio_a": ["...lL...", "...lL...", "...fFF.."],
    "passo_b": ["..L..l..", ".L....l.", "FF....ff"],
    "meio_b": ["...Ll...", "...Ll...", "..FFf..."],
}


def adulto(cabeca, tronco, pernas, abaixar=False):
    linhas = cabeca + tronco + pernas
    if abaixar:      # corpo desce 1 px: some uma linha de perna e entra uma linha vazia no alto
        linhas = ["........"] + cabeca + tronco + pernas[1:]
    assert len(linhas) == 12, len(linhas)
    return linhas


def parado(cab, tro, per):
    return [adulto(cab, tro["N"], per["parado"]), adulto(cab, tro["N"], per["parado"], abaixar=True)]


def andando(cab, tro, per):
    return [
        adulto(cab, tro["F"], per["passo_a"], abaixar=True),
        adulto(cab, tro["N"], per["meio_a"]),
        adulto(cab, tro["R"], per["passo_b"], abaixar=True),
        adulto(cab, tro["N"], per["meio_b"]),
    ]


CRIANCA_CAB = [".hhh..", "hHhSS.", "hhSeS.", ".sSS.."]
CRIANCA = [
    CRIANCA_CAB + [".TTTS.", "sTbT..", ".l..L.", "f...F."],
    CRIANCA_CAB + ["sTTTS.", ".TbT..", "..lL..", "..fF.."],
    CRIANCA_CAB + ["sTTT.S", ".TbT..", ".L..l.", "F...f."],
    CRIANCA_CAB + ["sTTTS.", ".TbT..", "..Ll..", "..Ff.."],
]

IDOSO_CAB = ["........", "...gggg.", "..gGGgg.", "..ggggSe", "...gsSSS"]
IDOSO = [
    IDOSO_CAB + [".TTTTSSc", "TTTbTT.c", ".TTTbT.c", "..bbbb.c", "..l..L.c", ".ff..FFc"],
    IDOSO_CAB + [".TTTTSSc", "TTTbTT.c", ".TTTbT.c", "..bbbb.c", "...lL..c", "...fFF.c"],
    IDOSO_CAB + [".TTTTS.c", "TTTbTTSc", ".TTTbT.c", "..bbbb.c", "..L.l..c", ".FF.ff.c"],
    IDOSO_CAB + [".TTTTSSc", "TTTbTT.c", ".TTTbT.c", "..bbbb.c", "...Ll..c", "..FFf..c"],
]

REZAR = [
    ["....s.S.", "..hhhhS.", ".hHHhhS.", ".hhhSeS.", "..hsSSs.", "..TTTTs.",
     ".sTTbT..", ".sTbTT..", "..bbbb..", "..lLL...", "..lLL...", "fflllL.."],
    ["........", "........", "........", "...hhhh.", "..hHHhhh", "..hhhhSe",
     "..TThsSS", ".TTbTTS.", ".TbTTTS.", "..bbbbSS", "..lLL...", "fflllL.."],
]

COLHER = [
    adulto(CABECA_A, TRONCO_A["N"], PERNAS["parado"]),
    ["........", "........", "...hhhh.", "..hHHhhh", "..hhhhSe", ".TTThsSS",
     "TTbTTT.S", ".TTbTT..", "..bbbb.S", "..l..L..", "..l..L..", ".ff..FF."],
    ["........", "........", "........", "........", "..hhhh..", ".hHHhhh.",
     ".hhhhSeS", "TTTThsS.", "TbTTTTS.", "bbbbLLS.", ".lllLLLS", "fflllLFk"],
    ["........", "..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS.", "..TTTTkK",
     ".sTTbTSk", ".sTbTT..", ".s.TTT..", "..bbbb..", "..l..L..", ".ff..FF."],
]

SENTADO = [["........", "........", "..hhhh..", ".hHHhhh.", ".hhhSeS.", "..hsSSS.",
            "..TTTT..", ".sTTbTS.", ".sTbTTS.", ".sbbbSSS", "..llLLLS", ".CCCCCCF"]]


# o idoso tem as pernas com uma linha a mais (a perna repete a linha de cima)
IDOSO = [q[:-1] + [q[-2]] + q[-1:] for q in IDOSO]


def pintar(moldes):
    quadros = []
    for m in moldes:
        larg = len(m[0])
        assert all(len(l) == larg for l in m), m
        quadros.append([[None if ch == "." else CORES[ch] for ch in linha] for linha in m])
    return quadros


PELES = [26, 25, 24, 23]
SOMBRA_PELE = {26: 25, 25: 24, 24: 23, 23: 8}
CABELOS = [30, 8, 23, 10, 12]
LUZ_CABELO = {30: 8, 8: 9, 23: 24, 10: 16, 12: 31}
TECIDOS = [28, 27, 29]


def troca(pele=PELE, cabelo=CABELO, tecido=TECIDO):
    """Tabela de troca a partir das cores-base. Pele e cabelo trocam em par (cor e tom)."""
    return {PELE: pele, PELE_S: SOMBRA_PELE[pele], CABELO: cabelo, CABELO_L: LUZ_CABELO[cabelo],
            TECIDO: tecido}


def folhas():
    return {
        "adulto_a_parado_2q": pintar(parado(CABECA_A, TRONCO_A, PERNAS)),
        "adulto_a_andar_4q": pintar(andando(CABECA_A, TRONCO_A, PERNAS)),
        "adulto_b_parado_2q": pintar(parado(CABECA_B, TRONCO_B, PERNAS_B)),
        "adulto_b_andar_4q": pintar(andando(CABECA_B, TRONCO_B, PERNAS_B)),
        "crianca_andar_4q": pintar(CRIANCA),
        "idoso_andar_4q": pintar(IDOSO),
        "adulto_a_rezar_2q": pintar(REZAR),
        "adulto_a_colher_4q": pintar(COLHER),
        "adulto_a_sentado_1q": pintar(SENTADO),
    }


def principal():
    fs = folhas()
    for nome, quadros in fs.items():
        gravar(folha_quadros(quadros), AQUI / f"{nome}.png")
    # folha de variações: linhas = 4 peles, colunas = 3 roupas x (A, B, criança), mais cabelos
    celulas = []
    for pele in PELES:
        linha = []
        for k, tecido in enumerate(TECIDOS):
            cab = CABELOS[(PELES.index(pele) + k) % 4]
            mapa = troca(pele, cab, tecido)
            linha += [trocar(fs["adulto_a_parado_2q"][0], mapa), trocar(fs["adulto_b_parado_2q"][0], mapa),
                      _pad(trocar(fs["crianca_andar_4q"][1], mapa))]
        celulas.append(linha)
    celulas.append([trocar(fs["adulto_a_parado_2q"][0], troca(cabelo=c)) for c in CABELOS]
                   + [_pad(q) for q in fs["idoso_andar_4q"][:1]])
    gravar(_grade(celulas), AQUI / "variacoes_pele_roupa.png")
    (AQUI / "trocas.json").write_text(json.dumps({
        "cores_base": {"pele": PELE, "pele_sombra": PELE_S, "cabelo": CABELO, "cabelo_brilho": CABELO_L,
                       "roupa": TECIDO, "idoso_cabelo": 12, "idoso_cabelo_brilho": 31},
        "peles": {str(p): {"pele": p, "pele_sombra": SOMBRA_PELE[p]} for p in PELES},
        "cabelos": {str(c): {"cabelo": c, "cabelo_brilho": LUZ_CABELO[c]} for c in CABELOS},
        "roupas": TECIDOS,
        "nota": "índices da paleta arte/paleta/paleta.hex (0 a 31); trocar todos ao mesmo tempo",
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print("habitantes:", ", ".join(f"{n} ({len(q)}q)" for n, q in fs.items()))


def _pad(q, w=8, h=12):
    out = [[None] * w for _ in range(h)]
    for y, linha in enumerate(q):
        for x, c in enumerate(linha):
            out[h - len(q) + y][x + (w - len(linha)) // 2] = c
    return out


def _grade(celulas, passo_x=10, passo_y=14):
    cols = max(len(l) for l in celulas)
    out = [[None] * (cols * passo_x + 2) for _ in range(len(celulas) * passo_y + 2)]
    for j, linha in enumerate(celulas):
        for i, q in enumerate(linha):
            for y, row in enumerate(q):
                for x, c in enumerate(row):
                    out[j * passo_y + 1 + y][i * passo_x + 1 + x] = c
    return out


if __name__ == "__main__":
    principal()

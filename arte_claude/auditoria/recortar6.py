"""Recortes da auditoria 6 a partir das capturas de `capturar6.sh`.
Uso: python arte_claude/auditoria/recortar6.py <pasta das capturas>"""
from pathlib import Path
import sys

from PIL import Image

D = Path(sys.argv[1])
R = Path(__file__).resolve().parent / "recortes6"
R.mkdir(exist_ok=True)


def q(nome, i):
    return Image.open(D / f"{nome}_{i:02d}.png").convert("RGB")


def folha(saida, quadros, caixa, cols, esc):
    w, h = caixa[2] - caixa[0], caixa[3] - caixa[1]
    linhas = (len(quadros) + cols - 1) // cols
    f = Image.new("RGB", (cols * w + (cols - 1), linhas * h + (linhas - 1)), (25, 40, 63))
    for k, (nome, i) in enumerate(quadros):
        f.paste(q(nome, i).crop(caixa), ((k % cols) * (w + 1), (k // cols) * (h + 1)))
    f.resize((f.width * esc, f.height * esc), Image.NEAREST).save(R / f"{saida}.png")


# a caçada que erra (12 dias): espreita, mira com a lança erguida, arremesso e a lança cravada no chão
folha("ok_espreita_mira_arremesso_12dias", [("cacada_longa", i) for i in range(178, 194)], (185, 98, 265, 124), 4, 4)
# a caçada que acerta (13 dias): a lança no ar, o porco abatido, a volta e o espeto
folha("ok_lanca_no_ar_abate_volta_espeto_13dias", [("cacada13_longa", i) for i in (182, 185, 188, 201, 212, 226)],
      (185, 96, 275, 126), 3, 4)
# H1: um carregador segura o pau vazio na cabeça, e o porco fica no chão com outro pau
folha("H1_pau_vazio_na_cabeca", [("cacada13_longa", i) for i in (191, 195, 197)], (190, 100, 250, 124), 3, 6)
# H2: os caçadores se amontoam e alguém fica parado ao lado do porco durante a espreita
folha("H2_cacadores_amontoados", [("cacada_longa", i) for i in (172, 178, 182)], (185, 98, 255, 124), 3, 6)
# a tarde antes da caçada (12h a 15h30), em 1x
folha("tarde_antes_da_cacada", [("cacada_longa", i) for i in (10, 40, 70, 100, 130)] + [("longa_tarde", 20)],
      (100, 60, 480, 130), 2, 2)
# T4: pássaro pousado na ponta da cabana, quase invisível; coelho na borda
folha("T4_passaro_pousado_e_coelho", [("longa_tarde", i) for i in (36, 40, 44)] + [("cacada13_longa", 205)],
      (150, 95, 300, 125), 2, 3)
# a dica: em 1x, como o jogador vê
Image.open(D / "dica_15h_5.png").crop((40, 30, 280, 130)).save(R / "ok_dica_em_1x.png")
f = Image.new("RGB", (960, 480))
for k, n in enumerate(["dica_9h_2", "dica_9h_5", "dica_15h_9", "dica_15h_12", "dica_19h_5", "dica_19h_9"]):
    f.paste(Image.open(D / f"{n}.png").convert("RGB"), ((k % 2) * 480, (k // 2) * 160))
f.resize((1920, 960), Image.NEAREST).save(R / "dica_tres_horas.png")
# D1: brincando na praia e pensando em ir à praia amanhã (o mesmo pensamento por 1 min)
folha("D1_pensamento_contradiz_o_que_faz", [("dica_seguida", i) for i in (0, 19)], (40, 30, 280, 130), 2, 2)
# o dia em 50x
folha("dia_em_50x", [("d50x", i) for i in range(2, 48, 4)], (0, 0, 480, 160), 3, 1)
print("recortes em", R)

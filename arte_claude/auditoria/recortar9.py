"""Recortes da auditoria 9 a partir de `capturas9/` (e de `capturas7/`, para comparar).
Uso: python arte_claude/auditoria/recortar9.py"""
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
D = AQUI / "capturas9"
R = AQUI / "recortes9"
R.mkdir(exist_ok=True)


def folha(saida, nomes, caixa, cols, esc, pasta=D):
    ims = [Image.open((pasta if "/" not in n else AQUI) / (n if n.endswith(".png") else n + ".png")).convert("RGB")
           .crop(caixa) for n in nomes]
    w, h = ims[0].size
    linhas = (len(ims) + cols - 1) // cols
    f = Image.new("RGB", (cols * w + cols - 1, linhas * h + linhas - 1), (25, 40, 63))
    for k, im in enumerate(ims):
        f.paste(im, ((k % cols) * (w + 1), (k // cols) * (h + 1)))
    f.resize((f.width * esc, f.height * esc), Image.NEAREST).save(R / f"{saida}.png")


VILA = (100, 60, 480, 130)
folha("estagios_semente3", [f"s3_a{a}_10h_00" for a in (55, 90, 120, 200, 400)], VILA, 1, 2)
folha("estagios_semente7_e_1", ["s7_a90_10h_00", "s7_a130_10h_00", "s1_a115_10h_00", "s7_a250_10h_00", "s1_a300_10h_00"],
      VILA, 1, 2)
folha("antes_e_depois_estagio6", ["capturas7/s3_a500_10h_00.png", "s3_a400_10h_00"], VILA, 1, 2)
folha("antes_e_depois_estagio5", ["capturas7/s3_a161_10h_00.png", "s1_a115_10h_00"], VILA, 1, 2)
folha("ok_estagio5_casa_caiada_e_templo", ["s1_a115_10h_00"], (100, 62, 300, 128), 1, 5)
folha("ok_estagio6_cupula_moinho_muralha", ["s3_a200_10h_00"], (100, 62, 300, 128), 1, 5)
folha("noite_e_inverno", ["s3_a200_22h_00", "s3_a200_inverno_00"], VILA, 1, 2)
folha("A9_chapeu_de_palha_antes_depois", ["A9_antes_tarde1x_15", "depois_e6_15"], (150, 96, 260, 126), 1, 6)
print("recortes em", R)

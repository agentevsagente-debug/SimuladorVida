"""Recortes da auditoria 7 (estágios 3 a 6) a partir de `capturas7/`.
Uso: python arte_claude/auditoria/recortar7.py"""
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
D = AQUI / "capturas7"
R = AQUI / "recortes7"
R.mkdir(exist_ok=True)
PECAS = AQUI.parent / "pecas"


def folha(saida, nomes, caixa, cols, esc):
    w, h = caixa[2] - caixa[0], caixa[3] - caixa[1]
    linhas = (len(nomes) + cols - 1) // cols
    f = Image.new("RGB", (cols * w + cols - 1, linhas * h + linhas - 1), (25, 40, 63))
    for k, n in enumerate(nomes):
        f.paste(Image.open(D / f"{n}.png").convert("RGB").crop(caixa), ((k % cols) * (w + 1), (k // cols) * (h + 1)))
    f.resize((f.width * esc, f.height * esc), Image.NEAREST).save(R / f"{saida}.png")


VILA = (100, 60, 480, 130)
# os estágios, um por linha, nas duas sementes
folha("estagios_semente3", [f"s3_a{a}_10h_00" for a in (60, 140, 161, 250, 500)], VILA, 1, 2)
folha("estagios_semente7", [f"s7_a{a}_10h_00" for a in (90, 110, 122, 200, 400)], VILA, 1, 2)
# noite e inverno do estágio 6
folha("estagio6_noite_e_inverno", ["s3_a500_22h_00", "s3_a500_inverno_00", "s7_a400_22h_00", "s7_a400_inverno_00"],
      VILA, 1, 2)
# V1: a multidão na frente das casas (4 povos, 200 pessoas, 3 ou 4 casas)
folha("V1_amontoado", ["s3_a140_10h_00", "s7_a400_10h_00"], (110, 88, 300, 126), 1, 5)
# a memória: a ruína do templo de pedra tomada pelo mato
folha("ok_ruina_com_mato", ["s3_a60_10h_00"], (100, 80, 330, 128), 1, 4)
# antes e depois da arte desta auditoria (casa caiada do estágio 5 e roupas nas folhas de sempre),
# com a ligação feita só para o teste
folha("antes_depois_casa_caiada_e_roupas",
      ["s3_a161_10h_00", "depois_s3_a161", "s7_a122_10h_00", "depois_s7_a122", "s7_a400_10h_00", "depois_s7_a400"],
      (100, 78, 480, 128), 2, 2)
folha("antes_depois_roupas_estagio6", ["s7_a400_10h_00", "depois_s7_a400"], (100, 96, 250, 126), 1, 6)
# as casas dos estágios 3 a 6 lado a lado (a do 5 é nova)
pal = [tuple(int(l[i:i + 2], 16) for i in (0, 2, 4)) for l in
       (AQUI.parent.parent / "arte" / "paleta" / "paleta.hex").read_text().split() if len(l) == 6]
img = Image.new("RGBA", (5 * 36, 36), pal[1] + (255,))
for i, n in enumerate(("estagio3/casa_pedra", "estagio4/casa_enxaimel", "estagio5/casa_caiada",
                       "estagio6/casa_tijolo", "estagio5/casa_caiada_ruina")):
    im = Image.open(PECAS / f"{n}.png").convert("RGBA")
    img.alpha_composite(im, (i * 36 + 2, 34 - im.height))
img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(R / "casas_dos_estagios.png")
print("recortes em", R)

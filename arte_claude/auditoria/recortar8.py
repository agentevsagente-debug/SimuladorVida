"""Recortes da auditoria 8 (a primeira hora) a partir de `capturas8/`.
Uso: python arte_claude/auditoria/recortar8.py"""
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
D = AQUI / "capturas8"
R = AQUI / "recortes8"
R.mkdir(exist_ok=True)


def folha(saida, nomes, cols=2, esc=2, caixa=None):
    ims = [Image.open(D / f"{n}.png").convert("RGB") for n in nomes]
    if caixa:
        ims = [im.crop(caixa) for im in ims]
    w, h = ims[0].size
    linhas = (len(ims) + cols - 1) // cols
    f = Image.new("RGB", (cols * w + cols - 1, linhas * h + linhas - 1), (25, 40, 63))
    for k, im in enumerate(ims):
        f.paste(im, ((k % cols) * (w + 1), (k // cols) * (h + 1)))
    f.resize((f.width * esc, f.height * esc), Image.NEAREST).save(R / f"{saida}.png")


folha("01_primeira_abertura_a_meia_noite", ["s1_00", "s1_06", "s1_18", "s1_29"])
folha("02_dicas_dos_botoes", ["s1_32", "s1_35", "s1_41", "s1_44"])
folha("03_chuva_carga_e_milagre", ["s1_51", "s1_55", "s1_57", "s1_62"])
folha("04_fogo_fraco_queima", ["s1_68", "s1_70", "s1_73", "s1_76"])
folha("05_fartura_e_sonho", ["s1_85", "s1_88", "s1_99", "s1_102"])
folha("06_seguir_a_linhagem", ["s1_107", "s1_108", "s1_127"])
folha("07_cronica_sem_os_milagres", ["s1_133", "s4_00"], cols=1)
folha("08_ritmos_10x_e_50x", ["s1_147", "s1_156", "s1_166", "s1_184"])
folha("09_estante", ["s1_191", "s1_197"])
folha("10_reabrir_e_dica_de_pessoa", ["s2_00", "s2_06", "s3_04", "s3_22"])
print("recortes em", R)

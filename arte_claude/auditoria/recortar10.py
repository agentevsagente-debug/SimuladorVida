"""Recortes da auditoria 10 (a primeira hora) a partir de `capturas10/`.
Uso: python arte_claude/auditoria/recortar8.py"""
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
D = AQUI / "capturas10"
R = AQUI / "recortes10"
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


folha("01_primeira_abertura_de_manha", ["s1_00", "s1_08", "s1_18", "s1_30"])
folha("02_chuva_e_dicas_em_fila", ["s1_57", "s1_62", "s1_99", "s1_134"])
folha("03_fogo_brando_sem_queimar", ["s1_67", "s1_68", "s1_69", "s1_70"], caixa=(150, 95, 310, 156), esc=3)
folha("04_cronica_com_os_milagres", ["s1_134", "s4_15"], cols=1)
folha("05_dica_de_pessoa_e_lugar", ["s3_12", "s3_28"])
folha("06_ausencia_e_ritmos", ["s4_00", "s1_170", "s1_192", "s1_199"])
print("recortes em", R)

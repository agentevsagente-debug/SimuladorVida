"""Auditoria 14: a caixa de preces e o termômetro de fé, montados sobre um quadro real do jogo
(capturas13, a tarde em 1x), em 1x e em 2x. A tela da caixa ainda não existe no jogo: a caixa
aberta e a dica da vila são maquetes com as peças e a fonte de verdade."""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent / "pecas"))
sys.path.insert(0, str(AQUI.parent / "pecas" / "interface"))

import interface as I  # noqa: E402
from comum import PALETA, para_imagem  # noqa: E402

PI = AQUI.parent / "pecas" / "interface"


def png(nome):
    return Image.open(PI / nome).convert("RGBA")


def termometro(img, x, y, nivel, seta):
    """nivel de 0 a 1: o código recorta o preenchimento de baixo para cima."""
    tubo, cheio = png("termometro_fe_tubo.png"), png("termometro_fe_cheio.png")
    img.alpha_composite(tubo, (x, y))
    h = cheio.height
    topo = 9 - round(nivel * 8)  # o bulbo sempre cheio; a fé toda chega à linha 1
    img.alpha_composite(cheio.crop((0, topo, cheio.width, h)), (x, y + topo))
    if seta:
        img.alpha_composite(png(f"termometro_fe_{seta}.png"), (x + 7, y + 1))


def principal():
    quadro = Image.open(AQUI / "capturas13" / "02_tarde_vila_1x.png").convert("RGBA").crop((0, 0, 480, 178))
    img = quadro.copy()
    fontes = {k: I.fonte(c) for k, c in (("clara", 31), ("escura", 8), ("dourada", 22), ("titulo", 23))}
    folhas = {k: (para_imagem(f), ch) for k, (f, ch) in fontes.items()}
    bts = I.botoes()
    # a ponta direita da alça: som, lupa e a caixa de preces com prece nova
    x = 186
    for nome in ("som", "lupa_2", "caixa_preces_nova"):
        img.alpha_composite(para_imagem(bts[0]), (x, 1))
        img.alpha_composite(png(f"icones_12/{nome}.png"), (x + 2, 3))
        x += 17
    # a caixa aberta (pergaminho), com um termômetro por povo
    cx, cy, cw, ch = 150, 24, 214, 108
    img.alpha_composite(para_imagem(I.nove(I.caixa_cronica(), 24, 6, cw, ch)), (cx, cy))
    f = folhas["titulo"]
    I.escrever(img, "Preces", cx + 8, cy + 6, f[1], f[0])
    povos = (("Ardem", 0.85, "sobe"), ("Vau", 0.45, None), ("Pedra Alta", 0.12, "desce"))
    for i, (nome, nivel, seta) in enumerate(povos):
        yy = cy + 20 + i * 16
        termometro(img, cx + 8, yy, nivel, seta)
        e = folhas["escura"]
        I.escrever(img, nome, cx + 26, yy + 2, e[1], e[0])
    linhas = ["Iara, de Ardem: «Que a chuva volte", "antes da colheita.» esperando"]
    for i, t in enumerate(linhas):
        e = folhas["escura"]
        I.escrever(img, t, cx + 8, cy + 72 + i * 12, e[1], e[0])
    # a dica escura ao passar o cursor sobre a vila
    dx, dy = 20, 96
    img.alpha_composite(para_imagem(I.nove(I.caixa_dica(), 12, 4, 100, 22)), (dx, dy))
    termometro(img, dx + 5, dy + 4, 0.6, "sobe")
    c = folhas["clara"]
    I.escrever(img, "Ardem, 23", dx + 23, dy + 6, c[1], c[0])
    img.save(AQUI / "capturas14" / "maquete_1x.png")
    img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(AQUI / "capturas14" / "maquete_2x.png")
    # recortes ampliados para ler os detalhes (cada pixel de tela em 4 e em 2)
    alca = img.crop((180, 0, 240, 18))
    alca.resize((alca.width * 8, alca.height * 8), Image.NEAREST).save(AQUI / "capturas14" / "recorte_alca_1x_8.png")
    caixa = img.crop((cx, cy, cx + cw, cy + 70))
    caixa.resize((caixa.width * 4, caixa.height * 4), Image.NEAREST).save(AQUI / "capturas14" / "recorte_caixa_1x_4.png")
    dica = img.crop((dx, dy, dx + 100, dy + 22))
    dica.resize((dica.width * 6, dica.height * 6), Image.NEAREST).save(AQUI / "capturas14" / "recorte_dica_1x_6.png")


if __name__ == "__main__":
    principal()

"""O mesmo lugar (a cena-alvo, de dia) nas 4 estações, montado só com peças e camadas.
No outono caem folhas secas; no inverno cai neve (efeitos de `efeitos/`)."""
from pathlib import Path
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(PECAS / "montagem"))
sys.path.insert(0, str(PECAS / "terreno"))

import montar  # noqa: E402
from comum import PALETA, gravar  # noqa: E402

W, H = 480, 160


def particulas(c, folha, larg, n, semente, ate_y=118):
    px = montar.ler(PECAS / "efeitos" / folha)
    quadros = [montar.quadro(px, i, larg) for i in range(len(px[0]) // larg)]
    rng = random.Random(semente)
    for _ in range(n):
        q = quadros[rng.randrange(len(quadros))]
        x, y = rng.randrange(-4, W), rng.randrange(0, ate_y)
        for j, l in enumerate(q):
            for i, cor in enumerate(l):
                if cor is not None and 0 <= x + i < W and 0 <= y + j < H and c.tag[y + j][x + i] != montar.PESSOA:
                    c.p[y + j][x + i] = cor


def neve(c):
    px = montar.ler(PECAS / "efeitos" / "neve_4q.png")
    q = montar.quadro(px, 0, 64)
    for y in range(H):
        for x in range(W):
            cor = q[y % 64][x % 64]
            if cor is not None and y < 140 and c.tag[y][x] != montar.PESSOA:
                c.p[y][x] = cor


def principal():
    juntas = Image.new("RGB", (W, H * 4 + 12), PALETA[30])
    for i, est in enumerate(("primavera", "verao", "outono", "inverno")):
        c = montar.montar("dia", None if est == "verao" else est)
        if est == "outono":
            particulas(c, "folha_seca_4q.png", 8, 22, 7)
        if est == "inverno":
            neve(c)
        img = montar.imagem(c)
        gravar(img.convert("RGBA"), AQUI / f"cena_{est}.png")
        juntas.paste(img, (0, i * (H + 4)))
    juntas.save(AQUI / "amostra_estacoes.png")
    juntas.resize((W * 4, juntas.height * 4), Image.NEAREST).save(AQUI / "amostra_estacoes_4x.png")
    # folha de peças: cada linha é uma estação (primavera, verão, outono, inverno)
    pecas = ["estagio1/arvore_copa_a", "estagio1/arvore_copa_b", "estagio1/pinheiro_a", "estagio1/arbusto_frutas",
             "estagio1/capim", "estagio1/cabana_galhos", "estagio2/casa_taipa", "estagio3/casa_pedra",
             "estagio6/casa_tijolo"]
    largura = sum(Image.open(PECAS / f"{p}.png").width + 4 for p in pecas) + 4
    folha = Image.new("RGBA", (largura, 4 * 46), PALETA[1] + (255,))
    for i, est in enumerate(("primavera", "verao", "outono", "inverno")):
        base_y = i * 46 + 42
        x = 4
        grama = PECAS / ("estacoes/" + est if est != "verao" else "") / "terreno" / "grama_a.png"
        g = Image.open(grama if grama.exists() else PECAS / "terreno" / "grama_a.png")
        for gx in range(0, largura, 8):
            folha.alpha_composite(g, (gx, base_y - 1))
        for p in pecas:
            pasta, nome = p.split("/")
            sazonal = PECAS / "estacoes" / est / pasta / f"{nome}.png"
            im = Image.open(sazonal if sazonal.exists() else PECAS / f"{p}.png")
            folha.alpha_composite(im, (x, base_y - im.height + 1))
            x += im.width + 4
    folha.save(AQUI / "amostra_estacoes_pecas.png")
    folha.resize((folha.width * 4, folha.height * 4), Image.NEAREST).save(AQUI / "amostra_estacoes_pecas_4x.png")
    print("cena nas 4 estações")


if __name__ == "__main__":
    principal()

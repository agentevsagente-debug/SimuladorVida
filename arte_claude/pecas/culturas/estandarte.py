"""Estandarte do povo (auditoria 7, C1): um mastro de 4 x 8 com a bandeira na cor da roupa do
povo e o símbolo do templo, para cada vila ler como um lugar, mesmo sem templo.

São 9 folhas, uma por cor de roupa (turquesa, rosa, lilás) e símbolo (sol, lua, árvore), com
2 quadros: a bandeira parada e balançando ao vento. As folhas vão em `objetos/`. As cores já vêm prontas: o motor só
escolhe a folha pela `aparencia` do povo. A base é a linha 7 (o pé do mastro): ponha-a no
alto da casa principal, na cumeeira.
"""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
OBJ = AQUI.parent / "objetos"           # em objetos/, para entrar no atlas comum (todos os estágios)
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, folha_quadros, gravar, para_imagem  # noqa: E402

# roupa do povo -> (cor da bandeira, sombra da barra de baixo)
ROUPAS = {"turquesa": (28, 18), "rosa": (27, 7), "lilas": (29, 5)}
# símbolo -> pixels (x, y, cor) na bandeira parada (colunas 1 a 3, linhas 1 a 5)
SIMBOLOS = {
    "sol": [(2, 2, 22), (1, 3, 22), (2, 3, 31), (3, 3, 22), (2, 4, 22)],
    "lua": [(2, 2, 31), (1, 3, 31), (2, 4, 31)],
    "arvore": [(2, 2, 14), (1, 3, 14), (2, 3, 13), (3, 3, 14), (2, 4, 9)],
}
MASTRO, PONTA = 9, 22


def quadro(roupa, simbolo, vento):
    cor, sombra = ROUPAS[roupa]
    q = [[None] * 4 for _ in range(8)]
    q[0][0] = PONTA
    for y in range(1, 8):
        q[y][0] = MASTRO
    desce = {1: 0, 2: 0, 3: 1 if vento else 0}            # ao vento, a ponta solta cai 1 px
    for x in (1, 2, 3):
        d = desce[x]
        for y in range(1, 6):
            q[y + d][x] = sombra if y == 5 else cor
    # o rabo de andorinha na ponta solta
    q[3 + desce[3]][3] = None
    for x, y, c in SIMBOLOS[simbolo]:
        q[y + desce[x]][x] = c
    return q


def gerar():
    return {f"estandarte_{r}_{s}_2q": [quadro(r, s, False), quadro(r, s, True)]
            for r in ROUPAS for s in SIMBOLOS}


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), OBJ / f"{nome}.png")
    # amostra: os 9 estandartes, parados e ao vento, sobre o céu de dia, o entardecer e a noite
    W, H = 9 * 12 + 4, 3 * 12 + 4
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    for j, cor in enumerate((1, 7, 3)):
        img.paste(PALETA[cor] + (255,), (0, 2 + j * 12, W, 2 + j * 12 + 12))
        for i, qs in enumerate(folhas.values()):
            img.alpha_composite(para_imagem(qs[0]), (4 + i * 12, 4 + j * 12))
            img.alpha_composite(para_imagem(qs[1]), (9 + i * 12, 4 + j * 12))
    img.save(AQUI / "amostra_estandartes.png")
    img.resize((W * 6, H * 6), Image.NEAREST).save(AQUI / "amostra_estandartes_4x.png")
    print("estandartes:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

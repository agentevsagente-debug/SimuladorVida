"""O recomeço no mundo vazio: a primeira fogueira acesa pelo povo novo.

- `acoes/acender_fogo_4q` (12x12): ajoelhado diante da lenha, gira o pau entre as mãos sobre
  a tábua (o fogo de fricção), sai um fio de fumaça e ele se curva para soprar a brasa.
- `estagio1/fogueira_nascendo_4q` (16x16, o mesmo encaixe da `fogueira_acesa_4q`): a lenha
  com a palha, o fio de fumaça, a brasa, a chama pequena e a chama crescendo. Depois do último
  quadro, a fogueira passa a `fogueira_acesa_4q`.

Quem chega com a trouxa (`acoes/andar_trouxa_4q`) já existia.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(AQUI))

import construcao as k  # noqa: E402
from acoes import CAB, CAB_BAIXA  # noqa: E402
from cotidiano import ajoelhado, largo, por  # noqa: E402
from forte import inclinar  # noqa: E402

TABUA = [(x, 10, "o") for x in range(7, 12)] + [(x, 11, "q") for x in range(7, 12)]


def acender_fogo():
    pau = lambda y0: [(9, y, "n") for y in range(y0, 10)]  # noqa: E731
    q0 = por(largo(ajoelhado([(1, 6, "s"), (6, 6, "S"), (7, 6, "S")])), TABUA + pau(4) + [(8, 6, "S"), (10, 6, "S")])
    q1 = por(largo(ajoelhado([(1, 6, "s"), (6, 7, "S"), (7, 8, "S")])), TABUA + pau(4) + [(8, 8, "S"), (10, 8, "S")])
    q2 = por(largo(ajoelhado([(1, 6, "s"), (6, 6, "S"), (7, 6, "S")], CAB)),
             TABUA + pau(4) + [(8, 6, "S"), (10, 6, "S"), (10, 9, "z"), (11, 8, "Z"), (10, 7, "z"), (11, 5, "Z")])
    q3 = por(largo(inclinar(ajoelhado([(1, 6, "s"), (6, 8, "S"), (7, 9, "S")]), 2)),
             TABUA + [(9, 9, "K"), (10, 9, "k"), (10, 8, "K"), (11, 7, "z"), (11, 5, "Z")])
    return [q0, q1, q2, q3]


def fogueira_nascendo():
    """16x16, cores da paleta direto (como as outras peças do estágio 1)."""
    base = {(2, 14): 12, (3, 14): 12, (4, 14): 9, (5, 14): 9, (6, 14): 9, (7, 14): 9, (8, 14): 8, (9, 14): 20,
            (10, 14): 8, (11, 14): 8, (12, 14): 8, (13, 14): 11, (14, 14): 11,
            (2, 15): 11, (3, 15): 11, (4, 15): 12, (5, 15): 12, (11, 15): 12, (12, 15): 12, (13, 15): 11, (14, 15): 11,
            (5, 13): 10, (11, 13): 9}
    palha = {(6, 13): 16, (7, 13): 16, (8, 13): 10, (9, 13): 16, (10, 13): 16}
    etapas = [
        {(8, 12): 11, (9, 10): 12, (8, 8): 11, (9, 6): 12},                                         # fio de fumaça
        {(7, 13): 21, (8, 13): 20, (9, 12): 22, (8, 11): 11, (9, 9): 12, (8, 7): 11, (9, 5): 12},   # a brasa
        {(7, 13): 22, (8, 13): 31, (9, 13): 21, (7, 12): 21, (8, 12): 22, (8, 11): 21, (9, 11): 20,
         (9, 8): 11, (8, 6): 12},                                                                   # chama pequena
        {(6, 13): 21, (7, 13): 22, (8, 13): 22, (9, 13): 22, (10, 13): 21,
         (6, 12): 20, (7, 12): 21, (8, 12): 31, (9, 12): 22, (10, 12): 20,
         (6, 11): 20, (7, 11): 21, (8, 11): 22, (9, 11): 21, (10, 11): 20,
         (7, 10): 20, (8, 10): 21, (9, 10): 20, (8, 9): 20, (10, 8): 20},                           # crescendo
    ]
    quadros = []
    for e in etapas:
        q = [[None] * 16 for _ in range(16)]
        for d in (base, palha, e):
            for (x, y), c in d.items():
                q[y][x] = c
        quadros.append(q)
    return quadros


def principal():
    from PIL import Image
    from comum import PALETA, para_imagem, trocar
    acao = k.pintar(acender_fogo())
    k.gravar(k.folha_quadros(acao), AQUI / "acender_fogo_4q.png")
    fog = fogueira_nascendo()
    k.gravar(k.folha_quadros(fog), PECAS / "estagio1" / "fogueira_nascendo_4q.png")
    # amostra: quem acende, ao lado da fogueira nascendo, e no fim a fogueira acesa
    acesa = Image.open(PECAS / "estagio1" / "fogueira_acesa_4q.png").crop((0, 0, 16, 16))
    W, H = 4 * 30 + 24, 22
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    grama = Image.open(PECAS / "terreno" / "grama_a.png")
    for x in range(0, W, 8):
        img.alpha_composite(grama, (x, 16))
    troca = k.hab.troca(24, 23, 27)
    for i in range(4):
        x0 = 2 + i * 30
        img.alpha_composite(para_imagem(trocar(acao[i], troca)), (x0, 6))
        img.alpha_composite(para_imagem(fog[i]), (x0 + 10, 2))
    img.alpha_composite(acesa, (2 + 4 * 30, 2))
    img.save(AQUI / "amostra_recomeco.png")
    img.resize((W * 6, H * 6), Image.NEAREST).save(AQUI / "amostra_recomeco_4x.png")
    print("recomeço: acender_fogo_4q e estagio1/fogueira_nascendo_4q")


if __name__ == "__main__":
    principal()

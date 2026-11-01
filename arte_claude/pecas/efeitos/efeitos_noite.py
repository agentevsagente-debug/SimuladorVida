"""Versões noturnas dos efeitos dos poderes (auditoria 8, P10), para os que não se liam no
escuro. Nenhuma passa pela tabela `noite`: já vêm nas cores certas para a noite, só da paleta e
sem semitransparência.

- Os que emitem luz (fartura, sonho, cura) ficam maiores e mais claros: a estrela tem os
  braços mais longos, o miolo branco e o contorno escuro, e as partículas têm 2 px.
- Os que acontecem no chão (seca, fenda, pedras) ganham o realce da lua: a borda de cima de
  cada pedaço escuro fica clara, como se a lua batesse ali, para o escuro não sumir no chão
  escuro.

Mesmo tamanho, mesmo número de quadros e mesmo encaixe das versões de dia (o motor troca uma
pela outra pelo horário), menos os brilhos, que passam de 8 x 8 para 12 x 12 (centro 6, 6).
"""
from pathlib import Path
import json
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
sys.path.insert(0, str(AQUI))

from comum import PALETA, folha_quadros, gravar, para_imagem  # noqa: E402
import efeitos_fase2 as f2  # noqa: E402

NOITE = {int(k): v for k, v in
         json.loads((AQUI.parent / "montagem" / "tabelas_luz.json").read_text())["noite"].items()}
LUA, LUA_FORTE, ESCURO = 11, 12, 3


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


# ---------------------------------------------------------------- brilhos que emitem luz

def estrela(braco, miolo, arestas, ponta, contorno=ESCURO):
    """Brilho de 12x12 em 4 quadros: acende, abre a estrela de 4 pontas, gira para a diagonal
    e apaga. Contorno escuro de 1 px em volta, para separar do céu e do chão da noite."""
    c = 6
    formas = [
        [(c, c, miolo), (c - 1, c, braco), (c + 1, c, braco), (c, c - 1, braco), (c, c + 1, braco)],
        [(c, c, miolo)] + [(c + d * s, c, braco if d < 3 else ponta) for s in (-1, 1) for d in (1, 2, 3)]
        + [(c, c + d * s, braco if d < 3 else ponta) for s in (-1, 1) for d in (1, 2, 3)]
        + [(c - 1, c - 1, arestas), (c + 1, c + 1, arestas), (c + 1, c - 1, arestas), (c - 1, c + 1, arestas)],
        [(c, c, miolo)] + [(c + d * sx, c + d * sy, braco if d < 2 else ponta) for sx in (-1, 1) for sy in (-1, 1)
                           for d in (1, 2)]
        + [(c - 1, c, arestas), (c + 1, c, arestas), (c, c - 1, arestas), (c, c + 1, arestas)],
        [(c, c, braco), (c - 2, c, ponta), (c + 2, c, ponta), (c, c - 2, ponta), (c, c + 2, ponta)],
    ]
    out = []
    for f in formas:
        q = novo(12, 12)
        for x, y, cor in f:
            put(q, x, y, cor)
        contornar(q, contorno)
        out.append(q)
    return out


def contornar(q, cor):
    h, w = len(q), len(q[0])
    cheios = {(x, y) for y in range(h) for x in range(w) if q[y][x] is not None}
    for x, y in cheios:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in cheios and q[ny][nx] is None:
                q[ny][nx] = cor


def fartura_aura_noite():
    """Partículas douradas de 2 px (claro em cima) subindo da roça, mais numerosas que de dia,
    com uma faísca branca de vez em quando."""
    rng = random.Random(91)
    parts = [(rng.randint(1, 13), rng.randint(0, 15)) for _ in range(12)]
    quadros = []
    for k in range(4):
        q = novo(16, 16)
        for i, (x, y) in enumerate(parts):
            yy = (y - k * 4) % 16
            xx = x + (1 if (yy // 4 + x) % 2 else 0)
            put(q, xx, yy, 31 if (i + k) % 5 == 0 else 22)
            put(q, xx, yy + 1, 21 if yy < 12 else 15)
        quadros.append(q)
    return quadros


def sonho_noite():
    """A espiral do sonho com 7 pontos de 2 px (branco e lilás) e o rastro lilás escuro."""
    quadros = []
    cx, cy = 7.5, 7.5
    for k in range(4):
        q = novo(16, 16)
        for i in range(7):
            a = k * math.pi / 8 + i * 2 * math.pi / 7
            r = 6 - i * 0.5
            x, y = round(cx + math.cos(a) * r), round(cy + math.sin(a) * r * 0.7)
            put(q, x, y, 31 if i < 2 else 29)
            put(q, x + 1, y, 29)
            ra = a - 0.4
            put(q, round(cx + math.cos(ra) * r), round(cy + math.sin(ra) * r * 0.7), 7)
        put(q, 7 + k % 2, 7 + (k // 2), 31)
        quadros.append(q)
    return quadros


# ---------------------------------------------------------------- o chão com realce da lua

def com_lua(quadros):
    """Passa pela tabela `noite` e contorna cada pedaço escuro (30 e 8 de dia) com o realce da
    lua: claro (12) em cima e menos claro (11) do lado esquerdo, por onde a lua bate, para a
    racha e a fenda terem forma no chão escuro. As pedras e os torrões claros ficam em 12."""
    out = []
    for q in quadros:
        n = [[None if c is None else NOITE.get(c, c) for c in l] for l in q]
        h, w = len(q), len(q[0])
        escuro = lambda x, y: 0 <= x < w and 0 <= y < h and q[y][x] in (30, 8)  # noqa: E731
        for y in range(h):
            for x in range(w):
                if escuro(x, y):
                    if y > 0 and not escuro(x, y - 1):
                        n[y - 1][x] = LUA_FORTE
                    if x > 0 and not escuro(x - 1, y) and n[y][x - 1] != LUA_FORTE:
                        n[y][x - 1] = LUA
                elif q[y][x] in (11, 12):
                    n[y][x] = LUA_FORTE
        out.append(n)
    return out


def pedras_caindo_noite():
    """As pedras do terremoto com a face de cima clara de lua e o resto escuro."""
    formas = [[(1, 1, 12), (2, 1, 12), (1, 2, 11), (2, 2, 4)], [(1, 1, 12), (2, 2, 4), (1, 2, 11)],
              [(1, 1, 11), (2, 1, 12), (1, 2, 4), (2, 2, 4)]]
    out = []
    for f in formas:
        q = novo(4, 4)
        for x, y, c in f:
            put(q, x, y, c)
        out.append(q)
    return out


def gerar():
    return {
        "fartura_brilho_noite_4q": estrela(22, 31, 21, 21),
        "fartura_aura_noite_4q": fartura_aura_noite(),
        "sonho_noite_4q": sonho_noite(),
        "sonho_brilho_noite_4q": estrela(29, 31, 7, 7),
        "cura_brilho_noite_4q": estrela(0, 31, 15, 15),
        "seca_rachaduras_noite_4q": com_lua(f2.seca_rachaduras()),
        "fenda_noite_4q": com_lua(f2.fenda()),
        "pedras_caindo_noite_3v": pedras_caindo_noite(),
    }


DIA = {"fartura_brilho_noite_4q": "fartura_brilho_4q", "fartura_aura_noite_4q": "fartura_aura_4q",
       "sonho_noite_4q": "sonho_4q", "sonho_brilho_noite_4q": "sonho_brilho_4q",
       "cura_brilho_noite_4q": "cura_brilho_4q", "seca_rachaduras_noite_4q": "seca_rachaduras_4q",
       "fenda_noite_4q": "fenda_4q", "pedras_caindo_noite_3v": "pedras_caindo_3v"}
PASSAM_PELA_NOITE = {"seca_rachaduras_4q", "fenda_4q", "pedras_caindo_3v"}


def amostra(folhas):
    """Cada linha: a versão de dia como fica à noite hoje (à esquerda) e a noturna (à direita),
    sobre o céu e o chão da noite."""
    idx = {c: i for i, c in enumerate(PALETA)}
    linhas = []
    for nome, qs in folhas.items():
        dia = Image.open(AQUI / f"{DIA[nome]}.png").convert("RGBA")
        if DIA[nome] in PASSAM_PELA_NOITE:
            px = dia.load()
            for y in range(dia.height):
                for x in range(dia.width):
                    r, g, b, a = px[x, y]
                    if a:
                        px[x, y] = PALETA[NOITE.get(idx[(r, g, b)], idx[(r, g, b)])] + (255,)
        linhas.append((dia, [para_imagem(q) for q in qs]))
    larg = max(d.width + sum(i.width + 2 for i in n) for d, n in linhas) + 16
    alt = sum(max(d.height, n[0].height) + 6 for d, n in linhas) + 4
    img = Image.new("RGBA", (larg, alt), PALETA[3] + (255,))
    y = 3
    for dia, novas in linhas:
        h = max(dia.height, novas[0].height)
        img.paste(PALETA[13] + (255,), (0, y + h - 2, larg, y + h + 4))
        img.alpha_composite(dia, (4, y + h - dia.height))
        x = dia.width + 12
        for im in novas:
            img.alpha_composite(im, (x, y + h - im.height))
            x += im.width + 2
        y += h + 6
    return img


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    img = amostra(folhas)
    img.save(AQUI / "amostra_efeitos_noite.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_efeitos_noite_4x.png")
    print("efeitos da noite:", ", ".join(folhas))


if __name__ == "__main__":
    principal()

"""Sinais de prece: a luz que sobe de quem reza (ou da vila), em 3 intensidades, e o
chamado "os últimos". Mais os símbolos de necessidade da API do núcleo
(seca, fome, doenca, frio, guerra), para o motor pôr ao lado do sinal.

A base de cada quadro (onde o sinal "nasce") é a última linha; o motor põe essa linha
1 px acima da cabeça de quem reza, ou acima do telhado mais alto da vila.
"""
from pathlib import Path
import math
import random
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, clamp, folha_quadros, gravar, para_imagem, pont  # noqa: E402


def novo(w, h):
    return [[None] * w for _ in range(h)]


def put(q, x, y, c):
    if 0 <= y < len(q) and 0 <= x < len(q[0]):
        q[y][x] = c


def gota_de_luz(q, cx, cy, a, b, cores, halo=None, halo_dens=0.5):
    """Chama-gota de luz: losango arredondado mais alto que largo, núcleo claro embaixo."""
    nucleo, meio, borda = cores
    for y in range(len(q)):
        for x in range(len(q[0])):
            dx, dy = (x - cx) / a, (y - cy) / b
            # ponta para cima: a largura diminui na metade de cima
            larg = 1 - max(0.0, -dy) * 0.55
            d = abs(dx) / max(larg, 0.2) + abs(dy)
            if d <= 0.45 and dy > -0.4:
                put(q, x, y, nucleo)
            elif d <= 0.75:
                put(q, x, y, meio)
            elif d <= 1.0:
                put(q, x, y, borda)
            elif halo is not None and d <= 1.45 and pont(x, y, halo_dens * (1.45 - d) / 0.45 + 0.1):
                put(q, x, y, halo)


def prece_comum():
    """Pedido comum: luz pequena e mansa que sobe e desce 1 px."""
    quadros = []
    for k, sobe in enumerate((0, 1, 1, 0)):
        q = novo(8, 12)
        gota_de_luz(q, 3.5, 7 - sobe, 2.3, 3.8, (31, 22, 21), halo=None)
        if k in (1, 2):
            put(q, 3 + k % 2, 10, 16)              # rastro subindo
        quadros.append(q)
    return quadros


def prece_urgente():
    """Urgente: luz maior, com halo pontilhado e 4 raios que pulsam."""
    quadros = []
    for k in range(4):
        q = novo(12, 16)
        cx, cy = 5.5, 8 - (k in (1, 2))
        gota_de_luz(q, cx, cy, 2.6, 4.2, (31, 22, 21), halo=22, halo_dens=0.3 + 0.2 * (k % 2))
        comp = 2 if k % 2 else 1
        for i in range(1, comp + 1):
            put(q, round(cx), round(cy - 5 - i), 22)
            put(q, round(cx - 3.5 - i), round(cy), 21)
            put(q, round(cx + 3.5 + i), round(cy), 21)
        put(q, round(cx), 15, 21 if k % 2 else 16)
        quadros.append(q)
    return quadros


def prece_desesperada():
    """Desesperado: chama de luz alta e quente que treme, 8 raios e faíscas subindo."""
    quadros = []
    rng = random.Random(5)
    faiscas = [(rng.randint(2, 13), rng.randint(0, 23)) for _ in range(5)]
    for k in range(4):
        q = novo(16, 24)
        cx, cy = 7.5 + (1 if k == 1 else -1 if k == 3 else 0) * 0.5, 13
        gota_de_luz(q, cx, cy, 3.6 + (k % 2) * 0.4, 6.5, (31, 22, 21), halo=20, halo_dens=0.5)
        comp = 2 + (k % 2)
        for ang in range(8):
            a = ang * math.pi / 4
            for i in range(comp):
                d = 7.5 + i if ang % 2 == 0 else 6 + i
                x, y = round(cx + math.cos(a) * d * 0.9), round(cy + math.sin(a) * d * 1.1)
                if q[y][x] is None if 0 <= y < 24 and 0 <= x < 16 else False:
                    put(q, x, y, 21 if i == 0 else 20)
        for x, y in faiscas:
            yy = (y - k * 3) % 24
            if yy < 6:
                put(q, x, yy, 22 if (x + k) % 2 else 21)
        quadros.append(q)
    return quadros


def os_ultimos():
    """Os últimos: o chamado mais forte. Um facho de luz fria e alta sobre a vila, com
    poucos pontos de luz caindo (os poucos que restam), pulsando devagar."""
    quadros = []
    w, h = 24, 48
    for k in range(4):
        q = novo(w, h)
        pulso = (0, 1, 2, 1)[k]
        cx = w / 2 - 0.5
        for y in range(h):
            alt = y / (h - 1)                      # 0 no topo, 1 na base
            meia = 1.2 + alt * (3.0 + pulso * 0.6)
            for x in range(w):
                d = abs(x - cx)
                if d <= meia * 0.35:
                    c = 31
                elif d <= meia * 0.7:
                    c = 0
                elif d <= meia:
                    c = 19 if pont(x, y, 0.4 + alt * 0.6) else None
                elif d <= meia + 2 and pont(x, y, 0.25 * alt):
                    c = 1
                else:
                    c = None
                # o facho se desfaz no alto
                if c is not None and alt < 0.3 and not pont(x, y, alt / 0.3):
                    c = None
                if c is not None:
                    put(q, x, y, c)
        # cinco pontos de luz em volta, descendo devagar
        for i in range(5):
            a = i * 2 * math.pi / 5 + k * 0.25
            x = round(cx + math.cos(a) * 8)
            y = round(30 + math.sin(a) * 4 + k)
            put(q, x, y, 31)
            put(q, x, y - 1, 0)
        # brilho no chão
        for x in range(w):
            d = abs(x - cx)
            if d < 7 + pulso and pont(x, h - 1, 1 - d / (8 + pulso)):
                put(q, x, h - 1, 0 if d < 3 else 19)
        quadros.append(q)
    return quadros


SIMBOLOS = {
    "seca": ["...y....", ".y.y.y..", "..yyy...", "yyyWyyy.", "..yyy...", ".y.y.y..", "...y....", "........"],
    "fome": ["...s....", "..sSs...", "...s....", "..sSs...", "...s....", "..sSs...", "...n....", "...n...."],
    "doenca": ["........", ".rr.rr..", "rRrrrrr.", "rrrxrrr.", ".rrxrr..", "..rxr...", "...r....", "........"],
    "frio": ["...W....", ".W.w.W..", "..wWw...", "WwWWWwW.", "..wWw...", ".W.w.W..", "...W....", "........"],
    "guerra": ["g.....g.", ".g...g..", "..g.g...", "...g....", "..n.n...", ".n...n..", "n.....n.", "........"],
}
CORES_SIMB = {"y": 22, "W": 31, "s": 16, "S": 22, "n": 9, "r": 20, "R": 27, "x": 8, "w": 19, "g": 12}


def simbolos():
    out = []
    for nome in ("seca", "fome", "doenca", "frio", "guerra"):
        out.append([[None if ch == "." else CORES_SIMB[ch] for ch in linha] for linha in SIMBOLOS[nome]])
    return out


def gerar():
    return {
        "prece_comum_4q": prece_comum(),
        "prece_urgente_4q": prece_urgente(),
        "prece_desesperada_4q": prece_desesperada(),
        "os_ultimos_4q": os_ultimos(),
        "necessidade_5v": simbolos(),
    }


def amostra(folhas):
    from PIL import Image
    larg = max(len(qs[0][0]) * len(qs) + 2 * (len(qs) - 1) for qs in folhas.values()) + 4
    alt = sum(len(qs[0]) + 4 for qs in folhas.values()) + 4
    img = Image.new("RGBA", (larg * 2 + 4, alt), PALETA[30] + (255,))
    img.paste(PALETA[1] + (255,), (0, 0, larg, alt))
    img.paste(PALETA[3] + (255,), (larg + 4, 0, larg * 2 + 4, alt))
    y = 4
    for qs in folhas.values():
        for i, q in enumerate(qs):
            f = para_imagem(q)
            x = 2 + i * (len(q[0]) + 2)
            img.alpha_composite(f, (x, y))
            img.alpha_composite(f, (larg + 4 + x, y))
        y += len(qs[0]) + 4
    return img


def principal():
    folhas = gerar()
    for nome, qs in folhas.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    from PIL import Image
    img = amostra(folhas)
    img.save(AQUI / "amostra_sinais.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / "amostra_sinais_4x.png")
    print("sinais:", ", ".join(f"{n} {len(q[0][0])}x{len(q[0])}" for n, q in folhas.items()))


if __name__ == "__main__":
    principal()

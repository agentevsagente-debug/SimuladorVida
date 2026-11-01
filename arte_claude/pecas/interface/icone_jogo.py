"""Ícone do jogo para a bandeja e a barra de tarefas: o pequeno mundo numa moldura.

Desenhado à mão em 16x16 e 32x32 (cada tamanho com o seu desenho, para ler bem em 1x).
O de 256x256 é o de 32x32 ampliado 8 vezes sem suavização. O .ico leva os tamanhos
16, 32, 48 (16x3), 64 (32x2), 128 (32x4) e 256, todos com pixels nítidos.
"""
from pathlib import Path
import math
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import gravar, para_imagem, pont  # noqa: E402


def moldura(n, raio):
    """Quadro com cantos arredondados: devolve a grade e a função 'dentro'."""
    q = [[None] * n for _ in range(n)]

    def dentro(x, y, margem=0):
        cx = min(max(x, raio + margem), n - 1 - raio - margem)
        cy = min(max(y, raio + margem), n - 1 - raio - margem)
        return math.hypot(x - cx, y - cy) <= raio + 0.3
    return q, dentro


def icone(n):
    grande = n == 32
    q, dentro = moldura(n, 3 if grande else 2)
    borda = 2 if grande else 1
    horizonte = 19 if grande else 9
    for y in range(n):
        for x in range(n):
            if not dentro(x, y):
                continue
            if not dentro(x, y, borda):
                # moldura de madeira escura, com luz em cima à esquerda
                q[y][x] = 30 if not dentro(x, y, 1) else (9 if x + y < n else 8)
                continue
            meio = horizonte - (6 if grande else 4)
            q[y][x] = 1 if y < meio else 0 if y > meio + 1 else (0 if pont(x, y, 0.5) else 1)
    # sol
    sx, sy, sr = (23, 8, 3.2) if grande else (11, 4, 1.7)
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - sx, y - sy)
            if dentro(x, y, borda) and d <= sr:
                q[y][x] = 31 if d < sr - 1 else 22
    # montanha ao fundo (só no grande)
    if grande:
        for x in range(n):
            topo = round(15 + 2 * abs(math.sin(x * 0.35 + 1.2)))
            for y in range(topo, horizonte + 2):
                if dentro(x, y, borda):
                    q[y][x] = 2 if y > topo else 18
    # morro de grama e terra
    for x in range(n):
        if grande:
            s = round(horizonte + 1 - 3 * math.sin((x - 2) / 28 * math.pi))
        else:
            s = round(horizonte + 1 - 1.5 * math.sin((x - 1) / 14 * math.pi))
        for y in range(s, n):
            if not dentro(x, y, borda):
                continue
            d = y - s
            if d == 0:
                c = 15
            elif d == 1:
                c = 14
            elif d == 2 and grande:
                c = 13
            else:
                c = 9 if (x * 3 + y) % 7 else 10
                if grande and y >= n - 6:
                    c = 11 if (x * 5 + y * 3) % 11 == 0 else 8
            q[y][x] = c
    # cabana de galhos e fogueira
    if grande:
        base, x0 = 19, 7
        for r in range(8):
            hw = r * 0.55 + 0.5
            for x in range(round(x0 + 4 - hw), round(x0 + 4 + hw) + 1):
                dx = x - (x0 + 4)
                c = 10 if dx < -hw + 1 else 8 if dx > hw - 1 else 14 if r < 5 else 9
                if r >= 5 and abs(dx + 0.5) < (r - 4) * 0.6:
                    c = 30
                q[base - 7 + r][x] = c
        q[base - 8][x0 + 3] = 10
        q[base - 8][x0 + 5] = 9
        fx = 18
        for dx, dy, c in ((0, -3, 20), (0, -2, 21), (-1, -1, 21), (0, -1, 22), (1, -1, 20),
                          (-1, 0, 9), (0, 0, 31), (1, 0, 8)):
            q[base + dy - 1][fx + dx] = c
        # uma pessoa ao lado do fogo
        for dy, c in ((-5, 30), (-4, 26), (-3, 28), (-2, 28), (-1, 25)):
            q[base + dy][21] = c
        q[base - 3][22] = 26
    else:
        base, x0 = 9, 3
        for r in range(5):
            hw = r * 0.6
            for x in range(round(x0 + 2 - hw), round(x0 + 2 + hw) + 1):
                dx = x - (x0 + 2)
                q[base - 4 + r][x] = 30 if r == 4 and dx == 0 else 10 if dx < 0 else 9
        q[base - 1][10] = 21
        q[base - 2][10] = 22
        q[base][10] = 20
    return q


def principal():
    p16, p32 = icone(16), icone(32)
    i16 = gravar(p16, AQUI / "icone_jogo_16.png", ampliar=False)
    i32 = gravar(p32, AQUI / "icone_jogo_32.png", ampliar=False)
    i256 = i32.resize((256, 256), Image.NEAREST)
    i256.save(AQUI / "icone_jogo_256.png")
    extras = [i16.resize((48, 48), Image.NEAREST), i32.resize((64, 64), Image.NEAREST),
              i32.resize((128, 128), Image.NEAREST), i256]
    i256.save(AQUI / "icone_jogo.ico", format="ICO",
              sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
              append_images=[i16, i32] + extras[:3])
    amostra = Image.new("RGBA", (16 + 32 + 12, 36), (0, 0, 0, 0))
    amostra.alpha_composite(i16, (2, 18))
    amostra.alpha_composite(i32, (24, 2))
    amostra.resize((amostra.width * 4, amostra.height * 4), Image.NEAREST).save(AQUI / "amostra_icone_4x.png")
    print("ícone do jogo: 16, 32, 256 e .ico")


if __name__ == "__main__":
    principal()

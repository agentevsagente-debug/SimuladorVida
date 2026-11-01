"""Ícone do jogo para a bandeja e a barra de tarefas: o pequeno mundo numa moldura.

Desenhado à mão em 16x16 e 32x32 (cada tamanho com o seu desenho, para ler bem em 1x), e
o mesmo desenho do 32 refeito em proporção para 24x24 e 48x48, que a barra de tarefas e a
bandeja do Windows usam na escala de 150%. O de 256x256 é o de 32x32 ampliado 8 vezes sem
suavização. O .ico leva 16, 24, 32, 48, 64 (32x2), 128 (32x4) e 256, todos nítidos.
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


def icone_escalado(n):
    """O desenho do de 32, refeito em proporção para 24 e 48 (o .ico precisa dos dois: a
    barra de tarefas e a bandeja do Windows usam 24 e 48 na escala de 150%). Cada pixel é
    desenhado no tamanho final, sem ampliar o de 16 ou o de 32."""
    f = n / 32
    q, dentro = moldura(n, max(2, round(3 * f)))
    borda = 1 if n <= 24 else 3
    horizonte = round(19 * f)
    meio = horizonte - round(6 * f)
    for y in range(n):
        for x in range(n):
            if not dentro(x, y):
                continue
            if not dentro(x, y, borda):
                q[y][x] = 30 if not dentro(x, y, 1) else (9 if x + y < n else 8)
                continue
            q[y][x] = 1 if y < meio else 0 if y > meio + 1 else (0 if pont(x, y, 0.5) else 1)
    sx, sy, sr = 23 * f, 8 * f, 3.2 * f
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - sx, y - sy)
            if dentro(x, y, borda) and d <= sr:
                q[y][x] = 31 if d < sr - 1 else 22
    for x in range(n):
        topo = round(15 * f + 2 * f * abs(math.sin(x * 0.35 / f + 1.2)))
        for y in range(topo, horizonte + 2):
            if dentro(x, y, borda):
                q[y][x] = 2 if y > topo else 18
    for x in range(n):
        s = round(horizonte + 1 - 3 * f * math.sin((x - 2 * f) / (28 * f) * math.pi))
        for y in range(s, n):
            if not dentro(x, y, borda):
                continue
            d = y - s
            if d < max(1, round(f)):
                c = 15
            elif d < max(2, round(2 * f)):
                c = 14
            elif d < max(3, round(3 * f)):
                c = 13
            else:
                c = 9 if (x * 3 + y) % 7 else 10
                if y >= n - round(6 * f):
                    c = 11 if (x * 5 + y * 3) % 11 == 0 else 8
            q[y][x] = c
    # cabana de galhos
    base, cx = round(19 * f), 7 * f + 4 * f
    altura = round(8 * f)
    for r in range(altura):
        hw = r * 0.55 + 0.5
        for x in range(round(cx - hw), round(cx + hw) + 1):
            dx = x - cx
            c = 10 if dx < -hw + 1 else 8 if dx > hw - 1 else 14 if r < altura * 0.6 else 9
            if r >= altura * 0.6 and abs(dx + 0.5) < (r - altura * 0.6 + 1) * 0.6:
                c = 30
            q[base - altura + 1 + r][x] = c
    q[base - altura][round(cx) - 1] = 10
    q[base - altura][round(cx) + 1] = 9
    # fogueira e uma pessoa ao lado, em blocos de 1 px (24) ou com o miolo maior (48)
    fx, fy = round(18 * f), base - 1
    chama = [(0, -3, 20), (0, -2, 21), (-1, -1, 21), (0, -1, 22), (1, -1, 20), (-1, 0, 9), (0, 0, 31), (1, 0, 8)]
    if n >= 48:
        chama = [(0, -5, 20), (0, -4, 21), (1, -4, 20), (-1, -3, 21), (0, -3, 22), (1, -3, 21), (-1, -2, 21),
                 (0, -2, 31), (1, -2, 22), (2, -2, 20), (-2, -1, 20), (-1, -1, 22), (0, -1, 31), (1, -1, 22),
                 (2, -1, 21), (-2, 0, 9), (-1, 0, 10), (0, 0, 21), (1, 0, 9), (2, 0, 8)]
    for dx, dy, c in chama:
        q[fy + dy][fx + dx] = c
    px = round(21 * f) + (1 if n >= 48 else 0)
    corpo = [(-5, 30), (-4, 26), (-3, 28), (-2, 28), (-1, 25)]
    if n >= 48:
        corpo = [(-8, 30), (-7, 30), (-6, 26), (-5, 26), (-4, 28), (-3, 28), (-2, 28), (-1, 25), (0, 25)]
        for dy, c in corpo:
            q[base + dy][px] = c
            q[base + dy][px + 1] = c if c != 26 else 25
        q[base - 4][px + 2] = 26
    else:
        for dy, c in corpo:
            q[base + dy][px] = c
        q[base - 3][px + 1] = 26
    return q


def principal():
    p16, p32 = icone(16), icone(32)
    i16 = gravar(p16, AQUI / "icone_jogo_16.png", ampliar=False)
    i32 = gravar(p32, AQUI / "icone_jogo_32.png", ampliar=False)
    i24 = gravar(icone_escalado(24), AQUI / "icone_jogo_24.png", ampliar=False)
    i48 = gravar(icone_escalado(48), AQUI / "icone_jogo_48.png", ampliar=False)
    i256 = i32.resize((256, 256), Image.NEAREST)
    i256.save(AQUI / "icone_jogo_256.png")
    # cada tamanho do .ico vem do seu desenho (sem reamostrar): 16, 24, 32 e 48 desenhados, e
    # 64, 128 e 256 ampliados do 32 em escala inteira
    tamanhos = {16: i16, 24: i24, 32: i32, 48: i48, 64: i32.resize((64, 64), Image.NEAREST),
                128: i32.resize((128, 128), Image.NEAREST), 256: i256}
    i256.save(AQUI / "icone_jogo.ico", format="ICO", sizes=[(t, t) for t in tamanhos],
              append_images=[im for t, im in tamanhos.items() if t != 256])
    # amostra: os 4 tamanhos da barra e da bandeja, sobre um fundo claro e um escuro (as cores
    # mais claras e mais escuras da paleta, perto das barras clara e escura do Windows)
    amostra = Image.new("RGBA", (2 * 160, 60), (0, 0, 0, 0))
    from comum import PALETA
    for j, fundo in enumerate((PALETA[31] + (255,), PALETA[30] + (255,))):
        amostra.paste(fundo, (j * 160, 0, (j + 1) * 160, 60))
        x = j * 160 + 4
        for im in (i16, i24, i32, i48):
            amostra.alpha_composite(im, (x, 6))
            x += im.width + 6
    amostra.resize((amostra.width * 4, amostra.height * 4), Image.NEAREST).save(AQUI / "amostra_icone_4x.png")
    print("ícone do jogo: 16, 24, 32, 48, 256 e .ico com 16, 24, 32, 48, 64, 128 e 256")


if __name__ == "__main__":
    principal()

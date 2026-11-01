"""Medidas da auditoria 6 sobre as capturas de `capturar6.sh` (pasta dada no argumento):
cores fora da paleta, movimento da faixa da vila em 1,5 s e quadros com balão.
Uso: python arte_claude/auditoria/medir6.py <pasta das capturas>"""
from pathlib import Path
import sys

from PIL import Image

D = Path(sys.argv[1])
RAIZ = Path(__file__).resolve().parents[2]
PALETA = {tuple(int(l[i:i + 2], 16) for i in (0, 2, 4))
          for l in (RAIZ / "arte/paleta/paleta.hex").read_text().split() if len(l) == 6}
CREME = (245, 233, 203)


def quadros(nome):
    return sorted(D.glob(f"{nome}_[0-9]*.png"))


def fora_da_paleta(p):
    return sum(1 for c in set(Image.open(p).convert("RGB").getdata()) if c not in PALETA)


def movimento(a, b):  # pixels da faixa da vila (x 100-480, y 85-135) que mudam
    ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    return sum(1 for x in range(100, 480) for y in range(85, 135) if ia.getpixel((x, y)) != ib.getpixel((x, y)))


def tem_balao(p):  # a borda de cima e a de baixo do balão 6×5: 4 pixels creme entre dois que não são
    im = Image.open(p).convert("RGB")
    w = im.width
    for y in range(60, 140):
        for x in range(1, w - 5):
            if all(im.getpixel((x + i, y)) == CREME for i in range(4)) and im.getpixel((x - 1, y)) != CREME \
                    and im.getpixel((x + 4, y)) != CREME \
                    and all(im.getpixel((x + i, y + 3)) == CREME for i in range(4)) \
                    and im.getpixel((x + 1, y + 1)) != CREME:
                return True
    return False


todas = sorted(D.glob("*.png"))
ruins = [p.name for p in todas if fora_da_paleta(p)]
print(f"{len(todas)} capturas, {len(ruins)} com cor fora da paleta", ruins[:5])
for h in (6, 8, 10, 12, 14, 16, 18, 20, 22, 1):
    q = quadros(f"h1x_{h}")
    m = [movimento(q[i], q[i + 1]) for i in range(len(q) - 1)]
    print(f"movimento {h}h: {round(sum(m) / len(m)) if m else '-'}")
for nome in ("longa_tarde", "longa_madrugada", "cacada_longa", "m40_long_tarde", "m40_madrugada"):
    q = quadros(nome)
    print(f"{nome}: balão em {sum(tem_balao(p) for p in q)} de {len(q)}")
# a caçada longa começa às 12h, a 1,5 min de jogo por quadro: até o quadro 140 é 12h a 15h30,
# do 140 ao 200, 15h30 a 17h (a caçada sai às 15h37)
for nome in ("cacada_longa", "cacada13_longa"):
    q = quadros(nome)
    print(f"{nome}: balão em {sum(tem_balao(p) for p in q[:140])} de 140 (12h a 15h30) e "
          f"{sum(tem_balao(p) for p in q[140:200])} de 60 (15h30 a 17h)")

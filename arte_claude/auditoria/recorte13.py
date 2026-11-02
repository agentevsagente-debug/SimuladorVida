import sys
from PIL import Image, ImageDraw
nome, ini, fim, passo, x0, x1, y0, y1, esc = sys.argv[1], *map(int, sys.argv[2:10])
ids = list(range(ini, fim, passo))
def abrir(i):
    for f in (f"{nome}_{i:02d}.png", f"{nome}_{i:03d}.png"):
        try: return Image.open(f)
        except FileNotFoundError: pass
fr = [abrir(i).convert("RGB").crop((x0, y0, x1, y1)) for i in ids]
w, h = (x1 - x0) * esc, (y1 - y0) * esc
cols = 2
rows = (len(fr) + 1) // 2
out = Image.new("RGB", (cols * (w + 4), rows * (h + 4)), (255, 255, 255))
d = ImageDraw.Draw(out)
for k, f in enumerate(fr):
    X, Y = (k % 2) * (w + 4), (k // 2) * (h + 4)
    out.paste(f.resize((w, h), Image.NEAREST), (X, Y))
    d.text((X + 3, Y + 2), str(ids[k]), fill=(255, 255, 0))
out.save(f"rec_{nome}_{ini}.png")

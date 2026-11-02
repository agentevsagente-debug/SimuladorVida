import sys
from PIL import Image
nome, passo, esc = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
ids = list(range(0, 105, passo))
fr = [Image.open(f"{nome}_{i:02d}.png") if i < 100 else Image.open(f"{nome}_{i:03d}.png") for i in ids]
w, h = fr[0].size
cols = 2
rows = (len(fr) + 1) // 2
out = Image.new("RGB", (cols * w * esc, rows * h * esc), (255, 255, 255))
for k, f in enumerate(fr):
    out.paste(f.convert("RGB").resize((w * esc, h * esc), Image.NEAREST), ((k % 2) * w * esc, (k // 2) * h * esc))
out.save(f"folha_{nome}.png")
print(ids)

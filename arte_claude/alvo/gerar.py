"""Gera as três cenas-alvo (480x160) e as versões ampliadas 4x por vizinho mais próximo."""
from pathlib import Path

from PIL import Image

from cena import render

AQUI = Path(__file__).resolve().parent

for hora in ("entardecer", "dia", "noite"):
    img = render(hora)
    img.save(AQUI / f"alvo_{hora}.png")
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / f"alvo_{hora}_4x.png")
    print("ok", hora)

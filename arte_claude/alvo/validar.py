"""Confere tamanho, paleta e opacidade das cenas geradas."""
from pathlib import Path

from PIL import Image

from cena import carregar_paleta

AQUI = Path(__file__).resolve().parent
paleta = set(carregar_paleta())
erros = 0
for hora in ("entardecer", "dia", "noite"):
    for suf, tam in (("", (480, 160)), ("_4x", (1920, 640))):
        img = Image.open(AQUI / f"alvo_{hora}{suf}.png").convert("RGBA")
        fora = {px[:3] for px in list(img.getdata()) if px[:3] not in paleta}
        transl = sum(1 for px in list(img.getdata()) if px[3] != 255)
        usadas = len({px[:3] for px in list(img.getdata())})
        ok = img.size == tam and not fora and not transl
        erros += not ok
        print(f"alvo_{hora}{suf}: {img.size} cores={usadas} fora_da_paleta={len(fora)} "
              f"nao_opacos={transl} {'OK' if ok else 'ERRO'}")
raise SystemExit(1 if erros else 0)

"""Confere todas as peças: só cores da paleta, cada pixel opaco ou totalmente transparente,
e tamanhos na grade (terreno 8x8, habitantes 8x12 ou 6x8 por quadro, estágio 1 em múltiplos de 8).
Os mapas de luz são dados em tons de cinza e ficam fora da regra da paleta."""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))
from comum import PALETA  # noqa: E402

paleta = set(PALETA)
erros = []
total = 0
for f in sorted(AQUI.rglob("*.png")):
    if "_4x" in f.parts:
        continue
    total += 1
    rel = f.relative_to(AQUI).as_posix()
    img = Image.open(f)
    if f.stem.startswith("luz_fogueira"):
        if img.mode != "L" or set(img.getdata()) - {0, 127, 255}:
            erros.append(f"{rel}: mapa de luz deve ter só 0, 127 e 255")
        continue
    img = img.convert("RGBA")
    px = list(img.getdata())
    if any(a not in (0, 255) for *_, a in px):
        erros.append(f"{rel}: semitransparência")
    if any(a == 255 and (r, g, b) not in paleta for r, g, b, a in px):
        erros.append(f"{rel}: cor fora da paleta")
    w, h = img.size
    pasta = f.parent.name
    nq = int(f.stem.rsplit("_", 1)[1][:-1]) if f.stem[-1] == "q" and f.stem.rsplit("_", 1)[1][:-1].isdigit() else 1
    if pasta == "terreno" and f.stem not in ("terreno_teste", "blocos_prancha") and (w != 8 * nq or h != 8):
        erros.append(f"{rel}: bloco deve ser 8x8 por quadro ({w}x{h})")
    if pasta == "habitantes" and f.stem != "variacoes_pele_roupa":
        qw = w // nq
        if (qw, h) not in ((8, 12), (6, 8)) or w % nq:
            erros.append(f"{rel}: quadro {qw}x{h} fora do padrão")
    if pasta in ("icones_12", "icones_8") and (w, h) != ((12, 12) if pasta == "icones_12" else (8, 8)):
        erros.append(f"{rel}: ícone {w}x{h} fora do tamanho")
    if pasta in ("efeitos", "sinais") and not f.stem.startswith("amostra"):
        fim = f.stem.rsplit("_", 1)[1]
        n = int(fim[:-1]) if fim[-1] in "qv" and fim[:-1].isdigit() else 1
        if w % n or (w // n) % 4 or h % 4:
            erros.append(f"{rel}: quadro {w // n}x{h} não é múltiplo de 4")
    if pasta == "estagio1" and (w % (8 * nq) or h % 8):
        erros.append(f"{rel}: tamanho {w}x{h} não é múltiplo de 8")
print(f"{total} PNGs conferidos")
for e in erros:
    print("ERRO", e)
raise SystemExit(1 if erros else 0)

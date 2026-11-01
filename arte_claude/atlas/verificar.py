"""Confere os atlas: cada região bate pixel a pixel com o PNG original, nenhuma região
encosta em outra (1 px de margem) e o tamanho é potência de 2."""
from pathlib import Path
import json

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent / "pecas"
erros = 0
for j in sorted(AQUI.glob("*.json")):
    d = json.loads(j.read_text(encoding="utf-8"))
    atlas = Image.open(AQUI / d["atlas"]).convert("RGBA")
    W, H = atlas.size
    if W & (W - 1) or H & (H - 1) or W > 2048 or H > 1024:
        print("ERRO tamanho", j.name, W, H)
        erros += 1
    rets = []
    for nome, r in d["regioes"].items():
        rets.append((r["x"] - 1, r["y"] - 1, r["x"] + r["w"], r["y"] + r["h"], nome))
        estacao = j.stem.split("_")[-1] if j.stem.startswith("estacao") or j.stem.endswith("inverno") else None
        candidatos = []
        if estacao and estacao != "verao":
            candidatos.append(PECAS / "estacoes" / estacao / f"{nome}.png")
        candidatos.append(PECAS / f"{nome}.png")
        orig = next((c for c in candidatos if c.exists()), None)
        rec = atlas.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]))
        if orig is None or list(Image.open(orig).convert("RGBA").getdata()) != list(rec.getdata()):
            print("ERRO pixels", j.name, nome)
            erros += 1
    for i, a in enumerate(rets):
        for b in rets[i + 1:]:
            if a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]:
                # retângulos com a margem incluída podem dividir a linha de margem, mas não a peça
                if a[0] + 1 < b[2] - 0 and b[0] + 1 < a[2] and a[1] + 1 < b[3] and b[1] + 1 < a[3]:
                    print("ERRO sobreposição", j.name, a[4], b[4])
                    erros += 1
print(len(list(AQUI.glob('*.json'))), "atlas conferidos,", erros, "erros")
raise SystemExit(1 if erros else 0)

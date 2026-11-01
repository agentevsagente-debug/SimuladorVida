"""Recria `capturas3b/` (fora do git): copia os GIFs da sessão B do commit 357b511 e extrai
cada quadro em PNG. Rode da raiz do repositório: `python arte_claude/auditoria/extrair3b.py`."""
from pathlib import Path
import io
import subprocess

from PIL import Image

COMMIT = "357b511"
GIFS = ["dia-inteiro-50x-inverno", "dia-inteiro-50x", "estacao-inverno", "estacao-outono",
        "estacao-primavera", "estacao-verao"]
D = Path(__file__).resolve().parent / "capturas3b"
D.mkdir(exist_ok=True)
for g in GIFS:
    dados = subprocess.run(["git", "show", f"{COMMIT}:jogo/capturas/{g}.gif"], capture_output=True, check=True).stdout
    im = Image.open(io.BytesIO(dados))
    for i in range(im.n_frames):
        im.seek(i)                      # seek compõe o quadro inteiro (o GIF guarda só o que muda)
        im.convert("RGB").save(D / f"{g}_{i:03d}.png")
dados = subprocess.run(["git", "show", f"{COMMIT}:jogo/capturas/luzes-inverno-pomar.png"], capture_output=True,
                       check=True).stdout
(D / "luzes-inverno-pomar.png").write_bytes(dados)
print("quadros em", D)

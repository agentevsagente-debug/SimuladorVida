"""Teste: o céu nunca vira uma grade de pontos.

Captura a vista de meia em meia hora, o dia inteiro, com e sem chuva, e conta
nas 60 linhas de cima (o céu) os pixels isolados: os que têm os 4 vizinhos
iguais entre si e diferentes dele. É a assinatura de um pontilhado regular. A
cena-alvo da arte também tem alguns (estrelas e o pontilhado do degradê). O
limite de cada hora é o maior número da cena-alvo nos dois estados daquela
hora (os mesmos de vista.gd, estado_da_hora) mais o que cabe na faixa da frente
de transição (2 linhas de pontilhado: 960 pixels).

Uso: python -I ferramentas/ceu_sem_grade.py   (da pasta jogo/)
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

JOGO = Path(__file__).resolve().parent.parent
ALVO = JOGO.parent / "arte_claude" / "alvo"
GODOT = os.environ.get("GODOT", str(Path(os.environ["LOCALAPPDATA"]) / "Microsoft/WinGet/Packages/"
                       "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"))
LINHAS = 60


def isolados(img):
    px = img.convert("RGB").load()
    n = 0
    for y in range(1, LINHAS - 1):
        for x in range(1, img.width - 1):
            v = [px[x - 1, y], px[x + 1, y], px[x, y - 1], px[x, y + 1]]
            if v.count(v[0]) == 4 and px[x, y] != v[0]:
                n += 1
    return n


## Os estados de cada faixa de horas, como em vista.gd (estado_da_hora).
FAIXAS = [(0, 5, "noite", "noite"), (5, 6.5, "noite", "entardecer"), (6.5, 8, "entardecer", "dia"),
          (8, 17, "dia", "dia"), (17, 18, "dia", "entardecer"), (18, 19, "entardecer", "entardecer"),
          (19, 20, "entardecer", "noite"), (20, 24, "noite", "noite")]


def estados(h):
    for ini, fim, a, b in FAIXAS:
        if ini <= h < fim:
            return a, b


def capturar(hora, extra, pasta):
    arq = Path(pasta) / f"ceu_{hora}_{'_'.join(extra) or 'limpo'}.png".replace("--", "").replace("=", "")
    subprocess.run([GODOT, "--path", str(JOGO), "--", "--sem-config", "--escala=2", "--pos=100,100", "--semente=7",
                    f"--hora={hora}", "--congelar", "--capturar-apos=2", f"--capturar={arq}"] + extra,
                   capture_output=True, timeout=90)
    return Image.open(arq) if arq.exists() else None


def principal():
    base = {h: isolados(Image.open(ALVO / f"alvo_{h}.png")) for h in ("dia", "entardecer", "noite")}
    print("cena-alvo, pixels isolados no céu:", base)
    falhas = 0
    with tempfile.TemporaryDirectory() as pasta:
        for extra in ([], ["--efeito=chuva"]):
            for meia in range(48):
                hora = f"{meia / 2:g}"
                img = capturar(hora, extra, pasta)
                if img is None:
                    print(f"{hora:>5}h {' '.join(extra):14} FALHA: sem captura")
                    falhas += 1
                    continue
                n = isolados(img)
                limite = max(base[e] for e in estados(meia / 2)) + 960
                if extra:  # as nuvens de chuva da arte têm pontilhado próprio, e as gotas são pixels soltos
                    limite += 600
                ok = n <= limite
                falhas += 0 if ok else 1
                print(f"{hora:>5}h {' '.join(extra):14} {n:5d} isolados (limite {limite:5d})  {'OK' if ok else 'GRADE'}")
    print("resultado:", "OK" if falhas == 0 else f"{falhas} falhas")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(principal())

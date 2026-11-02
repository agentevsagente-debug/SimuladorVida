"""A prévia de 60 s: um dia passando, com os laços se trocando e alguns acontecimentos, lida dos
.ogg já gerados (como o jogo vai tocar). Uso: python previa.py (depois de gerar_sons.py)."""
from pathlib import Path
import sys

import numpy as np
import soundfile as sf

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))

from sintese import SR, gravar, medir  # noqa: E402

DUR = 60.0

# laço: (início, fim, subida, descida, volume em dB), em segundos
LACOS = {
    "vento": [(0, 60, 0.5, 2, -3)],
    "passaros": [(1, 27, 4, 3, 0)],
    "lago": [(6, 30, 4, 4, -2)],
    "vila": [(11, 29, 4, 3, -1), (37, 50, 3, 4, -3)],
    "chuva": [(25, 41, 3, 4, 0)],
    "tempestade": [(30, 38, 2, 3, 0)],
    "fogo": [(36, 60, 4, 2, -1)],
    "grilos": [(45, 60, 4, 2, 0)],
}
# acontecimento: (momento, nome, volume em dB)
EVENTOS = [
    (2.5, "galo", 0), (14.0, "sino_templo", -2), (18.5, "arremesso", 0), (18.85, "lanca_cravar", 0),
    (20.5, "grito_cacada", -1), (23.0, "fartura", -1), (31.5, "trovao_2", 0), (35.0, "trovao_1", 0),
    (41.5, "choro_bebe", 0), (44.0, "milagre_sino", -2), (50.5, "coruja", 0), (55.0, "coruja", -4),
]


def ler(pasta, nome):
    x, sr = sf.read(str(AQUI / pasta / f"{nome}.ogg"), dtype="float32")
    assert sr == SR
    return x.astype(np.float64)


def principal():
    n = int(DUR * SR)
    mix = np.zeros(n)
    t = np.arange(n) / SR
    for nome, trechos in LACOS.items():
        laco = ler("ambiente", nome)
        cheio = np.tile(laco, n // laco.size + 1)[:n]
        for ini, fim, sobe, desce, vol in trechos:
            g = np.clip((t - ini) / sobe, 0, 1) * np.clip((fim - t) / desce, 0, 1)
            mix += cheio * np.sin(0.5 * np.pi * g) * 10 ** (vol / 20)
    for momento, nome, vol in EVENTOS:
        x = ler("eventos", nome) * 10 ** (vol / 20)
        k = int(momento * SR)
        m = min(x.size, n - k)
        mix[k:k + m] += x[:m]
    mix *= np.clip(t / 0.5, 0, 1) * np.clip((DUR - t) / 2.0, 0, 1)
    gravar(AQUI / "previa_um_dia_60s.ogg", mix)
    rms, pico = medir(mix)
    print(f"previa_um_dia_60s.ogg rms={rms:.1f} pico={pico:.1f} {(AQUI / 'previa_um_dia_60s.ogg').stat().st_size / 1024:.0f}KB")


if __name__ == "__main__":
    principal()

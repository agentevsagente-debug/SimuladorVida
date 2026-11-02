"""Gera todos os sons (ambiente/ e eventos/) em Ogg Vorbis e imprime a tabela de medidas
(duração, RMS, pico, tamanho) que vai para o LEIA-ME. Uso: python gerar_sons.py"""
from pathlib import Path
import sys

import numpy as np

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))

import ambiente  # noqa: E402
import eventos  # noqa: E402
from sintese import SR, gravar, medir  # noqa: E402


def emenda(x):
    """O salto entre a última amostra e a primeira, comparado com o salto típico entre
    amostras vizinhas: perto de 1 = emenda inaudível."""
    d = np.abs(np.diff(x))
    return abs(x[0] - x[-1]) / (np.percentile(d, 99) + 1e-12)


def principal():
    linhas = []
    total = 0
    for pasta, sons, laco in (("ambiente", ambiente.gerar(), True), ("eventos", eventos.gerar(), False)):
        (AQUI / pasta).mkdir(exist_ok=True)
        for nome, x in sons.items():
            arq = AQUI / pasta / f"{nome}.ogg"
            gravar(arq, x)
            kb = arq.stat().st_size / 1024
            total += arq.stat().st_size
            rms, pico = medir(x)
            extra = f" emenda={emenda(x):.2f}" if laco else ""
            linhas.append(f"{pasta}/{nome}.ogg {x.size / SR:.1f}s rms={rms:.1f} pico={pico:.1f} {kb:.0f}KB{extra}")
    print("\n".join(linhas))
    print(f"total {total / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    principal()

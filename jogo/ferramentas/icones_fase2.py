"""Desenha os ícones da fase 2 que a arte ainda não tem: estante e criar povo.

Seguem o estilo dos ícones de arte_claude/pecas/interface/ (contorno 12, só cores
da paleta) e ficam em jogo/arte/interface/icones_12 e icones_8, com o mesmo nome
que a sessão de arte usaria; se ela entregar os seus, sincronizar_arte.py os troca.

Uso: python -I jogo/ferramentas/icones_fase2.py   (da raiz do repositório)
"""
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
PALETA = [l.strip() for l in (RAIZ / "arte" / "paleta" / "paleta.hex").read_text().split()]
DESTINO = RAIZ / "jogo" / "arte" / "interface"

# "." transparente; números separados por espaço são índices da paleta
ICONES = {
    "estante": {
        12: """
. . . . . . . . . . . .
. . 12 12 . . . . . . . .
. 12 20 20 12 12 12 . . . . .
. 12 22 22 12 18 18 12 12 12 . .
. 12 20 20 12 22 22 12 14 14 12 .
. 12 20 20 12 18 18 12 14 14 12 .
. 12 22 22 12 18 18 12 22 22 12 .
. 12 20 20 12 22 22 12 14 14 12 .
. 12 20 20 12 18 18 12 14 14 12 .
12 9 9 9 9 9 9 9 9 9 9 12
. 12 10 . . . . . . 10 12 .
. . . . . . . . . . . .""",
        8: """
. 12 12 . . . . .
12 20 20 12 12 12 . .
12 22 22 12 18 12 12 12
12 20 20 12 22 12 14 12
12 20 20 12 18 12 22 12
12 20 20 12 18 12 14 12
12 9 9 9 9 9 9 12
. 10 . . . . 10 .""",
    },
    "criar_povo": {
        12: """
. . . . . . . . 22 . . .
. . . . . . . 22 31 22 . .
. . . . . . . . 22 . . .
. . 15 . . . . . 25 . . .
. 15 14 . 15 . . 12 28 12 . .
. . 14 15 14 . . 28 28 28 . .
. . . 14 . . . . 28 . . .
. . . 14 . . . 12 . 12 . .
. . . 14 . . . 12 . 12 . .
9 9 9 9 9 9 9 9 9 9 9 9
. 10 10 10 10 10 10 10 10 10 10 .
. . . . . . . . . . . .""",
        8: """
. . . . . . 22 .
. 15 . . . . 25 .
15 14 15 . . 28 28 28
. 14 . . . . 28 .
. 14 . . . 12 . 12
. 14 . . . 12 . 12
9 9 9 9 9 9 9 9
. 10 10 10 10 10 10 .""",
    },
}


def desenhar(texto, lado):
    linhas = [l.split() for l in texto.strip().splitlines()]
    assert len(linhas) == lado and all(len(l) == lado for l in linhas), (lado, [len(l) for l in linhas])
    img = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    for y, linha in enumerate(linhas):
        for x, c in enumerate(linha):
            if c != ".":
                h = PALETA[int(c)]
                img.putpixel((x, y), (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255))
    return img


def principal():
    for nome, tamanhos in ICONES.items():
        for lado, texto in tamanhos.items():
            desenhar(texto, lado).save(DESTINO / f"icones_{lado}" / f"{nome}.png")
    print("ícones:", ", ".join(ICONES))


if __name__ == "__main__":
    principal()

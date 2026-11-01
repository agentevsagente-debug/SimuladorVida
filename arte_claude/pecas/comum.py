"""Base comum das peças modulares: paleta, tela de sprite com transparência e gravação.

As peças reaproveitam as funções de desenho da cena-alvo (`arte_claude/alvo/cena.py`),
para que cada planta, cabana e pedra tenha exatamente o tratamento da cena.
"""
from pathlib import Path
import sys

from PIL import Image

PECAS = Path(__file__).resolve().parent
sys.path.insert(0, str(PECAS.parent / "alvo"))

import cena  # noqa: E402  (a cena-alvo é a fonte do estilo)

PALETA = cena.carregar_paleta()
pont = cena.pont
clamp = cena.clamp
MARGEM = 16   # múltiplo de 4, para o pontilhado Bayer não mudar de fase


class Folha:
    """Tela de sprite em índices da paleta; None é transparente.

    Desenha-se com coordenadas do sprite (0..w-1, 0..h-1). Internamente há uma margem
    de 16 px para as funções da cena poderem ler e escrever fora do quadro sem erro;
    `recortar()` confere que nada ficou fora.
    """

    def __init__(self, w, h):
        self.w, self.h = w, h
        self._p = [[None] * (w + 2 * MARGEM) for _ in range(h + 2 * MARGEM)]
        self.tag = [[0] * (w + 2 * MARGEM) for _ in range(h + 2 * MARGEM)]
        self.lado = [[0] * (w + 2 * MARGEM) for _ in range(h + 2 * MARGEM)]
        self.p = self._p

    # As funções da cena trabalham em coordenadas absolutas; a Folha desloca tudo pela margem.
    def put(self, x, y, c, tag=None, lado=0):
        x, y = x + MARGEM, y + MARGEM
        if 0 <= y < len(self._p) and 0 <= x < len(self._p[0]):
            self._p[y][x] = c

    def get(self, x, y):
        x, y = x + MARGEM, y + MARGEM
        if 0 <= y < len(self._p) and 0 <= x < len(self._p[0]):
            return self._p[y][x]
        return None

    def recortar(self, permitir_fora=False):
        fora = sum(1 for y, linha in enumerate(self._p) for x, c in enumerate(linha)
                   if c is not None and not (MARGEM <= x < MARGEM + self.w and MARGEM <= y < MARGEM + self.h))
        if fora and not permitir_fora:
            raise ValueError(f"{fora} pixels fora do quadro {self.w}x{self.h}")
        return [linha[MARGEM:MARGEM + self.w] for linha in self._p[MARGEM:MARGEM + self.h]]


class Deslocada:
    """Adaptador: as funções da cena escrevem em t.p[y][x] e t.put(x, y).
    Para elas, a Folha se apresenta com a origem já deslocada pela margem."""

    def __init__(self, folha):
        self.f = folha
        self.p = _Linhas(folha)
        self.tag = _Linhas(folha, folha.tag)

    def put(self, x, y, c, tag=None, lado=0):
        self.f.put(x, y, c)

    def get(self, x, y):
        return self.f.get(x, y)


class _Linhas:
    def __init__(self, folha, base=None):
        self.f, self.base = folha, base if base is not None else folha._p

    def __getitem__(self, y):
        return _Linha(self.base[y + MARGEM])


class _Linha:
    def __init__(self, linha):
        self.l = linha

    def __getitem__(self, x):
        return self.l[x + MARGEM]

    def __setitem__(self, x, v):
        self.l[x + MARGEM] = v


def para_imagem(pixels):
    h, w = len(pixels), len(pixels[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.putdata([(0, 0, 0, 0) if c is None else PALETA[c] + (255,) for linha in pixels for c in linha])
    return img


def folha_quadros(quadros):
    """Junta quadros do mesmo tamanho numa folha horizontal, sem espaço entre eles."""
    w, h = len(quadros[0][0]), len(quadros[0])
    out = [[None] * (w * len(quadros)) for _ in range(h)]
    for i, q in enumerate(quadros):
        assert len(q) == h and len(q[0]) == w
        for y in range(h):
            out[y][i * w:(i + 1) * w] = q[y]
    return out


def gravar(pixels, caminho, ampliar=True):
    caminho = Path(caminho)
    caminho.parent.mkdir(parents=True, exist_ok=True)
    img = para_imagem(pixels) if isinstance(pixels, list) else pixels
    img.save(caminho)
    if ampliar:
        (caminho.parent / "_4x").mkdir(exist_ok=True)
        img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(
            caminho.parent / "_4x" / (caminho.stem + "_4x.png"))
    return img


def trocar(pixels, mapa):
    """Troca de cores simultânea (como o motor fará para pele, cabelo e roupa)."""
    return [[mapa.get(c, c) if c is not None else None for c in linha] for linha in pixels]


def espelhar(pixels):
    return [linha[::-1] for linha in pixels]

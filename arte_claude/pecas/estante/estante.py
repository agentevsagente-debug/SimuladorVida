"""Tela da estante de crônicas: fundo de madeira, prateleira, lombadas de livro (uma para
cada era ou mundo, com uma etiqueta onde o motor escreve o nome) e o livro aberto, no
estilo do pergaminho da crônica.
"""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(PECAS / "interface"))

from comum import PALETA, folha_quadros, gravar, para_imagem, pont  # noqa: E402
import interface  # noqa: E402

CORES_LIVRO = [(20, 23), (18, 17), (14, 13), (10, 9), (29, 5), (24, 23)]


def novo(w, h):
    return [[None] * w for _ in range(h)]


def fundo():
    """Fundo da estante, 16x16, repete nas duas direções: tábuas verticais escuras."""
    q = novo(16, 16)
    for y in range(16):
        for x in range(16):
            c = 8
            if x % 8 == 0:
                c = 30
            elif x % 8 == 1:
                c = 9 if y % 5 else 8
            elif (x * 3 + y * 7) % 23 == 0:
                c = 30
            q[y][x] = c
    return q


def prateleira():
    """Tábua da prateleira, 16x6, repete na horizontal. Os livros ficam em cima da linha 0."""
    q = novo(16, 6)
    for x in range(16):
        q[0][x] = 10
        q[1][x] = 10 if x % 7 else 9
        q[2][x] = 9
        q[3][x] = 8
        q[4][x] = 30
        q[5][x] = 30 if pont(x, 5, 0.5) else None
    return q


def lombada(claro, escuro):
    """Lombada 12x64: couro com faixas douradas e uma etiqueta clara (linhas 8 a 55, colunas
    2 a 9) onde o motor escreve o nome da era em maiúsculas, girado 90° (lido de baixo
    para cima)."""
    q = novo(12, 64)
    for y in range(64):
        for x in range(12):
            c = claro
            if x == 0 or y in (0, 63):
                c = escuro
            elif x == 11:
                c = 30
            elif x == 1:
                c = claro if y % 6 else escuro
            elif x >= 9:
                c = escuro
            q[y][x] = c
    for y in (3, 4, 59, 60):
        for x in range(1, 11):
            q[y][x] = 22 if y in (3, 59) else 21
    for y in range(8, 56):
        for x in range(2, 10):
            borda = y in (8, 55) or x in (2, 9)
            q[y][x] = 9 if borda else 12
    return q


def livro_aberto():
    """Livro aberto (256x144): capa de couro, duas páginas de pergaminho, sombra na lombada,
    bordas de páginas empilhadas e uma fita marcadora. Área de texto: página da esquerda
    x 14..118, da direita x 138..242, y 12..130 (17 caracteres por linha, 10 linhas)."""
    W, H = 256, 144
    q = novo(W, H)
    meio = W // 2
    for y in range(H):
        for x in range(W):
            borda = min(x, y, W - 1 - x, H - 1 - y)
            canto = min(x, W - 1 - x) + min(y, H - 1 - y)
            if canto <= 1:
                continue
            if borda < 4:                                     # capa
                q[y][x] = 30 if borda == 0 else 9 if borda == 1 and (x < W // 2) else 8
                continue
            if borda < 7 and y > 6:                           # bordas das folhas empilhadas
                q[y][x] = 12 if (y + x) % 2 and borda % 2 else 11
                continue
            d = abs(x - meio + 0.5)
            if d < 1.5:
                c = 10
            elif d < 5:
                c = 11 if pont(x, y, 1 - (d - 1.5) / 3.5) else 12
            else:
                c = 12
                if (x * 7 + y * 3) % 41 == 0:
                    c = 31
            q[y][x] = c
    # fita marcadora
    for y in range(H - 8, H):
        for x in (meio + 30, meio + 31):
            q[y][x] = 20 if x == meio + 30 else 23
    q[H - 1][meio + 30] = None
    return q


def texto_img(texto, cor="escura"):
    folha, chars = interface.fonte({"escura": 8, "clara": 31, "dourada": 22}[cor])
    fimg = para_imagem(folha)
    larg = sum(av for cid, *_r, av in chars if chr(cid) in texto) + len(texto) * 6
    img = Image.new("RGBA", (max(larg, 1), 11), (0, 0, 0, 0))
    fim = interface.escrever(img, texto, 0, 0, chars, fimg)
    return img.crop((0, 0, fim, 11))


def amostras(livros):
    W, H = 480, 160
    tela = Image.new("RGBA", (W, H), PALETA[30] + (255,))
    f = para_imagem(fundo())
    for y in range(0, H, 16):
        for x in range(0, W, 16):
            tela.alpha_composite(f, (x, y))
    pr = para_imagem(prateleira())
    # a etiqueta cabe até 7 caracteres (46 px); nomes maiores o motor abrevia
    eras = ["ARDEM", "TORIL", "MUNDO 2", "A SECA", "BRONZE", "ÚLTIMOS",
            "ESCRITA", "MUNDO 3", "DILÚVIO", "MOINHO", "PEDRAS", "MUNDO 4"]
    for li, base in enumerate((72, 150)):
        for x in range(0, W, 16):
            tela.alpha_composite(pr, (x, base))
        x = 40 + li * 20
        for i in range(6):
            n = li * 6 + i
            liv = para_imagem(livros[n % 6])
            tela.alpha_composite(liv, (x, base - 64))
            # nome em maiúsculas, linhas 1-9 do glifo, girado 90° e centrado na etiqueta
            rotulo = texto_img(eras[n])
            rotulo = rotulo.crop((0, 1, rotulo.width, 9)).rotate(90, expand=True)
            topo = base - 64 + 9 + max(0, (46 - rotulo.height) // 2)
            tela.alpha_composite(rotulo, (x + 2, topo))
            x += 14 + (n % 3) * 2
        # objetos na prateleira: um rolo e uma tabuleta
        tela.alpha_composite(Image.open(PECAS / "estagio5" / "tabuletas_4v.png").crop((8, 0, 16, 8)), (x + 6, base - 8))
    tela.save(AQUI / "amostra_tela_estante.png")
    tela.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_tela_estante_4x.png")

    tela2 = Image.new("RGBA", (W, H), PALETA[30] + (255,))
    for y in range(0, H, 16):
        for x in range(0, W, 16):
            tela2.alpha_composite(f, (x, y))
    lv = para_imagem(livro_aberto())
    ox, oy = (W - lv.width) // 2, (H - lv.height) // 2
    tela2.alpha_composite(lv, (ox, oy))
    esquerda = ["Era de Ardem", "", "Ano 1. O povo", "chegou à praia com", "fome e frio. Iara",
                "acendeu o fogo.", "", "Ano 7. A seca levou", "a colheita; rezaram", "ao Que Rega."]
    direita = ["Ano 9. A chuva", "voltou na noite da", "festa: milagre.", "", "Ano 12. Nasceu",
               "Toril, neto de Iara,", "que um dia ergueria", "o primeiro altar."]
    for i, t in enumerate(esquerda):
        if t:
            tela2.alpha_composite(texto_img(t, "dourada" if i == 0 else "escura"), (ox + 14, oy + 12 + i * 11))
    for i, t in enumerate(direita):
        tela2.alpha_composite(texto_img(t), (ox + 138, oy + 12 + i * 11))
    tela2.save(AQUI / "amostra_tela_livro.png")
    tela2.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_tela_livro_4x.png")


def principal():
    livros = [lombada(c, e) for c, e in CORES_LIVRO]
    gravar(fundo(), AQUI / "estante_fundo.png")
    gravar(prateleira(), AQUI / "prateleira.png")
    gravar(folha_quadros(livros), AQUI / "livro_lombada_6v.png")
    gravar(livro_aberto(), AQUI / "livro_aberto.png")
    amostras([[l[:] for l in liv] for liv in livros])
    print("estante: fundo, prateleira, 6 lombadas, livro aberto")


if __name__ == "__main__":
    principal()

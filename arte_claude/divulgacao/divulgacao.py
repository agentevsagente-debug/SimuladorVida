"""Imagens de apresentação do jogo (vitrine no GitHub), feitas só com a arte do jogo.

- `logo_pequeno.png` e `logo_grande.png`: "Simulador de vida" na fonte de título (a fonte
  5x7 do jogo, ampliada em blocos inteiros, com degradê dourado, contorno e sombra);
- `capa.png` (1280x640): a moldura do jogo sobre uma área de trabalho estilizada, com o
  mundo ao entardecer. Montada em 640x320 e ampliada 2x por vizinho mais próximo;
- `destaque_1_prece.png` a `destaque_4_cronica.png` (960x320): cenas de 480x160 ampliadas
  2x, cada uma com uma frase embutida em pixel art.

Só cores da paleta; nada semitransparente, a não ser o fundo transparente dos logos.
"""
from pathlib import Path
import json
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent / "pecas"
for sub in ("", "interface", "montagem", "terreno", "cenas", "habitantes"):
    sys.path.insert(0, str(PECAS / sub))

from comum import PALETA, para_imagem, trocar  # noqa: E402
import interface  # noqa: E402
import montar  # noqa: E402
import terreno  # noqa: E402
import cenas  # noqa: E402
from habitantes import troca  # noqa: E402

W, H = 480, 160
COR = lambda i: PALETA[i] + (255,)  # noqa: E731


# ---------------------------------------------------------------- texto

def texto(t, escala=2, fill=(31,), contorno=30, sombra=8):
    """Texto na fonte do jogo, ampliado em blocos de `escala` px. `fill` é uma lista de
    cores de cima para baixo (degradê por faixas das 7 linhas da maiúscula)."""
    glifos = [interface.montar_glifo(ch) for ch in t]
    larg = sum(len(g[0]) + 1 for g in glifos) - 1
    base = [[False] * larg for _ in range(interface.ALT)]
    x = 0
    for ch, g in zip(t, glifos):
        for y in range(interface.ALT):
            for i in range(len(g[0])):
                if g[y][i] == "#":
                    base[y][x + i] = True
        x += len(g[0]) + 1 if ch != " " else 3
    # recorta as linhas vazias de cima e de baixo
    linhas = [y for y in range(interface.ALT) if any(base[y])]
    y0, y1 = linhas[0], linhas[-1]
    base = base[y0:y1 + 1]
    h, w = len(base) * escala, larg * escala
    m = 2  # margem para o contorno e a sombra
    img = Image.new("RGBA", (w + 2 * m + 1, h + 2 * m + 1), (0, 0, 0, 0))
    cheio = lambda X, Y: 0 <= Y // escala < len(base) and 0 <= X // escala < larg and base[Y // escala][X // escala]  # noqa: E731
    px = img.load()
    for Y in range(-m, h + m + 1):
        for X in range(-m, w + m + 1):
            ox, oy = X + m, Y + m
            if cheio(X, Y):
                faixa = min(len(fill) - 1, (Y // escala) * len(fill) // max(1, len(base)))
                px[ox, oy] = COR(fill[faixa])
            elif contorno is not None and any(cheio(X + dx, Y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                px[ox, oy] = COR(contorno)
            elif sombra is not None and (cheio(X - 2, Y - 2) or cheio(X - 1, Y - 2) or cheio(X - 2, Y - 1)):
                px[ox, oy] = COR(sombra)
    return img


def logo(escala, com_icone):
    titulo = texto("Simulador de vida", escala, fill=(31, 22, 22, 21, 21, 20, 20), contorno=30, sombra=8)
    if not com_icone:
        return titulo
    icone = Image.open(PECAS / "interface" / "icone_jogo_32.png")
    w = icone.width + 6 + titulo.width
    h = max(icone.height, titulo.height)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.alpha_composite(icone, (0, (h - icone.height) // 2))
    img.alpha_composite(titulo, (icone.width + 6, (h - titulo.height) // 2))
    return img


def legenda(img, frase, x, y, escala=2):
    """Frase sobre uma caixa escura (a caixa da dica do jogo, em 9 partes)."""
    t = texto(frase, escala, fill=(31, 31, 22), contorno=30, sombra=None)
    caixa = interface.nove(interface.caixa_dica(), 12, 4, t.width + 10, t.height + 8)
    img.alpha_composite(para_imagem(caixa), (x, y))
    img.alpha_composite(t, (x + 5, y + 4))


# ---------------------------------------------------------------- cenas

def base_mundo(hora="dia", ceu=None, manter=lambda item: True, estacao=None):
    """Céu, fundo, terreno, reflexo e a vegetação da cena-alvo (sem as pessoas)."""
    ler = montar.ler
    c = montar.Cena()
    c.camada(ler(PECAS / "montagem" / (ceu or f"ceu_{hora}.png")))
    for nome in ("montanhas_longe", "montanhas_perto", "mata_distante"):
        c.camada(montar.camada_fundo(nome, hora, estacao))
    blocos = montar.ler_pasta("terreno", estacao, lambda f: f.stem not in ("terreno_teste", "blocos_prancha",
                                                                            "agua_superficie_4q"))
    folha_agua = ler(PECAS / "terreno" / "agua_superficie_4q.png")
    quadros = [montar.quadro(folha_agua, i, 8) for i in range(4)]
    lay = json.loads((PECAS / "montagem" / "layout.json").read_text(encoding="utf-8"))
    px, tags, sup = terreno.montar_terreno(blocos, quadros, colunas=[tuple(cl) for cl in lay["colunas"]])
    for y in range(H):
        for x in range(W):
            if px[y][x] is not None:
                c.p[y][x], c.tag[y][x] = px[y][x], tags[y][x]
    c.camada(ler(PECAS / "montagem" / f"reflexo_{hora}.png"), tag=montar.REFLEXO, so_onde=montar.AGUA)
    e1 = montar.ler_pasta("estagio1", estacao)
    for item in lay["pecas"]:
        if item["plano"] in ("pessoa", "fogo") or item["peca"] == "cabana_galhos" or not manter(item):
            continue
        p = montar.quadro(e1[item["peca"]], 0, len(e1[item["peca"]][0]))
        if item.get("espelho"):
            p = [l[::-1] for l in p]
        c.sprite(p, item["x"], item["base"], {"agua": montar.AGUA, "frente": montar.FRENTE}.get(item["plano"], montar.MUNDO))
    return c, sup


def sprite(c, caminho, x, base, quadro=0, larg=None, espelho=False, mapa=None):
    cenas.por(c, caminho, x, base, quadro, larg, espelho, mapa, montar.PESSOA if mapa else montar.MUNDO)


def destaque_prece():
    """Entardecer: a vila do estágio 2 reza diante do altar, e as preces sobem como luzes."""
    c, sup = base_mundo("entardecer", manter=cenas.fora_da_vila(150, 330))
    sprite(c, "estagio2/casa_taipa.png", 156, 119)
    sprite(c, "estagio2/templo.png", 184, 119)
    sprite(c, "estagio2/altar.png", 226, 119)
    sprite(c, "estagio2/casa_taipa.png", 286, 119)
    for i, (x, pele, cab, roupa) in enumerate(((246, 24, 30, 28), (256, 26, 23, 27), (266, 23, 8, 29), (276, 25, 30, 28))):
        sprite(c, "habitantes/adulto_a_rezar_2q.png", x, 119, i % 2, 8, True, troca(pele, cab, roupa))
    img = montar.imagem(c).convert("RGBA")
    for caminho, q, w, x, y in (("sinais/prece_comum_4q.png", 1, 8, 246, 96), ("sinais/prece_urgente_4q.png", 2, 12, 254, 88),
                                ("sinais/prece_desesperada_4q.png", 1, 16, 262, 74), ("sinais/prece_comum_4q.png", 3, 8, 276, 95)):
        s = Image.open(PECAS / caminho)
        img.alpha_composite(s.crop((q * w, 0, q * w + w, s.height)), (x, y))
    return img


def destaque_chuva():
    """Seca: céu amarelado, chão rachado e roça seca. A nuvem do deus despeja a chuva."""
    c, sup = base_mundo("dia", ceu="ceu_seca.png", manter=cenas.fora_da_vila(150, 320), estacao="outono")
    for i in range(5):
        sprite(c, "estagio2/roca_seca.png", 150 + i * 16, 120)
    sprite(c, "estagio2/casa_taipa.png", 236, 119)
    sprite(c, "estagio2/celeiro.png", 262, 119)
    sprite(c, "estagio2/casa_taipa.png", 288, 119)
    for x, q, pele, cab, roupa in ((172, 0, 24, 30, 28), (204, 1, 26, 23, 27)):
        sprite(c, "acoes/esticar_4q.png", x, 119, 2, 8, False, troca(pele, cab, roupa))
    img = montar.imagem(c).convert("RGBA")
    rach = Image.open(PECAS / "efeitos" / "seca_rachaduras_4q.png")
    for x in range(232, 312, 32):
        img.alpha_composite(rach.crop((96, 0, 128, 8)), (x, 116))
    nuvem = Image.open(PECAS / "nuvens" / "nuvem_tempestade_perto_g.png")
    nuvem2 = Image.open(PECAS / "nuvens" / "nuvem_tempestade_perto_m.png")
    img.alpha_composite(nuvem, (150, 50))
    img.alpha_composite(nuvem2, (196, 46))
    img.alpha_composite(nuvem, (178, 56))
    gotas = Image.open(PECAS / "efeitos" / "chuva_forte_3v.png")
    resp = Image.open(PECAS / "efeitos" / "respingo_4q.png")
    rng = random.Random(901)
    for _ in range(46):
        v = rng.randrange(3)
        x, y = rng.randrange(152, 238), rng.randrange(70, 108)
        img.alpha_composite(gotas.crop((v * 4, 0, v * 4 + 4, 12)), (x, y))
    for x in range(154, 236, 11):
        q = (x // 11) % 4
        img.alpha_composite(resp.crop((q * 8, 0, q * 8 + 8, 8)), (x, 112))
    return img


def destaque_vila():
    img = Image.open(PECAS / "cenas" / "cena_estagio6.png").convert("RGBA")
    return img


def destaque_cronica():
    """O mundo vazio: ruínas tomadas pelo mato, árvores nascendo, e a crônica na estante."""
    c, sup = base_mundo("entardecer", manter=cenas.fora_da_vila(150, 330))
    sprite(c, "natureza/casa_ruina_mato_3.png", 152, 119)
    sprite(c, "natureza/templo_pedra_ruina_mato_2.png", 180, 119)
    sprite(c, "natureza/fogueira_antiga.png", 216, 119)
    sprite(c, "natureza/arvore_jovem.png", 234, 119)
    sprite(c, "natureza/casa_pedra_ruina_mato_3.png", 252, 119)
    sprite(c, "natureza/muda.png", 288, 119)
    sprite(c, "memoria/tumulo.png", 298, sup[300] + 1)
    img = montar.imagem(c).convert("RGBA")
    # a estante, num painel à direita
    px0, py0, pw, ph = 330, 44, 112, 80
    fundo = Image.open(PECAS / "estante" / "estante_fundo.png")
    for y in range(py0, py0 + ph, 16):
        for x in range(px0, px0 + pw, 16):
            img.alpha_composite(fundo.crop((0, 0, min(16, px0 + pw - x), min(16, py0 + ph - y))), (x, y))
    for x in range(px0, px0 + pw):
        for y in (py0, py0 + ph - 1):
            img.putpixel((x, y), COR(30))
    for y in range(py0, py0 + ph):
        for x in (px0, px0 + pw - 1):
            img.putpixel((x, y), COR(30))
    prat = Image.open(PECAS / "estante" / "prateleira.png")
    for x in range(px0 + 1, px0 + pw - 1, 16):
        img.alpha_composite(prat.crop((0, 0, min(16, px0 + pw - 1 - x), 6)), (x, py0 + 72))
    livros = Image.open(PECAS / "estante" / "livro_lombada_6v.png")
    eras = ["ARDEM", "TORIL", "MUNDO 2", "A SECA", "BRONZE", "ÚLTIMOS"]
    for i in range(6):
        x = px0 + 8 + i * 16
        img.alpha_composite(livros.crop((i * 12, 0, i * 12 + 12, 64)), (x, py0 + 72 - 64))
        rot = rotulo(eras[i])
        img.alpha_composite(rot, (x + 2, py0 + 72 - 64 + 9 + max(0, (46 - rot.height) // 2)))
    return img


def rotulo(nome):
    folha, chars = interface.fonte(8)
    f = para_imagem(folha)
    larg = sum(av for cid, *_r, av in chars if chr(cid) in nome) + 8 * len(nome)
    t = Image.new("RGBA", (larg, 11), (0, 0, 0, 0))
    fim = interface.escrever(t, nome, 0, 0, chars, f)
    return t.crop((0, 1, fim, 9)).rotate(90, expand=True)


# ---------------------------------------------------------------- capa

def capa():
    """640x320: área de trabalho estilizada (papel de parede, janelas e barra de tarefas)
    com a moldura do jogo mostrando o mundo ao entardecer."""
    Wc, Hc = 640, 320
    img = Image.new("RGBA", (Wc, Hc), COR(3))
    # papel de parede: degradê pontilhado do azul profundo ao violeta
    from comum import pont
    for y in range(Hc - 16):
        f = y / (Hc - 16)
        for x in range(Wc):
            c = 3
            if pont(x, y, max(0.0, min(1.0, (f - 0.35) * 2.2))):
                c = 4
            if pont(x, y, max(0.0, min(1.0, (f - 0.8) * 4))):
                c = 5
            img.putpixel((x, y), COR(c))
    # duas janelas de "trabalho" ao fundo
    for (x0, y0, w, h) in ((24, 120, 170, 120), (470, 36, 150, 110)):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                borda = x in (x0, x0 + w - 1) or y in (y0, y0 + h - 1)
                c = 30 if borda else 2 if y < y0 + 9 else 12 if (y - y0) % 8 in (3, 4) and x0 + 8 < x < x0 + w - 30 else 31
                img.putpixel((x, y), COR(c))
        for x in (x0 + w - 8, x0 + w - 14):
            for dy in range(3, 6):
                img.putpixel((x, y0 + dy), COR(31))
    # barra de tarefas
    for y in range(Hc - 16, Hc):
        for x in range(Wc):
            img.putpixel((x, y), COR(30 if y > Hc - 16 else 4))
    ico = Image.open(PECAS / "interface" / "icone_jogo_16.png")
    img.alpha_composite(ico, (Wc - 60, Hc - 15))
    for i in range(3):
        for y in range(Hc - 12, Hc - 4):
            for x in range(8 + i * 22, 22 + i * 22):
                img.putpixel((x, y), COR(5 if i else 2))
    # a moldura do jogo: alça em cima e o mundo ao entardecer, capturado do jogo de verdade
    # (versão 0.1: a vila do estágio 3 com a roda em volta do fogo; `capturar_divulgacao.sh`)
    mundo = Image.open(AQUI / "fontes" / "jogo_entardecer.png").convert("RGBA")
    fx, fy = 120, 92
    for y in range(fy - 21, fy + 162):
        for x in range(fx - 2, fx + 482):
            img.putpixel((x, y), COR(30))
    alca = para_imagem(interface.nove(interface.alca(), 12, 4, 480, 18))
    img.alpha_composite(alca, (fx, fy - 19))
    botoes = interface.botoes()
    x = fx + 3
    for i, nome in enumerate(("chuva", "raio", "fogo", "fartura", "erguer_terra", "sonho")):
        img.alpha_composite(para_imagem(interface.molde(interface.ICONES_8[nome])), (x + 1, fy - 14))
        x += 11
    x += 6
    for nome in ("pausa", "normal", "rapido", "cronica", "linhagem"):
        img.alpha_composite(para_imagem(interface.molde(interface.ICONES_8[nome])), (x + 1, fy - 14))
        x += 11
    rel = texto("18:00", 1, fill=(22,), contorno=None, sombra=None)
    img.alpha_composite(rel, (fx + 480 - rel.width - 6, fy - 15))
    img.alpha_composite(mundo, (fx, fy))
    # logo no alto à esquerda
    lg = logo(3, True)
    img.alpha_composite(lg, (24, 20))
    return img


def principal():
    for nome, img in (("logo_pequeno", logo(2, False)), ("logo_grande", logo(3, True))):
        img.save(AQUI / f"{nome}.png")
        img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(AQUI / f"{nome}_4x.png")
    c = capa()
    c.resize((1280, 640), Image.NEAREST).save(AQUI / "capa.png")
    # cada destaque é um recorte de 240x80 da cena, com a frase, ampliado 4x (960x320)
    for nome, f, caixa, frase, canto in (
            ("destaque_1_prece", destaque_prece, (150, 58, 390, 138), "O povo reza. Você decide.", "esq"),
            ("destaque_2_chuva", destaque_chuva, (124, 42, 364, 122), "A chuva do deus na seca.", "dir"),
            ("destaque_3_vila", destaque_vila, (188, 44, 428, 124), "Da cabana ao moinho.", "esq"),
            ("destaque_4_cronica", destaque_cronica, (196, 44, 436, 124), "Fica a crônica.", "esq")):
        img = f().crop(caixa)
        t = texto(frase, 1, fill=(31, 31, 22), contorno=None, sombra=None)
        x = 3 if canto == "esq" else img.width - t.width - 13
        legenda(img, frase, x, 3, escala=1)
        img.resize((960, 320), Image.NEAREST).save(AQUI / f"{nome}.png")
    # os melhores momentos da versão 0.1, capturados do jogo e ampliados 3x (`capturar_divulgacao.sh`)
    for nome, fonte in (("momento_1_entardecer", "jogo_entardecer"), ("momento_2_cacada", "jogo_cacada"),
                        ("momento_3_vila_estagio6", "jogo_vila_estagio6"),
                        ("momento_3b_vila_estagio6_noite", "jogo_vila_estagio6_noite"),
                        ("momento_4_livro", "jogo_livro"), ("momento_5_dica_pessoa", "jogo_dica_pessoa"),
                        ("momento_6_recomeco", "jogo_recomeco")):
        img = Image.open(AQUI / "fontes" / f"{fonte}.png").convert("RGB")
        img.resize((img.width * 3, img.height * 3), Image.NEAREST).save(AQUI / f"{nome}.png")
    print("divulgação: logos, capa, 4 destaques e 7 momentos")


if __name__ == "__main__":
    principal()

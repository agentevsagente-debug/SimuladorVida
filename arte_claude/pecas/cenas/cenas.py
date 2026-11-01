"""Cenas de amostra (480x160): uma vila em cada estágio, do 2 (agricultura) ao 6
(engenharia), no estilo da cena-alvo.

Como a prova de montagem, as cenas usam só peças e camadas entregues: céu, montanhas e
mata do dia, terreno em blocos, reflexo, e as peças de cada estágio lidas dos PNGs.
O morro e a praia guardam a vegetação da cena-alvo (de `montagem/layout.json`).
"""
from pathlib import Path
import json
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
for sub in ("", "terreno", "habitantes", "montagem"):
    sys.path.insert(0, str(PECAS / sub))

from comum import PALETA, espelhar, gravar, trocar  # noqa: E402
import montar  # noqa: E402
import terreno  # noqa: E402
from habitantes import troca  # noqa: E402

W, H = 480, 160
MUNDO, PESSOA, FOGO, AGUA = montar.MUNDO, montar.PESSOA, montar.FOGO, montar.AGUA


def base(manter_vegetacao):
    """Céu, fundo, terreno e reflexo de dia, mais a vegetação da cena-alvo que passar no filtro."""
    ler = montar.ler
    c = montar.Cena()
    c.camada(ler(PECAS / "montagem" / "ceu_dia.png"))
    for nome in ("montanhas_longe", "montanhas_perto", "mata_distante"):
        c.camada(ler(PECAS / "montagem" / f"{nome}_dia.png"))
    blocos = {f.stem: ler(f) for f in (PECAS / "terreno").glob("*.png")
              if f.stem not in ("terreno_teste", "blocos_prancha", "agua_superficie_4q")}
    folha_agua = ler(PECAS / "terreno" / "agua_superficie_4q.png")
    quadros = [montar.quadro(folha_agua, i, 8) for i in range(4)]
    lay = json.loads((PECAS / "montagem" / "layout.json").read_text(encoding="utf-8"))
    px, tags, sup = terreno.montar_terreno(blocos, quadros, colunas=[tuple(cl) for cl in lay["colunas"]])
    for y in range(H):
        for x in range(W):
            if px[y][x] is not None:
                c.p[y][x], c.tag[y][x] = px[y][x], tags[y][x]
    c.camada(ler(PECAS / "montagem" / "reflexo_dia.png"), tag=montar.REFLEXO, so_onde=AGUA)
    e1 = {f.stem: ler(f) for f in (PECAS / "estagio1").glob("*.png")}
    for item in lay["pecas"]:
        if item["plano"] in ("pessoa", "fogo") or item["peca"] in ("cabana_galhos",):
            continue
        if not manter_vegetacao(item):
            continue
        p = montar.quadro(e1[item["peca"]], 0, len(e1[item["peca"]][0]))
        if item.get("espelho"):
            p = espelhar(p)
        c.sprite(p, item["x"], item["base"], {"agua": AGUA, "frente": montar.FRENTE}.get(item["plano"], MUNDO))
    return c, sup


_cache = {}


def peca(caminho, quadro=0, larg_quadro=None):
    if caminho not in _cache:
        _cache[caminho] = montar.ler(PECAS / caminho)
    folha = _cache[caminho]
    return montar.quadro(folha, quadro, larg_quadro or len(folha[0]))


def por(c, caminho, x, base, quadro=0, larg=None, espelho=False, mapa=None, tag=MUNDO):
    p = peca(caminho, quadro, larg)
    if mapa:
        p = trocar(p, mapa)
    if espelho:
        p = espelhar(p)
    c.sprite(p, x, base, tag)


def gente(c, caminho, x, base, quadro, larg, pele, cabelo, tecido, espelho=False):
    por(c, caminho, x, base, quadro, larg, espelho, troca(pele, cabelo, tecido), PESSOA)


def fora_da_vila(x0, x1):
    """Mantém a vegetação da cena-alvo fora do trecho [x0, x1] em que a vila foi construída."""
    return lambda item: not (x0 <= item["x"] + 8 <= x1)


# ---------------------------------------------------------------- vilas

def estagio2():
    c, sup = base(fora_da_vila(150, 320))
    for i in range(4):
        por(c, "estagio2/roca_madura.png" if i % 3 else "estagio2/roca_crescida.png", 150 + i * 16, 120)
    for i in range(9):
        por(c, "estagio2/cerca.png", 150 + i * 8, 120)
    por(c, "estagio2/cerca_poste.png", 222, 120)
    por(c, "estagio2/casa_taipa.png", 226, 119)
    por(c, "estagio2/celeiro.png", 252, 119)
    por(c, "estagio2/casa_taipa.png", 278, 119)
    por(c, "estagio2/altar.png", 304, sup[310] + 1)
    por(c, "estagio2/templo.png", 404, sup[420] + 1)
    gente(c, "estagio2/adulto_enxada_trabalhar_4q.png", 166, 119, 2, 12, 24, 30, 28)
    gente(c, "estagio2/adulto_enxada_andar_4q.png", 196, 119, 1, 12, 26, 23, 27)
    gente(c, "habitantes/adulto_b_parado_2q.png", 246, 119, 0, 8, 25, 8, 29, True)
    gente(c, "habitantes/crianca_andar_4q.png", 270, 119, 1, 6, 26, 10, 27)
    gente(c, "habitantes/adulto_a_rezar_2q.png", 296, sup[300], 0, 8, 23, 30, 28)
    return c


def estagio3():
    c, sup = base(fora_da_vila(150, 330))
    por(c, "estagio3/casa_pedra.png", 152, 119)
    por(c, "estagio3/casa_pedra.png", 186, 119)
    por(c, "estagio3/templo_pedra.png", 224, 119)
    por(c, "estagio2/roca_madura.png", 262, 120)
    por(c, "estagio2/roca_madura.png", 278, 120)
    por(c, "estagio2/celeiro.png", 296, 119)
    for x in (338, 434):
        por(c, "estagio3/casa_pedra_ruina.png" if x == 434 else "estagio2/casa_taipa.png", x, sup[x + 12] + 1)
    gente(c, "estagio3/adulto_e3_andar_4q.png", 210, 119, 0, 8, 25, 8, 28)
    gente(c, "estagio3/adulto_e3_parado_2q.png", 258, 119, 0, 8, 24, 30, 29, True)
    gente(c, "habitantes/crianca_andar_4q.png", 216, 119, 1, 6, 26, 23, 27)
    gente(c, "estagio2/adulto_enxada_trabalhar_4q.png", 268, 119, 2, 12, 23, 30, 28)
    return c


def estagio4():
    c, sup = base(fora_da_vila(140, 330))
    por(c, "estagio4/forja_2q.png", 146, 119, 0, 24)
    por(c, "estagio4/casa_enxaimel.png", 172, 119)
    por(c, "estagio4/templo_colunas.png", 208, 119)
    por(c, "estagio4/casa_enxaimel.png", 244, 119)
    por(c, "estagio3/casa_pedra.png", 280, 119)
    por(c, "estagio4/forja_ruina.png", 418, sup[430] + 1)
    gente(c, "estagio4/ferreiro_trabalhar_4q.png", 158, 119, 1, 12, 23, 30, 28)
    gente(c, "estagio4/guerreiro_andar_4q.png", 240, 119, 0, 12, 25, 8, 27)
    gente(c, "estagio4/guerreiro_andar_4q.png", 274, 119, 2, 12, 24, 23, 27, True)
    gente(c, "estagio4/adulto_e4_parado_2q.png", 204, 119, 0, 8, 26, 10, 29)
    return c


def estagio5():
    c, sup = base(fora_da_vila(140, 330))
    por(c, "estagio5/biblioteca.png", 148, 119)
    por(c, "estagio5/estela.png", 182, 119)
    por(c, "estagio5/templo_escrita.png", 194, 119)
    por(c, "estagio4/casa_enxaimel.png", 230, 119)
    por(c, "estagio3/casa_pedra.png", 264, 119)
    por(c, "estagio5/estela.png", 300, sup[304] + 1)
    gente(c, "estagio5/escriba_sentado_2q.png", 184, 119, 0, 8, 24, 30, 29)
    gente(c, "estagio5/adulto_e5_andar_4q.png", 222, 119, 1, 8, 26, 23, 28)
    gente(c, "estagio5/adulto_e5_parado_2q.png", 258, 119, 0, 8, 25, 8, 27, True)
    gente(c, "habitantes/crianca_andar_4q.png", 298, 119, 3, 6, 25, 10, 29, True)
    return c


def estagio6():
    c, sup = base(lambda item: not (140 <= item["x"] + 8 <= 330 or 392 <= item["x"] + 8 <= 470))
    por(c, "estagio6/barco_2q.png", 40, 123, 0, 24, tag=MUNDO)
    for x in range(140, 172, 8):
        por(c, "estagio6/muralha.png", x, 119)
    por(c, "estagio6/muralha_torre.png", 172, 119)
    por(c, "estagio6/casa_tijolo.png", 190, 119)
    por(c, "estagio6/templo_cupula.png", 224, 119)
    por(c, "estagio6/casa_tijolo.png", 258, 119)
    por(c, "estagio6/roca_irrigada.png", 292, 120)
    por(c, "estagio6/moinho_4q.png", 398, sup[414] + 1, 1, 32)
    por(c, "estagio5/biblioteca.png", 432, sup[448] + 1)
    gente(c, "estagio6/adulto_e6_andar_4q.png", 216, 119, 0, 8, 25, 23, 28)
    gente(c, "estagio6/adulto_e6_parado_2q.png", 252, 119, 0, 8, 24, 30, 29, True)
    gente(c, "estagio4/guerreiro_andar_4q.png", 150, 103, 1, 12, 26, 8, 27)
    gente(c, "habitantes/crianca_andar_4q.png", 286, 119, 1, 6, 23, 30, 27, True)
    return c


def principal():
    cenas = {2: estagio2, 3: estagio3, 4: estagio4, 5: estagio5, 6: estagio6}
    juntas = Image.new("RGB", (W, (H + 4) * len(cenas) - 4), PALETA[30])
    for i, (n, f) in enumerate(cenas.items()):
        c = f()
        img = montar.imagem(c)
        gravar(img.convert("RGBA"), AQUI / f"cena_estagio{n}.png")
        juntas.paste(img, (0, i * (H + 4)))
    juntas.save(AQUI / "amostra_cenas.png")
    juntas.resize((juntas.width * 2, juntas.height * 2), Image.NEAREST).save(AQUI / "amostra_cenas_2x.png")
    print("cenas: estágios 2 a 6")


if __name__ == "__main__":
    principal()

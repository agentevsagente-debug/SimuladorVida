"""Prova de montagem: remonta a cena-alvo de dia e de noite usando só as peças e as camadas.

Lê os PNGs entregues (não chama o código de desenho das peças), como o jogo fará.
A noite é feita com as tabelas de `tabelas_luz.json` e os mapas `luz_fogueira*.png`.
"""
from pathlib import Path
import json
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(PECAS / "terreno"))
sys.path.insert(0, str(PECAS / "habitantes"))

from comum import PALETA, cena, espelhar, gravar, trocar  # noqa: E402
import terreno  # noqa: E402

W, H = cena.W, cena.H
INDICE = {rgb: i for i, rgb in enumerate(PALETA)}
CEU, MUNDO, PESSOA, FOGO, AGUA, FRENTE = cena.CEU, cena.MUNDO, cena.PESSOA, cena.FOGO, cena.AGUA, cena.FRENTE
REFLEXO = 9


def ler(caminho):
    img = Image.open(caminho).convert("RGBA")
    px = list(img.getdata())
    return [[None if px[y * img.width + x][3] == 0 else INDICE[px[y * img.width + x][:3]]
             for x in range(img.width)] for y in range(img.height)]


def quadro(folha, i, w):
    return [linha[i * w:(i + 1) * w] for linha in folha]


class Cena:
    def __init__(self):
        self.p = [[0] * W for _ in range(H)]
        self.tag = [[CEU] * W for _ in range(H)]
        self.lado = [[0] * W for _ in range(H)]

    def camada(self, px, tag=CEU, so_onde=None):
        for y in range(H):
            for x in range(W):
                c = px[y][x]
                if c is not None and (so_onde is None or self.tag[y][x] == so_onde):
                    self.p[y][x] = c
                    self.tag[y][x] = tag

    def sprite(self, px, x0, base, tag=MUNDO, centro_fogo=None):
        """Coloca a peça com a última linha em `base`."""
        h, w = len(px), len(px[0])
        for j in range(h):
            for i in range(w):
                c = px[j][i]
                x, y = x0 + i, base - h + 1 + j
                if c is not None and 0 <= x < W and 0 <= y < H:
                    self.p[y][x] = c
                    self.tag[y][x] = tag
                    if centro_fogo is not None:
                        meio = x0 + w / 2
                        self.lado[y][x] = 1 if abs(x + 0.5 - centro_fogo) < abs(meio - centro_fogo) \
                            or (x + 0.5 - centro_fogo) * (meio - centro_fogo) <= 0 else 0


def ler_pasta(pasta, estacao=None, filtro=lambda f: True):
    """Peças de uma pasta; na estação pedida, as variações de `estacoes/` substituem as de verão."""
    out = {f.stem: ler(f) for f in (PECAS / pasta).glob("*.png") if filtro(f)}
    if estacao:
        for f in (PECAS / "estacoes" / estacao / pasta).glob("*.png"):
            if f.stem in out:
                out[f.stem] = ler(f)
    return out


def camada_fundo(nome, hora, estacao):
    sazonal = PECAS / "estacoes" / (estacao or "-") / "montagem" / f"{nome}_{hora}.png"
    return ler(sazonal if sazonal.exists() else AQUI / f"{nome}_{hora}.png")


def montar(hora, estacao=None):
    pasta_hab = PECAS / "habitantes"
    e = ler_pasta("estagio1", estacao)
    hab = {f.stem: ler(f) for f in pasta_hab.glob("*_*q.png")}
    c = Cena()
    # 1. céu e fundo (camadas do motor)
    c.camada(camada_fundo("ceu", hora, estacao))
    for nome in ("montanhas_longe", "montanhas_perto", "mata_distante"):
        c.camada(camada_fundo(nome, hora, estacao))
    # 2. terreno em blocos
    blocos = ler_pasta("terreno", estacao, lambda f: f.stem not in ("terreno_teste", "blocos_prancha",
                                                                    "agua_superficie_4q"))
    folha_agua = ler(PECAS / "terreno" / "agua_superficie_4q.png")
    quadros = [quadro(folha_agua, i, 8) for i in range(4)]
    lay = json.loads((AQUI / "layout.json").read_text(encoding="utf-8"))
    px, tags, sup = terreno.montar_terreno(blocos, quadros, colunas=[tuple(cl) for cl in lay["colunas"]])
    for y in range(H):
        for x in range(W):
            if px[y][x] is not None:
                c.p[y][x], c.tag[y][x] = px[y][x], tags[y][x]
    c.camada(ler(AQUI / f"reflexo_{hora}.png"), tag=REFLEXO, so_onde=AGUA)
    if estacao == "inverno":
        # lago congelado na borda: as 3 colunas de água mais perto da praia viram gelo
        gelo = ler(PECAS / "estacoes" / "inverno" / "terreno" / "gelo_superficie.png")
        agua_cols = [cx for cx in range(0, W, 8) if c.tag[122][cx + 4] in (AGUA, REFLEXO)]
        for cx in agua_cols[-3:]:
            for j in range(8):
                for i in range(8):
                    if gelo[j][i] is not None:
                        c.p[120 + j][cx + i], c.tag[120 + j][cx + i] = gelo[j][i], AGUA

    # 3. peças, na ordem e nas posições de layout.json
    centro = lay["fogueira"]["x"] + 8
    for item in lay["pecas"]:
        pasta = hab if item["plano"] == "pessoa" else e
        folha = pasta[item["peca"]]
        px = quadro(folha, item.get("quadro", 0), item.get("larg_quadro", len(folha[0])))
        if item.get("troca"):
            px = trocar(px, {int(k): v for k, v in item["troca"].items()})
        if item.get("espelho"):
            px = espelhar(px)
        tag = {"mundo": MUNDO, "agua": AGUA, "fogo": FOGO, "pessoa": PESSOA, "frente": FRENTE}[item["plano"]]
        c.sprite(px, item["x"], item["base"], tag, centro_fogo=centro if tag == PESSOA else None)
    fx, fy = lay["fogueira"]["x"], lay["fogueira"]["y"]

    if hora == "noite":
        noite(c, sup, (fx, fy))
    return c


def gerar_layout():
    """Posições das peças na cena-alvo, gravadas como dados para o motor (layout.json).
    x = canto esquerdo da peça; base = linha da tela onde fica a última linha da peça."""
    from habitantes import troca
    colunas = terreno.perfil_colunas()
    sup = [colunas[x // 8][0] for x in range(W)]
    larg = {f.stem: Image.open(f).width for f in (PECAS / "estagio1").glob("*.png")}
    pecas = []

    def por(nome, x_centro, base, plano="mundo", ancora=None, espelho=False):
        ax = ancora if ancora is not None else larg[nome] // 2
        pecas.append({"peca": nome, "x": x_centro - ax, "base": base, "plano": plano, "espelho": espelho})

    for x in (338, 362, 392, 416, 446, 470):
        por("pinheiro_fundo", x, sup[x] - 2, ancora=15)
    for x, alt in ((322, 22), (350, 30), (378, 34), (404, 28), (432, 36), (458, 30), (478, 26)):
        por("pinheiro_a" if alt >= 32 else "pinheiro_b", x, sup[x], ancora=19 if alt >= 32 else 11)
    por("arvore_copa_a", 306, sup[306], ancora=19)
    por("arvore_copa_b", 444, sup[444] + 1, ancora=14)
    por("arvore_copa_b", 160, sup[160], ancora=14)
    for x, nome in ((186, "arbusto_frutas"), (296, "arbusto_frutas"), (340, "arbusto"),
                    (418, "arbusto_frutas"), (154, "arbusto"), (466, "arbusto")):
        por(nome, x, sup[x] + 1)
    for x in (176, 258, 312, 330, 366, 392, 424, 452):
        por("capim", x, sup[x] - 1, ancora=4)
    for x in (122, 132, 140, 147):
        por("capim_seco", x, sup[x] - 1, ancora=4)
    for x in (20, 27, 58, 66, 83):
        por("alga", x, sup[x] - 1, "agua", ancora=2)
    por("juncos", 107, sup[110] - 1, ancora=0)
    por("pedra_pequena", 144, sup[144] + 2, ancora=4)
    por("pedra_grande", 314, sup[314] + 3, ancora=8)
    por("pedra_pequena", 386, sup[386] + 2, ancora=4)
    por("pedra_pequena", 290, sup[290] + 2, ancora=4)
    por("tronco_deriva", 116, sup[122] - 1, ancora=0)
    por("cabana_galhos", 164, 119, ancora=0)
    por("cabana_galhos", 268, 119, ancora=0)
    fx, fy = cena.FOGO_X - 8, 104             # canto da peça: múltiplos de 4
    pecas.append({"peca": "fogueira_acesa_4q", "quadro": 0, "larg_quadro": 16, "x": fx, "base": fy + 15,
                  "plano": "fogo"})

    def gente(nome, q, lq, x, mapa, espelho=False):
        pecas.append({"peca": nome, "quadro": q, "larg_quadro": lq, "x": x,
                      "base": 119 if x > 150 else sup[x + 4] - 1, "plano": "pessoa",
                      "espelho": espelho, "troca": {str(k): v for k, v in mapa.items()}})

    gente("adulto_a_parado_2q", 0, 8, 136, troca(24, 30, 28))
    gente("adulto_a_andar_4q", 1, 8, 188, troca(26, 23, 27))
    gente("crianca_andar_4q", 1, 6, 198, troca(25, 8, 29))
    gente("adulto_a_sentado_1q", 0, 8, 206, troca(23, 30, 28))
    gente("adulto_b_parado_2q", 0, 8, 234, troca(25, 8, 29), espelho=True)
    gente("crianca_andar_4q", 3, 6, 244, troca(26, 10, 27), espelho=True)
    gente("idoso_andar_4q", 1, 8, 252, troca(pele=24, tecido=27), espelho=True)
    gente("adulto_a_andar_4q", 3, 8, 288, troca(25, 23, 28), espelho=True)
    for x, base, esp in ((2, 125, False), (7, 127, True), (474, sup[474] + 6, True),
                         (468, sup[468] + 8, False), (316, sup[316] + 5, False)):
        pecas.append({"peca": "samambaia_frente", "x": x - 7, "base": base + 2, "plano": "frente",
                      "espelho": esp})
    return {
        "nota": "colunas: [superfície y, tipo] de cada coluna de 8 px; x = canto esquerdo da peça; "
                "base = linha da tela da última linha da peça; troca = cor-base -> cor (índices da paleta); "
                "a ordem da lista é a ordem de desenho",
        "colunas": [list(cl) for cl in colunas],
        "fogueira": {"x": fx, "y": fy},
        "pecas": pecas,
    }


def noite(c, sup, canto_fogo):
    tab = json.loads((AQUI / "tabelas_luz.json").read_text(encoding="utf-8"))
    conv = lambda d: {int(k): v for k, v in d.items() if k.isdigit()}  # noqa: E731
    noite_t, agua_t = conv(tab["noite"]), conv(tab["noite_agua"])
    perto, medio, halo_t = conv(tab["fogo_perto"]), conv(tab["fogo_medio"]), conv(tab["halo_ceu"])
    luz = Image.open(AQUI / "luz_fogueira.png")
    halo = Image.open(AQUI / "luz_fogueira_halo.png")
    ox, oy = canto_fogo[0] - 56, canto_fogo[1] - 32

    def nivel(img, x, y):
        lx, ly = x - ox, y - oy
        if 0 <= lx < img.width and 0 <= ly < img.height:
            v = img.getpixel((lx, ly))
            return 2 if v > 200 else 1 if v > 60 else 0
        return 0

    novo = [linha[:] for linha in c.p]
    for y in range(H):
        for x in range(W):
            cor, tag = c.p[y][x], c.tag[y][x]
            if tag in (FOGO, REFLEXO):
                continue
            if tag == AGUA:
                novo[y][x] = agua_t.get(cor, cor)
            elif tag == CEU:
                if cor in halo_t and nivel(halo, x, y):
                    novo[y][x] = halo_t[cor]
            elif tag == FRENTE:
                novo[y][x] = 30 if cor == 3 else 3
            elif tag == MUNDO and y > sup[x] + 3:
                novo[y][x] = noite_t.get(cor, cor)
            else:
                n = nivel(luz, x, y)
                if tag == PESSOA and not c.lado[y][x]:
                    n -= 1
                tabela = perto if n == 2 else medio if n == 1 else noite_t
                novo[y][x] = tabela.get(cor, cor)
    c.p = novo


def imagem(c):
    img = Image.new("RGB", (W, H))
    img.putdata([PALETA[v] for linha in c.p for v in linha])
    return img


def principal():
    (AQUI / "layout.json").write_text(json.dumps(gerar_layout(), indent=1, ensure_ascii=False),
                                      encoding="utf-8")
    for hora in ("dia", "noite"):
        img = imagem(montar(hora))
        gravar(img.convert("RGBA"), AQUI / f"montagem_{hora}.png")
        alvo = Image.open(PECAS.parent / "alvo" / f"alvo_{hora}.png").convert("RGB")
        lado = Image.new("RGB", (W, H * 2 + 4), PALETA[30])
        lado.paste(alvo, (0, 0))
        lado.paste(img, (0, H + 4))
        gravar(lado.convert("RGBA"), AQUI / f"comparacao_{hora}.png")
        dif = sum(1 for a, b in zip(alvo.getdata(), img.getdata()) if a != b)
        print(f"montagem {hora}: {100 * dif / (W * H):.1f}% dos pixels diferem da cena-alvo")


if __name__ == "__main__":
    principal()

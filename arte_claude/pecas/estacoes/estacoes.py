"""Estações do ano. O verão é a arte de sempre; aqui saem as outras três.

Saída em `estacoes/<estacao>/<pasta>/<nome>.png`, com o mesmo nome, tamanho e encaixe
da peça original. O motor troca a pasta conforme a estação, e o que não tiver variação
usa a peça de verão.

- primavera: flores nas copas, nos arbustos, no capim e na borda da grama;
- outono: copas largas e arbustos alaranjados, capim e grama secando, folhas no chão;
- inverno: árvores de copa sem folhas, neve em cima de tudo (pinheiros, telhados,
  pedras, grama), montanhas com mais neve, lago congelado na borda.

Efeitos novos em `efeitos/`: neve caindo (`neve_4q`) e flocos (`floco_3v`).
"""
from pathlib import Path
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))
sys.path.insert(0, str(PECAS / "montagem"))

from comum import PALETA, folha_quadros, gravar, pont  # noqa: E402

ESTACOES = ("primavera", "outono", "inverno")
INDICE = {rgb: i for i, rgb in enumerate(PALETA)}


def ler(caminho):
    img = Image.open(caminho).convert("RGBA")
    px = list(img.getdata())
    return [[None if px[y * img.width + x][3] == 0 else INDICE[px[y * img.width + x][:3]]
             for x in range(img.width)] for y in range(img.height)]


def h(x, y, s=0):
    """Sorteio fixo por pixel (mesmo resultado sempre)."""
    return ((x * 73856093) ^ (y * 19349663) ^ (s * 83492791)) % 997 / 997


# ---------------------------------------------------------------- transformações

def mapear(px, mapa):
    return [[mapa.get(c, c) if c is not None else None for c in l] for l in px]


def flores(px, cores=(31, 7, 22), taxa=0.08, so=(15, 16), semente=1):
    out = [l[:] for l in px]
    for y, l in enumerate(px):
        for x, c in enumerate(l):
            if c in so and h(x, y, semente) < taxa:
                out[y][x] = cores[int(h(y, x, semente) * len(cores))]
    return out


def neve_por_cima(px, grossa=True, claro=31, sombra=0, espessura=1):
    """Neve assentada: o pixel exposto para cima vira neve, e o de baixo vira neve
    pontilhada (se a neve for grossa). Vale para copas, telhados, pedras e grama.
    `espessura` > 1 cobre mais pixels sólidos abaixo do exposto (telhados: a neve cobre a
    água do telhado, e não só a borda)."""
    hgt, w = len(px), len(px[0])
    out = [l[:] for l in px]
    for x in range(w):
        for y in range(hgt):
            if px[y][x] is None:
                continue
            exposto = y == 0 or px[y - 1][x] is None
            if not exposto:
                continue
            out[y][x] = claro
            for e in range(1, espessura):
                if y + e >= hgt or px[y + e][x] is None:
                    break
                out[y + e][x] = claro
            y += espessura - 1
            if y >= hgt or px[y][x] is None:
                continue
            if grossa and y + 1 < hgt and px[y + 1][x] is not None:
                out[y + 1][x] = claro if x % 3 else sombra
                if y + 2 < hgt and px[y + 2][x] is not None and pont(x, y + 2, 0.5):
                    out[y + 2][x] = sombra
    return out


OUTONO_COPA = {16: 22, 15: 21, 14: 24, 13: 23}
OUTONO_CAPIM = {15: 16, 14: 10, 13: 9}
OUTONO_GRAMA = {15: 16, 14: 15, 13: 14}


def outono_copa(px, semente=2):
    out = mapear(px, OUTONO_COPA)
    for y, l in enumerate(px):
        for x, c in enumerate(l):
            if c in (14, 15) and h(x, y, semente) < 0.12:
                out[y][x] = 16                 # algumas folhas ainda amarelando
    return out


def arvore_nua(w, hh, tronco_x, alt, semente):
    """Árvore de copa no inverno: tronco e galhos nus no mesmo encaixe da árvore de verão,
    com neve nos galhos."""
    rng = random.Random(semente)
    q = [[None] * w for _ in range(hh)]
    base = hh - 1

    def put(x, y, c):
        if 0 <= x < w and 0 <= y < hh:
            q[y][x] = c

    def linha(x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            put(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)

    topo_tronco = base - alt // 2
    for y in range(topo_tronco, base + 1):
        put(tronco_x, y, 9)
        put(tronco_x + 1, y, 9 if y < base - 3 else 8)
        put(tronco_x + 2, y, 8)
    put(tronco_x - 1, base, 9)
    put(tronco_x + 3, base, 8)
    alto = base - alt + 2
    galhos = [(-0.9, 0.55), (-0.45, 0.85), (0.1, 1.0), (0.55, 0.8), (1.0, 0.5)]
    for dx, dy in galhos:
        comp = alt * 0.55
        x0, y0 = tronco_x + 1, topo_tronco + 1
        x1, y1 = round(x0 + dx * comp), round(max(alto, y0 - dy * comp))
        linha(x0, y0, x1, y1, 9 if dx < 0.3 else 8)
        for _ in range(2):
            t = rng.uniform(0.45, 0.8)
            mx, my = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            linha(round(mx), round(my), round(mx + rng.choice((-1, 1)) * rng.randint(2, 4)),
                  round(my - rng.randint(2, 4)), 30 if dx > 0.3 else 8)
    return neve_por_cima(q, grossa=False)


# ---------------------------------------------------------------- catálogo

VEGETACAO_COPA = {"arvore_copa_a", "arvore_copa_b", "arbusto", "arbusto_frutas"}
PINHEIROS = {"pinheiro_a", "pinheiro_b", "pinheiro_fundo"}
ARVORES_NUAS = {"arvore_copa_a": (19, 30, 21), "arvore_copa_b": (14, 24, 22)}
GRAMAS = {"grama_a", "grama_b", "grama_seca", "chao_batido", "areia_superficie"}
SEM_NEVE = ("adulto_", "guerreiro", "ferreiro", "escriba", "crianca", "idoso", "amostra", "tabuletas",
            "variacoes", "canal", "fogueira_acesa")
PASTAS_CONSTRUCAO = ("estagio1", "estagio2", "estagio3", "estagio4", "estagio5", "estagio6", "culturas", "memoria",
                     "natureza")


def variante(pasta, nome, px, estacao):
    """Devolve a peça na estação, ou None se ela não muda."""
    if pasta == "terreno":
        if nome not in GRAMAS:
            return None
        if estacao == "primavera":
            if nome in ("grama_a", "grama_b"):
                return flores(px, taxa=0.3, so=(15,), semente=3)
            return None
        if estacao == "outono":
            if nome == "areia_superficie":
                return None
            out = mapear(px, OUTONO_GRAMA)
            for x in range(8):
                if h(x, 2, 4) < 0.25:
                    out[2][x] = 21 if h(x, 3, 4) < 0.5 else 24      # folhas caídas
            return out
        # inverno: neve na superfície (a superfície fica na linha 2, ou 0 na areia)
        out = [l[:] for l in px]
        topo = 0 if nome == "areia_superficie" else 2
        for x in range(8):
            for y in range(0, topo):
                if out[y][x] is not None:
                    out[y][x] = 31
            out[topo][x] = 31
            out[topo + 1][x] = 0 if pont(x, topo + 1, 0.5) else 31
            if out[topo + 2][x] in (13, 14):
                out[topo + 2][x] = 0 if x % 2 else 13
        return out
    if pasta == "estagio1":
        if estacao == "primavera":
            if nome in VEGETACAO_COPA:
                return flores(mapear(px, {13: 14}), taxa=0.2, so=(15, 16, 14), semente=5)
            if nome == "capim":
                return flores(px, cores=(22, 7, 31), taxa=0.25, so=(15,), semente=6)
            return None
        if estacao == "outono":
            if nome in VEGETACAO_COPA:
                return outono_copa(px)
            if nome == "capim":
                return mapear(px, OUTONO_CAPIM)
            if nome == "cabana_galhos":
                return mapear(px, {15: 16, 14: 10, 13: 9})
            return None
        if nome in ARVORES_NUAS:
            tx, alt, s = ARVORES_NUAS[nome]
            return arvore_nua(len(px[0]), len(px), tx, alt, s)
        if nome in ("arbusto", "arbusto_frutas"):
            return neve_por_cima(mapear(px, {15: 13, 16: 13, 14: 13, 27: 13, 20: 13}))
        if nome in ("capim", "capim_seco", "alga", "juncos"):
            return neve_por_cima(mapear(px, OUTONO_CAPIM), grossa=False) if nome != "alga" else None
        if nome.startswith(("fogueira", "samambaia")):
            return None
        return neve_por_cima(px, grossa=nome not in PINHEIROS or True)
    # agricultura: roças e pomar mudam em todas as estações
    if nome.startswith("roca_") or nome == "arvore_fruta":
        return agricultura(nome, px, estacao)
    if nome == "roda_dagua_4q" and estacao == "inverno":
        import sys as _s
        _s.path.insert(0, str(PECAS / "estagio6"))
        import estagio6
        return folha_quadros([estagio6.roda_dagua(0, congelada=True)] * 4)
    # construções dos estágios, culturas e memória: só o inverno muda (neve por cima)
    if estacao != "inverno" or nome.startswith(SEM_NEVE) or (nome + ".png").startswith(SEM_NEVE):
        return None
    if nome.startswith(("roca_", "cerca")):
        return neve_por_cima(px, grossa=False)
    return neve_por_cima(px, espessura=3)


def agricultura(nome, px, estacao):
    """Roças e pomar nas estações.
    Primavera: verde mais vivo e florzinhas entre os sulcos; pomar em flor.
    Outono: o verde amarela, a espiga madura fica cor de cobre e caem folhas no solo;
    pomar com frutas maduras e folhas alaranjadas.
    Inverno: roça coberta de neve (sulcos brancos e só pontas de palha seca); pomar nu."""
    hh, w = len(px), len(px[0])
    if nome == "arvore_fruta":
        if estacao == "primavera":
            out = flores(mapear(px, {22: 31, 16: 7}), cores=(31, 7), taxa=0.25, so=(15, 14), semente=8)
            return out
        if estacao == "outono":
            out = mapear(px, {22: 20, 16: 21})
            for y, l in enumerate(out):
                for x, c in enumerate(l):
                    if c in (15, 14) and h(x, y, 9) < 0.25:
                        out[y][x] = 24 if c == 14 else 21
            return out
        return arvore_nua(w, hh, 10, 18, 207)
    if estacao == "primavera":
        out = mapear(px, {14: 15, 13: 14})
        for x in range(0, w, 4):
            if out[12][x] in (8, 9) and h(x, 1, 30) < 0.5:
                out[12][x] = 22 if h(x, 2, 30) < 0.5 else 31
        return out
    if estacao == "outono":
        out = mapear(px, {15: 16, 14: 16, 22: 21, 31: 22})
        for x in range(w):
            if out[12][x] in (8, 9, 10) and h(x, 3, 31) < 0.3:
                out[12][x] = 24 if h(x, 4, 31) < 0.5 else 21
        return out
    # inverno: a roça vira campo de neve com sulcos, e sobra palha seca nas pontas
    out = [[None] * w for _ in range(hh)]
    for x in range(w):
        k = x % 4
        topo = 12 if k in (1, 2) else 13
        for y in range(topo, hh):
            out[y][x] = 31 if y == topo else (0 if k in (0, 3) or y > topo + 1 else 31)
            if y >= 15:
                out[y][x] = 0
        if k == 1 and nome not in ("roca_arada",) and px[11][x] is not None:
            out[11][x] = 10
            if px[10][x] is not None:
                out[10][x] = 9
    if nome == "roca_irrigada":
        for x in range(0, w, 4):
            out[13][x] = 0
            out[14][x] = 19                     # rego congelado
    return out


# ---------------------------------------------------------------- montanhas e gelo

def montanha_inverno(px, profundidade, hora):
    """Mais neve: uma calota que segue a crista de cada montanha, com `profundidade` px e a
    borda de baixo pontilhada. Branca do lado da luz, azul-clara na sombra."""
    # à noite a neve fica azul de lua (18) e azul-escuro na sombra (4): o cinza (11) pesava
    # mais que o resto da cena e puxava para o oliva (auditoria 3b)
    claro, sombra = (31, 0) if hora != "noite" else (18, 4)
    luz = {"dia": {1: True, 18: True, 14: True, 2: False, 17: False, 13: False},
           "entardecer": {7: True, 5: False, 4: False, 3: False},
           "noite": {5: True, 4: False, 3: False, 30: False}}[hora]
    out = [l[:] for l in px]
    for x in range(len(px[0])):
        topo = next((y for y in range(len(px)) if px[y][x] is not None), None)
        if topo is None:
            continue
        for y in range(topo, min(len(px), topo + profundidade + 4)):
            c = px[y][x]
            if c is None or c in (31, 0):
                continue
            f = (topo + profundidade + 4 - y) / 6
            if y < topo + profundidade - 2 or pont(x, y, max(0.0, min(1.0, f))):
                out[y][x] = claro if luz.get(c, True) else sombra
    return out


def mata_sazonal(px, estacao, hora):
    """Mata distante na estação: silhueta de copas com a ponta esquerda irregular (não mais
    um corte reto) e textura de folhagem. Outono: laranja e ferrugem com copas separadas.
    Inverno: neve nas copas e verde escuro salpicado de neve por baixo."""
    hh, w = len(px), len(px[0])
    topo = [next((y for y in range(hh) if px[y][x] is not None), None) for x in range(w)]
    xs = [x for x in range(w) if topo[x] is not None]
    if not xs:
        return px
    x0 = xs[0]
    out = [[None] * w for _ in range(hh)]
    noite = hora == "noite"
    # separações entre copas em larguras irregulares (5 a 11 px), sem padrão repetido
    import random as _r
    rr = _r.Random(909)
    separacoes, x = set(), x0
    while x < w:
        x += rr.randint(5, 11)
        separacoes.add(x)
    for x in xs:
        t = topo[x]
        # a ponta esquerda afina em copas soltas, em vez de terminar num corte reto
        if x < x0 + 18:
            sobe = (x - x0) * 0.7 + 3 * math.sin(x * 0.9) - 2
            t = max(t, round(121 - max(0, sobe)))
            if t >= 121:
                continue
        for y in range(t, hh):
            if px[y][x] is None:
                continue
            d = y - t
            sep = (x + 3) % 9 == 0 and d > 1           # separação entre copas
            if estacao == "outono":
                if hora == "dia":
                    if d == 0:
                        c = 21
                    elif d < 3:
                        c = 21 if pont(x, y, 0.55) else 24
                    else:
                        c = 23 if sep or (y > 116 and pont(x, y, 0.45)) else 24
                        if h(x, y, 11) < 0.07:
                            c = 16
                        elif h(x, y, 12) < 0.08:
                            c = 21
                else:
                    c = px[y][x]
            else:  # inverno
                claro, meio, corpo, escuro = (31, 0, 13, 3) if not noite else (11, 5, 3, 30)
                if hora == "entardecer":
                    claro, meio, corpo, escuro = 12, 7, 4, 3
                sep_i = x in separacoes and d > 1
                if d == 0:
                    c = claro
                elif d == 1:
                    c = claro if h(x, y, 21) < 0.7 else meio
                elif d < 4:
                    c = meio if h(x, y, 22) < 0.55 - d * 0.1 else corpo
                else:
                    c = escuro if sep_i or (y > 116 and h(x, y, 23) < 0.35) else corpo
                    if h(x, y, 13) < 0.06:
                        c = claro
            out[y][x] = c
    return out


def ceu_inverno(hora):
    """Céu de inverno: mais frio e pálido. Mesmo sol, lua e nuvens do verão."""
    from comum import cena
    cfg = dict(cena.HORARIOS[hora])
    if hora == "dia":
        cfg.update(ceu=[1, 19, 0], faixas=[(30, 14), (74, 12)], sol_cores=(31, 31, 0), nuvem=(31, 0, 19))
    else:
        cfg.update(ceu=[4, 5, 7, 12], faixas=[(22, 12), (46, 12), (68, 9)], nuvem=(12, 7, 5))
    t = cena.Tela()
    cena.pintar_ceu(t, cfg, random.Random(7))
    cena.pintar_sol(t, cfg)
    cena.pintar_nuvens(t, cfg, hora, random.Random(4))
    return t.p


PELE, PELE_S, ROUPA = 26, 25, 28        # cores-base dos habitantes (trocas.json)
PASTAS_PESSOAS = ("habitantes", "acoes", "estagio2", "estagio3", "estagio4", "estagio5", "estagio6")
PREFIXOS_PESSOAS = ("adulto_", "crianca", "idoso", "guerreiro", "ferreiro", "escriba", "pescar", "carregar",
                    "construir", "forjar", "escrever", "remar", "lutar", "dancar", "olhar", "esticar", "sentar",
                    "agachar", "cocar", "bocejar", "conversar", "mae_", "casal", "funeral", "tocar", "andar_",
                    "segurar", "colher_arbusto", "cavar", "catar", "cacar", "cozinhar", "buscar", "banhar",
                    "vigia", "contar", "ouvir", "criancas", "tropecar", "espantar", "discutir", "abraco", "lavar", "acender")


def vestir_inverno(px, qw, qh, idoso=False):
    """Roupa de frio sobre as cores-base: capuz de lã sobre o cabelo (9/10), manto nas
    costas (8), mangas de lã (o braço vira 10/9, as mãos ficam), polainas (9/8) e gola de
    pele (12). Pele e roupa continuam trocáveis; com o capuz, o cabelo não aparece.
    O cabelo branco do idoso (12 e 31) só vira capuz nas folhas de idoso: nas outras, 12 e 31
    na altura da cabeça são objetos (palha do cesto, ponta da lança) e ficam como estão."""
    cabelos = CABELOS_BASE if idoso else {c: t for c, t in CABELOS_BASE.items() if c in (30, 8)}
    out = [l[:] for l in px]
    w = len(px[0])
    adulto = qh == 12
    mangas = range(4, 7) if adulto else range(4, 5)
    pernas = range(9, 11) if adulto else range(6, 7)
    for q0 in range(0, w, qw):
        for y in mangas:
            for x in range(q0, q0 + qw):
                if out[y][x] == PELE:
                    out[y][x] = 10
                elif out[y][x] == PELE_S:
                    out[y][x] = 9
        for y in pernas:
            for x in range(q0, q0 + qw):
                if out[y][x] == PELE:
                    out[y][x] = 9
                elif out[y][x] == PELE_S:
                    out[y][x] = 8
        # gola: as pontas da roupa na linha dos ombros
        y = 4
        xs = [x for x in range(q0, q0 + qw) if px[y][x] == ROUPA]
        for x in (xs[:1] + xs[-1:]) if xs else []:
            out[y][x] = 12
        # capuz de lã sobre o cabelo (o rosto fica de fora)
        topo_cab = range(0, 6) if adulto else range(0, 3)
        for y in topo_cab:
            for x in range(q0, q0 + qw):
                if px[y][x] in cabelos:
                    out[y][x] = CAPUZ[cabelos[px[y][x]]]
        # manto: uma coluna a mais de lã nas costas, do ombro à cintura
        for y in (range(4, 9) if adulto else range(4, 6)):
            xs = [x for x in range(q0, q0 + qw) if px[y][x] is not None]
            if xs and xs[0] - 1 >= q0 and out[y][xs[0] - 1] is None:
                out[y][xs[0] - 1] = 8
    return out


CABELOS_BASE = {30: "claro", 12: "claro", 8: "luz", 31: "luz"}   # cabelo e brilho (adulto e idoso)
CAPUZ = {"claro": 9, "luz": 10}


def gelo():
    """Superfície do lago congelada (8x8), para as colunas de água perto da margem."""
    q = [[None] * 8 for _ in range(8)]
    for x in range(8):
        q[0][x] = 31 if x % 5 else None
        q[1][x] = 31
        q[2][x] = 0
        q[3][x] = 0 if x % 3 else 19
        for y in range(4, 8):
            q[y][x] = 18 if not (x + y) % 7 == 0 else 19
    q[3][5] = 12
    q[4][6] = 12                               # rachadura no gelo
    return q


def neve_caindo():
    """Neve caindo, 64x64 que repete nas duas direções, 4 quadros (descem 2 px e
    balançam 1 px por quadro)."""
    n = 64
    rng = random.Random(601)
    flocos = [(rng.randrange(n), rng.randrange(n), rng.random() < 0.25) for _ in range(34)]
    quadros = []
    for k in range(4):
        q = [[None] * n for _ in range(n)]
        for x0, y0, grande in flocos:
            y = (y0 + k * 2) % n
            x = (x0 + (1 if (y0 + k) % 4 < 2 else 0)) % n
            q[y][x] = 31
            if grande:
                q[y][(x + 1) % n] = 0
                q[(y + 1) % n][x] = 0
        quadros.append(q)
    return quadros


def flocos():
    out = []
    for f in ([(1, 1, 31)], [(1, 1, 31), (2, 1, 0), (1, 2, 0)], [(1, 0, 0), (0, 1, 0), (1, 1, 31), (2, 1, 0), (1, 2, 0)]):
        q = [[None] * 4 for _ in range(4)]
        for x, y, c in f:
            q[y][x] = c
        out.append(q)
    return out


def principal():
    contagem = {e: 0 for e in ESTACOES}
    for pasta in ("terreno",) + PASTAS_CONSTRUCAO:
        for f in sorted((PECAS / pasta).glob("*.png")):
            px = ler(f)
            for est in ESTACOES:
                v = variante(pasta, f.stem, px, est)
                if v is not None:
                    gravar(v, AQUI / est / pasta / f.name, ampliar=False)
                    contagem[est] += 1
    # montanhas, mata e gelo
    linhas = {"montanhas_longe": 16, "montanhas_perto": 6, "mata_distante": 0}
    for nome, ln in linhas.items():
        for hora in ("entardecer", "dia", "noite"):
            px = ler(PECAS / "montagem" / f"{nome}_{hora}.png")
            v = montanha_inverno(px, ln, hora) if nome != "mata_distante" else mata_sazonal(px, "inverno", hora)
            gravar(v, AQUI / "inverno" / "montagem" / f"{nome}_{hora}.png", ampliar=False)
            contagem["inverno"] += 1
    # outono: a mata distante enferruja (de dia) e ganha copas de verdade
    px = ler(PECAS / "montagem" / "mata_distante_dia.png")
    gravar(mata_sazonal(px, "outono", "dia"), AQUI / "outono" / "montagem" / "mata_distante_dia.png", ampliar=False)
    # inverno: céu mais frio e pálido
    for hora in ("dia", "entardecer"):
        gravar(ceu_inverno(hora), AQUI / "inverno" / "montagem" / f"ceu_{hora}.png", ampliar=False)
    gravar(gelo(), AQUI / "inverno" / "terreno" / "gelo_superficie.png", ampliar=False)
    # roupa de inverno dos habitantes (folhas de 8x12, 12x12 e 6x8)
    import re
    for pasta in PASTAS_PESSOAS:
        for f in sorted((PECAS / pasta).glob("*.png")):
            if not f.stem.startswith(PREFIXOS_PESSOAS) or f.stem.startswith(("amostra", "dormir")):
                continue
            px = ler(f)
            m = re.search(r"_(\d+)q$", f.stem)
            n = int(m.group(1)) if m else 1
            qh = len(px)
            if qh not in (8, 12):
                continue
            gravar(vestir_inverno(px, len(px[0]) // n, qh, f.stem.startswith("idoso")), AQUI / "inverno" / pasta / f.name, ampliar=False)
            contagem["inverno"] += 1
    gravar(folha_quadros(neve_caindo()), PECAS / "efeitos" / "neve_4q.png")
    gravar(folha_quadros(flocos()), PECAS / "efeitos" / "floco_3v.png")
    print("estações:", contagem)


if __name__ == "__main__":
    principal()

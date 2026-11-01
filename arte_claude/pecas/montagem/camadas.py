"""Camadas que no jogo são efeitos do motor, entregues como arquivos próprios.

- ceu_<hora>.png: céu em degradê pontilhado, sol ou lua, estrelas e nuvens (480x160, opaco);
- montanhas_longe_<hora>.png e montanhas_perto_<hora>.png: os 2 planos de montanha;
- mata_distante_<hora>.png: a linha de copas logo atrás do mundo;
- reflexo_<hora>.png: traços de reflexo, brilhos e raios de luz na água;
- luz_fogueira.png e luz_fogueira_halo.png: mapas de luz (dados, não arte; veja LEIA-ME);
- tabelas_luz.json: as tabelas de troca de cor por horário e por nível de luz.

Tudo sai das mesmas funções e sementes da cena-alvo, então bate pixel a pixel com ela.
"""
from pathlib import Path
import json
import math
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import cena, clamp, gravar, pont  # noqa: E402

W, H = cena.W, cena.H
HORAS = ("entardecer", "dia", "noite")

# Mapa de luz da fogueira: origem relativa ao canto da peça fogueira_acesa (16x16).
LUZ_W, LUZ_H = 128, 80
LUZ_DESLOC = (-56, -32)          # canto do mapa = canto da peça + deslocamento
LUZ_CENTRO = (8, 10)             # centro da luz dentro da peça da fogueira


class TelaFases:
    """Tela em que cada chamada de `cordilheira` vai para um plano separado."""

    def __init__(self, n):
        self.planos = [[[None] * W for _ in range(H)] for _ in range(n)]
        self.fase = 0
        self.tag = [[cena.CEU] * W for _ in range(H)]

    @property
    def p(self):
        return self.planos[self.fase]

    def put(self, x, y, c, tag=None, lado=0):
        if 0 <= x < W and 0 <= y < H:
            self.planos[self.fase][y][x] = c

    def get(self, x, y):
        return self.p[y][x] if 0 <= x < W and 0 <= y < H else None


def ceu(hora):
    cfg = cena.HORARIOS[hora]
    t = cena.Tela()
    cena.pintar_ceu(t, cfg, random.Random(7))
    if hora == "noite":
        cena.pintar_lua(t, cfg, random.Random(3))
    else:
        cena.pintar_sol(t, cfg)
    cena.pintar_nuvens(t, cfg, hora, random.Random(4))
    return t.p


def fundo(hora):
    """Devolve (montanhas_longe, montanhas_perto, mata_distante)."""
    cfg = cena.HORARIOS[hora]
    t = TelaFases(3)
    original = cena.cordilheira

    def cordilheira(tela, *a, **k):
        original(tela, *a, **k)
        tela.fase += 1

    cena.cordilheira = cordilheira
    try:
        cena.pintar_fundo(t, cfg, hora, random.Random(5))
    finally:
        cena.cordilheira = original
    return t.planos


def reflexo(hora):
    """Mesmos laços e semente de `cena.pintar_agua`, sem a água em si."""
    cfg = cena.HORARIOS[hora]
    sup, _ = cena.perfil(random.Random(11))
    agua = [[sup[x] > y >= cena.NIVEL_AGUA for x in range(W)] for y in range(H)]
    out = [[None] * W for _ in range(H)]
    clara, escura, brilho = cfg["agua"]
    if hora != "noite":
        for x in range(W):
            for y in range(cena.NIVEL_AGUA + 1, H):
                d = y - cena.NIVEL_AGUA
                if agua[y][x] and d > 3 and (x - d * 2) % 23 in (0, 1) and pont(x, y, 0.45):
                    out[y][x] = clara
    rng = random.Random(6)
    luz_reflexo, luz2, _ = cfg["reflexo"]
    ref_x = cfg["sol"][0] if "sol" in cfg else cfg["lua"][0]
    for y in range(cena.NIVEL_AGUA + 1, cena.NIVEL_AGUA + 12):
        d = y - cena.NIVEL_AGUA
        larg = 3 + d * 1.6
        for _ in range(3):
            x0 = int(ref_x + rng.uniform(-larg, larg))
            comp = rng.randint(2, 6 if d < 6 else 4)
            for x in range(x0, x0 + comp):
                if 0 <= x < W and agua[y][x]:
                    out[y][x] = luz_reflexo if abs(x - ref_x) < larg * 0.5 else luz2
    for _ in range(26):
        x, y = rng.randrange(0, 100), rng.randrange(cena.NIVEL_AGUA + 1, cena.NIVEL_AGUA + 8)
        if agua[y][x]:
            for i in range(rng.randint(2, 4)):
                if agua[y][x + i]:
                    out[y][x + i] = brilho
    return out


def mapas_luz():
    """Níveis já pontilhados: 0 = noite, 1 = luz média, 2 = luz perto; halo: 0 ou 1.
    O pontilhado foi calculado para o mapa com o canto em coordenadas múltiplas de 4."""
    luz = [[0] * LUZ_W for _ in range(LUZ_H)]
    halo = [[0] * LUZ_W for _ in range(LUZ_H)]
    cx = LUZ_CENTRO[0] - LUZ_DESLOC[0]
    cy = LUZ_CENTRO[1] - LUZ_DESLOC[1]
    for y in range(LUZ_H):
        for x in range(LUZ_W):
            d = math.hypot(x - cx, (y - cy) * 1.7)
            nivel = clamp((62 - d) / 3) + clamp((34 - d) / 3)
            if nivel >= 1:
                luz[y][x] = 2 if pont(x, y, clamp(nivel - 1)) else 1
            else:
                luz[y][x] = 1 if pont(x, y, clamp(nivel)) else 0
            halo[y][x] = 1 if pont(x, y, clamp((40 - d) / 10)) else 0
    return luz, halo


def tabelas():
    return {
        "nota": "índices da paleta; chave = cor de dia da peça, valor = cor a usar",
        "noite": cena.REMAP_NOITE,
        "noite_agua": {18: 17, 17: 4, 19: 0},
        "noite_primeiro_plano": {"13": 3, "14": 3, "3": 30, "outras": 3},
        "fogo_perto": cena.FOGO_PERTO,
        "fogo_medio": cena.FOGO_MEDIO,
        "halo_ceu": {30: 3, 3: 4, 4: 5},
        "entardecer": cena.REMAP_ENTARDECER,
        "entardecer_contorno_pessoas": cena.CONTORNO_SOL,
    }


def principal():
    for hora in HORAS:
        gravar(ceu(hora), AQUI / f"ceu_{hora}.png")
        longe, perto, mata = fundo(hora)
        gravar(longe, AQUI / f"montanhas_longe_{hora}.png")
        gravar(perto, AQUI / f"montanhas_perto_{hora}.png")
        gravar(mata, AQUI / f"mata_distante_{hora}.png")
        gravar(reflexo(hora), AQUI / f"reflexo_{hora}.png")
    luz, halo = mapas_luz()
    img = Image.new("L", (LUZ_W, LUZ_H))
    img.putdata([v * 127 + (v == 2) for linha in luz for v in linha])
    img.save(AQUI / "luz_fogueira.png")
    img = Image.new("L", (LUZ_W, LUZ_H))
    img.putdata([v * 255 for linha in halo for v in linha])
    img.save(AQUI / "luz_fogueira_halo.png")
    (AQUI / "tabelas_luz.json").write_text(json.dumps(tabelas(), indent=2, ensure_ascii=False),
                                          encoding="utf-8")
    print("camadas: céu, montanhas (2 planos), mata e reflexo por horário; mapas de luz; tabelas")


if __name__ == "__main__":
    principal()

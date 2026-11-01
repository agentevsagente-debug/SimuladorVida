"""Noite nas construções: janelas acesas como camada de luz separada, e chaminé com fumaça
para as casas com lareira no inverno.

- `<estagio>/<casa>_luz.png`: só as janelas acesas, do mesmo tamanho e encaixe da casa.
  O motor desenha por cima da casa à noite (e ao entardecer), sem passar pela tabela
  `noite`, porque é luz;
- `luzes/chamine.png` (4x8) e `luzes/chamines.json`: onde pôr a chaminé em cada casa,
  para cada um dos 3 telhados de cultura, e de onde sai a fumaça;
- `luzes/fumaca_chamine_4q.png` (8x16): fiapo de fumaça fino e irregular (sem pontilhado
  em grade), que sobe e se desfaz.
"""
from pathlib import Path
import json
import random
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent
sys.path.insert(0, str(PECAS))

from comum import PALETA, cena, folha_quadros, gravar, para_imagem  # noqa: E402

INDICE = {rgb: i for i, rgb in enumerate(PALETA)}
CASAS = [("estagio2", "casa_taipa"), ("estagio3", "casa_pedra"), ("estagio4", "casa_enxaimel"),
         ("estagio6", "casa_tijolo")]
TELHADOS = ("palha", "telha", "tabuas")


def ler(caminho):
    img = Image.open(caminho).convert("RGBA")
    px = list(img.getdata())
    return [[None if px[y * img.width + x][3] == 0 else INDICE[px[y * img.width + x][:3]]
             for x in range(img.width)] for y in range(img.height)]


def janelas(parede):
    """Componentes escuros (30) da parede que não tocam a base: são as janelas (as portas
    descem até o chão)."""
    h, w = len(parede), len(parede[0])
    visto, comps = set(), []
    for y in range(h):
        for x in range(w):
            if parede[y][x] == 30 and (x, y) not in visto:
                pilha, comp = [(x, y)], []
                visto.add((x, y))
                while pilha:
                    cx, cy = pilha.pop()
                    comp.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visto and parede[ny][nx] == 30:
                            visto.add((nx, ny))
                            pilha.append((nx, ny))
                if max(p[1] for p in comp) < h - 3 and len(comp) <= 16:
                    comps.append(comp)
    return comps


def camada_luz(parede):
    h, w = len(parede), len(parede[0])
    q = [[None] * w for _ in range(h)]
    for comp in janelas(parede):
        ys = [p[1] for p in comp]
        xs = [p[0] for p in comp]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        for x, y in comp:
            c = 21 if y == min(ys) else 22
            if abs(x - cx) < 0.6 and abs(y - cy) < 0.6:
                c = 31
            q[y][x] = c
    return q


def chamine():
    return [[None if ch == "." else {"G": 12, "g": 11, "d": 8, "x": 30}[ch] for ch in l] for l in
            ["dxxd", "GggG", "Gggd", "gGgd", "Gggd", "gGgd", "Gggd", "gGgd"]]


def fumaca_chamine():
    """Fiapo fino: 3 a 6 tufos de 1 a 2 px subindo e balançando, cada vez mais ralos.
    Sorteio fixo por quadro, sem grade."""
    quadros = []
    for k in range(4):
        rng = random.Random(800 + k)
        q = [[None] * 8 for _ in range(16)]
        x = 3.5
        for y in range(15, -1, -1):
            x += rng.choice((-0.5, 0, 0, 0.5)) + (0.25 if (y + k * 3) % 6 < 3 else -0.15)
            subida = 15 - y
            if rng.random() < 0.85 - subida * 0.045:
                xi = max(0, min(7, round(x)))
                q[y][xi] = 12 if subida < 6 else 11
                if subida < 5 and rng.random() < 0.5 and xi + 1 < 8:
                    q[y][xi + 1] = 11
        quadros.append(q)
    return quadros


def principal():
    posicoes = {}
    for pasta, casa in CASAS:
        parede = ler(PECAS / pasta / f"{casa}_parede.png")
        luz = camada_luz(parede)
        gravar(luz, PECAS / pasta / f"{casa}_luz.png")
        w = len(parede[0])
        for t in TELHADOS:
            arq = PECAS / pasta / f"{casa}_telhado_{t}.png"
            if not arq.exists():          # a casa de taipa usa os telhados de culturas/
                arq = PECAS / "culturas" / f"casa_telhado_{t}.png"
            tel = ler(arq)
            x0 = int(w * 0.68)
            topo = min((y for y in range(len(tel)) for x in range(x0, x0 + 4) if tel[y][x] is not None),
                       default=0)
            y0 = max(0, topo + 3 - 7)
            posicoes[f"{casa}_telhado_{t}"] = {"chamine_x": x0, "chamine_y": y0, "fumaca_x": x0 - 2,
                                               "fumaca_base_y": y0 - 1}
    gravar(chamine(), AQUI / "chamine.png")
    gravar(folha_quadros(fumaca_chamine()), AQUI / "fumaca_chamine_4q.png")
    (AQUI / "chamines.json").write_text(json.dumps({
        "nota": "coordenadas relativas ao canto da peça da casa: a chaminé (4x8) vai em (chamine_x, chamine_y), "
                "por cima do telhado; a fumaca_chamine_4q (8x16) vai com a última linha em fumaca_base_y e o "
                "canto esquerdo em fumaca_x. Só no inverno, nas casas com lareira.",
        "casas": posicoes}, indent=1, ensure_ascii=False), encoding="utf-8")
    amostra(posicoes)
    print("luzes:", len(CASAS), "casas com janelas acesas; chaminé e fumaça")


def amostra(posicoes):
    """As casas de noite no inverno: casa remapeada para a noite, janelas acesas, chaminé
    e fumaça."""
    noite = {int(k): v for k, v in cena.REMAP_NOITE.items()}
    W, H = 4 + len(CASAS) * 36, 40
    img = Image.new("RGBA", (W, H), PALETA[3] + (255,))
    fum = folha_quadros(fumaca_chamine())
    for i, (pasta, casa) in enumerate(CASAS):
        sazonal = PECAS / "estacoes" / "inverno" / pasta / f"{casa}.png"
        px = ler(sazonal if sazonal.exists() else PECAS / pasta / f"{casa}.png")
        px = [[noite.get(c, c) if c is not None else None for c in l] for l in px]
        x0, y0 = 4 + i * 36, H - len(px) - 1
        tel = "telha" if casa != "casa_enxaimel" else "tabuas"
        pos = posicoes[f"{casa}_telhado_{tel}"]
        ch = [[noite.get(c, c) if c is not None else None for c in l] for l in chamine()]
        img.alpha_composite(para_imagem(ch), (x0 + pos["chamine_x"], y0 + pos["chamine_y"]))
        img.alpha_composite(para_imagem(px), (x0, y0))
        img.alpha_composite(para_imagem(ler(PECAS / pasta / f"{casa}_luz.png")), (x0, y0))
        q = [l[(i % 4) * 8:(i % 4) * 8 + 8] for l in fum]
        img.alpha_composite(para_imagem(q), (x0 + pos["fumaca_x"], max(0, y0 + pos["fumaca_base_y"] - 15)))
    img.save(AQUI / "amostra_luzes.png")
    img.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_luzes_4x.png")


if __name__ == "__main__":
    principal()

"""Prepara as peças do céu vivo a partir das camadas de céu da sessão C.

Lê arte_claude/atlas/camadas/ (faixa de degradê 4 × 160 e camada de detalhes
de cada céu) e grava em jogo/arte/ceu/:
- faixa_<céu>.png: o degradê, repetido na largura pelo jogo;
- nuvens_<céu>.png e .json: cada nuvem da arte numa folha, com a camada de
  profundidade (longe, meio, perto) escolhida pelo tamanho; os fiapos finos
  vão para longe;
- estrelas.png e .json: as estrelas da noite, com o brilho (tamanho e cor).
O sol e a lua da arte ficam de fora: o jogo os desenha em arco, ligados ao
relógio, e a lua com fases.

Uso: python -I jogo/ferramentas/preparar_ceu.py   (da raiz do repositório)
"""
import json
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
ORIGEM = RAIZ / "arte_claude" / "atlas" / "camadas"
DESTINO = RAIZ / "jogo" / "arte" / "ceu"
CEUS = ["ceu_dia", "ceu_entardecer", "ceu_noite", "ceu_dia_inverno", "ceu_entardecer_inverno"]
## O sol e a lua da arte, a tirar: (centro x, centro y, raio) na camada de detalhes.
ASTROS = {"ceu_dia": (35, 12, 12, 17), "ceu_dia_inverno": (35, 12, 12, 17),
          "ceu_entardecer": (61, 76, 14, 999), "ceu_entardecer_inverno": (61, 76, 14, 999),
          "ceu_noite": (103, 31, 13, 999)}


def componentes(img, juntar):
    """Grupos de pixels opacos; pixels a até `juntar` px de distância ficam no mesmo grupo."""
    px = img.load()
    w, h = img.size
    visto = set()
    grupos = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 or (x, y) in visto:
                continue
            pilha, grupo = [(x, y)], []
            visto.add((x, y))
            while pilha:
                cx, cy = pilha.pop()
                grupo.append((cx, cy))
                for dy in range(-juntar, juntar + 1):
                    for dx in range(-juntar, juntar + 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visto and px[nx, ny][3] > 0:
                            visto.add((nx, ny))
                            pilha.append((nx, ny))
            grupos.append(grupo)
    return grupos


def caixa(grupo):
    xs = [p[0] for p in grupo]
    ys = [p[1] for p in grupo]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def folha(img, grupos):
    """Põe cada grupo numa folha horizontal (1 px entre eles) e devolve a folha e as regiões."""
    caixas = [caixa(g) for g in grupos]
    largura = sum(c[2] + 1 for c in caixas) or 1
    altura = max([c[3] for c in caixas] or [1])
    out = Image.new("RGBA", (largura, altura), (0, 0, 0, 0))
    px, opx = img.load(), out.load()
    regioes, sx = [], 0
    for g, (x0, y0, w, h) in zip(grupos, caixas):
        for x, y in g:
            opx[sx + x - x0, y - y0] = px[x, y]
        regioes.append({"sx": sx, "w": w, "h": h, "x": x0, "y": y0})
        sx += w + 1
    return out, regioes


def principal():
    DESTINO.mkdir(parents=True, exist_ok=True)
    meta = json.loads((RAIZ / "arte_claude" / "atlas" / "camadas.json").read_text(encoding="utf-8"))["camadas"]
    for ceu in CEUS:
        m = meta[ceu]
        Image.open(ORIGEM / m["faixa"]).save(DESTINO / f"faixa_{ceu[4:]}.png")
        img = Image.open(ORIGEM / m["detalhes"]).convert("RGBA")
        px = img.load()
        cx, cy, r, ate_y = ASTROS[ceu]
        for y in range(img.height):
            for x in range(img.width):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and y <= ate_y:
                    px[x, y] = (0, 0, 0, 0)
        grupos = componentes(img, 2)
        nuvens = [g for g in grupos if caixa(g)[2] >= 12]
        out, regioes = folha(img, nuvens)
        for reg in regioes:
            # longe: fiapos finos e nuvens pequenas; perto: as maiores
            reg["camada"] = "longe" if reg["h"] <= 3 or reg["w"] < 40 else ("perto" if reg["w"] >= 60 else "meio")
            reg["y"] += m["detalhes_y"]
        out.save(DESTINO / f"nuvens_{ceu[4:]}.png")
        (DESTINO / f"nuvens_{ceu[4:]}.json").write_text(json.dumps(regioes, indent=1), encoding="utf-8")
        if ceu == "ceu_noite":
            de_nuvem = {p for g in nuvens for p in g}
            estrelas = [g for g in componentes(img, 0) if len(g) <= 6 and not any(p in de_nuvem for p in g)]
            out, regioes = folha(img, estrelas)
            for g, reg in zip(estrelas, regioes):
                claro = max(sum(px[x, y][:3]) for x, y in g)
                reg["brilho"] = round(len(g) * 100 + claro / 7.65)  # maiores e mais claras primeiro
                reg["x"] += m["detalhes_x"]
                reg["y"] += m["detalhes_y"]
            out.save(DESTINO / "estrelas.png")
            (DESTINO / "estrelas.json").write_text(json.dumps(regioes, indent=1), encoding="utf-8")
        print(ceu, "nuvens:", len(nuvens), {c: sum(1 for r in json.loads((DESTINO / f'nuvens_{ceu[4:]}.json').read_text())
                                              if r['camada'] == c) for c in ('longe', 'meio', 'perto')})
    print("estrelas:", len(json.loads((DESTINO / "estrelas.json").read_text())))


if __name__ == "__main__":
    principal()

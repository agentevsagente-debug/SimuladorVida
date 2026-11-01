"""Camadas grandes reduzidas, sem perder nenhum pixel.

- montanhas, mata distante e reflexo: recortadas ao retângulo que tem pixels, com o
  deslocamento no JSON (o motor desenha o recorte em x, y);
- céus: o degradê pontilhado se repete a cada 4 px na horizontal (o pontilhado Bayer é
  4x4), então vira uma faixa de 4x160 que o motor repete, mais uma camada de detalhes
  (sol ou lua, nuvens, estrelas) recortada ao seu retângulo.

`camadas.json` traz, para cada camada, os arquivos, o deslocamento e a memória antes e
depois. O script confere que a remontagem dá exatamente a camada original.
"""
from pathlib import Path
import json

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent / "pecas"
SAIDA = AQUI / "camadas"


def fontes():
    """(nome, caminho) de todas as camadas grandes, de verão e das estações."""
    out = []
    for f in sorted((PECAS / "montagem").glob("*.png")):
        if f.stem.startswith(("ceu_", "montanhas_", "mata_", "reflexo_")):
            out.append((f.stem, f))
    for est in ("primavera", "outono", "inverno"):
        for f in sorted((PECAS / "estacoes" / est / "montagem").glob("*.png")):
            out.append((f"{f.stem}_{est}", f))
    return out


def recortar(img):
    caixa = img.getbbox()
    return img.crop(caixa), caixa[:2]


def faixa_do_ceu(img):
    """A coluna de 4 px que mais se repete em cada linha forma a faixa; o que difere dela
    vira detalhe."""
    W, H = img.size
    px = img.load()
    faixa = Image.new("RGBA", (4, H))
    for y in range(H):
        for fase in range(4):
            contagem = {}
            for x in range(fase, W, 4):
                contagem[px[x, y]] = contagem.get(px[x, y], 0) + 1
            faixa.putpixel((fase, y), max(contagem, key=contagem.get))
    det = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fp = faixa.load()
    for y in range(H):
        for x in range(W):
            if px[x, y] != fp[x % 4, y]:
                det.putpixel((x, y), px[x, y])
    return faixa, det


def principal():
    SAIDA.mkdir(exist_ok=True)
    info, antes, depois = {}, 0, 0
    for nome, f in fontes():
        img = Image.open(f).convert("RGBA")
        W, H = img.size
        antes += W * H * 4
        if nome.startswith("ceu_"):
            faixa, det = faixa_do_ceu(img)
            faixa.save(SAIDA / f"{nome}_faixa.png")
            if det.getbbox():
                rec, (x0, y0) = recortar(det)
                rec.save(SAIDA / f"{nome}_detalhes.png")
            else:
                rec, x0, y0 = None, 0, 0
            # confere a remontagem
            rem = Image.new("RGBA", (W, H))
            for x in range(0, W, 4):
                rem.paste(faixa, (x, 0))
            if rec is not None:
                rem.alpha_composite(rec, (x0, y0))
            assert list(rem.getdata()) == list(img.getdata()), nome
            mem = 4 * H * 4 + (rec.width * rec.height * 4 if rec else 0)
            info[nome] = {"faixa": f"{nome}_faixa.png", "detalhes": f"{nome}_detalhes.png" if rec else None,
                          "detalhes_x": x0, "detalhes_y": y0, "bytes_antes": W * H * 4, "bytes_depois": mem}
        else:
            rec, (x0, y0) = recortar(img)
            rec.save(SAIDA / f"{nome}.png")
            rem = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            rem.alpha_composite(rec, (x0, y0))
            assert list(rem.getdata()) == list(img.getdata()), nome
            mem = rec.width * rec.height * 4
            info[nome] = {"arquivo": f"{nome}.png", "x": x0, "y": y0, "w": rec.width, "h": rec.height,
                          "bytes_antes": W * H * 4, "bytes_depois": mem}
        depois += mem
    (AQUI / "camadas.json").write_text(json.dumps(
        {"nota": "céu: repita a faixa 4x160 na horizontal e ponha os detalhes em (detalhes_x, detalhes_y); "
                 "demais: desenhe o recorte em (x, y) da área de 480x160",
         "bytes_antes": antes, "bytes_depois": depois, "camadas": info}, indent=1, ensure_ascii=False),
        encoding="utf-8")
    print(f"camadas: {len(info)}; antes {antes / 1024 / 1024:.2f} MB, depois {depois / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    principal()

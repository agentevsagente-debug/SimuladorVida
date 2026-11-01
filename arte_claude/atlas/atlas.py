"""Atlas de texturas a partir das peças de `arte_claude/pecas/` (os originais não mudam).

- `comum`: habitantes, ações, interface, fonte, sinais, efeitos, criaturas, objetos, estante
  e as marcas da memória que servem a todos os estágios;
- `estacao_<primavera|verao|outono|inverno>`: terreno e vegetação da estação;
- `estagio<N>` e `estagio<N>_inverno`: construções, ruínas (com o mato), culturas e
  habitantes de cada estágio, de verão e com neve.

Cada atlas é potência de 2 (até 2048x1024), com 1 px de margem transparente entre as
peças, e vem com `<atlas>.json`: para cada peça, o retângulo da folha inteira, o número de
quadros e o tamanho de cada quadro. As fontes ganham um `.fnt` que aponta para o atlas.

As camadas grandes (céus, montanhas, mata, reflexo) ficam fora; o script `camadas.py`
gera as versões recortadas e em faixa (veja o LEIA-ME).
"""
from pathlib import Path
import json
import re

from PIL import Image

AQUI = Path(__file__).resolve().parent
PECAS = AQUI.parent / "pecas"
FORA = ("amostra", "comparacao", "montagem_", "terreno_teste", "blocos_prancha", "cena_", "icone_jogo",
        "variacoes_pele_roupa")
LARGURA_QUADRO_ESPECIAL = {
    # folhas cujo quadro não sai da regra "largura / N"
}


def pngs(pasta, filtro=lambda f: True):
    base = PECAS / pasta
    if not base.exists():
        return []
    return sorted(f for f in base.glob("*.png") if not f.stem.startswith(FORA) and filtro(f))


def quadros_de(nome, w):
    m = re.search(r"_(\d+)([qv])$", nome)
    n = int(m.group(1)) if m else 1
    return n, (m.group(2) if m else "q"), w // n


def empacotar(itens):
    """Prateleiras por altura decrescente. Devolve (largura, altura, posições) no menor
    tamanho potência de 2 que couber, até 2048x1024."""
    itens = sorted(itens, key=lambda it: (-it[1].height, -it[1].width, it[0]))
    tamanhos = sorted({(w, h) for w in (64, 128, 256, 512, 1024, 2048) for h in (64, 128, 256, 512, 1024)
                       if h <= w <= 2 * h or (w, h) == (2048, 1024)}, key=lambda t: (t[0] * t[1], t[0]))
    for W, H in tamanhos:
        pos, x, y, alt_linha = {}, 1, 1, 0
        ok = True
        for nome, img in itens:
            w, h = img.width, img.height
            if x + w + 1 > W:
                x, y, alt_linha = 1, y + alt_linha + 1, 0
            if y + h + 1 > H or w + 2 > W:
                ok = False
                break
            pos[nome] = (x, y)
            x += w + 1
            alt_linha = max(alt_linha, h)
        if ok:
            return W, H, pos
    raise ValueError("não coube em 2048x1024")


def gerar_atlas(nome, entradas):
    """entradas: lista de (nome da peça, caminho do PNG)."""
    itens = [(n, Image.open(c).convert("RGBA")) for n, c in entradas]
    W, H, pos = empacotar(itens)
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    regioes = {}
    for n, img in itens:
        x, y = pos[n]
        atlas.alpha_composite(img, (x, y))
        q, tipo, qw = quadros_de(Path(n).name, img.width)
        regioes[n] = {"x": x, "y": y, "w": img.width, "h": img.height, "quadros": q,
                      "tipo": "variacoes" if tipo == "v" else "quadros", "quadro_w": qw, "quadro_h": img.height}
    atlas.save(AQUI / f"{nome}.png")
    (AQUI / f"{nome}.json").write_text(json.dumps(
        {"atlas": f"{nome}.png", "largura": W, "altura": H, "margem": 1,
         "nota": "nome = pasta/peça em arte_claude/pecas; x, y, w, h = folha inteira; os quadros vão da "
                 "esquerda para a direita, cada um com quadro_w x quadro_h",
         "regioes": dict(sorted(regioes.items()))}, indent=1, ensure_ascii=False), encoding="utf-8")
    return W, H, regioes


def fontes_no_atlas(regioes):
    """Reescreve os .fnt das 4 fontes para apontarem para o atlas comum."""
    for cor in ("clara", "escura", "dourada", "titulo"):
        r = regioes[f"interface/fonte_5x7_{cor}"]
        orig = (PECAS / "interface" / f"fonte_5x7_{cor}.fnt").read_text(encoding="utf-8").splitlines()
        out = []
        for linha in orig:
            if linha.startswith("common "):
                linha = re.sub(r"scaleW=\d+", "scaleW={W}", linha)
                linha = re.sub(r"scaleH=\d+", "scaleH={H}", linha)
            elif linha.startswith("page "):
                linha = 'page id=0 file="comum.png"'
            elif linha.startswith("char "):
                x = int(re.search(r" x=(\d+)", linha).group(1)) + r["x"]
                y = int(re.search(r" y=(\d+)", linha).group(1)) + r["y"]
                linha = re.sub(r" x=\d+", f" x={x}", linha)
                linha = re.sub(r" y=\d+", f" y={y}", linha)
            out.append(linha)
        yield cor, "\n".join(out) + "\n"


def nomeados(pasta, filtro=lambda f: True, prefixo=None):
    return [((prefixo or pasta) + "/" + f.stem, f) for f in pngs(pasta, filtro)]


def sazonal(pasta, estacao, filtro=lambda f: True):
    """Peças da pasta na estação: a variação sazonal, se existir; senão a de verão."""
    out = []
    for f in pngs(pasta, filtro):
        s = PECAS / "estacoes" / estacao / pasta / f.name
        out.append((f"{pasta}/{f.stem}", s if estacao != "verao" and s.exists() else f))
    return out


ESTAGIO_DE_RUINA = {"cabana_abandonada": 1, "casa_ruina": 2}
MEMORIA_COMUM = {"tumulo", "pedra_erguida", "terra_queimada_a", "terra_queimada_b", "arvore_queimada"}
VEGETACAO_E1 = lambda f: f.stem not in ("cabana_galhos", "fogueira_acesa_4q", "fogueira_apagada")  # noqa: E731


def principal():
    resumo = {}
    # ---- comum
    comum = []
    for pasta in ("habitantes", "acoes", "sinais", "efeitos", "criaturas", "objetos", "estante", "luzes"):
        comum += nomeados(pasta)
    comum += nomeados("interface")
    comum += nomeados("interface/icones_12", prefixo="interface/icones_12")
    comum += nomeados("interface/icones_8", prefixo="interface/icones_8")
    comum += nomeados("memoria", lambda f: f.stem in MEMORIA_COMUM)
    comum += [(f"natureza/{f.stem}", f) for f in pngs("natureza", lambda f: f.stem.startswith(("tumulo", "pedra_erguida")))]
    W, H, reg = gerar_atlas("comum", comum)
    resumo["comum"] = (W, H, len(reg))
    for cor, texto in fontes_no_atlas(reg):
        (AQUI / f"fonte_5x7_{cor}.fnt").write_text(texto.replace("{W}", str(W)).replace("{H}", str(H)),
                                                   encoding="utf-8")
    # ---- pessoas de inverno: as folhas de habitantes com a roupa de frio (troca o comum no inverno)
    inverno = []
    for pasta in ("habitantes", "acoes"):
        for f in sorted((PECAS / "estacoes" / "inverno" / pasta).glob("*.png")):
            inverno.append((f"{pasta}/{f.stem}", f))
    W, H, reg = gerar_atlas("pessoas_inverno", inverno)
    resumo["pessoas_inverno"] = (W, H, len(reg))
    # ---- nuvens soltas do céu vivo (5 climas x 3 camadas x 3 tamanhos)
    W, H, reg = gerar_atlas("nuvens", nomeados("nuvens"))
    resumo["nuvens"] = (W, H, len(reg))
    # ---- estações: terreno e vegetação
    for est in ("primavera", "verao", "outono", "inverno"):
        itens = sazonal("terreno", est) + sazonal("estagio1", est, VEGETACAO_E1)
        # agricultura: roças e pomar mudam nas 4 estações (a roda d'água congela no inverno)
        itens += sazonal("estagio2", est, lambda f: f.stem.startswith("roca_") or f.stem == "arvore_fruta")
        itens += sazonal("estagio6", est, lambda f: f.stem in ("roca_irrigada", "roda_dagua_4q"))
        itens += sazonal("natureza", est, lambda f: f.stem in ("muda", "arvore_jovem", "pinheiro_jovem", "fogueira_antiga"))
        if est == "inverno":
            itens.append(("terreno/gelo_superficie", PECAS / "estacoes" / "inverno" / "terreno" / "gelo_superficie.png"))
        W, H, reg = gerar_atlas(f"estacao_{est}", itens)
        resumo[f"estacao_{est}"] = (W, H, len(reg))
    # ---- estágios
    for n in range(1, 7):
        for inverno in (False, True):
            est = "inverno" if inverno else "verao"
            itens = []
            if n == 1:
                itens += sazonal("estagio1", est, lambda f: not VEGETACAO_E1(f))
                itens += sazonal("memoria", est, lambda f: f.stem == "cabana_abandonada")
            else:
                itens += sazonal(f"estagio{n}", est, lambda f: not (f.stem.startswith("roca_") or
                                                                   f.stem in ("arvore_fruta", "roda_dagua_4q")))
                if n == 2:
                    itens += sazonal("culturas", est)
                    itens += sazonal("memoria", est, lambda f: f.stem == "casa_ruina")
                if n == 5:   # o templo da escrita usa telhados e símbolos do templo de colunas
                    itens += sazonal("estagio4", est, lambda f: f.stem.startswith("templo_colunas_") and
                                     not f.stem.endswith(("_ruina", "_parede")) and f.stem != "templo_colunas")
            # o mato das ruínas deste estágio
            nomes_ruina = {Path(nm).name for nm, _ in itens if nm.endswith(("_ruina", "abandonada", "naufragado"))}
            itens += sazonal("natureza", est, lambda f, r=nomes_ruina: f.stem.rsplit("_mato_", 1)[0] in r)
            nome = f"estagio{n}" + ("_inverno" if inverno else "")
            W, H, reg = gerar_atlas(nome, itens)
            resumo[nome] = (W, H, len(reg))
    total = 0
    linhas = []
    for nome, (W, H, q) in resumo.items():
        mem = W * H * 4
        total += mem
        linhas.append(f"{nome}: {W}x{H}, {q} peças, {mem / 1024:.0f} KB")
    (AQUI / "resumo.txt").write_text("\n".join(linhas) + f"\ntotal: {total / 1024 / 1024:.2f} MB\n", encoding="utf-8")
    print("\n".join(linhas))
    print(f"total: {total / 1024 / 1024:.2f} MB")


if __name__ == "__main__":
    principal()

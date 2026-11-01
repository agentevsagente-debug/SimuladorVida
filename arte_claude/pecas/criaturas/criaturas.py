"""Vida ambiente: criaturas que não fazem parte da simulação, só dão vida ao mundo.
Pequenas (de 4x4 a 12x8), animadas, olhando para a direita (o motor espelha), com a base
(os pés, ou o centro do voo) na última linha do quadro.
"""
from pathlib import Path
import sys

from PIL import Image

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, folha_quadros, gravar, para_imagem  # noqa: E402

K = {"R": 24, "Q": 23, "C": 12, "x": 30, "d": 8, "n": 9, "N": 10, "G": 12, "g": 11, "W": 31, "w": 0, "y": 22, "o": 21, "r": 20,
     "v": 15, "V": 14, "m": 13, "b": 18, "c": 19, "B": 17, "e": 3, "k": 4, "K": 5, "s": 16}


def molde(*quadros):
    out = []
    for q in quadros:
        larg = len(q[0])
        assert all(len(l) == larg for l in q), q
        out.append([[None if ch == "." else K[ch] for ch in l] for l in q])
    return out


CRIATURAS = {
    # pássaro pequeno voando (asas: cima, meio, baixo, meio)
    "passaro_voar_4q": molde(
        ["n...n.", ".n.nNy", "..nn..", "......"],
        ["......", "nnnnNy", "..nn..", "......"],
        ["......", "..nnNy", ".nnn..", "n...n."],
        ["......", "nnnnNy", "..nn..", "......"],
    ),
    # pássaro pousado: olhando e bicando o chão
    "passaro_pousado_2q": molde(
        ["....", ".nNy", "nnn.", ".y.."],
        ["....", "....", "nnNN", ".y.y"],
    ),
    # peixe saltando do lago: sai, sobe, vira, mergulha (8x8)
    "peixe_saltar_4q": molde(
        ["........", "........", "........", "........", "........", "...g....", "..gGW...", ".c.cc.c."],
        ["........", "....GW..", "...gG...", "..gd....", "........", "........", "........", "..c..c.."],
        ["....ggG.", "...d..W.", "........", "........", "........", "........", "........", "........"],
        ["........", "........", "........", "....W...", ".....G..", ".....gG.", "....c.c.", "...cWc.c"],
    ),
    # sapo na margem: parado e coaxando (6x4)
    "sapo_2q": molde(
        [".xV.x.", "VvvvVv", "VmVVmV", "v....v"],
        [".xV.x.", "Vvvvvv", "VsssmV", "v....v"],
    ),
    # garça na margem (8x8): de pé e pescando
    "garca_2q": molde(
        ["...WWy..", "...W....", "...W....", "..WWw...", ".WWWww..", "..ww....", "..n.....", "..n.n..."],
        ["........", "........", "........", "..WWw...", ".WWWwW..", "..ww..W.", "..n....y", "..n.n..."],
    ),
    # coelho pulando (6x4): agachado, impulso, no ar, pousa
    "coelho_4q": molde(
        ["...NN.", "WNNNNx", "NNNNN.", ".n.n.."],
        ["....NN", ".WNNNx", "NNNN..", "n...n."],
        ["..NN..", "WNNNNx", ".NNN..", "n..n.."],
        ["...NN.", "WNNNNx", "NNNNN.", "nn.nn."],
    ),
    # cervo na borda da floresta (10x8): olhando, pastando, andando
    "cervo_4q": molde(
        ["......n.n.", ".......nn.", ".......NNx", "nNNNNNNN..", ".NNNNNNN..", ".NNnnNNn..", ".n.n..n.n.", ".n.n..n.n."],
        ["..........", "..........", "..........", "nNNNNNNNnn", ".NNNNNNNNN", ".NNnnNNn.x", ".n.n..n.n.", ".n.n..n.n."],
        ["......n.n.", ".......nn.", ".......NNx", "nNNNNNNN..", ".NNNNNNN..", ".NNnnNNn..", "..n.n.n..n", ".n...n...n"],
        ["......n.n.", ".......nn.", ".......NNx", "nNNNNNNN..", ".NNNNNNN..", ".NNnnNNn..", ".n..n..n.n", "n...n...n."],
    ),
    # corvo voando e pousado (preto azulado)
    "corvo_voar_4q": molde(
        ["x...x.", ".x.xxk", "..xx..", "......"],
        ["......", "xxxxxk", "..xx..", "......"],
        ["......", "..xxxk", ".xxx..", "x...x."],
        ["......", "xxxxxk", "..xx..", "......"],
    ),
    "corvo_pousado_2q": molde(
        [".....", "..xxe", ".xxx.", "x.d.."],
        [".....", ".....", "xxxxe", "..dd."],
    ),
    # morcego ao anoitecer (6x4)
    "morcego_4q": molde(
        ["x....x", "xx.xxx", ".xxx..", "......"],
        ["......", "xxxxxx", ".xKx..", "......"],
        ["......", ".xxx..", "xxKxxx", "x....x"],
        ["......", "xxxxxx", ".xKx..", "......"],
    ),
    # bando migrando no inverno: 7 pássaros em V (24x8), asas alternadas
    "bando_migrando_4q": None,
    # coruja pousada num galho (7x8), já em tons de noite: olhos amarelos que piscam e viram.
    # Quadros: olhando, piscando, olhando para o lado, olhando.
    "coruja_pousada_4q": molde(
        ["K.....K", "KKKKKKK", "KgyKygK", "KggnggK", ".KkKkK.", ".KKkKK.", "..n.n..", "dnnddnd"],
        ["K.....K", "KKKKKKK", "KggKggK", "KggnggK", ".KkKkK.", ".KKkKK.", "..n.n..", "dnnddnd"],
        [".K.....", "KKKKKKK", "KKgyKyg", "KKggngg", ".KkKkK.", ".KKkKK.", "..n.n..", "dnnddnd"],
        ["K.....K", "KKKKKKK", "KgyKygK", "KggnggK", ".KkKkK.", ".KKkKK.", "..n.n..", "dnnddnd"],
    ),
    # coruja na neve (7x8): neve (cinza da noite, 11) no alto da cabeça e no galho, corpo
    # mais estufado de frio. Mesmos quadros da pousada.
    "coruja_neve_4q": molde(
        ["KgggggK", "KKKKKKK", "KgyKygK", "KggnggK", "KKkKkKK", "gKKkKKg", "g.n.n.g", "dnnddnd"],
        ["KgggggK", "KKKKKKK", "KggKggK", "KggnggK", "KKkKkKK", "gKKkKKg", "g.n.n.g", "dnnddnd"],
        [".ggggg.", "KKKKKKK", "KKgyKyg", "KKggngg", "KKkKkKK", "gKKkKKg", "g.n.n.g", "dnnddnd"],
        ["KgggggK", "KKKKKKK", "KgyKygK", "KggnggK", "KKkKkKK", "gKKkKKg", "g.n.n.g", "dnnddnd"],
    ),
    # coruja na chuva (7x8): encolhida (sem os tufos), pingos batendo na cabeça (c) e
    # escorrendo (b); no quadro 2 ela se sacode e os pingos voam para os lados.
    "coruja_chuva_4q": molde(
        ["...c...", ".......", "KKKKKKK", "KgyKygK", "KggnggK", "KKkKkKK", "b.n.nKb", "dnnddnd"],
        [".......", "..c..c.", "KKKKKKK", "KggKggK", "KggnggK", "KKkKkKK", "b.n.nKb", "dnnddnd"],
        ["c.....c", "cKKKKKc", "KKKKKKK", "KgyKygK", "KggnggK", "KKkKkKK", ".Kn.nK.", "dnnddnd"],
        [".c.....", "....c..", "KKKKKKK", "KgyKygK", "KggnggK", "KKkKkKK", "b.n.nKb", "dnnddnd"],
    ),
    # raposa da madrugada (12x7), já em tons de noite: ferrugem apagada (24 e 23), peito e
    # ponta do rabo claros (12), olho que brilha (22). Trote: as patas alternam.
    "raposa_noite_4q": molde(
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "...Q.Q..Q.Q.", "..Q...Q..Q.."],
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "....QQ..QQ..", "....QQ..QQ.."],
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "...Q.Q.Q..Q.", "....Q.Q...Q."],
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "....QQ..QQ..", "....QQ..QQ.."],
    ),
    # raposa parada (12x7): olhando (olho aceso), cheirando o chão (cabeça baixa), olhando,
    # e de orelha em pé virada para trás
    "raposa_parada_4q": molde(
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "....Q...Q...", "....Q...Q..."],
        ["............", "............", "C..RRRRRQ.Q.", "CQRRRRRRRRR.", ".QQRCCCRRyRR", "....Q...QCRQ", "....Q...Q..."],
        ["........Q.Q.", "........RRR.", "C..RRRRRRyRR", "CQRRRRRRRCRx", ".QQRCCCRRC..", "....Q...Q...", "....Q...Q..."],
        [".......Q.Q..", ".......RRR..", "C..RRRRRyRR.", "CQRRRRRRCRx.", ".QQRCCCRRC..", "....Q...Q...", "....Q...Q..."],
    ),
    # morcego da madrugada (8x5), maior que o do entardecer e com a borda das asas clara
    # (luz da lua) para ler sobre o céu escuro; olhos vermelhos
    "morcego_noite_4q": molde(
        ["g......g", "Kg....gK", ".KKkkKK.", "...kr...", "........"],
        ["........", "ggg..ggg", "KKKkkKKK", "...kr...", "........"],
        ["........", "...kk...", "gKKkrKKg", "KK....KK", "g......g"],
        ["........", "ggg..ggg", "KKKkkKKK", "...kr...", "........"],
    ),
}


def bando():
    """V de 5 pássaros escuros (24x8) voando para a direita; a asa de cada um bate
    defasada da vizinha."""
    posicoes = [(20, 3), (15, 1), (15, 5), (10, 0), (10, 6)]
    asas = [["k.k", ".k."], ["kkk", "..."], [".k.", "k.k"], ["kkk", "..."]]
    quadros = []
    for f in range(4):
        q = [[None] * 24 for _ in range(8)]
        for i, (x, y) in enumerate(posicoes):
            for j, l in enumerate(asas[(f + i) % 4]):
                for k, ch in enumerate(l):
                    if ch != "." and 0 <= y + j < 8:
                        q[y + j][x + k] = K[ch]
        quadros.append(q)
    return quadros


QUANDO = {
    "passaro_voar_4q": ("primavera, verão, outono", "dia", "bando de 3 a 5 que voa e pousa"),
    "passaro_pousado_2q": ("primavera, verão, outono", "dia", "no chão, nas cercas e nos telhados"),
    "peixe_saltar_4q": ("primavera, verão, outono", "dia e entardecer", "salta do lago e volta; não no gelo"),
    "sapo_2q": ("primavera, verão", "entardecer e noite", "na margem e no junco"),
    "garca_2q": ("primavera, verão, outono", "manhã e dia", "parada na água rasa da margem"),
    "coelho_4q": ("todas", "manhã e entardecer", "no mato e na borda das roças; foge de gente"),
    "cervo_4q": ("todas menos inverno fundo", "manhã (até 9h)", "na borda da floresta do morro"),
    "corvo_voar_4q": ("todas", "dia", "sobre campos de batalha e onde há mortos"),
    "corvo_pousado_2q": ("todas", "dia", "pousado perto dos mortos e das ruínas"),
    "morcego_4q": ("primavera, verão, outono", "entardecer e começo da noite", "sai da floresta e das ruínas"),
    "bando_migrando_4q": ("inverno (e fim do outono)", "dia", "atravessa o céu alto de um lado a outro"),
    "coruja_pousada_4q": ("todas", "noite e madrugada", "pousada num galho de árvore ou no telhado; pisca"),
    "morcego_noite_4q": ("primavera, verão, outono", "noite e madrugada", "voa em zigue-zague perto das árvores e da fogueira"),
    "raposa_noite_4q": ("todas", "noite e madrugada", "trota na beira da floresta e da vila, de cabeça baixa"),
    "raposa_parada_4q": ("todas", "noite e madrugada", "para, cheira o chão e olha em volta; foge de gente"),
    "coruja_neve_4q": ("inverno", "noite e madrugada", "no lugar da coruja pousada quando há neve"),
    "coruja_chuva_4q": ("todas menos inverno", "noite e madrugada, com chuva", "no lugar da pousada enquanto chove"),
}


def principal():
    CRIATURAS["bando_migrando_4q"] = bando()
    for nome, qs in CRIATURAS.items():
        gravar(folha_quadros(qs), AQUI / f"{nome}.png")
    # amostra: cada criatura sobre o céu de dia, o entardecer e a noite
    W = 3 * (4 * 26) + 8
    H = len(CRIATURAS) * 12 + 4
    img = Image.new("RGBA", (W, H), PALETA[30] + (255,))
    for i, cor in enumerate((1, 7, 3)):
        img.paste(PALETA[cor] + (255,), (i * (W // 3), 0, (i + 1) * (W // 3), H))
    for j, (nome, qs) in enumerate(CRIATURAS.items()):
        for i in range(3):
            for k, q in enumerate(qs):
                img.alpha_composite(para_imagem(q), (i * (W // 3) + 4 + k * 26, 2 + j * 12))
    img.save(AQUI / "amostra_criaturas.png")
    img.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_criaturas_4x.png")
    print("criaturas:", ", ".join(CRIATURAS))


if __name__ == "__main__":
    principal()

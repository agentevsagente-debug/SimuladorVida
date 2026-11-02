"""Balões de fala e de pensamento (6x5) sobre quem conversa, conta história ou pensa: ajudam
a ler a vida social em 1x. Creme chapado sem contorno, com um sinal escuro ou colorido dentro
e a ponta embaixo (a última linha), que aponta para a cabeça.

Como os sinais de prece, os balões não passam pela tabela da noite.
"""
from pathlib import Path
import sys

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from comum import PALETA, folha_quadros, gravar, para_imagem  # noqa: E402

K = {"W": 31, "x": 30, "g": 11, "r": 20, "y": 22}

# nesta ordem, as variações da folha `balao_5v`
BALOES = {
    # uma linha de texto: conversa. Um traço só, inteiro (dois traços separados liam como os
    # olhos de uma caveira, auditoria 13), e o canto de baixo à esquerda puxado para a ponta.
    "fala": [".WWWW.", "WxxxxW", "WWWWWW", "WWWWW.", "W....."],
    # duas linhas: quem conta história (fala comprida)
    "historia": [".WWWW.", "WxxWxW", "WxWxxW", ".WWWW.", ".W...."],
    # nuvem com reticências e a ponta solta: pensando, cochilando, rezando baixo
    "pensamento": [".WW.W.", "WWWWWW", "WgWgWW", ".WWWW.", "W....."],
    # coração: casal, abraço de reencontro, mãe com o bebê
    "coracao": [".WWWW.", "WrWrWW", "WWrWWW", ".WWWW.", ".W...."],
    # rabisco vermelho: discussão, crianças brigando
    "raiva": [".WWWW.", "WWrWrW", "WrWrWW", ".WWWW.", ".W...."],
}


def principal():
    from PIL import Image
    qs = [[[None if ch == "." else K[ch] for ch in l] for l in m] for m in BALOES.values()]
    gravar(folha_quadros(qs), AQUI / "balao_5v.png")
    # amostra: cada balão sobre uma pessoa, de dia e de noite
    pessoa = Image.open(AQUI.parent / "habitantes" / "adulto_a_parado_2q.png").convert("RGBA").crop((0, 0, 8, 12))
    W, H = len(qs) * 12 + 4, 2 * 22
    img = Image.new("RGBA", (W, H), PALETA[1] + (255,))
    img.paste(PALETA[3] + (255,), (0, 22, W, H))
    for j in range(2):
        for i, q in enumerate(qs):
            x, y = 4 + i * 12, j * 22 + 8
            img.alpha_composite(pessoa, (x, y))
            img.alpha_composite(para_imagem(q), (x + 2, y - 6))
    img.save(AQUI / "amostra_baloes.png")
    img.resize((W * 4, H * 4), Image.NEAREST).save(AQUI / "amostra_baloes_4x.png")
    print("balões:", ", ".join(BALOES))


if __name__ == "__main__":
    principal()

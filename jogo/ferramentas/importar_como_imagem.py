"""Marca as peças usadas só na CPU para serem importadas como Image, e não como textura.

O jogo monta terreno, peças, camadas e folhas de pessoas em imagens próprias.
Importar essas peças como textura criava, para cada uma, uma textura no driver
só para ler a imagem de volta, o que custava memória (cerca de 9,5 MB). As
peças desenhadas direto (efeitos, sinais, interface, criaturas, fogueira e
mapas de luz) continuam como textura.

Uso: python -I jogo/ferramentas/importar_como_imagem.py   (da raiz do repositório)
"""
import re
from pathlib import Path

ARTE = Path(__file__).resolve().parents[1] / "arte"
PASTAS = ["terreno", "estagio1", "estagio2", "estagio3", "estagio4", "estagio5", "estagio6", "memoria",
          "camadas", "habitantes", "acoes", "objetos", "estacoes", "ceu", "culturas", "natureza"]
MANTER = {"fogueira_acesa_4q.png", "fogueira_apagada.png", "luz_fogueira.png", "luz_fogueira_halo.png"}


def principal():
    n = 0
    for pasta in PASTAS:
        for imp in (ARTE / pasta).rglob("*.png.import"):
            if imp.name[:-len(".import")] in MANTER:
                continue
            s = imp.read_text(encoding="utf-8")
            if 'importer="image"' in s:
                continue
            uid = re.search(r'uid="([^"]+)"', s).group(1)
            fonte = re.search(r'source_file="([^"]+)"', s).group(1)
            imp.write_text(f'[remap]\n\nimporter="image"\ntype="Image"\nuid="{uid}"\n\n[deps]\n\n'
                           f'source_file="{fonte}"\n\n[params]\n', encoding="utf-8")
            n += 1
    print("importações trocadas para Image:", n)


if __name__ == "__main__":
    principal()

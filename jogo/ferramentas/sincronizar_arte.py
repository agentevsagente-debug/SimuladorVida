"""Copia a arte oficial de arte_claude/pecas/ para jogo/arte/, sem editar os originais.

Copia as pastas que o jogo usa (sem amostras, ampliações e cenas de exemplo) e
diz quantos arquivos são novos ou mudaram. Depois de rodar:

    Godot --headless --path jogo --import          (cria os .import dos novos)
    python -I jogo/ferramentas/importar_como_imagem.py
    Godot --headless --path jogo --import          (reimporta como Image)

Uso: python -I jogo/ferramentas/sincronizar_arte.py   (da raiz do repositório)
"""
import filecmp
import shutil
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
PECAS = RAIZ / "arte_claude" / "pecas"
DESTINO = RAIZ / "jogo" / "arte"
## pasta da arte -> pasta no jogo
PASTAS = {
    "terreno": "terreno", "estagio1": "estagio1", "estagio2": "estagio2", "estagio3": "estagio3",
    "estagio4": "estagio4", "estagio5": "estagio5", "estagio6": "estagio6", "habitantes": "habitantes",
    "acoes": "acoes", "objetos": "objetos", "efeitos": "efeitos", "sinais": "sinais",
    "interface": "interface", "memoria": "memoria", "criaturas": "criaturas", "estacoes": "estacoes",
    "montagem": "camadas", "culturas": "culturas", "natureza": "natureza", "estante": "estante", "nuvens": "nuvens",
    "luzes": "luzes",
}
FORA = ("amostra", "comparacao", "montagem_", "cena_", "terreno_teste", "blocos_prancha", "variacoes_")


def principal():
    novos = mudados = 0
    for origem, destino in PASTAS.items():
        for f in (PECAS / origem).rglob("*"):
            if f.suffix.lower() not in (".png", ".json", ".fnt", ".ico") or "_4x" in f.parts:
                continue
            if f.name.startswith(FORA):
                continue
            alvo = DESTINO / destino / f.relative_to(PECAS / origem)
            if alvo.exists() and filecmp.cmp(f, alvo, shallow=False):
                continue
            alvo.parent.mkdir(parents=True, exist_ok=True)
            novos += 0 if alvo.exists() else 1
            mudados += 1 if alvo.exists() else 0
            shutil.copy2(f, alvo)
    print(f"arte sincronizada: {novos} novos, {mudados} mudaram")


if __name__ == "__main__":
    principal()

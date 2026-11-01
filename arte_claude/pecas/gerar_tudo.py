"""Recria todas as peças, as camadas e a prova de montagem, na ordem certa."""
from pathlib import Path
import runpy

AQUI = Path(__file__).resolve().parent
for script in ("terreno/terreno.py", "habitantes/habitantes.py", "estagio1/estagio1.py",
               "efeitos/efeitos.py", "efeitos/efeitos_fase2.py", "sinais/sinais.py", "interface/interface.py", "interface/icone_jogo.py", "estagio2/estagio2.py",
               "memoria/memoria.py", "culturas/culturas.py",
               "montagem/camadas.py", "montagem/montar.py"):
    runpy.run_path(str(AQUI / script), run_name="__main__")

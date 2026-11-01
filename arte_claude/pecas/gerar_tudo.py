"""Recria todas as peças, as camadas e a prova de montagem, na ordem certa."""
from pathlib import Path
import runpy

AQUI = Path(__file__).resolve().parent
for script in ("terreno/terreno.py", "habitantes/habitantes.py", "estagio1/estagio1.py", "efeitos/efeitos.py",
               "montagem/camadas.py", "montagem/montar.py"):
    runpy.run_path(str(AQUI / script), run_name="__main__")

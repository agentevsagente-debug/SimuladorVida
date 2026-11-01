"""Recria adulto_a_andar_4q.png; requer Pillow e ../gerador.py."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from gerador import generate

if __name__ == "__main__":
    generate('adulto_a_andar_4q')

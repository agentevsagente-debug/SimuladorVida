"""Recria o PNG homônimo. Requer Pillow e ../visual_c.py."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from visual_c import generate

if __name__ == "__main__":
    generate('habitantes_c','adulto_a_andar_4q')

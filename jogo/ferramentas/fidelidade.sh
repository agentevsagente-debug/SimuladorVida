#!/bin/sh
# Teste de fidelidade: monta layout.json no jogo e compara pixel a pixel com
# a prova de montagem da arte (ferramentas/referencia/montagem_<hora>.png).
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
JOGO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TEMP:-/tmp}"
for h in dia noite; do
	rm -f "$TMP/fidelidade_$h.png"
	timeout 60 "$G" --path "$JOGO" -- --sem-config --cena=layout --hora=$h --pos=100,100 \
		--capturar="$TMP/fidelidade_$h.png" > /dev/null 2>&1
	python -W ignore - "$TMP/fidelidade_$h.png" "$JOGO/ferramentas/referencia/montagem_$h.png" "$h" <<'PY'
import sys, os
from PIL import Image
cap, ref, hora = sys.argv[1:4]
if not os.path.exists(cap):
    print(f"{hora}: FALHA, a captura não foi gerada"); sys.exit(1)
a, b = Image.open(cap).convert("RGB"), Image.open(ref).convert("RGB")
d = sum(1 for x, y in zip(a.getdata(), b.getdata()) if x != y)
print(f"{hora}: {100 * d / (a.width * a.height):.2f}% dos pixels diferem ({d})")
PY
done

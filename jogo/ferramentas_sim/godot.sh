#!/usr/bin/env bash
# Roda um script do protótipo sem gráfico e filtra o ruído de saída do Godot.
# Uso: ferramentas/godot.sh res://ferramentas_sim/sondar.gd -- 1 2 3
G="/c/Users/sergi/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
script="$1"; shift
"$G" --headless --path "$DIR" --script "$script" "$@" 2>&1 | grep -v "^\s*$\|RID alloc\|BUG: Unref\|PagedAlloc\|Thread object\|wait_to_finish\|~Thread\|unref (core\|paged_allocator\|^Godot Engine\|string_name.cpp\|thread.cpp"

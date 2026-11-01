# Auditoria 5: o mesmo roteiro da auditoria 3 (semente 7, verão), mais duas sessões longas em
# 1x (tarde e madrugada, 2 min de jogo de verdade cada) e o inverno de madrugada.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud5"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 400 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
for h in 6 8 10 12 14 16 18 20 22 1 3; do
  cap h1x_$h --mundo-novo --semente=7 --dias=12 --hora=$h --ritmo=normal --capturar-apos=1 --quadros=8 --intervalo=1.5
done
cap longa_tarde --mundo-novo --semente=7 --dias=12 --hora=14 --ritmo=normal --capturar-apos=1 --quadros=60 --intervalo=2
cap longa_madrugada --mundo-novo --semente=7 --dias=12 --hora=2 --ritmo=normal --capturar-apos=1 --quadros=60 --intervalo=2
cap d50x --mundo-novo --semente=7 --dias=12 --hora=5 --ritmo=rapido2 --capturar-apos=1 --quadros=48 --intervalo=1.125
for h in 10 16; do
  cap m40_$h --mundo-novo --semente=7 --anos=40 --hora=$h --ritmo=normal --capturar-apos=1 --quadros=6 --intervalo=1.5
done
cap m40_long_tarde --mundo-novo --semente=7 --anos=40 --hora=14 --ritmo=normal --capturar-apos=1 --quadros=40 --intervalo=2
cap m40_madrugada --mundo-novo --semente=7 --anos=40 --hora=2 --ritmo=normal --capturar-apos=1 --quadros=40 --intervalo=2
echo FIM
# a caçada em 1x (a da semente 7 começa por volta das 15h)
cap cacada_15h --mundo-novo --semente=7 --dias=12 --hora=15 --ritmo=normal --capturar-apos=1 --quadros=60 --intervalo=1.5
cap cacada_13h --mundo-novo --semente=7 --dias=12 --hora=13 --ritmo=normal --capturar-apos=1 --quadros=60 --intervalo=2

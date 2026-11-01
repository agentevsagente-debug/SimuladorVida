G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$TEMP/aud3"
cap() { nome=$1; shift; timeout 200 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
for h in 6 8 10 12 14 16 18 20 22 1; do
  cap h1x_$h --mundo-novo --semente=7 --dias=12 --hora=$h --ritmo=normal --capturar-apos=1 --quadros=8 --intervalo=1.5
done
cap d50x --mundo-novo --semente=7 --dias=12 --hora=5 --ritmo=rapido2 --capturar-apos=1 --quadros=48 --intervalo=1.125
for h in 10 16; do
  cap m40_$h --mundo-novo --semente=7 --anos=40 --hora=$h --ritmo=normal --capturar-apos=1 --quadros=6 --intervalo=1.5
done
echo FIM

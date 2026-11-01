# Auditoria 6: o roteiro das auditorias 3 a 5 (semente 7, verão), as duas caçadas inteiras em 1x (12 dias erra, 13 acerta) e a dica da pessoa.
# Medidas: medir6.py; recortes: recortar6.py.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud6"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
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
# a caçada inteira em 1x, da saída (~12h40) à repartição no fogo (~17h30): 11 min, um quadro a cada 3 s
cap cacada_longa --mundo-novo --semente=7 --dias=12 --hora=12 --ritmo=normal --capturar-apos=1 --quadros=230 --intervalo=3
# a dica da pessoa: 4 pessoas em 4 horas, e uma pessoa acompanhada por 1 min em 1x
for h in 9 15 19 23; do
  for id in 2 5 9 12; do
    cap dica_${h}h_$id --mundo-novo --semente=7 --dias=12 --hora=$h --ritmo=normal --dica-pessoa=$id:1 --capturar-apos=3 --quadros=1
  done
done
cap dica_seguida --mundo-novo --semente=7 --dias=12 --hora=14 --ritmo=normal --dica-pessoa=5:1 --capturar-apos=2 --quadros=20 --intervalo=3
echo FIM2
# a caçada que acerta (semente 7, 13 dias, segundo o RELATORIO da B), da saída à repartição
cap cacada13_longa --mundo-novo --semente=7 --dias=13 --hora=12 --ritmo=normal --capturar-apos=1 --quadros=230 --intervalo=3

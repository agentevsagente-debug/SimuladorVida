# Auditoria 7: os estágios 3 a 6 dentro do jogo. Sementes 3 e 7, nos anos em que cada estágio
# já se firmou (sondagem: semente 3 chega ao 3 no ano 42, ao 4 no 125, ao 5 no 158 e ao 6 no 164;
# semente 7, no 75, 101, 119 e 127). Dia, entardecer e noite; inverno; e o antes e depois (depois_*) com a arte nova ligada só para o teste.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud7"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
for sa in 3:60 3:140 3:161 3:250 3:500 7:90 7:110 7:122 7:200 7:400; do
  s=${sa%%:*}; a=${sa##*:}
  for h in 10 19 22; do
    cap s${s}_a${a}_${h}h --mundo-novo --semente=$s --anos=$a --dias=12 --hora=$h --ritmo=normal --capturar-apos=2 --quadros=3 --intervalo=2
  done
  cap s${s}_a${a}_inverno --mundo-novo --semente=$s --anos=$a --dias=33 --hora=11 --ritmo=normal --capturar-apos=2 --quadros=2 --intervalo=2
done
echo FIM

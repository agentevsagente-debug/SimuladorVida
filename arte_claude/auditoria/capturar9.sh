# Auditoria 9: os estágios 3 a 6 com tudo ligado (refaz as notas da 7). Sementes 3 e 7, nos anos em que cada estágio
# já se firmou (sondagem com o equilíbrio novo da A: semente 3 chega ao 3 no ano 42, ao 4 no 68, ao 5 no 112 e ao 6 no 128;
# semente 7, no 75, 109, 165 e 166; semente 1, ao 5 no 102 e ao 6 no 130). Dia, entardecer e noite; inverno; e 1 min de tarde em 1x.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud9"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
for sa in 3:55 3:90 3:120 3:200 3:400 7:90 7:130 7:250 1:115 1:300; do
  s=${sa%%:*}; a=${sa##*:}
  for h in 10 19 22; do
    cap s${s}_a${a}_${h}h --mundo-novo --semente=$s --anos=$a --dias=12 --hora=$h --ritmo=normal --capturar-apos=2 --quadros=3 --intervalo=2
  done
  cap s${s}_a${a}_inverno --mundo-novo --semente=$s --anos=$a --dias=33 --hora=11 --ritmo=normal --capturar-apos=2 --quadros=2 --intervalo=2
done

# a vida da vila em 1x: 1 min de tarde (15h) em cada estágio, um quadro a cada 2 s
for sa in 3:55 3:90 3:120 3:200 1:115 7:250; do
  s=${sa%%:*}; a=${sa##*:}
  cap s${s}_a${a}_tarde1x --mundo-novo --semente=$s --anos=$a --dias=12 --hora=15 --ritmo=normal --capturar-apos=2 --quadros=30 --intervalo=2
done
echo FIM

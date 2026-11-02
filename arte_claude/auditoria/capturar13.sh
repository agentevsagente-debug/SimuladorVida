# Auditoria 13: a tarde (12h às 15h30) em 1x, pelo código-fonte da main (b639bfa), com --sem-config e
# --mundo-novo (a pasta de dados do usuário não é tocada) e a janela no segundo monitor, sem foco.
# Em 1x, uma hora de jogo dura 112,5 s: as 3,5 h da tarde são uns 400 s. Um quadro a cada 4 s.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud13"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --sem-foco --pos=2700,200 "$@" --capturar-tudo --capturar="$(cygpath -m "$O")/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
T="--hora=12 --ritmo=normal --capturar-apos=2 --quadros=105 --intervalo=4"
case "$1" in
  a) cap s7_d12 --semente=7 --dias=12 $T & cap s11_d12 --semente=11 --dias=12 $T & wait ;;
  b) cap s3_d20 --semente=3 --dias=20 $T & cap s3_a60 --semente=3 --anos=60 --dias=12 $T & wait ;;
esac
echo FIM
# Os arremessos da cena ensinar (s3, 60 anos): em 1x, 1 minuto de jogo dura 1,875 s e a lança voa
# 0,3 minuto (0,56 s). Rajadas de 0,1 s em cada arremesso: o do velho (13h04,6), o primeiro da
# criança, que erra (13h19,8), e o último, que acerta (13h32,4).
if [ "$1" = c ]; then
  E="--semente=3 --anos=60 --dias=12 --hora=12 --ritmo=normal --quadros=70 --intervalo=0.1"
  cap arremesso_velho $E --capturar-apos=122 &
  cap arremesso_erro $E --capturar-apos=147 &
  cap arremesso_acerto $E --capturar-apos=170 &
  wait
fi

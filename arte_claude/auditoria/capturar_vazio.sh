# Revisão do fim do mundo e do mundo vazio (sessão C, antes da auditoria 9): a semente 3 no ano
# 140 (estágio 4) com todos mortos, logo depois e 5, 20 e 60 anos depois; e o povo novo chegando.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud10"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar-tudo --capturar="$(cygpath -m "$O")/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
for n in 0 5 20 60; do
  for h in 10 19 23; do
    cap vazio_${n}_${h}h --mundo-novo --semente=3 --anos=140 --dias=12 --hora=$h --extinguir=$n --ritmo=normal --capturar-apos=3 --quadros=2 --intervalo=2
  done
done
cap vazio_inverno --mundo-novo --semente=3 --anos=140 --dias=33 --hora=11 --extinguir=20 --ritmo=normal --capturar-apos=3 --quadros=2 --intervalo=2
# o povo novo chegando (com a entrada injetada: o botão de criar povo e um clique no mundo).
# Precisa do roteiro8_injetar_entrada.gd ligado na moldura (veja o cabeçalho dele) e de criar.json:
# [[3,"apertar",18,9],[3.1,"soltar",18,9],[5,"mover",240,128],[6,"apertar",240,128],[6.1,"soltar",240,128]]
cap criar --mundo-novo --semente=3 --anos=140 --dias=12 --hora=9 --extinguir=20 --ritmo=normal --roteiro="$(cygpath -m "$O")/criar.json" --capturar-apos=2 --quadros=50 --intervalo=1.5
echo FIM

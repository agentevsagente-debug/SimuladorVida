# Auditoria 3c: a interface. Cada captura é a janela inteira em 1x (480 x 178, com a alça);
# o 2x é a mesma imagem ampliada sem suavização, que é o que a janela mostra na escala 2.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$TEMP/aud3c"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 150 "$G" --path "$J" -- --sem-config --pos=100,100 --capturar-tudo "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
B="--mundo-novo --semente=7 --dias=12 --hora=10 --congelar"
cap base $B --capturar-apos=2
cap primeira_vez $B --primeira-vez --capturar-apos=2
cap poderes $B --abrir=poderes --capturar-apos=2
cap ritmo $B --abrir=ritmo --capturar-apos=2
cap salto $B --abrir=salto --capturar-apos=2
cap linhagem $B --abrir=linhagem --capturar-apos=2
for p in 150,148 200,150 258,150 280,140 320,140 420,120; do
  cap dica_${p/,/_} $B --dica=$p --capturar-apos=2
done
cap carga_raio $B --demo=raio:260:0.6:1.5 --capturar-apos=1.6 --quadros=3 --intervalo=0.3
cap cronica --mundo-novo --semente=7 --anos=20 --hora=10 --congelar --abrir=cronica --capturar-apos=2
cap estante --mundo-novo --semente=7 --anos=20 --hora=10 --congelar --abrir=estante --capturar-apos=2
cap livro --mundo-novo --semente=7 --anos=20 --hora=10 --congelar --abrir=livro --capturar-apos=2
cap abandonar --mundo-novo --semente=7 --anos=20 --hora=10 --congelar --abrir=abandonar --capturar-apos=2
cap abandonado --mundo-novo --semente=7 --anos=20 --hora=10 --congelar --abrir=abandonado --capturar-apos=3
cap vazio --mundo-novo --semente=7 --dias=12 --hora=10 --congelar --extinguir --capturar-apos=3
cap vazio_dica --mundo-novo --semente=7 --dias=12 --hora=10 --congelar --extinguir --dica=240,140 --capturar-apos=3
cap criar_povo --mundo-novo --semente=7 --dias=12 --hora=10 --extinguir --demo=criar_povo:240:0:2 --capturar-apos=2.5 --quadros=3 --intervalo=1
cap noite $B --hora=22 --capturar-apos=2
cap ausencia --mundo-novo --semente=7 --dias=12 --hora=10 --simular-ausencia --capturar-apos=3
cap avancado_poderes --mundo-novo --semente=7 --anos=60 --hora=10 --congelar --abrir=poderes --capturar-apos=2
echo FIM

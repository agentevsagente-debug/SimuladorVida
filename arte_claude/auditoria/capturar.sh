G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$TEMP/aud"
cap() { nome=$1; shift; timeout 120 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls -s "$O"/$nome*.png 2>/dev/null | head -1)"; }
# estações (meio-dia)
cap est_primavera --mundo-novo --semente=7 --dias=2 --hora=12 --congelar
cap est_verao --mundo-novo --semente=7 --dias=12 --hora=12 --congelar
cap est_outono --mundo-novo --semente=7 --dias=22 --hora=12 --congelar
cap est_inverno --mundo-novo --semente=7 --dias=32 --hora=12 --congelar
# horários (verão)
cap hora_manha --mundo-novo --semente=7 --dias=12 --hora=7 --congelar
cap hora_tarde --mundo-novo --semente=7 --dias=12 --hora=18 --congelar
cap hora_noite --mundo-novo --semente=7 --dias=12 --hora=22 --congelar
cap hora_noite_inverno --mundo-novo --semente=7 --dias=32 --hora=22 --congelar
# mundos
cap mundo_avancado --mundo-novo --semente=7 --anos=60 --hora=12 --congelar
cap mundo_avancado2 --mundo-novo --semente=3 --anos=150 --hora=12 --congelar
cap mundo_avancado_tudo --mundo-novo --semente=7 --anos=60 --hora=12 --congelar --capturar-tudo
# poderes (sequência de quadros depois do gesto)
for p in chuva raio fogo fartura erguer_terra sonho; do
  cap poder_$p --mundo-novo --semente=7 --dias=12 --hora=12 --demo=$p:220:1.0:1.5 --capturar-apos=2.0 --quadros=4 --intervalo=0.4
done
cap efeito_chuva --mundo-novo --semente=7 --dias=12 --hora=12 --efeito=chuva --capturar-apos=1.5
cap efeito_raio --mundo-novo --semente=7 --dias=12 --hora=14 --efeito=raio --capturar-apos=1.5 --quadros=4 --intervalo=0.3
echo FIM

G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$TEMP/aud2"
cap() { nome=$1; shift; timeout 150 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar="$O/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
cap est_primavera --mundo-novo --semente=7 --dias=2 --hora=12 --congelar
cap est_verao --mundo-novo --semente=7 --dias=12 --hora=12 --congelar
cap est_outono --mundo-novo --semente=7 --dias=22 --hora=12 --congelar
cap est_inverno --mundo-novo --semente=7 --dias=32 --hora=12 --congelar
cap hora_amanhecer --mundo-novo --semente=7 --dias=12 --hora=6 --congelar
cap hora_manha --mundo-novo --semente=7 --dias=12 --hora=8 --congelar
cap hora_tarde --mundo-novo --semente=7 --dias=12 --hora=18 --congelar
cap hora_noite --mundo-novo --semente=7 --dias=12 --hora=22 --congelar
cap ceu_noite_seq --mundo-novo --semente=7 --dias=12 --hora=23 --capturar-apos=1 --quadros=4 --intervalo=1.5
cap mundo_s7_60 --mundo-novo --semente=7 --anos=60 --hora=12 --congelar
cap mundo_s7_150 --mundo-novo --semente=7 --anos=150 --hora=12 --congelar
cap mundo_s3_150 --mundo-novo --semente=3 --anos=150 --hora=12 --congelar
cap mundo_s11_300 --mundo-novo --semente=11 --anos=300 --hora=12 --congelar
cap mundo_s3_150_inverno --mundo-novo --semente=3 --anos=150 --dias=32 --hora=12 --congelar
cap mundo_s3_150_noite --mundo-novo --semente=3 --anos=150 --hora=22 --congelar
cap mundo_s7_60_tudo --mundo-novo --semente=7 --anos=60 --hora=12 --congelar --capturar-tudo
cap vida_manha_seq --mundo-novo --semente=7 --dias=12 --hora=7 --capturar-apos=1 --quadros=6 --intervalo=1.0
cap vida_tarde_seq --mundo-novo --semente=7 --dias=12 --hora=18 --capturar-apos=1 --quadros=6 --intervalo=1.0
for p in chuva raio fogo fartura erguer_terra sonho seca diluvio terremoto pressagio cura; do
  cap poder_$p --mundo-novo --semente=7 --dias=12 --hora=12 --demo=$p:250:1.0:1.5 --capturar-apos=1.6 --quadros=5 --intervalo=0.25
done
echo FIM

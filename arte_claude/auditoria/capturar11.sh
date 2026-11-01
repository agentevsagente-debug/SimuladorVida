# Auditoria 11: o jogo como produto. Capturas de cada parte, pelo código-fonte e com --sem-config
# (a pasta de dados do usuário não é tocada; a primeira abertura do .exe está em capturas10).
# O recomeço usa a entrada injetada (roteiro8_injetar_entrada.gd ligado na moldura; veja o cabeçalho dele).
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud12"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=100,100 "$@" --capturar-tudo --capturar="$(cygpath -m "$O")/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
B="--mundo-novo --semente=7 --dias=12"
# os 11 poderes, de dia, sobre o acampamento (o fogo em brando e em milagre)
for pi in chuva:1 raio:1 fogo:0.2 fogo:0.9 fartura:0.8 erguer_terra:0.8 sonho:0.8 seca:0.8 diluvio:0.8 terremoto:0.8 pressagio:0.8 cura:0.8; do
  p=${pi%%:*}; i=${pi##*:}
  cap poder_${p}_${i} $B --hora=10 --ritmo=normal --demo=$p:255:$i:2 --capturar-apos=2.3 --quadros=6 --intervalo=0.7
done
# de noite, a fartura e o sonho (versões noturnas), e o modo discreto no raio e no fogo
for p in fartura sonho; do cap noite_$p $B --hora=22 --ritmo=normal --demo=$p:255:0.8:2 --capturar-apos=2.3 --quadros=4 --intervalo=0.7; done
for p in raio fogo; do cap discreto_$p $B --hora=10 --ritmo=normal --discreto --demo=$p:255:0.9:2 --capturar-apos=2.3 --quadros=5 --intervalo=0.7; done
# a crônica viva, a estante e os livros
cap cronica_viva --mundo-novo --semente=3 --anos=130 --hora=10 --ritmo=pausa --abrir=cronica --capturar-apos=3 --quadros=1
cap estante --mundo-novo --semente=3 --anos=130 --hora=10 --ritmo=pausa --abrir=estante --capturar-apos=3 --quadros=1
for l in extincao era-nova abandono; do cap livro_$l $B --hora=10 --ritmo=pausa --livro-arquivo=res://ferramentas_sim/livros/$l.md --capturar-apos=3 --quadros=1; done
cap livro_era-nova_p5 $B --hora=10 --ritmo=pausa --livro-arquivo=res://ferramentas_sim/livros/era-nova.md:5 --capturar-apos=3 --quadros=1
# os eventos raros
for r in estranhos doentes sonho dependencia coleta; do cap raro_$r $B --hora=10 --ritmo=normal --cenario-raro=$r --capturar-apos=3 --quadros=8 --intervalo=2; done
cap raro_guerra --mundo-novo --semente=3 --anos=60 --hora=10 --ritmo=pausa --cenario-raro=guerra --capturar-apos=3 --quadros=1
# o fim do mundo e o recomeço
cap fim --mundo-novo --semente=3 --anos=140 --dias=12 --hora=17 --extinguir=0 --ritmo=normal --capturar-apos=1 --quadros=6 --intervalo=1.5
cap recomeco --mundo-novo --semente=3 --anos=140 --dias=12 --hora=9 --extinguir=20 --ritmo=normal --roteiro="$(cygpath -m "$O")/criar.json" --capturar-apos=2 --quadros=40 --intervalo=1.5
echo FIM

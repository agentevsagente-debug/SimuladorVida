# Capturas do jogo de verdade para a divulgação da versão 0.1 (sessão C). A janela vai para o
# segundo monitor (--pos=2700,200), longe do cursor, que senão abre dicas sozinho. Pelo código-fonte, com
# --sem-config e --mundo-novo (não tocam a pasta de dados do usuário). O recomeço usa a entrada
# injetada (auditoria/roteiro8_injetar_entrada.gd ligado na moldura; veja o cabeçalho dele).
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/divulg"
mkdir -p "$O"
cap() { nome=$1; shift; timeout 900 "$G" --path "$J" -- --sem-config --pos=2700,200 --mundo-novo "$@" --capturar="$(cygpath -m "$O")/$nome.png" > "$O/$nome.log" 2>&1; echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"; }
"$G" --headless --path "$J" --import > /dev/null 2>&1
cap entardecer_e3 --semente=3 --anos=90 --dias=12 --hora=18 --ritmo=normal --capturar-apos=3 --quadros=8 --intervalo=3
cap entardecer_s7 --semente=7 --dias=12 --hora=18 --ritmo=normal --capturar-apos=3 --quadros=8 --intervalo=3
cap cacada --semente=3 --dias=13 --hora=16 --ritmo=normal --capturar-apos=66 --quadros=70 --intervalo=0.5
cap vila_e6_dia --semente=3 --anos=200 --dias=12 --hora=10 --ritmo=normal --capturar-apos=3 --quadros=3 --intervalo=2
cap vila_e6_tarde --semente=3 --anos=200 --dias=12 --hora=18 --ritmo=normal --capturar-apos=3 --quadros=3 --intervalo=2
cap vila_e6_noite --semente=3 --anos=200 --dias=12 --hora=21 --ritmo=normal --capturar-apos=3 --quadros=3 --intervalo=2
for p in 1 3 40; do cap livro_extincao_$p --semente=7 --dias=12 --hora=10 --ritmo=pausa --livro-arquivo=res://ferramentas_sim/livros/extincao.md:$p --capturar-tudo --capturar-apos=3 --quadros=1; done
for id in 2 3 4 5 6 8 9 10; do cap dica_$id --semente=7 --dias=12 --hora=16 --ritmo=normal --dica-pessoa=$id:1 --capturar-apos=3 --quadros=1; done
cap recomeco --semente=3 --anos=140 --dias=12 --hora=9 --extinguir=20 --ritmo=normal --roteiro="$(cygpath -m "$O")/criar.json" --capturar-apos=2 --quadros=30 --intervalo=1.5
# um dia inteiro em 50x na vila do estágio 6, para o GIF (54 s, um quadro a cada 0,5 s)
cap dia50x --semente=3 --anos=200 --dias=12 --hora=5 --ritmo=rapido2 --capturar-apos=1 --quadros=110 --intervalo=0.5
echo FIM

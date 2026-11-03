# Auditoria 14 (refeita no jogo): a caixa de preces e o termômetro de fé, pelo código da main (d97faef).
# Sem mouse: --abrir=preces abre a caixa e --dica=X,Y põe o cursor (de mentira) sobre a vila.
# --preces-falsas enche a caixa. APPDATA vai para uma pasta temporária: a pasta de dados do jogador
# não é lida nem escrita. A janela fica no segundo monitor, sem foco.
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
J="C:/sergio/2026/Consultoria/AgenteVsAgente/Projetos/SimuladorVida/.claude/worktrees/arte-claude-alvo-215685/jogo"
O="$(cygpath -u "$TEMP")/aud14"
mkdir -p "$O"
cap() {
  nome=$1; shift
  d="${DADOS:-$nome}"
  mkdir -p "$O/dados_$d"
  APPDATA="$(cygpath -w "$O/dados_$d")" timeout 300 "$G" --path "$J" -- --sem-foco --sem-atalho --sem-som --pos=2700,200 \
    --mundo-novo --semente=7 --anos=3 --congelar "$@" --capturar-tudo --capturar="$(cygpath -m "$O")/$nome.png" > "$O/$nome.log" 2>&1
  echo "$nome $(ls "$O"/$nome*.png 2>/dev/null | wc -l)"
}
"$G" --headless --path "$J" --import > /dev/null 2>&1
V="${VILA:-230,58}"
if [ "$1" = vila ]; then
  for x in 205 215 245 260 275; do cap vila_$x --hora=${HORA:-dia} --preces-falsas --dica=$x,58 --capturar-apos=3 & done; wait
  exit
fi
if [ "$1" != seta ]; then for h in dia noite; do
  cap ${h}_fechada_nova --hora=$h --preces-falsas --capturar-apos=3 &
  cap ${h}_aberta --hora=$h --preces-falsas --abrir=preces --capturar-apos=3 &
  [ $h = noite ] && V=215,58
  cap ${h}_dica --hora=$h --preces-falsas --dica=$V --capturar-apos=3 &
  # o botão sem ponto: a primeira abertura lê a caixa (fica no moldura.cfg da pasta temporária),
  # a segunda, no mesmo mundo congelado, não tem prece nova
  (DADOS=${h}_lida cap ${h}_lendo --hora=$h --abrir=preces --capturar-apos=3 && DADOS=${h}_lida cap ${h}_fechada_sem --hora=$h --capturar-apos=3) &
  wait
done; fi
echo FIM
# depois da seta nova (o vermelho com a ponta laranja), copiada para jogo/arte só para a captura
if [ "$1" = seta ]; then
  for h in dia noite; do
    cap ${h}_aberta_seta --hora=$h --preces-falsas --abrir=preces --capturar-apos=3 &
  done
  cap dia_dica_seta --hora=dia --preces-falsas --dica=230,58 --capturar-apos=3 &
  cap noite_dica_seta --hora=noite --preces-falsas --dica=215,58 --capturar-apos=3 &
  wait
fi

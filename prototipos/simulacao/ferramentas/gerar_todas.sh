#!/usr/bin/env bash
# Gera as quatro crônicas da fase 0 e confere o determinismo:
# cada uma é gerada duas vezes, em processos separados, e as duas saídas são comparadas.
set -e
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
gerar() { # semente cenario saida
	ferramentas/godot.sh res://ferramentas/gerar.gd -- "$1" "$2" "$3" > /dev/null
}
for item in "1 - semente-1" "2 - semente-2" "3 - semente-3" "1 cenarios/semente1-intervencoes.txt semente-1-intervencoes"; do
	set -- $item
	gerar "$1" "$2" "cronicas/$3.md"
	gerar "$1" "$2" "$TMP/$3.md"
	if cmp -s "cronicas/$3.md" "$TMP/$3.md"; then
		echo "$3: igual nas duas rodadas ($(wc -c < "cronicas/$3.md") bytes)"
	else
		echo "$3: DIFERENTE entre rodadas"; exit 1
	fi
	sed -n '2p' "cronicas/$3.resumo.txt"
done
rm -rf "$TMP"

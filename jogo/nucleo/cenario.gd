extends RefCounted
## Lê um arquivo de cenário: o que o deus faz e quando.
##
## Uma ação por linha. Linhas vazias e linhas que começam com # são ignoradas.
##   ano 5, dia 12: chuva sobre a floresta
##   ano 9, dia 3, hora 14: raio sobre o líder do morro
##   ano 20, dia 1: sonho no lago
## Poderes: chuva, raio, fartura, fogo, erguer (erguer terra), sonho.
## Zonas: praia, lago, floresta, morro. "líder" mira o líder do grupo da zona.
## O dia vai de 1 a 40 e a hora de 0 a 23 (padrão: 12). "fraca" ou "forte" mudam a intensidade
## (0,3 ou 0,95; padrão 0,8). Repetir o mesmo poder na mesma zona em 3 dias vira imposição.

const PODERES := ["chuva", "raio", "fartura", "fogo", "erguer", "sonho"]
const ZONAS := ["praia", "lago", "floresta", "morro"]


static func ler_arquivo(caminho: String) -> Array:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		push_error("Cenário não encontrado: " + caminho)
		return []
	return ler_texto(f.get_as_text())


static func ler_texto(texto: String) -> Array:
	var comandos: Array = []
	var re := RegEx.new()
	re.compile("ano\\s+(\\d+)\\s*,\\s*dia\\s+(\\d+)(?:\\s*,\\s*hora\\s+(\\d+))?\\s*:\\s*(.+)")
	var n_linha := 0
	for linha in texto.split("\n"):
		n_linha += 1
		var l := _normalizar(linha.strip_edges())
		if l.is_empty() or l.begins_with("#"):
			continue
		var m := re.search(l)
		if m == null:
			push_warning("Linha %d do cenário ignorada: %s" % [n_linha, linha])
			continue
		var acao := m.get_string(4)
		var poder := ""
		for p in PODERES:
			if acao.find(p) >= 0:
				poder = p
				break
		var zona := ""
		for z in ZONAS:
			if acao.find(z) >= 0:
				zona = z
				break
		if poder.is_empty() or zona.is_empty():
			push_warning("Linha %d do cenário sem poder ou zona: %s" % [n_linha, linha])
			continue
		var hora := 12
		if not m.get_string(3).is_empty():
			hora = clampi(int(m.get_string(3)), 0, 23)
		comandos.append({
			"ano": int(m.get_string(1)),
			"dia": clampi(int(m.get_string(2)), 1, 40) - 1,
			"hora": hora,
			"poder": poder,
			"zona": zona,
			"alvo": "lider" if acao.find("lider") >= 0 else "",
			"intensidade": 0.3 if acao.find("frac") >= 0 else (0.95 if acao.find("forte") >= 0 else 0.8),
			"texto": linha.strip_edges(),
			"ordem": comandos.size(),
		})
	comandos.sort_custom(func(a, b): return _chave(a) < _chave(b))
	return comandos


static func _chave(c: Dictionary) -> int:
	return ((c["ano"] * 40 + c["dia"]) * 24 + c["hora"]) * 1000 + c["ordem"]


static func _normalizar(s: String) -> String:
	s = s.to_lower()
	var de := "áàâãéêíóôõúç"
	var para := "aaaaeeiooouc"
	for i in de.length():
		s = s.replace(de[i], para[i])
	return s

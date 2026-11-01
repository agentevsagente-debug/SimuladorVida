extends RefCounted
## Lê um arquivo de cenário: o que o deus faz e quando.
##
## Uma ação por linha. Linhas vazias e linhas que começam com # são ignoradas.
##   ano 5, dia 12: chuva sobre a floresta
##   ano 9, dia 3, hora 14: raio sobre o líder do morro
##   ano 20, dia 1: sonho no lago
## Poderes: chuva, raio, fartura, fogo, erguer (erguer terra), sonho, seca, dilúvio, terremoto,
## presságio e cura.
## Zonas: praia, lago, floresta, morro. "líder" mira o líder do grupo da zona.
## O dia vai de 1 a 40 e a hora de 0 a 23 (padrão: 12). "fraca" ou "forte" mudam a intensidade
## (0,3 ou 0,95; padrão 0,8). Repetir o mesmo poder na mesma zona em 3 dias vira imposição.
##
## Comandos condicionais disparam uma vez, quando a condição acontece:
##   na próxima seca: chuva onde houver seca
##   na próxima fome, a partir do ano 30: fartura onde houver fome
##   quando houver guerra: erguer terra onde houver guerra
##   na próxima doença: sonho no lago
## Condições: seca, fome, guerra, doença, prece. "onde houver" (ou sem zona) age na zona
## em que a condição aconteceu; com zona, age na zona dada.

const PODERES := ["chuva", "raio", "fartura", "fogo", "erguer", "sonho", "seca", "diluvio", "terremoto",
	"pressagio", "cura"]
const ZONAS := ["praia", "lago", "floresta", "morro"]
const CONDICOES := ["seca", "fome", "guerra", "doenca", "prece"]


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
	var re_cond := RegEx.new()
	re_cond.compile("^(?:na proxima|no proximo|quando houver|quando)\\s+(\\w+)(?:[^:]*?ano\\s+(\\d+))?[^:]*:\\s*(.+)")
	var n_linha := 0
	for linha in texto.split("\n"):
		n_linha += 1
		var l := _normalizar(linha.strip_edges())
		if l.is_empty() or l.begins_with("#"):
			continue
		var mc := re_cond.search(l)
		if mc != null and CONDICOES.has(mc.get_string(1)):
			var c := _acao(mc.get_string(3), linha, n_linha, true)
			if c.is_empty():
				continue
			c.merge({"condicao": mc.get_string(1), "desde_ano": int(mc.get_string(2)) if not mc.get_string(2).is_empty() else 1,
				"usado": false, "ordem": comandos.size()})
			comandos.append(c)
			continue
		var m := re.search(l)
		if m == null:
			push_warning("Linha %d do cenário ignorada: %s" % [n_linha, linha])
			continue
		var c2 := _acao(m.get_string(4), linha, n_linha, false)
		if c2.is_empty():
			continue
		var hora := 12
		if not m.get_string(3).is_empty():
			hora = clampi(int(m.get_string(3)), 0, 23)
		c2.merge({"ano": int(m.get_string(1)), "dia": clampi(int(m.get_string(2)), 1, 40) - 1, "hora": hora,
			"ordem": comandos.size()})
		comandos.append(c2)
	comandos.sort_custom(func(a, b): return _chave(a) < _chave(b))
	return comandos


## Poder, zona, alvo e intensidade de uma ação. Vazio se a linha não tem o que é preciso.
static func _acao(acao: String, linha: String, n_linha: int, condicional: bool) -> Dictionary:
	var poder := ""
	for p in PODERES:
		if acao.find(p) >= 0:
			poder = p
			break
	var zona := ""
	if not (condicional and acao.find("onde") >= 0):
		for z in ZONAS:
			if acao.find(z) >= 0:
				zona = z
				break
	if poder.is_empty() or (zona.is_empty() and not condicional):
		push_warning("Linha %d do cenário sem poder ou zona: %s" % [n_linha, linha])
		return {}
	return {"poder": poder, "zona": zona, "alvo": "lider" if acao.find("lider") >= 0 else "",
		"intensidade": 0.3 if acao.find("frac") >= 0 else (0.95 if acao.find("forte") >= 0 else 0.8),
		"texto": linha.strip_edges()}


static func _chave(c: Dictionary) -> int:
	if c.has("condicao"):
		return (1 << 50) + c["ordem"]
	return ((c["ano"] * 40 + c["dia"]) * 24 + c["hora"]) * 1000 + c["ordem"]


static func _normalizar(s: String) -> String:
	s = s.to_lower()
	var de := "áàâãéêíóôõúç"
	var para := "aaaaeeiooouc"
	for i in de.length():
		s = s.replace(de[i], para[i])
	return s

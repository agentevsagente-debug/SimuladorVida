extends RefCounted
## A estante: as crônicas fechadas de todos os mundos e eras, guardadas fora do mundo
## salvo. Sobrevive ao abandono do mundo. Cada livro é um arquivo markdown, e um índice
## em texto lista todos.
##
## É insubstituível, então tudo tem cópia: cada livro é gravado também como <id>.1.md, e o
## índice guarda as 3 versões anteriores (indice.1.txt a indice.3.txt). Se o índice estiver
## estragado, valem as cópias; se todas estiverem, o índice é refeito a partir dos livros.

const Arquivo = preload("arquivo.gd")
const PASTA_PADRAO := "user://estante"
const INDICE := "indice.txt"
const CABECALHO := "# Estante de crônicas do Simulador de vida (var_to_str).\n"


## Guarda um livro (como vem de mundo.livros) e devolve o id dele na estante.
static func guardar(livro: Dictionary, pasta: String = PASTA_PADRAO) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	var indice := livros(pasta)
	var id := "%03d-semente-%d-era-%d" % [indice.size() + 1, livro.get("semente", 0), livro["era"]]
	var texto: String = livro["texto"] + "\n"
	if not Arquivo.gravar_com_copias(pasta + "/" + id + ".md", texto, 0) \
			or not Arquivo.gravar_com_copias(pasta + "/" + id + ".1.md", texto, 0):
		push_error("Não foi possível gravar o livro " + id)
		return ""
	indice.append({"id": id, "titulo": livro["titulo"], "era": livro["era"], "semente": livro.get("semente", 0),
		"ano_ini": livro["ano_ini"], "ano_fim": livro["ano_fim"],
		"guardado_em": int(Time.get_unix_time_from_system())})
	Arquivo.gravar_com_copias(pasta + "/" + INDICE, CABECALHO + var_to_str(indice) + "\n")
	return id


## Os livros guardados, do mais antigo ao mais novo:
## {id, titulo, era, semente, ano_ini, ano_fim, guardado_em}.
static func livros(pasta: String = PASTA_PADRAO) -> Array:
	var caminho := pasta + "/" + INDICE
	var v = _ler_indice(caminho)
	if v != null:
		return v
	for n in range(1, Arquivo.COPIAS + 1):
		v = _ler_indice(Arquivo.copia(caminho, n))
		if v != null:
			push_warning("Índice da estante estragado: recuperado de " + Arquivo.copia(caminho, n))
			return v
	return _refazer_indice(pasta)


static func _ler_indice(caminho: String):
	if not FileAccess.file_exists(caminho):
		return null
	var partes := FileAccess.get_file_as_string(caminho).split("\n", true, 1)
	if partes.size() < 2 or partes[0] + "\n" != CABECALHO:
		return null
	var v = str_to_var(partes[1])
	if typeof(v) != TYPE_ARRAY:
		return null
	for l in v:
		if typeof(l) != TYPE_DICTIONARY or not l.has("id"):
			return null
	return v


## Sem índice que preste: os livros continuam lá. Lista-os pelos arquivos, com o título da
## primeira linha de cada um.
static func _refazer_indice(pasta: String) -> Array:
	var r: Array = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return r
	var ids: Array = []
	for nome in dir.get_files():
		if nome.ends_with(".md"):
			var id: String = nome.trim_suffix(".md").trim_suffix(".1")
			if not ids.has(id):
				ids.append(id)
	ids.sort()
	for id in ids:
		var texto := ler(id, pasta)
		if texto.is_empty():
			continue
		var partes: PackedStringArray = id.split("-")
		r.append({"id": id, "titulo": texto.get_slice("\n", 0).trim_prefix("# ").strip_edges(), "era": int(partes[-1]),
			"semente": int(partes[2]) if partes.size() > 2 else 0, "ano_ini": 0, "ano_fim": 0, "guardado_em": 0})
	if not r.is_empty():
		push_warning("Índice da estante refeito a partir dos livros")
	return r


## O texto de um livro, em markdown; vazio se não existe. Se o arquivo sumiu ou está vazio,
## vale a cópia.
static func ler(id: String, pasta: String = PASTA_PADRAO) -> String:
	for caminho in [pasta + "/" + id + ".md", pasta + "/" + id + ".1.md"]:
		if FileAccess.file_exists(caminho):
			var t := FileAccess.get_file_as_string(caminho)
			if not t.strip_edges().is_empty():
				return t
	return ""

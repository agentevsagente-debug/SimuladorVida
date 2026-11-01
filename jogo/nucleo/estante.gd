extends RefCounted
## A estante: as crônicas fechadas de todos os mundos e eras, guardadas fora do mundo
## salvo. Sobrevive ao abandono do mundo. Cada livro é um arquivo markdown, e um índice
## em texto lista todos.

const PASTA_PADRAO := "user://estante"
const INDICE := "indice.txt"


## Guarda um livro (como vem de mundo.livros) e devolve o id dele na estante.
static func guardar(livro: Dictionary, pasta: String = PASTA_PADRAO) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	var indice := livros(pasta)
	var id := "%03d-semente-%d-era-%d" % [indice.size() + 1, livro.get("semente", 0), livro["era"]]
	var f := FileAccess.open(pasta + "/" + id + ".md", FileAccess.WRITE)
	if f == null:
		push_error("Não foi possível gravar o livro " + id)
		return ""
	f.store_string(livro["texto"] + "\n")
	f.close()
	indice.append({"id": id, "titulo": livro["titulo"], "era": livro["era"], "semente": livro.get("semente", 0),
		"ano_ini": livro["ano_ini"], "ano_fim": livro["ano_fim"],
		"guardado_em": int(Time.get_unix_time_from_system())})
	var fi := FileAccess.open(pasta + "/" + INDICE, FileAccess.WRITE)
	fi.store_string("# Estante de crônicas do Simulador de vida (var_to_str).\n" + var_to_str(indice) + "\n")
	fi.close()
	return id


## Os livros guardados, do mais antigo ao mais novo:
## {id, titulo, era, semente, ano_ini, ano_fim, guardado_em}.
static func livros(pasta: String = PASTA_PADRAO) -> Array:
	var caminho := pasta + "/" + INDICE
	if not FileAccess.file_exists(caminho):
		return []
	var f := FileAccess.open(caminho, FileAccess.READ)
	var partes := f.get_as_text().split("\n", true, 1)
	f.close()
	if partes.size() < 2:
		return []
	var v = str_to_var(partes[1])
	return v if typeof(v) == TYPE_ARRAY else []


## O texto de um livro, em markdown; vazio se não existe.
static func ler(id: String, pasta: String = PASTA_PADRAO) -> String:
	var caminho := pasta + "/" + id + ".md"
	if not FileAccess.file_exists(caminho):
		return ""
	return FileAccess.open(caminho, FileAccess.READ).get_as_text()

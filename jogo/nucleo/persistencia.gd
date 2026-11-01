extends RefCounted
## Salvar e carregar o mundo inteiro num arquivo de texto legível, e avançar a
## ausência ao carregar. O arquivo guarda a hora real do salvamento.
##
## O formato é o texto de Variant do Godot (var_to_str), que preserva inteiros e
## chaves inteiras. Os reais são gravados pelos seus 64 bits ("@f:" e um inteiro),
## porque a leitura de reais em texto do Godot perde o último dígito. Assim um mundo
## salvo e carregado continua exatamente igual ao que nunca parou.

const Mundo = preload("mundo.gd")
const Pessoa = preload("pessoa.gd")
const Grupo = preload("grupo.gd")
const Zona = preload("zona.gd")
const Evento = preload("evento.gd")

const VERSAO := 1
const CAMINHO_PADRAO := "user://mundo.txt"
## Campos do mundo que não são copiados um a um: objetos, guardados à parte.
const CAMPOS_ESPECIAIS := ["rng", "_cronista", "pessoas", "grupos", "zonas", "eventos"]
const CAMPOS_CRONISTA := ["_narrados", "_primeiros", "_usados", "anos_escritos", "ultimo_ano_escrito", "_cursor",
	"cronicas_povos"]
const Estante = preload("estante.gd")


## Grava o mundo. Devolve true se deu certo. Livros fechados ainda fora da estante vão para ela.
static func salvar(m, caminho: String = CAMINHO_PADRAO) -> bool:
	m.salvo_em = int(Time.get_unix_time_from_system())
	for livro in m.livros:
		if not livro["na_estante"]:
			Estante.guardar(livro)
			livro["na_estante"] = true
	var texto := "# Simulador de vida: mundo salvo. Arquivo de texto do Godot (var_to_str).\n"
	texto += var_to_str(_codificar(_para_dict(m))) + "\n"
	var tmp := caminho + ".novo"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Não foi possível gravar " + tmp)
		return false
	f.store_string(texto)
	f.close()
	# Troca o arquivo só depois de gravar tudo: um corte de energia não estraga o mundo salvo.
	var dir := DirAccess.open(caminho.get_base_dir())
	if dir == null:
		return false
	if FileAccess.file_exists(caminho):
		dir.remove(caminho.get_file())
	return dir.rename(tmp.get_file(), caminho.get_file()) == OK


## Abandona o mundo: fecha a crônica da era como livro, guarda na estante e apaga o mundo salvo.
## A estante fica. Depois disso, a apresentação cria outro mundo com Mundo.new(semente).
static func abandonar(m, caminho: String = CAMINHO_PADRAO) -> Dictionary:
	var livro: Dictionary = m.abandonar()
	for l in m.livros:
		if not l["na_estante"]:
			Estante.guardar(l)
			l["na_estante"] = true
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	return livro


static func existe(caminho: String = CAMINHO_PADRAO) -> bool:
	return FileAccess.file_exists(caminho)


## Lê um mundo salvo. Devolve null se o arquivo não existe ou não é um mundo.
static func carregar(caminho: String = CAMINHO_PADRAO):
	if not FileAccess.file_exists(caminho):
		return null
	var f := FileAccess.open(caminho, FileAccess.READ)
	var linhas := f.get_as_text().split("\n", true, 1)
	f.close()
	if linhas.size() < 2:
		return null
	var d = _decodificar(str_to_var(linhas[1]))
	if typeof(d) != TYPE_DICTIONARY or d.get("versao", 0) != VERSAO:
		push_error("Arquivo de mundo inválido ou de outra versão: " + caminho)
		return null
	return _de_dict(d)


## Carrega e já avança o tempo que passou desde o salvamento, até o teto de 1 ano.
## Devolve {mundo, ausencia} ou null. `ausencia` é o retorno de mundo.avancar_ausencia().
static func carregar_e_avancar(caminho: String = CAMINHO_PADRAO, agora: int = -1):
	var m = carregar(caminho)
	if m == null:
		return null
	if agora < 0:
		agora = int(Time.get_unix_time_from_system())
	return {"mundo": m, "ausencia": m.avancar_ausencia(agora - m.salvo_em)}


# ---------------------------------------------------------------- conversão

const PREFIXO_REAL := "@f:"


static func _codificar(v):
	match typeof(v):
		TYPE_FLOAT:
			return PREFIXO_REAL + str(PackedFloat64Array([v]).to_byte_array().decode_s64(0))
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = _codificar(v[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(_codificar(x))
			return a
	return v


static func _decodificar(v):
	match typeof(v):
		TYPE_STRING:
			if v.begins_with(PREFIXO_REAL):
				var b := PackedByteArray()
				b.resize(8)
				b.encode_s64(0, int(v.substr(PREFIXO_REAL.length())))
				return b.decode_double(0)
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = _decodificar(v[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(_decodificar(x))
			return a
	return v

static func _campos(o) -> Dictionary:
	var d := {}
	for prop in o.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[prop["name"]] = o.get(prop["name"])
	return d


static func _preencher(o, d: Dictionary) -> void:
	for k in d:
		o.set(k, d[k])


static func _para_dict(m) -> Dictionary:
	var mundo := _campos(m)
	for k in CAMPOS_ESPECIAIS:
		mundo.erase(k)
	var cron := {}
	for k in CAMPOS_CRONISTA:
		cron[k] = m._cronista.get(k)
	var pessoas: Array = []
	for p in m.pessoas.values():
		pessoas.append(_campos(p))
	var grupos: Array = []
	for g in m.grupos:
		grupos.append(_campos(g))
	var zonas: Array = []
	for chave in m.ORDEM_ZONAS:
		zonas.append(_campos(m.zonas[chave]))
	var eventos: Array = []
	for e in m.eventos:
		eventos.append(_campos(e))
	return {"versao": VERSAO, "salvo_em": m.salvo_em, "semente": m.semente,
		"rng_seed": m.rng.seed, "rng_state": m.rng.state, "mundo": mundo, "cronista": cron,
		"pessoas": pessoas, "grupos": grupos, "zonas": zonas, "eventos": eventos}


static func _de_dict(d: Dictionary):
	var m := Mundo.new(d["semente"])
	_preencher(m, d["mundo"])
	m.rng.seed = d["rng_seed"]
	m.rng.state = d["rng_state"]
	m.pessoas.clear()
	for pd in d["pessoas"]:
		var p := Pessoa.new()
		_preencher(p, pd)
		m.pessoas[p.id] = p
	m.grupos.clear()
	for gd in d["grupos"]:
		var g := Grupo.new()
		_preencher(g, gd)
		m.grupos.append(g)
	m.zonas.clear()
	for zd in d["zonas"]:
		var z := Zona.new()
		_preencher(z, zd)
		m.zonas[z.chave] = z
	m.eventos.clear()
	for ed in d["eventos"]:
		var e := Evento.new()
		_preencher(e, ed)
		m.eventos.append(e)
	for k in CAMPOS_CRONISTA:
		m._cronista.set(k, d["cronista"][k])
	return m

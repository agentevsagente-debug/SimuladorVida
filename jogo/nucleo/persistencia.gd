extends RefCounted
## Salvar e carregar o mundo inteiro num arquivo de texto legível, e avançar a
## ausência ao carregar. O arquivo guarda a hora real do salvamento.
##
## O formato é o texto de Variant do Godot (var_to_str), que preserva inteiros e
## chaves inteiras. Os dicionários vão como listas de pares ("@ordem"), porque o texto do
## Godot reordena as chaves e a ordem importa para o determinismo. Os reais são gravados pelos seus 64 bits ("@f:" e um inteiro),
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
const CAMPOS_ESPECIAIS := ["rng", "_cronista", "pessoas", "vivos", "grupos", "zonas", "eventos",
	"recuperado_de", "_rotina_cache", "_montando", "_tarefa", "_descartes", "_fichas_chave", "_eventos_por_tipo", "_por_tipo_ate", "_rotina_versao", "_consultado", "desempenho", "_visiveis_chave", "_visiveis", "_fichas", "_cenas_chave", "_cenas",
	"_construcoes_chave", "_construcoes", "_preces_chave", "_preces", "_textos_prece", "_obras_por_grupo"]
const CAMPOS_CRONISTA := ["_narrados", "_primeiros", "_usados", "anos_escritos", "ultimo_ano_escrito", "_cursor",
	"cronicas_povos"]
const Estante = preload("estante.gd")
const Arquivo = preload("arquivo.gd")
const COPIAS := Arquivo.COPIAS


## Grava o mundo. Devolve true se deu certo. Livros fechados ainda fora da estante vão para ela.
static func salvar(m, caminho: String = CAMINHO_PADRAO) -> bool:
	m.salvo_em = int(Time.get_unix_time_from_system())
	for livro in m.livros:
		if not livro["na_estante"]:
			Estante.guardar(livro)
			livro["na_estante"] = true
	var texto := "# Simulador de vida: mundo salvo. Arquivo de texto do Godot (var_to_str).\n"
	texto += var_to_str(_codificar(_para_dict(m))) + "\n"
	return Arquivo.gravar_com_copias(caminho, texto)


## Abandona o mundo: fecha a crônica da era como livro, guarda na estante e apaga o mundo salvo.
## A estante fica. Depois disso, a apresentação cria outro mundo com Mundo.new(semente).
static func abandonar(m, caminho: String = CAMINHO_PADRAO) -> Dictionary:
	var livro: Dictionary = m.abandonar()
	for l in m.livros:
		if not l["na_estante"]:
			Estante.guardar(l)
			l["na_estante"] = true
	# O mundo abandonado não volta: vão também as cópias de segurança dele.
	for c in [caminho] + range(1, COPIAS + 1).map(func(n): return Arquivo.copia(caminho, n)):
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(c))
	return livro


static func existe(caminho: String = CAMINHO_PADRAO) -> bool:
	if FileAccess.file_exists(caminho):
		return true
	for n in range(1, COPIAS + 1):
		if FileAccess.file_exists(Arquivo.copia(caminho, n)):
			return true
	return false


## Lê um mundo salvo. Se o arquivo está estragado ou ilegível, tenta as cópias, da mais nova
## para a mais velha; o mundo que voltou de uma cópia traz `recuperado_de` (o caminho dela).
## Devolve null se nenhum serve.
static func carregar(caminho: String = CAMINHO_PADRAO):
	var m = _ler_mundo(caminho)
	if m != null:
		return m
	for n in range(1, COPIAS + 1):
		m = _ler_mundo(Arquivo.copia(caminho, n))
		if m != null:
			push_warning("Mundo salvo estragado: recuperado de " + Arquivo.copia(caminho, n))
			m.recuperado_de = Arquivo.copia(caminho, n)
			return m
	return null


static func _ler_mundo(caminho: String):
	if not FileAccess.file_exists(caminho):
		return null
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return null
	var linhas := f.get_as_text().split("\n", true, 1)
	f.close()
	if linhas.size() < 2 or not linhas[0].begins_with("# Simulador de vida: mundo salvo."):
		return null
	var d = _decodificar(str_to_var(linhas[1]))
	if typeof(d) != TYPE_DICTIONARY or d.get("versao", 0) != VERSAO or not _completo(d):
		push_warning("Arquivo de mundo inválido ou de outra versão: " + caminho)
		return null
	return _de_dict(d)


## O dicionário tem tudo o que um mundo salvo precisa (um arquivo cortado ou mexido não tem).
static func _completo(d: Dictionary) -> bool:
	for k in ["semente", "mundo", "rng_seed", "rng_state", "pessoas", "grupos", "zonas", "eventos", "cronista"]:
		if not d.has(k):
			return false
	if typeof(d["mundo"]) != TYPE_DICTIONARY or typeof(d["cronista"]) != TYPE_DICTIONARY:
		return false
	for k in ["pessoas", "grupos", "eventos"]:
		if typeof(d[k]) != TYPE_ARRAY:
			return false
	for k in CAMPOS_CRONISTA:
		if not d["cronista"].has(k):
			return false
	return true


## Carrega e já avança o tempo que passou desde o salvamento, até o teto de 1 ano.
## Devolve {mundo, ausencia} ou null. `ausencia` é o retorno de mundo.avancar_ausencia().
static func carregar_e_avancar(caminho: String = CAMINHO_PADRAO, agora: int = -1):
	var m = carregar(caminho)
	if m == null:
		return null
	if agora < 0:
		agora = int(Time.get_unix_time_from_system())
	var aus: Dictionary = m.avancar_ausencia(agora - m.salvo_em)
	if not m.recuperado_de.is_empty():
		# O retorno conta que o mundo voltou de uma cópia: o que veio depois dela se perdeu.
		aus["recuperado_de"] = m.recuperado_de
		aus["relato"] = ("*O mundo salvo estava estragado. Ele voltou da cópia de segurança de %s, e o que aconteceu " +
			"depois dela se perdeu.*\n\n") % Time.get_datetime_string_from_unix_time(m.salvo_em, true) + aus["relato"]
	return {"mundo": m, "ausencia": aus}


# ---------------------------------------------------------------- conversão

const PREFIXO_REAL := "@f:"


static func _codificar(v):
	match typeof(v):
		TYPE_FLOAT:
			return PREFIXO_REAL + str(PackedFloat64Array([v]).to_byte_array().decode_s64(0))
		TYPE_DICTIONARY:
			# O texto do Godot ordena as chaves; a ordem conta para o determinismo, então
			# cada dicionário vai como lista de pares.
			var pares: Array = []
			for k in v:
				pares.append([k, _codificar(v[k])])
			return {"@ordem": pares}
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
			if v.size() == 1 and v.has("@ordem"):
				for par in v["@ordem"]:
					d[par[0]] = _decodificar(par[1])
				return d
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
	m.vivos.clear()
	for pd in d["pessoas"]:
		var p := Pessoa.new()
		_preencher(p, pd)
		m.pessoas[p.id] = p
		if p.vivo:
			m.vivos[p.id] = p
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
	m.reindexar()
	m._cronista.aquecer()
	return m

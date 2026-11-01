extends RefCounted
## Salvar e carregar o mundo inteiro num arquivo de texto legível, e avançar a
## ausência ao carregar. O arquivo guarda a hora real do salvamento.
##
## O formato é o texto de Variant do Godot (var_to_str), que preserva inteiros e
## chaves inteiras. Os dicionários vão como listas de pares ("@ordem"), porque o texto do
## Godot reordena as chaves e a ordem importa para o determinismo. Os reais são gravados pelos seus 64 bits ("@f:" e um inteiro),
## porque a leitura de reais em texto do Godot perde o último dígito. Assim um mundo
## salvo e carregado continua exatamente igual ao que nunca parou.
##
## Pessoas, povos, zonas e eventos vão em colunas: os nomes dos campos uma vez, e cada um
## como uma lista de valores na mesma ordem (versão 2 do arquivo). A versão 1, com um
## dicionário por objeto, continua sendo lida.
##
## `salvar_async` não trava o jogo: na linha principal só se tira um retrato do que pode
## mudar fora de um passo (os campos do mundo e a crônica); o resto (pessoas, povos,
## eventos) é lido e gravado numa thread. Enquanto isso, o mundo não muda: o passo e os
## gestos do deus esperam a gravação acabar (veja mundo._esperar_threads).

const Mundo = preload("mundo.gd")
const Pessoa = preload("pessoa.gd")
const Grupo = preload("grupo.gd")
const Zona = preload("zona.gd")
const Evento = preload("evento.gd")

const VERSAO := 2
const VERSOES_LIDAS := [1, 2]
const CABECALHO := "# Simulador de vida: mundo salvo. Arquivo de texto do Godot (var_to_str).\n"
const CAMINHO_PADRAO := "user://mundo.txt"
## Campos do mundo que não são copiados um a um: objetos, guardados à parte.
const CAMPOS_ESPECIAIS := ["rng", "_cronista", "pessoas", "vivos", "grupos", "zonas", "eventos",
	"recuperado_de", "_salvamento", "ultimo_salvamento_ok", "_rotina_cache", "_montando", "_tarefa", "_descartes", "_fichas_chave", "_eventos_por_tipo", "_por_tipo_ate", "_rotina_versao", "_consultado", "desempenho", "_visiveis_chave", "_visiveis", "_fichas", "_cenas_chave", "_cenas",
	"_construcoes_chave", "_construcoes", "_preces_chave", "_preces", "_textos_prece", "_obras_por_grupo"]
const CAMPOS_CRONISTA := ["_narrados", "_primeiros", "_usados", "anos_escritos", "ultimo_ano_escrito", "_cursor",
	"cronicas_povos"]
## Campos do cronista que os arquivos antigos não têm: gravados sempre, lidos se existirem.
const CAMPOS_CRONISTA_NOVOS := ["_recentes"]
const Estante = preload("estante.gd")
const Arquivo = preload("arquivo.gd")
const COPIAS := Arquivo.COPIAS


## Grava o mundo agora, na linha principal (para o fechamento do jogo: com o mundo grande,
## leva cerca de meio segundo). Devolve true se deu certo. Livros fechados ainda fora da
## estante vão para ela.
static func salvar(m, caminho: String = CAMINHO_PADRAO) -> bool:
	m._esperar_threads()
	_preparar(m)
	return Arquivo.gravar_com_copias(caminho, _texto(_para_dict(m)))


## Grava o mundo numa thread, sem travar o jogo: na linha principal fica só o retrato do que
## pode mudar fora de um passo (poucos ms). Enquanto a gravação corre, o próximo passo ou
## gesto do deus espera por ela (no jogo, ela acaba muito antes). Uma gravação anterior que
## ainda não acabou é esperada antes. O resultado fica em `mundo.ultimo_salvamento_ok`
## quando ela termina (veja `terminar_salvamento`).
static func salvar_async(m, caminho: String = CAMINHO_PADRAO) -> void:
	m._esperar_threads()
	_preparar(m)
	var g := Gravacao.new()
	g.mundo = m
	g.retrato = _retrato(m)
	g.caminho = caminho
	g.persistencia = load(_ESTE_SCRIPT)
	m._salvamento = g
	g.tarefa = WorkerThreadPool.add_task(g.rodar, false, "salvar o mundo")


## A gravação em andamento já acabou?
static func salvamento_terminou(m) -> bool:
	return m._salvamento == null or WorkerThreadPool.is_task_completed(m._salvamento.tarefa)


## Espera a gravação em andamento (se houver) e devolve se a última gravação deu certo.
static func terminar_salvamento(m) -> bool:
	m._esperar_threads()
	return m.ultimo_salvamento_ok


const _ESTE_SCRIPT := "res://nucleo/persistencia.gd"


## Uma gravação numa thread: completa o retrato com o que só muda nos passos e grava.
class Gravacao:
	extends RefCounted
	var mundo        # seguro aqui até a gravação acabar
	var retrato: Dictionary
	var caminho: String
	var persistencia
	var tarefa: int = -1
	var ok := false

	func rodar() -> void:
		persistencia._completar(retrato, mundo)
		ok = Arquivo.gravar_com_copias(caminho, persistencia._texto(retrato))


static func _preparar(m) -> void:
	m.salvo_em = int(Time.get_unix_time_from_system())
	for livro in m.livros:
		if not livro["na_estante"]:
			Estante.guardar(livro)
			livro["na_estante"] = true


static func _texto(d: Dictionary) -> String:
	return CABECALHO + var_to_str(_codificar(d)) + "\n"


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
	if typeof(d) != TYPE_DICTIONARY or not VERSOES_LIDAS.has(d.get("versao", 0)) or not _completo(d):
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
	for k in ["pessoas", "grupos", "zonas", "eventos"]:
		var v = d[k]
		if typeof(v) == TYPE_DICTIONARY:
			if not v.has("campos") or not v.has("linhas") or typeof(v["linhas"]) != TYPE_ARRAY:
				return false
		elif typeof(v) != TYPE_ARRAY:
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
	for nome in _nomes(o):
		d[nome] = o.get(nome)
	return d


## Os nomes das variáveis do script de um objeto, guardados por script (get_property_list
## é lento demais para chamar em cada uma das dezenas de milhares de pessoas e eventos).
static var _nomes_por_script := {}


static func _nomes(o) -> Array:
	var s = o.get_script()
	if not _nomes_por_script.has(s):
		var l: Array = []
		for prop in o.get_property_list():
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				l.append(prop["name"])
		_nomes_por_script[s] = l
	return _nomes_por_script[s]


## Objetos em colunas: {campos: [nomes], linhas: [[valores na ordem dos campos], ...]}.
static func _colunas(objs: Array, nomes: Array) -> Dictionary:
	var linhas: Array = []
	linhas.resize(objs.size())
	var i := 0
	for o in objs:
		var l: Array = []
		l.resize(nomes.size())
		var j := 0
		for nome in nomes:
			l[j] = o.get(nome)
			j += 1
		linhas[i] = l
		i += 1
	return {"campos": nomes, "linhas": linhas}


## As linhas de uma coluna (versão 2) ou a lista de dicionários (versão 1), como dicionários.
static func _objetos(v) -> Array:
	if typeof(v) == TYPE_ARRAY:
		return v
	var r: Array = []
	var nomes: Array = v["campos"]
	for l in v["linhas"]:
		var d := {}
		for j in nomes.size():
			d[nomes[j]] = l[j]
		r.append(d)
	return r


## O retrato do que pode mudar fora de um passo (consultas, a crônica escrita sob pedido,
## quem o jogador acompanha), copiado a fundo na linha principal. Custa poucos ms.
static func _retrato(m) -> Dictionary:
	var mundo := {}
	for nome in _nomes(m):
		if not CAMPOS_ESPECIAIS.has(nome):
			mundo[nome] = _copia(m.get(nome))
	var cron := {}
	for k in CAMPOS_CRONISTA + CAMPOS_CRONISTA_NOVOS:
		cron[k] = _copia(m._cronista.get(k))
	# Os nomes das colunas são calculados aqui, para a thread só ler o que já está guardado.
	for o in [Pessoa.new(), Grupo.new(), Zona.new(), Evento.new()]:
		_nomes(o)
	return {"versao": VERSAO, "salvo_em": m.salvo_em, "semente": m.semente,
		"rng_seed": m.rng.seed, "rng_state": m.rng.state, "mundo": mundo, "cronista": cron}


static func _copia(v):
	if v is Array or v is Dictionary:
		return v.duplicate(true)
	return v


## Completa o retrato com pessoas, povos, zonas e eventos, que só mudam nos passos e nos
## gestos do deus. Pode rodar numa thread.
static func _completar(d: Dictionary, m) -> void:
	var zonas: Array = []
	for chave in m.ORDEM_ZONAS:
		zonas.append(m.zonas[chave])
	d["pessoas"] = _colunas(m.pessoas.values(), _nomes_por_script[Pessoa])
	d["grupos"] = _colunas(m.grupos, _nomes_por_script[Grupo])
	d["zonas"] = _colunas(zonas, _nomes_por_script[Zona])
	d["eventos"] = _colunas(m.eventos, _nomes_por_script[Evento])


static func _preencher(o, d: Dictionary) -> void:
	for k in d:
		o.set(k, d[k])


static func _para_dict(m) -> Dictionary:
	var d := _retrato(m)
	_completar(d, m)
	return d


static func _de_dict(d: Dictionary):
	var m := Mundo.new(d["semente"])
	_preencher(m, d["mundo"])
	m.rng.seed = d["rng_seed"]
	m.rng.state = d["rng_state"]
	m.pessoas.clear()
	m.vivos.clear()
	for pd in _objetos(d["pessoas"]):
		var p := Pessoa.new()
		_preencher(p, pd)
		m.pessoas[p.id] = p
		if p.vivo:
			m.vivos[p.id] = p
	m.grupos.clear()
	for gd in _objetos(d["grupos"]):
		var g := Grupo.new()
		_preencher(g, gd)
		m.grupos.append(g)
	m.zonas.clear()
	for zd in _objetos(d["zonas"]):
		var z := Zona.new()
		_preencher(z, zd)
		m.zonas[z.chave] = z
	m.eventos.clear()
	for ed in _objetos(d["eventos"]):
		var e := Evento.new()
		_preencher(e, ed)
		m.eventos.append(e)
	for k in CAMPOS_CRONISTA:
		m._cronista.set(k, d["cronista"][k])
	for k in CAMPOS_CRONISTA_NOVOS:
		if d["cronista"].has(k) and typeof(d["cronista"][k]) == typeof(m._cronista.get(k)):
			m._cronista.set(k, d["cronista"][k])
	m.reindexar()
	m._cronista.aquecer()
	return m

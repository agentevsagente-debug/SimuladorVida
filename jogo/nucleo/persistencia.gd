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
## Desde a versão 3, os eventos e os mortos de mais de 300 anos que o mundo arquivou (veja
## mundo._arquivar_antigos) vão num arquivo à parte, ao lado do mundo salvo
## (user://mundo.antigos.txt, com as mesmas cópias de segurança). Ele só cresce: uma versão
## mais nova serve a um mundo salvo mais velho, que usa só as primeiras linhas. Como o mundo
## arquiva um pouco todo dia, as linhas novas vão dentro do próprio mundo salvo
## ("antigos_pendentes") até passarem de ANTIGOS_PENDENTES; aí o arquivo dos antigos é
## regravado inteiro, antes do mundo. Os eventos vivos levam o id, e os arquivados ficam como
## buracos na lista.
const ANTIGOS_PENDENTES := 300
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

const VERSAO := 3
const VERSOES_LIDAS := [1, 2, 3]
const CABECALHO := "# Simulador de vida: mundo salvo. Arquivo de texto do Godot (var_to_str).\n"
const CAMINHO_PADRAO := "user://mundo.txt"
## Campos do mundo que não são copiados um a um: objetos, guardados à parte.
const CAMPOS_ESPECIAIS := ["rng", "_cronista", "pessoas", "vivos", "grupos", "zonas", "eventos",
	"recuperado_de", "_salvamento", "ultimo_salvamento_ok", "_rotina_cache", "_montando", "_tarefa", "_descartes", "_fichas_chave", "_eventos_por_tipo", "_por_tipo_ate", "_rotina_versao", "_consultado", "desempenho", "_visiveis_chave", "_visiveis", "_fichas", "_cenas_chave", "_cenas",
	"_construcoes_chave", "_construcoes", "_preces_chave", "_preces", "_textos_prece", "_obras_por_grupo",
	"arquivar", "_arquivo", "_arquivo_gravado", "_dicas", "_dicas_passo", "_dica_fontes", "_dica_fontes_dia"]
const CAMPOS_CRONISTA := ["_narrados", "_primeiros", "_usados", "anos_escritos", "ultimo_ano_escrito", "_cursor",
	"cronicas_povos"]
## Campos do cronista que os arquivos antigos não têm: gravados sempre, lidos se existirem.
const CAMPOS_CRONISTA_NOVOS := ["_recentes", "_fatia", "_indice_ate"]
const Estante = preload("estante.gd")
const Arquivo = preload("arquivo.gd")
const Antigos = preload("antigos.gd")
const COPIAS := Arquivo.COPIAS


## Grava o mundo agora, na linha principal (para o fechamento do jogo: com o mundo grande,
## leva cerca de meio segundo). Devolve true se deu certo. Livros fechados ainda fora da
## estante vão para ela.
static func salvar(m, caminho: String = CAMINHO_PADRAO) -> bool:
	m._esperar_threads()
	_preparar(m)
	var plano := _plano_dos_antigos(m, caminho)
	if plano["regravar"] and not _gravar_antigos(m, caminho, m._arquivo.conteudo(), plano["no_arquivo"]):
		return false
	var d := _para_dict(m)
	d["antigos_no_arquivo"] = plano["no_arquivo"]
	d["antigos_pendentes"] = m._arquivo.linhas_desde(plano["no_arquivo"])
	return Arquivo.gravar_com_copias(caminho, _texto(d))


## Quantas linhas dos antigos ficam no arquivo à parte, e se ele precisa ser regravado (as
## que passam disso vão dentro do mundo salvo).
static func _plano_dos_antigos(m, caminho: String) -> Dictionary:
	var n: int = m._arquivo.linhas()
	var no_arquivo: int = m._arquivo_gravado.get(caminho, 0)
	if no_arquivo > n or not FileAccess.file_exists(caminho_antigos(caminho)):
		no_arquivo = 0
	if n - no_arquivo > ANTIGOS_PENDENTES:
		return {"regravar": true, "no_arquivo": n}
	return {"regravar": false, "no_arquivo": no_arquivo}


## O caminho do arquivo dos antigos de um mundo salvo: user://mundo.txt -> user://mundo.antigos.txt.
static func caminho_antigos(caminho: String) -> String:
	return "%s.antigos.%s" % [caminho.get_basename(), caminho.get_extension()]


## Grava o arquivo dos antigos, se ele mudou desde a última gravação neste caminho.
static func _gravar_antigos(m, caminho: String, conteudo: PackedByteArray, n: int) -> bool:
	if not Arquivo.gravar_com_copias(caminho_antigos(caminho), conteudo):
		return false
	m._arquivo_gravado[caminho] = n
	return true


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
	# O arquivo dos antigos só é regravado de tempos em tempos (o conteúdo é montado na thread);
	# as linhas novas vão dentro do mundo salvo.
	var plano := _plano_dos_antigos(m, caminho)
	g.regravar_antigos = plano["regravar"]
	g.antigos_n = plano["no_arquivo"]
	g.retrato["antigos_no_arquivo"] = plano["no_arquivo"]
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
	var regravar_antigos := false
	var antigos_n: int = 0
	var caminho: String
	var persistencia
	var tarefa: int = -1
	var ok := false

	func rodar() -> void:
		persistencia._completar(retrato, mundo)
		# As linhas dos antigos que vão dentro do mundo salvo (o mundo não muda enquanto grava).
		retrato["antigos_pendentes"] = mundo._arquivo.linhas_desde(antigos_n)
		ok = (not regravar_antigos or persistencia._gravar_antigos(mundo, caminho, mundo._arquivo.conteudo(), antigos_n)) \
			and Arquivo.gravar_com_copias(caminho, persistencia._texto(retrato))


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
	# O mundo abandonado não volta: vão também as cópias de segurança dele, e o arquivo dos
	# antigos com as cópias dele.
	for base in [caminho, caminho_antigos(caminho)]:
		for c in [base] + range(1, COPIAS + 1).map(func(n): return Arquivo.copia(base, n)):
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
	var m = _ler_mundo(caminho, caminho)
	if m != null:
		return m
	for n in range(1, COPIAS + 1):
		m = _ler_mundo(Arquivo.copia(caminho, n), caminho)
		if m != null:
			push_warning("Mundo salvo estragado: recuperado de " + Arquivo.copia(caminho, n))
			m.recuperado_de = Arquivo.copia(caminho, n)
			return m
	return null


static func _ler_mundo(caminho: String, base: String):
	if not FileAccess.file_exists(caminho):
		return null
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return null
	var linhas := f.get_as_text().split("\n", true, 1)
	f.close()
	if linhas.size() < 2 or not linhas[0].begins_with("# Simulador de vida: mundo salvo."):
		return null
	var d = _decodificar_mundo(str_to_var(linhas[1]))
	if typeof(d) != TYPE_DICTIONARY or not VERSOES_LIDAS.has(d.get("versao", 0)) or not _completo(d):
		push_warning("Arquivo de mundo inválido ou de outra versão: " + caminho)
		return null
	var m = _de_dict(d)
	# Os antigos: as primeiras linhas no arquivo à parte (o dele, ou uma cópia, com pelo menos
	# essas linhas), e as mais novas dentro do próprio mundo salvo.
	if m.arquivo_linhas > 0:
		var no_arquivo: int = d.get("antigos_no_arquivo", m.arquivo_linhas)
		var antigos := caminho_antigos(base)
		var lido := false
		for c in [antigos] + range(1, COPIAS + 1).map(func(n): return Arquivo.copia(antigos, n)):
			lido = m._arquivo.ler(c, no_arquivo)
			if lido:
				if c != antigos:
					push_warning("Arquivo dos antigos estragado: lido de " + c)
				elif no_arquivo > 0:
					m._arquivo_gravado[base] = no_arquivo
				break
		if not lido:
			push_warning("Falta o arquivo dos antigos de " + caminho)
			return null
		m._arquivo.acrescentar(d.get("antigos_pendentes", []))
		if m._arquivo.linhas() != m.arquivo_linhas:
			push_warning("Arquivo dos antigos incompleto: " + caminho)
			return null
	return m


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

static func _codificar(v):
	return Antigos.codificar(v)


static func _decodificar(v):
	return Antigos.decodificar(v)

## Decodifica o mundo lido. Pessoas e eventos, que são dezenas de milhares de linhas, só têm
## decodificadas as colunas que precisam (reais, dicionários, listas com eles): percorrer todo
## valor custava mais que ler o arquivo.
static func _decodificar_mundo(v):
	if typeof(v) != TYPE_DICTIONARY or not v.has("@ordem"):
		return _decodificar(v)
	var d := {}
	for par in v["@ordem"]:
		if par[0] in ["pessoas", "eventos"] and typeof(par[1]) == TYPE_DICTIONARY and par[1].has("@ordem"):
			d[par[0]] = _decodificar_colunas(par[1], Pessoa.new() if par[0] == "pessoas" else Evento.new())
		else:
			d[par[0]] = _decodificar(par[1])
	return d


static func _decodificar_colunas(v, modelo) -> Dictionary:
	var c := {}
	for par in v["@ordem"]:
		c[par[0]] = par[1]
	if not c.has("linhas") or typeof(c["linhas"]) != TYPE_ARRAY:
		return _decodificar(v)
	c["campos"] = _decodificar(c.get("campos", []))
	var linhas: Array = c["linhas"]
	var n: int = c["campos"].size()
	# Pelo tipo do campo na classe: reais e dicionários sempre; listas, se as primeiras
	# linhas trazem algo a decodificar (as de pessoas e eventos só têm ids e textos). Campo
	# que a classe não conhece: olha a coluna inteira.
	var precisa: Array = []
	for j in n:
		var nome: String = c["campos"][j]
		var tipo := typeof(modelo.get(nome)) if nome in modelo else TYPE_NIL
		var p := tipo == TYPE_FLOAT or tipo == TYPE_DICTIONARY
		if tipo == TYPE_ARRAY or tipo == TYPE_NIL:
			var ate := linhas.size() if tipo == TYPE_NIL else mini(linhas.size(), 64)
			for i in ate:
				if j < linhas[i].size() and _precisa(linhas[i][j]):
					p = true
					break
		precisa.append(p)
	var cols: Array = []
	for j in n:
		if precisa[j]:
			cols.append(j)
	if not cols.is_empty():
		for l in linhas:
			for j in cols:
				if j < l.size():
					l[j] = _decodificar(l[j])
	return c


## Um valor precisa de decodificação: um real gravado em texto, um dicionário, ou uma lista
## que tenha algum desses.
static func _precisa(x) -> bool:
	match typeof(x):
		TYPE_STRING:
			return x.begins_with(Antigos.PREFIXO_REAL)
		TYPE_DICTIONARY:
			return true
		TYPE_ARRAY:
			for y in x:
				if _precisa(y):
					return true
	return false


## A posição de cada campo de CAMPOS nas colunas do arquivo (-1 se não está lá).
static func _indices(campos_classe: Array, campos_arquivo: Array) -> PackedInt32Array:
	var ix := PackedInt32Array()
	for nome in campos_classe:
		ix.append(campos_arquivo.find(nome))
	return ix


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
	d["eventos"] = _colunas(m.eventos.filter(func(e): return e != null), _nomes_por_script[Evento])
	d["eventos_total"] = m.eventos.size()


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
	var colunas: bool = typeof(d["pessoas"]) == TYPE_DICTIONARY
	if colunas:
		var ix := _indices(Pessoa.CAMPOS, d["pessoas"]["campos"])
		for l in d["pessoas"]["linhas"]:
			var p := Pessoa.new()
			p.de_linha(l, ix)
			m.pessoas[p.id] = p
			if p.vivo:
				m.vivos[p.id] = p
	else:
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
	# Desde a versão 3, cada evento vai no lugar do seu id; os arquivados ficam como buracos.
	var por_id: bool = d.has("eventos_total")
	if por_id:
		m.eventos.resize(d["eventos_total"])
	if typeof(d["eventos"]) == TYPE_DICTIONARY:
		var ix := _indices(Evento.CAMPOS, d["eventos"]["campos"])
		for l in d["eventos"]["linhas"]:
			var e := Evento.new()
			e.de_linha(l, ix)
			if por_id:
				m.eventos[e.id] = e
			else:
				m.eventos.append(e)
	else:
		for ed in _objetos(d["eventos"]):
			var e := Evento.new()
			_preencher(e, ed)
			m.eventos.append(e)
	for k in CAMPOS_CRONISTA:
		m._cronista.set(k, d["cronista"][k])
	for k in CAMPOS_CRONISTA_NOVOS:
		if d["cronista"].has(k) and typeof(d["cronista"][k]) == typeof(m._cronista.get(k)):
			m._cronista.set("_indice_salvo" if k == "_indice_ate" else k, d["cronista"][k])
	m.reindexar()
	m._cronista.aquecer()
	return m

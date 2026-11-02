extends RefCounted
## A rotina visível de um dia inteiro: o plano de cada pessoa, as cenas dos eventos
## e a posição de todo mundo em qualquer minuto. É uma consulta pura: tudo sai do
## estado do mundo e de `ruido(id, dia, k)`, sem tocar no sorteio da simulação. A mesma
## pessoa no mesmo dia faz sempre a mesma coisa; dois dias nunca são iguais.
##
## Cada pessoa tem um lugar de descanso próprio perto do fogo, fixo enquanto o povo não
## muda: os lugares ficam a ESPACO px uns dos outros, alternando os lados da fogueira. Quem
## não cabe na faixa do povo não vai ao fogo à noite: recolhe-se em casa mais cedo.
##
## O dia usa o mundo inteiro: uma caçada leva 2 a 4 ao morro (ou à mata alta) de manhã e
## os traz de volta à tarde; alguém passa o dia pescando, alguém busca água no lago, outros
## colhem longe do acampamento; as crianças brincam na praia de manhã. O fim de tarde tem
## etapas (a volta com cargas, o lago ou a lenha, cozinhar e comer, a fogueira), e a noite
## tem sempre alguém acordado: o vigia, um casal olhando o céu, quem reza, quem vai ao lago,
## às vezes uma roda de histórias. Pequenos incidentes (crianças brigando, um tombo, um
## animal espantado, alguém perdido, uma discussão) aparecem como cenas curtas.
##
## O plano é uma lista de paradas {ini, fim, x, acao, ida, virado, cena, detalhe}, em minutos
## do dia (0 a 1440). Entre uma parada e outra a pessoa anda a VELOCIDADE px por minuto
## de jogo, com a ação `ida` (andar, lenha...). Blocos fixos (cenas, conversas, crianças
## correndo, reza) têm horário marcado; as tarefas do dia preenchem o resto.
##
## `montar` faz tudo de uma vez: lugares de cada povo, cenas, vida social, o plano de cada
## pessoa e as agendas das 24 horas. O mundo a monta numa thread de trabalho, só lendo o
## estado; enquanto isso, nada no mundo muda (veja mundo._esperar_rotina).

const Cotidiano = preload("cotidiano.gd")

const VELOCIDADE := 5.0          # px por minuto de jogo andando
const ESPACO := 7.0              # px entre dois lugares de descanso em volta do fogo
const MIN_DIA := 1440.0
const ACOES := ["dormir", "andar", "parado", "colher", "rezar", "fogueira", "pescar", "lenha",
	"construir", "forjar", "escrever", "remar", "lutar", "carregar_morto", "dancar", "cuidar", "conversar",
	"cacar", "carregar_caca", "brincar", "deitar", "tecer", "consertar", "cozinhar", "comer"]
## O que a pessoa faz, em detalhe, dentro da ação (campo `detalhe`; "" quando não há).
const DETALHES := ["colher_arbusto", "cavar_raiz", "catar_lenha", "colher_roca", "carregar_cesto", "carregar_agua",
	"buscar_agua", "guardar", "banho", "cozinhar", "comer", "brincar", "vigia", "olhar_ceu", "reza_noturna",
	"historias", "doente", "repartir", "maos_vazias", "brigar", "separar", "machucado", "espantar", "perdido",
	"buscar", "discutir", "descansar", "ninar", "carregar_feixe", "carregar_cesto_cabeca", "espreitar",
	"arremessar", "mirar", "apontar", "espeto", "pescar_lanca", "golpear", "peixe_na_lanca", "despejar", "lavar", "recolher_caca", "caca_no_pau", "bocejar", "aticar", "cochilar", "levar_cesto", "levar_vara", "levar_machado", "levar_pote", "levar_lanca",
	"sesta", "cutucar", "ralhar", "fugir", "mirar_alvo", "arremessar_alvo", "buscar_lanca", "mostrar", "aprovar", "comemorar",
	"trancar_cesto", "moldar_pote", "afiar_lanca", "mostrar_peca", "levar_peca"]
## A ferramenta que se leva a caminho do trabalho, pelo detalhe do trabalho.
const LEVAR := {"colher_arbusto": "levar_cesto", "cavar_raiz": "levar_cesto", "colher_roca": "levar_cesto",
	"catar_lenha": "levar_machado", "buscar_agua": "levar_pote", "banho": "levar_pote", "brincar": ""}
const LEVAR_ACAO := {"pescar": "levar_vara", "construir": "levar_machado", "forjar": "levar_machado"}
## Pequenos incidentes do dia: cenas curtas que não entram na crônica.
const INCIDENTES := ["briga_criancas", "tombo", "animal", "perdido", "discussao"]
## Ordem de prioridade: quem está em duas cenas no mesmo dia fica na primeira.
const PRIORIDADE_CENA := ["guerra", "funeral", "migracao", "casamento", "festa", "nascimento",
	"construcao", "colheita", "prece"]

## O mundo, por referência fraca: o mundo guarda a rotina do dia em cache.
## Tipos de evento que viram cena no próprio dia: se aparecem, a rotina é refeita.
const GERAM_CENA := ["ataque", "separacao", "mudanca", "casamento", "casamento_entre_grupos", "nascimento",
	"estagio", "agricultura", "tempestade", "terremoto", "terremoto_divino", "diluvio"]

var eventos_vistos: int = 0
var m:
	get:
		return _wm.get_ref()
var _wm: WeakRef
var dia: int = 0
var ano: int = 1                 # o ano do dia da rotina
var ctx: Dictionary = {}         # id do grupo -> contexto (lugares do acampamento)
var cenas: Array = []            # cenas do dia
var fixos: Dictionary = {}       # id da pessoa -> [blocos de paradas com horário fixo]
var planos: Dictionary = {}      # id da pessoa -> plano do dia
var abrigos: Dictionary = {}     # zona -> minuto em que a tempestade mandou todos para casa
var faltou := false              # uma consulta achou alguém sem plano
var montada_no_passo: int = 0   # o passo do mundo quando a rotina foi montada
var papeis: Dictionary = {}      # id da pessoa -> o papel do dia: "pescador", "agua" ou "longe"
var _grupos: Array = []


static func ruido(a: int, b: int, c: int) -> float:
	return Cotidiano.ruido(a, b, c)


## Uma rotina vazia do dia `p_dia`; `montar` a preenche.
func _init(mundo, p_dia: int) -> void:
	_wm = weakref(mundo)
	dia = p_dia
	ano = p_dia / mundo.DIAS_ANO + 1
	montada_no_passo = mundo.passo
	if p_dia == mundo.dia_abs():
		cortar_desde = mundo.hora()
	_soltas_ate = maxi(0, cortar_desde - 1)
	_grupos = mundo.grupos_vivos()


## Monta a rotina inteira. Só lê o mundo: pode rodar numa thread. `_mundo` é só para quem
## chama numa thread segurar o mundo vivo enquanto ela roda.
func montar(_mundo = null) -> void:
	for g in _grupos:
		ctx[g.id] = _contexto(g)
	_montar_cenas()
	for g in _grupos:
		_vida_social(g)
	var t: Dictionary = m.tempestade
	if not t.is_empty():
		abrigos[t["zona"]] = t["inicio"] * 60.0
	# O resto (planos, conversas no trabalho, linhas e agendas) só depende do próprio povo: cada
	# povo é montado numa fatia à parte, em paralelo, e as fatias se juntam no fim, na ordem dos
	# povos. O resultado é o mesmo da montagem em série (veja montagem_rotina.gd, o HASH).
	if por_povo_em_paralelo and _grupos.size() > 1:
		var fatias: Array = []
		for g in _grupos:
			fatias.append(_fatia(g))
		var tarefa := WorkerThreadPool.add_group_task(func(i: int): fatias[i]._montar_povo(fatias[i]._grupos[0]),
			fatias.size(), -1, false, "rotina por povo")
		WorkerThreadPool.wait_for_group_task_completion(tarefa)
		for f in fatias:
			planos.merge(f.planos)
			linhas.merge(f.linhas)
			_inicios.merge(f._inicios)
			_agendas.merge(f._agendas)
	else:
		for g in _grupos:
			_montar_povo(g)
	_grupos = []
	# Depois de cortado o dia, só as linhas e as agendas são lidas: os planos e os blocos fixos
	# (um terço da memória de uma rotina com 250 pessoas) saem aqui mesmo, na thread.
	if not guardar_planos:
		planos.clear()
		fixos.clear()


## Montar os povos em paralelo (QA D-07): com a CPU disputada, cada povo numa thread. As
## ferramentas desligam para comparar com a montagem em série.
var por_povo_em_paralelo := true


## Os planos, as conversas no trabalho, as linhas e as agendas de um povo.
func _montar_povo(g) -> void:
	for pid in g.membros:
		planos[pid] = _plano(m.pessoas[pid], g)
	if ctx.has(g.id):
		_conversas_no_trabalho(g, ctx[g.id])
	for pid in g.membros:
		_linha(pid)
		_cortar_dia(pid)


## Uma fatia da rotina para montar um povo numa thread: lê o que é de todos (contexto, blocos
## fixos, papéis, cenas, abrigos, as caçadas), que nesta fase ninguém muda, e escreve só nos próprios planos,
## linhas e agendas.
func _fatia(g):
	var f = get_script().new(m, dia)
	f.ano = ano
	f.ctx = ctx
	f.fixos = fixos
	f.papeis = papeis
	f.cenas = cenas
	f.abrigos = abrigos
	f._porcos = _porcos
	f.cortar_desde = cortar_desde
	f.cortar_ate = cortar_ate
	f._soltas_ate = _soltas_ate
	f._grupos = [g]
	return f


## Solta as agendas das horas que já passaram (antes da hora h - 1): a apresentação só lê a
## hora corrente. Se alguém pedir uma delas de novo, ela é cortada outra vez das linhas.
func soltar_horas_antes(h: int) -> void:
	for k in range(_soltas_ate, h - 1):
		for pid in _agendas:
			_agendas[pid][k] = null
	_soltas_ate = maxi(_soltas_ate, h - 1)


## Solta tudo o que a rotina guarda. O mundo chama numa thread quando a troca por outra:
## desmontar dezenas de milhares de listas e dicionários custa vários milissegundos.
func desmontar() -> void:
	linhas.clear()
	_inicios.clear()
	_agendas.clear()
	planos.clear()
	fixos.clear()
	cenas.clear()
	ctx.clear()
	_sono.clear()


## Quantas pessoas vivas ainda não têm plano nesta rotina.
func faltam() -> int:
	var n := 0
	for g in m.grupos_vivos():
		for id in g.membros:
			if not linhas.has(id):
				n += 1
	return n


var _sono: Dictionary = {}   # id -> a hora dormindo em casa, guardada


## A madrugada antes de a rotina do dia entrar: a última hora do dia da rotina, como foi
## (quem dormia continua dormindo; o vigia continua a ronda).
func dormindo(pid: int) -> Array:
	if not _sono.has(pid):
		var x := 0.0
		if _agendas.has(pid):
			_sono[pid] = agenda(pid, 23)
			return _sono[pid]
		elif m.pessoas.has(pid):
			x = casa_de(pid)
		_sono[pid] = [{"de": 0.0, "ate": 1.0, "x0": x, "x1": x, "acao": "dormir", "virado": 0, "cena": {}, "detalhe": ""}]
	return _sono[pid]


## Onde a pessoa dorme: a casa dela. Não precisa do plano.
func casa_de(pid: int) -> float:
	var p = m.pessoas[pid]
	var g = m.grupo(p.grupo)
	if not ctx.has(g.id):
		ctx[g.id] = _contexto(g)
	return maxf(_casa(p, ctx[g.id]), Cotidiano.MARGEM)


# ---------------------------------------------------------------- lugares

func _contexto(g) -> Dictionary:
	var c := {"casas": [], "largura_casa": 16.0, "rocas": [], "fogo": 0.0, "altar": -1.0, "templo": -1.0, "forja": -1.0,
		"arquivo": -1.0, "celeiro": -1.0, "moinho": -1.0, "barco": -1.0, "obras": []}
	for o in Cotidiano.construcoes_do_grupo(m, g):
		# O chão que as construções da fileira da frente ocupam (para as cenas não cair em cima delas).
		if o["fileira"] == 0 and not o["tipo"] in ["fogueira", "roca", "barco"]:
			c["obras"].append([o["x"] - o["largura"] * 0.5, o["x"] + o["largura"] * 0.5])
		match o["tipo"]:
			"fogueira":
				c["fogo"] = o["x"]
			"cabana":
				c["casas"].append(o["x"])
				c["largura_casa"] = o["largura"]
			"roca":
				c["rocas"].append(o["x"])
			"altar", "templo", "forja", "arquivo", "celeiro", "moinho", "barco":
				c[o["tipo"]] = o["x"]
	if c["altar"] < 0.0:
		c["altar"] = c["fogo"] + 9.0
	c["faixa"] = Cotidiano.faixa_do_grupo(m, g)
	c["trabalho"] = Cotidiano.TRABALHO[g.zona]
	# Onde se busca lenha: a mata mais perto.
	var mata: Array = Cotidiano.FAIXAS["floresta"]
	c["mata"] = clampf(c["fogo"], mata[0] + 6.0, mata[1] - 6.0)
	if g.zona == "floresta" or g.zona == "morro":
		c["mata"] = clampf(c["fogo"] + 30.0 * (1.0 if ruido(g.id, dia, 1) < 0.5 else -1.0), mata[0] + 6.0, Cotidiano.FAIXAS["morro"][1] - 8.0)
	# Onde se pesca: a margem do lago.
	c["margem"] = Cotidiano.MARGEM + 2.0
	# O lugar de descanso de cada um, pela ordem de chegada ao mundo (o id): os primeiros
	# ficam mais perto do fogo, um de cada lado, a ESPACO px uns dos outros.
	var ids: Array = g.membros.duplicate()
	ids.sort()
	var descanso := {}
	for i in ids.size():
		var x: float = c["fogo"] + (1.0 if i % 2 == 0 else -1.0) * (6.0 + ESPACO * (i / 2))
		if x >= c["faixa"][0] + 3.0 and x <= c["faixa"][1] - 3.0 and x >= Cotidiano.MARGEM:
			descanso[ids[i]] = x
	c["descanso"] = descanso
	# A praia onde as crianças brincam, e o lugar longe do acampamento (o morro, ou a mata
	# alta para quem mora no morro) onde se caça e se colhe.
	c["praia"] = clampf(c["fogo"], 150.0, 186.0) if c["fogo"] < 200.0 else 168.0
	c["longe"] = 405.0 if c["fogo"] < 330.0 else 262.0
	# Quanto o trabalho se espalha: povos grandes ocupam a faixa de trabalho inteira.
	c["espalhar"] = maxf(90.0, g.membros.size() * 3.0)
	return c


func _casa(p, c: Dictionary) -> float:
	if c["casas"].is_empty():
		return c["fogo"] - 6.0
	return c["casas"][p.id % c["casas"].size()] + (ruido(p.id, 0, 7) - 0.5) * (c["largura_casa"] - 4.0)


## O lugar de descanso da pessoa perto do fogo; quem não cabe fica perto de casa.
func _lugar_fogo(p, c: Dictionary) -> float:
	return c["descanso"].get(p.id, _casa(p, c))


## Para que lado olha quem está em `x`: para o fogo.
func _virado_ao_fogo(x: float, c: Dictionary) -> int:
	return -1 if x > c["fogo"] else 1


# ---------------------------------------------------------------- blocos fixos

func _fixar(pid: int, paradas: Array, cena: Dictionary = {}) -> bool:
	if not fixos.has(pid):
		fixos[pid] = []
	var ini: float = paradas[0]["ini"]
	var fim: float = paradas[-1]["fim"]
	for b in fixos[pid]:
		if ini < b["fim"] and fim > b["ini"]:
			return false   # já tem algo nesse horário
	for pa in paradas:
		pa["cena"] = cena
		if not pa.has("ida"):
			pa["ida"] = "andar"
		if not pa.has("virado"):
			pa["virado"] = 0
		if not pa.has("detalhe"):
			pa["detalhe"] = ""
		if not pa.has("ida_det"):
			pa["ida_det"] = ""
	fixos[pid].append({"ini": ini, "fim": fim, "paradas": paradas, "cena": cena})
	return true


func _parada(ini: float, fim: float, x: float, acao: String, ida: String = "andar", virado: int = 0,
		detalhe: String = "", ida_det: String = "") -> Dictionary:
	return {"ini": ini, "fim": fim, "x": x, "acao": acao, "ida": ida, "virado": virado, "cena": {}, "detalhe": detalhe,
		"ida_det": ida_det}


func _adultos(g, a_min: int = 16, a_max: int = 55) -> Array:
	var r: Array = []
	for id in g.membros:
		var i: int = m.pessoas[id].idade(ano)
		if i >= a_min and i <= a_max:
			r.append(m.pessoas[id])
	return r


## Ordem fixa por dia: quem é chamado primeiro para uma cena ou uma conversa.
func _embaralhados(lista: Array, k: int) -> Array:
	var pares: Array = []
	for p in lista:
		pares.append([ruido(p.id, dia, k), p])
	pares.sort_custom(func(a, b): return a[0] < b[0])
	var r: Array = []
	for par in pares:
		r.append(par[1])
	return r


# ---------------------------------------------------------------- cenas

func _dia_do_evento(e) -> int:
	return (e.ano - 1) * m.DIAS_ANO + e.dia


func _montar_cenas() -> void:
	var candidatas: Array = []
	var recentes: Array = m.eventos_recentes(dia - 2)
	for i in range(recentes.size() - 1, -1, -1):
		var e = recentes[i]
		var d := _dia_do_evento(e)
		if d < dia - 2:
			break
		if d > dia:
			continue
		match e.tipo:
			"ataque":
				if d == dia:
					candidatas.append(["guerra", e])
				elif d == dia - 1 and not e.dados["mortos"].is_empty():
					candidatas.append(["corvos", e])
			"morte":
				if d == dia - 1 and e.dados["idade"] >= 12:
					candidatas.append(["funeral", e])
			"separacao", "mudanca":
				if d == dia:
					candidatas.append(["migracao", e])
			"casamento", "casamento_entre_grupos":
				if d == dia:
					candidatas.append(["casamento", e])
			"nascimento":
				if d == dia:
					candidatas.append(["nascimento", e])
			"estagio", "agricultura":
				if d >= dia - 1:
					candidatas.append(["construcao", e])
			"tempestade", "terremoto", "terremoto_divino", "diluvio":
				if d >= dia - 1 and e.dados.get("cabanas", e.dados.get("abrigos", 0)) > 0:
					candidatas.append(["construcao", e])
	var ja: Dictionary = {}   # tipo@grupo -> true: no máximo uma cena de cada tipo por povo
	for tipo in PRIORIDADE_CENA + ["corvos"]:
		for cand in candidatas:
			if cand[0] == tipo:
				_criar_cena(tipo, cand[1], ja)
	# Cenas que não vêm de um evento do dia: festa, colheita e prece coletiva.
	for g in m.grupos_vivos():
		var c: Dictionary = ctx[g.id]
		if g.tem_costume("festa_chuva"):
			for cos in g.costumes:
				if cos["tipo"] == "festa_chuva" and m.evento(cos["evento"]).dia == dia % m.DIAS_ANO:
					_cena_danca("festa", g, c, [], "festa:%d:%d" % [g.id, dia], ja)
		if g.estagio >= 2 and dia % m.DIAS_ANO >= 26 and dia % m.DIAS_ANO <= 29 and not c["rocas"].is_empty():
			_cena_colheita(g, c, ja)
		for nec in g.preces:
			var pr: Dictionary = g.preces[nec]
			if nec != "banal" and dia - pr["dia"] >= 3:
				_cena_prece(g, c, ja)
				break


func _criar_cena(tipo: String, e, ja: Dictionary) -> void:
	var g = m.grupo(e.grupo)
	if g == null or g.extinto:
		if tipo != "guerra" and tipo != "corvos":
			return
	var chave := "%s@%d" % [tipo, e.grupo]
	if ja.has(chave):
		return
	ja[chave] = true
	var id := "%s:%d" % [tipo, e.id]
	match tipo:
		"guerra":
			_cena_guerra(e, id)
		"corvos":
			var b = m.grupo(e.outro_grupo)
			if b != null and not b.extinto and ctx.has(b.id):
				cenas.append({"id": id, "tipo": "corvos", "grupo": b.id, "evento": e.id, "ini": 300.0, "fim": 1200.0,
					"participantes": [], "x": ctx[b.id]["fogo"] - 25.0, "mortos": e.dados["mortos"].size()})
		"funeral":
			_cena_funeral(e, g, id)
		"migracao":
			_cena_migracao(e, g, id)
		"casamento":
			_cena_danca("casamento", g, ctx[g.id], e.participantes, id, ja)
		"nascimento":
			_cena_nascimento(e, g, id)
		"construcao":
			_cena_construcao(e, g, id)


func _registrar_cena(id: String, tipo: String, g, e, ini: float, fim: float, participantes: Array, x: float, extra: Dictionary = {}) -> Dictionary:
	var cena := {"id": id, "tipo": tipo, "grupo": g.id if g != null else -1, "evento": e.id if e != null else -1,
		"ini": ini, "fim": fim, "participantes": participantes, "x": x}
	cena.merge(extra)
	cenas.append(cena)
	return cena


func _cena_guerra(e, id: String) -> void:
	var a = m.grupo(e.grupo)
	var b = m.grupo(e.outro_grupo)
	if a == null or b == null or a.extinto or b.extinto or not ctx.has(a.id) or not ctx.has(b.id):
		return
	var ca: Dictionary = ctx[a.id]
	var cb: Dictionary = ctx[b.id]
	var dir := 1.0 if cb["fogo"] >= ca["fogo"] else -1.0
	var bx: float = clampf(cb["fogo"] - dir * 28.0, Cotidiano.MARGEM + 10.0, Cotidiano.LARGURA_MUNDO - 10.0)
	# O ataque da virada do dia vira a batalha da manhã (7h30 às 12h; a luta das 9h às 10h30). Um
	# ataque no meio do dia (forçado por um cenário, ou depois da montagem) começa meia hora depois
	# dele: a rotina é refeita na hora, sem esperar a thread (mundo._ataque_sem_cena). Depois das
	# 18h, não há batalha no dia.
	var t0 := 450.0
	if e.hora >= 6:
		t0 = e.hora * 60.0 + 30.0
		if t0 > 1080.0:
			return
	var cena := _registrar_cena(id, "guerra", a, e, t0, t0 + 270.0, [], bx, {"outro_grupo": b.id, "x_combate": bx,
		"mortos": e.dados["mortos"].size()})
	var info := {"tipo": "guerra", "id": id}
	var lados := [[_embaralhados(_adultos(a, 16, 50), 31).slice(0, 8), -dir, ca, t0],
		[_embaralhados(_adultos(b, 16, 50), 32).slice(0, 8), dir, cb, t0 + 70.0]]
	for lado in lados:
		var i := 0
		for p in lado[0]:
			var linha: float = bx + lado[1] * (5.0 + 4.0 * i)
			var casa := _casa(p, lado[2])
			var ok := _fixar(p.id, [
				_parada(lado[3] + i * 2.0, t0 + 90.0, linha, "parado"),
				_parada(t0 + 90.0, t0 + 180.0, linha, "lutar", "andar", int(-lado[1])),
				_parada(t0 + 240.0, t0 + 250.0, casa, "parado")], info)
			if ok:
				cena["participantes"].append(p.id)
			i += 1


func _cena_funeral(e, g, id: String) -> void:
	var c: Dictionary = ctx[g.id]
	var morto = m.pessoas[e.participantes[0]]
	var local: float
	var rito: String = g.mortos
	match rito:
		"queimam":
			local = c["fogo"] + 22.0
		"veneram":
			local = c["altar"]
		_:
			# Cortejo até o túmulo: na ponta do acampamento, do lado do morro.
			local = minf(c["faixa"][1] - 4.0, Cotidiano.LARGURA_MUNDO - 8.0) if g.zona != "morro" else 468.0
	# Quem vai: parentes primeiro, depois outros.
	var gente: Array = []
	for p in _adultos(g, 12, 80):
		if p.id == morto.conjuge or p.mae == morto.id or p.pai == morto.id or p.id == morto.mae or p.id == morto.pai:
			gente.append(p)
	for p in _embaralhados(_adultos(g, 12, 70), 41):
		if not gente.has(p) and gente.size() < 8:
			gente.append(p)
	if gente.is_empty():
		return
	var cena := _registrar_cena(id, "funeral", g, e, 470.0, 680.0, [], local, {"morto": morto.id, "rito": rito,
		"x_tumulo": local})
	var info := {"tipo": "funeral", "id": id}
	var saida: float = c["fogo"]
	var dir := 1.0 if local >= saida else -1.0
	var i := 0
	for p in gente:
		var carrega := i < 2
		var atras: float = dir * (4.0 * i)
		var paradas := [_parada(470.0, 480.0 + i, saida - atras, "parado")]
		paradas.append(_parada(480.0 + absf(local - saida) / VELOCIDADE + i, 600.0, local - dir * (6.0 + 4.0 * i),
			"rezar", "carregar_morto" if carrega else "andar", int(dir)))
		paradas.append(_parada(600.0 + absf(local - saida) / VELOCIDADE + 5.0, 680.0, _lugar_fogo(p, c), "parado"))
		if _fixar(p.id, paradas, info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_migracao(e, g, id: String) -> void:
	var c: Dictionary = ctx[g.id]
	var origem: float
	if e.tipo == "separacao":
		var pai = m.grupo(e.outro_grupo)
		origem = ctx[pai.id]["fogo"] if pai != null and ctx.has(pai.id) else Cotidiano.centro_da_zona(e.dados["zona_origem"])
	else:
		origem = Cotidiano.centro_da_zona(e.dados["de"])
	var quem: Array = []
	var lista: Array = e.participantes if e.tipo == "separacao" else g.membros
	for pid in lista:
		if m.pessoas.has(pid) and m.pessoas[pid].vivo and m.pessoas[pid].grupo == g.id:
			quem.append(m.pessoas[pid])
	if quem.is_empty():
		return
	var destino: float = c["fogo"]
	var dir := 1.0 if destino >= origem else -1.0
	var duracao := absf(destino - origem) / VELOCIDADE
	var cena := _registrar_cena(id, "migracao", g, e, 390.0, 400.0 + duracao + quem.size() * 2.0 + 30.0, [], origem,
		{"de": origem, "para": destino})
	var info := {"tipo": "migracao", "id": id}
	var i := 0
	for p in quem:
		var largada := 390.0 + i * 2.0
		var paradas := [_parada(largada, largada + 1.0, origem - dir * 3.0 * i, "parado"),
			_parada(largada + 1.0 + duracao, largada + duracao + 30.0, _casa(p, c), "parado", "lenha" if p.idade(ano) >= 12 else "andar")]
		if _fixar(p.id, paradas, info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_danca(tipo: String, g, c: Dictionary, principais: Array, id: String, ja: Dictionary) -> void:
	if g == null or ja.has("danca@%d" % g.id):
		return
	ja["danca@%d" % g.id] = true
	var gente: Array = []
	for pid in principais:
		if m.pessoas.has(pid) and m.pessoas[pid].vivo and m.pessoas[pid].grupo == g.id:
			gente.append(m.pessoas[pid])
	for p in _embaralhados(_adultos(g, 8, 60), 51):
		if not gente.has(p) and gente.size() < (12 if tipo == "festa" else 10):
			gente.append(p)
	var cena := _registrar_cena(id, tipo, g, null, 1140.0, 1260.0, [], c["fogo"])
	var info := {"tipo": tipo, "id": id}
	var i := 0
	for p in gente:
		var lado := 1.0 if i % 2 == 0 else -1.0
		var x: float = c["fogo"] + lado * (5.0 + 5.0 * (i / 2))
		if _fixar(p.id, [_parada(1140.0, 1260.0, x, "dancar", "andar", int(-lado))], info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_nascimento(e, g, id: String) -> void:
	var c: Dictionary = ctx[g.id]
	var mae = m.pessoas.get(e.participantes[1])
	if mae == null or not mae.vivo or mae.grupo != g.id:
		return
	var casa := _casa(mae, c)
	var cena := _registrar_cena(id, "nascimento", g, e, 480.0, 720.0, [], casa, {"mae": mae.id, "crianca": e.participantes[0]})
	var info := {"tipo": "nascimento", "id": id}
	if _fixar(mae.id, [_parada(480.0, 720.0, casa, "cuidar")], info):
		cena["participantes"].append(mae.id)
	var visitas: Array = []
	for p in _embaralhados(_adultos(g, 14, 70), 61):
		if p.id != mae.id and visitas.size() < 5 and (p.sexo == "f" or ruido(p.id, dia, 62) < 0.3):
			visitas.append(p)
	var i := 0
	for p in visitas:
		var lado := 1.0 if i % 2 == 0 else -1.0
		var x := casa + lado * (8.0 + 4.0 * (i / 2))
		if _fixar(p.id, [_parada(540.0 + i * 5.0, 620.0, x, "conversar", "andar", int(-lado))], info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_construcao(e, g, id: String) -> void:
	var c: Dictionary = ctx[g.id]
	var alvo: float = -1.0
	var acao := "construir"
	match e.tipo:
		"estagio":
			alvo = {3: c["templo"], 4: c["forja"], 5: c["arquivo"], 6: c["moinho"]}.get(e.dados["estagio"], -1.0)
		"agricultura":
			if not c["rocas"].is_empty():
				alvo = c["rocas"][0]
				acao = "colher"
	if alvo < 0.0:
		alvo = c["casas"][int(ruido(e.id, dia, 3) * c["casas"].size())] if not c["casas"].is_empty() else c["fogo"] + 12.0
	var gente: Array = []
	for p in _adultos(g, 16, 55):
		if p.tem("engenhoso"):
			gente.append(p)
	for p in _embaralhados(_adultos(g, 16, 55), 71):
		if not gente.has(p) and gente.size() < 6:
			gente.append(p)
	gente = gente.slice(0, 6)
	var cena := _registrar_cena(id, "construcao", g, e, 480.0, 960.0, [], alvo, {"obra": e.tipo})
	var info := {"tipo": "construcao", "id": id}
	var i := 0
	for p in gente:
		var lado := 1.0 if i % 2 == 0 else -1.0
		var x := alvo + lado * (3.0 + 5.0 * (i / 2))
		if _fixar(p.id, [_parada(480.0, 690.0, x, acao, "andar", int(-lado)),
				_parada(780.0, 960.0, x + lado * 2.0, acao, "andar", int(-lado))], info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_colheita(g, c: Dictionary, ja: Dictionary) -> void:
	if ja.has("colheita@%d" % g.id):
		return
	ja["colheita@%d" % g.id] = true
	var id := "colheita:%d:%d" % [g.id, dia]
	var cena := _registrar_cena(id, "colheita", g, null, 450.0, 990.0, [], c["rocas"][0])
	var info := {"tipo": "colheita", "id": id}
	var i := 0
	for p in _adultos(g, 12, 60):
		var roca: float = c["rocas"][i % c["rocas"].size()]
		var paradas: Array = []
		var t := 450.0 + (i % 5) * 3.0
		var k := 0
		while t < 960.0:
			if t >= 690.0 and t < 780.0:
				t = 780.0
			var x := roca + (ruido(p.id, dia, 80 + k) - 0.5) * 14.0
			paradas.append(_parada(t, t + 25.0, x, "colher"))
			t += 30.0
			k += 1
		if _fixar(p.id, paradas, info):
			cena["participantes"].append(p.id)
		i += 1


func _cena_prece(g, c: Dictionary, ja: Dictionary) -> void:
	if ja.has("prece@%d" % g.id):
		return
	ja["prece@%d" % g.id] = true
	var id := "prece:%d:%d" % [g.id, dia]
	var cena := _registrar_cena(id, "prece", g, null, 1080.0, 1130.0, [], c["altar"])
	var info := {"tipo": "prece", "id": id}
	var i := 0
	for p in _embaralhados(_adultos(g, 10, 80), 91):
		if p.fe <= 0.15 or i >= 12:
			continue
		var lado := 1.0 if i % 2 == 0 else -1.0
		var x: float = c["altar"] + lado * (4.0 + 4.0 * (i / 2))
		if _fixar(p.id, [_parada(1080.0, 1130.0, x, "rezar", "andar", int(-lado))], info):
			cena["participantes"].append(p.id)
		i += 1


# ---------------------------------------------------------------- vida social

## Conversas em pares, crianças correndo, mães cuidando, a reza do sacerdote, de um povo.
func _vida_social(g) -> void:
	if not ctx.has(g.id):
		return
	var c: Dictionary = ctx[g.id]
	_cacada(g, c)
	_papeis_do_dia(g)
	_cozinha_da_cacada(g, c)
	_criancas_atras_da_caca(g, c)
	if c.get("sem_cacada", false):
		_cena_da_tarde(g, c)
	_cenas_da_vila(g, c)
	_noite(g, c)
	_incidentes(g, c)
	_travessias(g, c)
	# Pares que conversam no almoço e à noite, em volta do fogo.
	for janela in [[720.0, 750.0, 100], [1200.0, 1250.0, 101]]:
		var adultos: Array = []
		for p in _embaralhados(_adultos(g, 14, 80), janela[2]):
			# No almoço, quem tem papel no dia (pesca, água, longe) fica no trabalho.
			if janela[0] > 1000.0 or not papeis.has(p.id):
				adultos.append(p)
		var n := int(adultos.size() * 0.5) / 2 * 2
		for i in range(0, n, 2):
			var a = adultos[i]
			var b = adultos[i + 1]
			var x := _lugar_fogo(a, c) + (ruido(a.id, dia, janela[2]) - 0.5) * 6.0
			# Cada par termina numa hora (até 15 min antes ou depois do fim da janela): ninguém
			# volta ao trabalho todo mundo junto.
			var fim: float = janela[1] - 15.0 + ruido(a.id, dia, janela[2] + 50) * 30.0
			if _fixar(a.id, [_parada(janela[0], fim, x - 4.0, "conversar", "andar", 1)]):
				if not _fixar(b.id, [_parada(janela[0], fim, x + 4.0, "conversar", "andar", -1)]):
					fixos[a.id].pop_back()
	# Crianças correm umas atrás das outras: de manhã na praia, à tarde e à noite perto do fogo.
	var criancas: Array = []
	for id in g.membros:
		var i: int = m.pessoas[id].idade(ano)
		if i >= 3 and i <= 8:
			criancas.append(m.pessoas[id])
	criancas = _embaralhados(criancas, 110)
	for i in range(0, criancas.size() - 1, 2):
		var lider = criancas[i]
		var seguidor = criancas[i + 1]
		# Em pedaços de meia hora: um incidente no meio só tira o pedaço dele.
		var k := 0
		for janela in [[540.0, 690.0, c["praia"]], [840.0, 1080.0, c["praia"]], [1170.0, 1230.0, c["fogo"]]]:
			var t: float = janela[0]
			while t < janela[1] - 8.0:
				var pl: Array = []
				var ps: Array = []
				var fim_pedaco: float = minf(t + 30.0, janela[1])
				while t < fim_pedaco - 4.0:
					var x: float = janela[2] + (ruido(lider.id, dia, 200 + k) - 0.5) * (40.0 if janela[2] < 200.0 else 60.0)
					pl.append(_parada(t, t + 2.0, x, "brincar", "brincar", 0, "brincar"))
					ps.append(_parada(t + 3.0, t + 4.0, x - 5.0, "brincar", "brincar", 0, "brincar"))
					t += 9.0
					k += 1
				# Se o par está ocupado (num incidente, numa cena), a outra criança brinca sozinha.
				_fixar(lider.id, pl)
				_fixar(seguidor.id, ps)
	# A criança que ficou sem par brinca sozinha na areia.
	if criancas.size() % 2 == 1:
		var so = criancas[-1]
		var k2 := 0
		for janela in [[540.0, 690.0], [840.0, 1080.0]]:
			var t: float = janela[0]
			while t < janela[1] - 10.0:
				_fixar(so.id, [_parada(t, t + 10.0, c["praia"] + (ruido(so.id, dia, 230 + k2) - 0.5) * 40.0, "brincar", "brincar", 0, "brincar")])
				t += 16.0
				k2 += 1
	# Mães com bebê cuidam perto de casa.
	for id in g.membros:
		var p = m.pessoas[id]
		if p.sexo == "f" and p.idade(ano) >= 16:
			for f in p.filhos:
				if m.pessoas[f].vivo and m.pessoas[f].idade(ano) <= 1:
					var casa := _casa(p, c)
					_fixar(p.id, [_parada(560.0, 640.0, casa + 3.0, "cuidar")])
					_fixar(p.id, [_parada(840.0, 900.0, casa + 3.0, "cuidar")])
					break
	# O sacerdote reza no altar de manhã e ao entardecer; quem tem prece aberta, também.
	if g.sacerdote != -1 and m.pessoas[g.sacerdote].vivo:
		_fixar(g.sacerdote, [_parada(420.0, 460.0, c["altar"], "rezar")])
		_fixar(g.sacerdote, [_parada(1085.0, 1120.0, c["altar"] + 1.0, "rezar")])
	for nec in g.preces:
		var autor: int = g.preces[nec]["autor"]
		if m.pessoas.has(autor) and m.pessoas[autor].vivo and m.pessoas[autor].grupo == g.id:
			_fixar(autor, [_parada(375.0, 400.0, c["altar"] + (ruido(autor, 0, 5) - 0.5) * 6.0, "rezar")])


# ---------------------------------------------------------------- plano de cada pessoa

var _sorte_id := 0
var _sorte_k := 0


## Próximo número da sequência fixa da pessoa no dia.
func _sorte() -> float:
	_sorte_k += 1
	return ruido(_sorte_id, dia, _sorte_k)


# Estado das tarefas de um adulto, geradas ciclo a ciclo conforme o plano pede.
var _t_p = null
var _t_c: Dictionary = {}
var _t_escolhidas: Array = []
var _t_i := 0
var _t_fim := 0


## As tarefas do dia, em ordem: cada uma é {x, acao, dur, ida}. Variam por pessoa e por dia.
## As dos adultos vêm aos poucos (veja _mais_tarefas): o dia raramente usa todas.
func _tarefas(p, g, c: Dictionary) -> Array:
	var r: Array = []
	var idade: int = p.idade(ano)
	_sorte_id = p.id
	_sorte_k = 300
	_t_fim = 0
	if idade >= 9 and idade < 12:
		# As crianças maiores ajudam: colhem perto de casa, buscam água, catam lenha.
		for i in 12:
			var u := _sorte()
			if u < 0.35:
				r.append({"x": c["fogo"] + (_sorte() - 0.5) * 60.0, "acao": "colher", "det": "colher_arbusto", "dur": 20.0 + _sorte() * 25.0})
			elif u < 0.55:
				r.append({"x": c["margem"] + _sorte() * 6.0, "acao": "parado", "det": "buscar_agua", "dur": 6.0, "virado": -1})
				r.append({"x": _casa(p, c) + 4.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_agua"})
			elif u < 0.75:
				r.append({"x": c["mata"] + (_sorte() - 0.5) * 20.0, "acao": "colher", "det": "catar_lenha", "dur": 15.0 + _sorte() * 15.0})
			else:
				r.append({"x": c["praia"] + (_sorte() - 0.5) * 36.0, "acao": "brincar", "det": "brincar", "dur": 20.0 + _sorte() * 30.0})
		return r
	if idade < 12:
		# Crianças brincam na praia e acompanham a lida perto de casa.
		for i in 12:
			if _sorte() < 0.4:
				r.append({"x": c["praia"] + (_sorte() - 0.5) * 36.0, "acao": "brincar", "det": "brincar", "dur": 20.0 + _sorte() * 30.0})
			elif _sorte() < 0.5:
				r.append({"x": c["fogo"] + (_sorte() - 0.5) * 50.0, "acao": "brincar", "det": "brincar", "dur": 15.0 + _sorte() * 20.0})
			else:
				r.append({"x": c["fogo"] + (_sorte() - 0.5) * 50.0, "acao": "colher", "det": "colher_arbusto", "dur": 20.0 + _sorte() * 30.0})
		return r
	if idade > 60:
		# Os velhos ficam perto do fogo, dão voltas curtas, conversam, tecem e consertam.
		for i in 14:
			var lugar := _lugar_fogo(p, c)
			r.append({"x": lugar, "acao": "fogueira", "dur": 40.0 + _sorte() * 50.0, "virado": _virado_ao_fogo(lugar, c)})
			if _sorte() < 0.5:
				r.append({"x": c["fogo"] + (_sorte() - 0.5) * 50.0, "acao": "conversar" if _sorte() < 0.5 else "parado", "dur": 10.0 + _sorte() * 15.0})
			else:
				r.append({"x": _casa(p, c) + 2.0, "acao": "tecer" if _sorte() < 0.5 else "consertar", "dur": 25.0 + _sorte() * 30.0})
		return r
	var menu: Array = []    # [peso, construtor]
	var papel: String = papeis.get(p.id, "")

	# Coletar num percurso de arbustos, perto ou longe do acampamento.
	menu.append([2.5 if g.estagio <= 2 else 1.0, "coletar"])
	menu.append([4.0 if papel == "longe" else 0.8, "coletar_longe"])
	if g.zona == "lago" or g.zona == "praia" or _sorte() < 0.15:
		menu.append([2.5, "pescar"])
	if papel == "pescador":
		menu.append([12.0, "pescar"])
	menu.append([5.0 if papel == "agua" else 0.8, "agua"])
	menu.append([1.5, "lenha"])
	if g.estagio >= 2 and not c["rocas"].is_empty():
		menu.append([3.0, "roca"])
	if p.tem("engenhoso") or (g.estagio >= 3 and _sorte() < 0.3):
		menu.append([1.5, "construir"])
	if g.estagio >= 4 and c["forja"] >= 0.0 and (p.saberes.has("metal") or p.tem("engenhoso")):
		menu.append([3.0, "forjar"])
	if g.estagio >= 5 and c["arquivo"] >= 0.0 and (p.saberes.has("escrita") or p.tem("curioso") or g.sacerdote == p.id):
		menu.append([3.0, "escrever"])
	if g.estagio >= 6 and c["barco"] >= 0.0:
		menu.append([1.5, "remar"])
	if p.tem("curioso"):
		menu.append([1.0, "explorar"])
	if p.tem("devoto"):
		menu.append([1.0, "altar"])
	if g.lider == p.id:
		menu.append([2.5, "visitar"])
	# De 2 a 4 atividades no dia, repetidas em ciclos até encher a jornada.
	var n := 2 + int(_sorte() * 3.0)
	var escolhidas: Array = []
	for i in n:
		var total := 0.0
		for op in menu:
			total += op[0]
		var s: float = _sorte() * total
		var escolha: String = menu[-1][1]
		for op in menu:
			s -= op[0]
			if s <= 0.0:
				escolha = op[1]
				break
		escolhidas.append(escolha)
	# Quem tem papel no dia faz sobretudo o papel.
	match papel:
		"pescador":
			# O pescador fica na margem o dia todo: é ele que mantém gente no lago.
			escolhidas = ["pescar", "pescar", "pescar"]
		"agua":
			escolhidas = ["agua", escolhidas[0], escolhidas[0]]
		"longe":
			escolhidas = ["coletar_longe", "coletar_longe", escolhidas[0]]
	n = escolhidas.size()
	_t_p = p
	_t_c = c
	_t_escolhidas = escolhidas
	_t_i = 0
	_t_fim = n * 4
	return r


## Mais um ciclo das tarefas do adulto que está sendo planejado. False quando acabaram.
func _mais_tarefas(r: Array) -> bool:
	if _t_i >= _t_fim:
		return false
	var p = _t_p
	var c: Dictionary = _t_c
	var trab: Array = c["trabalho"]
	var escolha: String = _t_escolhidas[_t_i % _t_escolhidas.size()]
	_t_i += 1
	match escolha:
		"coletar":
			for j in 2 + int(_sorte() * 2.0):
				var u := _sorte()
				var det := "colher_arbusto" if u < 0.4 else ("cavar_raiz" if u < 0.7 else "catar_lenha")
				var xc: float = clampf(c["fogo"] + (_sorte() - 0.5) * c["espalhar"], trab[0] + 3.0, trab[1] - 3.0)
				# Perto do fogo, vai de mãos vazias; o cesto só aparece em quem vai longe.
				r.append({"x": xc, "acao": "colher", "det": det, "dur": 20.0 + _sorte() * 25.0, "perto": absf(xc - c["fogo"]) < 45.0})
		"coletar_longe":
			var det2 := "colher_arbusto" if _sorte() < 0.5 else "cavar_raiz"
			for j in 3 + int(_sorte() * 2.0):
				r.append({"x": c["longe"] + (_sorte() - 0.5) * 60.0, "acao": "colher", "det": det2, "dur": 30.0 + _sorte() * 25.0})
			if _sorte() < 0.5:
				r.append({"x": _casa(p, c) + 5.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_cesto"})
		"agua":
			r.append({"x": c["margem"] + _sorte() * 6.0, "acao": "parado", "det": "buscar_agua", "dur": 6.0 + _sorte() * 6.0, "virado": -1})
			r.append({"x": _casa(p, c) + 4.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_agua"})
		"pescar":
			r.append({"x": c["margem"] + _sorte() * 6.0, "acao": "pescar", "dur": 60.0 + _sorte() * 70.0, "virado": -1})
		"lenha":
			r.append({"x": c["mata"] + (_sorte() - 0.5) * 30.0, "acao": "colher", "det": "catar_lenha", "dur": 20.0 + _sorte() * 20.0})
			r.append({"x": _casa(p, c) + 5.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_cesto"})
		"roca":
			var roca: float = c["rocas"][int(_sorte() * c["rocas"].size())]
			for j in 2:
				r.append({"x": roca + (_sorte() - 0.5) * 14.0, "acao": "colher", "det": "colher_roca", "dur": 35.0 + _sorte() * 30.0})
			if c["celeiro"] >= 0.0:
				r.append({"x": c["celeiro"], "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_cesto"})
		"construir":
			var alvo: float = c["casas"][int(_sorte() * c["casas"].size())] if not c["casas"].is_empty() else c["fogo"] + 14.0
			r.append({"x": alvo + 6.0, "acao": "construir", "dur": 50.0 + _sorte() * 50.0, "virado": -1})
		"forjar":
			r.append({"x": c["forja"] + 4.0, "acao": "forjar", "dur": 90.0 + _sorte() * 90.0, "virado": -1})
		"escrever":
			r.append({"x": c["arquivo"] + (_sorte() - 0.5) * 10.0, "acao": "escrever", "dur": 90.0 + _sorte() * 90.0})
		"remar":
			r.append({"x": c["margem"], "acao": "parado", "dur": 5.0})
			r.append({"x": c["barco"] - 4.0 + _sorte() * 8.0, "acao": "remar", "dur": 60.0 + _sorte() * 60.0, "ida": "remar"})
		"explorar":
			var borda: float = Cotidiano.MARGEM + 3.0 if _sorte() < 0.5 else Cotidiano.LARGURA_MUNDO - 6.0
			r.append({"x": borda, "acao": "parado", "dur": 15.0 + _sorte() * 20.0})
		"altar":
			r.append({"x": c["altar"] + (_sorte() - 0.5) * 6.0, "acao": "rezar", "dur": 20.0 + _sorte() * 20.0})
		"visitar":
			for lugar in [c["rocas"][0] if not c["rocas"].is_empty() else c["mata"], c["forja"] if c["forja"] >= 0.0 else c["margem"], c["fogo"] - 20.0]:
				r.append({"x": lugar + 3.0, "acao": "conversar", "dur": 12.0 + _sorte() * 10.0})
	if r.size() > 1 and _sorte() < 0.6:
		r.append({"x": -1.0, "acao": "deitar", "det": "descansar", "dur": 5.0 + _sorte() * 10.0})   # descanso à sombra, onde estiver
	return true


## Monta o plano do dia: a madrugada (dormindo, ou de vigia), o dia de tarefas, o fim de
## tarde em etapas e a noite. Os blocos fixos (cenas, conversas, vigia) mandam: a pessoa
## chega a tempo e cumpre.
func _plano(p, g) -> Array:
	var c: Dictionary = ctx[g.id]
	var casa := _casa(p, c)
	var acorda := 300.0 + ruido(p.id, dia, 2) * 90.0
	var deita := 1260.0 + ruido(p.id, dia, 3) * 90.0
	var blocos: Array = fixos.get(p.id, []).duplicate()
	blocos.sort_custom(func(a, b): return a["ini"] < b["ini"])
	if p.doente > 0:
		# O doente passa o dia em casa: dorme, acorda um pouco, não dorme direito à noite.
		return [_parada(0.0, 540.0, casa, "dormir"), _parada(540.0, 660.0, casa, "parado", "andar", 0, "doente"),
			_parada(660.0, 960.0, casa, "dormir"), _parada(960.0, 1080.0, casa, "parado", "andar", 0, "doente"),
			_parada(1080.0, 1380.0, casa, "dormir"), _parada(1380.0, MIN_DIA, casa, "parado", "andar", 0, "doente")]
	# A madrugada: dorme, a não ser que tenha vigia ou outra coisa marcada antes de acordar.
	var plano: Array = []
	var t := 0.0
	var x := casa
	var bi := 0
	while bi < blocos.size() and blocos[bi]["ini"] < acorda:
		var b: Dictionary = blocos[bi]
		# Entre dois compromissos da madrugada, quem tem tempo volta para casa e dorme.
		if x != casa and b["ini"] - absf(b["paradas"][0]["x"] - casa) / VELOCIDADE > t + absf(casa - x) / VELOCIDADE + 5.0:
			var em_casa := t + absf(casa - x) / VELOCIDADE
			plano.append(_parada(em_casa, em_casa + 1.0, casa, "dormir"))
			t = em_casa + 1.0
			x = casa
		var sai: float = b["ini"] - absf(b["paradas"][0]["x"] - x) / VELOCIDADE
		if sai > t + 1.0:
			plano.append(_parada(t, sai, x, "dormir"))
		elif plano.is_empty():
			x = b["paradas"][0]["x"]
		t = _cumprir_bloco(plano, b, t, x)
		x = b["paradas"][-1]["x"]
		bi += 1
	if plano.is_empty() or x != casa or t < acorda:
		var volta := t + absf(casa - x) / VELOCIDADE
		plano.append(_parada(volta if not plano.is_empty() else 0.0, maxf(acorda, volta + 1.0), casa, "dormir"))
		t = plano[-1]["fim"]
		x = casa
	# A tempestade não entra no plano: é posta por cima, na hora de cortar (veja _cortar_hora).
	var tarefas := _tarefas(p, g, c)
	var fim_tarefas := 975.0 + ruido(p.id, dia, 4) * 60.0
	if papeis.get(p.id, "") == "pescador":
		fim_tarefas = 1065.0   # pesca até o sol baixar
	var r := _encher(plano, tarefas, true, t, x, fim_tarefas, blocos, bi, p)
	t = r[0]
	x = r[1]
	bi = r[2]
	# O fim de tarde: a volta com a carga, o lago ou a lenha, cozinhar e comer, a fogueira.
	var tarde := _fim_de_tarde(p, c, casa, g)
	var ate_fogo := deita - absf(casa - _lugar_fogo(p, c)) / VELOCIDADE
	r = _encher(plano, tarde, false, t, x, ate_fogo, blocos, bi, p)
	t = r[0]
	x = r[1]
	bi = r[2]
	# A noite: o que ainda estiver marcado (vigia, histórias, o céu), e depois casa.
	while bi < blocos.size():
		t = _cumprir_bloco(plano, blocos[bi], t, x)
		x = blocos[bi]["paradas"][-1]["x"]
		bi += 1
	var chega_casa := maxf(t + absf(casa - x) / VELOCIDADE, minf(deita, MIN_DIA - 1.0))
	if chega_casa < MIN_DIA - 0.5:
		plano.append(_parada(chega_casa, MIN_DIA, casa, "dormir"))
	plano = _sem_ficar_parado(plano, c)
	_longe_do_fogo(plano, c)
	_longe_do_porco(plano, p.id)
	return plano


## À tarde (12h45 às 16h45), a cada 12 a 15 min, dois do mesmo povo que estão trabalhando ou à
## toa a menos de 24 px um do outro param uns 6 min e conversam ali mesmo, um de frente para o
## outro: na tela, sempre há conversa em algum lugar, sem tirar ninguém do lugar.
const TRABALHOS_COM_CONVERSA := ["colher", "tecer", "consertar", "construir", "cuidar", "parado", "deitar", "fogueira"]


func _conversas_no_trabalho(g, c: Dictionary) -> void:
	var w := 0
	var ultimos := {}
	var ultima := -100
	var horas: Array = []
	for t in range(765, 1006, 5):
		w += 1
		if t - ultima < 12:
			continue
		var par := _tentar_conversa(g, float(t), w, ultimos, 24.0)
		if not par.is_empty():
			ultimos = {par[0]: true, par[1]: true}
			ultima = t
			horas.append(t)
	# Meia hora sem conversa: um par mais longe (até 60 px) se encontra; um vai até o outro.
	for k in 8:
		var ini := 765 + k * 30
		if horas.any(func(h): return h >= ini and h < ini + 30):
			continue
		for t in range(ini, ini + 25, 5):
			w += 1
			var par := _tentar_conversa(g, float(t), w, ultimos, 60.0)
			if not par.is_empty():
				ultimos = {par[0]: true, par[1]: true}
				break


## Dois do mesmo povo, a até `dist` px, com um bloco de trabalho ou de folga que cobre a
## conversa: conversam. Se estão longe, o segundo vai até o primeiro e depois volta.
## Devolve os dois ids, ou [] se não achou.
func _tentar_conversa(g, t: float, w: int, ultimos: Dictionary, dist: float) -> Array:
	# O pescador e quem busca água continuam no que fazem: são eles que levam o povo ao lago.
	# Quem pode conversar é filtrado uma vez, na ordem embaralhada, e o bloco de cada um nesse
	# instante é procurado uma vez só (o resultado é o mesmo de comparar todos com todos).
	var gente: Array = []
	for p in _embaralhados(g.membros.map(func(id): return m.pessoas[id]), 3900 + w):
		if not ultimos.has(p.id) and p.idade(ano) >= 10 and not papeis.get(p.id, "") in ["pescador", "agua"]:
			gente.append(p)
	var blocos := {}
	for a in gente:
		var ia := _bloco_de_trabalho(a.id, t, 9.0)
		if ia < 0:
			continue
		for b in gente:
			if b == a:
				continue
			if not blocos.has(b.id):
				blocos[b.id] = _bloco_de_trabalho(b.id, t, 9.0)
			var ib: int = blocos[b.id]
			if ib < 0:
				continue
			var xa: float = planos[a.id][ia]["x"]
			var xb: float = planos[b.id][ib]["x"]
			var longe := absf(xa - xb)
			if longe > dist:
				continue
			var lado: float = 1.0 if xb >= xa else -1.0
			var anda: float = maxf(0.0, longe - 6.0) / VELOCIDADE if longe > 24.0 else 0.0
			var dur: float = 5.0 + ruido(a.id, dia, 4000 + w) * 3.0
			if anda > 0.0:
				# b vai até perto de a: os dois blocos precisam cobrir a ida, a conversa e a volta.
				if _bloco_de_trabalho(a.id, t, anda + dur + 1.0) != ia or _bloco_de_trabalho(b.id, t, 2.0 * anda + dur + 1.0) != ib:
					continue
				# b para do lado de a que fica longe do fogo.
				var xc: float = xa + lado * 6.0
				if absf(xc - ctx[g.id]["fogo"]) < FOGO_LIVRE + 0.5:
					lado = -lado
					xc = xa + lado * 6.0
				_conversar_no_bloco(a.id, ia, t + anda, t + anda + dur, int(lado))
				_conversar_no_bloco(b.id, ib, t, t + anda + dur, int(-lado), xc)
			else:
				_conversar_no_bloco(a.id, ia, t, t + dur, int(lado))
				_conversar_no_bloco(b.id, ib, t, t + dur, int(-lado))
			return [a.id, b.id]
	return []


## O bloco de trabalho ou de folga que cobre [t, t + dur] no plano da pessoa (-1 se não há).
func _bloco_de_trabalho(pid: int, t: float, dur: float) -> int:
	var plano: Array = planos.get(pid, [])
	for i in plano.size():
		var pa: Dictionary = plano[i]
		if pa["ini"] <= t and pa["fim"] >= t + dur and TRABALHOS_COM_CONVERSA.has(pa["acao"]) and pa["cena"].is_empty():
			return i
		if pa["ini"] > t:
			break
	return -1


## Põe uma conversa de t a fim no meio do bloco i (em x, se dado; senão, no lugar do bloco).
func _conversar_no_bloco(pid: int, i: int, t: float, fim: float, virado: int, x: float = -1.0) -> void:
	var plano: Array = planos[pid]
	var pa: Dictionary = plano[i]
	var antes: Dictionary = pa.duplicate()
	antes["fim"] = t
	var fala: Dictionary = pa.duplicate()
	fala["ini"] = t
	fala["fim"] = fim
	fala["acao"] = "conversar"
	fala["detalhe"] = ""
	fala["virado"] = virado
	if x >= 0.0:
		fala["x"] = x
		fala["ida"] = "andar"
		fala["ida_det"] = ""
	var depois: Dictionary = pa.duplicate()
	depois["ini"] = fim
	if x >= 0.0:
		depois["ida"] = "andar"
		depois["ida_det"] = ""
	plano[i] = depois
	plano.insert(i, fala)
	if t - pa["ini"] > 0.5:
		plano.insert(i, antes)


## De dia (6h às 17h), ninguém fica parado no mesmo ponto mais de PARADO_MAX min: quem está
## de pé, deitado, sentado no fogo ou conversando muda de lugar (6 a 10 px) a cada 15 a 20 min,
## e volta. A mudança sai das horas do próprio bloco (e não da pessoa): os dois de um par que
## conversa mudam juntos e continuam um de frente para o outro. Cenas não mudam.
const PARADO_MAX := 20.0
const MEXIVEIS := ["parado", "deitar", "fogueira", "conversar"]


func _sem_ficar_parado(plano: Array, c: Dictionary) -> Array:
	var r: Array = []
	for pa in plano:
		if pa["fim"] - pa["ini"] <= PARADO_MAX or not MEXIVEIS.has(pa["acao"]) or not pa["cena"].is_empty() \
				or pa["fim"] <= 360.0 or pa["ini"] >= 1020.0:
			r.append(pa)
			continue
		var chave := int(pa["ini"] * 7.0 + pa["fim"])
		var t: float = pa["ini"]
		var k := 0
		while t < pa["fim"] - 0.01:
			var fim: float = minf(pa["fim"], t + 15.0 + ruido(chave, dia, 3400 + k) * 5.0)
			if pa["fim"] - fim < 5.0:
				# Sobra pouco: junta, se couber no limite; senão, divide o resto ao meio.
				fim = pa["fim"] if pa["fim"] - t <= PARADO_MAX else t + (pa["fim"] - t) * 0.5
			var q: Dictionary = pa.duplicate()
			q["ini"] = t
			q["fim"] = fim
			if k % 2 == 1:
				var d: float = (6.0 + ruido(chave, dia, 3500 + k) * 4.0) * (1.0 if ruido(chave, dia, 3600 + k) < 0.5 else -1.0)
				q["x"] = clampf(pa["x"] + d, Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)
			if k > 0:
				q["ida"] = "andar"
				q["ida_det"] = ""
			if q["acao"] == "fogueira":
				q["virado"] = _virado_ao_fogo(q["x"], c)
			r.append(q)
			t = fim
			k += 1
	# Blocos seguidos no mesmo ponto (buscar água e descansar na margem, por exemplo) também
	# somam: o que passaria de PARADO_MAX muda de lugar. As conversas ficam onde estão (o par
	# combinou o lugar).
	var desde := -1.0
	var x_atual := -9999.0
	for q in r:
		if absf(q["x"] - x_atual) > 0.01:
			x_atual = q["x"]
			desde = q["ini"]
			continue
		if q["fim"] - desde > PARADO_MAX and MEXIVEIS.has(q["acao"]) and q["acao"] != "conversar" and q["cena"].is_empty() 				and q["ini"] >= 360.0 and q["ini"] < 1020.0:
			var chave := int(q["ini"] * 7.0 + q["fim"])
			var d: float = (6.0 + ruido(chave, dia, 3700) * 4.0) * (1.0 if ruido(chave, dia, 3800) < 0.5 else -1.0)
			q["x"] = clampf(q["x"] + d, Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)
			if q["acao"] == "fogueira":
				q["virado"] = _virado_ao_fogo(q["x"], c)
			x_atual = q["x"]
			desde = q["ini"]
	return r


## Ninguém para em cima da fogueira: quem cair a menos de FOGO_LIVRE px do centro dela vai
## para a beira, do lado em que estava.
const FOGO_LIVRE := 6.0


func _longe_do_fogo(plano: Array, c: Dictionary) -> void:
	var f: float = c["fogo"]
	for pa in plano:
		var d: float = pa["x"] - f
		if absf(d) < FOGO_LIVRE:
			pa["x"] = f + (FOGO_LIVRE if d >= 0.0 else -FOGO_LIVRE)


## O fim de tarde de uma pessoa, como tarefas: quem trabalhou volta com a carga; uns vão ao
## lago (banho ou água), outros buscam lenha; depois cozinham ou comem perto do fogo, e
## ficam na fogueira até a hora de dormir.
func _fim_de_tarde(p, c: Dictionary, casa: float, g) -> Array:
	var r: Array = []
	var idade: int = p.idade(ano)
	if idade >= 12 and idade <= 60:
		r.append({"x": casa + 4.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_cesto"})
		var s := ruido(p.id, dia, 20)
		if s < 0.45:
			var banho := s < 0.25
			r.append({"x": c["margem"] + ruido(p.id, dia, 22) * 6.0, "acao": "parado", "det": "banho" if banho else "buscar_agua",
				"dur": 15.0 + ruido(p.id, dia, 23) * 15.0, "virado": -1})
			# Na volta do lago, traz água (depois do banho também).
			r.append({"x": casa + 4.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_agua"})
		elif s < 0.7:
			r.append({"x": c["mata"] + (ruido(p.id, dia, 24) - 0.5) * 30.0, "acao": "colher", "det": "catar_lenha", "dur": 15.0})
			r.append({"x": casa + 5.0, "acao": "parado", "det": "guardar", "dur": 2.0, "ida": "lenha", "ida_det": "carregar_cesto"})
		else:
			r.append({"x": casa + 2.0, "acao": _afazer_de_casa(p, 26), "dur": 25.0})
	var lugar := _lugar_fogo(p, c)
	var vir := _virado_ao_fogo(lugar, c) if c["descanso"].has(p.id) else 0
	var cozinha: bool = idade >= 14 and ruido(p.id, dia, 21) < 0.35
	if not cozinha:
		# Enquanto a comida não fica pronta: conversa perto do fogo, senta, ou descansa em casa.
		var e := ruido(p.id, dia, 28)
		if e < 0.4:
			r.append({"x": lugar + (ruido(p.id, dia, 27) - 0.5) * 8.0, "acao": "conversar", "dur": 999.0, "fim_em": 1090.0, "virado": vir})
		elif e < 0.7:
			r.append({"x": lugar, "acao": "fogueira", "dur": 999.0, "fim_em": 1090.0, "virado": vir})
		else:
			r.append({"x": casa + 2.0, "acao": _afazer_de_casa(p, 29), "dur": 999.0, "fim_em": 1090.0})
	if idade < 12:
		# As crianças brincam na praia até o sol baixar, depois perto do fogo enquanto os
		# grandes comem, e comem depois.
		r.append({"x": c["praia"] + (ruido(p.id, dia, 34) - 0.5) * 30.0, "acao": "brincar", "det": "brincar", "dur": 999.0, "fim_em": 1075.0})
		r.append({"x": c["fogo"] + (ruido(p.id, dia, 33) - 0.5) * 40.0, "acao": "brincar", "det": "brincar", "dur": 999.0, "fim_em": 1115.0})
	r.append({"x": lugar, "acao": "cozinhar" if cozinha else "comer", "det": "cozinhar" if cozinha else "comer",
		"dur": 45.0 + ruido(p.id, dia, 25) * 20.0, "virado": vir, "desde": 1060.0 if cozinha else (1115.0 if idade < 12 else 1090.0),
		"espera": "cozinhar" if cozinha else ("brincar" if idade < 12 else "conversar")})
	# Depois de comer, nem todos vão para a fogueira: uns ninam os pequenos, tecem ou
	# consertam alguma coisa em casa, e só depois vêm para o fogo.
	if idade >= 14 and ruido(p.id, dia, 30) < 0.35:
		r.append({"x": casa + 2.0, "acao": "cuidar" if _tem_pequeno(p) else _afazer_de_casa(p, 31), "det": "ninar" if _tem_pequeno(p) else "",
			"dur": 60.0 + ruido(p.id, dia, 32) * 80.0})
	if c["descanso"].has(p.id):
		r.append({"x": lugar, "acao": "fogueira", "dur": 999.0, "virado": vir})
	return r


## Um afazer de casa, visível: tecer cesto, consertar uma ferramenta, ou deitar à sombra.
func _afazer_de_casa(p, k: int) -> String:
	var r := ruido(p.id, dia, k)
	if r < 0.35:
		return "tecer"
	if r < 0.7:
		return "consertar"
	return "deitar"


func _tem_pequeno(p) -> bool:
	for f in p.filhos:
		if m.pessoas.has(f) and m.pessoas[f].vivo and m.pessoas[f].idade(ano) <= 3:
			return true
	return false


## Enche o plano com as tarefas até `ate`, cumprindo os blocos fixos que vierem antes.
## Devolve [t, x, índice do próximo bloco]. Com `gerar`, as tarefas vêm de _mais_tarefas.
func _encher(plano: Array, tarefas: Array, gerar: bool, t: float, x: float, ate: float, blocos: Array, bi: int, p) -> Array:
	var ti := 0
	while t < ate:
		while gerar and ti >= tarefas.size() and _mais_tarefas(tarefas):
			pass
		# O próximo bloco fixo manda: chega a tempo e cumpre.
		var proximo: Dictionary = blocos[bi] if bi < blocos.size() else {}
		if not proximo.is_empty() and proximo["ini"] < ate + 300.0:
			var primeira: Dictionary = proximo["paradas"][0]
			var ate_la: float = absf(primeira["x"] - x) / VELOCIDADE
			if t + ate_la + 20.0 >= proximo["ini"] or (ti >= tarefas.size() and proximo["ini"] < ate):
				t = _cumprir_bloco(plano, proximo, t, x)
				x = proximo["paradas"][-1]["x"]
				bi += 1
				continue
		if ti >= tarefas.size():
			break
		var tarefa: Dictionary = tarefas[ti]
		ti += 1
		# x < 0: onde a pessoa estiver (o fim do último bloco do plano).
		var aqui: float = plano[-1]["x"] if not plano.is_empty() else x
		var destino: float = aqui if tarefa["x"] < 0.0 else tarefa["x"]
		var chega := t + absf(destino - x) / VELOCIDADE
		if tarefa.get("desde", 0.0) > chega + 1.0:
			# Chegou antes da hora: espera fazendo algo (quem cozinha já prepara; os outros conversam).
			# Uma espera longa começa sentado perto do fogo; só a última meia hora é a espera dita.
			var meia: float = maxf(chega, tarefa["desde"] - 30.0)
			if meia > chega + 1.0:
				plano.append(_parada(chega, meia, destino, "fogueira", "andar", tarefa.get("virado", 0), "", _a_caminho(tarefa)))
			plano.append(_parada(meia, tarefa["desde"], destino, tarefa.get("espera", "conversar"), "andar", tarefa.get("virado", 0),
				"", _a_caminho(tarefa) if meia <= chega + 1.0 else ""))
			t = tarefa["desde"]
			x = destino
			chega = t
		var limite: float = proximo["ini"] - absf(proximo["paradas"][0]["x"] - destino) / VELOCIDADE if not proximo.is_empty() else ate
		var termina := minf(minf(chega + tarefa["dur"], tarefa.get("fim_em", MIN_DIA)), minf(limite, ate))
		if termina - chega < 3.0:
			continue
		# Trabalho de mão (colher, construir, caçar) anda aos poucos: de arbusto em arbusto.
		var trecho_ini := chega
		var xi := destino
		var passo_k := 0
		while trecho_ini < termina:
			var trecho_fim := termina
			if tarefa["acao"] in ["colher", "construir"] and termina - trecho_ini > 24.0:
				trecho_fim = trecho_ini + 12.0 + ruido(p.id, dia, 500 + ti * 10 + passo_k) * 8.0
			plano.append(_parada(trecho_ini, trecho_fim, xi, tarefa["acao"], tarefa.get("ida", "andar"), tarefa.get("virado", 0),
				tarefa.get("det", ""), _a_caminho(tarefa) if passo_k == 0 else ""))
			passo_k += 1
			var dx := (ruido(p.id, dia, 600 + ti * 10 + passo_k) - 0.5) * 12.0
			var proximo_x := xi + dx
			trecho_ini = trecho_fim + absf(dx) / VELOCIDADE
			xi = proximo_x
		t = termina
		x = plano[-1]["x"]
	return [t, x, bi]


## O que a pessoa leva no caminho até a tarefa: a carga de volta, ou a ferramenta de ida.
func _a_caminho(tarefa: Dictionary) -> String:
	if tarefa.has("ida_det"):
		return tarefa["ida_det"]
	if tarefa.get("perto", false):
		return ""
	if LEVAR_ACAO.has(tarefa["acao"]):
		return LEVAR_ACAO[tarefa["acao"]]
	return LEVAR.get(tarefa.get("det", ""), "")


# ---------------------------------------------------------------- o dia no mundo inteiro

## A caçada, à tarde, longe do acampamento: o porco aparece 35 px além da última cabana, na
## borda da mata ou do morro (um dia de cada lado), em chão aberto. 2 a 4 adultos saem juntos
## do fogo entre 13h30 e 14h e espreitam agachados das 14h às 16h30: 9 a 11 avanços de 2 a 4 px,
## com pausas de 12 a 17 min em que o porco fuça e eles esperam abaixados. Vão escalonados, a
## 7 px uns dos outros; o da frente ergue a lança, para um instante (`mirar`) e arremessa, e os
## de trás apontam. Se acertam, recolhem o bicho caído e voltam com ele no pau, atravessando a
## vila até a fogueira, com 2 ou 3 crianças correndo atrás; a caça é repartida no fogo no fim
## de tarde (17h15 às 17h45), com alguém do povo no espeto. Enquanto dura a caçada, ninguém de
## fora dela fica parado a menos de 27 px do porco (veja _longe_do_porco).
## As etapas vão na cena (`etapas`), com a hora e o lugar de cada uma e onde está o bicho,
## para a apresentação encenar; a espreita vem em várias etapas seguidas, uma por avanço.
const ETAPAS_CACADA := ["saida", "espreita", "arremesso", "abatido", "fuga", "volta", "repartir"]
const MIRA := 0.8          # min de jogo com a lança erguida antes de soltar (uns 1,5 s em 1x)
const ARREMESSO := 6.0     # min de jogo do arremesso: a lança voa, crava, o bicho tomba ou foge
const ABATE := 16.0        # min de jogo recolhendo o bicho (ou a lança, quando ele fugiu), no mínimo
const REPARTIR := 22.0     # min de jogo repartindo a caça no fogo
const ESCALONADO := 7.0    # px entre um caçador e o de trás
const PORCO_LIVRE := 27.0  # px em volta do porco sem ninguém de fora da caçada parado
const ALEM_DAS_CASAS := 35.0  # px entre a última cabana do lado e o porco

var _porcos: Array = []    # as caçadas do dia: {x0, x1, ini, fim, cacadores}, para _longe_do_porco


func _cacada(g, c: Dictionary) -> void:
	var adultos := _embaralhados(_adultos(g, 16, 50), 901)
	# Um dia em cada três, mais ou menos, não há caçada: entra uma cena do começo da tarde.
	if adultos.size() < 3 or ruido(g.id, dia, 900) > 0.67:
		c["sem_cacada"] = true
		return
	var n := clampi(adultos.size() / 3, 2, 4)
	# O porco: 40 px além da última cabana, um dia do lado da mata e outro do lado do morro (se
	# não cabe num lado, vai para o outro). Em chão aberto, longe da água.
	var xs: Array = c["casas"].duplicate()
	xs.append(c["fogo"])
	var esq: float = xs.min() - c["largura_casa"] / 2.0 - ALEM_DAS_CASAS
	var dir: float = xs.max() + c["largura_casa"] / 2.0 + ALEM_DAS_CASAS
	var min_x: float = Cotidiano.FAIXAS["praia"][1] + 4.0
	var max_x: float = Cotidiano.LARGURA_MUNDO - 30.0
	var lado: float = -1.0 if ruido(g.id, dia, 902) < 0.5 else 1.0
	if (lado < 0.0 and esq < min_x) or (lado > 0.0 and dir > max_x):
		lado = -lado
	var bicho0: float = clampf(esq if lado < 0.0 else dir, min_x, max_x)
	var bicho1: float = bicho0 + lado * 6.0              # o porco se afasta um pouco enquanto fuça
	var perto: float = bicho1 - lado * 12.0              # de onde a lança sai
	var vazia := ruido(g.id, dia, 903) < 0.3
	var id := "cacada:%d:%d" % [g.id, dia]
	var dv: float = absf(c["fogo"] - bicho1) / VELOCIDADE
	# A espreita acaba entre 16h30 e 16h40; a volta chega ao fogo entre 17h15 e 17h23 (o que
	# sobra fica no abate, nunca na volta).
	var mira := 990.0 + ruido(g.id, dia, 905) * 10.0
	var solta := mira + MIRA
	var chega := maxf(1035.0 + ruido(g.id, dia, 906) * 8.0, solta + ARREMESSO + ABATE + dv)
	var fim_abate := chega - dv
	# A espreita: 9 a 11 avanços de 2 a 4 px até `perto`, escalonados a ESCALONADO px; sem espaço
	# até o fogo, fica mais curta (6 avanços, no mínimo), não os passos menores.
	var saida := 810.0 + ruido(g.id, dia, 904) * 30.0
	var passos := 9 + int(ruido(g.id, dia, 907) * 3.0)
	var pxs: Array = []
	var total := 0.0
	for k in passos:
		pxs.append(2.0 + ruido(g.id, dia, 930 + k) * 2.0)
		total += pxs[k]
	var cabe: float = absf(perto - c["fogo"]) - 8.0 - ESCALONADO * (n - 1)
	while passos > 6 and total > cabe:
		total -= pxs.pop_back()
		passos -= 1
	var escala: float = minf(1.0, maxf(cabe, passos * 2.0) / total)
	var lider: Array = [perto - lado * total * escala]   # onde o da frente está em cada avanço
	var t0: float = saida + 12.0 + absf(lider[0] - c["fogo"]) / VELOCIDADE
	# As pausas: o tempo da espreita repartido entre os avanços, umas mais longas que outras.
	var pesos: Array = []
	var soma := 0.0
	for k in passos:
		pesos.append(0.8 + ruido(g.id, dia, 910 + k) * 0.4)
		soma += pesos[k]
	var horas: Array = [t0]
	for k in passos:
		lider.append(lider[k] + lado * pxs[k] * escala)
		horas.append(horas[k] + (mira - t0) * pesos[k] / soma)
	var etapas: Array = [{"etapa": "saida", "ini": saida / 60.0, "fim": t0 / 60.0, "x": c["fogo"], "x_bicho": bicho0}]
	for k in passos:
		# O porco fuça e se mexe: vai de bicho0 a bicho1, indo e voltando um pouco.
		var xb: float = lerpf(bicho0, bicho1, float(k) / passos) + snappedf((ruido(g.id, dia, 950 + k) - 0.5) * 4.0, 0.5)
		etapas.append({"etapa": "espreita", "ini": horas[k] / 60.0, "fim": horas[k + 1] / 60.0, "x": lider[k], "x_bicho": xb})
	etapas.append({"etapa": "espreita", "mira": true, "ini": mira / 60.0, "fim": solta / 60.0, "x": perto, "x_bicho": bicho1})
	etapas.append({"etapa": "arremesso", "ini": solta / 60.0, "fim": (solta + ARREMESSO) / 60.0, "x": perto, "x_bicho": bicho1})
	etapas.append({"etapa": "fuga" if vazia else "abatido", "ini": (solta + ARREMESSO) / 60.0, "fim": fim_abate / 60.0, "x": bicho1,
		"x_bicho": bicho1 + lado * 40.0 if vazia else bicho1})
	etapas.append({"etapa": "volta", "ini": fim_abate / 60.0, "fim": chega / 60.0, "x": c["fogo"], "x_bicho": -1.0})
	etapas.append({"etapa": "repartir", "ini": chega / 60.0, "fim": (chega + REPARTIR) / 60.0, "x": c["fogo"], "x_bicho": -1.0})
	var cena := _registrar_cena(id, "cacada", g, null, saida, chega + REPARTIR, [], bicho1, {"vazia": vazia, "bicho": "porco",
		"etapas": etapas, "cozinha": -1, "criancas": []})
	var info := {"tipo": "cacada", "id": id}
	var volta_cena := {"tipo": "caca_vazia" if vazia else "cacada", "id": ("caca_vazia:%d:%d" % [g.id, dia]) if vazia else id}
	var i := 0
	for p in adultos:
		if i >= n:
			break
		var atras: float = -lado * ESCALONADO * i
		var paradas: Array = [_parada(saida, saida + 12.0, c["fogo"] + lado * (8.0 + i * 5.0), "parado")]
		# Espreitando, agachados: a cada avanço, uns passos e agacha de novo.
		for k in passos:
			paradas.append(_parada(horas[k], horas[k + 1] - pxs[k] * escala / VELOCIDADE, lider[k] + atras, "cacar", "andar", int(lado),
				"espreitar", "levar_lanca"))
		if i == 0:
			paradas.append(_parada(mira, solta, perto, "cacar", "andar", int(lado), "mirar"))
			paradas.append(_parada(solta, solta + ARREMESSO, perto, "cacar", "andar", int(lado), "arremessar"))
		else:
			paradas.append(_parada(mira, solta + ARREMESSO, perto + atras, "cacar", "andar", int(lado), "apontar"))
		# Acertou: recolhem o bicho. Errou: vão buscar a lança, onde o bicho estava.
		paradas.append(_parada(solta + ARREMESSO + 1.0, fim_abate, bicho1 - lado * (3.0 + i * 3.0), "parado", "andar", int(lado),
			"" if vazia else "recolher_caca"))
		var volta := _parada(chega, chega + REPARTIR, c["fogo"] + (6.0 + i * 5.0) * -lado, "parado", "andar" if vazia else "carregar_caca", 0,
			"maos_vazias" if vazia else "repartir", "" if vazia else "caca_no_pau")
		paradas.append(volta)
		if _fixar(p.id, paradas, info):
			volta["cena"] = volta_cena
			cena["participantes"].append(p.id)
			i += 1
	if i == 0:
		cenas.erase(cena)
		c["sem_cacada"] = true
		return
	_porcos.append({"x0": minf(bicho0, bicho1) - 2.0, "x1": maxf(bicho0, bicho1) + 2.0, "ini": saida, "fim": fim_abate,
		"cacadores": cena["participantes"]})
	if vazia:
		_registrar_cena(volta_cena["id"], "caca_vazia", g, null, chega, chega + REPARTIR, cena["participantes"].duplicate(), c["fogo"])
		return
	cena["chega"] = chega
	cena["lado"] = lado
	cena["volta_ini"] = fim_abate


## Nos dias sem caçada, uma cena no começo da tarde (13h30 às 15h30), com começo, meio e fim
## que se veem de longe, alternando entre três (as etapas vão na cena, como na caçada):
## - `pesca_lanca`: um adulto na água rasa, com a lança de pesca; erra umas vezes, acerta, ergue
##   o peixe na ponta e o leva ao fogo;
## - `coleta_morro`: 3 ou 4 adultos sobem ao morro, colhem e descem em fila, com o cesto na
##   cabeça, até o fogo, onde despejam os cestos;
## - `lavagem`: 2 adultos lavam na beira do lago, e as crianças brincam na água.
const CENAS_DA_TARDE := ["pesca_lanca", "coleta_morro", "lavagem"]


func _cena_da_tarde(g, c: Dictionary) -> void:
	var adultos := _embaralhados(_adultos(g, 16, 55), 961)
	if adultos.is_empty():
		return
	var tipo: String = CENAS_DA_TARDE[int(ruido(g.id, dia, 960) * 3.0) % 3]
	if tipo == "coleta_morro" and adultos.size() < 3:
		tipo = "pesca_lanca"
	var id := "%s:%d:%d" % [tipo, g.id, dia]
	var ini := 810.0 + ruido(g.id, dia, 962) * 20.0
	var margem: float = c["margem"] + 1.0
	match tipo:
		"pesca_lanca":
			# Tenta 2 a 4 vezes antes de acertar; cada tentativa: espera parado com a lança erguida, golpeia.
			var ida: float = ini + absf(c["fogo"] - margem) / VELOCIDADE
			var tentativas := 2 + int(ruido(g.id, dia, 963) * 3.0)
			var etapas: Array = [{"etapa": "ida", "ini": ini / 60.0, "fim": ida / 60.0, "x": margem}]
			var paradas: Array = []
			var t: float = ida
			for k in tentativas + 1:
				var espera: float = 10.0 + ruido(g.id, dia, 964 + k) * 8.0
				etapas.append({"etapa": "espera", "ini": t / 60.0, "fim": (t + espera) / 60.0, "x": margem})
				paradas.append(_parada(t, t + espera, margem, "pescar", "andar", -1, "pescar_lanca", "levar_lanca"))
				t += espera
				var acerto: bool = k == tentativas
				etapas.append({"etapa": "golpe", "acerto": acerto, "ini": t / 60.0, "fim": (t + 1.0) / 60.0, "x": margem})
				paradas.append(_parada(t, t + 1.0, margem, "pescar", "andar", -1, "golpear"))
				t += 1.0
			etapas.append({"etapa": "peixe", "ini": t / 60.0, "fim": (t + 3.0) / 60.0, "x": margem})
			paradas.append(_parada(t, t + 3.0, margem, "parado", "andar", 1, "peixe_na_lanca"))
			t += 3.0
			var chega: float = t + absf(c["fogo"] - margem) / VELOCIDADE
			etapas.append({"etapa": "volta", "ini": t / 60.0, "fim": chega / 60.0, "x": c["fogo"]})
			etapas.append({"etapa": "entrega", "ini": chega / 60.0, "fim": (chega + 8.0) / 60.0, "x": c["fogo"]})
			var xf: float = c["fogo"] + (8.0 if margem > c["fogo"] else -8.0)
			paradas.append(_parada(chega, chega + 8.0, xf, "parado", "andar", 0, "guardar", "peixe_na_lanca"))
			var cena := _registrar_cena(id, tipo, g, null, ini, chega + 8.0, [], margem, {"etapas": etapas})
			for p in adultos:
				if papeis.get(p.id, "") == "" and _fixar(p.id, paradas, {"tipo": tipo, "id": id}):
					cena["participantes"].append(p.id)
					return
			cenas.erase(cena)
		"coleta_morro":
			# Sobem juntos, colhem no morro até 15h35 e descem em fila, a 8 px uns dos outros.
			var longe: float = c["longe"]
			var lado: float = signf(longe - c["fogo"])
			var sobe: float = ini + absf(longe - c["fogo"]) / VELOCIDADE
			var desce: float = maxf(sobe + 60.0, 935.0)   # ficam no morro até 15h35
			var chega: float = desce + absf(longe - c["fogo"]) / VELOCIDADE
			var etapas: Array = [{"etapa": "subida", "ini": ini / 60.0, "fim": sobe / 60.0, "x": longe},
				{"etapa": "coleta", "ini": sobe / 60.0, "fim": desce / 60.0, "x": longe},
				{"etapa": "descida", "ini": desce / 60.0, "fim": (chega + 3.0) / 60.0, "x": c["fogo"]},
				{"etapa": "despejar", "ini": (chega + 3.0) / 60.0, "fim": (chega + 12.0) / 60.0, "x": c["fogo"]}]
			var cena := _registrar_cena(id, tipo, g, null, ini, chega + 12.0, [], longe, {"etapas": etapas})
			var k := 0
			for p in adultos:
				if k >= 4:
					break
				if papeis.has(p.id):
					continue
				var atras: float = k * 1.6     # min: em fila, a 8 px uns dos outros
				var xc: float = longe + (k - 1.5) * 10.0
				var paradas: Array = [_parada(sobe + atras, desce, xc, "colher", "andar", 0,
						"cavar_raiz" if k % 2 == 0 else "colher_arbusto", "levar_cesto"),
					_parada(chega + atras, chega + 12.0, c["fogo"] + lado * (8.0 + k * 4.0), "parado", "lenha", int(-lado), "despejar",
						"carregar_cesto_cabeca")]
				if _fixar(p.id, paradas, {"tipo": tipo, "id": id}):
					cena["participantes"].append(p.id)
					k += 1
			if k < 2:
				for pid in cena["participantes"]:
					fixos[pid] = fixos[pid].filter(func(b): return b["cena"].get("id", "") != id)
				cenas.erase(cena)
		"lavagem":
			# Dois adultos lavam na beira do lago; as crianças (3 a 10 anos) brincam na água rasa.
			var ida: float = ini + absf(c["fogo"] - margem) / VELOCIDADE
			var fim: float = ida + 60.0 + ruido(g.id, dia, 965) * 20.0
			var etapas: Array = [{"etapa": "ida", "ini": ini / 60.0, "fim": ida / 60.0, "x": margem},
				{"etapa": "lavar", "ini": ida / 60.0, "fim": fim / 60.0, "x": margem},
				{"etapa": "volta", "ini": fim / 60.0, "fim": (fim + absf(c["fogo"] - margem) / VELOCIDADE) / 60.0, "x": c["fogo"]}]
			var cena := _registrar_cena(id, tipo, g, null, ini, fim, [], margem, {"etapas": etapas, "criancas": []})
			var k := 0
			for p in adultos:
				if k >= 2:
					break
				if papeis.has(p.id):
					continue
				if _fixar(p.id, [_parada(ida, fim, margem + 3.0 + k * 6.0, "parado", "andar", -1, "lavar", "levar_cesto")], {"tipo": tipo, "id": id}):
					cena["participantes"].append(p.id)
					k += 1
			if k == 0:
				cenas.erase(cena)
				return
			var j := 0
			for p in _embaralhados(g.membros.map(func(i2): return m.pessoas[i2]), 966):
				if j >= 4 or p.idade(ano) < 3 or p.idade(ano) > 10:
					continue
				var pl: Array = []
				var t: float = ida + 2.0
				var q := 0
				while t < fim - 6.0:
					pl.append(_parada(t, t + 5.0, margem + 2.0 + ruido(p.id, dia, 970 + q) * 14.0, "brincar", "brincar", 0, "banho"))
					t += 7.0
					q += 1
				if _fixar(p.id, pl, {"tipo": tipo, "id": id}):
					cena["criancas"].append(p.id)
					j += 1


## Quem não está na caçada não fica parado perto do porco enquanto ela dura: o trecho parado
## (ou o lugar de uma tarefa) que cai a menos de PORCO_LIVRE px dele vai para a borda dessa
## distância, do lado em que já estava.
func _longe_do_porco(plano: Array, pid: int) -> void:
	for z in _porcos:
		if z["cacadores"].has(pid):
			continue
		for pa in plano:
			if pa["fim"] <= z["ini"] or pa["ini"] >= z["fim"] or pa["cena"].get("tipo", "") == "cacada":
				continue
			var x: float = pa["x"]
			if x > z["x0"] - PORCO_LIVRE and x < z["x1"] + PORCO_LIVRE:
				var centro: float = (z["x0"] + z["x1"]) / 2.0
				pa["x"] = clampf(z["x0"] - PORCO_LIVRE if x < centro else z["x1"] + PORCO_LIVRE,
					Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)


## x cai perto do porco de uma caçada (a menos de PORCO_LIVRE px) no minuto t, para quem não caça?
func _perto_do_porco(x: float, t: float, pid: int) -> bool:
	for z in _porcos:
		if t >= z["ini"] and t <= z["fim"] and not z["cacadores"].has(pid) and x > z["x0"] - PORCO_LIVRE and x < z["x1"] + PORCO_LIVRE:
			return true
	return false


## Na volta da caçada, até 3 crianças (de 3 a 8 anos; uma, pelo menos, fica brincando na praia)
## esperam na beira da vila, do lado de onde a caça vem, e correm atrás dos caçadores até o
## fogo. Antes das brincadeiras da tarde, que perdem o pedaço que cai nessa hora.

## O começo da tarde na vila, todos os dias (também nos de caçada, que acontece longe): três cenas
## que se encadeiam das 12h30 às 15h30 e se leem de longe.
## - `sesta` (12h30 às 13h40): 2 ou 3 adultos deitados à sombra de uma casa (`deitar`, `sesta`), e
##   uma criança que não dorme: cutuca um por um (`brincar`, `cutucar`), até que um se ergue e
##   ralha (`parado`, `ralhar`), e ela foge correndo.
## - `ensinar` (12h40 às 14h): um velho ensina uma criança de 8 a 13 anos a atirar a lança num alvo
##   de capim: ele mostra (`mirar_alvo`, `arremessar_alvo`), ela tenta, erra, vai buscar a lança
##   (`buscar_lanca`) e tenta de novo, até acertar; ele aprova (`aprovar`).
## - `artesanato` (13h50 às 15h30): 2 ou 3 adultos sentados em roda perto do fogo, fazendo cestos,
##   potes ou lanças (`tecer` ou `consertar`, com `trancar_cesto`, `moldar_pote` ou `afiar_lanca`);
##   um vai buscar material no meio, e no fim um ergue a peça pronta (`mostrar_peca`) e a leva
##   para casa.
const CENAS_DA_VILA := ["sesta", "ensinar", "artesanato"]


func _cenas_da_vila(g, c: Dictionary) -> void:
	# A sesta por último: gente para dormir sempre sobra; o mestre e a roda, nem sempre.
	if ruido(g.id, dia, 1101) < 0.6:
		_cena_ensinar(g, c)
	if ruido(g.id, dia, 1102) < 0.7:
		_cena_artesanato(g, c)
	if ruido(g.id, dia, 1100) < 0.65:
		_cena_sesta(g, c)


## Tira de todos os participantes os blocos de uma cena que não se completou.
func _desfazer_cena(cena: Dictionary, ids: Array) -> void:
	for pid in ids:
		if fixos.has(pid):
			fixos[pid] = fixos[pid].filter(func(b): return b["cena"].get("id", "") != cena["id"])
	cenas.erase(cena)


## Um x da vila para a cena: perto de `x`, dentro da faixa do povo e longe do centro do fogo.
func _na_vila(x: float, c: Dictionary) -> float:
	x = clampf(x, maxf(c["faixa"][0] + 4.0, Cotidiano.MARGEM + 4.0), c["faixa"][1] - 4.0)
	if absf(x - c["fogo"]) < FOGO_LIVRE + 2.0:
		x = c["fogo"] + (FOGO_LIVRE + 2.0) * (1.0 if x >= c["fogo"] else -1.0)
	return x


## Um trecho de chão livre para uma cena de `meia` px para cada lado: o x mais perto de `x0` (de
## 2 em 2 px, até 80 px) que fica na faixa do povo, a 14 px ou mais do fogo e sem cruzar
## nenhuma construção (`c["obras"]`), com 2 px de folga. Sem lugar, devolve `x0` na vila.
func _chao_livre(x0: float, meia: float, c: Dictionary) -> float:
	var lo: float = maxf(c["faixa"][0], Cotidiano.MARGEM + 2.0) + meia
	var hi: float = c["faixa"][1] - meia
	for i in 81:
		var x := x0 + 2.0 * ceilf(i / 2.0) * (1.0 if i % 2 == 1 else -1.0)
		if x < lo or x > hi or absf(x - c["fogo"]) < 14.0:
			continue
		var livre := true
		for ob in c["obras"]:
			if x - meia < ob[1] + 2.0 and x + meia > ob[0] - 2.0:
				livre = false
				break
		if livre:
			return x
	return _na_vila(x0, c)


## x (com `meia` px para cada lado) cruza alguma construção do povo?
func _em_obra(x: float, meia: float, c: Dictionary) -> bool:
	for ob in c["obras"]:
		if x - meia < ob[1] and x + meia > ob[0]:
			return true
	return false


func _cena_sesta(g, c: Dictionary) -> void:
	var adultos: Array = _embaralhados(_adultos(g, 18, 75), 1110).filter(func(p): return not papeis.has(p.id))
	var criancas: Array = _embaralhados(_adultos(g, 4, 9), 1111).filter(func(p): return not papeis.has(p.id))
	if adultos.size() < 2 or criancas.is_empty():
		return
	var id := "sesta:%d:%d" % [g.id, dia]
	var ini := 750.0 + ruido(g.id, dia, 1112) * 10.0
	var fim := 810.0 + ruido(g.id, dia, 1113) * 12.0   # acaba antes da roda do artesanato
	var casa: float = c["fogo"] + 20.0
	if not c["casas"].is_empty():
		casa = c["casas"][int(ruido(g.id, dia, 1114) * c["casas"].size()) % c["casas"].size()]
	# Deitados ao lado de uma casa, a 7 px da parede e a 8 px um do outro, onde houver chão: as
	# casas das pontas da vila, pelo lado de fora, primeiro (entre duas casas mal cabe um).
	var parede: float = c["largura_casa"] * 0.5 + 7.0
	var casas: Array = c["casas"].duplicate()
	casas.sort()
	var tentativas: Array = []
	if not casas.is_empty():
		var primeiro_lado: bool = ruido(g.id, dia, 1115) < 0.5
		tentativas.append([casas[-1], 1.0] if primeiro_lado else [casas[0], -1.0])
		tentativas.append([casas[0], -1.0] if primeiro_lado else [casas[-1], 1.0])
		for hx in casas:
			tentativas.append([hx, 1.0])
			tentativas.append([hx, -1.0])
	var lugares: Array = []
	for tt in tentativas:
		lugares = []
		for i in 3:
			var x: float = tt[0] + tt[1] * (parede + i * 8.0)
			if x < maxf(c["faixa"][0], Cotidiano.MARGEM + 2.0) + 3.0 or x > c["faixa"][1] - 3.0 or _em_obra(x, 3.0, c) \
					or absf(x - c["fogo"]) < FOGO_LIVRE + 2.0:
				break
			lugares.append(x)
		if lugares.size() >= 2:
			casa = tt[0]
			break
	if lugares.size() < 2:
		return   # a vila não tem chão livre ao lado de nenhuma casa: hoje não há sesta
	var cena := _registrar_cena(id, "sesta", g, null, ini, fim, [], casa, {"etapas": [], "crianca": -1})
	var info := {"tipo": "sesta", "id": id}
	var xs: Array = []
	for p in adultos:
		if xs.size() >= lugares.size():
			break
		var x: float = lugares[xs.size()]
		if _fixar(p.id, [_parada(ini + xs.size() * 2.0, fim, x, "deitar", "andar", 0, "sesta")], info):
			cena["participantes"].append(p.id)
			xs.append(x)
	if xs.size() < 2:
		_desfazer_cena(cena, cena["participantes"])
		return
	# A criança chega, cutuca um por um (3 min cada, com 3 min entre um e outro); o último se ergue
	# e ralha, e ela foge para longe da casa.
	var t0 := ini + 12.0
	var t := t0
	var pl: Array = []
	for i in xs.size():
		pl.append(_parada(t, t + 3.0, xs[i] + 3.0, "brincar", "andar", -1, "cutucar"))
		t += 6.0
	var t_ralha := t - 3.0
	var foge: float = _na_vila(casa + 40.0 * (1.0 if casa < c["fogo"] + 1.0 else -1.0), c)
	pl.append(_parada(t + 4.0, t + 14.0, foge, "brincar", "brincar", 0, "fugir"))
	var crianca = null
	for p in criancas:
		if _fixar(p.id, pl, info):
			crianca = p
			break
	if crianca == null:
		_desfazer_cena(cena, cena["participantes"])
		return
	cena["crianca"] = crianca.id
	# Quem ralha é o último cutucado: o bloco de deitar dele se parte em três.
	var quem: int = cena["participantes"][xs.size() - 1]
	var xq: float = xs[xs.size() - 1]
	fixos[quem] = fixos[quem].filter(func(b): return b["cena"].get("id", "") != id)
	_fixar(quem, [_parada(ini + (xs.size() - 1) * 2.0, t_ralha, xq, "deitar", "andar", 0, "sesta"),
		_parada(t_ralha, t_ralha + 3.0, xq, "parado", "andar", 1, "ralhar"),
		_parada(t_ralha + 3.0, fim, xq, "deitar", "andar", 0, "sesta")], info)
	cena["etapas"] = [{"etapa": "deitar", "ini": ini / 60.0, "fim": t0 / 60.0, "x": casa},
		{"etapa": "cutucar", "ini": t0 / 60.0, "fim": t_ralha / 60.0, "x": casa},
		{"etapa": "ralhar", "ini": t_ralha / 60.0, "fim": (t_ralha + 3.0) / 60.0, "x": xq, "quem": quem},
		{"etapa": "fuga", "ini": (t_ralha + 3.0) / 60.0, "fim": (t + 14.0) / 60.0, "x": foge},
		{"etapa": "sesta", "ini": (t + 14.0) / 60.0, "fim": fim / 60.0, "x": casa}]


func _cena_ensinar(g, c: Dictionary) -> void:
	var velhos: Array = _embaralhados(_adultos(g, 35, 80), 1120).filter(func(p): return not papeis.has(p.id))
	var criancas: Array = _embaralhados(_adultos(g, 8, 13), 1121).filter(func(p): return not papeis.has(p.id))
	if velhos.is_empty() or criancas.is_empty():
		return
	var id := "ensinar:%d:%d" % [g.id, dia]
	var ini := 760.0 + ruido(g.id, dia, 1122) * 20.0
	# Além da última construção do lado de terra (no máximo até a borda da faixa do povo): atiram
	# para fora, com o alvo a 26 a 30 px, contra o capim e o céu, longe das casas e da gente.
	var lado: float = 1.0 if c["longe"] >= c["fogo"] else -1.0
	var ponta: float = c["fogo"]
	for ob in c["obras"]:
		ponta = maxf(ponta, ob[1]) if lado > 0.0 else minf(ponta, ob[0])
	var xa: float = ponta + lado * 6.0
	xa = minf(xa, c["faixa"][1] - 2.0) if lado > 0.0 else maxf(xa, maxf(c["faixa"][0], Cotidiano.MARGEM) + 2.0)
	if absf(xa - c["fogo"]) < 14.0:
		xa = c["fogo"] + lado * 14.0
	var alvo := clampf(xa + lado * (26.0 + ruido(g.id, dia, 1124) * 4.0), Cotidiano.MARGEM + 4.0, Cotidiano.LARGURA_MUNDO - 6.0)
	var ida: float = ini + absf(xa - c["fogo"]) / VELOCIDADE
	var buscar: float = absf(alvo - xa) / VELOCIDADE
	# O velho mostra uma vez: mira, arremessa, busca a lança e volta.
	var pv: Array = [_parada(ida, ida + 2.0, xa, "parado", "andar", int(lado), "mirar_alvo", "levar_lanca"),
		_parada(ida + 2.0, ida + 3.0, xa, "parado", "andar", int(lado), "arremessar_alvo"),
		_parada(ida + 3.0 + buscar, ida + 4.0 + buscar, alvo, "parado", "andar", int(-lado), "buscar_lanca")]
	var etapas: Array = [{"etapa": "ida", "ini": ini / 60.0, "fim": ida / 60.0, "x": xa},
		{"etapa": "mostrar", "ini": ida / 60.0, "fim": (ida + 4.0 + 2.0 * buscar) / 60.0, "x": xa, "acerto": true}]
	var t := ida + 4.0 + 2.0 * buscar
	# O mestre a 9 px, atrás da criança: as duas figuras se leem inteiras.
	var xv: float = xa - lado * 9.0
	# A criança tenta 2 ou 3 vezes; só a última acerta. Entre uma e outra, vai buscar a lança.
	var pc: Array = []
	var tentativas := 2 + int(ruido(g.id, dia, 1123) * 2.0)
	for k in tentativas:
		var acerto: bool = k == tentativas - 1
		pc.append(_parada(t, t + 2.0, xa, "parado", "andar", int(lado), "mirar_alvo"))
		pc.append(_parada(t + 2.0, t + 3.0, xa, "parado", "andar", int(lado), "arremessar_alvo"))
		pv.append(_parada(t, t + 3.0, xv, "parado", "andar", int(lado), "mostrar"))
		etapas.append({"etapa": "tentativa", "ini": t / 60.0, "fim": (t + 3.0) / 60.0, "x": xa, "acerto": acerto})
		t += 3.0
		if not acerto:
			pc.append(_parada(t + buscar, t + buscar + 1.0, alvo, "parado", "brincar", int(-lado), "buscar_lanca"))
			pv.append(_parada(t, t + 1.0 + 2.0 * buscar, xv, "parado", "andar", int(lado), "mostrar"))
			etapas.append({"etapa": "buscar", "ini": t / 60.0, "fim": (t + 1.0 + 2.0 * buscar) / 60.0, "x": alvo})
			t += 1.0 + 2.0 * buscar
	pv.append(_parada(t, t + 4.0, xv, "parado", "andar", int(lado), "aprovar"))
	pc.append(_parada(t, t + 4.0, xa, "brincar", "andar", int(-lado), "comemorar"))
	etapas.append({"etapa": "aprovar", "ini": t / 60.0, "fim": (t + 4.0) / 60.0, "x": xa})
	var cena := _registrar_cena(id, "ensinar", g, null, ini, t + 4.0, [], xa,
		{"etapas": etapas, "alvo": alvo, "mestre": -1, "aprendiz": -1})
	var info := {"tipo": "ensinar", "id": id}
	for v in velhos:
		if _fixar(v.id, pv, info):
			cena["mestre"] = v.id
			cena["participantes"].append(v.id)
			break
	if cena["mestre"] == -1:
		cenas.erase(cena)
		return
	for p in criancas:
		if _fixar(p.id, pc, info):
			cena["aprendiz"] = p.id
			cena["participantes"].append(p.id)
			return
	_desfazer_cena(cena, cena["participantes"])


## O trabalho na roda de ini a fim, parado em x, cortado pelas conversas ([início, virado], 6 min
## cada, as que caem dentro do trecho).
func _na_roda(ini: float, fim: float, x: float, acao: String, vir: int, det: String, conversas: Array, ida_det: String) -> Array:
	var r: Array = []
	var t := ini
	for cv in conversas:
		var t0: float = cv[0]
		if t0 < t + 3.0 or t0 + 6.0 > fim - 3.0:
			continue
		r.append(_parada(t, t0, x, acao, "andar", vir, det, ida_det if r.is_empty() else ""))
		r.append(_parada(t0, t0 + 6.0, x, "conversar", "andar", cv[1]))
		t = t0 + 6.0
	r.append(_parada(t, fim, x, acao, "andar", vir, det, ida_det if r.is_empty() else ""))
	return r


## A peça do artesanato: a ação (a arte de sempre, para quem não usar o detalhe) e o detalhe.
const PECAS := {"cesto": ["tecer", "trancar_cesto"], "pote": ["consertar", "moldar_pote"], "lanca": ["consertar", "afiar_lanca"]}


func _cena_artesanato(g, c: Dictionary) -> void:
	var adultos: Array = _embaralhados(_adultos(g, 20, 80), 1130).filter(func(p): return not papeis.has(p.id))
	if adultos.size() < 2:
		return
	var opcoes: Array = ["cesto", "lanca"] + (["pote"] if g.estagio >= 2 else [])
	var peca: String = opcoes[int(ruido(g.id, dia, 1131) * opcoes.size()) % opcoes.size()]
	var id := "artesanato:%d:%d" % [g.id, dia]
	var ini := 830.0 + ruido(g.id, dia, 1132) * 15.0
	var fim := 920.0 + ruido(g.id, dia, 1133) * 15.0
	var lado: float = -1.0 if c["longe"] >= c["fogo"] else 1.0
	# O centro da roda num chão livre: sem casa nem outra construção atrás (16 px para cada lado).
	var xr := _chao_livre(c["fogo"] + lado * 18.0, 16.0, c)
	var acao: String = PECAS[peca][0]
	var det: String = PECAS[peca][1]
	var cena := _registrar_cena(id, "artesanato", g, null, ini, fim + 10.0, [], xr, {"etapas": [], "peca": peca})
	var info := {"tipo": "artesanato", "id": id}
	var k := 0
	var xs: Array = []
	# Na roda se conversa: o da esquerda e o da direita, duas vezes antes de o da direita sair
	# para buscar material, e o da esquerda com o do meio depois que ele volta (6 min cada).
	var meio := (ini + fim) * 0.5
	var conversas := {0: [[ini + 14.0, 1], [ini + 32.0, 1], [meio + 22.0, 1]], 1: [[ini + 14.0, -1], [ini + 32.0, -1]],
		2: [[meio + 22.0, -1]]}
	for p in adultos:
		if k >= 3:
			break
		# Em roda: um de cada lado do centro, olhando para ele, e o terceiro no meio, de frente.
		var dx: float = [-6.0, 6.0, 0.0][k]
		var x := _na_vila(xr + dx, c)
		var vir: int = 1 if dx < 0.0 else (-1 if dx > 0.0 else int(-lado))
		var fala: Array = conversas[k]
		var pl: Array = _na_roda(ini + k * 2.0, fim, x, acao, vir, det, fala, "levar_cesto")
		if k == 1:
			# No meio da tarde, este vai buscar material em casa e volta.
			var busca := _casa(p, c)
			var ida: float = absf(busca - x) / VELOCIDADE
			pl = _na_roda(ini + k * 2.0, meio, x, acao, vir, det, fala, "levar_cesto") + [
				_parada(meio + ida, meio + ida + 3.0, busca, "parado", "andar", 0, "guardar")] + \
				_na_roda(meio + 2.0 * ida + 3.0, fim, x, acao, vir, det, [], "carregar_cesto")
		elif k == 0:
			# No fim, este ergue a peça pronta e a leva para casa.
			var casa := _casa(p, c)
			var leva: float = absf(casa - x) / VELOCIDADE
			pl = _na_roda(ini, fim - 3.0, x, acao, vir, det, fala, "levar_cesto") + [
				_parada(fim - 3.0, fim, x, "parado", "andar", int(-lado), "mostrar_peca"),
				_parada(fim + leva, fim + leva + 3.0, casa, "parado", "andar", 0, "guardar", "levar_peca")]
		if _fixar(p.id, pl, info):
			cena["participantes"].append(p.id)
			xs.append(x)
			k += 1
	if k < 2:
		_desfazer_cena(cena, cena["participantes"])
		return
	cena["etapas"] = [{"etapa": "chegada", "ini": ini / 60.0, "fim": (ini + 6.0) / 60.0, "x": xr},
		{"etapa": "trabalho", "ini": (ini + 6.0) / 60.0, "fim": (fim - 3.0) / 60.0, "x": xr},
		{"etapa": "mostrar", "ini": (fim - 3.0) / 60.0, "fim": fim / 60.0, "x": xs[0], "quem": cena["participantes"][0]},
		{"etapa": "guardar", "ini": fim / 60.0, "fim": (fim + 10.0) / 60.0, "x": xr}]


func _criancas_atras_da_caca(g, c: Dictionary) -> void:
	for cena in cenas:
		if cena["tipo"] != "cacada" or cena["grupo"] != g.id or cena["vazia"] or not cena.has("volta_ini"):
			continue
		var ini: float = cena["volta_ini"]
		cena.erase("volta_ini")
		var lado: float = signf(cena["x"] - c["fogo"])
		var chega: float = ini + absf(cena["x"] - c["fogo"]) / VELOCIDADE
		# Onde esperam: a uns 40% do caminho, já perto das casas; os caçadores passam ali em `passa`.
		var espera: float = c["fogo"] + lado * absf(cena["x"] - c["fogo"]) * 0.4
		var passa: float = ini + absf(cena["x"] - espera) / VELOCIDADE
		# Uma criança, pelo menos, continua na brincadeira da praia.
		var pequenos: Array = _embaralhados(g.membros.map(func(id): return m.pessoas[id]).filter(
			func(p): return p.idade(ano) >= 3 and p.idade(ano) <= 8), 909)
		var quantas := mini(3, pequenos.size() - 1)
		var k := 0
		for p in pequenos:
			if k >= quantas:
				break
			var x: float = espera + lado * (k * 4.0 - 4.0)
			if _fixar(p.id, [_parada(passa - 10.0, passa, x, "brincar", "brincar", int(-lado), "brincar"),
					_parada(chega + 0.5, chega + 8.0, c["fogo"] + lado * (12.0 + k * 4.0), "brincar", "brincar", int(-lado), "brincar")],
					{"tipo": "cacada", "id": cena["id"]}):
				cena["criancas"].append(p.id)
				k += 1


## A caça chega ao fogo: alguém do povo já está lá, com o espeto, do lado de quem chega.
## Depois dos papéis do dia: o pescador, quem busca água e quem colhe longe continuam no que fazem.
## O bloco de quem cozinha não leva a cena (ele não é caçador; a cena diz quem é, em `cozinha`).
func _cozinha_da_cacada(g, c: Dictionary) -> void:
	for cena in cenas:
		if cena["tipo"] != "cacada" or cena["grupo"] != g.id or cena["vazia"] or not cena.has("chega"):
			continue
		var chega: float = cena["chega"]
		var lado: float = cena["lado"]
		cena.erase("chega")
		cena.erase("lado")
		for p in _embaralhados(_adultos(g, 14, 70), 908):
			if cena["participantes"].has(p.id) or papeis.has(p.id):
				continue
			if _fixar(p.id, [_parada(chega - 3.0, chega + REPARTIR + 2.0, c["fogo"] + lado * 7.0, "cozinhar", "andar", int(-lado), "espeto")]):
				cena["cozinha"] = p.id
				break


## Travessias: a cada hora do dia (6h às 20h), alguém atravessa a tela com uma carga grande
## (água do lago num pote na cabeça, um feixe de lenha da mata, um cesto da praia), para que
## quem olha em 1x veja sempre alguma coisa acontecendo.
func _travessias(g, c: Dictionary) -> void:
	# Quem tem papel no dia (pesca, água, longe) ou foi caçar continua no que faz.
	var gente: Array = []
	for p in _adultos(g, 10, 70):
		var cacando: bool = fixos.has(p.id) and not fixos[p.id].is_empty() and fixos[p.id][0]["cena"].get("tipo", "") == "cacada"
		if papeis.get(p.id, "") != "pescador" and not cacando:
			gente.append(p)
	if gente.is_empty():
		return
	var tipos := [["agua", c["margem"] + 3.0, "parado", "buscar_agua", "levar_pote", "carregar_agua"],
		["lenha", c["mata"], "colher", "catar_lenha", "levar_machado", "carregar_feixe"],
		["cesto", c["praia"], "colher", "colher_arbusto", "", "carregar_cesto_cabeca"],
		["longe", c["longe"] - (c["longe"] - c["fogo"]) * 0.4, "colher", "cavar_raiz", "", "carregar_cesto_cabeca"]]
	for h in range(6, 21):
		var tipo: Array = tipos[(h + int(ruido(g.id, dia, 1100) * 4.0)) % tipos.size()]
		var destino: float = tipo[1]
		var ida: float = h * 60.0 + 5.0 + ruido(g.id, dia, 1101 + h) * 15.0
		for p in _embaralhados(gente, 1120 + h):
			var casa := _casa(p, c)
			var chega: float = ida + absf(destino - casa) / VELOCIDADE
			var volta: float = chega + 8.0 + absf(destino - casa) / VELOCIDADE
			if _fixar(p.id, [_parada(ida, ida + 1.0, casa, "parado"),
					_parada(chega, chega + 8.0, destino, tipo[2], "andar", -1 if destino < casa else 1, tipo[3], tipo[4]),
					_parada(volta, volta + 2.0, casa + 4.0, "parado", "lenha", 0, "guardar", tipo[5])]):
				break


## Os papéis do dia de quem não foi caçar: um passa o dia pescando, outro busca água,
## outros colhem longe do acampamento.
func _papeis_do_dia(g) -> void:
	var livres: Array = []
	for p in _embaralhados(_adultos(g, 16, 55), 920):
		# Quem já tem compromisso de dia (caçada, uma cena) não recebe papel.
		var ocupado := false
		for bl in fixos.get(p.id, []):
			if bl["ini"] < 960.0 and bl["fim"] > 360.0:
				ocupado = true
		if not ocupado:
			livres.append(p)
	var ordem := ["pescador", "agua", "longe", "longe"]
	for k in mini(livres.size() - 1, ordem.size()):
		papeis[livres[k].id] = ordem[k]


## A noite tem sempre alguém acordado: o vigia faz a ronda (da meia-noite às 2h40, das 2h40
## às 5h, das 22h à meia-noite). Às vezes um casal fica olhando o céu, alguém reza tarde ou
## vai ao lago de madrugada; em noites sem tempestade, uma roda de histórias vai até tarde.
func _noite(g, c: Dictionary) -> void:
	var adultos := _embaralhados(_adultos(g, 16, 60), 950)
	if adultos.is_empty():
		return
	var borda: float = c["faixa"][1] - 4.0 if ruido(g.id, dia, 951) < 0.5 else c["faixa"][0] + 4.0
	borda = maxf(borda, Cotidiano.MARGEM + 2.0)
	var turnos := [[0.0, 170.0], [150.0, 300.0], [1320.0, MIN_DIA]]
	for k in turnos.size():
		var vigia = adultos[k % adultos.size()]
		var paradas: Array = []
		var t: float = turnos[k][0]
		var j := 0
		while t < turnos[k][1] - 5.0:
			var na_borda := j % 2 == 1
			var xj: float = borda if na_borda else c["fogo"] + 9.0
			var fim := minf(t + (12.0 if na_borda else 22.0), turnos[k][1])
			# No fogo, às vezes o vigia cochila; na beira, olha o escuro.
			var cochila: bool = not na_borda and turnos[k][0] < 600.0 and ruido(g.id, dia, 2000 + j + k * 40) < 0.35
			paradas.append(_parada(t, fim, xj, "parado" if na_borda else "fogueira", "andar", 0, "cochilar" if cochila else "vigia"))
			t = fim + absf(borda - c["fogo"] - 9.0) / VELOCIDADE
			j += 1
		if not paradas.is_empty():
			paradas[-1]["fim"] = turnos[k][1]   # o turno vai até o fim, até o próximo vigia chegar
		var id := "vigia:%d:%d:%d" % [g.id, dia, k]
		if not paradas.is_empty() and _fixar(vigia.id, paradas, {"tipo": "vigia", "id": id}):
			_registrar_cena(id, "vigia", g, null, turnos[k][0], turnos[k][1], [vigia.id], c["fogo"] + 9.0)
	# Um casal olhando o céu na beira do acampamento.
	if ruido(g.id, dia, 952) < 0.5:
		for p in adultos:
			if p.conjuge != -1 and m.pessoas.has(p.conjuge) and m.pessoas[p.conjuge].vivo and m.pessoas[p.conjuge].grupo == g.id:
				if _fixar(p.id, [_parada(1325.0, 1375.0, borda - 3.0, "conversar", "andar", 1, "olhar_ceu")]):
					if not _fixar(p.conjuge, [_parada(1325.0, 1375.0, borda + 3.0, "conversar", "andar", -1, "olhar_ceu")]):
						fixos[p.id].pop_back()
				break
	# Quem reza tarde.
	for p in adultos:
		if p.tem("devoto") and ruido(p.id, dia, 953) < 0.4:
			_fixar(p.id, [_parada(1380.0, 1410.0, c["altar"] + (ruido(p.id, dia, 954) - 0.5) * 6.0, "rezar", "andar", 0, "reza_noturna")])
			break
	# Alguém acorda no meio da noite, boceja, vai até o fogo e o atiça. Antes disso, o fogo
	# baixa para brasas (cena `brasas`); depois de atiçado, volta a arder por um tempo.
	var aticou: Array = []
	for k in 1 + (1 if ruido(g.id, dia, 980) < 0.5 else 0):
		var t: float = 70.0 + ruido(g.id, dia, 981 + k) * 170.0
		for p in _embaralhados(_adultos(g, 14, 70), 983 + k):
			var casa := _casa(p, c)
			var lugar := _lugar_fogo(p, c)
			var no_fogo: float = t + 4.0 + absf(lugar - casa) / VELOCIDADE
			if _fixar(p.id, [_parada(t, t + 4.0, casa, "parado", "andar", 0, "bocejar"),
					_parada(no_fogo, no_fogo + 12.0, lugar, "fogueira", "andar", _virado_ao_fogo(lugar, c), "aticar")],
					{"tipo": "acordou", "id": "acordou:%d:%d:%d" % [g.id, dia, k]}):
				aticou.append(no_fogo)
				break
	aticou.sort()
	var brasa_ini := 40.0
	for t_at in aticou:
		if t_at > brasa_ini + 10.0:
			_registrar_cena("brasas:%d:%d:%d" % [g.id, dia, int(brasa_ini)], "brasas", g, null, brasa_ini, t_at, [], c["fogo"])
		brasa_ini = t_at + 50.0
	if brasa_ini < 290.0:
		_registrar_cena("brasas:%d:%d:%d" % [g.id, dia, int(brasa_ini)], "brasas", g, null, brasa_ini, 300.0, [], c["fogo"])
	# A coruja fica a noite toda na árvore da mata mais perto da vila (das 21h às 5h).
	var arvore: float = clampf(c["fogo"], Cotidiano.FAIXAS["floresta"][0] + 6.0, Cotidiano.FAIXAS["floresta"][1] - 6.0)
	for janela in [[0.0, 300.0], [1260.0, MIN_DIA]]:
		_registrar_cena("coruja:%d:%d:%d" % [g.id, dia, int(janela[0])], "bicho_noturno", g, null, janela[0], janela[1],
			[], arvore, {"bicho": "coruja", "fixo": true})
	# Os outros passam a cada 15 a 30 min: a raposa trotando pela beira do acampamento, o
	# morcego sobre o lago, o sapo na margem. `x_fim` é onde o bicho termina a passagem.
	var bichos := [["raposa", borda, borda + (30.0 if borda < c["fogo"] else -30.0)],
		["morcego", c["margem"] + 4.0, c["margem"] + 24.0], ["sapo", c["margem"] + 4.0, c["margem"] + 8.0]]
	var k := 0
	for janela in [[0.0, 300.0], [1260.0, MIN_DIA]]:
		var t: float = janela[0] + 5.0 + ruido(g.id, dia, 986) * 15.0
		while t < janela[1] - 8.0:
			var b: Array = bichos[int(ruido(g.id, dia, 2100 + k) * bichos.size()) % bichos.size()]
			var dur: float = 6.0 + ruido(g.id, dia, 2200 + k) * 4.0
			_registrar_cena("bicho_noturno:%d:%d:%d" % [g.id, dia, k], "bicho_noturno", g, null, t, minf(t + dur, janela[1]),
				[], b[1], {"bicho": b[0], "fixo": false, "x_fim": b[2]})
			t += 15.0 + ruido(g.id, dia, 2300 + k) * 15.0
			k += 1
	# Alguém vai ao lago de madrugada.
	if ruido(g.id, dia, 955) < 0.5:
		var p = adultos[(3 + int(ruido(g.id, dia, 956) * 5.0)) % adultos.size()]
		var de_volta: float = 268.0 + absf(_casa(p, c) - c["margem"]) / VELOCIDADE
		_fixar(p.id, [_parada(255.0, 268.0, c["margem"] + 3.0, "parado", "andar", -1, "buscar_agua"),
			_parada(de_volta, maxf(de_volta + 5.0, 300.0), _casa(p, c) + 4.0, "parado", "lenha", 0, "guardar", "carregar_agua")])
	# A roda de histórias, em noite sem tempestade na zona (pelos eventos do dia, e não pelo
	# tempo de agora: a rotina sai igual em qualquer hora em que for montada).
	var tempestade_hoje := false
	for e in m.eventos_recentes(dia - 1):
		if e.tipo == "tempestade" and e.zona == g.zona and _dia_do_evento(e) >= dia - 1:
			tempestade_hoje = true
	if ruido(g.id, dia, 957) < 0.3 and not tempestade_hoje:
		var roda: Array = []
		for p in _embaralhados(_adultos(g, 12, 90), 958):
			if roda.size() >= 6:
				break
			if c["descanso"].has(p.id):
				var x: float = c["descanso"][p.id]
				if _fixar(p.id, [_parada(1275.0, 1380.0, x, "conversar", "andar", _virado_ao_fogo(x, c), "historias")]):
					roda.append(p.id)
		if not roda.is_empty():
			_registrar_cena("historias:%d:%d" % [g.id, dia], "historias", g, null, 1275.0, 1380.0, roda, c["fogo"])


## Pequenos incidentes do dia, 2 ou 3 por povo: cenas curtas, visíveis, que não entram na
## crônica.
func _incidentes(g, c: Dictionary) -> void:
	var n := 2 + (1 if ruido(g.id, dia, 960) < 0.4 else 0)
	var adultos: Array = []
	for p in _adultos(g, 14, 70):
		var cacando: bool = fixos.has(p.id) and not fixos[p.id].is_empty() and fixos[p.id][0]["cena"].get("tipo", "") == "cacada"
		if not papeis.has(p.id) and not cacando:
			adultos.append(p)
	var criancas: Array = []
	for id in g.membros:
		var idade: int = m.pessoas[id].idade(ano)
		if idade >= 4 and idade <= 11:
			criancas.append(m.pessoas[id])
	for k in n:
		var tipo: String = INCIDENTES[int(ruido(g.id, dia, 961 + k) * INCIDENTES.size()) % INCIDENTES.size()]
		var t: float = 560.0 + ruido(g.id, dia, 970 + k) * 420.0
		var ad := _embaralhados(adultos, 980 + k)
		var cr := _embaralhados(criancas, 990 + k)
		var id := "%s:%d:%d:%d" % [tipo, g.id, dia, k]
		var info := {"tipo": tipo, "id": id}
		var x: float = c["fogo"] + (ruido(g.id, dia, 1000 + k) - 0.5) * 60.0
		var quem: Array = []
		match tipo:
			"briga_criancas":
				if cr.size() < 2 or ad.is_empty():
					continue
				if _fixar(cr[0].id, [_parada(t, t + 10.0, x - 3.0, "parado", "andar", 1, "brigar")], info) \
						and _fixar(cr[1].id, [_parada(t, t + 10.0, x + 3.0, "parado", "andar", -1, "brigar")], info):
					quem = [cr[0].id, cr[1].id]
					if _fixar(ad[0].id, [_parada(t + 3.0, t + 12.0, x, "conversar", "andar", 0, "separar")], info):
						quem.append(ad[0].id)
			"tombo":
				if ad.size() < 2:
					continue
				if _fixar(ad[0].id, [_parada(t, t + 18.0, x, "parado", "andar", 0, "machucado")], info):
					quem = [ad[0].id]
					if _fixar(ad[1].id, [_parada(t + 3.0, t + 18.0, x + 4.0, "cuidar", "andar", -1)], info):
						quem.append(ad[1].id)
			"animal":
				if ad.size() < 2:
					continue
				var lado: float = 1.0 if ruido(g.id, dia, 1010 + k) < 0.5 else -1.0
				x = clampf(c["fogo"] + lado * 45.0, Cotidiano.MARGEM + 6.0, Cotidiano.LARGURA_MUNDO - 8.0)
				for j in 2:
					if _fixar(ad[j].id, [_parada(t + j * 2.0, t + 12.0, x - lado * (4.0 + 5.0 * j), "parado", "andar", int(lado), "espantar")], info):
						quem.append(ad[j].id)
			"perdido":
				if cr.is_empty() or ad.is_empty():
					continue
				t = 560.0 + ruido(g.id, dia, 970 + k) * 240.0   # cedo: a criança volta antes do fim da tarde
				x = c["longe"] + (ruido(g.id, dia, 1020 + k) - 0.5) * 40.0
				var volta: float = t + 50.0 + absf(x - c["fogo"]) / VELOCIDADE
				if _fixar(cr[0].id, [_parada(t, t + 50.0, x, "parado", "andar", 0, "perdido"),
						_parada(volta, volta + 5.0, c["fogo"] + 5.0, "parado")], info):
					quem = [cr[0].id]
					if _fixar(ad[0].id, [_parada(t + 25.0, t + 50.0, x + 3.0, "parado", "andar", -1, "buscar"),
							_parada(volta, volta + 5.0, c["fogo"] + 9.0, "parado")], info):
						quem.append(ad[0].id)
			"discussao":
				var bravos: Array = []
				for p in ad:
					if p.tem("rancoroso") or p.tem("ambicioso"):
						bravos.append(p)
				for p in ad:
					if bravos.size() < 2 and not bravos.has(p):
						bravos.append(p)
				if bravos.size() < 2:
					continue
				if _fixar(bravos[0].id, [_parada(t, t + 15.0, x - 4.0, "conversar", "andar", 1, "discutir")], info):
					if _fixar(bravos[1].id, [_parada(t, t + 15.0, x + 4.0, "conversar", "andar", -1, "discutir")], info):
						quem = [bravos[0].id, bravos[1].id]
					else:
						fixos[bravos[0].id].pop_back()
		if not quem.is_empty():
			_registrar_cena(id, tipo, g, null, t, t + 20.0, quem, x)


func _cumprir_bloco(plano: Array, bloco: Dictionary, t: float, x: float) -> float:
	for pa in bloco["paradas"]:
		var chega: float = t + absf(pa["x"] - x) / VELOCIDADE
		var nova: Dictionary = pa.duplicate()
		nova["ini"] = maxf(pa["ini"], chega)
		nova["fim"] = maxf(pa["fim"], nova["ini"] + 1.0)
		plano.append(nova)
		t = nova["fim"]
		x = pa["x"]
	return t


# ---------------------------------------------------------------- posição

## A linha do tempo de cada pessoa: o plano virado em trechos contínuos de 0 a 1440 min,
## [t0, t1, x0, x1, acao, virado, cena]. Montada uma vez por dia; as consultas só buscam nela.
var linhas: Dictionary = {}      # id -> Array de trechos
var _inicios: Dictionary = {}    # id -> PackedFloat64Array com os t0, para a busca binária
var _agendas: Dictionary = {}    # id -> as 24 agendas do dia (null: hora ainda não cortada, ou já solta)
var _soltas_ate: int = 0         # as agendas das horas antes desta já foram soltas
## Até que hora a thread já corta as agendas (as outras são cortadas quando pedidas). A rotina
## de amanhã montada às 23h só serve até ser refeita, na 1h: ela corta só as primeiras horas.
var cortar_ate: int = 24
var guardar_planos := false      # para as ferramentas: não solta os planos depois de montar
var cortar_desde: int = 0        # a rotina de hoje montada no meio do dia não corta as horas que já passaram


func _linha(pid: int) -> Array:
	var segs: Array = []
	var plano: Array = planos[pid]
	var prev: Dictionary = plano[0]
	_trecho(segs, 0.0, prev["fim"], prev["x"], prev["x"], prev["acao"], prev["virado"], prev["cena"], prev.get("detalhe", ""))
	for i in range(1, plano.size()):
		var pa: Dictionary = plano[i]
		var t: float = segs[-1][1] if not segs.is_empty() else 0.0
		var anda: float = absf(pa["x"] - prev["x"]) / VELOCIDADE
		if anda > 0.001:
			_trecho(segs, t, t + anda, prev["x"], pa["x"], pa["ida"], 1 if pa["x"] > prev["x"] else -1, pa["cena"], pa.get("ida_det", ""))
			t += anda
		if pa["ini"] > t + 0.001:
			# Esperando a hora marcada: quem está brincando continua brincando. Uma espera
			# longa de dia muda de lugar a cada 15 a 20 min (veja PARADO_MAX).
			var espera: String = "brincar" if pa["acao"] == "brincar" else "parado"
			var de_dia: bool = t >= 360.0 and t < 1020.0 and pa["cena"].is_empty()
			if espera == "parado" and pa["ini"] - t > PARADO_MAX and de_dia:
				_esperar_mexendo(segs, t, pa["ini"], pa["x"], pa["virado"], pid)
			elif espera == "parado" and de_dia and pa["fim"] - t > PARADO_MAX and pa["ini"] - t > 5.0 and MEXIVEIS.has(pa["acao"]):
				# A espera mais o bloco passariam do limite no mesmo ponto: espera ao lado.
				var lado: float = 8.0 if ruido(pid, dia, 4400 + int(t)) < 0.5 else -8.0
				var p = m.pessoas.get(pid)
				if p != null and ctx.has(p.grupo) and absf(pa["x"] + lado - ctx[p.grupo]["fogo"]) < FOGO_LIVRE + 1.0:
					lado = -lado
				var xo: float = clampf(pa["x"] + lado, Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)
				var anda2: float = absf(xo - pa["x"]) / VELOCIDADE
				_trecho(segs, t, t + anda2, pa["x"], xo, "andar", 1 if xo > pa["x"] else -1, {}, "")
				_trecho(segs, t + anda2, pa["ini"] - anda2, xo, xo, "parado", pa["virado"], {}, "")
				_trecho(segs, pa["ini"] - anda2, pa["ini"], xo, pa["x"], "andar", 1 if pa["x"] > xo else -1, {}, "")
			else:
				_trecho(segs, t, pa["ini"], pa["x"], pa["x"], espera, pa["virado"], pa["cena"], pa["detalhe"] if espera != "parado" else "")
			t = pa["ini"]
		_trecho(segs, t, maxf(pa["fim"], t + 0.5), pa["x"], pa["x"], pa["acao"], pa["virado"], pa["cena"], pa.get("detalhe", ""))
		prev = pa
	if segs[-1][1] < MIN_DIA:
		var u: Array = segs[-1]
		_trecho(segs, u[1], MIN_DIA, u[3], u[3], u[4], u[5], u[6], u[7])
	segs = _sem_parar_na_linha(segs, pid)
	var ini := PackedFloat64Array()
	for sg in segs:
		ini.append(sg[0])
	linhas[pid] = segs
	_inicios[pid] = ini
	return segs


## A rede de segurança de PARADO_MAX, na linha pronta: de dia, quando o tempo no mesmo ponto
## (de pé, deitado, sentado no fogo ou conversando, fora das cenas) chega a PARADO_MAX, a pessoa
## dá uns passos para o lado (8 px) e continua dali; o que vinha depois segue do novo ponto.
func _sem_parar_na_linha(segs: Array, pid: int) -> Array:
	var p = m.pessoas.get(pid)
	var fogo: float = ctx[p.grupo]["fogo"] if p != null and ctx.has(p.grupo) else -1000.0
	var r: Array = []
	var x_original := -9999.0    # o ponto parado de antes do passo para o lado
	var x_agora := -9999.0       # onde a pessoa está de fato
	var desde := 0.0
	var k := 0
	for sg0 in segs:
		var sg: Array = sg0.duplicate()
		var parado: bool = sg[2] == sg[3] and MEXIVEIS.has(sg[4]) and sg[6].is_empty() and sg[0] >= 360.0 and sg[0] < 1020.0
		# Continuidade: quem deu o passo para o lado segue de onde está.
		if not r.is_empty() and absf(r[-1][3] - sg[2]) > 0.01 and absf(sg[2] - x_original) < 0.01:
			if sg[2] == sg[3]:
				sg[3] = r[-1][3]
			sg[2] = r[-1][3]
		if not parado:
			x_original = -9999.0
			x_agora = -9999.0
			r.append(sg)
			continue
		if absf(sg[2] - x_agora) > 0.01 or r.is_empty() or absf(r[-1][1] - sg[0]) > 0.01:
			if absf(sg0[2] - x_original) > 0.01:
				x_original = sg0[2]
			x_agora = sg[2]
			desde = sg[0]
		while sg[1] - desde > PARADO_MAX and sg[1] - sg[0] > 2.0:
			var corte: float = maxf(sg[0], desde + PARADO_MAX - 2.0)
			if corte > sg[0] + 0.01:
				var antes: Array = sg.duplicate()
				antes[1] = corte
				r.append(antes)
			# Um passo para o lado e, no seguinte, de volta ao ponto de antes: não vai se afastando.
			var d: float = 8.0 if ruido(pid, dia, 4500 + k) < 0.5 else -8.0
			var novo: float = x_original if absf(x_agora - x_original) > 0.01 else x_agora + d
			if absf(novo - fogo) < FOGO_LIVRE + 1.0 or novo < Cotidiano.MARGEM + 2.0 or novo > Cotidiano.LARGURA_MUNDO - 3.0 					or _perto_do_porco(novo, corte, pid):
				novo = x_agora - d
			novo = clampf(novo, Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)
			var anda: float = absf(novo - x_agora) / VELOCIDADE
			r.append([corte, corte + anda, x_agora, novo, "andar", 1 if novo > x_agora else -1, {}, ""])
			sg[0] = corte + anda
			sg[2] = novo
			sg[3] = novo
			x_agora = novo
			desde = sg[0]
			k += 1
		if sg[1] > sg[0] + 0.001:
			r.append(sg)
	return r


## Uma espera longa, de t até ate, perto de x: parado uns 15 a 20 min, uns passos para o lado,
## parado de novo, e de volta a x antes da hora.
func _esperar_mexendo(segs: Array, t: float, ate: float, x: float, virado: int, pid: int) -> void:
	var k := 0
	var aqui := x
	while t < ate - 0.01:
		var fim: float = minf(ate, t + 15.0 + ruido(pid, dia, 4100 + k + int(t)) * 5.0)
		var volta: float = absf(aqui - x) / VELOCIDADE
		if ate - fim < 5.0 + volta:
			fim = ate - volta if ate - volta - t <= PARADO_MAX else t + (ate - volta - t) * 0.5
		if fim > t + 0.01:
			_trecho(segs, t, fim, aqui, aqui, "parado", virado, {}, "")
			t = fim
		if t >= ate - volta - 0.01:
			break
		var d: float = (6.0 + ruido(pid, dia, 4200 + k) * 4.0) * (1.0 if ruido(pid, dia, 4300 + k) < 0.5 else -1.0)
		var novo: float = x if absf(aqui - x) > 0.01 else maxf(Cotidiano.MARGEM + 2.0, x + d)
		var p = m.pessoas.get(pid)
		if p != null and ctx.has(p.grupo) and absf(novo - ctx[p.grupo]["fogo"]) < FOGO_LIVRE:
			novo = x - d
		novo = clampf(novo, Cotidiano.MARGEM + 2.0, Cotidiano.LARGURA_MUNDO - 3.0)
		var anda: float = absf(novo - aqui) / VELOCIDADE
		_trecho(segs, t, t + anda, aqui, novo, "andar", 1 if novo > aqui else -1, {}, "")
		t += anda
		aqui = novo
		k += 1
	if absf(aqui - x) > 0.01:
		var anda2: float = absf(x - aqui) / VELOCIDADE
		_trecho(segs, t, t + anda2, aqui, x, "andar", 1 if x > aqui else -1, {}, "")
		t += anda2
	if t < ate - 0.001:
		_trecho(segs, t, ate, x, x, "parado", virado, {}, "")


## As agendas das 24 horas, numa passada só pela linha do tempo; com tempestade, as horas
## dali em diante são cortadas de novo, com o abrigo por cima.
func _cortar_dia(pid: int) -> void:
	var segs: Array = linhas[pid]
	var horas: Array = []
	horas.resize(24)
	for h in range(cortar_desde, cortar_ate):
		horas[h] = []
	for sg in segs:
		var h0 := maxi(cortar_desde, int(sg[0] / 60.0))
		var h1 := mini(cortar_ate - 1, int((sg[1] - 0.0001) / 60.0))
		for h in range(h0, h1 + 1):
			_pedaco(horas[h], sg, h * 60.0, h * 60.0 + 60.0)
	_agendas[pid] = horas
	var abrigo := _abrigo(pid)
	if abrigo >= 0.0:
		for h in range(maxi(cortar_desde, int(abrigo / 60.0)), cortar_ate):
			horas[h] = _cortar_hora(pid, h)


## A tempestade que cai na zona manda todos para casa da hora em que começa até o fim do
## dia. Guardada na rotina: vale pelo resto do dia mesmo depois que a chuva passa.
func ver_tempestade() -> void:
	var t: Dictionary = m.tempestade
	if t.is_empty() or abrigos.has(t["zona"]):
		return
	abrigos[t["zona"]] = t["inicio"] * 60.0
	# As horas já cortadas dali em diante, nessa zona, ficam velhas.
	for pid in _agendas:
		var p = m.pessoas.get(pid)
		var g = m.grupo(p.grupo) if p != null else null
		if g != null and g.zona == t["zona"]:
			var horas: Array = _agendas[pid]
			for h in range(t["inicio"], 24):
				horas[h] = null


## Minuto em que a pessoa vai se abrigar da tempestade, ou -1.
func _abrigo(pid: int) -> float:
	if abrigos.is_empty() or linhas[pid].size() <= 1:
		return -1.0
	var p = m.pessoas.get(pid)
	var g = m.grupo(p.grupo) if p != null else null
	return abrigos.get(g.zona, -1.0) if g != null else -1.0


## De onde a pessoa está no minuto do abrigo até a casa dela, e lá até o fim do dia.
func _trechos_do_abrigo(pid: int, abrigo: float) -> Array:
	var segs: Array = linhas[pid]
	var sg: Array = segs[_indice(pid, abrigo)]
	var x: float = lerpf(sg[2], sg[3], clampf((abrigo - sg[0]) / maxf(0.001, sg[1] - sg[0]), 0.0, 1.0))
	var casa := casa_de(pid)
	var anda := absf(casa - x) / VELOCIDADE
	var r: Array = []
	_trecho(r, abrigo, abrigo + anda, x, casa, "andar", 1 if casa > x else -1, {})
	_trecho(r, abrigo + anda, MIN_DIA, casa, casa, "parado", 0, {})
	return r


## A agenda de uma hora: os trechos da linha do tempo que caem nela, com a tempestade por cima.
func _cortar_hora(pid: int, h: int) -> Array:
	var segs: Array = linhas[pid]
	var ini := h * 60.0
	var fim := ini + 60.0
	var lista: Array = []
	var abrigo := _abrigo(pid)
	var ate := fim if abrigo < 0.0 else clampf(abrigo, ini, fim)
	if ate > ini:
		var inicios: PackedFloat64Array = _inicios[pid]
		var i := maxi(0, inicios.bsearch(ini, false) - 1)
		while i < segs.size() and segs[i][0] < ate:
			_pedaco(lista, segs[i], ini, ate)
			i += 1
	if ate < fim:
		for sg in _trechos_do_abrigo(pid, abrigo):
			_pedaco(lista, sg, ini, fim)
	return lista


## A parte do trecho `sg` entre `ini` (o começo da hora) e `ate`, juntada à anterior se for
## a mesma ação parada no mesmo lugar.
func _pedaco(lista: Array, sg: Array, ini: float, ate: float) -> void:
	var a: float = maxf(sg[0], ini)
	var b: float = minf(sg[1], ate)
	if b - a <= 0.001:
		return
	var x0: float = sg[2]
	var x1: float = sg[3]
	var xa := x0
	var xb := x1
	if x0 != x1:
		var dur: float = maxf(0.001, sg[1] - sg[0])
		xa = lerpf(x0, x1, (a - sg[0]) / dur)
		xb = lerpf(x0, x1, (b - sg[0]) / dur)
	if not lista.is_empty():
		var u: Dictionary = lista[-1]
		if xa == xb and u["acao"] == sg[4] and u["detalhe"] == sg[7] and u["x0"] == u["x1"] and u["x1"] == xa:
			u["ate"] = (b - ini) / 60.0
			return
	lista.append({"de": (a - ini) / 60.0, "ate": (b - ini) / 60.0, "x0": xa, "x1": xb, "acao": sg[4],
		"virado": sg[5], "cena": sg[6], "detalhe": sg[7]})


func _trecho(segs: Array, t0: float, t1: float, x0: float, x1: float, acao: String, virado: int, cena: Dictionary,
		detalhe: String = "") -> void:
	if t1 - t0 < 0.001:
		return
	if acao != "remar":
		# Ninguém fica na água, a não ser remando.
		x0 = maxf(x0, Cotidiano.MARGEM)
		x1 = maxf(x1, Cotidiano.MARGEM)
	x0 = minf(x0, Cotidiano.LARGURA_MUNDO - 2.0)
	x1 = minf(x1, Cotidiano.LARGURA_MUNDO - 2.0)
	segs.append([t0, t1, x0, x1, acao, virado, cena, detalhe])


func _indice(pid: int, minuto: float) -> int:
	var ini: PackedFloat64Array = _inicios[pid]
	return maxi(0, ini.bsearch(minuto, false) - 1)


## Onde a pessoa está, o que faz e para que lado olha no minuto dado do dia.
func instante(pid: int, minuto: float) -> Dictionary:
	if not linhas.has(pid):
		var ag: Array = agenda(pid, int(minuto / 60.0))
		return {"x": ag[0]["x0"], "acao": ag[0]["acao"], "virado": 0, "cena": {}, "detalhe": ""}
	var segs: Array = linhas[pid]
	var sg: Array = segs[_indice(pid, minuto)]
	var abrigo := _abrigo(pid)
	if abrigo >= 0.0 and minuto >= abrigo:
		for s2 in _trechos_do_abrigo(pid, abrigo):
			sg = s2
			if minuto < s2[1]:
				break
	var f := clampf((minuto - sg[0]) / maxf(0.001, sg[1] - sg[0]), 0.0, 1.0)
	return {"x": lerpf(sg[2], sg[3], f), "acao": sg[4], "virado": sg[5], "cena": sg[6], "detalhe": sg[7]}


## Os trechos de uma hora: [{de, ate, x0, x1, acao, virado, cena}], com de e ate de 0 a 1.
## Trechos com x0 == x1 são ações paradas; com x0 != x1, a pessoa anda. Cada hora é cortada
## uma vez por dia: a lista devolvida é a guardada.
## Quem ainda não tem plano (a rotina está sendo montada) fica em casa: dormindo de noite,
## parado de dia. Isso é uma reserva, que não deve aparecer com o jogo andando normalmente.
func agenda(pid: int, hora: int) -> Array:
	var h := clampi(hora, 0, 23)
	var horas = _agendas.get(pid)
	if horas == null:
		faltou = true
		var casa := casa_de(pid) if m.pessoas.has(pid) else 0.0
		var acordado := h >= 5 and h < 22
		if acordado:
			m.desempenho["substitutos"] += 1
		return [{"de": 0.0, "ate": 1.0, "x0": casa, "x1": casa, "acao": "parado" if acordado else "dormir",
			"virado": 0, "cena": {}, "detalhe": ""}]
	var ag = horas[h]
	if ag == null:
		ag = _cortar_hora(pid, h)
		horas[h] = ag
	return ag


## As cenas que acontecem em algum momento da hora dada.
func cenas_na_hora(hora: int) -> Array:
	var r: Array = []
	for c in cenas:
		if c["ini"] < (hora + 1) * 60.0 and c["fim"] > hora * 60.0:
			r.append(c)
	return r

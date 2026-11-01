extends RefCounted
## A rotina visível de um dia inteiro: o plano de cada pessoa, as cenas dos eventos
## e a posição de todo mundo em qualquer minuto. É uma consulta pura: tudo sai do
## estado do mundo e de `ruido(id, dia, k)`, sem tocar no sorteio da simulação. A mesma
## pessoa no mesmo dia faz sempre a mesma coisa; dois dias nunca são iguais.
##
## O plano é uma lista de paradas {ini, fim, x, acao, ida, virado, cena}, em minutos
## do dia (0 a 1440). Entre uma parada e outra a pessoa anda a VELOCIDADE px por minuto
## de jogo, com a ação `ida` (andar, lenha...). Blocos fixos (cenas, conversas, crianças
## correndo, reza) têm horário marcado; as tarefas do dia preenchem o resto.
##
## `montar` faz tudo de uma vez: lugares de cada povo, cenas, vida social, o plano de cada
## pessoa e as agendas das 24 horas. O mundo a monta numa thread de trabalho, só lendo o
## estado; enquanto isso, nada no mundo muda (veja mundo._esperar_rotina).

const Cotidiano = preload("cotidiano.gd")

const VELOCIDADE := 5.0          # px por minuto de jogo andando
const MIN_DIA := 1440.0
const ACOES := ["dormir", "andar", "parado", "colher", "rezar", "fogueira", "pescar", "lenha",
	"construir", "forjar", "escrever", "remar", "lutar", "carregar_morto", "dancar", "cuidar", "conversar"]
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
var _grupos: Array = []


static func ruido(a: int, b: int, c: int) -> float:
	return Cotidiano.ruido(a, b, c)


## Uma rotina vazia do dia `p_dia`; `montar` a preenche.
func _init(mundo, p_dia: int) -> void:
	_wm = weakref(mundo)
	dia = p_dia
	ano = p_dia / mundo.DIAS_ANO + 1
	_grupos = mundo.grupos_vivos()


## Monta a rotina inteira. Só lê o mundo: pode rodar numa thread.
func montar() -> void:
	for g in _grupos:
		ctx[g.id] = _contexto(g)
	_montar_cenas()
	for g in _grupos:
		_vida_social(g)
	var t: Dictionary = m.tempestade
	if not t.is_empty():
		abrigos[t["zona"]] = t["inicio"] * 60.0
	for g in _grupos:
		for pid in g.membros:
			planos[pid] = _plano(m.pessoas[pid], g)
			_linha(pid)
			_cortar_dia(pid)
	_grupos = []


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


## Uma hora inteira dormindo em casa: a madrugada antes de a rotina do dia entrar. É a
## última hora do dia da rotina, quando todos já dormiram.
func dormindo(pid: int) -> Array:
	if not _sono.has(pid):
		var x := 0.0
		if _agendas.has(pid):
			var u: Array = agenda(pid, 23)
			if u.size() == 1 and u[0]["acao"] == "dormir":
				_sono[pid] = u
				return u
			x = u[-1]["x1"]
		elif m.pessoas.has(pid):
			x = casa_de(pid)
		_sono[pid] = [{"de": 0.0, "ate": 1.0, "x0": x, "x1": x, "acao": "dormir", "virado": 0, "cena": {}}]
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
	var c := {"casas": [], "rocas": [], "fogo": 0.0, "altar": -1.0, "templo": -1.0, "forja": -1.0,
		"arquivo": -1.0, "celeiro": -1.0, "moinho": -1.0, "barco": -1.0}
	for o in Cotidiano.construcoes_do_grupo(m, g):
		match o["tipo"]:
			"fogueira":
				c["fogo"] = o["x"]
			"cabana":
				c["casas"].append(o["x"])
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
	return c


func _casa(p, c: Dictionary) -> float:
	if c["casas"].is_empty():
		return c["fogo"] - 6.0
	return c["casas"][p.id % c["casas"].size()] + (ruido(p.id, 0, 7) - 0.5) * 8.0


func _lugar_fogo(p, c: Dictionary) -> float:
	return c["fogo"] + (ruido(p.id, 0, 1) - 0.5) * 24.0


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
	fixos[pid].append({"ini": ini, "fim": fim, "paradas": paradas, "cena": cena})
	return true


func _parada(ini: float, fim: float, x: float, acao: String, ida: String = "andar", virado: int = 0) -> Dictionary:
	return {"ini": ini, "fim": fim, "x": x, "acao": acao, "ida": ida, "virado": virado, "cena": {}}


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
	var cena := _registrar_cena(id, "guerra", a, e, 450.0, 720.0, [], bx, {"outro_grupo": b.id, "x_combate": bx,
		"mortos": e.dados["mortos"].size()})
	var info := {"tipo": "guerra", "id": id}
	var lados := [[_embaralhados(_adultos(a, 16, 50), 31).slice(0, 8), -dir, ca, 450.0],
		[_embaralhados(_adultos(b, 16, 50), 32).slice(0, 8), dir, cb, 520.0]]
	for lado in lados:
		var i := 0
		for p in lado[0]:
			var linha: float = bx + lado[1] * (5.0 + 4.0 * i)
			var casa := _casa(p, lado[2])
			var ok := _fixar(p.id, [
				_parada(lado[3] + i * 2.0, 540.0, linha, "parado"),
				_parada(540.0, 630.0, linha, "lutar", "andar", int(-lado[1])),
				_parada(690.0, 700.0, casa, "parado")], info)
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
	# Pares que conversam no almoço e à noite, em volta do fogo.
	for janela in [[720.0, 750.0, 100], [1150.0, 1190.0, 101]]:
		var adultos := _embaralhados(_adultos(g, 14, 80), janela[2])
		var n := int(adultos.size() * 0.5) / 2 * 2
		for i in range(0, n, 2):
			var a = adultos[i]
			var b = adultos[i + 1]
			var x := _lugar_fogo(a, c) + (ruido(a.id, dia, janela[2]) - 0.5) * 20.0
			var info := {}
			if _fixar(a.id, [_parada(janela[0], janela[1], x - 4.0, "conversar", "andar", 1)]):
				if not _fixar(b.id, [_parada(janela[0], janela[1], x + 4.0, "conversar", "andar", -1)]):
					fixos[a.id].pop_back()
	# Crianças correm umas atrás das outras perto do fogo.
	var criancas: Array = []
	for id in g.membros:
		var i: int = m.pessoas[id].idade(ano)
		if i >= 3 and i <= 11:
			criancas.append(m.pessoas[id])
	criancas = _embaralhados(criancas, 110)
	for i in range(0, criancas.size() - 1, 2):
		var lider = criancas[i]
		var seguidor = criancas[i + 1]
		for janela in [[540.0, 640.0], [900.0, 990.0]]:
			var pl: Array = []
			var ps: Array = []
			var t: float = janela[0]
			var k := 0
			while t < janela[1]:
				var x: float = c["fogo"] + (ruido(lider.id, dia, 200 + k) - 0.5) * 60.0
				pl.append(_parada(t, t + 2.0, x, "parado"))
				ps.append(_parada(t + 3.0, t + 4.0, x - 5.0, "parado"))
				t += 9.0
				k += 1
			if _fixar(lider.id, pl):
				if not _fixar(seguidor.id, ps):
					fixos[lider.id].pop_back()
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
	if idade < 12:
		# Crianças mais velhas às vezes acompanham a lida perto de casa.
		for i in 12:
			r.append({"x": c["fogo"] + (_sorte() - 0.5) * 50.0, "acao": "parado" if _sorte() < 0.5 else "colher", "dur": 20.0 + _sorte() * 30.0})
		return r
	if idade > 60:
		# Os velhos ficam perto do fogo, dão voltas curtas e conversam.
		for i in 8:
			r.append({"x": _lugar_fogo(p, c), "acao": "fogueira", "dur": 40.0 + _sorte() * 50.0})
			if _sorte() < 0.5:
				r.append({"x": c["fogo"] + (_sorte() - 0.5) * 50.0, "acao": "conversar" if _sorte() < 0.5 else "parado", "dur": 10.0 + _sorte() * 15.0})
		return r
	var menu: Array = []    # [peso, construtor]

	# Coletar num percurso de arbustos.
	menu.append([3.0 if g.estagio <= 2 else 1.0, "coletar"])
	if g.zona == "lago" or g.zona == "praia" or _sorte() < 0.15:
		menu.append([2.5, "pescar"])
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
				r.append({"x": clampf(c["fogo"] + (_sorte() - 0.5) * 90.0, trab[0] + 3.0, trab[1] - 3.0), "acao": "colher", "dur": 20.0 + _sorte() * 25.0})
		"pescar":
			r.append({"x": c["margem"] + _sorte() * 6.0, "acao": "pescar", "dur": 60.0 + _sorte() * 70.0, "virado": -1})
		"lenha":
			r.append({"x": c["mata"] + (_sorte() - 0.5) * 30.0, "acao": "colher", "dur": 20.0 + _sorte() * 20.0})
			r.append({"x": _casa(p, c) + 5.0, "acao": "parado", "dur": 6.0, "ida": "lenha"})
		"roca":
			var roca: float = c["rocas"][int(_sorte() * c["rocas"].size())]
			for j in 2:
				r.append({"x": roca + (_sorte() - 0.5) * 14.0, "acao": "colher", "dur": 35.0 + _sorte() * 30.0})
			if c["celeiro"] >= 0.0:
				r.append({"x": c["celeiro"], "acao": "parado", "dur": 6.0, "ida": "lenha"})
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
		r.append({"x": -1.0, "acao": "parado", "dur": 5.0 + _sorte() * 10.0})   # pausa onde estiver
	return true


## Monta o plano do dia: dorme, acorda, cumpre os blocos fixos na hora certa e
## preenche o resto com as tarefas; à noite, fogo; depois, casa.
func _plano(p, g) -> Array:
	var c: Dictionary = ctx[g.id]
	var casa := _casa(p, c)
	var acorda := 330.0 + ruido(p.id, dia, 2) * 60.0
	var deita := 1250.0 + ruido(p.id, dia, 3) * 50.0
	var blocos: Array = fixos.get(p.id, []).duplicate()
	blocos.sort_custom(func(a, b): return a["ini"] < b["ini"])
	var plano: Array = [_parada(0.0, acorda, casa, "dormir")]
	if p.doente > 0:
		plano[0]["fim"] = MIN_DIA
		return plano
	# A tempestade não entra no plano: é posta por cima, na hora de cortar (veja _cortar_hora).
	var tarefas := _tarefas(p, g, c)
	var t := acorda
	var x := casa
	var fim_tarefas := 1020.0 + ruido(p.id, dia, 4) * 40.0
	var bi := 0
	var ti := 0
	while t < fim_tarefas:
		while ti >= tarefas.size() and _mais_tarefas(tarefas):
			pass
		# O próximo bloco fixo manda: chega a tempo e cumpre.
		var proximo: Dictionary = blocos[bi] if bi < blocos.size() else {}
		if not proximo.is_empty() and proximo["ini"] < fim_tarefas + 300.0:
			var primeira: Dictionary = proximo["paradas"][0]
			var ate_la: float = absf(primeira["x"] - x) / VELOCIDADE
			if t + ate_la + 20.0 >= proximo["ini"] or ti >= tarefas.size():
				t = _cumprir_bloco(plano, proximo, t, x)
				x = proximo["paradas"][-1]["x"]
				bi += 1
				continue
		if ti >= tarefas.size():
			break
		var tarefa: Dictionary = tarefas[ti]
		ti += 1
		var destino: float = x if tarefa["x"] < 0.0 else tarefa["x"]
		var chega := t + absf(destino - x) / VELOCIDADE
		var limite: float = proximo["ini"] - absf(proximo["paradas"][0]["x"] - destino) / VELOCIDADE if not proximo.is_empty() else fim_tarefas
		var termina := minf(chega + tarefa["dur"], minf(limite, fim_tarefas))
		if termina - chega < 5.0:
			continue
		# Trabalho de mão (colher, construir) anda aos poucos: de arbusto em arbusto, ao longo da roça.
		var trecho_ini := chega
		var xi := destino
		var passo_k := 0
		while trecho_ini < termina:
			var trecho_fim := termina
			if tarefa["acao"] in ["colher", "construir"] and termina - trecho_ini > 24.0:
				trecho_fim = trecho_ini + 12.0 + ruido(p.id, dia, 500 + ti * 10 + passo_k) * 8.0
			plano.append(_parada(trecho_ini, trecho_fim, xi, tarefa["acao"], tarefa.get("ida", "andar"), tarefa.get("virado", 0)))
			passo_k += 1
			var dx := (ruido(p.id, dia, 600 + ti * 10 + passo_k) - 0.5) * 12.0
			var proximo_x := xi + dx
			trecho_ini = trecho_fim + absf(dx) / VELOCIDADE
			xi = proximo_x
		t = termina
		x = plano[-1]["x"]
	# Blocos que sobraram (a noite: conversas, danças, rezas).
	while bi < blocos.size():
		t = _cumprir_bloco(plano, blocos[bi], t, x)
		x = blocos[bi]["paradas"][-1]["x"]
		bi += 1
	# O fim do dia em volta do fogo, e depois casa.
	var fogo := _lugar_fogo(p, c)
	var chega_fogo := t + absf(fogo - x) / VELOCIDADE
	if chega_fogo < deita - 20.0:
		plano.append(_parada(chega_fogo, deita - absf(casa - fogo) / VELOCIDADE, fogo, "fogueira"))
		t = deita - absf(casa - fogo) / VELOCIDADE
		x = fogo
	var chega_casa := maxf(t + absf(casa - x) / VELOCIDADE, deita)
	plano.append(_parada(chega_casa, MIN_DIA, casa, "dormir"))
	return plano


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
var _agendas: Dictionary = {}    # id -> as 24 agendas do dia (null: hora ainda não cortada)


func _linha(pid: int) -> Array:
	var segs: Array = []
	var plano: Array = planos[pid]
	var prev: Dictionary = plano[0]
	_trecho(segs, 0.0, prev["fim"], prev["x"], prev["x"], prev["acao"], prev["virado"], prev["cena"])
	for i in range(1, plano.size()):
		var pa: Dictionary = plano[i]
		var t: float = segs[-1][1]
		var anda: float = absf(pa["x"] - prev["x"]) / VELOCIDADE
		if anda > 0.001:
			_trecho(segs, t, t + anda, prev["x"], pa["x"], pa["ida"], 1 if pa["x"] > prev["x"] else -1, pa["cena"])
			t += anda
		if pa["ini"] > t + 0.001:
			_trecho(segs, t, pa["ini"], pa["x"], pa["x"], "parado", pa["virado"], pa["cena"])
			t = pa["ini"]
		_trecho(segs, t, maxf(pa["fim"], t + 0.5), pa["x"], pa["x"], pa["acao"], pa["virado"], pa["cena"])
		prev = pa
	if segs[-1][1] < MIN_DIA:
		var u: Array = segs[-1]
		_trecho(segs, u[1], MIN_DIA, u[3], u[3], u[4], u[5], u[6])
	var ini := PackedFloat64Array()
	for sg in segs:
		ini.append(sg[0])
	linhas[pid] = segs
	_inicios[pid] = ini
	return segs


## As agendas das 24 horas, numa passada só pela linha do tempo; com tempestade, as horas
## dali em diante são cortadas de novo, com o abrigo por cima.
func _cortar_dia(pid: int) -> void:
	var segs: Array = linhas[pid]
	var horas: Array = []
	horas.resize(24)
	for h in 24:
		horas[h] = []
	for sg in segs:
		var h0 := int(sg[0] / 60.0)
		var h1 := mini(23, int((sg[1] - 0.0001) / 60.0))
		for h in range(h0, h1 + 1):
			_pedaco(horas[h], sg, h * 60.0, h * 60.0 + 60.0)
	_agendas[pid] = horas
	var abrigo := _abrigo(pid)
	if abrigo >= 0.0:
		for h in range(int(abrigo / 60.0), 24):
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
		if xa == xb and u["acao"] == sg[4] and u["x0"] == u["x1"] and u["x1"] == xa:
			u["ate"] = (b - ini) / 60.0
			return
	lista.append({"de": (a - ini) / 60.0, "ate": (b - ini) / 60.0, "x0": xa, "x1": xb, "acao": sg[4],
		"virado": sg[5], "cena": sg[6]})


func _trecho(segs: Array, t0: float, t1: float, x0: float, x1: float, acao: String, virado: int, cena: Dictionary) -> void:
	if t1 - t0 < 0.001:
		return
	if acao != "remar":
		# Ninguém fica na água, a não ser remando.
		x0 = maxf(x0, Cotidiano.MARGEM)
		x1 = maxf(x1, Cotidiano.MARGEM)
	x0 = minf(x0, Cotidiano.LARGURA_MUNDO - 2.0)
	x1 = minf(x1, Cotidiano.LARGURA_MUNDO - 2.0)
	segs.append([t0, t1, x0, x1, acao, virado, cena])


func _indice(pid: int, minuto: float) -> int:
	var ini: PackedFloat64Array = _inicios[pid]
	return maxi(0, ini.bsearch(minuto, false) - 1)


## Onde a pessoa está, o que faz e para que lado olha no minuto dado do dia.
func instante(pid: int, minuto: float) -> Dictionary:
	if not linhas.has(pid):
		var ag: Array = agenda(pid, int(minuto / 60.0))
		return {"x": ag[0]["x0"], "acao": ag[0]["acao"], "virado": 0, "cena": {}}
	var segs: Array = linhas[pid]
	var sg: Array = segs[_indice(pid, minuto)]
	var abrigo := _abrigo(pid)
	if abrigo >= 0.0 and minuto >= abrigo:
		for s2 in _trechos_do_abrigo(pid, abrigo):
			sg = s2
			if minuto < s2[1]:
				break
	var f := clampf((minuto - sg[0]) / maxf(0.001, sg[1] - sg[0]), 0.0, 1.0)
	return {"x": lerpf(sg[2], sg[3], f), "acao": sg[4], "virado": sg[5], "cena": sg[6]}


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
			"virado": 0, "cena": {}}]
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

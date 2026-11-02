extends SceneTree
## Testa a rotina visível: variedade de ações, movimento dentro da hora, cenas,
## regras (ninguém na água, nada fora do mundo), determinismo e custo.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_rotina.gd

const Mundo = preload("res://nucleo/mundo.gd")

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)


func _initialize() -> void:
	var m: Mundo
	if OS.get_cmdline_user_args().size() > 0 and OS.get_cmdline_user_args()[0] == "estagio6":
		# O mundo grande do estágio 6, gerado por medir_desempenho.gd.
		m = preload("res://ferramentas_sim/desempenho.gd").carregar_mundo_grande()
	else:
		m = Mundo.new(4, [], Mundo.HORA_INICIAL, true)
		m.avancar_dias(40 * 70)
	var est := 0
	for g in m.grupos_vivos():
		est = maxi(est, g.estagio)
	print("mundo: ano %d, %d pessoas, estágio máximo %d" % [m.ano(), m.populacao(), est])
	var acoes := {}
	var cenas := {}
	var trechos := 0
	var horas_pessoa := 0
	var paradas_a_hora_toda := 0
	var paradas_por_acao := {}
	var t_total := 0.0
	var consultas := 0
	var antes := m.rng.state
	var ontem := {}
	var iguais := 0
	var comparados := 0
	for d in (60 if OS.get_cmdline_user_args().size() > 0 else 40):
		var hoje := {}
		for h in 24:
			var t := Time.get_ticks_usec()
			var ps := m.pessoas_visiveis()
			var cs := m.cenas_ativas()
			t_total += (Time.get_ticks_usec() - t) / 1000.0
			consultas += 1
			for c in cs:
				cenas[c["tipo"]] = cenas.get(c["tipo"], 0) + 1
			for p in ps:
				acoes[p["acao"]] = acoes.get(p["acao"], 0) + 1
				for tr in p["agenda"]:
					acoes[tr["acao"]] = acoes.get(tr["acao"], 0) + 1
					if tr["acao"] != "remar":
						conferir(tr["x0"] >= 126.0 and tr["x1"] >= 126.0, "na água: %s %s" % [p["nome"], tr])
					conferir(tr["x0"] >= 0.0 and tr["x1"] < 480.0, "fora do mundo: %s" % tr)
				if h >= 7 and h <= 16 and not p["crianca"]:
					horas_pessoa += 1
					trechos += p["agenda"].size()
					if p["agenda"].size() == 1 and absf(p["agenda"][0]["x0"] - p["agenda"][0]["x1"]) < 0.1:
						paradas_a_hora_toda += 1
						var chave: String = p["agenda"][0]["acao"] + (" (idoso)" if p["idade"] > 60 else "")
						paradas_por_acao[chave] = paradas_por_acao.get(chave, 0) + 1
				if h == 10:
					hoje[p["id"]] = p["x"]
			m.avancar_hora()
		for id in hoje:
			if ontem.has(id):
				comparados += 1
				if absf(ontem[id] - hoje[id]) < 0.5:
					iguais += 1
		ontem = hoje
	conferir(m.rng.state != antes, "o mundo andou")
	print("ações vistas: ", acoes.keys())
	print("cenas vistas em 40 dias (horas): ", cenas)
	print("das 7h às 16h: %.1f trechos por pessoa por hora; %.0f%% das horas sem nenhum movimento" % [
		float(trechos) / horas_pessoa, 100.0 * paradas_a_hora_toda / horas_pessoa])
	print("horas sem movimento, por ação: ", paradas_por_acao)
	print("às 10h, %.0f%% das pessoas estavam no mesmo lugar que no dia anterior" % [100.0 * iguais / maxi(1, comparados)])
	print("custo médio de pessoas_visiveis + cenas_ativas: %.2f ms (%d pessoas)" % [t_total / consultas, m.populacao()])
	conferir(acoes.size() >= 12, "pelo menos 12 ações diferentes (%d)" % acoes.size())
	# Mesma pergunta, mesma resposta, sem tocar no sorteio (de dia: de madrugada, antes de a
	# rotina do dia entrar, vale a última hora da de ontem).
	while m.hora() != 12:
		m.pessoas_visiveis()
		m.avancar_hora()
	var s1 := m.rng.state
	var a1 := str(m.pessoas_visiveis())
	m._rotina_cache = null
	var a2 := str(m.pessoas_visiveis())
	conferir(a1 == a2 and m.rng.state == s1, "consulta pura e repetível")
	# A rotina montada na thread é igual à montada aqui, no mesmo instante.
	var dias_vistos := 0
	while dias_vistos < 2:
		m.avancar_hora()
		m.pessoas_visiveis()
		if m._montando != null:
			while not WorkerThreadPool.is_task_completed(m._tarefa):
				OS.delay_msec(5)
			var feita = m._montando
			var aqui = preload("res://nucleo/rotina.gd").new(m, feita.dia)   # às 23h, a de amanhã
			aqui.cortar_desde = feita.cortar_desde
			aqui.cortar_ate = feita.cortar_ate
			aqui._soltas_ate = feita._soltas_ate
			aqui.montar()
			conferir(feita._agendas == aqui._agendas and feita.cenas == aqui.cenas and feita.linhas == aqui.linhas,
				"rotina da thread igual à da linha principal (dia %d)" % feita.dia)
			dias_vistos += 1
	conferir(m.desempenho["substitutos"] == 0, "ninguém acordado sem plano (%s)" % m.desempenho)
	_cenas_da_vila()
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


## As cenas do começo da tarde na vila (sesta, ensinar, artesanato): aparecem, entre 12h30 e
## 15h45, e quem está nelas faz o que a cena diz, na hora certa.
func _cenas_da_vila() -> void:
	var vistas := {"sesta": 0, "ensinar": 0, "artesanato": 0}
	var dias := 0
	for s in [1, 2, 3, 4]:
		var m := Mundo.new(s, [], Mundo.HORA_INICIAL, true)
		m.avancar_dias(3)
		for d in 8:
			dias += 1
			var ro = m.rotina()
			for cena in ro.cenas:
				if not vistas.has(cena["tipo"]):
					continue
				vistas[cena["tipo"]] += 1
				conferir(cena["ini"] >= 745.0 and cena["fim"] <= 950.0, "%s fora do começo da tarde: %.0f a %.0f" % [cena["id"], cena["ini"], cena["fim"]])
				var dets := {}
				for pid in cena["participantes"] + ([cena["crianca"]] if cena.has("crianca") else []):
					for h in range(12, 16):
						for tr in ro.agenda(pid, h):
							if tr["cena"].get("id", "") == cena["id"]:
								dets[tr["detalhe"]] = true
				match cena["tipo"]:
					"sesta":
						conferir(dets.has("sesta") and dets.has("cutucar") and dets.has("ralhar") and dets.has("fugir"), "sesta sem as etapas: %s" % [dets.keys()])
					"ensinar":
						conferir(dets.has("mirar_alvo") and dets.has("arremessar_alvo") and dets.has("aprovar") and dets.has("comemorar")
							and cena["etapas"].filter(func(e): return e["etapa"] == "tentativa")[-1]["acerto"], "ensinar sem as etapas: %s" % [dets.keys()])
					"artesanato":
						conferir(dets.has("mostrar_peca") and (dets.has("trancar_cesto") or dets.has("moldar_pote") or dets.has("afiar_lanca")),
							"artesanato sem as etapas: %s" % [dets.keys()])
			m.avancar_dias(1)
	print("cenas da vila em %d dias: %s" % [dias, vistas])
	for t in vistas:
		conferir(vistas[t] >= dias / 4, "%s aparece pouco: %d em %d dias" % [t, vistas[t], dias])

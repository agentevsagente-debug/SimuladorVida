extends SceneTree
## Exercita a API da apresentação (nucleo/API.md) e confere o básico.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_api.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Cotidiano = preload("res://nucleo/cotidiano.gd")

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)


func _initialize() -> void:
	var m := Mundo.new(1, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(5)
	for i in 14:   # até 14h do dia 6
		m.avancar_hora()
	print("tempo: ", m.tempo())
	var ps := m.pessoas_visiveis()
	conferir(ps.size() == m.populacao(), "uma entrada por pessoa viva")
	for p in ps:
		conferir((p["x"] >= 126 or p["acao"] == "remar") and p["x"] < 480, "x fora da água e dentro do mundo: %s" % p)
		conferir(p["acao"] in preload("res://nucleo/rotina.gd").ACOES, "ação conhecida: " + p["acao"])
	print("pessoa: ", ps[0])
	print("construções: ", m.construcoes())
	print("zona: ", m.zonas_visiveis()[2])
	print("grupos: ", m.grupos_visiveis())
	conferir(m.acompanhada != -1, "acompanha a matriarca no começo")
	# A mesma pergunta duas vezes dá a mesma resposta e não mexe no mundo.
	var antes := m.rng.state
	conferir(str(m.pessoas_visiveis()) == str(ps), "consulta repetida é igual")
	conferir(m.rng.state == antes, "consulta não consome sorteio")
	# Noite: quase todos dormem perto de casa; o vigia (e às vezes mais alguém) fica acordado.
	var noite := 0
	var acordados := 0
	m.avancar_hora()
	while m.hora() != 2:
		m.avancar_hora()
	for p in m.pessoas_visiveis():
		if p["acao"] == "dormir":
			noite += 1
		elif p.get("detalhe", "") in ["vigia", "olhar_ceu", "reza_noturna", "buscar_agua", "historias", "doente"] or p["cena"].get("tipo", "") == "vigia":
			acordados += 1
	conferir(acordados >= 1 and m.populacao() - noite <= 3,
		"às 2h todos dormem, menos o vigia e poucos outros (%d de %d acordados)" % [m.populacao() - noite, m.populacao()])
	# Poderes.
	var alvo: Dictionary = m.pessoas_visiveis()[3]
	var r := m.usar_poder("raio", alvo["x"], 0.9)
	print("raio preciso: ", r)
	conferir(r["ok"] and r["grau"] == "milagre", "raio forte é milagre")
	r = m.usar_poder("chuva", 300.0, 0.2)
	conferir(r["grau"] == "sinal", "chuva fraca é sinal")
	m.usar_poder("chuva", 300.0, 0.2)
	r = m.usar_poder("chuva", 300.0, 0.2)
	conferir(r["grau"] == "imposicao", "terceira chuva seguida é imposição")
	r = m.usar_poder("vento", 10.0, 1.0)
	conferir(not r["ok"], "poder desconhecido é recusado")
	for nome in ["fartura", "fogo", "erguer", "sonho", "seca", "terremoto", "pressagio", "diluvio"]:
		r = m.usar_poder(nome, 260.0, 0.7)
		conferir(r["ok"] and r["evento"] >= 0, "poder " + nome)
		print("  ", nome, ": ", m.eventos[r["evento"]].tipo, " ", r)
	# Cura: em alguém doente vira milagre; em alguém são, só sinal.
	var vivos := m.pessoas_visiveis()
	var gesto: float = vivos[1]["x"]
	var quem = m._pessoa_perto(gesto)
	quem.doente = 5
	r = m.usar_poder("cura", gesto, 0.8)
	conferir(r["grau"] == "milagre" and r["alvo"] == quem.id and quem.doente == 0, "cura de doente é milagre: %s" % r)
	var sao: Dictionary = m.pessoas_visiveis()[2]
	r = m.usar_poder("cura", sao["x"], 0.8)
	conferir(r["alvo"] == -1 or r["grau"] == "sinal", "cura em alguém são é sinal: %s" % r)
	# Anos depois: preces, chamados, sugestões, crônica. Ninguém na água em nenhuma hora.
	var visto := m.eventos.size()
	for d in 40 * 15:
		m.avancar_dias(1)
		if d % 7 == 0:
			for h in 24:
				for p in m.pessoas_visiveis():
					conferir(p["x"] >= 126 or p["acao"] == "remar", "pessoa na água: %s" % p)
				m.avancar_hora()
	var novos := m.eventos_desde(visto)
	var chamados := novos.filter(func(d): return d["camada"] == "chamado")
	print("eventos novos: %d, chamados: %d" % [novos.size(), chamados.size()])
	print("preces abertas agora: ", m.preces_abertas())
	print("sugestões: ", m.sugestoes(3))
	print("acompanhada: ", m.acompanhada, " viva=", m.pessoas[m.acompanhada].vivo if m.acompanhada != -1 else "-")
	conferir(m.acompanhada == -1 or m.pessoas[m.acompanhada].vivo, "acompanhada está viva")
	conferir(m.ultimo_ano_na_cronica() == m.ano() - 1, "crônica em dia até o ano anterior")
	conferir(not m.cronica().is_empty(), "crônica tem texto")
	print(m.cronica_ano(2).substr(0, 300))
	# Custo de uma consulta completa da apresentação.
	var t := Time.get_ticks_usec()
	for i in 100:
		m.pessoas_visiveis()
		m.construcoes()
		m.preces_abertas()
	print("consulta completa: %.2f ms (%d pessoas)" % [(Time.get_ticks_usec() - t) / 100000.0, m.populacao()])
	_batalha_no_meio_do_dia()
	_mira_dos_poderes()
	_qa_pequenos()
	_sons()
	print("%d falhas" % falhas)
	quit()


## D-02 do QA: o sonho (e o raio, e a cura) atinge quem está sob o gesto na tela, no minuto da
## hora que a tela mostra, e não onde a pessoa estará no fim da hora. E com o id, sempre ela.
func _mira_dos_poderes() -> void:
	var tentativas := 0
	var acertos := 0
	var perto := 0
	var pelo_id := 0
	for s in range(1, 4):
		var m := Mundo.new(s, [], Mundo.HORA_INICIAL, true)
		m.avancar_dias(3)
		for h in [9, 11, 14]:
			while m.hora() != h:
				m.avancar_hora()
			var ro = m.rotina()
			for q in m.pessoas_visiveis():
				if q["acao"] == "dormir" or q["crianca"]:
					continue
				for minuto in [5.0, 30.0, 55.0]:
					var x: float = ro.instante(q["id"], h * 60.0 + minuto)["x"]
					# A mira de usar_poder (sem gesto: o gesto mudaria o mundo no meio da medida).
					var alvo = m._pessoa_perto(x, minuto)
					tentativas += 1
					var a: int = alvo.id if alvo != null else -1
					if a == q["id"]:
						acertos += 1
					if a >= 0 and absf(ro.instante(a, h * 60.0 + minuto)["x"] - x) <= Mundo.ALCANCE_ALVO:
						perto += 1
			# O gesto de verdade, uma vez por hora: pelo id e pelo minuto.
			var q0: Dictionary = m.pessoas_visiveis().filter(func(q): return q["acao"] != "dormir" and not q["crianca"])[0]
			if m.usar_poder("sonho", 0.0, 0.2, q0["id"]).get("alvo", -1) == q0["id"]:
				pelo_id += 1
			var x0: float = m.rotina().instante(q0["id"], h * 60.0 + 50.0)["x"]
			var r0: Dictionary = m.usar_poder("sonho", x0, 0.2, -1, 50.0)
			conferir(r0.get("alvo", -1) >= 0, "usar_poder com o minuto acerta alguém (%s)" % r0)
	print("mira: %d de %d acertam a pessoa no minuto mirado (%d acertam alguém a até 6 px); pelo id, %d" % [acertos, tentativas, perto, pelo_id])
	conferir(perto == tentativas, "o gesto no x de uma pessoa, no minuto da tela, sempre acerta alguém ali (%d de %d)" % [perto, tentativas])
	conferir(acertos >= tentativas * 0.9, "e quase sempre ela mesma (%d de %d)" % [acertos, tentativas])
	conferir(pelo_id == 9, "com o id, sempre ela (%d de 9)" % pelo_id)


## Um ataque às 8h (como o cenário raro da batalha): a cena de guerra entra na mesma hora, já na
## consulta seguinte, com gente dos dois povos, e começa meia hora depois do ataque.
func _batalha_no_meio_do_dia() -> void:
	var m := Mundo.new(3, [], Mundo.HORA_INICIAL, true)
	while m.ano() < 60:
		m.avancar_dias(40)
	while m.hora() != 8:
		m.avancar_hora()
	m.cenas_ativas()
	var vivos: Array = m.grupos_vivos()
	if vivos.size() < 2:
		return
	m._atacar(vivos[0], vivos[1])
	var viu := false
	for c in m.cenas_ativas():
		if c["tipo"] == "guerra" and c["participantes"].size() >= 4 and is_equal_approx(c["ini"], 8.5) and is_equal_approx(c["fim"], 13.0):
			viu = true
	conferir(viu, "o ataque às 8h vira a cena de guerra das 8h30 às 13h, já na mesma hora")


## D-11, D-12 e D-13 do QA.
func _qa_pequenos() -> void:
	# D-11: todo gesto do deus é nota ou chamado, nunca ambiente (a chuva sem seca, a cura em quem está são).
	for poder in Mundo.PODERES:
		var m := Mundo.new(3, [], Mundo.HORA_INICIAL, true)
		var r: Dictionary = m.usar_poder(poder, 260.0, 0.6)
		if r.get("ok", false) and r.get("evento", -1) >= 0:
			var d: Dictionary = m.eventos_desde(r["evento"])[0]
			conferir(d["camada"] != "ambiente", "D-11: o gesto %s (0,6) é %s, com importância %d" % [poder, d["camada"], d["importancia"]])
	# D-12: dois povos vivos não dão o mesmo nome ao mesmo lugar (semente 3, ano 120).
	var w := Mundo.new(3, [], Mundo.HORA_INICIAL, true)
	while w.ano() < 120:
		w.avancar_dias(Mundo.DIAS_ANO)
	var repetidos: Array = []
	var nomes := 0
	for z in w.zonas.values():
		var vistos := {}
		for gid in z.nomes:
			var g = w.grupo(int(gid))
			if g == null or g.extinto:
				continue
			nomes += 1
			var n: String = z.nomes[gid]["nome"]
			if vistos.has(n):
				repetidos.append("%s: %s" % [z.chave, n])
			vistos[n] = true
	print("D-12: %d nomes de povos vivos, repetidos %s" % [nomes, repetidos])
	conferir(nomes > 0 and repetidos.is_empty(), "D-12: cada povo vivo dá o seu nome ao lugar: %s" % [repetidos])
	# D-13: exatamente um ano fora conta como teto atingido.
	var a := Mundo.new(2, [], Mundo.HORA_INICIAL, true)
	var aus: Dictionary = a.avancar_ausencia(Mundo.TETO_AUSENCIA * Mundo.SEGUNDOS_POR_PASSO)
	conferir(aus["passos"] == Mundo.TETO_AUSENCIA and aus["teto_atingido"], "D-13: um ano exato fora: %d passos, teto %s" % [aus["passos"], aus["teto_atingido"]])
	var b := Mundo.new(2, [], Mundo.HORA_INICIAL, true)
	conferir(not b.avancar_ausencia((Mundo.TETO_AUSENCIA - 1) * Mundo.SEGUNDOS_POR_PASSO)["teto_atingido"], "D-13: uma hora a menos que o ano não é o teto")


## Os ganchos do som (versão 0.2): o som de cada gesto, os sons marcados de um dia e o ambiente.
func _sons() -> void:
	# Os gestos: o som vem no retorno de usar_poder, com o x do gesto.
	for caso in [["raio", "trovao"], ["terremoto", "terremoto"], ["fogo", "fogo"], ["diluvio", "diluvio"],
			["pressagio", "pressagio"], ["chuva", "chuva"], ["fartura", "sino"]]:
		var m := Mundo.new(3, [], Mundo.HORA_INICIAL, true)
		var r: Dictionary = m.usar_poder(caso[0], 260.0, 0.8)
		var som: Dictionary = r.get("som", {})
		conferir(som.get("som", "") == caso[1] and absf(som.get("x", -1.0) - 260.0) < 0.1 and som["intensidade"] > 0.0 and som["intensidade"] <= 1.0,
			"o gesto %s soa %s em x 260: %s" % [caso[0], caso[1], som])
		if caso[0] in ["chuva", "fartura"]:
			conferir(som.get("sino", false), "o milagre de %s toca também o sino" % caso[0])
	var fraco: Dictionary = Mundo.new(3, [], Mundo.HORA_INICIAL, true).usar_poder("raio", 260.0, 0.2).get("som", {})
	var forte: Dictionary = Mundo.new(3, [], Mundo.HORA_INICIAL, true).usar_poder("raio", 260.0, 0.9).get("som", {})
	conferir(fraco["intensidade"] < forte["intensidade"], "o raio de sinal soa mais baixo que o milagre (%.2f, %.2f)" % [fraco["intensidade"], forte["intensidade"]])
	# Os sons marcados de um dia inteiro, num mundo do estágio 3 ou mais.
	var w := Mundo.new(3, [], Mundo.HORA_INICIAL, true)
	while w.ano() < 120:
		w.avancar_dias(Mundo.DIAS_ANO)
	var vistos := {}
	var pior := 0
	var custos: Array = []
	for d in 4:
		for hh in 24:
			w.avancar_hora()
			w.rotina()   # a montagem da rotina é de qualquer consulta; aqui mede-se só o som
			var t0 := Time.get_ticks_usec()
			var sons: Array = w.sons_da_hora()
			w.ambiente_sonoro()
			custos.append(Time.get_ticks_usec() - t0)
			pior = maxi(pior, custos[-1])
			conferir(w.sons_da_hora() == sons, "sons_da_hora guardado no passo")
			for sm in sons:
				vistos[sm["som"]] = vistos.get(sm["som"], 0) + 1
				conferir(sm["minuto"] >= 0.0 and sm["minuto"] < 60.0 and sm["x"] >= 0.0 and sm["x"] <= Cotidiano.LARGURA_MUNDO, "som fora da hora ou do mundo: %s" % sm)
			var amb: Dictionary = w.ambiente_sonoro()
			conferir(amb["fogo_aceso"] and amb["vila"] > 0.0 and not amb["vilas"].is_empty(), "ambiente da vila: %s" % amb)
			conferir(amb["noite"] == (w.hora() >= 20 or w.hora() < 6), "ambiente: a noite")
	var estagio := 0
	for g in w.grupos_vivos():
		estagio = maxi(estagio, g.estagio)
	custos.sort()
	var mediana: float = custos[custos.size() / 2] / 1000.0
	print("sons marcados em 4 dias (estágio %d): %s; sons_da_hora com ambiente_sonoro: mediana %.2f ms, pior %.2f ms" % [estagio, vistos, mediana, pior / 1000.0])
	conferir(vistos.has("galo") and vistos.has("lanca"), "o galo e a caçada soam em 4 dias: %s" % vistos)
	conferir(estagio < 3 or vistos.has("sino_templo"), "o sino do templo soa no estágio 3 ou mais: %s" % vistos)
	conferir(mediana < 1.0, "sons_da_hora e ambiente_sonoro custam %.2f ms (mediana) na primeira chamada da hora" % mediana)
	# O nascimento num povo pequeno soa (choro ao longe); o mundo vazio tem ambiente vazio.
	var nasc := {"tipo": "nascimento", "camada": "nota", "grupo": -1, "zona": "floresta", "dados": {}}
	conferir(Mundo.new(3).som_do_evento(nasc).get("som", "") == "choro_bebe", "o nascimento soa o choro do bebê")
	nasc["camada"] = "ambiente"
	conferir(Mundo.new(3).som_do_evento(nasc).is_empty(), "o nascimento de camada ambiente não soa")
	var vazio: Dictionary = Mundo.new(3).ambiente_sonoro()
	conferir(vazio["vazio"] and not vazio["fogo_aceso"] and vazio["vila"] == 0.0, "o mundo vazio: sem fogo e sem vila: %s" % vazio)

extends SceneTree
## Exercita a API da apresentação (nucleo/API.md) e confere o básico.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_api.gd

const Mundo = preload("res://nucleo/mundo.gd")

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

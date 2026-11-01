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
	var m := Mundo.new(1)
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
	# Noite: todos dormem perto de casa.
	var noite := 0
	m.avancar_hora()
	while m.hora() != 2:
		m.avancar_hora()
	for p in m.pessoas_visiveis():
		if p["acao"] == "dormir":
			noite += 1
	conferir(noite == m.populacao(), "todos dormem às 2h")
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
	print("%d falhas" % falhas)
	quit()

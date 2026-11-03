extends SceneTree
## A caixa de preces e o termômetro de fé (pedido do autor em 03/11/2026).
## - Um deus que atende metade das preces, contraria um quarto e cala o resto, por 30 anos (sementes
##   1 a 3): preces_historico() mostra os quatro estados (esperando, atendida, falso_milagre,
##   sem_resposta), das mais novas para as mais antigas; "esperando" são as de preces_abertas(),
##   "atendida" e "falso_milagre" batem com o evento prece_atendida, a contrariada é "sem_resposta"
##   com `contrariada`; o x é o de quem rezou, -1 se morreu; preces_novas_desde() conta as do fim.
## - fe_do_povo(): média de -1 a 1, tendência "sobe", "desce" ou "estavel"; o deus que só contraria
##   faz a fé descer.
## - Mundo salvo sem as amostras de fé (como os de antes): carrega, e a tendência é "estavel".
##   O save do autor (qa/save-sergio-ano3.txt) também.
## - Custo, num mundo de cerca de 240 pessoas: preces_historico(), preces_novas_desde() e fe_do_povo()
##   de todos os povos, no primeiro chamado de cada passo: mediana e média abaixo de 1 ms.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_preces.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")

const ATENDE := {"seca": "chuva", "fome": "fartura", "doenca": "cura", "banal": "sonho", "frio": "fogo"}
const CONTRARIA := {"seca": "seca", "fome": "seca", "doenca": "raio", "frio": "diluvio", "guerra": "terremoto", "banal": "seca"}

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU  ", msg)


func _initialize() -> void:
	var estados := {}
	for s in [1, 2, 3]:
		_deus_misturado(s, estados)
	for e in ["esperando", "atendida", "falso_milagre", "sem_resposta"]:
		conferir(estados.has(e), "nenhuma prece ficou no estado %s" % e)
	print("estados vistos: %s" % [estados])
	_deus_que_contraria(1)
	_save_antigo()
	_save_do_autor()
	_custo()
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


func _deus_misturado(semente: int, estados: Dictionary) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var feitas := {}
	for dia in Mundo.DIAS_ANO * 30:
		m.avancar_dias(1)
		for pr in m.preces_abertas():
			if feitas.has(pr["evento"]) or m.dia_abs() - pr["desde"] < 2:
				continue
			feitas[pr["evento"]] = true
			var sorte := rng.randf()
			var poder: String = ""
			if sorte < 0.5:
				poder = ATENDE.get(pr["necessidade"], "")
			elif sorte < 0.75:
				poder = CONTRARIA.get(pr["necessidade"], "")
			if poder.is_empty():
				continue
			var x: float = m.posicao_de(pr["alvo"]) if poder == "cura" and pr["alvo"] != -1 else pr["x_povo"]
			m.usar_poder(poder, x, 0.2 if poder == "fogo" else 0.8)
		if dia % 40 == 39:
			_conferir_historico(m, semente, estados)
	m.encerrar()


func _conferir_historico(m, semente: int, estados: Dictionary) -> void:
	var h: Array = m.preces_historico(200)
	conferir(m.preces_historico(200) == h, "semente %d: o histórico muda sem o mundo mudar" % semente)
	var abertas := {}
	for pr in m.preces_abertas():
		abertas[pr["evento"]] = true
	var atendidas := {}
	var contrariadas := {}
	for e in m.do_tipo("prece_atendida"):
		atendidas[e.dados["prece"]] = e.dados["falso_milagre"]
	for e in m.do_tipo("prece_contrariada"):
		contrariadas[e.dados["prece"]] = true
	var anterior := 1 << 40
	var esperando := 0
	for it in h:
		estados[it["estado"]] = true
		conferir(it["evento"] < anterior, "semente %d: fora de ordem (%d depois de %d)" % [semente, it["evento"], anterior])
		anterior = it["evento"]
		for k in ["evento", "grupo", "nome_povo", "povo", "autor", "nome_autor", "nome", "alvo", "necessidade", "ano", "dia",
				"hora", "passo", "texto", "curto", "estado", "contrariada", "x", "vivo"]:
			conferir(it.has(k), "semente %d: o item não tem %s" % [semente, k])
		var e = m.evento(it["evento"])
		conferir(e.tipo == "prece" and it["passo"] == m.passo_de(e), "semente %d: o item %d não é a prece certa" % [semente, it["evento"]])
		conferir(not it["texto"].is_empty() and it["texto"].find("{") < 0, "semente %d: texto da prece: %s" % [semente, it["texto"]])
		match it["estado"]:
			"esperando":
				esperando += 1
				conferir(abertas.has(it["evento"]), "semente %d: %d esperando, mas não está aberta" % [semente, it["evento"]])
			"atendida", "falso_milagre":
				conferir(atendidas.has(it["evento"]) and atendidas[it["evento"]] == (it["estado"] == "falso_milagre"),
					"semente %d: %d %s sem o evento prece_atendida certo" % [semente, it["evento"], it["estado"]])
			"sem_resposta":
				conferir(it["contrariada"] == contrariadas.has(it["evento"]), "semente %d: %d contrariada errada" % [semente, it["evento"]])
		conferir(it["vivo"] == (it["x"] >= 0.0), "semente %d: %d vivo %s com x %.1f" % [semente, it["evento"], it["vivo"], it["x"]])
	var abertas_na_lista := 0
	for pr in m.preces_abertas():
		if h.size() < 200 or pr["evento"] >= h[-1]["evento"]:
			abertas_na_lista += 1
	conferir(esperando == abertas_na_lista, "semente %d: %d esperando, %d abertas" % [semente, esperando, abertas_na_lista])
	conferir(m.preces_historico(5).size() <= 5, "semente %d: o limite não vale" % semente)
	# O ponto de "não lida": as que chegaram depois de um passo.
	if h.size() > 3:
		var p: int = h[3]["passo"]
		var n := h.filter(func(it): return it["passo"] > p).size()
		conferir(m.preces_novas_desde(p) == n, "semente %d: preces_novas_desde(%d) = %d, esperado %d" % [semente, p, m.preces_novas_desde(p), n])
	conferir(m.preces_novas_desde(m.passo) == 0, "semente %d: prece nova depois do passo de agora" % semente)
	for g in m.grupos_vivos():
		var f: Dictionary = m.fe_do_povo(g.id)
		conferir(f["media"] >= -1.0 and f["media"] <= 1.0 and f["nivel"] >= 0.0 and f["nivel"] <= 1.0, "semente %d: fé fora da faixa %s" % [semente, f])
		conferir(f["tendencia"] in ["sobe", "desce", "estavel"], "semente %d: tendência %s" % [semente, f["tendencia"]])


## O deus que só contraria: a fé do povo desce, e o termômetro diz.
func _deus_que_contraria(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	# Até o povo rezar (os primeiros anos não têm deus).
	m.avancar_dias(Mundo.DIAS_ANO * 2 + 25)
	while m.preces_abertas().is_empty() and m.ano() < 60:
		m.avancar_dias(1)
	var feitas := {}
	var desceu := false
	for dia in Mundo.DIAS_ANO * 6:
		m.avancar_dias(1)
		for pr in m.preces_abertas():
			if feitas.has(pr["evento"]):
				continue
			feitas[pr["evento"]] = true
			var poder: String = CONTRARIA.get(pr["necessidade"], "")
			if not poder.is_empty():
				m.usar_poder(poder, pr["x_povo"], 0.8)
		for g in m.grupos_vivos():
			if m.fe_do_povo(g.id)["tendencia"] == "desce":
				desceu = true
	conferir(desceu, "o deus contrariou %d preces e a fé de nenhum povo desceu" % feitas.size())
	conferir(m.fe_do_povo(9999).is_empty(), "fe_do_povo de um povo que não existe não é {}")
	m.encerrar()


## Um mundo salvo antes das amostras de fé: carrega, a tendência é "estavel", e a amostra volta na virada.
func _save_antigo() -> void:
	var m := Mundo.new(5, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(Mundo.DIAS_ANO * 3 + 30)
	conferir(not m.fe_amostras.is_empty(), "nenhuma amostra de fé depois de 3 viradas de ano")
	var d: Dictionary = Persistencia._para_dict(m)
	conferir(d["mundo"].has("fe_amostras"), "as amostras de fé não vão no mundo salvo")
	d["mundo"].erase("fe_amostras")
	var pasta := "user://testar_preces"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	var f := FileAccess.open(pasta + "/antigo.txt", FileAccess.WRITE)
	f.store_string(Persistencia._texto(d))
	f.close()
	m.encerrar()
	var m2 = Persistencia.carregar(pasta + "/antigo.txt")
	conferir(m2 != null, "o mundo salvo sem amostras não carregou")
	if m2 == null:
		return
	conferir(m2.fe_amostras.is_empty(), "o mundo antigo carregou com amostras")
	for g in m2.grupos_vivos():
		conferir(m2.fe_do_povo(g.id)["tendencia"] == "estavel", "mundo antigo: tendência %s sem amostra" % m2.fe_do_povo(g.id)["tendencia"])
	conferir(m2.preces_historico() is Array, "mundo antigo: sem histórico de preces")
	m2.avancar_dias(Mundo.DIAS_ANO)
	conferir(not m2.fe_amostras.is_empty(), "mundo antigo: a amostra não voltou na virada")
	# E as amostras sobrevivem a salvar e carregar.
	Persistencia.salvar(m2, pasta + "/novo.txt")
	var m3 = Persistencia.carregar(pasta + "/novo.txt")
	conferir(m3 != null and m3.fe_amostras == m2.fe_amostras, "as amostras de fé não sobreviveram a salvar e carregar")
	m2.encerrar()
	if m3 != null:
		m3.encerrar()


func _save_do_autor() -> void:
	var orig := ProjectSettings.globalize_path("res://").path_join("../qa/save-sergio-ano3.txt")
	if not FileAccess.file_exists(orig):
		return
	var pasta := "user://testar_preces"
	var f := FileAccess.open(pasta + "/autor.txt", FileAccess.WRITE)
	f.store_string(FileAccess.get_file_as_string(orig).replace("\r", ""))
	f.close()
	var m = Persistencia.carregar(pasta + "/autor.txt")
	conferir(m != null, "o save do autor não carregou")
	if m == null:
		return
	for g in m.grupos_vivos():
		conferir(m.fe_do_povo(g.id)["tendencia"] == "estavel", "save do autor: tendência sem amostra")
	print("save do autor: %d preces no histórico; fé de %s: %s" % [m.preces_historico().size(), m.grupos_vivos()[0].nome, m.fe_do_povo(m.grupos_vivos()[0].id)])
	m.encerrar()


## Num mundo de cerca de 240 pessoas, o primeiro chamado de cada passo (o cache vazio).
func _custo() -> void:
	var m := Mundo.new(1, [], Mundo.HORA_INICIAL, true)
	while m.populacao() < 240 and m.ano() < 400:
		m.avancar_dias(Mundo.DIAS_ANO)
	print("custo: ano %d, %d pessoas, %d preces na memória" % [m.ano(), m.populacao(), m.do_tipo("prece").size()])
	var pior := 0
	var soma := 0
	var tempos: Array = []
	for i in 48:
		m.avancar_hora()
		m.rotina()   # a montagem do dia novo não é custo da caixa (posicao_de lê a rotina pronta)
		var t0 := Time.get_ticks_usec()
		m.preces_historico()
		m.preces_novas_desde(m.passo - 200)
		for g in m.grupos_vivos():
			m.fe_do_povo(g.id)
		var dt := Time.get_ticks_usec() - t0
		pior = maxi(pior, dt)
		soma += dt
		tempos.append(dt)
	tempos.sort()
	var mediana: int = tempos[tempos.size() / 2]
	# O pior sai na tela, sem falhar: com a máquina ocupada (outras sessões, o Windows), um passo
	# isolado pode levar dezenas de ms. A meta vale para a mediana e para a média.
	print("custo: mediana %.2f ms, média %.2f ms, pior %.2f ms" % [mediana / 1000.0, soma / 48000.0, pior / 1000.0])
	conferir(mediana < 1000, "custo mediano %.2f ms (meta: abaixo de 1 ms)" % (mediana / 1000.0))
	conferir(soma / 48 < 1000, "custo médio %.2f ms (meta: abaixo de 1 ms)" % (soma / 48000.0))
	m.encerrar()

extends SceneTree
## O fim do mundo pela simulação (auditoria 11, D7): o que a tela "Não resta ninguém" lê.
## - Morte natural do último: num mundo de 30 anos, ficam só os 3 mais velhos (os outros morrem de
##   doença, os 3 passam dos 80 anos), e o mundo anda hora a hora até o último morrer de velho. Confere: "os_ultimos" uma vez,
##   "fim_do_mundo" uma vez e na mesma hora da última morte, `fim_do_mundo` ligado, o livro fechado
##   (com resumo e epitáfio) em `livros[-1]`, ruínas.
## - O último morto no meio do dia (às 14h): o fim chega na mesma hora, não na virada do dia.
## - O mundo vazio: anda 2 anos sem erro e sem eventos de gente; as consultas da tela vêm vazias
##   (pessoas, cenas, povos); a crônica viva e a ausência funcionam; salva e carrega vazio; os
##   poderes recusam; criar_povo recomeça a era 2.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_fim.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")

var falhas := 0
var naturais := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU  ", msg)


func _initialize() -> void:
	for semente in [1, 2, 3, 4, 5]:
		_morte_natural(semente)
	conferir(naturais >= 3, "só %d mundos acabaram pela morte natural do último" % naturais)
	_morte_no_meio_do_dia(4)
	_raio_no_ultimo(5)
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


func _morte_natural(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(Mundo.DIAS_ANO * 30)
	var vivos: Array = []
	for g in m.grupos_vivos():
		for id in g.membros:
			vivos.append(m.pessoas[id])
	vivos.sort_custom(func(a, b): return a.nasc_ano < b.nasc_ano)
	for p in vivos.slice(3):
		m._morrer(p, "doenca")
	# Os 3 que ficam envelhecem de uma vez (80 a 82 anos), num povo que não acolhe estranhos: sem
	# isso, os estranhos de além da borda chegam a um povo pequeno sem casal e o salvam.
	var a: int = m.ano()
	for i in 3:
		vivos[i].nasc_ano = a - 80 - i
		m.grupo(vivos[i].grupo).estranhos = -1.0
	var antes: int = m.eventos.size()
	var horas := 0
	var visto: int = antes
	while m.populacao() > 0 and horas < Mundo.HORAS_DIA * Mundo.DIAS_ANO * 30:
		m.avancar_hora()
		horas += 1
		var novos: Array = m.eventos_desde(visto)
		visto = m.eventos.size()
		if novos.any(func(e): return e["tipo"] == "estranhos"):
			print("  semente %d: chegaram estranhos de além da borda e salvaram o povo (não conta)" % semente)
			return
	naturais += 1
	conferir(m.populacao() == 0, "semente %d: os 3 velhos não morreram em 30 anos" % semente)
	conferir(m.fim_do_mundo, "semente %d: a população é 0, mas o fim do mundo não chegou na mesma hora" % semente)
	var tipos: Array = m.eventos_desde(antes).map(func(e): return e["tipo"])
	conferir(tipos.count("os_ultimos") == 1, "semente %d: os_ultimos %d vezes" % [semente, tipos.count("os_ultimos")])
	conferir(tipos.count("extincao_grupo") >= 1 and tipos.find("extincao_grupo") < tipos.find("fim_do_mundo"),
		"semente %d: o povo não virou ruína antes do fim" % semente)
	conferir(tipos.count("fim_do_mundo") == 1, "semente %d: fim_do_mundo %d vezes" % [semente, tipos.count("fim_do_mundo")])
	var ultima_morte = null
	var fim = null
	for e in m.eventos_desde(antes):
		if e["tipo"] == "morte":
			ultima_morte = e
		elif e["tipo"] == "fim_do_mundo":
			fim = e
	if ultima_morte != null and fim != null:
		conferir(ultima_morte["ano"] == fim["ano"] and ultima_morte["dia"] == fim["dia"] and ultima_morte["hora"] == fim["hora"],
			"semente %d: a última morte (%d/%d %dh) e o fim (%d/%d %dh) não são da mesma hora" % [semente,
			ultima_morte["ano"], ultima_morte["dia"], ultima_morte["hora"], fim["ano"], fim["dia"], fim["hora"]])
		print("  semente %d: o último morreu de %s no ano %d, dia %d, %dh, e o fim veio na mesma hora" % [semente,
			ultima_morte["dados"].get("causa", "?"), ultima_morte["ano"], ultima_morte["dia"], ultima_morte["hora"]])
	_conferir_mundo_vazio(m, "semente %d" % semente)


func _morte_no_meio_do_dia(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(Mundo.DIAS_ANO * 10)
	while m.hora() != 14:
		m.avancar_hora()
	for g in m.grupos_vivos():
		for id in g.membros.duplicate():
			m._morrer(m.pessoas[id], "doenca")
	m.avancar_hora()
	conferir(m.fim_do_mundo, "último morto às 14h: o fim não chegou às 15h")
	print("  último morto às 14h: fim do mundo às %dh" % m.hora())
	_conferir_mundo_vazio(m, "às 14h")


func _conferir_mundo_vazio(m, nome: String) -> void:
	conferir(not m.livros.is_empty() and m.livros[-1]["texto"].contains("## Em resumo") and m.livros[-1]["texto"].contains("*Aqui termina"),
		"%s: o livro da era não fechou com resumo e epitáfio" % nome)
	if not m.livros.is_empty():
		print("    livro: %s" % m.livros[-1]["titulo"])
	conferir(m.ruinas_visiveis().size() > 0, "%s: sem ruínas" % nome)
	var antes: int = m.eventos.size()
	for h in Mundo.HORAS_DIA * Mundo.DIAS_ANO * 2:
		m.avancar_hora()
		if h % 6 == 0:
			conferir(m.pessoas_visiveis().is_empty() and m.cenas_ativas().is_empty() and m.grupos_visiveis().is_empty(),
				"%s: o mundo vazio mostra %d pessoas, cenas %s, %d povos" % [nome, m.pessoas_visiveis().size(),
				m.cenas_ativas().map(func(c): return c["tipo"]), m.grupos_visiveis().size()])
	var depois: Array = m.eventos_desde(antes).map(func(e): return e["tipo"])
	conferir(not depois.has("fim_do_mundo") and not depois.has("morte") and not depois.has("nascimento"),
		"%s: eventos de gente no mundo vazio: %s" % [nome, depois])
	conferir(not m.cronica_viva().is_empty(), "%s: crônica viva vazia" % nome)
	conferir(not m.usar_poder("chuva", 200.0, 0.8)["ok"], "%s: um poder agiu sobre o mundo vazio" % nome)
	var aus: Dictionary = m.avancar_ausencia(3600.0 * 64)
	conferir(aus["passos"] > 0 and m.populacao() == 0 and m.fim_do_mundo, "%s: a ausência no mundo vazio" % nome)
	var caminho := "user://teste_fim.txt"
	conferir(Persistencia.salvar(m, caminho), "%s: não salvou o mundo vazio" % nome)
	var c = Persistencia.carregar(caminho)
	conferir(c != null and c.fim_do_mundo and c.populacao() == 0, "%s: o mundo vazio não voltou vazio do arquivo" % nome)
	var r: Dictionary = m.criar_povo(260.0)
	conferir(r["ok"] and m.era == 2 and m.populacao() > 0 and not m.fim_do_mundo, "%s: criar_povo: %s" % [nome, r])
	m.avancar_dias(Mundo.DIAS_ANO)
	conferir(m.populacao() > 0, "%s: o povo novo não viveu um ano" % nome)


## D-03 do QA: às 10h, o raio de milagre mata o último; o fim vem logo depois do gesto, sem
## esperar o passo, e o próximo gesto sobre o povo recusa.
func _raio_no_ultimo(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(Mundo.DIAS_ANO * 5)
	while m.hora() != 10:
		m.avancar_hora()
	var vivos: Array = []
	for g in m.grupos_vivos():
		for id in g.membros:
			vivos.append(id)
	for id in vivos.slice(1):
		m._morrer(m.pessoas[id], "doenca")
	var r: Dictionary = m.usar_poder("raio", 0.0, 0.95, vivos[0])
	conferir(r.get("alvo", -1) == vivos[0] and m.populacao() == 0, "o raio no último não o matou: %s" % r)
	conferir(m.fim_do_mundo, "o raio matou o último, e o fim não veio logo depois do gesto")
	conferir(not m.usar_poder("chuva", 200.0, 0.8)["ok"], "depois do raio no último, a chuva ainda é aceita")
	print("  raio no último às 10h: fim do mundo logo depois do gesto")
	_conferir_mundo_vazio(m, "raio no último")

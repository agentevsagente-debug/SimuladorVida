extends SceneTree
## Imprime as dicas (o que a pessoa faz, o que pensa, o humor) de pessoas em mundos, anos e
## horas diferentes, e confere: frases não vazias, pensamento até 60 caracteres, nada
## sobre o jogador, a mesma pessoa sem a mesma frase por horas a fio, e o mesmo mundo dá a
## mesma dica (a dica não mexe no sorteio do mundo); quem dorme, com humor de sono; no mesmo povo,
## duas pessoas nunca com a mesma frase na mesma hora; e o custo da consulta (a primeira do dia e
## a primeira de uma hora).
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_dica.gd

const Mundo = preload("res://nucleo/mundo.gd")
const PROIBIDAS := ["jogador", "você", "deus ", "Deus"]

var falhas := 0


func _initialize() -> void:
	var casos := [[1, 4, 10], [2, 14, 16], [3, 24, 21], [4, 34, 3], [5, 120, 17], [7, 400, 12], [2, 2400, 15], [3, 3600, 19], [4, 1600, 10], [6, 11400, 14]]
	var impressas := 0
	for c in casos:
		var m := Mundo.new(c[0])
		while m.dia_abs() < c[1]:
			m.avancar_hora()
		while m.hora() < c[2]:
			m.avancar_hora()
		var rng0: int = m.rng.state
		var vivos: Array = m.pessoas_visiveis()
		var t0 := Time.get_ticks_usec()
		if not vivos.is_empty():
			m.dica(vivos[0]["id"])
		var custo := (Time.get_ticks_usec() - t0) / 1000.0
		print("\n== semente %d, ano %d, dia %d, %dh (%d pessoas)" % [c[0], m.ano(), m.dia_do_ano(), m.hora(), vivos.size()])
		var n := 0
		for f in vivos:
			if n >= 4 and impressas >= 20 and n >= 2:
				break
			if n >= 5:
				break
			var d: Dictionary = m.dica(f["id"])
			var p = m.pessoas[f["id"]]
			print("  %s, %d anos (%s): %s | \"%s\" | %s" % [p.nome, p.idade(m.ano()), ", ".join(p.tracos), d["fazendo"], d["pensamento"], d["humor"]])
			_conferir(d, f, m)
			n += 1
			impressas += 1
		for f in vivos:
			_conferir(m.dica(f["id"]), f, m)
		print("  (%d pessoas: %.1f ms na primeira consulta do dia, para o povo de %s)" % [vivos.size(), custo, vivos[0]["nome"] if not vivos.is_empty() else ""])
		var vistas := {}
		var repetidas := 0
		var com_frase := 0
		for f in vivos:
			var pe: String = m.dica(f["id"])["pensamento"]
			if pe.is_empty():
				continue
			com_frase += 1
			var k: String = "%d|%s" % [f["grupo"], pe]
			if vistas.has(k):
				repetidas += 1
			vistas[k] = true
		if repetidas > 0:
			_falha("%d frases repetidas no mesmo povo na mesma hora" % repetidas)
		print("  (%d de %d com a frase de outra pessoa do mesmo povo)" % [repetidas, com_frase])
		if m.rng.state != rng0:
			_falha("a dica mexeu no sorteio do mundo")
		m.avancar_hora()
		if not vivos.is_empty():
			var t1 := Time.get_ticks_usec()
			m.dica(m.pessoas_visiveis()[0]["id"])
			print("  (%.1f ms na primeira consulta da hora seguinte)" % ((Time.get_ticks_usec() - t1) / 1000.0))
		_repeticao(m)
	print("\n%d dicas impressas, %d falhas" % [impressas, falhas])
	quit(1 if falhas > 0 else 0)


func _conferir(d: Dictionary, f: Dictionary, m) -> void:
	if d.is_empty() or String(d["fazendo"]).is_empty() or String(d["humor"]).is_empty():
		_falha("dica vazia: %s %s" % [f["nome"], str(d)])
		return
	if String(d["pensamento"]).length() > 60:
		_falha("pensamento longo: " + d["pensamento"])
	if f["acao"] == "dormir" and not d["humor"] in ["dormindo", "sono leve", "inquieto no sono", "inquieta no sono"]:
		_falha("dormindo com humor acordado: %s" % d["humor"])
	if d["pensamento"].is_empty() and f["acao"] != "dormir" and m.grupo(f["grupo"]).membros.size() <= 40:
		_falha("sem pensamento acordado: %s" % f["nome"])
	for w in PROIBIDAS:
		if (d["pensamento"] + " " + d["fazendo"]).contains(w):
			_falha("fala do jogador: " + d["pensamento"])
	if "{" in d["pensamento"] or "{" in d["fazendo"]:
		_falha("modelo sem preencher: %s / %s" % [d["fazendo"], d["pensamento"]])


## A mesma pessoa acordada, 8 horas seguidas (dia): não pode ficar com a mesma frase o tempo todo
## (em povos de até 40 pessoas; nos maiores, as frases livres acabam e alguns ficam com a mesma).
func _repeticao(m) -> void:
	var frases := {}
	for i in 8:
		for f in m.pessoas_visiveis():
			if f["acao"] == "dormir" or m.grupo(f["grupo"]).membros.size() > 40:
				continue
			var d: Dictionary = m.dica(f["id"])
			if not frases.has(f["id"]):
				frases[f["id"]] = {}
			frases[f["id"]][d["pensamento"]] = frases[f["id"]].get(d["pensamento"], 0) + 1
		m.avancar_hora()
	for id in frases:
		var tot := 0
		for k in frases[id]:
			tot += frases[id][k]
		if tot >= 6 and frases[id].size() < 2:
			_falha("pessoa %d com a mesma frase %d horas: %s" % [id, tot, frases[id].keys()[0]])


func _falha(t: String) -> void:
	falhas += 1
	if falhas <= 30:
		print("FALHOU  ", t)

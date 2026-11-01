extends SceneTree
## Passos e consultas num mundo velho (salvo por resistencia.gd): carrega o arquivo e avança
## 2 anos como a apresentação usa o mundo (um passo e, depois, tudo o que ela lê). Antes de
## cada passo, espera as threads, como no jogo, em que há 1,9 s entre passos. Mostra os piores
## passos e consultas, o custo de salvar_async na linha principal e na thread, e o da
## montagem da rotina.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/resistencia_passos.gd -- user://resistencia/nenhum-3.txt

const Persistencia = preload("res://nucleo/persistencia.gd")
const Rotina = preload("res://nucleo/rotina.gd")


func _initialize() -> void:
	var m = Persistencia.carregar(OS.get_cmdline_user_args()[0])
	print("ano %d, %d pessoas, %d eventos" % [m.ano(), m.populacao(), m.eventos.size()])
	var t0 := Time.get_ticks_usec()
	Persistencia.salvar_async(m, "user://resistencia/_passos.txt")
	print("salvar_async na linha principal: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	Persistencia.terminar_salvamento(m)
	print("gravação na thread: %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	m.pessoas_visiveis()
	var tempos: Array = []
	for i in 960 * 2:
		m._esperar_threads()
		var q := "ano %d, dia %d, %dh" % [m.ano(), m.dia_do_ano(), m.hora()]
		t0 = Time.get_ticks_usec()
		m.avancar_hora()
		var dp := (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		m.pessoas_visiveis()
		m.cenas_ativas()
		m.construcoes()
		m.ruinas_visiveis()
		m.preces_abertas()
		m.grupos_visiveis()
		tempos.append([dp, (Time.get_ticks_usec() - t0) / 1000.0, q])
	tempos.sort_custom(func(a, b): return a[0] > b[0])
	print("piores passos (passo ms, consulta ms, quando): ", tempos.slice(0, 6))
	tempos.sort_custom(func(a, b): return a[1] > b[1])
	print("piores consultas (passo ms, consulta ms, quando): ", tempos.slice(0, 4))
	for k in 3:
		t0 = Time.get_ticks_usec()
		var ro = Rotina.new(m, m.dia_abs())
		ro.montar()
		print("montagem da rotina: %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	quit()

extends SceneTree
## Sonda de ajuste: roda sementes sem intervenção e mostra população por década
## e contagem de eventos. Uso:
##   godot --headless --path . --script res://ferramentas/sondar.gd -- 1 2 3

const Mundo = preload("res://nucleo/mundo.gd")


func _initialize() -> void:
	var sementes: Array = []
	for a in OS.get_cmdline_user_args():
		sementes.append(int(a))
	if sementes.is_empty():
		sementes = [1, 2, 3]
	for s in sementes:
		var m := Mundo.new(s)
		var t0 := Time.get_ticks_usec()
		var linha := "semente %d:" % s
		for dec in 10:
			m.avancar_dias(Mundo.DIAS_ANO * 10)
			linha += " %d/%dg" % [m.populacao(), m.grupos_vivos().size()]
		var t := (Time.get_ticks_usec() - t0) / 1e6
		print(linha, "  (%.2fs)" % t)
		var cont := {}
		for e in m.eventos:
			cont[e.tipo] = cont.get(e.tipo, 0) + 1
		var ks: Array = cont.keys()
		ks.sort()
		var txt := ""
		for k in ks:
			txt += "%s=%d " % [k, cont[k]]
		print("   ", txt)
		var primeiros := ""
		for tipo in ["crenca", "separacao", "ataque", "costume", "agricultura", "silencio", "fim_do_mundo"]:
			for e in m.eventos:
				if e.tipo == tipo:
					primeiros += "%s@%d " % [tipo, e.ano]
					break
		print("   primeiros: ", primeiros)
		for g in m.grupos:
			if OS.get_cmdline_user_args().size() > 3:
				continue
			print("   grupo %s (%d) zona=%s membros=%d est=%d deus=%s crencas=%s costumes=%d extinto=%s" % [
				g.nome, g.id, g.zona, g.membros.size(), g.estagio, g.nome_deus, str(g.crencas), g.costumes.size(), str(g.extinto)])
	quit()

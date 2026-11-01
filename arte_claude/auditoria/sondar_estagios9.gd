extends SceneTree
## Auditoria 9: o que o núcleo tem em cada mundo (povos, estágio, membros, aparência, obras por
## povo e ruínas), para comparar com a tela. Copie para jogo/ferramentas_sim/ e rode com
##   ferramentas_sim/godot.sh res://ferramentas_sim/sondar_estagios9.gd -- 3:60 3:140 3:161 3:250 3:500 7:90 7:122 7:400
## (semente:ano; o mundo anda 40 × ano + 12 dias, como o --anos e o --dias=12 da captura). Apague depois.
const Mundo = preload("res://nucleo/mundo.gd")
func _initialize() -> void:
	for sa in OS.get_cmdline_user_args():
		var p := String(sa).split(":")
		var m := Mundo.new(int(p[0]))
		m.avancar_dias(40 * int(p[1]) + 12)
		print("== semente %s ano %s" % [p[0], p[1]])
		for g in m.grupos_vivos():
			var tipos := {}
			for o in m.construcoes():
				if int(o.get("grupo", -1)) == g.id:
					var k := "%s(e%d)" % [o["tipo"], int(o.get("estagio", 0))]
					tipos[k] = tipos.get(k, 0) + 1
			print("  %s: estágio %d, %d pessoas, %s, obras %s" % [g.nome, g.estagio, g.membros.size(), JSON.stringify(g.aparencia), tipos])
		print("  ruínas: %d" % m.ruinas.size())
	quit()

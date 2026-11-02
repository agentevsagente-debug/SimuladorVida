extends SceneTree
## O custo da montagem da rotina (QA D-07) e a impressão digital do que ela produz.
## - Para 3 mundos (semente 3 no ano 250, o da D, com povos de 90 pessoas; semente 1 no ano 120;
##   semente 5 no ano 60), monta a rotina de 3 dias seguidos, na linha principal, e mede.
## - A máquina varia muito (a mesma montagem já levou de 200 ms a 1,4 s, com a CPU em outra
##   frequência ou ocupada por outras sessões). Por isso, antes de cada montagem, mede um laço fixo
##   de calibração e mostra a razão montagem / calibração, que varia bem menos.
## - HASH: o md5 das linhas e das agendas de todos. Uma otimização tem de manter o mesmo HASH.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/montagem_rotina.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Rotina = preload("res://nucleo/rotina.gd")


func _calibrar() -> float:
	var t := Time.get_ticks_usec()
	var d := {}
	var x := 0.0
	for i in 300000:
		x += sin(float(i)) * 0.5
		d[i % 997] = [x, i]
	return (Time.get_ticks_usec() - t) / 1000.0


func _initialize() -> void:
	var r: PackedStringArray = []
	for c in [[3, 250], [1, 120], [5, 60]]:
		var m := Mundo.new(c[0], [], Mundo.HORA_INICIAL, true)
		while m.ano() < c[1]:
			m.avancar_dias(Mundo.DIAS_ANO)
		print("semente %d, ano %d: %d pessoas, povos %s" % [c[0], c[1], m.populacao(), str(m.grupos_vivos().map(func(g): return g.membros.size()))])
		for k in 3:
			var cal := _calibrar()
			var ro = Rotina.new(m, m.dia_abs())
			var t := Time.get_ticks_usec()
			ro.montar()
			var ms := (Time.get_ticks_usec() - t) / 1000.0
			var ag := ""
			for pid in ro._agendas:
				for h in 24:
					ag += str(ro._agendas[pid][h])
			r.append("%d/%d/%d %d %d" % [c[0], c[1], k, hash(str(ro.linhas)), hash(ag)])
			print("  dia %d: montagem %.0f ms, calibração %.0f ms, razão %.2f" % [k, ms, cal, ms / cal])
			m.avancar_dias(1)
	print("HASH ", "|".join(r).md5_text())
	quit()

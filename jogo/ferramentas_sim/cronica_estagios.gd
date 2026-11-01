extends SceneTree
## A crônica da subida dos estágios 3 a 6: roda um mundo até algum povo chegar ao estágio 6
## (ou até o ano limite) e grava a crônica do ano do primeiro estágio 3 até 60 anos depois do
## estágio 6, e a crônica do povo que chegou lá, para ler e cortar o que soa repetido.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/cronica_estagios.gd -- <semente> [ano_limite] [saida.md]

const Mundo = preload("res://nucleo/mundo.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var semente := int(args[0]) if args.size() > 0 else 1
	var limite := int(args[1]) if args.size() > 1 else 1000
	var saida: String = args[2] if args.size() > 2 else "user://cronica_estagios_%d.md" % semente
	var m := Mundo.new(semente)
	var primeiro := {}   # estágio -> [ano, grupo]
	var visto := 0
	var depois := -1
	while m.ano() < limite:
		m.avancar_dias(Mundo.DIAS_ANO)
		for i in range(visto, m.eventos.size()):
			var e = m.eventos[i]
			if e != null and e.tipo == "estagio" and not primeiro.has(e.dados["estagio"]):
				primeiro[e.dados["estagio"]] = [e.ano, e.grupo]
		visto = m.eventos.size()
		if primeiro.has(6) and depois < 0:
			depois = m.ano() + 60
		if depois > 0 and m.ano() >= depois:
			break
		if m.fim_do_mundo:
			break
	print("semente %d: primeiros estágios %s, ano %d" % [semente, str(primeiro), m.ano()])
	if not primeiro.has(3):
		quit(1)
		return
	var ini: int = maxi(1, primeiro[3][0] - 3)
	var t := "# Semente %d: a subida dos estágios\n\nPrimeiro ano de cada estágio: %s\n\n" % [semente, str(primeiro)]
	t += m.cronica(ini, -1, false)
	var gid: int = primeiro.get(6, primeiro.get(5, primeiro.get(4, primeiro[3])))[1]
	t += "\n\n# A crônica do povo %s\n\n" % m.grupo(gid).nome + m.cronica_do_povo(gid)
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string(t)
	f.close()
	print("gravado em ", saida)
	quit()

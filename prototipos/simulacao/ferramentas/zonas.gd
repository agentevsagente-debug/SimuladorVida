extends SceneTree
## Diagnóstico: mostra onde cada grupo vive e se há seca ou fome em certos anos.
## Uso: ... --script res://ferramentas/zonas.gd -- <semente> <cenario|-> <ano> [ano...]
const Mundo = preload("res://nucleo/mundo.gd")
const Cenario = preload("res://nucleo/cenario.gd")

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var cmds: Array = [] if a[1] == "-" else Cenario.ler_arquivo(a[1])
	var m := Mundo.new(int(a[0]), cmds)
	var anos: Array = []
	for i in range(2, a.size()):
		anos.append(int(a[i]))
	for ano in anos:
		while m.ano() < ano:
			m.avancar_dias(1)
		for d in 4:
			var txt := "ano %d dia %d:" % [m.ano(), m.dia_do_ano() + 1]
			for g in m.grupos_vivos():
				txt += " %s@%s(%d%s%s)" % [g.nome, g.zona, g.membros.size(), " FOME" if g.em_fome else "", " crê" if g.tem_crenca else ""]
			txt += " seca=%s" % str(m.seca_global)
			print(txt)
			m.avancar_dias(10)
	quit()

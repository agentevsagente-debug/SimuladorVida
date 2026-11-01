extends SceneTree
## Lista as mortes dos primeiros anos de uma semente (diagnóstico).
const Mundo = preload("res://nucleo/mundo.gd")

func _initialize() -> void:
	var s := int(OS.get_cmdline_user_args()[0])
	var anos := int(OS.get_cmdline_user_args()[1])
	var m := Mundo.new(s)
	m.avancar_dias(Mundo.DIAS_ANO * anos)
	for e in m.eventos:
		if e.tipo in ["morte", "fome_inicio", "fome_fim", "inverno_rigoroso", "seca_inicio", "doenca_inicio", "nascimento"]:
			print(e.ano, " d", e.dia, " ", e.tipo, " ", e.dados)
	quit()

extends SceneTree
## Usado por testar_persistencia.gd: salva o mesmo mundo sem parar, de forma assíncrona,
## até ser morto. Serve para testar que uma gravação interrompida no meio nunca estraga.
## Uso: ... --script res://ferramentas_sim/gravar_sem_parar.gd -- <caminho>

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")


func _initialize() -> void:
	var caminho: String = OS.get_cmdline_user_args()[0]
	var m := Mundo.new(2, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(40 * 60)
	print("PRONTO")
	for i in 400:
		m.avancar_hora()
		Persistencia.salvar_async(m, caminho)
		Persistencia.terminar_salvamento(m)
	quit()

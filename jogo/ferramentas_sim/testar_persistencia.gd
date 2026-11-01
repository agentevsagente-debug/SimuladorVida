extends SceneTree
## Salvar, carregar e ausência: o mundo carregado precisa seguir igual ao que nunca parou.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_persistencia.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const CAMINHO := "user://teste_mundo.txt"

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)


func _initialize() -> void:
	var cmds := preload("res://nucleo/cenario.gd").ler_arquivo("res://ferramentas_sim/cenarios/semente1-intervencoes.txt")
	var continuo := Mundo.new(1, cmds)
	continuo.avancar_dias(40 * 100)
	var a := Mundo.new(1, cmds)
	a.avancar_dias(40 * 37 + 13)
	for i in 7:
		a.avancar_hora()
	a.usar_poder("chuva", 150.0, 0.6)   # um gesto antes de salvar entra no estado salvo
	continuo = Mundo.new(1, cmds)
	continuo.avancar_dias(40 * 37 + 13)
	for i in 7:
		continuo.avancar_hora()
	continuo.usar_poder("chuva", 150.0, 0.6)
	var t := Time.get_ticks_usec()
	conferir(Persistencia.salvar(a, CAMINHO), "salvar")
	var t_salvar := (Time.get_ticks_usec() - t) / 1000.0
	t = Time.get_ticks_usec()
	var b = Persistencia.carregar(CAMINHO)
	var t_carregar := (Time.get_ticks_usec() - t) / 1000.0
	conferir(b != null, "carregar")
	var tam := FileAccess.open(CAMINHO, FileAccess.READ).get_length()
	print("salvar: %.0f ms, carregar: %.0f ms, arquivo: %d KB, ano %d" % [t_salvar, t_carregar, tam / 1024, a.ano()])
	conferir(var_to_str(Persistencia._para_dict(a)) == var_to_str(Persistencia._para_dict(b)), "estado igual depois de carregar")
	conferir(str(a.pessoas_visiveis()) == str(b.pessoas_visiveis()), "mesma cena depois de carregar")
	b.avancar_dias(40 * 63)
	continuo.avancar_dias(40 * 63)
	var ca: String = continuo.cronica_completa("x", "y")
	var cb: String = b.cronica_completa("x", "y")
	conferir(ca == cb, "mesma crônica de 100 anos com e sem salvar no meio")
	print("crônica: %d caracteres; pessoas no fim: %d e %d" % [ca.length(), continuo.populacao(), b.populacao()])
	# Ausência.
	var r = Persistencia.carregar_e_avancar(CAMINHO, a.salvo_em + 16 * 3600)
	var aus: Dictionary = r["ausencia"]
	print("noite fechada (16 h): %d passos, de %s a %s, %d chamados" % [aus["passos"], aus["de"], aus["ate"], aus["chamados"].size()])
	conferir(aus["passos"] == 512, "16 horas são 512 passos")
	print(aus["relato"])
	r = Persistencia.carregar_e_avancar(CAMINHO, a.salvo_em + 30 * 24 * 3600)
	aus = r["ausencia"]
	conferir(aus["passos"] == 960 and aus["teto_atingido"], "férias param no teto de um ano")
	print("férias (30 dias): %d passos, teto=%s" % [aus["passos"], aus["teto_atingido"]])
	print("--- relato das férias ---")
	print(aus["relato"])
	conferir(Persistencia.carregar("user://nao_existe.txt") == null, "arquivo ausente devolve null")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO))
	print("%d falhas" % falhas)
	quit()

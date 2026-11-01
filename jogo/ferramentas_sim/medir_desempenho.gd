extends SceneTree
## Desempenho com população grande, no estágio 6.
## Passo 1 (gerar): procura, entre algumas sementes, o mundo de maior população com um povo
## no estágio 6, e salva em user://desempenho.txt.
## Passo 2 (medir), em outro processo: carrega esse mundo e mede quanto custa 1 ano de jogo
## (e uma consulta completa da apresentação). Rodar em processo novo evita medir uma máquina
## já cansada por minutos de cálculo.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/medir_desempenho.gd -- gerar
##      ferramentas_sim/godot.sh res://ferramentas_sim/medir_desempenho.gd -- medir

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const CAMINHO := "user://desempenho.txt"


func _initialize() -> void:
	if OS.get_cmdline_user_args()[0] == "gerar":
		var melhor := 0
		for semente in [1, 2, 3, 4, 7, 9]:
			var m := Mundo.new(semente)
			for a in 300:
				m.avancar_dias(Mundo.DIAS_ANO)
				var est6 := false
				for g in m.grupos_vivos():
					est6 = est6 or g.estagio >= 6
				if est6 and m.populacao() > melhor:
					Persistencia.salvar(m, CAMINHO)
					melhor = m.populacao()
					print("semente %d ano %d: %d pessoas" % [semente, m.ano(), m.populacao()])
		quit()
		return
	var w = Persistencia.carregar(CAMINHO)
	var est := 0
	for g in w.grupos_vivos():
		est = maxi(est, g.estagio)
	print("mundo: ano %d, %d pessoas em %d povos, estágio máximo %d, %d eventos" % [w.ano(), w.populacao(), w.grupos_vivos().size(), est, w.eventos.size()])
	for i in 3:
		var t := Time.get_ticks_usec()
		w.avancar_dias(Mundo.DIAS_ANO)
		print("1 ano de jogo: %.3f s (agora %d pessoas)" % [(Time.get_ticks_usec() - t) / 1e6, w.populacao()])
	var t2 := Time.get_ticks_usec()
	for i in 10:
		w.pessoas_visiveis()
		w.construcoes()
		w.preces_abertas()
	print("consulta completa da apresentação: %.2f ms" % [(Time.get_ticks_usec() - t2) / 10000.0])
	quit()

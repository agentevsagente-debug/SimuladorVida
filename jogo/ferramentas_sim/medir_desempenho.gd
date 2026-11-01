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
	# Consulta completa por passo: avança uma hora e pergunta tudo o que a moldura usa.
	var primeira := 0.0
	var repetida := 0.0
	var pior := 0.0
	var dia_soma := 0.0
	var dia_pior := 0.0
	var dia_n := 0
	for h in 48:
		w.avancar_hora()
		var t2 := Time.get_ticks_usec()
		w.pessoas_visiveis()
		w.cenas_ativas()
		w.construcoes()
		w.preces_abertas()
		var dt := (Time.get_ticks_usec() - t2) / 1000.0
		primeira += dt
		pior = maxf(pior, dt)
		if w.hora() >= 5:
			dia_soma += dt
			dia_pior = maxf(dia_pior, dt)
			dia_n += 1
		var t3 := Time.get_ticks_usec()
		w.pessoas_visiveis()
		w.cenas_ativas()
		w.construcoes()
		w.preces_abertas()
		repetida += (Time.get_ticks_usec() - t3) / 1000.0
	print("consulta completa por passo (%d pessoas): média %.2f ms, pior %.2f ms; repetida na mesma hora %.2f ms" % [
		w.populacao(), primeira / 48.0, pior, repetida / 48.0])
	print("   das 5h à meia-noite: média %.2f ms, pior %.2f ms; da meia-noite às 5h (montagem dos planos do dia): o resto" % [
		dia_soma / maxi(1, dia_n), dia_pior])
	quit()

extends SceneTree
## O ciclo completo: a semente 2 chega ao fim do mundo (ano 137); 10 anos depois, o jogador
## cria um povo novo, que encontra as ruínas. Confere o livro fechado, a era nova, o que o
## povo novo fez e se o mundo salvo e carregado depois do fim dá a mesma crônica. Grava a
## crônica do fim ao recomeço em resistencia/ciclo-semente-2.md.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/resistencia_ciclo.gd
const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
func _initialize() -> void:
	var m := Mundo.new(2, [], Mundo.HORA_INICIAL, true)
	var criado := -1
	while m.ano() < 200:
		m.avancar_dias(Mundo.DIAS_ANO)
		if m.fim_do_mundo and criado < 0 and m.ano() - m.livros[-1]["ano_fim"] >= 10:
			m.criar_povo(260.0)
			criado = m.ano()
	print("fim do mundo no ano ", m.livros[0]["ano_fim"], "; livro: ", m.livros[0]["titulo"], " (", m.livros[0]["texto"].length(), " caracteres)")
	print("povo novo no ano ", criado, "; era ", m.era, "; ruínas visíveis: ", m.ruinas_visiveis().size())
	var cont := {}
	for e in m.eventos:
		if e.ano >= criado and e.tipo in ["ruinas_saber", "ruinas_mito", "ruinas", "agricultura", "estagio", "crenca"]:
			cont[e.tipo] = cont.get(e.tipo, 0) + 1
	print("depois do povo novo: ", cont)
	var ok := Persistencia.salvar(m, "user://resistencia/_ciclo.txt")
	var c = Persistencia.carregar("user://resistencia/_ciclo.txt")
	print("salvo e carregado depois do fim: ", ok and c != null and c.cronica(100) == m.cronica(100))
	var f := FileAccess.open("res://ferramentas_sim/resistencia/ciclo-semente-2.md", FileAccess.WRITE)
	f.store_string(m.cronica(m.livros[0]["ano_fim"] - 8, criado + 25, false))
	f.close()
	quit()

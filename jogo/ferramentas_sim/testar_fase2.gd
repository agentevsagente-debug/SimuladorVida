extends SceneTree
## Testa a fase 2 do núcleo: estágios, construções, ruínas, cultura, crônica do povo,
## fim do mundo, povo novo, eras, estante e abandono.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_fase2.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Estante = preload("res://nucleo/estante.gd")
## A estante do mundo de teste (nunca a do jogador, user://estante).
const PASTA := "user://teste_fase2.estante"

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	print(("ok      " if cond else "FALHOU  ") + msg)
	if not cond:
		falhas += 1


func _initialize() -> void:
	_limpar_estante()
	_mundo_novo_vazio()
	# Estágios e construções: procura uma semente em que algum povo chegue à escrita.
	var m: Mundo
	var maior := 0
	var escritor := -1
	for semente in range(5, 25):
		m = Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
		m.avancar_dias(40 * 100)
		maior = 0
		for g in m.grupos_vivos():
			maior = maxi(maior, g.estagio)
			if g.escrita_desde >= 0 and g.escrita_desde < m.ultimo_ano_na_cronica() - 3:
				escritor = g.id
		if escritor >= 0:
			print("   semente %d: um povo escreve" % semente)
			break
	conferir(maior >= 4, "algum povo passou do estágio 3 (maior: %d)" % maior)
	var tipos := {}
	for o in m.construcoes():
		tipos[o["tipo"]] = true
		if not (o.has("estagio") and o.has("ruina")):
			conferir(false, "construção sem estágio ou ruína: %s" % o)
	print("   tipos de construção: ", tipos.keys())
	print("   ruínas: ", m.ruinas_visiveis().size(), " ", m.ruinas_visiveis().slice(0, 2))
	var gv: Array = m.grupos_visiveis()
	conferir(gv[0]["cultura"].size() == 6, "6 dimensões culturais: %s" % gv[0]["cultura"])
	conferir(gv[0]["aparencia"].has("telhado"), "aparência: %s" % gv[0]["aparencia"])
	if escritor >= 0:
		var cp := m.cronica_do_povo(escritor)
		conferir(not cp.is_empty(), "um povo que escreve tem a própria crônica")
		print(cp.substr(0, 700))
	# Fim do mundo: todos morrem.
	var w := Mundo.new(2, [], Mundo.HORA_INICIAL, true)
	w.avancar_dias(40 * 20)
	for g in w.grupos_vivos():
		for id in g.membros.duplicate():
			w._morrer(w.pessoas[id], "doenca")
	w.avancar_dias(2)
	conferir(w.fim_do_mundo, "mundo vazio depois que todos morrem")
	conferir(w.livros.size() == 1 and w.livros[0]["titulo"].begins_with("A Primeira Era: "), "a crônica fechou como livro: " + (w.livros[0]["titulo"] if not w.livros.is_empty() else ""))
	conferir(not w.livros.is_empty() and w.livros[0]["texto"].contains("## Em resumo") and w.livros[0]["texto"].contains("## Capítulo I") and w.livros[0]["texto"].contains("*Aqui termina"), "o livro tem resumo, capítulos e epitáfio")
	conferir(w.usar_poder("chuva", 200.0, 0.8)["ok"] == false, "sem povo, o deus não age sobre ninguém")
	var n_ruinas := w.ruinas_visiveis().size()
	conferir(n_ruinas > 0, "o povo extinto deixou %d ruínas" % n_ruinas)
	w.avancar_dias(40 * 3)
	var r := w.criar_povo(260.0)
	conferir(r["ok"] and w.era == 2 and w.populacao() == 12, "criar_povo com o mundo vazio: %s" % r)
	conferir(not w.criar_povo(260.0)["ok"], "criar_povo recusa com o mundo habitado")
	w.avancar_dias(40 * 15)
	var cr := w.cronica()
	conferir(cr.contains("Depois que a primeira era terminou"), "a nova crônica começa pela nova era")
	conferir(w.eventos_desde(0).filter(func(e): return e["tipo"] == "mito_ruinas").size() > 0, "o novo povo explicou as ruínas")
	print(cr.substr(0, 900))
	# Estante: salvar leva o livro; abandonar fecha a segunda era e apaga o mundo.
	Persistencia.salvar(w, "user://teste_fase2.txt")
	conferir(Estante.livros(PASTA).size() == 1, "o livro da Primeira Era foi para a estante")
	var w2 = Persistencia.carregar("user://teste_fase2.txt")
	conferir(w2.era == 2 and w2.livros.size() == 1, "era e livros sobrevivem a salvar e carregar")
	Persistencia.abandonar(w2, "user://teste_fase2.txt")
	var est := Estante.livros(PASTA)
	conferir(est.size() == 2 and est[1]["titulo"].begins_with("A Segunda Era"), "abandonar guarda a Segunda Era: %s" % [str(est.map(func(l): return l["titulo"]))])
	conferir(not FileAccess.file_exists("user://teste_fase2.txt"), "abandonar apaga o mundo salvo")
	conferir(Estante.ler(est[0]["id"], PASTA).begins_with("# A Primeira Era"), "o livro pode ser lido da estante")
	_limpar_estante()
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


func _limpar_estante() -> void:
	var dir := DirAccess.open(PASTA)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)


## D-09 do QA: o mundo novo começa vazio, de manhã; o primeiro gesto é criar o povo, como no
## recomeço depois de uma extinção.
func _mundo_novo_vazio() -> void:
	var m := Mundo.new(3)
	conferir(m.populacao() == 0 and m.grupos_vivos().is_empty() and m.fim_do_mundo and m.tempo()["hora"] == 7,
		"o mundo novo começa vazio, às 7h (população %d, hora %d)" % [m.populacao(), m.tempo()["hora"]])
	conferir(m.eventos_desde(0).is_empty() and m.livros.is_empty(), "o mundo vazio do começo não tem fim do mundo nem livro")
	conferir(not m.usar_poder("chuva", 260.0, 0.8)["ok"], "no mundo novo vazio, os poderes sobre o povo recusam")
	conferir(m.abandonar().is_empty(), "abandonar o mundo antes do primeiro povo não fecha livro")
	m.avancar_dias(2)
	var r := m.criar_povo(260.0)
	conferir(r["ok"] and m.era == 1 and m.populacao() == 12 and not m.fim_do_mundo and m.tempo()["hora"] == 7,
		"criar o primeiro povo: era 1, 12 pessoas, às 7h (%s)" % r)
	conferir(m.eventos_desde(0).any(func(e): return e["tipo"] == "inicio"), "o primeiro povo tem o evento de início")
	conferir(m.grupos_vivos()[0].zona == "floresta", "o gesto em x 260 põe o povo na floresta")
	m.avancar_dias(Mundo.DIAS_ANO * 3)
	conferir(m.populacao() > 0 and m.cronica_viva().contains("Ano 1"), "o primeiro povo vive, e a crônica conta desde o ano 1")
	# Começo e recomeço funcionam igual: o mesmo mundo, salvo vazio e carregado, cria o povo.
	var v := Mundo.new(4)
	Persistencia.salvar(v, "user://teste_fase2_vazio.txt")
	var c = Persistencia.carregar("user://teste_fase2_vazio.txt")
	conferir(c != null and c.fim_do_mundo and c.populacao() == 0 and c.criar_povo(400.0)["ok"] and c.era == 1,
		"o mundo vazio salvo e carregado cria o primeiro povo")

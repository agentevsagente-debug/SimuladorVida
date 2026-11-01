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
	_apagar_com_copias(CAMINHO)
	_testar_copias()
	_testar_estante()
	_testar_async()
	_testar_interrompido()
	print("%d falhas" % falhas)
	quit()


const Arquivo = preload("res://nucleo/arquivo.gd")
const Estante = preload("res://nucleo/estante.gd")


func _apagar_com_copias(caminho: String) -> void:
	for c in [caminho, caminho + ".novo", Arquivo.copia(caminho, 1), Arquivo.copia(caminho, 2), Arquivo.copia(caminho, 3),
			Arquivo.copia(caminho, 4)]:
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(c))


func _estragar(caminho: String, como: String) -> void:
	var t := FileAccess.get_file_as_string(caminho)
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	match como:
		"cortado":   # um salvamento interrompido no meio
			f.store_string(t.substr(0, t.length() / 2))
		"lixo":
			f.store_string("lixo que nao e um mundo {[(")
		"vazio":
			pass
		"mexido":   # um pedaço trocado no meio: o texto ainda é lido, mas falta o que importa
			f.store_string(t.replace("\"eventos\"", "\"evento\""))
	f.close()


## Cópias de segurança do mundo salvo: 3 versões anteriores, e o carregar recorre a elas.
func _testar_copias() -> void:
	var m := Mundo.new(3)
	var estados: Array = []
	for i in 5:
		m.avancar_dias(7)
		Persistencia.salvar(m, CAMINHO)
		estados.append(m.rng.state)
	conferir(FileAccess.file_exists(Arquivo.copia(CAMINHO, 3)) and not FileAccess.file_exists(Arquivo.copia(CAMINHO, 4)),
		"cópias: guarda as 3 versões anteriores, e só 3")
	var b = Persistencia.carregar(CAMINHO)
	conferir(b != null and b.rng.state == estados[4] and b.recuperado_de == "", "cópias: o arquivo bom é o que vale")
	var casos := [["cortado", 1], ["lixo", 2], ["vazio", 3], ["mexido", 1]]
	for caso in casos:
		# Estraga o principal e as cópias mais novas que a esperada.
		_testar_um(caso[0], caso[1], estados)
	# Tudo estragado: null, sem quebrar.
	for c in [CAMINHO, Arquivo.copia(CAMINHO, 1), Arquivo.copia(CAMINHO, 2), Arquivo.copia(CAMINHO, 3)]:
		_estragar(c, "lixo")
	conferir(Persistencia.carregar(CAMINHO) == null, "cópias: tudo estragado devolve null")
	# O retorno conta a recuperação.
	Persistencia.salvar(m, CAMINHO)
	m.avancar_dias(1)
	Persistencia.salvar(m, CAMINHO)
	_estragar(CAMINHO, "cortado")
	var r = Persistencia.carregar_e_avancar(CAMINHO, int(Time.get_unix_time_from_system()) + 3600)
	conferir(r != null and r["ausencia"].get("recuperado_de", "") == Arquivo.copia(CAMINHO, 1)
		and r["ausencia"]["relato"].begins_with("*O mundo salvo estava estragado."), "cópias: o retorno conta que o mundo voltou de uma cópia")
	# Abandonar leva as cópias junto.
	Persistencia.abandonar(Persistencia.carregar(CAMINHO), CAMINHO)
	conferir(not Persistencia.existe(CAMINHO), "cópias: abandonar apaga o mundo e as cópias")
	_apagar_com_copias(CAMINHO)


func _testar_um(como: String, esperada: int, estados: Array) -> void:
	# Refaz os 4 arquivos (principal + 3 cópias) a partir dos estados salvos de novo.
	_apagar_com_copias(CAMINHO)
	var m := Mundo.new(3)
	var st: Array = []
	for i in 4:
		m.avancar_dias(7)
		Persistencia.salvar(m, CAMINHO)
		st.append(m.rng.state)
	_estragar(CAMINHO, como)
	for n in range(1, esperada):
		_estragar(Arquivo.copia(CAMINHO, n), como)
	var b = Persistencia.carregar(CAMINHO)
	conferir(b != null and b.recuperado_de == Arquivo.copia(CAMINHO, esperada) and b.rng.state == st[3 - esperada],
		"cópias: arquivo %s volta da cópia %d" % [como, esperada])


## A estante também tem cópias: de cada livro e do índice.
func _testar_estante() -> void:
	var pasta := "user://teste_estante"
	_apagar_pasta(pasta)
	for i in 3:
		Estante.guardar({"texto": "# Livro %d\n\nTexto do livro %d." % [i, i], "titulo": "Livro %d" % i, "era": i + 1,
			"semente": 9, "ano_ini": 1, "ano_fim": 10}, pasta)
	var lista := Estante.livros(pasta)
	conferir(lista.size() == 3, "estante: 3 livros")
	_estragar(pasta + "/indice.txt", "cortado")
	conferir(Estante.livros(pasta).size() == 2, "estante: índice estragado volta da cópia (a de antes do 3º livro)")
	for c in [pasta + "/indice.txt"] + range(1, 4).map(func(n): return Arquivo.copia(pasta + "/indice.txt", n)):
		_estragar(c, "lixo")
	var refeito := Estante.livros(pasta)
	conferir(refeito.size() == 3 and refeito[2]["titulo"] == "Livro 2", "estante: sem índice, ele é refeito dos livros")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pasta + "/" + lista[1]["id"] + ".md"))
	conferir(Estante.ler(lista[1]["id"], pasta).begins_with("# Livro 1"), "estante: livro apagado volta da cópia")
	_estragar(pasta + "/" + lista[0]["id"] + ".md", "vazio")
	conferir(Estante.ler(lista[0]["id"], pasta).begins_with("# Livro 0"), "estante: livro vazio volta da cópia")
	_apagar_pasta(pasta)


func _apagar_pasta(pasta: String) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pasta))


## Salvar numa thread: o arquivo é o mesmo do salvar síncrono, e o passo seguinte espera a
## gravação acabar (o arquivo é o retrato de antes do passo).
func _testar_async() -> void:
	var m := Mundo.new(4)
	m.avancar_dias(40 * 30)
	Persistencia.salvar(m, CAMINHO)
	var sinc := FileAccess.get_file_as_string(CAMINHO)
	Persistencia.salvar_async(m, CAMINHO)
	var antes: int = m.rng.state
	var passo_antes: int = m.passo
	m.avancar_hora()   # espera a gravação
	conferir(m.passo == passo_antes + 1 and Persistencia.terminar_salvamento(m), "async: gravou, e o passo esperou")
	var b = Persistencia.carregar(CAMINHO)
	conferir(b != null and b.rng.state == antes and b.passo == passo_antes, "async: o arquivo é o mundo de antes do passo")
	conferir(FileAccess.get_file_as_string(CAMINHO).length() == sinc.length(), "async: mesmo arquivo que o salvar síncrono")
	_apagar_com_copias(CAMINHO)


## Uma gravação interrompida no meio (o processo morto a qualquer momento) nunca deixa o
## mundo ilegível: vale o arquivo ou uma das cópias.
func _testar_interrompido() -> void:
	var caminho := "user://teste_interrompido.txt"
	_apagar_com_copias(caminho)
	var ok := 0
	var no_meio := 0
	for i in 6:
		var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--quit-after", "100000", "--path",
			ProjectSettings.globalize_path("res://"), "--script", "res://ferramentas_sim/gravar_sem_parar.gd", "--", caminho])
		# Espera o mundo existir e mata o processo num momento qualquer de uma gravação.
		var t := Time.get_ticks_msec()
		while not FileAccess.file_exists(caminho) and Time.get_ticks_msec() - t < 30000:
			OS.delay_msec(20)
		OS.delay_msec(150 + 137 * i)
		OS.kill(pid)
		OS.delay_msec(200)
		if FileAccess.file_exists(caminho + ".novo") or not FileAccess.file_exists(caminho):
			no_meio += 1
		var m = Persistencia.carregar(caminho)
		if m != null and m.populacao() > 0:
			ok += 1
	print("gravação interrompida: o mundo carregou %d de 6 vezes; %d mortes deixaram um arquivo pela metade" % [ok, no_meio])
	conferir(ok == 6, "interrompido: depois de matar o processo no meio da gravação, o mundo carrega (%d de 6; %d mortes com um arquivo pela metade)" % [ok, no_meio])
	_apagar_com_copias(caminho)

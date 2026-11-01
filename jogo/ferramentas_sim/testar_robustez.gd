extends SceneTree
## A robustez do mundo salvo e do relógio: o jogo nunca trava nem perde o mundo.
## - O mundo salvo estragado de muitos jeitos (cortado em vários pontos, bytes trocados, vazio, só o
##   cabeçalho, lixo binário, de outra versão, apagado): carregar() volta sempre um mundo (do
##   principal ou de uma cópia, com `recuperado_de`), e o mundo carregado roda 2 dias sem erro.
## - O relógio do sistema para trás (até anos) ou pulando anos: a ausência fica entre 0 e o teto
##   de 1 ano, nunca negativa.
## - O disco cheio ao salvar (a gravação falha no meio): salvar() devolve false e o mundo salvo
##   de antes continua lá; uma gravação que falhou entre girar as cópias e trocar o arquivo
##   ainda é achada.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_robustez.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Arquivo = preload("res://nucleo/arquivo.gd")
const PASTA := "user://robustez"

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU  ", msg)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/robustez")
	var caminho := PASTA + "/mundo.txt"
	_limpar(caminho)
	var m := Mundo.new(2)
	while m.ano() < 40:
		m.avancar_dias(Mundo.DIAS_ANO)
	# Quatro gravações: o principal e as 3 cópias, cada uma um dia mais velha.
	for k in 4:
		conferir(Persistencia.salvar(m, caminho), "salvar %d" % k)
		m.avancar_dias(1)
	var bons := {}
	for c in _todos(caminho):
		bons[c] = FileAccess.get_file_as_bytes(c)
	var texto: PackedByteArray = bons[caminho]
	var n := texto.size()
	var casos := {
		"cortado em 10%": texto.slice(0, n / 10), "cortado em 50%": texto.slice(0, n / 2),
		"cortado em 90%": texto.slice(0, n * 9 / 10), "cortado no último byte": texto.slice(0, n - 2),
		"vazio": PackedByteArray(), "só o cabeçalho": texto.slice(0, texto.find(10) + 1),
		"lixo binário": _lixo(5000, 7), "outra versão": _outra_versao(texto),
	}
	for k in 8:
		casos["%d bytes trocados (%d)" % [1 + k, k]] = _trocar_bytes(texto, 1 + k, 100 + k)
	for nome in casos:
		_restaurar(bons)
		var f := FileAccess.open(caminho, FileAccess.WRITE)
		f.store_buffer(casos[nome])
		f.close()
		_conferir_carga(caminho, nome, true)
	_restaurar(bons)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	_conferir_carga(caminho, "principal apagado", true)
	# Principal bom e cópias estragadas: carrega o principal, sem aviso.
	_restaurar(bons)
	for k in range(1, Arquivo.COPIAS + 1):
		var f2 := FileAccess.open(Arquivo.copia(caminho, k), FileAccess.WRITE)
		f2.store_string("lixo")
		f2.close()
	_conferir_carga(caminho, "cópias estragadas, principal bom", false)
	# Um mundo salvo antes da soma (cabeçalho sem ela) carrega do principal.
	_restaurar(bons)
	var s := texto.get_string_from_utf8()
	var f3 := FileAccess.open(caminho, FileAccess.WRITE)
	f3.store_string(s.substr(0, s.find(Persistencia.SOMA)) + s.substr(s.find("\n")))
	f3.close()
	_conferir_carga(caminho, "salvo antes da soma", false)
	# O relógio.
	_relogio(caminho, bons)
	# O disco cheio.
	_disco_cheio(caminho, bons)
	_limpar(caminho)
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


func _conferir_carga(caminho: String, nome: String, estragado: bool) -> void:
	var t := Time.get_ticks_msec()
	var m = Persistencia.carregar(caminho)
	conferir(m != null, "%s: o mundo não carregou" % nome)
	if m == null:
		return
	conferir(not estragado or not m.recuperado_de.is_empty(), "%s: carregou sem avisar que veio de uma cópia" % nome)
	conferir(estragado or m.recuperado_de.is_empty(), "%s: avisou de cópia sem precisar" % nome)
	var pop: int = m.populacao()
	m.avancar_dias(2)
	m.pessoas_visiveis()
	m.cronica_viva()
	conferir(pop > 0 and m.populacao() > 0, "%s: o mundo carregado não roda" % nome)
	print("  %s: ok (%s, %d ms)" % [nome, m.recuperado_de.get_file() if not m.recuperado_de.is_empty() else "principal", Time.get_ticks_msec() - t])


func _relogio(caminho: String, bons: Dictionary) -> void:
	_restaurar(bons)
	var m0 = Persistencia.carregar(caminho)
	var salvo: int = m0.salvo_em
	for caso in [["para trás 1 hora", salvo - 3600], ["para trás 3 anos", salvo - 3 * 365 * 86400], ["agora mesmo", salvo],
			["16 h", salvo + 16 * 3600], ["um salto de 30 anos", salvo + 30 * 365 * 86400], ["relógio zerado (1970)", 0],
			["ano 2106", 4294967295]]:
		_restaurar(bons)
		var r = Persistencia.carregar_e_avancar(caminho, caso[1])
		conferir(r != null, "relógio %s: não carregou" % caso[0])
		if r == null:
			continue
		var passos: int = r["ausencia"]["passos"]
		conferir(passos >= 0 and passos <= Mundo.TETO_AUSENCIA, "relógio %s: ausência de %d passos" % [caso[0], passos])
		print("  relógio %s: %d passos de ausência" % [caso[0], passos])
	# Depois de uma volta do relógio, a ausência 0 não estraga nada: o mundo carregado roda e salva.
	_restaurar(bons)
	var r1 = Persistencia.carregar_e_avancar(caminho, salvo - 3 * 365 * 86400)
	r1["mundo"].avancar_dias(1)
	conferir(Persistencia.salvar(r1["mundo"], caminho), "relógio para trás: não salvou depois")
	conferir(Persistencia.carregar(caminho) != null, "relógio para trás: não carregou depois de salvar")


func _disco_cheio(caminho: String, bons: Dictionary) -> void:
	# A gravação não consegue nem abrir o arquivo novo (no lugar do .novo há uma pasta).
	_restaurar(bons)
	var m = Persistencia.carregar(caminho)
	m.avancar_dias(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho + ".novo"))
	conferir(not Persistencia.salvar(m, caminho), "disco cheio: salvar() devia falhar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho + ".novo"))
	conferir(FileAccess.get_file_as_bytes(caminho) == bons[caminho], "disco cheio: o mundo salvo de antes mudou")
	_conferir_carga(caminho, "depois do disco cheio", false)
	# A gravação escreveu o .novo e girou as cópias, mas falhou ao trocar o arquivo: o principal sumiu.
	_restaurar(bons)
	var novo_texto := FileAccess.get_file_as_bytes(caminho)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(caminho), ProjectSettings.globalize_path(caminho + ".novo"))
	var m2 = Persistencia.carregar(caminho)
	conferir(m2 != null and m2.recuperado_de.ends_with(".novo"), "troca interrompida: devia carregar o .novo (o mais recente)")
	if m2 != null:
		print("  troca interrompida: ok (%s)" % m2.recuperado_de.get_file())
	conferir(novo_texto.size() > 0, "")


func _todos(caminho: String) -> Array:
	var r: Array = [caminho]
	for k in range(1, Arquivo.COPIAS + 1):
		r.append(Arquivo.copia(caminho, k))
	return r.filter(func(c): return FileAccess.file_exists(c))


func _restaurar(bons: Dictionary) -> void:
	for c in bons:
		var f := FileAccess.open(c, FileAccess.WRITE)
		f.store_buffer(bons[c])
		f.close()


func _limpar(caminho: String) -> void:
	for c in [caminho, caminho + ".novo", Persistencia.caminho_antigos(caminho)] + range(1, Arquivo.COPIAS + 1).map(func(k): return Arquivo.copia(caminho, k)):
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(c))


func _lixo(n: int, semente: int) -> PackedByteArray:
	var r := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in n:
		r.append(rng.randi_range(0, 255))
	return r


func _trocar_bytes(t: PackedByteArray, n: int, semente: int) -> PackedByteArray:
	var r := t.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in n:
		var k := rng.randi_range(r.find(10) + 1, r.size() - 1)
		var c := r[k]
		# Trocar um algarismo por outro (o mais traiçoeiro: o texto continua válido).
		if c >= 48 and c <= 57:
			r[k] = 48 + (c - 48 + 1 + rng.randi_range(0, 8)) % 10
		else:
			r[k] = rng.randi_range(32, 126)
	return r


func _outra_versao(t: PackedByteArray) -> PackedByteArray:
	var s := t.get_string_from_utf8()
	# A versão vai como par ordenado: ["versao", 3]. A soma é refeita: o arquivo é bom, só é de outra versão.
	var i := s.find("[\"versao\", ")
	if i < 0:
		return t
	var j := s.find("]", i)
	var linhas := (s.substr(0, i) + "[\"versao\", 99" + s.substr(j)).split("\n", true, 1)
	var k := linhas[0].find(Persistencia.SOMA)
	if k >= 0:
		linhas[0] = linhas[0].substr(0, k) + Persistencia.SOMA + linhas[1].md5_text()
	return (linhas[0] + "\n" + linhas[1]).to_utf8_buffer()

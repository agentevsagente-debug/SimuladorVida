extends SceneTree
## Cenários do som da versão 0.2 (QA-188 a QA-196), escritos antes do som, pela regra de TDD.
## Abre o jogo inteiro (principal.tscn), aperta o botão e a tecla por Viewport.push_input (sem o
## mouse nem o teclado reais) e lê o AudioServer: o barramento Master e os AudioStreamPlayer da árvore.
##
## Uso (da raiz do repositório):
##   Godot_console.exe --headless --path jogo --script res://qa/som/testar_som.gd [-- --janela]
##
## Cada etapa roda num processo próprio (os argumentos do jogo valem para o processo inteiro), com
## APPDATA em %TEMP%/simvida_qa_som/<grupo>: nunca na pasta de dados do jogador. Com --janela, a
## etapa do QA-194 (minimizar fora do esconder) roda numa janela de verdade; sem ele, fica PULADO.
## O --headless força o driver de áudio Dummy: o estado dos barramentos e dos players vale, o som
## que sai e o custo de CPU não (esses ficam no QA-197, em jogo/qa/janela/rodar_janela.ps1 -Parte som).
##
## O contrato (proposto à B, revisável):
## - o botão de id "som" na alça (interface.botoes), em todas as fases, e a tecla M;
## - o som desligado = o barramento Master mudo (AudioServer.is_bus_mute), já no mesmo quadro;
## - a escolha no user://moldura.cfg, gravada ao mudar;
## - o volume inicial: o Master em -12 dB ou menos (e acima de -60 dB) com a configuração nova;
## - os players dos sons pesados no grupo "som_pesado", que o modo discreto não toca.

const MARCA := "simvida_qa_som"
const BASE_ARGS := ["--sem-foco", "--sem-atalho"]
const POVO_ARGS := ["--mundo-novo", "--com-povo", "--semente=7", "--sem-config"]
const PODERES := ["chuva", "raio", "fogo", "fartura", "erguer_terra", "sonho"]
const VOLUME_MAX := -12.0
const SILENCIO := -60.0
const RUIDO := ["RID alloc", "BUG: Unref", "PagedAlloc", "Thread object", "wait_to_finish", "~Thread", "unref (core",
	"paged_allocator", "Godot Engine v", "string_name.cpp", "thread.cpp", "leaked at exit", "ObjectDB instances"]
# etapa -> [grupo de APPDATA, argumentos do jogo]
const ETAPAS := [
	["estatico", "", []],
	["inicial", "persistir", ["--mundo-novo"]],
	["reabrir", "persistir", []],
	["reabrir2", "persistir", []],
	["ligado", "ligado", POVO_ARGS],
	["discreto", "discreto", POVO_ARGS + ["--discreto"]],
]
const NOMES := {
	"QA-188": "o jogo exportado tem driver de áudio (não o Dummy)",
	"QA-189": "o volume começa baixo",
	"QA-190": "o botão de som na alça desliga e liga na hora",
	"QA-191": "a tecla M desliga e liga na hora",
	"QA-192": "a escolha sobrevive a fechar e abrir",
	"QA-193": "escondida, o som se cala; ao mostrar, volta se estiver ligado",
	"QA-194": "minimizada fora do esconder, o som se cala",
	"QA-195": "o modo discreto não toca os sons pesados",
	"QA-196": "com o som desligado, nenhum som toca",
}

var moldura: Node
var erros: Array = []
var _logger
var _tocaram := {}        # caminho do player -> {"pesado": bool, "audivel": bool} (o que tocou desde a última limpeza)


class Captura extends Logger:
	var dono

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type != 1:  # avisos não contam
			dono.erros.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


# ---------------------------------------------------------------- o processo pai: roda as etapas

func _initialize() -> void:
	var etapa := OS.get_environment("SIMVIDA_QA_SOM")
	if etapa == "":
		_rodar_etapas()
		return
	if not OS.get_user_data_dir().contains(MARCA) and etapa != "estatico":
		print("RES QA-000 FALHOU a etapa %s não está isolada: user:// = %s" % [etapa, OS.get_user_data_dir()])
		quit(2)
		return
	_logger = Captura.new()
	_logger.dono = self
	OS.add_logger(_logger)
	call_deferred("_etapa", etapa)


func _rodar_etapas() -> void:
	var janela := OS.get_cmdline_user_args().has("--janela")
	var raiz := OS.get_environment("TEMP").path_join(MARCA)
	for g in ["persistir", "ligado", "discreto", "minimizar"]:
		_limpar(raiz.path_join(g))   # só as pastas desta bateria, em %TEMP%
	var lista := ETAPAS.duplicate()
	if janela:
		lista.append(["minimizar", "minimizar", POVO_ARGS])
	var res := {}
	for e in lista:
		var dir: String = raiz.path_join(e[1] if e[1] != "" else "estatico")
		DirAccess.make_dir_recursive_absolute(dir)
		OS.set_environment("APPDATA", dir)
		OS.set_environment("SIMVIDA_QA_SOM", e[0])
		var a := ["--path", ProjectSettings.globalize_path("res://"), "--script", "res://qa/som/testar_som.gd", "--"]
		if e[0] != "minimizar":
			a.insert(0, "--headless")
		a.append_array(BASE_ARGS + e[2])
		var saida: Array = []
		var t0 := Time.get_ticks_msec()
		OS.execute(OS.get_executable_path(), a, saida, true)
		print("[etapa %s] %.1f s" % [e[0], (Time.get_ticks_msec() - t0) / 1000.0])
		for bloco in saida:
			for linha in _de_cp1252(str(bloco)).split("\n"):
				if linha.begins_with("RES "):
					var p := linha.split(" ", false, 3)
					var id := p[1]
					var antes: String = res.get(id, {}).get("estado", "")
					var estado := p[2]
					if antes == "FALHOU" or (antes == "PASSOU" and estado == "PULADO"):
						estado = antes
					if not res.has(id):
						res[id] = {"notas": []}
					res[id]["estado"] = estado
					res[id]["notas"].append("[%s] %s %s" % [e[0], p[2], p[3] if p.size() > 3 else ""])
				elif linha.begins_with("[som-qa]"):
					print("  ", linha)
	OS.set_environment("SIMVIDA_QA_SOM", "")
	if not janela:
		res["QA-194"] = {"estado": "PULADO", "notas": ["só com --janela (a janela minimizada de verdade)"]}
	var falhas := 0
	var ids := NOMES.keys()
	ids.sort()
	for id in ids:
		var r: Dictionary = res.get(id, {"estado": "FALHOU", "notas": ["nenhuma etapa testou"]})
		if r["estado"] == "FALHOU":
			falhas += 1
		print("%s %s  %s" % [r["estado"], id, NOMES[id]])
		for n in r["notas"]:
			print("      ", n)
	var cont := {"PASSOU": 0, "FALHOU": 0, "PULADO": 0}
	for id in ids:
		cont[res.get(id, {"estado": "FALHOU"})["estado"]] += 1
	print("RESUMO som: %d passam, %d falham, %d pulados" % [cont["PASSOU"], cont["FALHOU"], cont["PULADO"]])
	quit(1 if falhas > 0 else 0)


func _limpar(pasta: String) -> void:
	if not pasta.contains(MARCA):
		return
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	for d in dir.get_directories():
		_limpar(pasta.path_join(d))
		dir.remove(d)


const CP1252 := "€\u0081‚ƒ„…†‡ˆ‰Š‹Œ\u008dŽ\u008f\u0090‘’“”•–—˜™š›œ\u009džŸ"


func _de_cp1252(s: String) -> String:
	var bytes := PackedByteArray()
	for i in s.length():
		var c := s.unicode_at(i)
		var k := CP1252.find(s[i])
		if k >= 0:
			bytes.append(0x80 + k)
		elif c < 256:
			bytes.append(c)
		else:
			return s
	return bytes.get_string_from_utf8()


# ---------------------------------------------------------------- uma etapa (processo filho)

func _res(id: String, ok: bool, texto: String) -> void:
	print("RES %s %s %s" % [id, "PASSOU" if ok else "FALHOU", texto])


func _pulado(id: String, texto: String) -> void:
	print("RES %s PULADO %s" % [id, texto])


func _etapa(etapa: String) -> void:
	if etapa == "estatico":
		_driver()
		quit(0)
		return
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	await process_frame
	match etapa:
		"inicial":
			await _inicial()
		"reabrir":
			await _reabrir(true)
		"reabrir2":
			await _reabrir(false)
		"ligado":
			await _ligado()
		"discreto":
			await _discreto()
		"minimizar":
			await _minimizar()
	if not erros.is_empty():
		print("[som-qa] erros de script na etapa %s: %s" % [etapa, erros.slice(0, 5)])
	if etapa in ["inicial", "reabrir"]:
		moldura.sair()   # o caminho de verdade do fechar (grava a configuração e sai)
	else:
		quit(0)


# QA-188: o projeto não pode usar o driver Dummy, que não toca nada (o projeto da 0.1 usa).
func _driver() -> void:
	var texto := FileAccess.get_file_as_string("res://project.godot")
	var secao := ""
	var achados := []
	for linha in texto.split("\n"):
		linha = linha.strip_edges()
		if linha.begins_with("["):
			secao = linha
		elif secao == "[audio]" and linha.begins_with("driver/driver"):
			achados.append(linha)
	var dummy := achados.filter(func(l): return l.contains("Dummy"))
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	var no_preset := preset.contains("audio/driver") and preset.contains("Dummy")
	_res("QA-188", dummy.is_empty() and not no_preset,
		"project.godot [audio]: %s%s" % [achados if not achados.is_empty() else "padrão (WASAPI)",
		"; export_presets.cfg pede o Dummy" if no_preset else ""])


func _vista() -> Node:
	return moldura.get_node_or_null("Recorte/Vista")


func _interface() -> Node:
	return moldura.get("interface")


func _master() -> int:
	return AudioServer.get_bus_index("Master")


func _mudo() -> bool:
	return AudioServer.is_bus_mute(_master())


func _db() -> float:
	return AudioServer.get_bus_volume_db(_master())


func _estado() -> String:
	return "Master mudo=%s volume=%.1f dB" % [_mudo(), _db()]


## O botão "som" na alça, ou {} se não há.
func _botao_som() -> Dictionary:
	var i := _interface()
	if i == null or i.get("botoes") == null:
		return {}
	for b in i.get("botoes"):
		if b.get("id", "") == "som":
			return b
	return {}


func _ids_da_alca() -> Array:
	var i := _interface()
	if i == null or i.get("botoes") == null:
		return []
	return i.get("botoes").map(func(b): return b.get("id", ""))


func _clicar(p: Vector2, botao := MOUSE_BUTTON_LEFT) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	root.push_input(m, true)
	for apertado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = p
		ev.global_position = p
		ev.button_index = botao
		ev.pressed = apertado
		root.push_input(ev, true)


func _tecla(k: int) -> void:
	for apertado in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = apertado
		root.push_input(ev, true)


func _apertar_botao_som() -> bool:
	var b := _botao_som()
	if b.is_empty():
		return false
	var r: Rect2i = b["rect"]
	_clicar(Vector2(r.get_center()))
	return true


func _esperar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame
		_amostrar()


# ---------------------------------------------------------------- o que está tocando

## O barramento chega mudo (ou quase em silêncio) ao Master? Segue os envios até o Master.
func _rota_calada(bus: StringName) -> bool:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		idx = _master()
	var vistos := {}
	while idx >= 0 and not vistos.has(idx):
		vistos[idx] = true
		if AudioServer.is_bus_mute(idx) or AudioServer.get_bus_volume_db(idx) <= SILENCIO:
			return true
		if idx == _master():
			return false
		var envio := AudioServer.get_bus_send(idx)
		idx = AudioServer.get_bus_index(envio) if envio != &"" else _master()
	return false


func _players(no: Node, lista: Array) -> void:
	if no is AudioStreamPlayer or no is AudioStreamPlayer2D or no is AudioStreamPlayer3D:
		lista.append(no)
	for f in no.get_children():
		_players(f, lista)


## Anota quem está tocando agora e se dá para ouvir.
func _amostrar() -> void:
	var lista := []
	_players(root, lista)
	for p in lista:
		if not p.playing:
			continue
		var audivel: bool = p.volume_db > SILENCIO and not _rota_calada(p.bus)
		var chave := str(p.get_path())
		var antes: Dictionary = _tocaram.get(chave, {"audivel": false})
		_tocaram[chave] = {"pesado": p.is_in_group("som_pesado"), "audivel": audivel or antes["audivel"]}


func _resumo_tocou() -> Dictionary:
	var r := {"tocou": 0, "audivel": 0, "pesado": 0, "pesado_audivel": 0, "nomes": []}
	for k in _tocaram:
		var t: Dictionary = _tocaram[k]
		r["tocou"] += 1
		r["nomes"].append(k.get_file())
		if t["audivel"]:
			r["audivel"] += 1
		if t["pesado"]:
			r["pesado"] += 1
			if t["audivel"]:
				r["pesado_audivel"] += 1
	return r


## Usa os seis poderes pelo gesto de verdade (escolhe, segura 2,3 s sobre alguém e solta), na
## intensidade cheia: imposição. Deixa o tempo correr entre um e outro.
func _usar_os_poderes() -> void:
	var i := _interface()
	var v := _vista()
	if i == null or v == null or v.sim == null:
		return
	for p in PODERES:
		i.set("poder", p)
		var alvo := Vector2(240, 120)
		var figuras = v.get("figuras")
		if figuras is Array and not figuras.is_empty():
			var f = figuras[randi() % figuras.size()]
			alvo = v.para_tela(Vector2(float(f.x) + float(f.largura) / 2.0, float(f.base) - 6.0)) + Vector2(0, 18)
		alvo = alvo.clamp(Vector2(4, 22), Vector2(476, 174))
		var m := InputEventMouseMotion.new()
		m.position = alvo
		m.global_position = alvo
		root.push_input(m, true)
		var ev := InputEventMouseButton.new()
		ev.position = alvo
		ev.global_position = alvo
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		root.push_input(ev, true)
		await _esperar(2.3)
		var solta := ev.duplicate()
		solta.pressed = false
		root.push_input(solta, true)
		await _esperar(1.5)
	i.set("poder", "")


# ---------------------------------------------------------------- as etapas

## Mundo novo vazio, configuração nova (a primeira abertura do jogador).
func _inicial() -> void:
	# QA-189: o volume começa baixo, ligado.
	_res("QA-189", not _mudo() and _db() <= VOLUME_MAX and _db() > SILENCIO,
		"na primeira abertura, %s (esperado: ligado, entre %.0f e %.0f dB)" % [_estado(), SILENCIO, VOLUME_MAX])
	# QA-190: o botão existe no mundo vazio; um clique cala na hora, outro devolve.
	var b := _botao_som()
	if b.is_empty():
		_res("QA-190", false, "não há botão de id \"som\" na alça do mundo vazio (há %s)" % [_ids_da_alca()])
	else:
		_apertar_botao_som()
		var calou := _mudo()
		await _esperar(0.3)
		_apertar_botao_som()
		var voltou := not _mudo()
		_res("QA-190", calou and voltou, "mundo vazio: o clique calou no mesmo quadro=%s; o segundo clique devolveu=%s" % [calou, voltou])
	# QA-191: a tecla M, a mesma coisa.
	_tecla(KEY_M)
	var calou_m := _mudo()
	await _esperar(0.3)
	_tecla(KEY_M)
	var voltou_m := not _mudo()
	_res("QA-191", calou_m and voltou_m, "M calou no mesmo quadro=%s; o segundo M devolveu=%s (%s)" % [calou_m, voltou_m, _estado()])
	# QA-193: esconder e mostrar, com o som ligado e com o som desligado.
	await _esconder_e_mostrar()
	# QA-192 (primeira parte): desliga e fecha pelo caminho de verdade; a etapa "reabrir" confere.
	_tecla(KEY_M)
	var cfg := ConfigFile.new()
	cfg.load("user://moldura.cfg")
	print("[som-qa] desligado com M antes de fechar: %s; moldura.cfg tem %s" % [_estado(), _chaves_som(cfg)])
	if not _mudo():
		_res("QA-192", false, "M não desligou o som antes de fechar: não há escolha para guardar")


func _chaves_som(cfg: ConfigFile) -> Array:
	var r := []
	for s in cfg.get_sections():
		for k in cfg.get_section_keys(s):
			if "som" in k.to_lower() or "som" in s.to_lower() or "volume" in k.to_lower():
				r.append("%s/%s=%s" % [s, k, cfg.get_value(s, k)])
	return r


func _esconder_e_mostrar() -> void:
	if not moldura.has_method("esconder"):
		_res("QA-193", false, "a moldura não tem esconder()")
		return
	var ligado_antes := not _mudo()
	moldura.esconder()
	await _esperar(2.6)   # na primeira vez, a alça avisa como voltar e só depois a janela some (2 s)
	var escondida: bool = moldura.get("escondida")
	var calou := _mudo()
	moldura.mostrar()
	await _esperar(0.3)
	var voltou := not _mudo()
	_res("QA-193", escondida and ligado_antes and calou and voltou,
		"som ligado: escondida=%s, calou ao esconder=%s, voltou ao mostrar=%s" % [escondida, calou, voltou])
	# desligado pelo jogador: esconder e mostrar não podem religar
	_tecla(KEY_M)
	var desligou := _mudo()
	moldura.esconder()
	await _esperar(0.5)
	moldura.mostrar()
	await _esperar(0.3)
	var continua := _mudo()
	_res("QA-193", desligou and continua,
		"som desligado com M: desligou=%s, continua desligado depois de esconder e mostrar=%s" % [desligou, continua])
	_tecla(KEY_M)   # volta a ligar


## Reabre o jogo na mesma pasta: a escolha tem de valer desde o primeiro quadro.
func _reabrir(espera_mudo: bool) -> void:
	var estado_inicial := _mudo()
	_res("QA-192", estado_inicial == espera_mudo,
		"ao reabrir depois de fechar com o som %s: %s no primeiro quadro" % ["desligado" if espera_mudo else "ligado", _estado()])
	if espera_mudo:
		_amostrar()
		await _esperar(1.0)
		var r := _resumo_tocou()
		_res("QA-196", r["audivel"] == 0, "ao reabrir com o som desligado, %d players audíveis no primeiro segundo" % r["audivel"])
		_tecla(KEY_M)   # religa; a etapa "reabrir2" confere que isso também ficou guardado
		await _esperar(0.3)
		print("[som-qa] religado com M antes de fechar: %s" % _estado())


## Com povo e o som ligado: os gestos tocam sons (a prova de que os testes do silêncio valem); depois,
## com o som desligado, nada se ouve.
func _ligado() -> void:
	var b := _botao_som()
	if b.is_empty():
		_res("QA-190", false, "com povo, não há botão de id \"som\" na alça (há %s)" % [_ids_da_alca()])
	await _esperar(1.0)
	_tocaram.clear()
	await _usar_os_poderes()
	await _esperar(2.0)
	var ligado := _resumo_tocou()
	print("[som-qa] som ligado, seis poderes: %s" % ligado)
	var prova: bool = ligado["audivel"] > 0
	_res("QA-196", prova, "com o som ligado, os seis poderes tocaram %d players audíveis (precisa de pelo menos 1, para o silêncio valer)" % ligado["audivel"])
	_res("QA-195", ligado["pesado_audivel"] > 0,
		"sem o modo discreto, os seis poderes tocaram %d sons pesados (grupo som_pesado; precisa de pelo menos 1, para o QA-195 valer)" % ligado["pesado_audivel"])
	# desliga pelo botão e confere "na hora": no mesmo quadro, nada audível
	var desligou := _apertar_botao_som()
	if not desligou:
		_tecla(KEY_M)
	_tocaram.clear()
	_amostrar()
	var agora := _resumo_tocou()
	_res("QA-196", _mudo() and agora["audivel"] == 0,
		"no quadro em que o som foi desligado (%s): %s, %d players audíveis" % ["botão" if desligou else "M", _estado(), agora["audivel"]])
	# os seis poderes de novo, e o tempo correndo em 50x: nada se ouve
	_tocaram.clear()
	await _usar_os_poderes()
	var v := _vista()
	if v != null and v.sim != null and v.sim.has_method("definir_ritmo"):
		v.sim.definir_ritmo(3)
	await _esperar(8.0)
	var desligado := _resumo_tocou()
	_res("QA-196", _mudo() and desligado["audivel"] == 0,
		"som desligado, seis poderes e 8 s em 50x: %d players audíveis (%s)" % [desligado["audivel"], desligado["nomes"].slice(0, 6)])


## Modo discreto ligado e o som ligado: nenhum som pesado; os outros, sim.
func _discreto() -> void:
	var v := _vista()
	var discreto: bool = v != null and v.get("modo_discreto") == true
	await _esperar(1.0)
	_tocaram.clear()
	await _usar_os_poderes()
	await _esperar(2.0)
	var r := _resumo_tocou()
	print("[som-qa] modo discreto, seis poderes: %s" % r)
	_res("QA-195", discreto and r["audivel"] > 0 and r["pesado_audivel"] == 0,
		"modo discreto=%s: %d sons audíveis, %d pesados audíveis (esperado: algum som, nenhum pesado)" % [discreto, r["audivel"], r["pesado_audivel"]])


## Só em janela: minimizar sem passar pelo esconder (a barra de tarefas, Win+D).
func _minimizar() -> void:
	await _esperar(1.0)
	var antes := not _mudo()
	get_root().mode = Window.MODE_MINIMIZED
	await _esperar(0.6)
	if get_root().mode != Window.MODE_MINIMIZED:
		_pulado("QA-194", "a janela não ficou minimizada neste ambiente")
		return
	var calou := _mudo()
	get_root().mode = Window.MODE_WINDOWED
	await _esperar(0.6)
	var voltou := not _mudo()
	_res("QA-194", antes and calou and voltou, "ligado antes=%s; minimizada, calou em 0,6 s=%s; restaurada, voltou=%s" % [antes, calou, voltou])

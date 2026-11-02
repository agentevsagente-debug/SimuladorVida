extends SceneTree
## Cenários da lupa (QA-200 a QA-205), escritos antes do botão, pela regra de TDD.
## Abre o jogo inteiro (principal.tscn), clica no botão de id "lupa" da alça por Viewport.push_input
## (sem o mouse real) e lê moldura.escala, o tamanho da janela, a dica e o user://moldura.cfg.
##
## Uso (da raiz do repositório):
##   Godot_console.exe --headless --path jogo --script res://qa/lupa/testar_lupa.gd [-- --janela]
##
## Cada etapa roda num processo próprio, com APPDATA em %TEMP%/simvida_qa_lupa/<grupo>: nunca na pasta
## de dados do jogador. Com --janela, a etapa do QA-205 (a janela nunca sai da tela) roda numa janela
## de verdade, posta pelo próprio teste nos cantos da tela; sem ele, fica PULADO. Os jogos abrem calados
## (--sem-som).
##
## O contrato (proposto à B, revisável):
## - o botão de id "lupa" na alça (interface.botoes), em todas as fases;
## - clique esquerdo sobe a escala (2 → 3 → 4 → 2), clique direito desce (4 → 3 → 2 → 4);
##   uma escala que não cabe na área útil da tela é pulada;
## - a dica do botão mostra a escala atual ("2x", "3x" ou "4x") e acompanha a mudança;
## - a escala vai para o user://moldura.cfg (moldura/escala), como a de Ctrl+2 a 4; com --sem-config, não;
## - a janela inteira fica sempre dentro da área útil de uma tela.

const MARCA := "simvida_qa_lupa"
const BASE_ARGS := ["--sem-foco", "--sem-atalho", "--sem-som"]
const RUIDO := []
const ETAPAS := [
	["inicial", "persistir", ["--mundo-novo"]],
	["reabrir", "persistir", []],
	["reabrir2", "persistir", []],
	["povo", "povo", ["--mundo-novo", "--com-povo", "--semente=7", "--sem-config"]],
]
const NOMES := {
	"QA-200": "o botão da lupa está na alça, no mundo vazio e com povo",
	"QA-201": "o clique esquerdo sobe a escala: 2x, 3x, 4x e volta a 2x",
	"QA-202": "o clique direito desce a escala: 4x, 3x, 2x e volta a 4x",
	"QA-203": "a dica da lupa mostra a escala atual",
	"QA-204": "a escala escolhida pela lupa sobrevive a fechar e abrir",
	"QA-205": "a janela nunca sai da tela ao mudar a escala",
}

var moldura: Node
var erros: Array = []
var _logger


class Captura extends Logger:
	var dono

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type != 1:
			dono.erros.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


# ---------------------------------------------------------------- o processo pai: roda as etapas

func _initialize() -> void:
	var etapa := OS.get_environment("SIMVIDA_QA_LUPA")
	if etapa == "":
		_rodar_etapas()
		return
	if not OS.get_user_data_dir().contains(MARCA):
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
	for g in ["persistir", "povo", "tela"]:
		_limpar(raiz.path_join(g))   # só as pastas desta bateria, em %TEMP%
	var lista := ETAPAS.duplicate()
	if janela:
		lista.append(["tela", "tela", ["--mundo-novo", "--com-povo", "--semente=7", "--sem-config"]])
	var res := {}
	for e in lista:
		var dir: String = raiz.path_join(e[1])
		DirAccess.make_dir_recursive_absolute(dir)
		OS.set_environment("APPDATA", dir)
		OS.set_environment("SIMVIDA_QA_LUPA", e[0])
		var a := ["--path", ProjectSettings.globalize_path("res://"), "--script", "res://qa/lupa/testar_lupa.gd", "--"]
		if e[0] != "tela":
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
				elif linha.begins_with("[lupa-qa]"):
					print("  ", linha)
	OS.set_environment("SIMVIDA_QA_LUPA", "")
	if not janela:
		res["QA-205"] = {"estado": "PULADO", "notas": ["só com --janela (precisa da tela de verdade)"]}
	var falhas := 0
	var ids := NOMES.keys()
	ids.sort()
	var cont := {"PASSOU": 0, "FALHOU": 0, "PULADO": 0}
	for id in ids:
		var r: Dictionary = res.get(id, {"estado": "FALHOU", "notas": ["nenhuma etapa testou"]})
		cont[r["estado"]] += 1
		if r["estado"] == "FALHOU":
			falhas += 1
		print("%s %s  %s" % [r["estado"], id, NOMES[id]])
		for n in r["notas"]:
			print("      ", n)
	print("RESUMO lupa: %d passam, %d falham, %d pulados" % [cont["PASSOU"], cont["FALHOU"], cont["PULADO"]])
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
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	await process_frame
	await _esperar(0.5)
	match etapa:
		"inicial":
			await _inicial()
		"reabrir":
			await _reabrir(3, 4)
		"reabrir2":
			await _reabrir(4, -1)
		"povo":
			await _povo()
		"tela":
			await _tela()
	if not erros.is_empty():
		print("[lupa-qa] erros de script na etapa %s: %s" % [etapa, erros.slice(0, 5)])
	if etapa in ["inicial", "reabrir"]:
		moldura.sair()   # o caminho de verdade do fechar (grava a configuração e sai)
	else:
		quit(0)


func _interface() -> Node:
	return moldura.get("interface")


func _escala() -> int:
	return int(moldura.get("escala"))


func _headless() -> bool:
	return DisplayServer.get_name() == "headless"


## A janela tem o tamanho da escala? (sem tela, o tamanho não muda: não confere)
func _tamanho_ok() -> bool:
	if _headless():
		return true
	return get_root().size == Vector2i(480, 178) * _escala()


func _botao_lupa() -> Dictionary:
	var i := _interface()
	if i == null or i.get("botoes") == null:
		return {}
	for b in i.get("botoes"):
		if b.get("id", "") == "lupa":
			return b
	return {}


func _ids_da_alca() -> Array:
	var i := _interface()
	if i == null or i.get("botoes") == null:
		return []
	return i.get("botoes").map(func(b): return b.get("id", ""))


func _mover(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	root.push_input(m, true)


func _clicar(p: Vector2, botao := MOUSE_BUTTON_LEFT) -> void:
	_mover(p)
	for apertado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = p
		ev.global_position = p
		ev.button_index = botao
		ev.pressed = apertado
		root.push_input(ev, true)


## Clica na lupa (o botão pode mudar de lugar quando a alça muda: procura de novo a cada vez).
func _clicar_lupa(botao := MOUSE_BUTTON_LEFT) -> bool:
	var b := _botao_lupa()
	if b.is_empty():
		return false
	_clicar(Vector2((b["rect"] as Rect2i).get_center()), botao)
	return true


func _esperar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame


## O texto da dica visível agora, ou "" se não há dica.
func _texto_da_dica() -> String:
	var i := _interface()
	if i == null:
		return ""
	var d = i.get("_dica")
	if d == null or not d.visible:
		return ""
	var linhas := []
	for l in i.get("_dica_textos"):
		if l.visible:
			linhas.append(l.text)
	return " / ".join(linhas)


func _mostra_escala(texto: String, k: int) -> bool:
	return texto.contains("%dx" % k) or texto.contains("%d×" % k) or texto.contains("%d x" % k)


## A sequência de escalas depois de cada clique (clique e um quadro de folga).
func _sequencia(botao: int, cliques: int) -> Array:
	var seq := [_escala()]
	for n in cliques:
		_clicar_lupa(botao)
		await _esperar(0.2)
		seq.append(_escala() if _tamanho_ok() else -_escala())   # negativo: a janela não acompanhou
	return seq


static func _proxima(k: int, passo: int) -> int:
	return (k - 2 + passo + 3) % 3 + 2   # 2, 3, 4 em ciclo


func _ciclo_certo(seq: Array, passo: int) -> bool:
	for n in range(1, seq.size()):
		if seq[n] != _proxima(seq[n - 1], passo):
			return false
	return true


func _ler_cfg_escala() -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load("user://moldura.cfg") != OK:
		return null
	return cfg.get_value("moldura", "escala", null)


# ---------------------------------------------------------------- as etapas

func _inicial() -> void:
	if _botao_lupa().is_empty():
		_res("QA-200", false, "não há botão de id \"lupa\" na alça do mundo vazio (há %s)" % [_ids_da_alca()])
		for id in ["QA-201", "QA-202", "QA-203", "QA-204"]:
			_res(id, false, "sem o botão da lupa")
		return
	_res("QA-200", true, "mundo vazio: a lupa está na alça")
	var subida := await _sequencia(MOUSE_BUTTON_LEFT, 3)
	_res("QA-201", _ciclo_certo(subida, 1), "três cliques esquerdos: %s (esperado: subir 2 → 3 → 4 → 2; negativo = a janela não mudou de tamanho)" % [subida])
	var descida := await _sequencia(MOUSE_BUTTON_RIGHT, 3)
	_res("QA-202", _ciclo_certo(descida, -1), "três cliques direitos: %s (esperado: descer 4 → 3 → 2 → 4)" % [descida])
	# QA-203: a dica sobre a lupa mostra a escala, e muda junto com ela
	var b := _botao_lupa()
	var centro := Vector2((b["rect"] as Rect2i).get_center())
	_mover(centro + Vector2(0, 1))
	await _esperar(0.3)
	var antes := _texto_da_dica()
	var k1 := _escala()
	_clicar_lupa()
	await _esperar(0.3)
	_mover(centro)
	await _esperar(0.3)
	var depois := _texto_da_dica()
	var k2 := _escala()
	_res("QA-203", _mostra_escala(antes, k1) and _mostra_escala(depois, k2) and k1 != k2,
		"em %dx a dica diz \"%s\"; depois do clique, em %dx, diz \"%s\"" % [k1, antes, k2, depois])
	# QA-204, primeira parte: deixa em 3x e fecha pelo caminho de verdade
	var tentativas := 0
	while _escala() != 3 and tentativas < 4:
		_clicar_lupa()
		await _esperar(0.2)
		tentativas += 1
	print("[lupa-qa] antes de fechar: %dx; moldura.cfg moldura/escala=%s" % [_escala(), _ler_cfg_escala()])
	if _escala() != 3:
		_res("QA-204", false, "a lupa não chegou a 3x antes de fechar (%dx)" % _escala())


## Reabre na mesma pasta: a escala tem de ser a que ficou. Depois deixa em `proxima` e fecha.
func _reabrir(esperada: int, proxima: int) -> void:
	_res("QA-204", _escala() == esperada and _tamanho_ok(),
		"ao reabrir depois de fechar em %dx: %dx (janela %s)" % [esperada, _escala(), get_root().size])
	if proxima > 0:
		var tentativas := 0
		while _escala() != proxima and tentativas < 4:
			_clicar_lupa()
			await _esperar(0.2)
			tentativas += 1
		print("[lupa-qa] antes de fechar: %dx" % _escala())


## Com povo e --sem-config: a lupa está lá, muda a escala e não grava nada.
func _povo() -> void:
	var tem := not _botao_lupa().is_empty()
	_res("QA-200", tem, "com povo: %s" % ("a lupa está na alça" if tem else "não há botão de id \"lupa\" (há %s)" % [_ids_da_alca()]))
	if not tem:
		return
	var seq := await _sequencia(MOUSE_BUTTON_LEFT, 2)
	_res("QA-201", _ciclo_certo(seq, 1), "com povo, dois cliques esquerdos: %s" % [seq])
	_res("QA-204", _ler_cfg_escala() == null, "com --sem-config, a lupa não grava a escala (moldura.cfg: %s)" % [_ler_cfg_escala()])


## Só em janela: a janela posta nos quatro cantos da área útil, a lupa sobe e desce; ela fica inteira na tela.
func _tela() -> void:
	if _botao_lupa().is_empty():
		_res("QA-205", false, "sem o botão da lupa")
		return
	var w := get_root()
	var area := DisplayServer.screen_get_usable_rect(w.current_screen)
	var falhas := []
	var casos := 0
	for canto in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		for botao in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			# começa em 2x, encostada no canto
			var t := 0
			while _escala() != 2 and t < 4:
				_clicar_lupa(MOUSE_BUTTON_RIGHT)
				await _esperar(0.2)
				t += 1
			w.position = Vector2i(area.position + Vector2i((Vector2(area.size - w.size) * canto).round()))
			await _esperar(0.3)
			for n in 3:
				_clicar_lupa(botao)
				await _esperar(0.3)
				casos += 1
				var janela := Rect2i(w.position, w.size)
				var dentro := false
				for i in DisplayServer.get_screen_count():
					if DisplayServer.screen_get_usable_rect(i).encloses(janela):
						dentro = true
				if not dentro:
					falhas.append("canto %s, %dx: janela %s, área %s" % [canto, _escala(), janela, area])
	_res("QA-205", falhas.is_empty(), "%d mudanças de escala nos 4 cantos; fora da tela: %s" % [casos, falhas.slice(0, 3)])

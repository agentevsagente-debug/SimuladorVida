extends SceneTree
## A caixa de preces (pedido do autor em 03/11/2026): abre o jogo inteiro (principal.tscn), clica
## por Viewport.push_input (sem o mouse real) e confere o botão, o ponto de "não lida", abrir e
## fechar, o clique que leva a vista até quem rezou, o modo discreto, a lupa em 2x/3x/4x, o
## termômetro na dica da vila e o custo de um quadro com a caixa aberta.
##
## Uso (da pasta jogo):
##   Godot_console.exe --headless --path . --script res://ferramentas/testar_preces.gd
##
## Cada etapa roda num processo próprio, com APPDATA em %TEMP%/simvida_b_preces/<etapa>: nunca na
## pasta de dados do jogador. Os jogos abrem calados (--sem-som) e com --preces-falsas (preces de
## mentira com os nomes do mundo), até o núcleo entregar o histórico.

const PrecesTela = preload("res://apresentacao/preces_tela.gd")
const MARCA := "simvida_b_preces"
const BASE_ARGS := ["--sem-foco", "--sem-atalho", "--sem-som", "--semente=7", "--anos=3"]
const ETAPAS := [
	["caixa", "cfg", ["--preces-falsas"]],
	["reabrir", "cfg", ["--preces-falsas"]],
	["discreto", "discreto", ["--preces-falsas", "--discreto", "--sem-config"]],
	["real", "real", ["--sem-config", "--anos=12"]],
]
const NOMES := {
	"P-01": "o botão da caixa de preces está na alça, logo depois da lupa",
	"P-02": "o ponto de \"não lida\" aparece quando há prece nova e some ao abrir",
	"P-03": "abrir e fechar: botão, P, Esc, botão direito e clique fora",
	"P-04": "a leitura vai para o moldura.cfg e volta ao reabrir",
	"P-05": "clicar numa prece de quem vive leva a vista até a pessoa",
	"P-06": "clicar numa prece de quem morreu avisa e não move a vista",
	"P-07": "a caixa abre e fecha no modo discreto",
	"P-08": "com a lupa em 2x, 3x e 4x, a caixa abre e o clique acerta a prece",
	"P-09": "o termômetro de fé aparece na dica da vila",
	"P-10": "sem pico no quadro com a caixa aberta (percentil 90, até 3 rodadas)",
	"P-11": "com os dados de verdade do núcleo (sem preces falsas), a caixa abre e mostra o que há",
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


func _initialize() -> void:
	var etapa := OS.get_environment("SIMVIDA_B_PRECES")
	if etapa == "":
		_rodar_etapas()
		return
	if not OS.get_user_data_dir().contains(MARCA):
		print("RES P-00 FALHOU a etapa %s não está isolada: user:// = %s" % [etapa, OS.get_user_data_dir()])
		quit(2)
		return
	_logger = Captura.new()
	_logger.dono = self
	OS.add_logger(_logger)
	call_deferred("_etapa", etapa)


func _rodar_etapas() -> void:
	var raiz := OS.get_environment("TEMP").path_join(MARCA)
	for e in ETAPAS:
		_limpar(raiz.path_join(e[1]))
	var res := {}
	for e in ETAPAS:
		var dir: String = raiz.path_join(e[1])
		DirAccess.make_dir_recursive_absolute(dir)
		OS.set_environment("APPDATA", dir)
		OS.set_environment("SIMVIDA_B_PRECES", e[0])
		var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
			"res://ferramentas/testar_preces.gd", "--"]
		a.append_array(BASE_ARGS + (["--mundo-novo", "--com-povo"] if e[0] == "caixa" else []) + e[2])
		var saida: Array = []
		var t0 := Time.get_ticks_msec()
		OS.execute(OS.get_executable_path(), a, saida, true)
		print("[etapa %s] %.1f s" % [e[0], (Time.get_ticks_msec() - t0) / 1000.0])
		for bloco in saida:
			for linha in str(bloco).split("\n"):
				if linha.begins_with("RES "):
					var p := linha.split(" ", false, 3)
					var antes: String = res.get(p[1], {}).get("estado", "")
					var estado := p[2]
					if antes == "FALHOU":
						estado = antes
					if not res.has(p[1]):
						res[p[1]] = {"notas": []}
					res[p[1]]["estado"] = estado
					res[p[1]]["notas"].append("[%s] %s %s" % [e[0], p[2], p[3] if p.size() > 3 else ""])
				elif linha.begins_with("[preces-qa]"):
					print("  ", linha)
	OS.set_environment("SIMVIDA_B_PRECES", "")
	var falhas := 0
	var ids := NOMES.keys()
	ids.sort()
	var cont := {"PASSOU": 0, "FALHOU": 0}
	for id in ids:
		var r: Dictionary = res.get(id, {"estado": "FALHOU", "notas": ["nenhuma etapa testou"]})
		cont[r["estado"]] = cont.get(r["estado"], 0) + 1
		if r["estado"] == "FALHOU":
			falhas += 1
		print("%s %s  %s" % [r["estado"], id, NOMES[id]])
		for n in r["notas"]:
			print("      ", n)
	print("RESUMO preces: %d passam, %d falham" % [cont["PASSOU"], cont["FALHOU"]])
	for e in ETAPAS:
		_limpar(raiz.path_join(e[1]))
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


# ---------------------------------------------------------------- uma etapa (processo filho)

func _res(id: String, ok: bool, texto: String) -> void:
	print("RES %s %s %s" % [id, "PASSOU" if ok else "FALHOU", texto])


func _etapa(etapa: String) -> void:
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	await process_frame
	await _esperar(1.5)  # a caixa confere as preces novas de segundo em segundo
	match etapa:
		"caixa":
			await _caixa()
		"reabrir":
			await _reabrir()
		"discreto":
			await _discreto()
		"real":
			await _real()
	if not erros.is_empty():
		print("[preces-qa] erros de script na etapa %s: %s" % [etapa, erros.slice(0, 5)])
		_res("P-03", false, "erros de script: %s" % erros.slice(0, 3))
	if etapa == "caixa":
		moldura.sair()  # o fechar de verdade: grava a configuração e o mundo
	else:
		quit(0)


func _i() -> Node:
	return moldura.get("interface")


func _caixa_tela() -> Node:
	return _i().get("_preces")


func _ids() -> Array:
	return _i().get("botoes").map(func(b): return b.get("id", ""))


func _botao(id: String) -> Dictionary:
	for b in _i().get("botoes"):
		if b.get("id", "") == id:
			return b
	return {}


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
	await process_frame


func _tecla(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	root.push_input(ev)
	await process_frame
	ev = ev.duplicate()
	ev.pressed = false
	root.push_input(ev)
	await process_frame


func _clicar_botao(id: String, botao := MOUSE_BUTTON_LEFT) -> bool:
	var b := _botao(id)
	if b.is_empty():
		return false
	await _clicar(Vector2((b["rect"] as Rect2i).get_center()), botao)
	return true


## O centro (em coordenadas da janela base, 480 × 178) da prece i na lista, se visível.
func _ponto_da_prece(i: int) -> Vector2:
	var c = _caixa_tela()
	var y: int = c.CAIXA.position.y + c.LISTA_TOPO - c._rolagem
	for k in i:
		y += int(c.preces[k]["altura"])
	return Vector2(c.CAIXA.position.x + 40, y + 5 + 18)


func _esperar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame


func _caixa() -> void:
	var ids := _ids()
	var k := ids.find("preces")
	_res("P-01", k >= 0 and k == ids.find("lupa") + 1, "alça: %s" % [ids])
	# o ponto: com preces e nada lido, o ícone com o ponto
	var b := _botao("preces")
	var com_ponto: bool = b.get("icone", "") == "caixa_preces_nova"
	var c = _caixa_tela()
	# abrir pelo botão
	await _clicar_botao("preces")
	await process_frame
	var abriu: bool = c.visible
	var sem_ponto: bool = _botao("preces").get("icone", "") == "caixa_preces"
	_res("P-02", com_ponto and sem_ponto, "antes de abrir: %s; depois: %s" % [b.get("icone", ""), _botao("preces").get("icone", "")])
	var cfg := ConfigFile.new()
	cfg.load("user://moldura.cfg")
	var lida: Dictionary = cfg.get_value("preces", "lida", {})
	var m = moldura.vista.sim.mundo
	print("[preces-qa] lida=%s passo do mundo=%d" % [lida, m.passo])
	_res("P-04", int(lida.get("passo", -1)) == int(m.passo) and int(lida.get("semente", -1)) == int(m.semente),
		"cfg [preces] lida = %s" % lida)
	# fechar: Esc
	await _tecla(KEY_ESCAPE)
	var esc: bool = not c.visible
	# P abre, botão direito fecha
	await _tecla(KEY_P)
	var p_abre: bool = c.visible
	await _clicar(Vector2(300, 100), MOUSE_BUTTON_RIGHT)
	var direito: bool = not c.visible
	# clique fora (à esquerda, no mundo) fecha
	await _tecla(KEY_P)
	await _clicar(Vector2(60, 100))
	var fora: bool = not c.visible
	# o botão de novo fecha
	await _tecla(KEY_P)
	await _clicar_botao("preces")
	var botao_fecha: bool = not c.visible
	_res("P-03", abriu and esc and p_abre and direito and fora and botao_fecha,
		"botão=%s Esc=%s P=%s direito=%s fora=%s botão fecha=%s" % [abriu, esc, p_abre, direito, fora, botao_fecha])
	# quem morreu (a prece 3 das falsas): avisa, a caixa fica, a vista não sai do lugar
	await _tecla(KEY_P)
	var morta := -1
	for i in c.preces.size():
		if not c.preces[i].get("vivo", true):
			morta = i
			break
	await _clicar(_ponto_da_prece(morta))
	var msg: String = _i().get("_mensagem")
	_res("P-06", morta >= 0 and c.visible and moldura.vista.foco < 0 and msg.contains("não vive"),
		"prece %d: caixa aberta=%s foco=%d aviso=\"%s\"" % [morta, c.visible, moldura.vista.foco, msg])
	# quem vive (a primeira): a caixa fecha, a vista vai até a pessoa
	var autor := int(c.preces[0]["autor"])
	await _clicar(_ponto_da_prece(0))
	await _esperar(0.5)
	_res("P-05", not c.visible and moldura.vista.foco == autor and moldura.vista.zoom == 2,
		"foco=%d (autor %d) zoom=%d aviso=\"%s\"" % [moldura.vista.foco, autor, moldura.vista.zoom, _i().get("_mensagem")])
	await _tecla(KEY_ESCAPE)  # o Esc devolve a vista
	await _esperar(0.3)
	print("[preces-qa] depois do Esc: foco=%d zoom=%d" % [moldura.vista.foco, moldura.vista.zoom])
	# a dica da vila: o termômetro
	var x := -1.0
	for o in moldura.vista.sim.construcoes:
		if int(o.get("grupo", -1)) >= 0:
			x = float(o["x"])
			break
	_i()._atualizar_dica(Vector2(x, 40), Vector2(x, 58))
	var dica_fe: Control = _i().get("_dica_fe")
	_res("P-09", x >= 0.0 and _i().get("_dica").visible and dica_fe.visible,
		"vila em x=%d: \"%s\", termômetro=%s" % [x, _i().get("_dica_textos")[0].text, dica_fe.visible])
	_i()._dica.visible = false
	# a lupa: 2x, 3x, 4x (sem tela, a lupa vai até 4x)
	var notas := []
	var ok := true
	for alvo in [3, 4, 2]:
		await _clicar_botao("lupa")
		await _esperar(0.2)
		await _tecla(KEY_P)
		var vivo := -1
		for i in c.preces.size():
			if c.preces[i].get("vivo", false):
				vivo = i
				break
		var aberta: bool = c.visible
		await _clicar(_ponto_da_prece(vivo))
		var foi: bool = not c.visible and moldura.vista.foco == int(c.preces[vivo]["autor"])
		ok = ok and aberta and foi and int(moldura.get("escala")) == alvo
		notas.append("%dx aberta=%s clique=%s" % [int(moldura.get("escala")), aberta, foi])
		await _tecla(KEY_ESCAPE)
	_res("P-08", ok, ", ".join(notas))
	# o quadro: o que é da caixa (o desenho, cada evento do cursor e da roda, a conferência de preces
	# novas e o abrir). O tempo total do quadro vai só como informação: com outras coisas rodando na
	# máquina, ele varia muito de uma rodada para outra. Contra a máquina ocupada, como no V-09 do
	# painel da população: o percentil 90 do desenho e do evento, a mediana de 3 aberturas e de 5
	# conferências, e até 3 rodadas antes de falhar. Os limites continuam (3, 3, 2 e 16 ms).
	var fechada := await _medir(3.0, false)
	var custos := []
	var custo_ok := false
	for rodada in 3:
		var aberturas: Array = []
		for vez in 3:
			var t0 := Time.get_ticks_usec()
			_i().alternar_preces()
			aberturas.append((Time.get_ticks_usec() - t0) / 1000.0)
			if vez < 2:
				_i().alternar_preces()
			await process_frame
		var aberta := await _medir(3.0, true)
		var conferencias: Array = []
		for vez in 5:
			var t0 := Time.get_ticks_usec()
			_i()._preces_conferir = 0.0
			_i()._conferir_preces(0.0)
			conferencias.append((Time.get_ticks_usec() - t0) / 1000.0)
		_i().alternar_preces()
		aberturas.sort()
		conferencias.sort()
		var abrir_ms: float = aberturas[1]
		var conferir: float = conferencias[2]
		print("[preces-qa] quadro inteiro (informação), fechada: média %.2f ms, máx %.2f ms; aberta: média %.2f ms, máx %.2f ms" %
			[fechada[0], fechada[1], aberta[0], aberta[1]])
		custos.append("rodada %d: desenho p90 %.2f ms (máx %.2f, %d desenhos), evento p90 %.2f ms (máx %.2f), conferir %.2f ms, abrir %.2f ms" %
			[rodada + 1, aberta[2], aberta[6], aberta[3], aberta[4], aberta[7], conferir, abrir_ms])
		print("[preces-qa] da caixa, " + custos[-1])
		if aberta[2] < 3.0 and aberta[3] > 10 and aberta[4] < 3.0 and conferir < 2.0 and abrir_ms < 16.0:
			custo_ok = true
			break
	_res("P-10", custo_ok, "; ".join(custos))


## [média e máximo do tempo de processo por quadro (ms), percentil 90 do desenho da caixa (ms), desenhos,
## percentil 90 de um evento do cursor ou da roda (ms), eventos, máximo do desenho, máximo do evento], em
## `segundos`; com `rolar`, a roda na caixa e o cursor andando sobre as preces.
func _medir(segundos: float, rolar: bool) -> Array:
	var soma := 0.0
	var n := 0
	var maximo := 0.0
	var desenhos: Array = []
	var eventos: Array = []
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	var c = _caixa_tela()
	while Time.get_ticks_msec() < fim:
		if rolar:
			var t0 := Time.get_ticks_usec()
			_mover(Vector2(200 + (n * 7) % 260, 50 + (n * 5) % 100))
			eventos.append((Time.get_ticks_usec() - t0) / 1000.0)
			if n % 3 == 0:
				var roda := InputEventMouseButton.new()
				roda.position = Vector2(300, 100)
				roda.global_position = roda.position
				roda.button_index = MOUSE_BUTTON_WHEEL_DOWN if (n / 3) % 6 < 3 else MOUSE_BUTTON_WHEEL_UP
				roda.pressed = true
				t0 = Time.get_ticks_usec()
				root.push_input(roda, true)
				eventos.append((Time.get_ticks_usec() - t0) / 1000.0)
		c.custo_desenho_us = -1
		await process_frame
		var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		if c.custo_desenho_us >= 0:
			desenhos.append(c.custo_desenho_us / 1000.0)
		if n > 2:
			soma += ms
			maximo = maxf(maximo, ms)
		n += 1
	return [soma / maxi(1, n - 3), maximo, _p90(desenhos), desenhos.size(), _p90(eventos), eventos.size(),
		desenhos.max() if not desenhos.is_empty() else 0.0, eventos.max() if not eventos.is_empty() else 0.0]


func _p90(valores: Array) -> float:
	if valores.is_empty():
		return 0.0
	var v := valores.duplicate()
	v.sort()
	return float(v[mini(v.size() - 1, int(ceil(v.size() * 0.9)) - 1)])


func _reabrir() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://moldura.cfg")
	var guardada: Dictionary = cfg.get_value("preces", "lida", {})
	var lida: Dictionary = _i().get("preces_lida")
	_res("P-04", not guardada.is_empty() and lida == guardada, "ao reabrir, a interface leu %s" % lida)


func _discreto() -> void:
	var c = _caixa_tela()
	var discreto: bool = moldura.vista.modo_discreto
	await _tecla(KEY_P)
	var abriu: bool = c.visible
	await process_frame
	await _tecla(KEY_ESCAPE)
	_res("P-07", discreto and abriu and not c.visible, "discreto=%s abriu=%s fechou=%s" % [discreto, abriu, not c.visible])


func _real() -> void:
	var c = _caixa_tela()
	var m = moldura.vista.sim.mundo
	var fonte := "núcleo" if m.has_method("preces_historico") else "preces abertas"
	await _tecla(KEY_P)
	await process_frame
	var abriu: bool = c.visible
	var n: int = c.preces.size()
	var povos: Array = c.povos.map(func(f): return "%s %s" % [f["nome"], PrecesTela.texto_da_fe(f)])
	await _tecla(KEY_ESCAPE)
	print("[preces-qa] dados de verdade (%s): %d preces, povos: %s" % [fonte, n, povos])
	_res("P-11", abriu and not c.visible and erros.is_empty(), "%s: %d preces, %d povos" % [fonte, n, povos.size()])

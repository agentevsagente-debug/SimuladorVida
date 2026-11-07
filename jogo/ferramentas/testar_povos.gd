extends SceneTree
## O painel da população (pedido do autor em 07/11/2026): abre o jogo inteiro (principal.tscn), clica
## por Viewport.push_input (sem o mouse real) e confere o botão e a dica com o total, os povos, as
## pessoas na ordem do painel, voltar e fechar, o clique que leva a vista até a pessoa, a rolagem,
## a releitura só quando a hora vira, a convivência com a caixa de preces e o custo.
##
## Uso (da pasta jogo):
##   Godot_console.exe --headless --path . --script res://ferramentas/testar_povos.gd
##
## Roda num processo próprio, com APPDATA em %TEMP%/simvida_b_povos: nunca na pasta de dados do
## jogador. O jogo abre calado (--sem-som) e sem configuração (--sem-config).

const MARCA := "simvida_b_povos"
const ARGS := ["--sem-foco", "--sem-atalho", "--sem-som", "--sem-config", "--semente=3", "--anos=80"]
const NOMES := {
	"V-01": "o botão da população está na alça, depois da caixa de preces, e a dica dá o total e a tecla",
	"V-02": "G abre os povos vivos, com o total do mundo no topo",
	"V-03": "clicar num povo lista as pessoas dele: líder, sacerdote, adultos do mais velho ao mais novo, crianças",
	"V-04": "voltar e fechar: Voltar, Esc, botão direito e clique fora",
	"V-05": "clicar numa pessoa leva a vista até ela",
	"V-06": "a roda rola uma lista longa",
	"V-07": "o painel relê a API só quando a hora vira",
	"V-08": "o painel e a caixa de preces não abrem juntos",
	"V-09": "sem pico: o desenho, os eventos e o abrir custam pouco",
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
	if OS.get_environment("SIMVIDA_B_POVOS") == "":
		_rodar()
		return
	if not OS.get_user_data_dir().contains(MARCA):
		print("RES V-00 FALHOU não está isolado: user:// = %s" % OS.get_user_data_dir())
		quit(2)
		return
	_logger = Captura.new()
	_logger.dono = self
	OS.add_logger(_logger)
	call_deferred("_etapa")


func _rodar() -> void:
	var dir := OS.get_environment("TEMP").path_join(MARCA)
	DirAccess.make_dir_recursive_absolute(dir)
	OS.set_environment("APPDATA", dir)
	OS.set_environment("SIMVIDA_B_POVOS", "1")
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
		"res://ferramentas/testar_povos.gd", "--"] + ARGS
	var saida: Array = []
	OS.execute(OS.get_executable_path(), a, saida, true)
	OS.set_environment("SIMVIDA_B_POVOS", "")
	var res := {}
	for bloco in saida:
		for linha in str(bloco).split("\n"):
			if linha.begins_with("RES "):
				var p := linha.split(" ", false, 3)
				if res.get(p[1], {}).get("estado", "") != "FALHOU":
					res[p[1]] = {"estado": p[2], "nota": p[3] if p.size() > 3 else ""}
			elif linha.begins_with("[povos-qa]"):
				print("  ", linha)
	var falhas := 0
	var ids := NOMES.keys()
	ids.sort()
	for id in ids:
		var r: Dictionary = res.get(id, {"estado": "FALHOU", "nota": "não testado"})
		falhas += 1 if r["estado"] == "FALHOU" else 0
		print("%s %s  %s\n      %s" % [r["estado"], id, NOMES[id], r["nota"]])
	print("RESUMO povos: %d passam, %d falham" % [ids.size() - falhas, falhas])
	quit(1 if falhas > 0 else 0)


func _res(id: String, ok: bool, texto: String) -> void:
	print("RES %s %s %s" % [id, "PASSOU" if ok else "FALHOU", texto])


func _i() -> Node:
	return moldura.get("interface")


func _p() -> Node:
	return _i().get("_povos")


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


## O ponto (na janela base, 480 × 178) da linha i da lista visível do painel.
func _ponto(i: int) -> Vector2:
	var c = _p()
	var h: int = c._altura_item()
	return Vector2(c.CAIXA.position.x + 40, c.CAIXA.position.y + c.LISTA_TOPO + i * h - c._rolagem + 4 + 18)


func _esperar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame


func _etapa() -> void:
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	await process_frame
	await _esperar(1.0)
	await _testes()
	if not erros.is_empty():
		_res("V-09", false, "erros de script: %s" % [erros.slice(0, 3)])
	quit(0)


func _testes() -> void:
	var m = moldura.vista.sim.mundo
	var c = _p()
	var grupos: Array = m.grupos_visiveis()
	var total := 0
	for g in grupos:
		total += int(g["membros"])
	# V-01: o botão e a dica
	var ids: Array = _i().get("botoes").map(func(b): return b.get("id", ""))
	var b := _botao("povos")
	_mover(Vector2((b["rect"] as Rect2i).get_center()) + Vector2(0, 0))
	await process_frame
	var dica: Array = _i().get("_dica_textos").filter(func(l): return l.visible).map(func(l): return l.text)
	_res("V-01", ids.find("povos") == ids.find("preces") + 1 and dica.size() >= 2 and dica[0].contains("(G)")
		and dica[1] == "%d habitantes" % total, "alça: ...%s; dica: %s" % [ids.slice(-3), dica])
	# V-02: G abre os povos
	await _tecla(KEY_G)
	_res("V-02", c.visible and c.modo == "povos" and c.total == total and c.povos.size() == grupos.size(),
		"aberto=%s total=%d (esperado %d) povos=%d (esperado %d): %s" % [c.visible, c.total, total, c.povos.size(),
		grupos.size(), c.povos.map(func(p): return "%s %d, %s" % [p["nome"], p["membros"], p["linha"]])])
	# V-03: o maior povo, pelo clique
	var maior := 0
	for k in c.povos.size():
		if c.povos[k]["membros"] > c.povos[maior]["membros"]:
			maior = k
	var gid: int = c.povos[maior]["id"]
	var membros: int = c.povos[maior]["membros"]
	await _clicar(_ponto(maior))
	var pes: Array = c.pessoas
	var ordem_ok := true
	for k in range(1, pes.size()):
		var a: Dictionary = pes[k - 1]
		var d: Dictionary = pes[k]
		if a["ordem"] > d["ordem"] or (a["ordem"] == d["ordem"] and a["idade"] < d["idade"]):
			ordem_ok = false
	var g_info: Dictionary = grupos.filter(func(g): return g["id"] == gid)[0]
	var lider_primeiro: bool = g_info["lider"] < 0 or (not pes.is_empty() and pes[0]["id"] == g_info["lider"])
	var criancas_no_fim := true
	var viu_crianca := false
	for pe in pes:
		if pe["ordem"] == 3:
			viu_crianca = true
		elif viu_crianca:
			criancas_no_fim = false
	_res("V-03", c.modo == "pessoas" and c.povo == gid and pes.size() == membros and ordem_ok and lider_primeiro
		and criancas_no_fim, "povo %d: %d pessoas (membros %d), ordem=%s, líder primeiro=%s; começo: %s" % [gid,
		pes.size(), membros, ordem_ok, lider_primeiro, pes.slice(0, 4).map(func(p): return "%s %s %d" % [p["nome"], p["papel"], p["idade"]])])
	# V-06: a roda rola (o maior povo passa da altura da lista)
	var cabe: bool = pes.size() * c.ALTURA_PESSOA <= c._altura_lista()
	await _clicar(Vector2(330, 110), MOUSE_BUTTON_WHEEL_DOWN)
	var rolou: int = c._rolagem
	await _clicar(Vector2(330, 110), MOUSE_BUTTON_WHEEL_UP)
	_res("V-06", cabe or (rolou > 0 and c._rolagem == 0), "%d pessoas; a roda desceu %d px e voltou a %d" % [pes.size(), rolou, c._rolagem])
	# V-04: Voltar, Esc, botão direito, clique fora
	await _clicar(Vector2(c.VOLTAR.get_center()) + Vector2(0, 18))
	var voltar_ok: bool = c.visible and c.modo == "povos"
	await _clicar(_ponto(0))
	await _tecla(KEY_ESCAPE)
	var esc_volta: bool = c.visible and c.modo == "povos"
	await _tecla(KEY_ESCAPE)
	var esc_fecha: bool = not c.visible
	await _tecla(KEY_G)
	await _clicar(_ponto(0))
	await _clicar(Vector2(330, 110), MOUSE_BUTTON_RIGHT)
	var direito_volta: bool = c.visible and c.modo == "povos"
	await _clicar(Vector2(330, 110), MOUSE_BUTTON_RIGHT)
	var direito_fecha: bool = not c.visible
	await _tecla(KEY_G)
	await _clicar(Vector2(60, 100))
	var fora: bool = not c.visible
	_res("V-04", voltar_ok and esc_volta and esc_fecha and direito_volta and direito_fecha and fora,
		"Voltar=%s Esc volta=%s Esc fecha=%s direito volta=%s direito fecha=%s fora=%s" % [voltar_ok, esc_volta, esc_fecha,
		direito_volta, direito_fecha, fora])
	# V-05: a pessoa
	await _tecla(KEY_G)
	await _clicar(_ponto(maior))
	var alvo: int = c.pessoas[0]["id"]
	await _clicar(_ponto(0))
	await _esperar(0.5)
	_res("V-05", not c.visible and moldura.vista.foco == alvo and moldura.vista.zoom == 2,
		"foco=%d (esperado %d) zoom=%d aviso=\"%s\"" % [moldura.vista.foco, alvo, moldura.vista.zoom, _i().get("_mensagem")])
	await _tecla(KEY_ESCAPE)
	# V-08: um ou outro
	await _tecla(KEY_G)
	await _tecla(KEY_P)
	var p_fecha_g: bool = not c.visible and _i().get("_preces").visible
	await _tecla(KEY_G)
	var g_fecha_p: bool = c.visible and not _i().get("_preces").visible
	_res("V-08", p_fecha_g and g_fecha_p, "P com o painel aberto: %s; G com a caixa aberta: %s" % [p_fecha_g, g_fecha_p])
	# V-07: relê só quando a hora vira (no ritmo 50x, uma hora a cada 2,25 s)
	var antes: int = c.cargas
	await _esperar(0.5)
	var na_mesma_hora: int = c.cargas - antes
	var passo0: int = m.passo
	moldura.vista.sim.definir_ritmo(moldura.vista.sim.Ritmo.MUITO_RAPIDO)
	var fim := Time.get_ticks_msec() + 8000
	while m.passo < passo0 + 2 and Time.get_ticks_msec() < fim:
		await process_frame
	await process_frame
	var horas: int = m.passo - passo0
	var cargas: int = c.cargas - antes
	moldura.vista.sim.definir_ritmo(moldura.vista.sim.Ritmo.NORMAL)
	_res("V-07", na_mesma_hora == 0 and horas >= 1 and cargas == horas and c.total > 0,
		"meio segundo na mesma hora: %d leituras; %d horas viradas: %d leituras" % [na_mesma_hora, horas, cargas])
	# V-09: o custo (o desenho, cada evento do cursor ou da roda, o abrir)
	await _tecla(KEY_ESCAPE)
	var abrir_ms := 0.0
	for vez in 3:
		var t0 := Time.get_ticks_usec()
		_i().alternar_povos()
		abrir_ms = maxf(abrir_ms, (Time.get_ticks_usec() - t0) / 1000.0)
		await process_frame
		if vez < 2:
			_i().alternar_povos()
	c.escolher(maior)
	var desenho := 0.0
	var evento := 0.0
	for n in 90:
		var t0 := Time.get_ticks_usec()
		_mover(Vector2(200 + (n * 7) % 260, 50 + (n * 5) % 100))
		if n % 3 == 0:
			c.rolar(11 if (n / 3) % 6 < 3 else -11)
		evento = maxf(evento, (Time.get_ticks_usec() - t0) / 1000.0)
		c.custo_desenho_us = -1
		await process_frame
		if c.custo_desenho_us >= 0:
			desenho = maxf(desenho, c.custo_desenho_us / 1000.0)
	print("[povos-qa] desenho máx %.2f ms, evento máx %.2f ms, abrir máx %.2f ms" % [desenho, evento, abrir_ms])
	_res("V-09", desenho < 3.0 and evento < 3.0 and abrir_ms < 16.0 and erros.is_empty(),
		"desenho %.2f ms, evento %.2f ms, abrir %.2f ms" % [desenho, evento, abrir_ms])

extends SceneTree
## Fuzz de entrada da sessão D: abre o jogo (principal.tscn) e injeta centenas de ações
## aleatórias, sem o mouse nem o teclado reais. São movimentos, cliques, gestos segurados,
## rodas e teclas, em pontos e momentos sorteados. Passa pelo mundo vazio, pela chegada do povo,
## pela extinção e pelo recomeço. Cada erro de script é capturado com a pilha e com o número da ação.
##
## Uso (da raiz do repositório, com APPDATA isolado; veja rodar_fuzz.ps1):
##   Godot_console.exe --path jogo --script res://qa/fuzz/fuzz_entrada.gd -- --sem-config --mundo-novo
##       --semente=7 --sem-foco --sem-atalho --fuzz-semente=1 --fuzz-acoes=800
##
## A entrada vai por Viewport.push_input, nas coordenadas da vista (480 × 178): o cursor real
## não se move. Mesma --fuzz-semente, mesmas ações na mesma ordem. O tempo do jogo segue o
## relógio, então o momento exato de cada ação pode variar uns quadros.

const TECLAS := [KEY_C, KEY_E, KEY_L, KEY_D, KEY_S, KEY_SPACE, KEY_ESCAPE, KEY_0, KEY_1, KEY_2, KEY_3,
	KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN, KEY_ENTER]
# Ficam de fora: Q (sai), H e F8 (escondem a janela e param a entrada) e Ctrl+2 a 4 (escala).

var rng := RandomNumberGenerator.new()
var acoes := 800
var passo := 0
var registro: Array = []          # as últimas ações, para o caminho até um erro
var erros: Array = []
var moldura: Node
var _espera := 0                  # quadros até a próxima ação
var _segurando := false
var _solta_em := 0
var _ponto := Vector2.ZERO
var _fase := "vazio"
var _desde_povo := 0              # ações desde que o povo nasceu
var _logger
var _teste_erro := false
var _clique_vazio := 0.03         # --fuzz-clique-vazio: a parte dos cliques no mundo vazio que passa (e cria o povo)
var _extinguir_em := -1           # --fuzz-extinguir-em=N: a extinção na ação N (para cobrir o fim e o recomeço)


class Captura extends Logger:
	var dono

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		var pilha := []
		for bt in script_backtraces:
			for i in bt.get_frame_count():
				pilha.append("%s:%d %s" % [bt.get_frame_file(i), bt.get_frame_line(i), bt.get_frame_function(i)])
		dono.call_deferred("_erro", error_type, "%s %s" % [rationale, code], "%s:%d %s" % [file, line, function], pilha)

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var semente := 1
	for a in args:
		if a.begins_with("--fuzz-semente="):
			semente = int(a.get_slice("=", 1))
		elif a.begins_with("--fuzz-acoes="):
			acoes = int(a.get_slice("=", 1))
		elif a.begins_with("--fuzz-clique-vazio="):
			_clique_vazio = float(a.get_slice("=", 1))
		elif a.begins_with("--fuzz-extinguir-em="):
			_extinguir_em = int(a.get_slice("=", 1))
		elif a == "--fuzz-teste-erro":
			_teste_erro = true   # um erro de propósito no passo 5, para provar a captura
	rng.seed = semente
	_logger = Captura.new()
	_logger.dono = self
	OS.add_logger(_logger)
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	_espera = 90   # 3 s para o jogo abrir
	print("[fuzz] semente %d, %d ações" % [semente, acoes])
	process_frame.connect(_quadro)


func _erro(tipo: int, texto: String, onde: String, pilha: Array) -> void:
	if texto.contains("[fuzz]"):
		return
	erros.append({"passo": passo, "fase": _fase, "texto": texto})
	print("[fuzz] ERRO tipo=%d no passo %d (fase %s): %s em %s" % [tipo, passo, _fase, texto, onde])
	for l in pilha:
		print("[fuzz]    ", l)
	print("[fuzz]    ações antes: ", registro.slice(-8))


func _vista():
	return moldura.get_node_or_null("Recorte/Vista")


func _atualizar_fase() -> void:
	var v = _vista()
	if v == null or v.sim == null:
		return
	var m = v.sim.mundo
	var antes := _fase
	if m.populacao() == 0:
		_fase = "vazio" if m.era == 1 and m.livros.is_empty() else "extinto"
	elif not v.recomeco.is_empty() and v._relogio - float(v.recomeco.get("ini", 0.0)) < 25.0:
		_fase = "chegada"
	else:
		_fase = "povo"
	if _fase in ["vazio", "extinto"]:
		_desde_povo = 0
	if _fase != antes:
		print("[fuzz] passo %d: fase %s → %s (era %d, %d pessoas)" % [passo, antes, _fase, m.era, m.populacao()])


func _quadro() -> void:
	# o jogo economiza quadros quando nada se move (e desenha a 20 por segundo em 1x): no fuzz, os
	# quadros vêm sem pausa, para as ações não demorarem (a lógica do jogo é a mesma)
	OS.low_processor_usage_mode = false
	Engine.max_fps = 60
	_atualizar_fase()
	if _segurando:
		if Engine.get_process_frames() >= _solta_em:
			_botao(_ponto + Vector2(rng.randf_range(-3, 3), 0), MOUSE_BUTTON_LEFT, false)
			_segurando = false
		elif rng.randf() < 0.3:
			_mover(_ponto + Vector2(rng.randf_range(-2, 2), rng.randf_range(-1, 1)))
		return
	_espera -= 1
	if _espera > 0:
		return
	if passo >= acoes:
		_fim()
		return
	passo += 1
	_espera = rng.randi_range(1, 4)
	# De vez em quando, a extinção (a mesma de --extinguir), para passar pelo fim e pelo recomeço.
	var v = _vista()
	_desde_povo += 1
	var forcada: bool = passo == _extinguir_em and v != null and v.sim.mundo.populacao() > 0
	if forcada or (_fase in ["povo", "chegada"] and _desde_povo > 80 and rng.randf() < 0.006 and v != null):
		v._extinguir(0)
		_anotar("extinguir")
		return
	if _teste_erro and passo == 5:
		var nada = null
		print(nada.grupo)
	var r := rng.randf()
	var p := Vector2(rng.randf_range(0, 480), rng.randf_range(0, 178))
	if rng.randf() < 0.35:
		p.y = rng.randf_range(0, 18)   # a faixa da alça (botões, poderes, relógio)
	# No mundo vazio (o lugar do erro visto pela B), o clique no mundo cria o povo: só deixa passar
	# uma parte deles (3%, ou --fuzz-clique-vazio), para ficar muitas ações no vazio.
	if _fase in ["vazio", "extinto"] and p.y > 18 and r >= 0.40 and r < 0.81 and rng.randf() > _clique_vazio:
		r = 0.0
	if r < 0.40:
		_mover(p)
		_anotar("mover %d,%d" % [p.x, p.y])
	elif r < 0.62:
		var b := MOUSE_BUTTON_LEFT if rng.randf() < 0.85 else MOUSE_BUTTON_RIGHT
		_mover(p)
		_botao(p, b, true)
		_botao(p, b, false)
		_anotar("clique%s %d,%d" % ["" if b == MOUSE_BUTTON_LEFT else "-dir", p.x, p.y])
	elif r < 0.72:
		_mover(p)
		_botao(p, MOUSE_BUTTON_LEFT, true)
		_segurando = true
		_ponto = p
		_solta_em = Engine.get_process_frames() + rng.randi_range(2, 75)
		_anotar("segurar %d,%d por %d quadros" % [p.x, p.y, _solta_em - Engine.get_process_frames()])
	elif r < 0.78:
		var b := MOUSE_BUTTON_WHEEL_UP if rng.randf() < 0.5 else MOUSE_BUTTON_WHEEL_DOWN
		_botao(p, b, true)
		_botao(p, b, false)
		_anotar("roda %d,%d" % [p.x, p.y])
	elif r < 0.81:
		_mover(p)
		_botao(p, MOUSE_BUTTON_LEFT, true, true)
		_botao(p, MOUSE_BUTTON_LEFT, false)
		_anotar("duplo %d,%d" % [p.x, p.y])
	else:
		var k: int = TECLAS[rng.randi_range(0, TECLAS.size() - 1)]
		_tecla(k)
		_anotar("tecla %s" % OS.get_keycode_string(k))


func _anotar(t: String) -> void:
	registro.append("%d[%s] %s" % [passo, _fase, t])
	if registro.size() > 40:
		registro.pop_front()


func _mover(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	root.push_input(ev, true)


func _botao(p: Vector2, b: int, apertado: bool, duplo := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = p
	ev.global_position = p
	ev.button_index = b
	ev.pressed = apertado
	ev.double_click = duplo
	root.push_input(ev, true)


func _tecla(k: int) -> void:
	for apertado in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = apertado
		root.push_input(ev, true)


func _fim() -> void:
	process_frame.disconnect(_quadro)
	var v = _vista()
	var m = v.sim.mundo if v != null and v.sim != null else null
	print("[fuzz] FIM: %d ações, %d erros; era %d, %d pessoas" % [passo, erros.size(), m.era if m else -1, m.populacao() if m else -1])
	OS.remove_logger(_logger)
	moldura.sair()

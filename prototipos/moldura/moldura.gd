extends Node2D
## Moldura: janela sem borda, transparente e sempre por cima, em que o mouse
## atravessa tudo fora do mundo e da alça.
##
## A tela base tem 480 × 176: uma faixa transparente de 16 pixels no topo,
## com a alça à esquerda, e o mundo de 480 × 160 embaixo. A janela tem sempre
## exatamente base × escala, com escala inteira, e o Godot amplia a tela base
## sem filtro (modo "viewport"), então os pixels ficam sempre nítidos.
##
## Argumentos (depois de "--"):
##   --cenario=andando|parado|escondido   estado inicial (padrão: andando)
##   --escala=N                           escala inteira de 2 a 4 (padrão: 2)
##   --pos=X,Y                            posição da janela na tela
##   --duracao=S                          fecha sozinho depois de S segundos
##   --sem-foco                           a janela nunca rouba o foco do teclado
##   --atalho-global[=TECLA]              liga Ctrl+Alt+TECLA (padrão: H) com
##                                        outra janela em foco, via processo
##                                        auxiliar em PowerShell

const BASE := Vector2i(480, 176)
const FAIXA := 16
const MUNDO := Rect2i(0, FAIXA, 480, 160)
const ALCA := Rect2i(0, 0, 88, 14)
const ZONA_ARRASTE := Rect2i(0, 0, 46, 14)
const BOTAO_MENOS := Rect2i(48, 2, 10, 10)
const BOTAO_MAIS := Rect2i(60, 2, 10, 10)
const BOTAO_ESCONDER := Rect2i(74, 2, 10, 10)
const ESCALA_MIN := 2
const ESCALA_MAX := 4
const FPS_VISIVEL := 30
const FPS_ESCONDIDA := 12  # só o suficiente para a lógica do mundo seguir

var escala := 2
var escondida := false
var _duracao := 0.0
var _bandeja: StatusIndicator
var _atalho_pid := 0
var _atalho_saida: FileAccess
var _atalho_leitor: Thread

@onready var mundo: Node2D = $Mundo


func _ready() -> void:
	var args := _ler_argumentos()
	escala = clampi(int(args.get("escala", "2")), ESCALA_MIN, ESCALA_MAX)
	_duracao = float(args.get("duracao", "0"))
	var cenario: String = args.get("cenario", "andando")
	mundo.andando = cenario != "parado"
	if args.has("sem-foco"):
		get_window().unfocusable = true

	_log("renderizador=%s adaptador=%s %s escala_tela=%.2f" % [
		RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_vendor(), DisplayServer.screen_get_scale()])
	_log("transparencia_por_pixel=%s bandeja=%s cenario=%s" % [
		DisplayServer.is_window_transparency_available(),
		DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR), cenario])

	_criar_bandeja()
	_aplicar_escala(escala)
	if args.has("pos"):
		var p: PackedStringArray = args["pos"].split(",")
		get_window().position = Vector2i(int(p[0]), int(p[1]))
	else:
		var area := DisplayServer.screen_get_usable_rect()
		get_window().position = area.end - get_window().size - Vector2i(24, 24)

	if args.has("atalho-global"):
		_iniciar_atalho_global(args["atalho-global"] if args["atalho-global"] != "" else "H")
	if cenario == "escondido":
		esconder()


func _process(delta: float) -> void:
	# Se o jogador restaurar a janela pela barra de tarefas, volta a desenhar.
	if escondida and get_window().mode != Window.MODE_MINIMIZED:
		mostrar()
	mundo.avancar(delta, not escondida)
	if _duracao > 0.0:
		_duracao -= delta
		if _duracao <= 0.0:
			sair()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var pos := Vector2i(event.position)
		_log("mouse botao=%d pos=%s" % [event.button_index, pos])
		if event.button_index == MOUSE_BUTTON_LEFT:
			if BOTAO_MENOS.has_point(pos):
				_aplicar_escala(escala - 1)
			elif BOTAO_MAIS.has_point(pos):
				_aplicar_escala(escala + 1)
			elif BOTAO_ESCONDER.has_point(pos):
				esconder()
			elif ZONA_ARRASTE.has_point(pos):
				_log("arraste")
				get_window().start_drag()
				_log("arraste fim pos=%s" % get_window().position)
			elif MUNDO.has_point(pos):
				var local := Vector2(pos - MUNDO.position)
				if local.y < mundo.CHAO:
					_log("chuva x=%d y=%d" % [local.x, local.y])
					mundo.chover(local)
		elif ALCA.has_point(pos) and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_aplicar_escala(escala + 1)
		elif ALCA.has_point(pos) and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_aplicar_escala(escala - 1)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H, KEY_F8:
				esconder()
			KEY_2, KEY_3, KEY_4:
				_aplicar_escala(event.keycode - KEY_0)
			KEY_SPACE:
				mundo.andando = not mundo.andando
			KEY_Q:
				if event.ctrl_pressed:
					sair()


func esconder() -> void:
	if escondida:
		return
	escondida = true
	# Window.visible = false não esconde a janela principal no Windows: ela some
	# da tela, mas continua lá segurando os cliques. Minimizar funciona.
	get_window().mode = Window.MODE_MINIMIZED
	RenderingServer.render_loop_enabled = false
	Engine.max_fps = FPS_ESCONDIDA
	_log("escondida")


func mostrar() -> void:
	if not escondida:
		return
	escondida = false
	Engine.max_fps = FPS_VISIVEL
	RenderingServer.render_loop_enabled = true
	if get_window().mode == Window.MODE_MINIMIZED:
		get_window().mode = Window.MODE_WINDOWED
	get_window().always_on_top = true
	_aplicar_passagem_mouse()
	mundo.queue_redraw()
	queue_redraw()
	_log("visivel")


func alternar() -> void:
	if escondida:
		mostrar()
	else:
		esconder()


func sair() -> void:
	_log("saindo")
	if _atalho_pid != 0:
		OS.kill(_atalho_pid)
		_atalho_leitor.wait_to_finish()
	get_tree().quit()


## Muda a escala mantendo o canto inferior esquerdo do mundo no lugar,
## que é onde o olho costuma estar ancorado.
func _aplicar_escala(nova: int) -> void:
	nova = clampi(nova, ESCALA_MIN, ESCALA_MAX)
	var janela := get_window()
	var tamanho := BASE * nova
	var area := DisplayServer.screen_get_usable_rect(janela.current_screen)
	if nova != escala or janela.size != tamanho:
		var fundo := janela.position.y + janela.size.y
		janela.size = tamanho
		var pos := Vector2i(janela.position.x, fundo - tamanho.y)
		pos.x = clampi(pos.x, area.position.x, maxi(area.position.x, area.end.x - tamanho.x))
		pos.y = clampi(pos.y, area.position.y, maxi(area.position.y, area.end.y - tamanho.y))
		janela.position = pos
	escala = nova
	_aplicar_passagem_mouse()
	_log("escala=%dx janela=%s" % [escala, tamanho])


## Só a alça e o mundo recebem o mouse. O polígono está em pixels da janela.
func _aplicar_passagem_mouse() -> void:
	var k := escala
	var poligono := PackedVector2Array([
		Vector2(0, 0),
		Vector2(ALCA.end.x * k, 0),
		Vector2(ALCA.end.x * k, FAIXA * k),
		Vector2(BASE.x * k, FAIXA * k),
		Vector2(BASE.x * k, BASE.y * k),
		Vector2(0, BASE.y * k),
	])
	DisplayServer.window_set_mouse_passthrough(poligono)


## O Godot não tem atalho global. Um processo auxiliar registra o atalho no
## Windows e escreve uma linha a cada aperto; uma thread lê essas linhas.
func _iniciar_atalho_global(tecla: String) -> void:
	var script := ProjectSettings.globalize_path("res://atalho/atalho_global.ps1")
	var r := OS.execute_with_pipe("powershell.exe", [
		"-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
		"-File", script, "-Pai", str(OS.get_process_id()), "-Tecla", tecla])
	if r.is_empty():
		_log("atalho_global=falhou ao iniciar")
		return
	_atalho_pid = r["pid"]
	_atalho_saida = r["stdio"]
	_atalho_leitor = Thread.new()
	_atalho_leitor.start(_ler_atalho_global)


func _ler_atalho_global() -> void:
	while _atalho_saida.is_open() and _atalho_saida.get_error() == OK:
		var linha := _atalho_saida.get_line().strip_edges()
		if linha != "":
			_ao_receber_atalho.call_deferred(linha)


func _ao_receber_atalho(linha: String) -> void:
	_log("atalho_global: " + linha)
	if linha == "alternar":
		alternar()


func _criar_bandeja() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		return
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color8(70, 140, 220))
	img.fill_rect(Rect2i(0, 11, 16, 5), Color8(110, 75, 45))
	img.fill_rect(Rect2i(0, 11, 16, 1), Color8(80, 140, 60))
	img.fill_rect(Rect2i(7, 5, 2, 6), Color8(240, 200, 160))
	_bandeja = StatusIndicator.new()
	_bandeja.icon = ImageTexture.create_from_image(img)
	_bandeja.tooltip = "Moldura: clique para mostrar ou esconder, botão direito para sair"
	_bandeja.pressed.connect(_ao_clicar_bandeja)
	add_child(_bandeja)
	await get_tree().process_frame
	_log("bandeja_rect=%s" % _bandeja.get_rect())


func _ao_clicar_bandeja(botao: int, _posicao: Vector2i) -> void:
	if botao == MOUSE_BUTTON_LEFT:
		alternar()
	elif botao == MOUSE_BUTTON_RIGHT:
		sair()


func _draw() -> void:
	# Alça: zona de arraste com pontinhos, botões de diminuir, aumentar e esconder.
	draw_rect(ALCA, Color8(40, 34, 30, 220))
	for x in range(6, 42, 4):
		draw_rect(Rect2(x, 5, 2, 1), Color8(150, 140, 120))
		draw_rect(Rect2(x, 8, 2, 1), Color8(150, 140, 120))
	for botao in [BOTAO_MENOS, BOTAO_MAIS, BOTAO_ESCONDER]:
		draw_rect(botao, Color8(80, 70, 60))
	var cor := Color8(230, 220, 200)
	draw_rect(Rect2(BOTAO_MENOS.position + Vector2i(2, 4), Vector2(6, 2)), cor)
	draw_rect(Rect2(BOTAO_MAIS.position + Vector2i(2, 4), Vector2(6, 2)), cor)
	draw_rect(Rect2(BOTAO_MAIS.position + Vector2i(4, 2), Vector2(2, 6)), cor)
	draw_rect(Rect2(BOTAO_ESCONDER.position + Vector2i(2, 7), Vector2(6, 1)), cor)


func _ler_argumentos() -> Dictionary:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var partes := a.substr(2).split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	return args


func _log(texto: String) -> void:
	print("[%.1f] %s" % [Time.get_ticks_msec() / 1000.0, texto])

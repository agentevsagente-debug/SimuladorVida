extends Node2D
## Moldura: janela sem borda, transparente e sempre por cima, em que o mouse
## atravessa tudo fora do mundo e da alça. Vem do protótipo da fase 0
## (prototipos/moldura/), cujo RELATORIO.md explica as escolhas.
##
## A tela base tem 480 × 178: uma faixa transparente de 18 pixels no topo,
## com a alça à esquerda, e o mundo de 480 × 160 embaixo. A janela tem sempre
## exatamente base × escala, com escala inteira, e o Godot amplia a tela base
## sem filtro (modo "viewport"), então os pixels ficam sempre nítidos.
##
## A escala inicial vem da densidade da tela. Depois disso, a escala e a
## posição escolhidas pelo jogador ficam guardadas em user://moldura.cfg.
## O mundo é salvo a cada dia de jogo e ao fechar.
##
## Argumentos (depois de "--"):
##   --cenario=escondido                  começa escondida
##   --escala=N                           escala inteira de 2 a 4
##   --pos=X,Y                            posição da janela na tela
##   --sem-config                         ignora e não grava a escala e a posição guardadas
##   --duracao=S                          fecha sozinho depois de S segundos
##   --sem-foco                           a janela nunca rouba o foco do teclado
##   --atalho-global[=TECLA]              liga Ctrl+Alt+TECLA (padrão: H) com
##                                        outra janela em foco, via processo
##                                        auxiliar em PowerShell
##   --ritmo=pausa|normal|rapido          ritmo inicial do tempo
##   --demo=PODER:X:INTENSIDADE:S         usa um poder em X depois de S segundos (testes)
##   --dica=X,Y                           mostra a dica do cursor nesse ponto da tela (testes)
##   --abrir=cronica|poderes|ritmo|linhagem|salto   abre um painel ou aperta um botão (testes)

const Simulacao = preload("res://apresentacao/simulacao.gd")

const FAIXA := 18
const BASE := Vector2i(480, 160 + FAIXA)
const MUNDO := Rect2i(0, FAIXA, 480, 160)
const ESCALA_MIN := 2
const ESCALA_MAX := 4
const FPS_VISIVEL := 30
const FPS_ESCONDIDA := 4  # o mundo anda 1 passo a cada 112 s; não precisa de mais
const ARQUIVO_CONFIG := "user://moldura.cfg"

var escala := 2
var escondida := false
var _duracao := 0.0
var _usar_config := true
var _bandeja: StatusIndicator
var _atalho_pid := 0
var _atalho_saida: FileAccess
var _atalho_leitor: Thread
var _largura_alca := 0

@onready var vista: Node2D = $Recorte/Vista
@onready var interface: Node2D = $Interface


func _ready() -> void:
	var args := _ler_argumentos()
	_duracao = float(args.get("duracao", "0"))
	_usar_config = not args.has("sem-config")
	if args.has("sem-foco"):
		get_window().unfocusable = true
	var icone := (load("res://arte/interface/icone_jogo_32.png") as Texture2D).get_image()
	DisplayServer.set_icon(icone)

	var tela := DisplayServer.window_get_current_screen()
	_log("renderizador=%s adaptador=%s dpi=%d" % [
		RenderingServer.get_current_rendering_driver_name(),
		RenderingServer.get_video_adapter_name(), DisplayServer.screen_get_dpi(tela)])

	interface.criar(vista)
	interface.largura_mudou.connect(_aplicar_passagem_mouse)
	interface.arrastar.connect(_arrastar)
	interface.esconder.connect(esconder)
	interface.escala.connect(func(d): _aplicar_escala(escala + d))
	vista.pessoa_clicada.connect(_acompanhar)
	if vista.sim:
		match args.get("ritmo", ""):
			"pausa":
				vista.sim.definir_ritmo(Simulacao.Ritmo.PAUSA)
			"rapido":
				vista.sim.definir_ritmo(Simulacao.Ritmo.RAPIDO)
		_mostrar_ausencia()

	var config := ConfigFile.new()
	if _usar_config:
		config.load(ARQUIVO_CONFIG)
	var nova: int = config.get_value("moldura", "escala", _escala_pela_tela(tela))
	if args.has("escala"):
		nova = int(args["escala"])
	var pos: Variant = null
	if config.has_section_key("moldura", "posicao"):
		pos = config.get_value("moldura", "posicao")
	if args.has("pos"):
		var p: PackedStringArray = args["pos"].split(",")
		pos = Vector2i(int(p[0]), int(p[1]))

	_criar_bandeja()
	_aplicar_escala(nova, false)
	if pos is Vector2i and _cabe_em_alguma_tela(pos, BASE * escala):
		get_window().position = pos
	else:
		var area := DisplayServer.screen_get_usable_rect(tela)
		get_window().position = area.end - get_window().size - Vector2i(24, 24)

	if args.has("demo"):
		var d: PackedStringArray = args["demo"].split(":")
		get_tree().create_timer(float(d[3]) if d.size() > 3 else 2.0).timeout.connect(
			func(): interface.demo(d[0], float(d[1]), float(d[2])))
	if args.has("dica"):
		var p: PackedStringArray = args["dica"].split(",")
		get_tree().create_timer(1.0).timeout.connect(func():
			var ev := InputEventMouseMotion.new()
			interface.tratar(ev, Vector2(float(p[0]), float(p[1])), FAIXA))
	match args.get("abrir", ""):
		"cronica":
			interface.alternar_cronica.call_deferred()
		"poderes", "ritmo", "linhagem":
			interface._apertar.call_deferred(args["abrir"])
		"salto":
			interface._apertar.call_deferred("ritmo:salto")
	if args.has("atalho-global"):
		_iniciar_atalho_global(args["atalho-global"] if args["atalho-global"] != "" else "H")
	if args.get("cenario", "") == "escondido":
		esconder()


## Ao voltar, a crônica abre com o que aconteceu enquanto o jogador esteve fora.
func _mostrar_ausencia() -> void:
	var a: Dictionary = vista.sim.ausencia
	if a.is_empty() or int(a.get("passos", 0)) < 24:
		return
	var dias := int(a["passos"]) / 24
	var titulo := "Enquanto você esteve fora (%d dias):" % dias
	if a.get("teto_atingido", false):
		titulo = "Enquanto você esteve fora, o mundo seguiu por um ano e esperou:"
	interface.mostrar_cronica.call_deferred(titulo + "\n\n" + interface._sem_markdown(a.get("relato", "")))


func _process(delta: float) -> void:
	# Se o jogador restaurar a janela pela barra de tarefas, volta a desenhar.
	if escondida and get_window().mode != Window.MODE_MINIMIZED:
		mostrar()
	vista.avancar(delta, not escondida)
	if not escondida:
		interface.avancar(delta)
	if _duracao > 0.0:
		_duracao -= delta
		if _duracao <= 0.0:
			sair()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_guardar_config()
		if vista.sim:
			vista.sim.salvar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		interface.tratar(event, event.position, FAIXA)
	elif event is InputEventKey and event.pressed and not event.echo:
		if interface.tecla(event.keycode):
			return
		match event.keycode:
			KEY_H, KEY_F8:
				esconder()
			KEY_2, KEY_3, KEY_4:
				_aplicar_escala(event.keycode - KEY_0)
			KEY_Q:
				if event.ctrl_pressed:
					sair()


func _arrastar() -> void:
	get_window().start_drag()  # volta quando o botão é solto
	_guardar_config()
	_log("arrastada pos=%s" % get_window().position)


func _acompanhar(id: int) -> void:
	if vista.sim and vista.sim.mundo.acompanhar(id):
		interface._avisar("Acompanhando " + String(vista.sim.mundo.pessoa(id).nome))


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
	vista.queue_redraw()
	interface.queue_redraw()
	_log("visivel")


func alternar() -> void:
	if escondida:
		mostrar()
	else:
		esconder()


func sair() -> void:
	_log("saindo")
	_guardar_config()
	if vista.sim:
		vista.sim.salvar()
	if _atalho_pid != 0:
		OS.kill(_atalho_pid)
		_atalho_leitor.wait_to_finish()
	get_tree().quit()


## Escala inicial: 2x numa tela de 96 dpi, 3x em 144 dpi (150%), 4x em
## 192 dpi, sem passar de 60% da largura útil da tela.
func _escala_pela_tela(tela: int) -> int:
	var dpi := DisplayServer.screen_get_dpi(tela)
	var largura := DisplayServer.screen_get_usable_rect(tela).size.x
	var k := clampi(roundi(dpi / 96.0 * 2.0), ESCALA_MIN, ESCALA_MAX)
	while k > ESCALA_MIN and BASE.x * k > largura * 0.6:
		k -= 1
	return k


func _cabe_em_alguma_tela(pos: Vector2i, tamanho: Vector2i) -> bool:
	var janela := Rect2i(pos, tamanho)
	for i in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(i).encloses(janela):
			return true
	return false


## Muda a escala mantendo o canto inferior esquerdo do mundo no lugar,
## que é onde o olho costuma estar ancorado.
func _aplicar_escala(nova: int, guardar := true) -> void:
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
	if guardar:
		_guardar_config()
	_log("escala=%dx janela=%s" % [escala, tamanho])


## Só a alça e o mundo recebem o mouse. O polígono está em pixels da janela.
func _aplicar_passagem_mouse() -> void:
	var k := escala
	var alca: int = interface.largura()
	var poligono := PackedVector2Array([
		Vector2(0, 0),
		Vector2(alca * k, 0),
		Vector2(alca * k, FAIXA * k),
		Vector2(BASE.x * k, FAIXA * k),
		Vector2(BASE.x * k, BASE.y * k),
		Vector2(0, BASE.y * k),
	])
	DisplayServer.window_set_mouse_passthrough(poligono)
	if alca != _largura_alca:
		_largura_alca = alca
		_log("alca largura=%d" % alca)


func _guardar_config() -> void:
	if not _usar_config or escondida:
		return
	var config := ConfigFile.new()
	config.set_value("moldura", "escala", escala)
	config.set_value("moldura", "posicao", get_window().position)
	config.save(ARQUIVO_CONFIG)


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
	_bandeja = StatusIndicator.new()
	_bandeja.icon = load("res://arte/interface/icone_jogo_16.png")
	_bandeja.tooltip = "Simulador de vida: clique para mostrar ou esconder, botão direito para sair"
	_bandeja.pressed.connect(_ao_clicar_bandeja)
	add_child(_bandeja)


func _ao_clicar_bandeja(botao: int, _posicao: Vector2i) -> void:
	if botao == MOUSE_BUTTON_LEFT:
		alternar()
	elif botao == MOUSE_BUTTON_RIGHT:
		sair()


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

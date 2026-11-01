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
##                                        (e não mostra as dicas da primeira abertura)
##   --primeira-vez                       mostra as dicas da primeira abertura desde o começo (testes)
##   --duracao=S                          fecha sozinho depois de S segundos
##   --sair-salvando                      ao fim da duração, sai com um salvamento em segundo plano rodando (testes)
##   --sem-foco                           a janela nunca rouba o foco do teclado
##   --sem-atalho                         não liga o atalho global (que o jogo de verdade liga sozinho)
##   --atalho-global[=TECLA]              liga Ctrl+Alt+TECLA (padrão: H) com
##                                        outra janela em foco, via processo
##                                        auxiliar em PowerShell
##   --ritmo=pausa|normal|rapido|rapido2  ritmo inicial do tempo (rapido = 10x, rapido2 = 50x);
##                                        sem ele, vale o último guardado no moldura.cfg
##   --demo=PODER:X:INTENSIDADE:S         usa um poder em X depois de S segundos (testes)
##   --dica=X,Y                           mostra a dica do cursor nesse ponto da tela (testes)
##   --livro-arquivo=CAMINHO[:PÁGINA]     abre um livro em markdown no leitor da estante (testes)
##   --discreto                           liga o modo discreto (D, no jogo): o pior fica só na crônica
##   --carregar=PODER:X:INTENSIDADE        segura um poder em X com a carga fixa, sem soltar (testes)
##   --dica-pessoa=ID[:S]                 a dica sobre a pessoa ID, acompanhando-a, depois de S segundos (testes)
##   --abrir=cronica|poderes|ritmo|linhagem|salto|estante|livro|abandonar
##                        abre um painel ou aperta um botão (testes); livro abre o
##                        último livro, abandonar abre a pergunta de abandono e
##                        abandonado abandona sem perguntar e abre a estante

const Simulacao = preload("res://apresentacao/simulacao.gd")

const FAIXA := 18
const BASE := Vector2i(480, 160 + FAIXA)
const MUNDO := Rect2i(0, FAIXA, 480, 160)
const ESCALA_MIN := 2
const ESCALA_MAX := 4
const FPS_VISIVEL := 30
const FPS_DEVAGAR := 20  # em 1x e na pausa (ninguém anda rápido): menos CPU no canto da tela
const FPS_ESCONDIDA := 4  # o mundo anda 1 passo a cada 112 s; não precisa de mais
const ARQUIVO_CONFIG := "user://moldura.cfg"

var escala := 2
var escondida := false
var _duracao := 0.0
var _usar_config := true
var _bandeja: StatusIndicator
var _atalho_pid := 0
var _avisou_esconder := false
var _sair_salvando := false  # --sair-salvando: ao fim de --duracao, sai durante um salvar_async (testes)
var _atalho_saida: FileAccess
var _atalho_leitor: Thread
var _largura_alca := 0

@onready var vista: Node2D = $Recorte/Vista
@onready var interface: Node2D = $Interface


func _ready() -> void:
	var args := _ler_argumentos()
	_duracao = float(args.get("duracao", "0"))
	_sair_salvando = args.has("sair-salvando")
	_usar_config = not args.has("sem-config")
	if args.has("sem-foco"):
		get_window().unfocusable = true
	var icone := (load("res://arte/interface/icone_jogo_32.png") as Texture2D).get_image()
	DisplayServer.set_icon(icone)

	var tela := DisplayServer.window_get_current_screen()
	_log("pasta de dados=%s" % OS.get_user_data_dir())  # no jogo exportado, a pasta própria (project.godot)
	_log("renderizador=%s adaptador=%s dpi=%d" % [
		RenderingServer.get_current_rendering_driver_name(),
		RenderingServer.get_video_adapter_name(), DisplayServer.screen_get_dpi(tela)])

	interface.criar(vista)
	interface.largura_mudou.connect(_aplicar_passagem_mouse)
	interface.arrastar.connect(_arrastar)
	interface.esconder.connect(esconder)
	interface.escala.connect(func(d): _aplicar_escala(escala + d))
	vista.pessoa_clicada.connect(_acompanhar)
	interface.ritmo_mudou.connect(_guardar_config)
	interface.preferencia_mudou.connect(_guardar_config)
	var config := ConfigFile.new()
	if _usar_config:
		config.load(ARQUIVO_CONFIG)
	if vista.sim:
		# o ritmo escolhido volta na abertura seguinte, salvo depois de mais de
		# um dia real fora: aí o jogo abre no normal, para o jogador ver o que mudou
		var a: Dictionary = vista.sim.ausencia
		var longe: bool = a.get("teto_atingido", false) or a.get("passos", 0) * Simulacao.Mundo.SEGUNDOS_POR_PASSO > 86400.0
		var ritmo: String = args.get("ritmo", "" if longe else config.get_value("moldura", "ritmo", ""))
		var r: int = Simulacao.NOME_RITMO.find_key(ritmo) if Simulacao.NOME_RITMO.values().has(ritmo) else -1
		if r >= 0:
			vista.sim.definir_ritmo(r)
		_mostrar_ausencia()
	vista.modo_discreto = args.has("discreto") or (_usar_config and bool(config.get_value("moldura", "discreto", false)))
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
	if args.has("livro-arquivo"):  # abre um livro em markdown direto no leitor (testes): CAMINHO[:PÁGINA]
		var partes: PackedStringArray = args["livro-arquivo"].rsplit(":", true, 1)
		var pagina := int(partes[1]) if partes.size() > 1 and partes[1].is_valid_int() else 0
		var caminho: String = partes[0] if partes.size() > 1 and partes[1].is_valid_int() else args["livro-arquivo"]
		interface._estante.abrir_texto.call_deferred(FileAccess.get_file_as_string(caminho), pagina)
	if args.has("carregar"):  # segura um poder sem soltar, com a carga fixa (testes da carga)
		var c: PackedStringArray = args["carregar"].split(":")
		get_tree().create_timer(1.0).timeout.connect(func():
			interface.poder = c[0]
			interface._carga_ponto = Vector2(float(c[1]), 100)
			interface._carga_inicio = interface._relogio - float(c[2]) * interface.CARGA_SEGUNDOS
			interface._carregando = true)
	if args.has("dica-pessoa"):  # o cursor acompanha a pessoa (id), a partir de S segundos
		var d: PackedStringArray = args["dica-pessoa"].split(":")
		get_tree().create_timer(float(d[1]) if d.size() > 1 else 1.0).timeout.connect(func():
			var t := Timer.new()
			t.wait_time = 0.25
			add_child(t)
			t.timeout.connect(func():
				for f in vista.figuras:
					if f.id == int(d[0]):
						var ev := InputEventMouseMotion.new()
						interface.tratar(ev, vista.para_tela(Vector2(f.x + f.largura / 2.0, f.base - 6)) + Vector2(0, FAIXA), FAIXA))
			t.start())
	match args.get("abrir", ""):
		"cronica":
			interface.alternar_cronica.call_deferred()
		"poderes", "ritmo", "linhagem":
			interface._apertar.call_deferred(args["abrir"])
		"salto":
			interface._apertar.call_deferred("ritmo:salto")
		"estante":
			interface.alternar_estante.call_deferred()
		"livro":
			interface._estante.abrir_livro.call_deferred(1 << 20)
		"abandonar":
			interface._estante.pedir_confirmacao.call_deferred()
		"abandonado":  # abandona de vez e mostra a estante com o livro novo
			(func():
				interface._abandonar()
				interface.alternar_estante()).call_deferred()
	_iniciar_dicas(args.has("primeira-vez"))
	if args.has("atalho-global") or (_usar_config and not args.has("sem-atalho")):
		_iniciar_atalho_global(args.get("atalho-global", "") if args.get("atalho-global", "") != "" else "H")
	if args.get("cenario", "") == "escondido":
		esconder()


## Ao voltar, a crônica abre com o que aconteceu enquanto o jogador esteve fora.
func _mostrar_ausencia() -> void:
	var a: Dictionary = vista.sim.ausencia
	if a.is_empty() or int(a.get("passos", 0)) < 24:
		return
	var dias := int(a["passos"]) / 24
	var titulo := ("Enquanto você esteve fora: %d dias" % dias) if dias != 1 else "Enquanto você esteve fora: 1 dia"
	var relato: String = interface._sem_markdown(a.get("relato", ""))
	if a.get("teto_atingido", false):
		titulo = "Enquanto você esteve fora: um ano"
		relato = "O mundo seguiu por um ano e esperou.\n\n" + relato
	interface.mostrar_cronica.call_deferred(relato, titulo)


var _mem_feito := false
func _process(delta: float) -> void:
	if OS.has_environment("MEMORIA") and not _mem_feito and Time.get_ticks_msec() > 15000:
		_mem_feito = true
		print("[memoria] estatica=%.1f texturas=%.1f buffers=%.1f video=%.1f objetos=%d nos=%d recursos=%d" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)])
	# Se o jogador restaurar a janela pela barra de tarefas, volta a desenhar.
	if escondida and get_window().mode != Window.MODE_MINIMIZED:
		_log("restaurada pela barra de tarefas? modo=%d" % get_window().mode)
		mostrar()
	if not escondida:  # os quadros por segundo acompanham o ritmo
		var fps: int = FPS_DEVAGAR if vista.sim and vista.sim.ritmo in [Simulacao.Ritmo.NORMAL, Simulacao.Ritmo.PAUSA] else FPS_VISIVEL
		if Engine.max_fps != fps:
			Engine.max_fps = fps
	var t_m := Time.get_ticks_usec()  # DEPURAR_TEMPO
	vista.avancar(delta, not escondida)
	var t_v := Time.get_ticks_usec()  # DEPURAR_TEMPO
	if not escondida:
		interface.avancar(delta)
	if vista._medindo:  # DEPURAR_TEMPO
		vista._tempos["M_vista_total"] = vista._tempos.get("M_vista_total", 0) + t_v - t_m
		vista._tempos["M_interface"] = vista._tempos.get("M_interface", 0) + Time.get_ticks_usec() - t_v
	if _duracao > 0.0:
		_duracao -= delta
		if _duracao <= 0.0:
			if _sair_salvando and vista.sim:  # teste: fecha com o salvamento em segundo plano ainda rodando
				vista.sim.salvar_async()
			sair()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_guardar_config()
		if vista.sim:
			vista.sim.salvar()
			vista.sim.encerrar()
		_parar_atalho_global()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		interface.tratar(event, event.position, FAIXA)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode in [KEY_2, KEY_3, KEY_4]:  # 2, 3 e 4 sozinhos são ritmos
			_aplicar_escala(event.keycode - KEY_0)
			return
		if interface.tecla(event.keycode):
			return
		match event.keycode:
			KEY_H, KEY_F8:
				esconder()
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
	if _usar_config and not interface.ja_escondeu() and not _avisou_esconder:
		# na primeira vez, a alça diz como voltar e só então a janela some (auditoria 8, P7)
		_avisou_esconder = true
		interface._avisar("Para voltar: o ícone na bandeja ou Ctrl+Alt+H")
		get_tree().create_timer(2.0).timeout.connect(esconder)
		return
	interface.marcar_dica("esconder")
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
		vista.sim.encerrar()
	_parar_atalho_global()
	get_tree().quit()


## Também quando o jogo fecha por outro caminho (a captura dos testes, por exemplo).
func _exit_tree() -> void:
	if vista and vista.sim:
		vista.sim.encerrar()
	_parar_atalho_global()


func _parar_atalho_global() -> void:
	if _atalho_pid != 0:
		OS.kill(_atalho_pid)
		_atalho_pid = 0
		_atalho_leitor.wait_to_finish()


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
	var relogio: Rect2i = interface.RELOGIO
	var caixa: Rect2 = interface.caixa_na_faixa  # a dica ou o aviso ao lado da alça, quando há
	var poligono := PackedVector2Array([Vector2(0, 0)])
	if caixa.has_area():
		poligono.append_array([Vector2(caixa.end.x * k, 0), Vector2(caixa.end.x * k, caixa.end.y * k),
			Vector2(alca * k, caixa.end.y * k)])
	else:
		poligono.append(Vector2(alca * k, 0))
	poligono.append_array([
		Vector2(alca * k, FAIXA * k),
		Vector2(relogio.position.x * k, FAIXA * k),  # o relógio, no canto de cima à direita
		Vector2(relogio.position.x * k, 0),
		Vector2(BASE.x * k, 0),
		Vector2(BASE.x * k, BASE.y * k),
		Vector2(0, BASE.y * k),
	])
	DisplayServer.window_set_mouse_passthrough(poligono)
	if alca != _largura_alca:
		_largura_alca = alca
		_log("alca largura=%d" % alca)


## As dicas da primeira abertura (uma de cada vez, na alça): as que o jogador
## já fez ficam em moldura.cfg ([dicas] feitas) e não voltam. Os testes com
## --sem-config não as mostram; --primeira-vez mostra todas de novo.
func _iniciar_dicas(desde_o_comeco: bool) -> void:
	if not _usar_config and not desde_o_comeco:
		return
	var feitas: Array = []
	if _usar_config and not desde_o_comeco:
		var config := ConfigFile.new()
		config.load(ARQUIVO_CONFIG)
		feitas = config.get_value("dicas", "feitas", [])
	interface.dica_feita.connect(_guardar_dica)
	interface.iniciar_dicas(feitas)


func _guardar_dica(feitas: Array) -> void:
	if not _usar_config:
		return
	var config := ConfigFile.new()
	config.load(ARQUIVO_CONFIG)
	config.set_value("dicas", "feitas", feitas)
	config.save(ARQUIVO_CONFIG)


func _guardar_config() -> void:
	if not _usar_config or escondida:
		return
	var config := ConfigFile.new()
	config.load(ARQUIVO_CONFIG)  # guarda junto o que já havia (as dicas feitas)
	config.set_value("moldura", "escala", escala)
	config.set_value("moldura", "discreto", vista.modo_discreto)
	config.set_value("moldura", "posicao", get_window().position)
	if vista.sim:
		config.set_value("moldura", "ritmo", Simulacao.NOME_RITMO[vista.sim.ritmo])
	config.save(ARQUIVO_CONFIG)


## O Godot não tem atalho global. Um processo auxiliar registra o atalho no
## Windows e escreve uma linha a cada aperto; uma thread lê essas linhas.
func _iniciar_atalho_global(tecla: String) -> void:
	# no jogo exportado, res:// fica dentro do pacote e o PowerShell não o
	# alcança: o script vai para user:// e roda de lá
	var copia := "user://atalho_global.ps1"
	var f := FileAccess.open(copia, FileAccess.WRITE)
	if f == null:
		_log("atalho_global=falhou ao copiar o script")
		return
	f.store_string(FileAccess.get_file_as_string("res://atalho/atalho_global.ps1"))
	f.close()
	var script := ProjectSettings.globalize_path(copia)
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

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
##   --sem-som                            abre com o som desligado, sem gravar a escolha (testes)
##   --som-inaudivel                      som ligado e mixado, mas a -80 dB (medir o custo sem fazer barulho)
##   --alternar-som=S                     aperta o botão de som depois de S segundos (testes)
##   --menu-bandeja=S[:janela|som|sair]   abre o menu da bandeja depois de S segundos e escolhe o item (testes)
##   --carregar=PODER:X:INTENSIDADE        segura um poder em X com a carga fixa, sem soltar (testes)
##   --dica-pessoa=ID[:S]                 a dica sobre a pessoa ID, acompanhando-a, depois de S segundos (testes)
##   --preces-falsas                      a caixa de preces com preces de mentira, com os nomes do mundo (testes)
##   --abrir=cronica|poderes|ritmo|linhagem|salto|estante|preces|livro|abandonar
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
var som: Node                  # o som (apresentacao/som.gd): os barramentos, o ambiente e os acontecimentos
var _minimizada := false
var _som_forcado := false      # --sem-som: desligado só nesta abertura, sem gravar
var _menu_bandeja: PopupMenu   # o botão direito na bandeja: Mostrar/Esconder, Som ligado, Sair
enum { MENU_JANELA, MENU_SOM, MENU_SAIR }

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
	som = preload("res://apresentacao/som.gd").new()
	add_child(som)
	som.criar(vista)
	vista.som = som
	interface.som_alternar.connect(_alternar_som)
	interface.escala_ciclo.connect(_ciclar_escala)
	interface.largura_mudou.connect(_aplicar_passagem_mouse)
	interface.arrastar.connect(_arrastar)
	interface.esconder.connect(esconder)
	interface.escala.connect(func(d): _aplicar_escala(escala + d))
	vista.pessoa_clicada.connect(_acompanhar)
	interface.ritmo_mudou.connect(_guardar_config)
	interface.preferencia_mudou.connect(_guardar_config)
	interface.preces_lidas.connect(_guardar_preces_lidas)
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
	interface.preces_lida = config.get_value("preces", "lida", {}) if _usar_config else {}
	vista.modo_discreto = args.has("discreto") or (_usar_config and bool(config.get_value("moldura", "discreto", false)))
	# o som: a escolha guardada (ligado na primeira vez); --sem-som cala só esta abertura
	_som_forcado = args.has("sem-som")
	som.definir_ligado(false if _som_forcado else bool(config.get_value("moldura", "som", true)))
	if args.has("som-inaudivel"):  # medição: tudo toca e é mixado, mas a -80 dB (ninguém ouve)
		_som_forcado = true
		som.volume_db = -80.0
		som.definir_ligado(true)
	interface.som_ligado = som.ligado
	if vista.sim:
		vista.sim.eventos_novos.connect(_sons_dos_eventos)
	if args.has("menu-bandeja"):  # teste: abre o menu da bandeja (S) e escolhe o item (janela|som|sair)
		var mb: PackedStringArray = args["menu-bandeja"].split(":")
		get_tree().create_timer(float(mb[0])).timeout.connect(_testar_menu_da_bandeja.bind(mb[1] if mb.size() > 1 else ""))
	if args.has("alternar-som"):  # teste: aperta o botão de som depois de S segundos
		get_tree().create_timer(float(args["alternar-som"])).timeout.connect(_alternar_som)
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
		"preces":
			interface.alternar_preces.call_deferred()
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
	if vista.sim.ilegivel != "" and str(a.get("recuperado_de", "")) == "":  # nada se leu: começou um mundo novo
		_log("mundo salvo ilegível, guardado em %s" % vista.sim.ilegivel)
		interface.mostrar_cronica.call_deferred("O mundo salvo não pôde ser aberto (estragado, ou de uma versão mais nova do jogo). " +
			"Ele ficou guardado em %s, e começou um mundo novo." % vista.sim.ilegivel.get_file(), "O mundo salvo não abriu")
		return
	var copia := str(a.get("recuperado_de", ""))  # o mundo salvo estava estragado e voltou de uma cópia
	if a.is_empty() or (int(a.get("passos", 0)) < 24 and copia == ""):
		return
	var dias := int(a.get("passos", 0)) / 24
	var titulo := ("Enquanto você esteve fora: %d dias" % dias) if dias != 1 else "Enquanto você esteve fora: 1 dia"
	var relato: String = interface._sem_markdown(a.get("relato", ""))
	if copia != "":
		_log("mundo recuperado de %s" % copia)
		relato = "O mundo salvo estava estragado e voltou da cópia anterior (%s). Pode faltar o último dia.\n\n%s" % [copia.get_file(), relato]
		if dias == 0:
			titulo = "O mundo voltou de uma cópia"
	if a.get("teto_atingido", false):
		titulo = "Enquanto você esteve fora: um ano"
		relato = "O mundo seguiu por um ano e esperou.\n\n" + relato
	interface.mostrar_cronica.call_deferred(relato, titulo)


var _mem_feito := false


## O botão de som da alça e a tecla M: liga e desliga na hora, e a escolha fica guardada.
func _alternar_som() -> void:
	som.definir_ligado(not som.ligado)
	interface.som_ligado = som.ligado
	interface._avisar("Som ligado" if som.ligado else "Som desligado (M liga de novo)")
	interface._montar_botoes()
	_log("som %s" % ("ligado" if som.ligado else "desligado"))
	_guardar_som()


## A escolha do som vai para o moldura.cfg na hora, mesmo com a janela escondida (pelo
## menu da bandeja): o resto da configuração só se guarda com a janela visível.
func _guardar_som() -> void:
	if not _usar_config:
		return
	_som_forcado = false  # o jogador escolheu: daqui em diante vale a escolha dele
	var config := ConfigFile.new()
	config.load(ARQUIVO_CONFIG)
	config.set_value("moldura", "som", som.ligado)
	config.save(ARQUIVO_CONFIG)


## Os acontecimentos do núcleo que têm som, no x de onde aconteceram.
func _sons_dos_eventos(eventos: Array) -> void:
	if som.calado():
		return
	var mundo = vista.sim.mundo
	if not mundo.has_method("som_do_evento"):
		return
	for ev in eventos:
		if som.ja_tocados.erase(int(ev.get("id", -2))):
			continue  # o gesto já tocou o som dele na hora
		som.tocar_do_nucleo(mundo.som_do_evento(ev), String(ev.get("tipo", "")))


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
	if vista.sim and vista.sim.salvamento_falhou:  # um aviso por falha (o salvamento é diário)
		vista.sim.salvamento_falhou = false
		_log("salvamento falhou")
		interface._avisar("Não deu para salvar o mundo: o disco está cheio? O salvo antes continua lá.")
	# sem tela (headless, os testes), a janela diz que está minimizada: não vale
	var minimizada := get_window().mode == Window.MODE_MINIMIZED and DisplayServer.get_name() != "headless"
	if minimizada != _minimizada:  # minimizada por fora (Win+D, a barra de tarefas): mudo também
		_minimizada = minimizada
		som.definir_escondida(escondida or minimizada)
	if not escondida and vista.sim:
		som.discreto = vista.modo_discreto
		som.avancar(delta, vista.sim.mundo, vista.sim.hora_continua())
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
		som.encerrar()


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
	som.definir_escondida(true)  # o som se cala na hora, mesmo antes do aviso da primeira vez
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
	som.definir_escondida(_minimizada)
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
	som.encerrar()
	get_tree().quit()


## Também quando o jogo fecha por outro caminho (a captura dos testes, por exemplo).
func _exit_tree() -> void:
	if vista and vista.sim:
		vista.sim.encerrar()
	_parar_atalho_global()
	if som:
		som.encerrar()


func _parar_atalho_global() -> void:
	if _atalho_pid != 0:
		OS.kill(_atalho_pid)
		_atalho_pid = 0
		_atalho_leitor.wait_to_finish()


## O botão da lupa: sobe (2x, 3x, 4x e volta a 2x) ou desce (com o botão direito), só até
## a maior escala que cabe na tela; ao crescer, _aplicar_escala puxa a janela para dentro.
func _ciclar_escala(direcao: int) -> void:
	var area := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	var maior := ESCALA_MIN
	for k in range(ESCALA_MIN, ESCALA_MAX + 1):
		if BASE.x * k <= area.size.x and BASE.y * k <= area.size.y:
			maior = k
	if DisplayServer.get_name() == "headless" or not area.has_area():
		maior = ESCALA_MAX  # sem tela (os testes): só a escala conta
	var nova := escala + direcao
	if nova > maior:
		nova = ESCALA_MIN
	elif nova < ESCALA_MIN:
		nova = maior
	_aplicar_escala(nova)
	interface._avisar("Tamanho: %dx" % escala)


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
	interface.escala_atual = escala
	interface._montar_botoes()
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


## A caixa de preces abriu: o passo (e o último evento) dessa leitura, para o ponto de "não lida".
func _guardar_preces_lidas(marca: Dictionary) -> void:
	if not _usar_config:
		return
	var config := ConfigFile.new()
	config.load(ARQUIVO_CONFIG)
	config.set_value("preces", "lida", marca)
	config.save(ARQUIVO_CONFIG)


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
	if not _som_forcado:
		config.set_value("moldura", "som", som.ligado)
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
	# o ícone desenhado no tamanho da bandeja: 16 px em 100%, 24 em 150%, 32 em 200%
	var escala_tela := DisplayServer.screen_get_dpi(DisplayServer.SCREEN_PRIMARY) / 96.0
	var lado := 32 if escala_tela >= 1.75 else (24 if escala_tela >= 1.25 else 16)
	_bandeja.icon = load("res://arte/interface/icone_jogo_%d.png" % lado)
	_log("bandeja: dpi=%d ícone %d px" % [DisplayServer.screen_get_dpi(DisplayServer.SCREEN_PRIMARY), lado])
	_bandeja.tooltip = "Simulador de vida: clique para mostrar ou esconder; botão direito para o menu"
	_bandeja.pressed.connect(_ao_clicar_bandeja)
	add_child(_bandeja)
	# o menu sai como janela própria, perto do relógio (embutido, ficaria preso dentro da moldura)
	get_window().gui_embed_subwindows = false
	_menu_bandeja = PopupMenu.new()
	_menu_bandeja.add_item("Esconder", MENU_JANELA)
	_menu_bandeja.add_check_item("Som ligado", MENU_SOM)
	_menu_bandeja.add_separator()
	_menu_bandeja.add_item("Sair", MENU_SAIR)
	_menu_bandeja.id_pressed.connect(_no_menu_da_bandeja)
	add_child(_menu_bandeja)


func _ao_clicar_bandeja(botao: int, posicao: Vector2i) -> void:
	if botao == MOUSE_BUTTON_LEFT:
		alternar()
	elif botao == MOUSE_BUTTON_RIGHT:
		abrir_menu_da_bandeja(posicao)


## O menu da bandeja, acima do ponto do clique: dá para calar o jogo numa reunião sem abrir a janela.
func abrir_menu_da_bandeja(posicao: Vector2i) -> void:
	_menu_bandeja.set_item_text(_menu_bandeja.get_item_index(MENU_JANELA), "Mostrar" if escondida else "Esconder")
	_menu_bandeja.set_item_checked(_menu_bandeja.get_item_index(MENU_SOM), som.ligado)
	_menu_bandeja.reset_size()
	var tamanho := _menu_bandeja.get_contents_minimum_size()
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.get_screen_from_rect(Rect2(posicao, Vector2.ONE)))
	var canto := Vector2i(posicao.x - int(tamanho.x), posicao.y - int(tamanho.y))
	canto.x = clampi(canto.x, area.position.x, area.end.x - int(tamanho.x))
	canto.y = clampi(canto.y, area.position.y, area.end.y - int(tamanho.y))
	_menu_bandeja.popup(Rect2i(canto, Vector2i(tamanho)))
	_log("menu da bandeja")


## Teste (--menu-bandeja): abre o menu perto do canto da tela e, 1 s depois, escolhe o item.
func _testar_menu_da_bandeja(item: String) -> void:
	if _menu_bandeja == null:
		return
	abrir_menu_da_bandeja(DisplayServer.screen_get_usable_rect().end - Vector2i(40, 4))
	if item == "":
		return
	await get_tree().create_timer(1.0).timeout
	_menu_bandeja.hide()
	_no_menu_da_bandeja({"janela": MENU_JANELA, "som": MENU_SOM, "sair": MENU_SAIR}[item])


func _no_menu_da_bandeja(id: int) -> void:
	match id:
		MENU_JANELA:
			alternar()
		MENU_SOM:
			_alternar_som()
		MENU_SAIR:
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

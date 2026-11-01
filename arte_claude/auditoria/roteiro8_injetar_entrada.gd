extends Node
## Auditoria 8: injeta mouse e teclado em tempos marcados, pelo mesmo caminho da entrada de
## verdade (Input.parse_input_event). Usado com a sessão do Windows bloqueada, sem tela nem mouse.
## Para usar: copie para jogo/apresentacao/_roteiro.gd e, no _ready() de moldura.gd, logo depois
## de ler os argumentos:
##     if args.has("roteiro"):
##         add_child(load("res://apresentacao/_roteiro.gd").new(args["roteiro"]))
## Rode com -- --roteiro=passos.json (veja capturas8/roteiro_sessao1.json) e desfaça depois.
## Passos: [t, "mover"|"apertar"|"soltar", x, y] ou [t, "tecla", "C"], com x e y na tela base (480 × 178).
var passos: Array = []
var t := 0.0
var i := 0

func _init(caminho: String) -> void:
	passos = JSON.parse_string(FileAccess.get_file_as_string(caminho))

func _process(delta: float) -> void:
	t += delta
	while i < passos.size() and t >= float(passos[i][0]):
		_fazer(passos[i])
		i += 1

func _fazer(p: Array) -> void:
	var esc: float = get_window().size.x / 480.0
	var tipo: String = p[1]
	print("[roteiro] t=%.1f %s" % [t, str(p)])
	if tipo == "tecla":
		for apertado in [true, false]:
			var ev := InputEventKey.new()
			ev.keycode = OS.find_keycode_from_string(String(p[2]))
			ev.physical_keycode = ev.keycode
			ev.pressed = apertado
			Input.parse_input_event(ev)
		return
	var pos := Vector2(float(p[2]), float(p[3])) * esc
	if tipo == "mover":
		var ev := InputEventMouseMotion.new()
		ev.position = pos
		ev.global_position = pos
		Input.parse_input_event(ev)
	else:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = tipo == "apertar"
		Input.parse_input_event(ev)

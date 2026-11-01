extends Node2D
## Interface na moldura (arte/interface/): a alça com os botões, a dica do
## cursor, o leitor da crônica, o gesto dos poderes e mensagens curtas.
##
## A alça fica na faixa de cima (18 px). Ela é discreta: mostra o poder e o
## ritmo atuais e só se abre para mostrar as opções quando o jogador clica.
## Os ícones só aparecem sobre fundo escuro (a alça ou uma caixa de dica),
## nunca direto sobre o céu.
##
## O gesto: com um poder escolhido, segurar o botão sobre o mundo carrega a
## intensidade (0 a 1 em 2 s); soltar usa o poder ali. O botão direito cancela.

signal largura_mudou
signal arrastar
signal esconder
signal escala(delta: int)

const Arte = preload("res://apresentacao/arte.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")

const ALTURA_ALCA := 18
const PEGA := 10          # largura da zona de arraste à esquerda
const BOTAO := 16
const PASSO_BOTAO := 17
const PODERES := ["chuva", "raio", "fogo", "fartura", "erguer_terra", "sonho"]
## Nome do poder no núcleo e na tela.
const PODER_NUCLEO := {"chuva": "chuva", "raio": "raio", "fogo": "fogo", "fartura": "fartura",
	"erguer_terra": "erguer", "sonho": "sonho"}
const NOME_PODER := {"chuva": "Chuva", "raio": "Raio", "fogo": "Fogo", "fartura": "Fartura",
	"erguer_terra": "Erguer a terra", "sonho": "Sonho"}
const RITMOS := ["pausa", "normal", "rapido", "salto"]
const NOME_RITMO := {"pausa": "Pausa", "normal": "Ritmo normal", "rapido": "Ritmo rápido",
	"salto": "Saltar ao próximo acontecimento"}
const NOME_GRAU := {"sinal": "um sinal", "milagre": "um milagre", "imposicao": "uma imposição"}
const NOME_TRACO := {"pacifico": "pacífico", "devoto": "devoto", "curioso": "curioso",
	"ambicioso": "ambicioso", "rancoroso": "rancoroso", "desconfiado": "desconfiado",
	"generoso": "generoso", "engenhoso": "engenhoso", "corajoso": "corajoso", "medroso": "medroso"}
const NOME_ZONA := {"lago": "O lago", "praia": "A praia", "floresta": "A floresta", "morro": "O morro"}
const NECESSIDADES := ["seca", "fome", "doenca", "frio", "guerra"]
const CARGA_SEGUNDOS := 2.0

var vista: Node2D
var poder := ""            # poder escolhido ("" = nenhum)
var aberto := ""           # "poderes", "ritmo" ou ""
var botoes: Array = []     # [{id, rect, icone, selecionado}]

var _icones := {}
var _alca: Texture2D
var _botao: Texture2D
var _sob_cursor := ""
var _carregando := false
var _carga_inicio := 0.0
var _carga_ponto := Vector2.ZERO
var _cursor := Vector2(-100, -100)
var _dica: NinePatchRect
var _dica_textos: Array[Label] = []
var _dica_icone: TextureRect
var _cronica: NinePatchRect
var _cronica_texto: Label
var _cronica_titulo: Label
var _cronica_rolagem := 0
var _mensagem := ""
var _mensagem_ate := 0.0
var _fontes := {}
var _relogio := 0.0
var _ultimo_desenho := []


func criar(p_vista: Node2D) -> void:
	vista = p_vista
	_alca = Arte.textura("interface/alca_9s.png")
	_botao = Arte.textura("interface/botao_3q.png")
	for nome in PODERES + RITMOS + ["cronica", "linhagem", "esconder"]:
		_icones[nome] = Arte.textura("interface/icones_12/%s.png" % nome)
		_icones[nome + "_8"] = Arte.textura("interface/icones_8/%s.png" % nome)
	for cor in ["clara", "escura", "dourada"]:
		_fontes[cor] = load("res://arte/interface/fonte_5x7_%s.fnt" % cor)
	_criar_dica()
	_criar_cronica()
	_montar_botoes()


func largura() -> int:
	return PEGA + botoes.size() * PASSO_BOTAO + 4


# --- alça ------------------------------------------------------------------

func _montar_botoes() -> void:
	var ritmo := _ritmo_atual()
	var lista := []
	if aberto == "poderes":
		for p in PODERES:
			lista.append({"id": "poder:" + p, "icone": p, "selecionado": p == poder})
	else:
		lista.append({"id": "poderes", "icone": poder if poder != "" else "chuva", "selecionado": poder != ""})
	if aberto == "ritmo":
		for r in RITMOS:
			lista.append({"id": "ritmo:" + r, "icone": r, "selecionado": r == ritmo})
	else:
		lista.append({"id": "ritmo", "icone": ritmo, "selecionado": false})
	lista.append({"id": "cronica", "icone": "cronica", "selecionado": _cronica.visible})
	lista.append({"id": "linhagem", "icone": "linhagem", "selecionado": vista.seguindo})
	lista.append({"id": "esconder", "icone": "esconder", "selecionado": false})
	var antes := botoes.size()
	botoes = []
	for i in lista.size():
		var b: Dictionary = lista[i]
		b["rect"] = Rect2i(PEGA + i * PASSO_BOTAO, 1, BOTAO, BOTAO)
		botoes.append(b)
	if botoes.size() != antes:
		largura_mudou.emit()
	queue_redraw()


func _ritmo_atual() -> String:
	if vista.sim == null:
		return "normal"
	match vista.sim.ritmo:
		Simulacao.Ritmo.PAUSA:
			return "pausa"
		Simulacao.Ritmo.RAPIDO:
			return "rapido"
	return "normal"


func _botao_em(p: Vector2) -> Dictionary:
	for b in botoes:
		if b.rect.has_point(Vector2i(p)):
			return b
	return {}


func _apertar(id: String) -> void:
	if id == "poderes":
		aberto = "" if aberto == "poderes" else "poderes"
	elif id.begins_with("poder:"):
		var p := id.substr(6)
		poder = "" if p == poder else p
		aberto = ""
		_avisar(NOME_PODER[poder] + ": segure sobre o mundo" if poder != "" else "Nenhum poder escolhido")
	elif id == "ritmo":
		aberto = "" if aberto == "ritmo" else "ritmo"
	elif id.begins_with("ritmo:"):
		aberto = ""
		match id.substr(6):
			"pausa":
				vista.sim.definir_ritmo(Simulacao.Ritmo.PAUSA)
			"normal":
				vista.sim.definir_ritmo(Simulacao.Ritmo.NORMAL)
			"rapido":
				vista.sim.definir_ritmo(Simulacao.Ritmo.RAPIDO)
			"salto":
				_saltar()
	elif id == "cronica":
		alternar_cronica()
	elif id == "linhagem":
		vista.alternar_seguir()
		_avisar(_texto_linhagem())
	elif id == "esconder":
		esconder.emit()
	_montar_botoes()


func _saltar() -> void:
	var antes: Dictionary = vista.sim.tempo
	var eventos: Array = vista.sim.saltar()
	var depois: Dictionary = vista.sim.tempo
	var dias: int = (depois["ano"] - antes["ano"]) * 40 + depois["dia"] - antes["dia"]
	var nota := ""
	for ev in eventos:
		if ev["camada"] != "ambiente":
			nota = _nome_evento(ev["tipo"])
			break
	_avisar(("Passaram %d dias. " % dias if dias > 0 else "") + (nota if nota != "" else "Nada de notável."))


func _texto_linhagem() -> String:
	var m = vista.sim.mundo
	if m.acompanhada < 0:
		return "A linhagem acabou."
	var nome: String = m.pessoa(m.acompanhada).nome
	return ("Seguindo " if vista.seguindo else "Acompanhando ") + nome


# --- entrada (a moldura repassa; devolve true se usou o evento) --------------

func tratar(event: InputEvent, pos: Vector2, faixa: int) -> bool:
	_cursor = pos
	var na_alca := pos.y < faixa and pos.x < largura()
	if event is InputEventMouseMotion:
		var b := _botao_em(pos) if na_alca else {}
		var novo: String = b.get("id", "")
		if novo != _sob_cursor:
			_sob_cursor = novo
			queue_redraw()
		if _cronica.visible:
			return true
		if not na_alca and pos.y >= faixa:
			_atualizar_dica(vista.para_mundo(pos - Vector2(0, faixa)), pos)
		elif not novo.is_empty():
			_mostrar_dica_botao(novo, Vector2(b.rect.position) + Vector2(0, faixa))
		else:
			_dica.visible = false
		return false
	if event is InputEventMouseButton:
		if OS.has_environment("DEPURAR_ALCA"):
			print("[alca] botao=%d apertado=%s duplo=%s pos=%s botoes=%s" % [event.button_index, event.pressed,
				event.double_click, pos, botoes.map(func(b): return [b.id, b.rect.position.x])])
		# No Windows, um clique rápido depois de outro chega duas vezes: o
		# "apertou" normal e outro marcado como duplo, sem soltar no meio.
		# O segundo apertaria o botão de novo ou reiniciaria a carga do gesto.
		if event.double_click:
			return true
		if event.pressed and na_alca:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var b := _botao_em(pos)
				if b.is_empty():
					arrastar.emit()
				else:
					_apertar(b.id)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				escala.emit(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				escala.emit(-1)
			return true
		if _cronica.visible:
			if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_rolar(-2)
			elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_rolar(2)
			elif event.pressed and not _cronica.get_rect().has_point(pos):
				alternar_cronica()
			return true
		if pos.y < faixa:
			return false
		var mundo_p: Vector2 = vista.para_mundo(pos - Vector2(0, faixa))
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and poder != "":
				_carregando = true
				_carga_inicio = _relogio
				_carga_ponto = mundo_p
				_dica.visible = false
			elif not event.pressed and _carregando:
				_carregando = false
				_usar_poder()
			elif event.pressed:
				vista.clicar(pos - Vector2(0, faixa))
			queue_redraw()
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _carregando:
				_carregando = false
				_avisar("Cancelado")
			elif poder != "":
				poder = ""
				_montar_botoes()
			queue_redraw()
			return true
	return false


func tecla(keycode: int) -> bool:
	match keycode:
		KEY_C:
			alternar_cronica()
		KEY_L:
			_apertar("linhagem")
		KEY_D:
			vista.modo_discreto = not vista.modo_discreto
			_avisar("Modo discreto ligado" if vista.modo_discreto else "Modo discreto desligado")
		KEY_SPACE:
			_apertar("ritmo:normal" if vista.sim.ritmo == Simulacao.Ritmo.PAUSA else "ritmo:pausa")
		KEY_ESCAPE:
			if _cronica.visible:
				alternar_cronica()
			elif poder != "" or _carregando:
				_carregando = false
				poder = ""
				_montar_botoes()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			return false
		_:
			return false
	return true


## Usa um poder como se o jogador tivesse feito o gesto (testes e capturas).
func demo(p: String, x: float, intensidade_fixa: float) -> void:
	poder = p
	_carga_ponto = Vector2(x, 100)
	_carga_inicio = _relogio - intensidade_fixa * CARGA_SEGUNDOS
	_usar_poder()
	_montar_botoes()


func intensidade() -> float:
	return clampf((_relogio - _carga_inicio) / CARGA_SEGUNDOS, 0.0, 1.0)


func _usar_poder() -> void:
	var r: Dictionary = vista.sim.usar_poder(PODER_NUCLEO[poder], _carga_ponto.x, intensidade())
	print("[interface] poder %s em x=%d intensidade=%.2f -> %s" % [poder, _carga_ponto.x, intensidade(), r])
	if r.get("ok", false):
		var alvo := ""
		if int(r.get("alvo", -1)) >= 0:
			alvo = " sobre " + String(vista.sim.mundo.pessoa(r["alvo"]).nome)
		_avisar("%s: %s%s" % [NOME_PODER[poder], NOME_GRAU.get(r.get("grau", ""), ""), alvo])
	else:
		_avisar(String(r.get("motivo", "Não deu certo")))


func avancar(delta: float) -> void:
	_relogio += delta
	var assinatura := [_carregando, int(intensidade() * 8.0) if _carregando else 0,
		_mensagem if _relogio < _mensagem_ate else "", _ritmo_atual(), vista.seguindo]
	if assinatura != _ultimo_desenho:
		if _ultimo_desenho.size() > 3 and (assinatura[3] != _ultimo_desenho[3] or assinatura[4] != _ultimo_desenho[4]):
			_montar_botoes()
		_ultimo_desenho = assinatura
		queue_redraw()


func _avisar(texto: String) -> void:
	_mensagem = texto
	_mensagem_ate = _relogio + 2.5
	queue_redraw()


# --- dica do cursor ----------------------------------------------------------

func _criar_dica() -> void:
	_dica = NinePatchRect.new()
	_dica.texture = Arte.textura("interface/caixa_dica_9s.png")
	_dica.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	_dica.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_dica.set_patch_margin(lado, 4)
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.visible = false
	add_child(_dica)
	for i in 4:
		var l := Label.new()
		l.add_theme_font_override("font", _fontes["dourada" if i == 0 else "clara"])
		l.add_theme_constant_override("line_spacing", 0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dica.add_child(l)
		_dica_textos.append(l)
	_dica_icone = TextureRect.new()
	_dica_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_child(_dica_icone)


func _atualizar_dica(p: Vector2, tela: Vector2) -> void:
	if _carregando:
		return
	var o: Dictionary = vista.objeto_em(p)
	var linhas: Array = []
	var icone := -1
	match o.get("tipo", ""):
		"pessoa":
			var pe: Dictionary = o.pessoa
			var titulo := "%s, %d anos" % [pe["nome"], pe["idade"]]
			linhas.append(titulo)
			var detalhes := ", ".join(pe["tracos"].map(func(t): return NOME_TRACO.get(t, t)))
			if pe["papel"] != "":
				detalhes = ("líder" if pe["papel"] == "lider" else "sacerdote" if pe["sexo"] == "m" else "sacerdotisa") \
					+ ", " + detalhes
			linhas.append(detalhes)
			if pe.get("acompanhada", false):
				linhas.append("a linhagem que você segue")
			if not o.prece.is_empty():
				linhas.append("reza: " + o.prece["texto"])
				icone = NECESSIDADES.find(o.prece["necessidade"])
		"sinal":
			var pr: Dictionary = o.prece
			var autor = vista.sim.mundo.pessoa(pr["autor"])
			linhas.append("Prece de " + String(autor.nome))
			linhas.append(pr["texto"])
			linhas.append("espera há %d dias" % pr["dias"] if pr["dias"] != 1 else "espera há 1 dia")
			icone = NECESSIDADES.find(pr["necessidade"])
		"lugar":
			var z: Dictionary = o.zona
			linhas.append(NOME_ZONA.get(z["chave"], z["nome"]))
			var nomes: Array = []
			for g in z["nomes"]:
				nomes.append(z["nomes"][g])
			if not nomes.is_empty():
				linhas.append("chamado " + ", ".join(nomes.slice(0, 2)))
			var estado := []
			if z["seca"]:
				estado.append("em seca")
			if z["queimada"]:
				estado.append("queimada")
			if z["comida"] > 1.2:
				estado.append("farta")
			if not estado.is_empty():
				linhas.append(", ".join(estado))
	_mostrar_dica(linhas, icone, tela)


func _mostrar_dica_botao(id: String, canto: Vector2) -> void:
	var nome := ""
	if id.begins_with("poder:"):
		nome = NOME_PODER[id.substr(6)]
	elif id.begins_with("ritmo:"):
		nome = NOME_RITMO[id.substr(6)]
	else:
		nome = {"poderes": "Poderes", "ritmo": "Ritmo do tempo", "cronica": "Crônica (C)",
			"linhagem": "Seguir a linhagem (L)", "esconder": "Esconder (H)"}.get(id, "")
	_mostrar_dica([nome], -1, canto + Vector2(4, 22), false)


func _mostrar_dica(linhas: Array, icone: int, perto: Vector2, acima := true) -> void:
	if linhas.is_empty():
		_dica.visible = false
		return
	var largura_max := 160
	var y := 3
	var w := 0
	for i in _dica_textos.size():
		var l := _dica_textos[i]
		l.visible = i < linhas.size()
		if not l.visible:
			continue
		l.text = linhas[i]
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		var tamanho := l.get_minimum_size()
		if tamanho.x > largura_max:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(largura_max, 0)
			l.size = Vector2(largura_max, 0)
			tamanho = Vector2(largura_max, l.get_minimum_size().y)
		else:
			l.custom_minimum_size = Vector2.ZERO
			l.size = tamanho
		l.position = Vector2(5, y)
		y += int(tamanho.y)
		w = maxi(w, int(tamanho.x))
	var extra := 0
	_dica_icone.visible = icone >= 0
	if icone >= 0:
		var at := AtlasTexture.new()
		at.atlas = Arte.textura("sinais/necessidade_5v.png")
		at.region = Rect2(icone * 8, 0, 8, 8)
		_dica_icone.texture = at
		_dica_icone.position = Vector2(w + 8, 4)
		extra = 10
	var tamanho_caixa := Vector2(w + 10 + extra, y + 3)
	_dica.size = tamanho_caixa
	var pos := perto + Vector2(-tamanho_caixa.x / 2.0, -tamanho_caixa.y - 6) if acima else perto
	pos.x = clampf(pos.x, 1, 480 - tamanho_caixa.x - 1)
	if pos.y < 19:
		pos.y = perto.y + 10
	pos.y = clampf(pos.y, 19, 178 - tamanho_caixa.y - 1)
	_dica.position = pos.round()
	_dica.visible = true


# --- crônica -----------------------------------------------------------------

func _criar_cronica() -> void:
	_cronica = NinePatchRect.new()
	_cronica.texture = Arte.textura("interface/caixa_cronica_9s.png")
	_cronica.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	_cronica.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_cronica.set_patch_margin(lado, 6)
	_cronica.position = Vector2(24, 22)
	_cronica.size = Vector2(432, 152)
	_cronica.visible = false
	_cronica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cronica)
	var recorte := Control.new()
	recorte.clip_contents = true
	recorte.position = Vector2(10, 8)
	recorte.size = Vector2(412, 132)  # ajustado a linhas inteiras em _rolar()
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cronica.add_child(recorte)
	_cronica_texto = Label.new()
	_cronica_texto.add_theme_font_override("font", _fontes["escura"])
	_cronica_texto.add_theme_constant_override("line_spacing", 0)
	_cronica_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cronica_texto.size = Vector2(412, 0)
	_cronica_texto.custom_minimum_size = Vector2(412, 0)
	recorte.add_child(_cronica_texto)


func alternar_cronica() -> void:
	_cronica.visible = not _cronica.visible
	_dica.visible = false
	if _cronica.visible:
		mostrar_cronica("")
	_montar_botoes()


## Abre a crônica; `antes` vem em cima (o relato da ausência, por exemplo).
func mostrar_cronica(antes: String) -> void:
	var m = vista.sim.mundo
	var texto := ""
	if antes != "":
		texto = antes + "\n\n"
	var t: Dictionary = vista.sim.tempo
	texto += _sem_markdown(m.cronica()) + "\n\nAno %d, dia %d: o ano ainda está em curso." % [t["ano"], t["dia"]]
	_cronica_texto.text = texto
	_cronica.visible = true
	_cronica_texto.size.y = 0
	_montar_botoes()
	# começa no fim, onde está o mais recente (as linhas só existem depois do layout)
	await get_tree().process_frame
	_cronica_rolagem = _cronica_texto.get_line_count() if antes == "" else 0
	_rolar(0)


func _rolar(d: int) -> void:
	var altura := _cronica_texto.get_line_height()
	var cabem := int(136 / altura)
	_cronica_texto.get_parent().size.y = cabem * altura
	var linhas := _cronica_texto.get_line_count()
	_cronica_rolagem = clampi(_cronica_rolagem + d, 0, maxi(0, linhas - cabem))
	_cronica_texto.position.y = -_cronica_rolagem * altura


static func _sem_markdown(md: String) -> String:
	var r := []
	var titulo := false
	for linha in md.split("\n"):
		var l := linha.strip_edges()
		if titulo and l == "":
			continue  # o parágrafo vem logo abaixo do título do ano
		titulo = l.begins_with("#")
		while l.begins_with("#"):
			l = l.substr(1)
		l = l.strip_edges().replace("**", "").replace("*", "").replace("_", " ")
		l = l.replace("“", "«").replace("”", "»").replace("’", "'")
		if l.begins_with("> "):
			l = l.substr(2)
		r.append(l)
	var texto := "\n".join(r)
	while texto.contains("\n\n\n"):
		texto = texto.replace("\n\n\n", "\n\n")
	return texto.strip_edges()


static func _nome_evento(tipo: String) -> String:
	return {"prece": "Alguém rezou.", "nascimento": "Nasceu alguém.", "gemeos": "Nasceram gêmeos.",
		"morte": "Alguém morreu.", "casamento": "Houve um casamento.",
		"casamento_entre_grupos": "Dois povos se uniram num casamento.", "fome_inicio": "Começou uma fome.",
		"fome_fim": "A fome passou.", "doenca_inicio": "Começou uma doença.", "doenca_fim": "A doença passou.",
		"ataque": "Houve um ataque.", "rixa": "Houve uma briga.", "roubo": "Houve um roubo.",
		"guerra_inicio": "Começou uma guerra.", "guerra_fim": "Uma guerra acabou.", "tregua": "Houve uma trégua.",
		"conquista": "Um povo conquistou outro.", "fusao": "Dois povos viraram um.",
		"crenca": "Um povo passou a crer.", "nova_crenca": "Nasceu uma nova crença.",
		"deus_renomeado": "O deus ganhou um novo nome.", "sacerdote": "Surgiu um sacerdote.",
		"edito": "Um sacerdote ditou uma regra.", "exigencia": "O povo fez uma exigência ao deus.",
		"reforma": "A fé mudou.", "silencio": "O deus ficou em silêncio.", "desamparo": "Um povo se sentiu desamparado.",
		"culpado": "Culparam alguém.", "dependencia": "Um povo depende do deus.",
		"separacao": "Um povo se dividiu.", "mudanca": "Um povo se mudou.", "expedicao": "Partiu uma expedição.",
		"extincao_grupo": "Um povo acabou.", "novo_lider": "Há um novo líder.", "agricultura": "Nasceu a agricultura.",
		"descoberta": "Alguém descobriu algo.", "conhecimento_perdido": "Um saber se perdeu.",
		"costume": "Nasceu um costume.", "costume_esquecido": "Um costume foi esquecido.",
		"cultura": "A cultura de um povo mudou.", "lugar_nomeado": "Um lugar ganhou nome.",
		"tempestade": "Veio uma tempestade.", "inverno_rigoroso": "Veio um inverno duro.",
		"seca_inicio": "Começou uma seca.", "seca_fim": "A seca acabou.", "eclipse": "Houve um eclipse.",
		"cometa": "Passou um cometa.", "terremoto": "A terra tremeu.", "fartura_natural": "Veio uma fartura.",
		"os_ultimos": "Restam poucos.", "fim_do_mundo": "Não resta ninguém.", "linhagem": "A linhagem passou adiante.",
		"prece_atendida": "Uma prece foi atendida.", "prece_sem_resposta": "Uma prece ficou sem resposta."}.get(
		tipo, "Algo aconteceu.")


# --- desenho -------------------------------------------------------------------

## Caixa em 9 partes: os cantos ficam fixos, as bordas e o miolo repetem.
func _desenhar_9(tex: Texture2D, r: Rect2, m: int) -> void:
	var t := tex.get_size()
	var xs := [0.0, m, t.x - m, t.x]
	var ys := [0.0, m, t.y - m, t.y]
	var dx := [r.position.x, r.position.x + m, r.end.x - m, r.end.x]
	var dy := [r.position.y, r.position.y + m, r.end.y - m, r.end.y]
	for j in 3:
		for i in 3:
			var sw: float = xs[i + 1] - xs[i]
			var sh: float = ys[j + 1] - ys[j]
			var y: float = dy[j]
			while y < dy[j + 1]:
				var h := minf(sh, dy[j + 1] - y)
				var x: float = dx[i]
				while x < dx[i + 1]:
					var w := minf(sw, dx[i + 1] - x)
					draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(xs[i], ys[j], w, h))
					x += sw
				y += sh


func _draw() -> void:
	_desenhar_9(_alca, Rect2(0, 0, largura(), ALTURA_ALCA), 4)
	for y in [5, 8, 11]:  # pega de arraste
		for x in [3, 6]:
			draw_rect(Rect2(x, y, 2, 1), Arte.paleta[12])
	for b in botoes:
		var q := 2 if b.selecionado else (1 if b.id == _sob_cursor else 0)
		draw_texture_rect_region(_botao, Rect2(b.rect), Rect2(q * BOTAO, 0, BOTAO, BOTAO))
		draw_texture(_icones[b.icone], Vector2(b.rect.position) + Vector2(2, 2))
	if _carregando:
		# caixa escura junto ao cursor com o ícone do poder e a carga
		var tela: Vector2 = vista.para_tela(_carga_ponto) + Vector2(0, ALTURA_ALCA)
		var r := Rect2((tela + Vector2(-17, -20)).round(), Vector2(34, 12))
		r.position.y = maxf(r.position.y, ALTURA_ALCA + 1)
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), r, 4)
		draw_texture(_icones[poder + "_8"], r.position + Vector2(2, 2))
		var n := int(intensidade() * 20.0)
		for i in 20:
			var cor: Color = Arte.paleta[22 if i < n else 3]
			draw_rect(Rect2(r.position.x + 12 + i, r.position.y + 5, 1, 2), cor)
	if _relogio < _mensagem_ate and _mensagem != "":
		var fonte: Font = _fontes["clara"]
		var w := int(fonte.get_string_size(_mensagem).x)
		var r := Rect2(largura() + 2, 2, w + 10, 14)
		if r.end.x > 480:
			r.position = Vector2(480 - r.size.x, ALTURA_ALCA + 1)
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), r, 4)
		draw_string(fonte, r.position + Vector2(5, 11), _mensagem)

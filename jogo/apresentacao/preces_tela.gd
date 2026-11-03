extends Node2D
## A caixa de preces (pedido do autor em 03/11/2026): um pergaminho à direita,
## por cima do mundo (logo abaixo da alça), que não cobre o mundo todo. No topo,
## cada povo que reza com o termômetro de fé dele (sem número: a cor diz quanto,
## a seta diz se esquenta ou esfria). Embaixo, as preces, da mais nova para a mais
## antiga: quem rezou e o povo, quando, as palavras da pessoa e o estado (esperando,
## atendida, atendida mas não por você, sem resposta). Grupos que não rezam ficam
## de fora: o ponto cego continua.
##
## Clicar numa prece leva a vista até quem rezou, se a pessoa vive. A roda e as
## setas rolam; Esc, o botão direito ou um clique fora fecham.
##
## Os dados vêm do núcleo (preces_historico, fe_do_povo, preces_novas_desde).
## Enquanto o núcleo não os tem, a caixa mostra o que já existe (as preces
## abertas e a fé média das pessoas); --preces-falsas enche a caixa com preces
## de mentira, com os nomes do mundo, para ver o desenho (testes).

signal fechada
signal ir_ate(id: int)  # a vista vai até a pessoa

const Arte = preload("res://apresentacao/arte.gd")
const Mundo = preload("res://nucleo/mundo.gd")
const TAM_FONTE := 11
const ALTURA_LINHA := 11
const CAIXA := Rect2i(180, 3, 296, 154)   # em coordenadas do mundo (480 × 160); o mundo segue à esquerda
const MARGEM := 8
const LISTA_TOPO := 28                      # y da lista, dentro da caixa, abaixo da linha dos povos
const LINHAS_TEXTO := 2                     # as palavras da prece: até duas linhas (a terceira ganha reticências)
const NOME_ESTADO := {"esperando": "esperando", "atendida": "atendida",
	"falso_milagre": "atendida, mas não por você", "sem_resposta": "sem resposta"}
const COR_ESTADO := {"esperando": 2, "atendida": 15, "falso_milagre": 29, "sem_resposta": 20}  # paleta
const TERMOMETRO := Vector2i(22, 5)         # o tubo; o bulbo fica à esquerda

var interface: Node2D
var vista: Node2D
var falsas := false
var preces: Array = []   # as preces, já com as linhas quebradas: {..., linhas: [String], altura}
var povos: Array = []    # [{id, nome, nivel 0..1, tendencia -1..1}]
var _rolagem := 0        # px rolados da lista
var _sob := -1
var _fe_antes := {}      # gid -> [dia, nível]: a fé de um dia antes (a tendência sem o núcleo)
var _rects_povos: Array = []  # [Rect2i] de cada povo no topo, para a dica
var custo_desenho_us := 0     # quanto custou o último desenho (o teste confere que não pesa)
var _falsas_feitas: Array = []  # as preces de mentira, feitas uma vez
var _pergaminho: Texture2D    # o fundo da caixa, montado uma vez (as 9 partes em ladrilhos eram centenas de desenhos)


func criar(p_interface: Node2D, p_vista: Node2D) -> void:
	interface = p_interface
	vista = p_vista
	position = Vector2(0, interface.ALTURA_ALCA)
	visible = false


func abrir() -> void:
	carregar()
	_rolagem = 0
	_sob = -1
	visible = true
	queue_redraw()


func fechar() -> void:
	if not visible:
		return
	visible = false
	interface._dica.visible = false
	fechada.emit()


## Lê as preces e a fé dos povos (na abertura e quando chegam preces com a caixa aberta).
func carregar() -> void:
	preces = []
	var fonte: Font = interface._fontes["escura"]
	for p in historico():
		var q: Dictionary = p.duplicate()
		var linhas: Array = interface._estante._quebrar_linhas("\"%s\"" % String(p.get("texto", "")), fonte, CAIXA.size.x - 2 * MARGEM - 6)
		if linhas.size() > LINHAS_TEXTO:
			linhas = linhas.slice(0, LINHAS_TEXTO)
			linhas[-1] = String(linhas[-1]).substr(0, maxi(0, String(linhas[-1]).length() - 2)) + "…"
		q["linhas"] = linhas
		q["altura"] = (2 + linhas.size()) * ALTURA_LINHA + 4
		preces.append(q)
	povos = []
	var vistos := {}
	for g in _grupos_que_rezam():
		vistos[g.id] = true
		var f := fe(g.id)
		povos.append({"id": g.id, "nome": g.nome, "nivel": f["nivel"], "tendencia": f["tendencia"]})
	if falsas and povos.size() < 2:
		povos.append({"id": -1, "nome": "Ourem", "nivel": 0.25, "tendencia": -0.5})
	queue_redraw()


# --- dados -------------------------------------------------------------------

func _mundo():
	return vista.sim.mundo if vista.sim else null


## As preces, da mais nova para a mais antiga: {evento, autor, nome, grupo, povo,
## ano, dia, texto, estado, vivo, passo}.
func historico() -> Array:
	var m = _mundo()
	if m == null:
		return []
	if falsas:
		return _falsas()
	if m.has_method("preces_historico"):
		return m.preces_historico()
	# sem o núcleo novo: as preces abertas, todas esperando
	var r: Array = []
	for p in vista.sim.preces:
		var autor = m.pessoa(int(p["autor"]))
		var g = m.grupo(int(p["grupo"]))
		var desde := int(p["desde"])
		r.append({"evento": int(p["evento"]), "autor": int(p["autor"]), "nome": autor.nome if autor else "?",
			"grupo": int(p["grupo"]), "povo": g.nome if g else "", "ano": desde / Mundo.DIAS_ANO + 1,
			"dia": desde % Mundo.DIAS_ANO + 1, "texto": String(p.get("curto", p.get("texto", ""))),
			"estado": "esperando", "vivo": autor != null and autor.vivo, "passo": desde * Mundo.HORAS_DIA})
	r.sort_custom(func(a, b): return a["evento"] > b["evento"])
	return r


## A fé média de um povo, 0..1, e a tendência, -1 (esfria) a 1 (esquenta).
func fe(gid: int) -> Dictionary:
	var m = _mundo()
	if falsas:
		return {"nivel": [0.8, 0.45, 0.2][absi(gid) % 3], "tendencia": [0.6, 0.0, -0.6][absi(gid) % 3]}
	if m == null:
		return {"nivel": 0.5, "tendencia": 0.0}
	if m.has_method("fe_do_povo"):
		var f: Dictionary = m.fe_do_povo(gid)
		return {"nivel": clampf(float(f.get("nivel", 0.5)), 0.0, 1.0), "tendencia": clampf(float(f.get("tendencia", 0.0)), -1.0, 1.0)}
	# sem o núcleo novo: a média da fé das pessoas (-1..1), e a tendência contra a de um dia antes
	var g = m.grupo(gid)
	if g == null or g.membros.is_empty():
		return {"nivel": 0.5, "tendencia": 0.0}
	var soma := 0.0
	for id in g.membros:
		soma += float(m.pessoa(id).fe)
	var nivel := clampf((soma / g.membros.size() + 1.0) / 2.0, 0.0, 1.0)
	var dia: int = m.dia_abs()
	var antes: Array = _fe_antes.get(gid, [dia, nivel])
	if dia - int(antes[0]) >= 1:
		_fe_antes[gid] = [dia, nivel]
	elif not _fe_antes.has(gid):
		_fe_antes[gid] = antes
	return {"nivel": nivel, "tendencia": clampf((nivel - float(antes[1])) * 20.0, -1.0, 1.0)}


## Quantas preces chegaram depois da última leitura ({passo, evento} guardados pela moldura).
func novas_desde(lida: Dictionary) -> int:
	var m = _mundo()
	if m == null:
		return 0
	if falsas:
		var n := 0
		for p in _falsas():
			if int(p["passo"]) > int(lida.get("passo", -1)):
				n += 1
		return n
	if m.has_method("preces_novas_desde"):
		return int(m.preces_novas_desde(int(lida.get("passo", -1))))
	var n := 0
	for p in vista.sim.preces:
		if int(p["evento"]) > int(lida.get("evento", -1)):
			n += 1
	return n


## O que guardar como "lido agora": o passo do mundo e o último evento.
func marca_de_leitura() -> Dictionary:
	var m = _mundo()
	if m == null:
		return {}
	return {"semente": int(m.semente), "passo": int(m.passo), "evento": int(m.eventos.size()) - 1}


## Os povos que rezam (os outros ficam no ponto cego): com crença, ou com prece na caixa.
func _grupos_que_rezam() -> Array:
	var m = _mundo()
	if m == null:
		return []
	var com_prece := {}
	for p in preces:
		com_prece[int(p.get("grupo", -1))] = true
	var r: Array = []
	for g in m.grupos_vivos():
		if g.tem_crenca or com_prece.has(g.id) or falsas:
			r.append(g)
	return r


## Preces de mentira com os nomes deste mundo (--preces-falsas): o desenho cheio.
func _falsas() -> Array:
	if not _falsas_feitas.is_empty():
		return _falsas_feitas
	var m = _mundo()
	var gente: Array = []
	for g in m.grupos_vivos():
		for id in g.membros:
			gente.append([m.pessoa(id), g])
	var textos := ["Que a chuva volte antes da colheita", "Proteja meu filho na guerra",
		"Por que nos abandonaste?", "Cura a febre da minha mãe, que não passa da lua nova",
		"Dá-nos peixe no lago, que as redes voltam vazias", "Que o frio não leve os pequenos",
		"Manda um sinal, um só, que eu acredito de novo", "Que o fogo da vila não se apague"]
	var estados := ["esperando", "atendida", "falso_milagre", "sem_resposta"]
	var r: Array = []
	var ano: int = m.ano()
	for i in textos.size():
		var pg: Array = gente[(i * 3) % gente.size()] if not gente.is_empty() else [null, null]
		r.append({"evento": 1000 - i, "autor": pg[0].id if pg[0] else -1, "nome": pg[0].nome if pg[0] else "Teo",
			"grupo": pg[1].id if pg[1] else -1, "povo": pg[1].nome if pg[1] else "Toan",
			"ano": maxi(1, ano - i / 3), "dia": 38 - i * 4, "texto": textos[i],
			"estado": estados[i % 4] if i > 0 else "esperando", "vivo": i != 3, "passo": m.passo - i * 30})
	_falsas_feitas = r
	return r


# --- entrada (pos em coordenadas do mundo da tela, 480 × 160) --------------------

func tratar(event: InputEvent, pos: Vector2) -> void:
	var p := Vector2i(pos)
	if event is InputEventMouseMotion:
		_mover(p, pos)
		return
	if not (event is InputEventMouseButton and event.pressed) or event.double_click:
		return
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			fechar()
		MOUSE_BUTTON_WHEEL_DOWN:
			rolar(ALTURA_LINHA * 2)
		MOUSE_BUTTON_WHEEL_UP:
			rolar(-ALTURA_LINHA * 2)
		MOUSE_BUTTON_LEFT:
			if not CAIXA.has_point(p):
				fechar()
				return
			var i := _prece_em(p)
			if i >= 0:
				escolher(i)


func tecla(keycode: int) -> bool:
	match keycode:
		KEY_ESCAPE:
			fechar()
		KEY_DOWN, KEY_PAGEDOWN:
			rolar(ALTURA_LINHA * (2 if keycode == KEY_DOWN else 8))
		KEY_UP, KEY_PAGEUP:
			rolar(-ALTURA_LINHA * (2 if keycode == KEY_UP else 8))
		_:
			return false
	return true


## Clicou na prece i: a vista vai até quem rezou, se vive.
func escolher(i: int) -> void:
	var q: Dictionary = preces[i]
	if not bool(q.get("vivo", false)) or int(q.get("autor", -1)) < 0:
		interface._avisar("%s não vive mais." % q.get("nome", "Quem rezou"))
		return
	fechar()
	ir_ate.emit(int(q["autor"]))


func rolar(d: int) -> void:
	var antes := _rolagem
	_rolagem = clampi(_rolagem + d, 0, _rolagem_max())
	if _rolagem != antes:
		queue_redraw()


func _altura_lista() -> int:
	return CAIXA.size.y - LISTA_TOPO - 6


func _rolagem_max() -> int:
	var total := 0
	for q in preces:
		total += int(q["altura"])
	return maxi(0, total - _altura_lista())


## A prece sob o ponto (só a parte visível da lista conta), ou -1.
func _prece_em(p: Vector2i) -> int:
	var y0 := CAIXA.position.y + LISTA_TOPO
	if p.x < CAIXA.position.x + 4 or p.x >= CAIXA.end.x - 4 or p.y < y0 or p.y >= y0 + _altura_lista():
		return -1
	var y := y0 - _rolagem
	for i in preces.size():
		var h := int(preces[i]["altura"])
		if p.y >= y and p.y < y + h:
			return i
		y += h
	return -1


func _mover(p: Vector2i, pos: Vector2) -> void:
	var sob := _prece_em(p)
	if sob != _sob:
		_sob = sob
		queue_redraw()
	var povo := _povo_em(p)
	if sob >= 0:
		var q: Dictionary = preces[sob]
		interface._mostrar_dica(["Clique para ver %s" % q["nome"]] if q.get("vivo", false) else ["%s não vive mais" % q["nome"]],
			-1, pos + position + Vector2(-60, 10), false)
	elif povo >= 0:
		var f: Dictionary = povos[povo]
		interface._mostrar_dica([texto_da_fe(f)], -1, pos + position + Vector2(-40, 10), false)
	else:
		interface._dica.visible = false


## Em palavras, para a dica (sem número): "A fé dos Toan esquenta", "está fria e esfria"...
static func texto_da_fe(f: Dictionary) -> String:
	var nivel := float(f.get("nivel", 0.5))
	var t := float(f.get("tendencia", 0.0))
	var quanto := "forte" if nivel >= 0.66 else ("morna" if nivel >= 0.33 else "fria")
	var rumo := "esquentando" if t > 0.15 else ("esfriando" if t < -0.15 else "parada")
	return "A fé dos %s: %s, %s" % [f.get("nome", "?"), quanto, rumo]


func _povo_em(p: Vector2i) -> int:
	for i in _rects_povos.size():
		if _rects_povos[i].has_point(p):
			return i
	return -1


# --- desenho -----------------------------------------------------------------

func _draw() -> void:
	if not visible:
		return
	var t0 := Time.get_ticks_usec()
	_desenhar()
	custo_desenho_us = Time.get_ticks_usec() - t0


func _desenhar() -> void:
	draw_texture(_fundo(), Vector2(CAIXA.position))
	var titulo: Font = interface._fontes["titulo"]
	var escura: Font = interface._fontes["escura"]
	var x0 := CAIXA.position.x + MARGEM
	var y := CAIXA.position.y + 6
	draw_string(titulo, Vector2(x0, y + int(titulo.get_ascent(TAM_FONTE))), "Preces", HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
	# os povos que rezam, com o termômetro, numa linha (os que não cabem ficam para a dica da vila)
	_rects_povos = []
	var x := x0 + 44
	for f in povos:
		var nome := String(f["nome"])
		var w := int(escura.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		if x + w + 40 > CAIXA.end.x - MARGEM:
			break
		draw_string(escura, Vector2(x, y + int(escura.get_ascent(TAM_FONTE))), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		desenhar_termometro(self, Vector2i(x + w + 4, y + 2), float(f["nivel"]), float(f["tendencia"]))
		_rects_povos.append(Rect2i(x, y, w + 38, 11))
		x += w + 44
	var traco_y := CAIXA.position.y + 22
	draw_rect(Rect2(x0, traco_y, CAIXA.size.x - 2 * MARGEM, 1), Arte.paleta[8])
	if povos.is_empty() and preces.is_empty():
		draw_string(escura, Vector2(x0, traco_y + 14 + int(escura.get_ascent(TAM_FONTE))), "Nenhuma prece chegou ainda.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		draw_string(escura, Vector2(x0, traco_y + 25 + int(escura.get_ascent(TAM_FONTE))), "Quem não reza não aparece aqui.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		return
	if preces.is_empty():
		draw_string(escura, Vector2(x0, traco_y + 14 + int(escura.get_ascent(TAM_FONTE))), "Ninguém rezou ainda.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		return
	_desenhar_lista(x0)


func _desenhar_lista(x0: int) -> void:
	var titulo: Font = interface._fontes["titulo"]
	var escura: Font = interface._fontes["escura"]
	var topo := CAIXA.position.y + LISTA_TOPO
	var fundo := topo + _altura_lista()
	var y := topo - _rolagem
	var subida := int(escura.get_ascent(TAM_FONTE))
	for i in preces.size():
		var q: Dictionary = preces[i]
		var h := int(q["altura"])
		if y + h <= topo:
			y += h
			continue
		if y >= fundo:
			break
		if i == _sob:  # a prece sob o cursor: um fundo mais claro
			draw_rect(Rect2(x0 - 3, maxi(y - 2, topo - 2), CAIXA.size.x - 2 * MARGEM + 6, mini(h - 1, fundo - maxi(y - 2, topo - 2))),
				Color(Arte.paleta[31], 0.6))
		var linhas: Array = []  # [texto, fonte, dx]
		var cabeca := "%s, %s" % [q.get("nome", "?"), _do_povo(String(q.get("povo", "")))]
		linhas.append([cabeca, titulo, 0])
		for l in q["linhas"]:
			linhas.append([l, escura, 4])
		for k in linhas.size():
			var ly := y + k * ALTURA_LINHA
			if ly >= topo - 1 and ly + ALTURA_LINHA <= fundo + 1:
				draw_string(linhas[k][1], Vector2(x0 + linhas[k][2], ly + subida), linhas[k][0], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		# a data, à direita da cabeça; o estado, na última linha, com um ponto da cor dele
		var data := "Ano %d, dia %d" % [int(q.get("ano", 1)), int(q.get("dia", 1))]
		var wd := int(escura.get_string_size(data, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		if y >= topo - 1 and y + ALTURA_LINHA <= fundo + 1:
			draw_string(escura, Vector2(CAIXA.end.x - MARGEM - wd, y + subida), data, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		var ey := y + linhas.size() * ALTURA_LINHA
		if ey >= topo - 1 and ey + ALTURA_LINHA <= fundo + 1:
			var estado := String(q.get("estado", "esperando"))
			draw_rect(Rect2(x0 + 4, ey + 3, 4, 4), Arte.paleta[8])
			draw_rect(Rect2(x0 + 5, ey + 4, 2, 2), Arte.paleta[COR_ESTADO.get(estado, 2)])
			draw_string(escura, Vector2(x0 + 12, ey + subida), NOME_ESTADO.get(estado, estado), HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		y += h
	# setinhas de que há mais acima ou abaixo
	var sx := CAIXA.end.x - MARGEM - 3
	if _rolagem > 0:
		_triangulo(Vector2i(sx, topo - 5), true, 8)
	if _rolagem < _rolagem_max():
		_triangulo(Vector2i(sx, fundo + 1), false, 8)


## O pergaminho do tamanho da caixa, com as 9 partes (cantos, bordas e miolo em ladrilhos), numa textura só.
func _fundo() -> Texture2D:
	if _pergaminho != null:
		return _pergaminho
	var origem: Image = Arte.textura("interface/caixa_cronica_9s.png").get_image()
	origem.decompress()
	origem.convert(Image.FORMAT_RGBA8)
	var m := 6
	var t := origem.get_size()
	var img := Image.create(CAIXA.size.x, CAIXA.size.y, false, Image.FORMAT_RGBA8)
	var xs := [0, m, t.x - m, t.x]
	var ys := [0, m, t.y - m, t.y]
	var dx := [0, m, CAIXA.size.x - m, CAIXA.size.x]
	var dy := [0, m, CAIXA.size.y - m, CAIXA.size.y]
	for j in 3:
		for i in 3:
			var y: int = dy[j]
			while y < dy[j + 1]:
				var h: int = mini(ys[j + 1] - ys[j], dy[j + 1] - y)
				var x: int = dx[i]
				while x < dx[i + 1]:
					var w: int = mini(xs[i + 1] - xs[i], dx[i + 1] - x)
					img.blit_rect(origem, Rect2i(xs[i], ys[j], w, h), Vector2i(x, y))
					x += xs[i + 1] - xs[i]
				y += ys[j + 1] - ys[j]
	_pergaminho = ImageTexture.create_from_image(img)
	return _pergaminho


static func _do_povo(povo: String) -> String:
	return "dos %s" % povo if povo != "" else "sem povo"


func _triangulo(c: Vector2i, para_cima: bool, cor: int) -> void:
	for k in 3:
		var linha := k if para_cima else 2 - k
		draw_rect(Rect2(c.x - k, c.y + linha, 2 * k + 1, 1), Arte.paleta[cor])


## O termômetro (também na dica da vila): um bulbo e um tubo, cheio até o nível,
## na cor do nível (frio azul, morno laranja, forte vermelho), e a seta da tendência.
static func desenhar_termometro(alvo: CanvasItem, canto: Vector2i, nivel: float, tendencia: float) -> void:
	var tinta: Color = Arte.paleta[8]
	var vazio: Color = Arte.paleta[31]
	var cor: Color = Arte.paleta[2] if nivel < 0.33 else (Arte.paleta[21] if nivel < 0.66 else Arte.paleta[20])
	var t := TERMOMETRO
	# o bulbo, 5 × 5 com os cantos cortados
	alvo.draw_rect(Rect2(canto.x + 1, canto.y - 1, 3, 7), tinta)
	alvo.draw_rect(Rect2(canto.x, canto.y, 5, 5), tinta)
	alvo.draw_rect(Rect2(canto.x + 1, canto.y + 1, 3, 3), cor)
	# o tubo
	var tx := canto.x + 4
	alvo.draw_rect(Rect2(tx, canto.y + 1, t.x, 3), tinta)
	alvo.draw_rect(Rect2(tx, canto.y + 2, t.x - 1, 1), vazio)
	var cheio := clampi(roundi(nivel * (t.x - 1)), 1, t.x - 1)
	alvo.draw_rect(Rect2(tx, canto.y + 2, cheio, 1), cor)
	# a seta: para cima (esquenta), para baixo (esfria), um traço (parada)
	var sx := tx + t.x + 3
	if tendencia > 0.15:
		for k in 3:
			alvo.draw_rect(Rect2(sx + 2 - k, canto.y + k, 2 * k + 1, 1), Arte.paleta[20])
		alvo.draw_rect(Rect2(sx + 2, canto.y + 3, 1, 2), Arte.paleta[20])
	elif tendencia < -0.15:
		for k in 3:
			alvo.draw_rect(Rect2(sx + 2 - k, canto.y + 4 - k, 2 * k + 1, 1), Arte.paleta[2])
		alvo.draw_rect(Rect2(sx + 2, canto.y, 1, 2), Arte.paleta[2])
	else:
		alvo.draw_rect(Rect2(sx, canto.y + 2, 5, 1), tinta)

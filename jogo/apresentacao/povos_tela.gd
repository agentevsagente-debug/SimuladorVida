extends Node2D
## O painel da população (pedido do autor em 07/11/2026): o mesmo pergaminho da caixa de
## preces, à direita, por cima do mundo. No topo, quantos habitantes o mundo tem.
##
## - Nível 1, os povos vivos: o nome e quantas pessoas, e embaixo onde vive, o estágio e
##   como chama o deus ("não crê" ou "cético"). Clicar num povo abre o nível 2.
## - Nível 2, os habitantes do povo: o nome, o papel e a idade. Primeiro o líder e o
##   sacerdote, depois os adultos do mais velho ao mais novo, por último as crianças.
##   "Voltar" (ou o botão direito, ou o Esc) volta aos povos.
## Clicar numa pessoa leva a vista até ela, como clicar numa prece. A roda e as setas rolam.
##
## Tudo sai de grupos_visiveis() e pessoas_visiveis(), que valem só pela hora: o painel copia o
## que mostra e só relê quando a hora vira. Não mostra fé de ninguém nem números internos.

signal fechada
signal ir_ate(id: int)

const Arte = preload("res://apresentacao/arte.gd")
const PrecesTela = preload("res://apresentacao/preces_tela.gd")
const TAM_FONTE := 11
const ALTURA_LINHA := 11
const CAIXA := PrecesTela.CAIXA
const MARGEM := 8
const LISTA_TOPO := 26
const ALTURA_POVO := 2 * ALTURA_LINHA + 3
const ALTURA_PESSOA := ALTURA_LINHA
const VOLTAR := Rect2i(CAIXA.end.x - 52, CAIXA.position.y + 5, 44, 13)
const NOME_ZONA := {"lago": "o lago", "praia": "a praia", "floresta": "a floresta", "morro": "o morro"}
const NOME_ESTAGIO := {1: "coleta", 2: "agricultura", 3: "pedra", 4: "metal", 5: "escrita", 6: "engenharia"}

var interface: Node2D
var vista: Node2D
var modo := "povos"     # "povos" ou "pessoas"
var povo := -1          # o id do povo aberto no nível 2
var total := 0          # habitantes do mundo
var povos: Array = []   # [{id, nome, membros, linha}] (cópias)
var pessoas: Array = [] # [{id, nome, idade, papel}] do povo aberto (cópias), na ordem do painel
var custo_desenho_us := 0
var cargas := 0         # quantas vezes leu a API (o teste confere que é uma vez por hora)
var _rolagem := 0
var _sob := -1
var _sob_voltar := false
var _hora_lida := -1


func criar(p_interface: Node2D, p_vista: Node2D) -> void:
	interface = p_interface
	vista = p_vista
	position = Vector2(0, interface.ALTURA_ALCA)
	visible = false


func abrir() -> void:
	modo = "povos"
	povo = -1
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


## Relê o mundo quando a hora vira (os arrays da API valem só pela hora).
func atualizar_se_virou() -> void:
	if not visible or vista.sim == null:
		return
	if int(vista.sim.mundo.passo) != _hora_lida:
		carregar()


## O total e os povos (e, no nível 2, as pessoas do povo aberto), copiados da API.
func carregar() -> void:
	if vista.sim == null:
		return
	var m = vista.sim.mundo
	_hora_lida = int(m.passo)
	cargas += 1
	povos = []
	total = 0
	for g in m.grupos_visiveis():
		total += int(g["membros"])
		povos.append({"id": int(g["id"]), "nome": String(g["nome"]), "membros": int(g["membros"]),
			"linha": linha_do_povo(g)})
	if modo == "pessoas":
		if not povos.any(func(p): return p["id"] == povo):
			modo = "povos"  # o povo acabou ou se juntou a outro: volta à lista
			_rolagem = 0
		else:
			pessoas = _pessoas_do_povo(m, povo)
	_rolagem = clampi(_rolagem, 0, _rolagem_max())
	queue_redraw()


## "a floresta, agricultura, crê em Risca o Céu" (ou "não crê", ou "cético").
static func linha_do_povo(g: Dictionary) -> String:
	var deus := String(g.get("nome_deus", ""))
	var fe := "cético" if bool(g.get("ceticos", false)) else ("não crê" if deus == "" else "crê " + _em(deus))
	return "%s, %s, %s" % [NOME_ZONA.get(String(g.get("zona", "")), String(g.get("zona", ""))),
		NOME_ESTAGIO.get(int(g.get("estagio", 1)), "estágio %d" % int(g.get("estagio", 1))), fe]


## "em" com o artigo do nome do deus: "no Olho Escuro", "na Terra Brava", "em Risca".
static func _em(deus: String) -> String:
	for artigo in [["os ", "nos "], ["as ", "nas "], ["o ", "no "], ["a ", "na "]]:
		if deus.to_lower().begins_with(artigo[0]):
			return artigo[1] + deus.substr(artigo[0].length())
	return "em " + deus


## As pessoas do povo, na ordem: líder, sacerdote, adultos do mais velho ao mais novo, crianças.
static func _pessoas_do_povo(m, gid: int) -> Array:
	var r: Array = []
	for f in m.pessoas_visiveis():
		if int(f.get("grupo", -1)) != gid:
			continue
		var papel := String(f.get("papel", ""))
		var nome_papel := "líder" if papel == "lider" else \
			("sacerdotisa" if papel == "sacerdote" and f.get("sexo", "m") == "f" else ("sacerdote" if papel == "sacerdote" else ""))
		if nome_papel == "" and bool(f.get("crianca", false)):
			nome_papel = "criança"
		var ordem := 0 if papel == "lider" else (1 if papel == "sacerdote" else (3 if f.get("crianca", false) else 2))
		r.append({"id": int(f["id"]), "nome": String(f["nome"]), "idade": int(f.get("idade", 0)), "papel": nome_papel,
			"ordem": ordem})
	r.sort_custom(func(a, b): return a["ordem"] < b["ordem"] or (a["ordem"] == b["ordem"] and
		(a["idade"] > b["idade"] or (a["idade"] == b["idade"] and a["nome"] < b["nome"]))))
	return r


# --- entrada (pos em coordenadas do mundo da tela, 480 × 160) ----------------

func tratar(event: InputEvent, pos: Vector2) -> void:
	var p := Vector2i(pos)
	if event is InputEventMouseMotion:
		_mover(p, pos)
		return
	if not (event is InputEventMouseButton and event.pressed) or event.double_click:
		return
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			voltar()
		MOUSE_BUTTON_WHEEL_DOWN:
			rolar(ALTURA_LINHA * 2)
		MOUSE_BUTTON_WHEEL_UP:
			rolar(-ALTURA_LINHA * 2)
		MOUSE_BUTTON_LEFT:
			if not CAIXA.has_point(p):
				fechar()
			elif modo == "pessoas" and VOLTAR.has_point(p):
				voltar()
			else:
				var i := _linha_em(p)
				if i >= 0:
					escolher(i)


func tecla(keycode: int) -> bool:
	match keycode:
		KEY_ESCAPE:
			voltar()
		KEY_DOWN, KEY_PAGEDOWN:
			rolar(ALTURA_LINHA * (2 if keycode == KEY_DOWN else 8))
		KEY_UP, KEY_PAGEUP:
			rolar(-ALTURA_LINHA * (2 if keycode == KEY_UP else 8))
		_:
			return false
	return true


## Um passo para trás: das pessoas aos povos; dos povos, fecha.
func voltar() -> void:
	if modo == "pessoas":
		modo = "povos"
		povo = -1
		_rolagem = 0
		_sob = -1
		interface._dica.visible = false
		queue_redraw()
	else:
		fechar()


## A linha i: no nível 1 abre o povo; no nível 2 leva a vista até a pessoa.
func escolher(i: int) -> void:
	if modo == "povos":
		povo = int(povos[i]["id"])
		modo = "pessoas"
		pessoas = _pessoas_do_povo(vista.sim.mundo, povo)
		_rolagem = 0
		_sob = -1
		interface._dica.visible = false
		queue_redraw()
		return
	var id := int(pessoas[i]["id"])
	fechar()
	ir_ate.emit(id)


func abrir_povo(gid: int) -> void:
	for i in povos.size():
		if int(povos[i]["id"]) == gid:
			escolher(i)
			return


func rolar(d: int) -> void:
	var antes := _rolagem
	_rolagem = clampi(_rolagem + d, 0, _rolagem_max())
	if _rolagem != antes:
		queue_redraw()


func _linhas() -> Array:
	return povos if modo == "povos" else pessoas


func _altura_item() -> int:
	return ALTURA_POVO if modo == "povos" else ALTURA_PESSOA


func _altura_lista() -> int:
	return CAIXA.size.y - LISTA_TOPO - 6


func _rolagem_max() -> int:
	return maxi(0, _linhas().size() * _altura_item() - _altura_lista())


func _linha_em(p: Vector2i) -> int:
	var y0 := CAIXA.position.y + LISTA_TOPO
	if p.x < CAIXA.position.x + 4 or p.x >= CAIXA.end.x - 4 or p.y < y0 or p.y >= y0 + _altura_lista():
		return -1
	var i := (p.y - y0 + _rolagem) / _altura_item()
	return i if i >= 0 and i < _linhas().size() else -1


func _mover(p: Vector2i, pos: Vector2) -> void:
	var sob := _linha_em(p)
	var sob_voltar := modo == "pessoas" and VOLTAR.has_point(p)
	if sob != _sob or sob_voltar != _sob_voltar:
		_sob = sob
		_sob_voltar = sob_voltar
		queue_redraw()
	if sob >= 0:
		var texto := ("Clique para ver o povo de %s" % povos[sob]["nome"]) if modo == "povos" else \
			("Clique para ver %s" % pessoas[sob]["nome"])
		interface._mostrar_dica([texto], -1, pos + position + Vector2(-60, 10), false)
	else:
		interface._dica.visible = false


# --- desenho -----------------------------------------------------------------

func _draw() -> void:
	if not visible:
		return
	var t0 := Time.get_ticks_usec()
	_desenhar()
	custo_desenho_us = Time.get_ticks_usec() - t0


func _desenhar() -> void:
	draw_texture(PrecesTela.pergaminho(), Vector2(CAIXA.position))
	var titulo: Font = interface._fontes["titulo"]
	var escura: Font = interface._fontes["escura"]
	var subida := int(escura.get_ascent(TAM_FONTE))
	var x0 := CAIXA.position.x + MARGEM
	var y := CAIXA.position.y + 6
	var cabeca := "População: %s" % habitantes(total)
	if modo == "pessoas":
		var nome := ""
		for p in povos:
			if p["id"] == povo:
				nome = p["nome"]
		cabeca = "Os %s: %s" % [nome, habitantes(pessoas.size())]
		PrecesTela.botao_texto(self, interface, VOLTAR, "Voltar", _sob_voltar)
	draw_string(titulo, Vector2(x0, y + subida), cabeca, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
	draw_rect(Rect2(x0, CAIXA.position.y + 21, CAIXA.size.x - 2 * MARGEM, 1), Arte.paleta[8])
	var linhas := _linhas()
	if linhas.is_empty():
		draw_string(escura, Vector2(x0, CAIXA.position.y + LISTA_TOPO + subida), "Não há ninguém no mundo.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		return
	var topo := CAIXA.position.y + LISTA_TOPO
	var fundo := topo + _altura_lista()
	var h := _altura_item()
	var direita := CAIXA.end.x - MARGEM
	var primeiro := _rolagem / h
	for i in range(primeiro, linhas.size()):
		var ly := topo + i * h - _rolagem
		if ly >= fundo:
			break
		if ly + ALTURA_LINHA > fundo + 1:
			break
		if i == _sob:
			draw_rect(Rect2(x0 - 3, ly - 1, CAIXA.size.x - 2 * MARGEM + 6, h - 1), Color(Arte.paleta[31], 0.6))
		var l: Dictionary = linhas[i]
		if modo == "povos":
			draw_string(titulo, Vector2(x0, ly + subida), String(l["nome"]), HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
			var n := habitantes(int(l["membros"]))
			var wn := int(escura.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
			draw_string(escura, Vector2(direita - wn, ly + subida), n, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
			if ly + 2 * ALTURA_LINHA <= fundo + 1:
				draw_string(escura, Vector2(x0 + 6, ly + ALTURA_LINHA + subida), String(l["linha"]),
					HORIZONTAL_ALIGNMENT_LEFT, direita - x0 - 6, TAM_FONTE)
		else:
			var f: Font = titulo if l["papel"] in ["líder", "sacerdote", "sacerdotisa"] else escura
			draw_string(f, Vector2(x0, ly + subida), String(l["nome"]), HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
			if l["papel"] != "":
				draw_string(escura, Vector2(x0 + 110, ly + subida), String(l["papel"]), HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
			var idade := "1 ano" if int(l["idade"]) == 1 else ("%d anos" % int(l["idade"]))
			var wi := int(escura.get_string_size(idade, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
			draw_string(escura, Vector2(direita - wi, ly + subida), idade, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
	var sx := direita - 3
	if _rolagem > 0:
		PrecesTela.triangulo(self, Vector2i(sx, topo - 5), true)
	if _rolagem < _rolagem_max():
		PrecesTela.triangulo(self, Vector2i(sx, fundo + 1), false)


## "1 habitante", "23 habitantes".
static func habitantes(n: int) -> String:
	return "1 habitante" if n == 1 else "%d habitantes" % n

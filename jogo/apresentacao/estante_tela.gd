extends Node2D
## A estante de crônicas e os avisos do fim do mundo, por cima do mundo (480 × 160,
## logo abaixo da alça). Arte: arte/estante/ (LEIA-ME, seção 16).
##
## Modos:
## - "estante": as prateleiras com um livro por era (os guardados na estante,
##   os fechados que ainda não foram salvos e, por último, a era em curso). A
##   cor da lombada é a do mundo (semente), e o nome vai girado na etiqueta.
##   Clicar num livro o abre. "Abandonar este mundo" pede confirmação.
## - "livro": o livro aberto, com o texto paginado (até 17 caracteres por linha
##   e 10 linhas por página). Clicar na página da direita avança, na da
##   esquerda volta; a roda também folheia. Fora do livro, volta à estante.
## - "confirmar": a pergunta antes de abandonar o mundo.
## - "fim": o aviso de que não resta ninguém, sobre o mundo vazio.
## O botão direito e o Esc voltam um passo (do livro à estante, da estante ao mundo).

signal abandonar
signal fechada

const Arte = preload("res://apresentacao/arte.gd")
const Estante = preload("res://nucleo/estante.gd")
const TAM_FONTE := 11  # as fontes 5x7 pixel a pixel

const LARGURA := 480
const ALTURA := 160
const BASES := [72, 150]          # linha de cima de cada prateleira
const INICIO_X := 24
const FIM_X := [456, 340]          # a segunda prateleira deixa lugar para os botões
const LIVRO := Vector2i(112, 8)    # canto do livro aberto (256 × 144)
const PAGINAS := [Rect2i(14, 12, 104, 118), Rect2i(138, 12, 104, 118)]
const LINHAS := 9  # a décima linha encostava no número da página
const ALTURA_LINHA := 11
const FECHAR := Rect2i(440, 3, 37, 14)
const ABANDONAR := Rect2i(352, 128, 122, 16)
const CAIXA_CONFIRMAR := Rect2i(110, 34, 260, 84)
const NAO := Rect2i(150, 96, 84, 16)   # o padrão, à esquerda
const SIM := Rect2i(246, 96, 84, 16)   # abandonar, à direita e discreto
const CAIXA_FIM := Rect2i(100, 30, 280, 74)

var interface: Node2D             # fontes, caixas de 9 partes e a dica
var vista: Node2D
var modo := ""
var livros: Array = []            # {titulo, era, semente, ano_ini, ano_fim, id | texto | atual}
var _rects: Array[Rect2i] = []
var _sob := -1
var _sob_botao := ""
var _paginas: Array = []          # páginas: [[texto, estilo]] (titulo, capitulo, secao, ano, texto, epitafio)
var so_um_livro := false  # aberta só para ler um livro (a crônica da tecla C): fechar vai direto ao mundo
var _pagina_ultimo_ano := 0      # onde começa o último "### Ano" (a crônica abre ali, no mais recente)
var _indice: Array = []           # [[rótulo curto, página]]: o resumo, os capítulos, quem foi quem, o fim
const INDICE := Rect2i(4, 8, 104, 144)  # o índice, à esquerda do livro aberto
const ESTILOS_TITULO := ["titulo", "capitulo", "secao", "epitafio"]  # na fonte de títulos (vinho)
var _pagina := 0                  # a página da esquerda (par)
var _aberto := -1
var _fim := {}                    # {titulo, ano_ini, ano_fim}
var _fundo: Texture2D
var _prateleira: Texture2D
var _lombadas: Texture2D
var _livro: Texture2D


func criar(p_interface: Node2D, p_vista: Node2D) -> void:
	interface = p_interface
	vista = p_vista
	position = Vector2(0, interface.ALTURA_ALCA)
	visible = false
	_fundo = Arte.textura("estante/estante_fundo.png")
	_prateleira = Arte.textura("estante/prateleira.png")
	_lombadas = Arte.textura("estante/livro_lombada_6v.png")
	_livro = Arte.textura("estante/livro_aberto.png")


func abrir() -> void:
	so_um_livro = false
	_carregar_livros()
	modo = "estante"
	_sob = -1
	visible = true
	queue_redraw()


func fechar() -> void:
	visible = false
	modo = ""
	so_um_livro = false
	fechada.emit()


## O aviso do fim do mundo, sobre o mundo vazio.
func avisar_fim(livro: Dictionary) -> void:
	_fim = livro
	modo = "fim"
	visible = true
	queue_redraw()


## Abre o livro i (testes: --abrir=livro).
func abrir_livro(i: int) -> void:
	if livros.is_empty():
		_carregar_livros()
	if livros.is_empty():
		return
	_aberto = clampi(i, 0, livros.size() - 1)
	_paginas = _paginar(_texto_do_livro(livros[_aberto]))
	_pagina = 0
	modo = "livro"
	visible = true
	queue_redraw()


func pedir_confirmacao() -> void:
	if modo == "":
		abrir()
	modo = "confirmar"
	queue_redraw()


# --- livros ------------------------------------------------------------------

func _carregar_livros() -> void:
	var sim = vista.sim
	var m = sim.mundo
	livros = []
	for l in Estante.livros(sim.pasta_estante()):
		livros.append(l)
	for l in m.livros:  # fechados, ainda não salvos na estante
		if not l["na_estante"]:
			livros.append({"titulo": l["titulo"], "era": l["era"], "semente": l["semente"],
				"ano_ini": l["ano_ini"], "ano_fim": l["ano_fim"], "texto": l["texto"]})
	if not m.fim_do_mundo:
		livros.append({"titulo": m.nome_da_era(), "era": m.era, "semente": m.semente,
			"ano_ini": m.era_inicio_ano, "ano_fim": m.ano(), "atual": true})
	# as posições: da esquerda para a direita, de cima para baixo; se não couber, ficam os mais novos
	var posicoes: Array[Rect2i] = []
	for prat in BASES.size():
		var x := INICIO_X
		var n := 0
		while x + 12 <= FIM_X[prat]:
			posicoes.append(Rect2i(x, BASES[prat] - 64, 12, 64))
			x += 14 + (n % 3) * 2
			n += 1
	if livros.size() > posicoes.size():
		livros = livros.slice(livros.size() - posicoes.size())
	_rects = posicoes.slice(0, livros.size())


func _texto_do_livro(l: Dictionary) -> String:
	if l.get("atual", false):
		var t: Dictionary = vista.sim.tempo
		var m = vista.sim.mundo
		var miolo: String = m.cronica_viva() if m.has_method("cronica_viva") else m.cronica()
		return "# " + String(l["titulo"]) + "\n\n" + miolo + "\n\nAno %d, dia %d: o ano ainda está em curso." % [t["ano"], t["dia"]]
	if l.has("texto"):
		return l["texto"]
	return Estante.ler(l["id"], vista.sim.pasta_estante())


## O nome na lombada: "ERA II" (cabem 7 caracteres).
static func rotulo(era: int) -> String:
	var r := ""
	var n := era
	for par in [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while n >= par[0]:
			r += par[1]
			n -= par[0]
	var texto := "ERA " + r
	return texto if texto.length() <= 7 else "ERA %d" % era


## O nome na lombada: com um mundo só na estante, "ERA II"; com vários, o
## número do mundo (na ordem da estante) e a era, como "M2 EIII" (até 7).
func _rotulo_do_livro(l: Dictionary) -> String:
	var mundos := []
	for o in livros:
		if not int(o["semente"]) in mundos:
			mundos.append(int(o["semente"]))
	if mundos.size() <= 1:  # a era e o povo do epíteto, se couber: "I Suem"
		var povo := _povo_do_epiteto(String(l["titulo"]))
		var romano := rotulo(int(l["era"])).substr(4)
		if povo != "" and (romano + " " + povo).length() <= 7:
			return romano + " " + povo
		return rotulo(int(l["era"]))
	var era := rotulo(int(l["era"])).substr(4)  # o romano
	var texto := "M%d E%s" % [mundos.find(int(l["semente"])) + 1, era]
	return texto if texto.length() <= 7 else "M%d E%d" % [mundos.find(int(l["semente"])) + 1, int(l["era"])]


## "A Primeira Era: de Teil ao último de Suem" -> ["A Primeira Era", "de Teil ao último de Suem"].
static func _titulo_e_epiteto(titulo: String) -> Array:
	var i := titulo.find(":")
	if i < 0:
		return [titulo, ""]
	return [titulo.substr(0, i).strip_edges(), titulo.substr(i + 1).strip_edges()]


## O último povo do epíteto ("de Teil ao último de Suem" -> "Suem"; "o tempo de Lour" -> "Lour").
static func _povo_do_epiteto(titulo: String) -> String:
	var epiteto: String = _titulo_e_epiteto(titulo)[1]
	if epiteto == "":
		return ""
	var palavras := epiteto.split(" ", false)
	return palavras[-1] if not palavras.is_empty() else ""


## Abre um livro em markdown direto no leitor, na página `pagina` (-1: no começo do
## último ano, o mais recente; testes: --livro-arquivo).
func abrir_texto(md: String, pagina := 0, so_ele := false) -> void:
	var titulo := md.get_slice("\n", 0).trim_prefix("# ").strip_edges()
	livros = [{"titulo": titulo, "era": 1, "semente": 0, "ano_ini": 1, "ano_fim": 1, "texto": md}]
	_rects = [Rect2i(INICIO_X, BASES[0] - 64, 12, 64)]
	abrir_livro(0)
	so_um_livro = so_ele
	_ir_a_pagina(_pagina_ultimo_ano if pagina < 0 else pagina)


## A cor da lombada: a mesma para todas as eras de um mundo.
static func cor(semente: int) -> int:
	return posmod(semente, 6)


## Quebra o livro (markdown) em páginas de 9 linhas que cabem em 104 px, com
## um estilo por linha: o título do livro, os capítulos e as seções na fonte de
## títulos; os anos e o texto na tinta escura. Cada capítulo e cada seção
## ("Quem foi quem", "O mundo no fim") começa numa página nova, e o epitáfio (o
## parágrafo em itálico depois do último ---) fica sozinho na última página,
## centrado. Monta também o índice (`_indice`).
func _paginar(md: String) -> Array:
	var fonte: Font = interface._fontes["escura"]
	var largura := PAGINAS[0].size.x
	var brutas := md.split("\n")
	var ultima_sep := -1
	for k in brutas.size():
		if brutas[k].strip_edges() == "---":
			ultima_sep = k
	var paginas: Array = []
	var pagina: Array = []
	_indice = []
	var quebrar := func():  # fecha a página (o array é o mesmo: copia e esvazia)
		if not pagina.is_empty():
			paginas.append(pagina.duplicate())
			pagina.clear()
	for k in brutas.size():
		var bruta: String = brutas[k].strip_edges()
		if bruta == "---":
			continue
		var estilo := "texto"
		if bruta.begins_with("### "):
			estilo = "ano"
		elif bruta.begins_with("## "):
			estilo = "capitulo" if bruta.begins_with("## Capítulo") else "secao"
		elif bruta.begins_with("# "):
			estilo = "titulo"
		elif k > ultima_sep and ultima_sep >= 0 and bruta.begins_with("*") and bruta.length() > 2:
			estilo = "epitafio"
		var texto: String = interface._sem_markdown(bruta)
		if texto == "":
			if not pagina.is_empty() and pagina[-1][0] != "":
				pagina.append(["", "texto"])
				if pagina.size() == LINHAS:
					quebrar.call()
			continue
		if estilo in ["capitulo", "secao", "epitafio"]:
			quebrar.call()
			if estilo == "epitafio" and paginas.size() % 2 == 1:  # o epitáfio abre na página da esquerda: lê-se nas duas
				paginas.append([])
			_indice.append([_rotulo_da_secao(texto, estilo), paginas.size()])
			if estilo == "epitafio":  # no meio da página, se couber nela
				var n_ep := _quebrar_linhas(texto, fonte, largura).size()
				for b in maxi(0, (LINHAS - n_ep) / 2):
					pagina.append(["", "texto"])
		elif estilo == "ano" and not pagina.is_empty() and pagina[-1][0] != "":
			pagina.append(["", "texto"])
		if estilo == "ano":
			_pagina_ultimo_ano = paginas.size() + (1 if pagina.size() >= LINHAS - 1 else 0)
		for linha in _quebrar_linhas(texto, fonte, largura):
			if pagina.is_empty() and linha == "":
				continue
			pagina.append([linha, estilo])
			if pagina.size() == LINHAS:
				quebrar.call()
	quebrar.call()
	return paginas if not paginas.is_empty() else [[["(em branco)", "texto"]]]


## As linhas de um parágrafo que cabem na largura (palavras longas demais são cortadas).
func _quebrar_linhas(texto: String, fonte: Font, largura: float) -> Array:
	var r: Array = []
	var atual := ""
	for palavra in texto.split(" ", false):
		while fonte.get_string_size(palavra, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x > largura:
			var corte := palavra.length() - 1
			while corte > 1 and fonte.get_string_size(palavra.substr(0, corte), HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x > largura:
				corte -= 1
			if atual != "":
				r.append(atual)
				atual = ""
			r.append(palavra.substr(0, corte))
			palavra = palavra.substr(corte)
		var tentativa := palavra if atual == "" else atual + " " + palavra
		if fonte.get_string_size(tentativa, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x <= largura:
			atual = tentativa
		else:
			r.append(atual)
			atual = palavra
	if atual != "":
		r.append(atual)
	return r


## O rótulo curto no índice: "Capítulo VII: Os últimos (anos 161 a 162)" vira "VII. Os últimos".
func _rotulo_da_secao(texto: String, estilo: String) -> String:
	if estilo == "epitafio":
		return "O epitáfio"
	if texto.begins_with("Capítulo "):
		var resto := texto.substr(9)
		var dois := resto.find(":")
		var nome := resto.substr(dois + 1).strip_edges() if dois >= 0 else resto
		var par := nome.find(" (")
		if par >= 0:
			nome = nome.substr(0, par)
		return resto.substr(0, dois) + ". " + nome
	return texto


# --- entrada (pos em coordenadas da tela da estante, 480 × 160) ----------------

func tratar(event: InputEvent, pos: Vector2) -> void:
	var p := Vector2i(pos)
	if event is InputEventMouseMotion:
		_mover(p, pos)
		return
	if not (event is InputEventMouseButton and event.pressed) or event.double_click:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		voltar()
		return
	match modo:
		"fim":
			fechar()
		"estante":
			if event.button_index != MOUSE_BUTTON_LEFT:
				return
			if FECHAR.has_point(p):
				fechar()
			elif ABANDONAR.has_point(p) and _pode_abandonar():
				pedir_confirmacao()
			else:
				var i := _livro_em(p)
				if i >= 0:
					interface._dica.visible = false
					abrir_livro(i)
		"livro":
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_folhear(2)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_folhear(-2)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				var local := p - LIVRO
				if INDICE.has_point(p) and not _indice.is_empty():  # um capítulo do índice
					var k := (p.y - INDICE.position.y - 6) / ALTURA_LINHA
					if k >= 0 and k < _indice.size():
						_ir_a_pagina(_indice[k][1])
				elif not Rect2i(Vector2i.ZERO, Vector2i(256, 144)).has_point(local):
					voltar()
				else:
					_folhear(2 if local.x >= 128 else -2)
		"confirmar":
			if event.button_index != MOUSE_BUTTON_LEFT:
				return
			if SIM.has_point(p):
				modo = ""
				visible = false
				abandonar.emit()
			elif NAO.has_point(p) or not CAIXA_CONFIRMAR.has_point(p):
				modo = "estante"
				queue_redraw()


## Volta um passo: do livro ou da pergunta à estante; da estante ao mundo.
func voltar() -> void:
	if modo == "livro" and so_um_livro:
		fechar()
	elif modo in ["livro", "confirmar"]:
		modo = "estante"
		queue_redraw()
	else:
		fechar()


func tecla(keycode: int) -> bool:
	match keycode:
		KEY_ESCAPE:
			voltar()
		KEY_RIGHT, KEY_PAGEDOWN:
			_folhear(2)
		KEY_LEFT, KEY_PAGEUP:
			_folhear(-2)
		KEY_DOWN:
			_ir_ao_capitulo(1)
		KEY_UP:
			_ir_ao_capitulo(-1)
		_:
			return false
	return true


## Pula para o começo do capítulo (ou da seção) seguinte (1) ou anterior (-1).
func _ir_ao_capitulo(d: int) -> void:
	if modo != "livro" or _indice.is_empty():
		return
	var atual := _secao_atual()
	var alvo := clampi(atual + d, 0, _indice.size() - 1)
	if d < 0 and atual >= 0 and _indice[atual][1] < _pagina:  # no meio de um capítulo: volta ao começo dele
		alvo = atual
	_ir_a_pagina(_indice[alvo][1])


func _ir_a_pagina(n: int) -> void:
	_pagina = clampi(n - n % 2, 0, maxi(0, (_paginas.size() - 1) / 2 * 2))
	queue_redraw()


## A seção do índice em que está a página da direita (ou -1, antes da primeira).
func _secao_atual() -> int:
	var r := -1
	for k in _indice.size():
		if _indice[k][1] <= _pagina + 1:
			r = k
	return r


func _folhear(d: int) -> void:
	if modo != "livro":
		return
	_pagina = clampi(_pagina + d, 0, maxi(0, (_paginas.size() - 1) / 2 * 2))
	queue_redraw()


func _livro_em(p: Vector2i) -> int:
	for i in _rects.size():
		if _rects[i].grow_individual(0, 2, 0, 0).has_point(p):
			return i
	return -1


## "Abandonar este mundo" só aparece do segundo ano em diante: na primeira hora,
## é um botão perigoso e sem contexto (auditoria 8, P8).
func _pode_abandonar() -> bool:
	return int(vista.sim.tempo.get("ano", 1)) >= 2


func _mover(p: Vector2i, pos: Vector2) -> void:
	var sob := _livro_em(p) if modo == "estante" else -1
	var botao := ""
	if modo == "estante":
		botao = "fechar" if FECHAR.has_point(p) else ("abandonar" if ABANDONAR.has_point(p) and _pode_abandonar() else "")
	elif modo == "confirmar":
		botao = "sim" if SIM.has_point(p) else ("nao" if NAO.has_point(p) else "")
	if sob != _sob or botao != _sob_botao:
		_sob = sob
		_sob_botao = botao
		queue_redraw()
	if sob >= 0:
		var l: Dictionary = livros[sob]
		var partes := _titulo_e_epiteto(String(l["titulo"]))
		var linhas := [partes[0]] + ([partes[1]] if partes[1] != "" else []) + \
			["Mundo %d, do ano %d ao ano %d" % [l["semente"], l["ano_ini"], l["ano_fim"]]]
		if l.get("atual", false):
			linhas = [l["titulo"], "Mundo %d, desde o ano %d" % [l["semente"], l["ano_ini"]], "em curso"]
		interface._mostrar_dica(linhas, -1, pos + position)
	else:
		interface._dica.visible = false


# --- desenho -----------------------------------------------------------------

func _draw() -> void:
	if modo == "":
		return
	if modo == "fim":
		_desenhar_fim()
		return
	for y in range(0, ALTURA, 16):
		for x in range(0, LARGURA, 16):
			draw_texture(_fundo, Vector2(x, y))
	if modo == "livro":
		_desenhar_livro()
		return
	for base in BASES:
		for x in range(0, LARGURA, 16):
			draw_texture(_prateleira, Vector2(x, base))
	var escura: Font = interface._fontes["escura"]
	for i in livros.size():
		var l: Dictionary = livros[i]
		var r := _rects[i]
		var y := r.position.y - (2 if i == _sob else 0)
		draw_texture_rect_region(_lombadas, Rect2(r.position.x, y, 12, 64), Rect2(cor(int(l["semente"])) * 12, 0, 12, 64))
		# o nome, lido de baixo para cima, centrado na etiqueta (linhas 8 a 55, colunas 2 a 9)
		var texto := _rotulo_do_livro(l)
		var w := int(escura.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		var origem := Vector2(r.position.x + 2, y + 8 + (48 + w) / 2)
		draw_set_transform(origem, -PI / 2.0)
		draw_string(escura, Vector2(0, int(escura.get_ascent(TAM_FONTE)) - 1), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		draw_set_transform(Vector2.ZERO)
		if l.get("atual", false):  # a era em curso: uma fita dourada saindo de cima
			draw_rect(Rect2(r.position.x + 8, y - 3, 1, 3), Arte.paleta[22])
	_botao_texto(FECHAR, "Fechar", _sob_botao == "fechar")
	if _pode_abandonar():
		_botao_texto(ABANDONAR, "Abandonar este mundo", _sob_botao == "abandonar")
	if modo == "confirmar":
		_desenhar_confirmar()


func _desenhar_livro() -> void:
	draw_texture(_livro, Vector2(LIVRO))
	var escura: Font = interface._fontes["escura"]
	var titulo: Font = interface._fontes["titulo"]
	_desenhar_indice()
	for lado in 2:
		var n := _pagina + lado
		if n >= _paginas.size():
			continue
		var canto := Vector2(LIVRO + PAGINAS[lado].position)
		var linhas: Array = _paginas[n]
		for i in linhas.size():
			var f: Font = titulo if linhas[i][1] in ESTILOS_TITULO else escura
			var dx := 0.0
			if linhas[i][1] == "epitafio":  # o epitáfio, centrado
				dx = (PAGINAS[lado].size.x - f.get_string_size(linhas[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x) / 2.0
			draw_string(f, canto + Vector2(roundf(dx), i * ALTURA_LINHA + int(f.get_ascent(TAM_FONTE))), linhas[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
			if linhas[i][1] == "capitulo" and (i + 1 >= linhas.size() or linhas[i + 1][1] != "capitulo"):
				draw_rect(Rect2(canto.x, canto.y + i * ALTURA_LINHA + 10, 24, 1), Arte.paleta[8])  # um traço sob o título
		var numero := str(n + 1)
		var w := escura.get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x
		draw_string(escura, Vector2(LIVRO + PAGINAS[lado].position) + Vector2((PAGINAS[lado].size.x - w) / 2,
			(LINHAS + 1) * ALTURA_LINHA - 3 + int(escura.get_ascent(TAM_FONTE))), numero, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)


## O índice do livro aberto, à esquerda: o capítulo em que se está, na fonte de títulos.
func _desenhar_indice() -> void:
	if _indice.is_empty():
		return
	_caixa_pergaminho(INDICE)
	var atual := _secao_atual()
	var escura: Font = interface._fontes["escura"]
	var titulo: Font = interface._fontes["titulo"]
	for k in mini(_indice.size(), 12):
		var f: Font = titulo if k == atual else escura
		var texto: String = _indice[k][0]
		while texto.length() > 3 and f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x > INDICE.size.x - 10:
			texto = texto.substr(0, texto.length() - 2) + "…"
		draw_string(f, Vector2(INDICE.position) + Vector2(5, 6 + k * ALTURA_LINHA + int(f.get_ascent(TAM_FONTE))), texto,
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)


func _desenhar_confirmar() -> void:
	_caixa_pergaminho(CAIXA_CONFIRMAR)
	_texto_centrado("Abandonar este mundo?", CAIXA_CONFIRMAR.position.y + 8, "titulo")
	_texto_centrado("A crônica desta era vai para a", CAIXA_CONFIRMAR.position.y + 24, "escura")
	_texto_centrado("estante, e começa outro mundo.", CAIXA_CONFIRMAR.position.y + 35, "escura")
	_texto_centrado("Este povo não volta.", CAIXA_CONFIRMAR.position.y + 46, "escura")
	# "Voltar" é o padrão (caixa e letra dourada); "Abandonar", à direita, é só a
	# palavra na tinta do pergaminho, e ganha caixa só com o cursor em cima
	_botao_texto(NAO, "Voltar", true)
	if _sob_botao == "sim":
		_botao_texto(SIM, "Abandonar", false)
	else:
		var f: Font = interface._fontes["escura"]
		var w := int(f.get_string_size("Abandonar", HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		draw_string(f, Vector2(SIM.position.x + (SIM.size.x - w) / 2, SIM.position.y + (SIM.size.y - 11) / 2 + int(f.get_ascent(TAM_FONTE))),
			"Abandonar", HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		draw_rect(Rect2(SIM.position.x + (SIM.size.x - w) / 2, SIM.position.y + 13, w, 1), Arte.paleta[8])


func _desenhar_fim() -> void:
	_caixa_pergaminho(CAIXA_FIM)
	var y := CAIXA_FIM.position.y + 8
	_texto_centrado("Não resta ninguém.", y, "titulo")
	_texto_centrado("%s terminou: do ano %d ao ano %d." % [_fim.get("titulo", "A era"),
		_fim.get("ano_ini", 1), _fim.get("ano_fim", 1)], y + 15, "escura")
	_texto_centrado("O livro dela foi para a estante.", y + 26, "escura")
	_texto_centrado("Quando quiser, faça nascer um povo", y + 41, "escura")
	_texto_centrado("novo: botão de criar povo, na alça.", y + 52, "escura")


func _caixa_pergaminho(r: Rect2i) -> void:
	interface._desenhar_9(Arte.textura("interface/caixa_cronica_9s.png"), Rect2(r), 6, self)


func _botao_texto(r: Rect2i, texto: String, sob: bool) -> void:
	interface._desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), Rect2(r), 4, self)
	var f: Font = interface._fontes["dourada" if sob else "clara"]
	var w := int(f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
	draw_string(f, Vector2(r.position.x + (r.size.x - w) / 2, r.position.y + (r.size.y - 11) / 2 + int(f.get_ascent(TAM_FONTE))), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)


func _texto_centrado(texto: String, y: int, cor_fonte: String) -> void:
	var f: Font = interface._fontes[cor_fonte]
	var w := int(f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
	draw_string(f, Vector2((LARGURA - w) / 2, y + int(f.get_ascent(TAM_FONTE))), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)

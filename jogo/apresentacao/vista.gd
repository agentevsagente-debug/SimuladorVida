extends Node2D
## Vista do mundo (480 × 160), montada com as peças de arte_claude/pecas.
##
## As partes fixas (terreno, vegetação, construções, marcas) viram uma imagem
## só, refeita apenas quando as construções, as zonas ou a estação mudam. O
## horário (dia, entardecer, noite) e a luz das fogueiras saem de
## remap.gdshader, que troca as cores pelas tabelas da arte. Pessoas,
## fogueiras, água, sinais e efeitos são desenhados por cima.
##
## A vista pode aproximar 2x e seguir a pessoa acompanhada; o nó pai recorta
## a área do mundo.
##
## Argumentos (depois de "--"):
##   --cena=layout        monta exatamente arte/camadas/layout.json (teste de fidelidade)
##   --hora=dia|entardecer|noite|N   horário inicial (mundo novo)
##   --congelar           o tempo não anda
##   --semente=N          semente do mundo novo
##   --mundo-novo         ignora o mundo salvo e não grava nada
##   --anos=N             avança N anos antes de abrir (mundo novo, testes)
##   --simular-ausencia=H depois de carregar, avança como se o jogador tivesse saído H horas (testes)
##   --capturar=ARQUIVO   grava a vista (480 × 160) em PNG e fecha
##   --capturar-apos=S    espera S segundos antes de capturar
##   --capturar-tudo      captura a tela inteira (480 × 178), com a alça
##   --quadros=N          em vez de um quadro, grava N quadros (ARQUIVO_00.png ...)
##   --intervalo=S        entre os quadros da sequência (padrão 0,2 s)
##   --efeito=chuva|raio  força chuva (e raios) sobre a aldeia, para testes

signal pessoa_clicada(id: int)

const Arte = preload("res://apresentacao/arte.gd")
const Terreno = preload("res://apresentacao/terreno.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")
const Pessoas = preload("res://apresentacao/pessoas.gd")
const Atmosfera = preload("res://apresentacao/atmosfera.gd")
const Sinais = preload("res://apresentacao/sinais.gd")
const REMAP = preload("res://apresentacao/remap.gdshader")

const LARGURA := 480
const ALTURA := 160
const ESTADOS := ["dia", "entardecer", "noite"]
const DIA := 0
const ENTARDECER := 1
const NOITE := 2
const FUNDOS := ["ceu", "montanhas_longe", "montanhas_perto", "mata_distante"]
## Quanto cada plano de fundo acompanha a câmera (0 = parado no infinito).
const PARALAXE := [0.0, 0.35, 0.55, 0.8]
const HORAS_NOMEADAS := {"dia": 12, "entardecer": 18, "noite": 22}
## Peças pequenas do cenário que somem quando uma construção cai em cima.
const PECAS_MIUDAS := ["capim", "capim_seco", "arbusto", "arbusto_frutas", "pedra_pequena",
	"pedra_grande", "tronco_deriva", "juncos"]
## Árvores que o fogo do deus deixa carbonizadas, com a coluna do tronco.
const ARVORES := {"arvore_copa_a": 19, "arvore_copa_b": 14, "pinheiro_a": 19, "pinheiro_b": 11, "pinheiro_fundo": 15}
const PASSO_ANDAR := 9.0      # px/s de quem anda
const ESPACO := 7             # distância mínima entre pessoas paradas lado a lado
const MARGEM := 130.0         # ninguém fica à esquerda disto (é água; API: x ≥ 126)
const ZOOM_SEGUIR := 2

var sim: Simulacao
var modo_discreto := false
var seguindo := false        # a câmera aproxima e segue a pessoa acompanhada
var zoom := 1
var camera := Vector2.ZERO   # canto de cima à esquerda da área vista, em pixels do mundo
var figuras: Array = []      # o que foi desenhado neste quadro, para a dica do cursor

var _layout: Dictionary
var _modo_layout := false
var _hora_fixa := -1.0
var _capturar := ""
var _quadros_ate_capturar := 4
var _capturar_apos := 0.0
var _capturar_tudo := false
var _quadros := 1
var _intervalo := 0.2
var _gravados := 0

var _materiais: Array[ShaderMaterial] = []
var _fundos: Array[Sprite2D] = []
var _tex_fundo := {}       # "ceu_dia" -> Texture2D, recortada à área usada
var _canto_fundo := []     # canto do recorte de cada plano de fundo
var _tex_reflexo := []     # por estado
var _mundo: Sprite2D
var _agua: Sprite2D
var _reflexo: Sprite2D
var _frente: Sprite2D
var _fogueiras: Node2D
var _pessoas: Pessoas
var _sinais: Sinais
var _quadros_agua: Array[Image] = []
var _tex_agua: Array[ImageTexture] = []
var _sup := PackedInt32Array()
var _tipos := []           # tipo do terreno por coluna de 8 px
var _fogos: Array = []     # [{canto: Vector2i, centro: float, luz: Vector2}]
var _estado := []
var _relogio := 0.0
var _quadro_agua := -1
var _quadro_fogo := -1
var _refazer := true
var _chave_fixo := []
var _virada := {}          # id da pessoa -> espelho (olhando para a esquerda)
var _x_visto := {}         # id da pessoa -> x desenhado (anda até o x do núcleo)
var _acordou := {}         # id da pessoa -> quando saiu da cabana (para saírem em fila)
var _tex_fogueira: Texture2D
var _atmosfera: Atmosfera
var _minutos := 0.0        # fração de hora fixa (--hora=17.5 com --congelar)
var _ceu_especial := ""    # "seca" ou "eclipse": troca o céu de dia
var _eclipse_ate := -1
var _camera_aplicada := [-1, Vector2(-1, -1)]


func _ready() -> void:
	var args := _ler_argumentos()
	_modo_layout = args.get("cena", "") == "layout"
	_capturar = args.get("capturar", "")
	_capturar_apos = float(args.get("capturar-apos", "0"))
	_capturar_tudo = args.has("capturar-tudo")
	_quadros = int(args.get("quadros", "1"))
	_intervalo = float(args.get("intervalo", "0.2"))
	Arte.carregar_paleta()
	_layout = Arte.json("camadas/layout.json")
	_criar_nos()

	var hora: String = args.get("hora", "")
	if _modo_layout:
		_hora_fixa = HORAS_NOMEADAS.get(hora, 12)
	else:
		sim = Simulacao.new()
		add_child(sim)
		sim.construcoes_mudaram.connect(func(): _refazer = true)
		sim.zonas_mudaram.connect(func(): _refazer = true)
		sim.eventos_novos.connect(_ao_receber_eventos)
		var novo := args.has("mundo-novo") or args.has("semente") or args.has("cena")
		sim.salvar_em_disco = not novo
		var semente := int(args.get("semente", str(randi())))
		var hf := float(HORAS_NOMEADAS.get(hora, hora)) if hora != "" else -1.0
		if args.has("anos"):
			sim.iniciar(semente, -1, false)
			sim.mundo.avancar_dias(40 * int(args["anos"]))
			if hf >= 0.0:
				while sim.mundo.tempo()["hora"] != int(hf):
					sim.mundo.avancar_hora()
			sim.iniciar_de_mundo()
		else:
			sim.iniciar(semente, int(hf) if hf >= 0.0 else -1, not novo)
		if args.has("simular-ausencia"):  # teste: como se o jogador tivesse saído N horas
			sim.ausencia = sim.mundo.avancar_ausencia(float(args["simular-ausencia"]) * 3600.0)
			sim.iniciar_de_mundo()
		sim.congelado = args.has("congelar")
		if sim.congelado and hf >= 0.0:
			_minutos = hf - floorf(hf)
		print("[vista] semente=%d %s" % [semente, "mundo novo" if novo else "mundo salvo, se houver"])
	var efeito: String = args.get("efeito", "")
	if efeito in ["chuva", "raio"]:
		_atmosfera.forcar_chuva = Vector2i(200, 330)
		_atmosfera.forcar_raio = efeito == "raio"


func avancar(delta: float, desenhar: bool) -> void:
	if sim:
		sim.avancar(delta)
	if not desenhar:
		return
	_relogio += delta
	if sim and _chave_fixo != _chave_do_fixo():
		_refazer = true
	if _refazer:
		_refazer = false
		_chave_fixo = _chave_do_fixo() if sim else []
		_montar_fixo()
	_atualizar_horario()
	_atualizar_agua()
	_atualizar_fogueiras()
	figuras = _figuras_layout() if _modo_layout else _figuras_nucleo(delta)
	_atualizar_camera(delta)
	_pessoas.definir(figuras)
	if OS.has_environment("CONTAR_SOBREPOSICAO") and sim:
		_contar_sobreposicao()
	if sim:
		_sinais.atualizar(sim, self, _relogio, figuras)
	_atmosfera.avancar(delta, _hora(), _estado[0] if _estado[2] < 0.5 else _estado[1], _fogos,
		{} if _modo_layout else sim.clima, _modo_layout)
	if _capturar != "" and _relogio >= _capturar_apos + _gravados * _intervalo:
		_quadros_ate_capturar -= 1
		if _quadros_ate_capturar <= 0:
			_quadros_ate_capturar = 1 << 30
			queue_redraw()  # no modo de baixo consumo, sem mudança não há quadro novo
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			if not _capturar_tudo:
				img = img.get_region(Rect2i(Vector2i(get_parent().global_position), Vector2i(LARGURA, ALTURA)))
			var arquivo := _capturar if _quadros == 1 else _capturar.replace(".png", "_%02d.png" % _gravados)
			img.save_png(arquivo)
			_gravados += 1
			_quadros_ate_capturar = 1
			print("[vista] capturada em %s" % arquivo)
			if _gravados >= _quadros:
				get_tree().quit()


## Ponto da tela da vista (0..480, 0..160) para pixels do mundo.
func para_mundo(ponto: Vector2) -> Vector2:
	return ponto / zoom + camera


func para_tela(ponto: Vector2) -> Vector2:
	return (ponto - camera) * zoom


## O que está sob o ponto do mundo: {tipo: "pessoa"|"sinal"|"lugar", ...}.
func objeto_em(p: Vector2) -> Dictionary:
	if sim == null:
		return {}
	var sinal := _sinais.sinal_em(p)
	if not sinal.is_empty():
		return {"tipo": "sinal", "prece": sinal}
	var melhor := {}
	var dist := INF
	for f in figuras:
		var r := Rect2(f.x - 1, f.base - 12, f.largura + 2, 14)
		if r.has_point(p) and absf(p.x - f.x - f.largura / 2.0) < dist:
			dist = absf(p.x - f.x - f.largura / 2.0)
			melhor = f
	if not melhor.is_empty():
		for pe in sim.pessoas:
			if pe["id"] == melhor.id:
				return {"tipo": "pessoa", "pessoa": pe, "prece": _sinais.prece_de(pe["id"])}
	for z in sim.zonas:
		if p.x >= z["x_ini"] and p.x < z["x_fim"]:
			return {"tipo": "lugar", "zona": z}
	return {}


func clicar(ponto_tela: Vector2) -> void:
	print("[vista] clique no mundo %s" % para_mundo(ponto_tela).round())
	var o := objeto_em(para_mundo(ponto_tela))
	if o.get("tipo", "") == "pessoa":
		pessoa_clicada.emit(o.pessoa["id"])


func alternar_seguir() -> void:
	seguindo = not seguindo


## Efeito do resultado de um poder (e de outros eventos com dados de ponto).
func _ao_receber_eventos(eventos: Array) -> void:
	for ev in eventos:
		match ev["tipo"]:
			"eclipse":
				_eclipse_ate = sim.mundo.passo + 3
			"chuva_divina", "raio_divino", "fogo_divino", "fartura_divina", "terra_erguida", "sonho":
				var d: Dictionary = ev.get("dados", {})
				var alvo := -1.0
				var ids: Array = ev.get("participantes", [])
				if not ids.is_empty():
					alvo = sim.mundo.posicao_de(ids[0])
				_atmosfera.poder(ev["tipo"], float(d.get("x", 240.0)), String(d.get("grau", "sinal")),
					alvo, modo_discreto)


# --- montagem -----------------------------------------------------------

func _criar_nos() -> void:
	var paleta := Arte.paleta_vec3()
	var tabelas := Arte.textura_tabelas()
	for nome in FUNDOS:
		var nomes := ESTADOS.duplicate()
		if nome == "ceu":
			nomes += ["seca", "eclipse"]
		var imgs := nomes.map(func(e): return Arte.imagem("camadas/%s_%s.png" % [nome, e]))
		var corte := _recortar(imgs)
		for i in nomes.size():
			_tex_fundo["%s_%s" % [nome, nomes[i]]] = corte[1][i]
		_canto_fundo.append(Vector2(corte[0].position))
		_fundos.append(_sprite(0, paleta, tabelas))
	_agua = _sprite(4, paleta, tabelas)
	_mundo = _sprite(1, paleta, tabelas)
	_fogueiras = Node2D.new()
	_fogueiras.draw.connect(_desenhar_fogueiras)
	add_child(_fogueiras)
	_pessoas = Pessoas.new()
	_pessoas.material = _material(2, paleta, tabelas)
	var opcoes := Arte.opcoes_troca()
	_pessoas.material.set_shader_parameter("peles", opcoes.peles)
	_pessoas.material.set_shader_parameter("cabelos", opcoes.cabelos)
	_pessoas.material.set_shader_parameter("roupas", PackedInt32Array(opcoes.roupas))
	add_child(_pessoas)
	_reflexo = _sprite(5, paleta, tabelas)
	_frente = _sprite(3, paleta, tabelas)
	_atmosfera = Atmosfera.new()
	add_child(_atmosfera)
	_atmosfera.criar(self, _material(6, paleta, tabelas), _frente)
	_sinais = Sinais.new()
	add_child(_sinais)
	var luz := Arte.textura("camadas/luz_fogueira.png")
	var halo := Arte.textura("camadas/luz_fogueira_halo.png")
	for m in _materiais:
		m.set_shader_parameter("luz", luz)
		m.set_shader_parameter("halo", halo)
	var folha := Arte.imagem("terreno/agua_superficie_4q.png")
	for i in 4:
		_quadros_agua.append(Arte.quadro(folha, i, 8))


func _material(plano: int, paleta: PackedVector3Array, tabelas: Texture2D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = REMAP
	m.set_shader_parameter("plano", plano)
	m.set_shader_parameter("paleta", paleta)
	m.set_shader_parameter("tabelas", tabelas)
	_materiais.append(m)
	return m


func _sprite(plano: int, paleta: PackedVector3Array, tabelas: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.material = _material(plano, paleta, tabelas)
	add_child(s)
	return s


## O que, além das construções, muda a imagem fixa: a estação (fase das roças).
func _chave_do_fixo() -> Array:
	return [sim.tempo.get("estacao", "")]


## Refaz tudo o que é fixo: terreno, vegetação, construções, marcas, reflexo e frente.
func _montar_fixo() -> void:
	var obras := _construcoes()
	_fogos.clear()
	var batido := []
	for o in obras:
		if o.tipo == "fogueira":
			var c := int(o.x) / 8
			for col in range(c - 3, c + 3):
				batido.append(col)
	var queimadas := []
	if sim:
		for z in sim.zonas:
			if z["queimada"]:
				for col in range(int(z["x_ini"]) / 8, int(z["x_fim"]) / 8):
					queimadas.append(col)
	var arvore_queimada := Arte.imagem("memoria/arvore_queimada.png") if not queimadas.is_empty() else null

	var terreno := Terreno.new()
	var colunas: Array = _layout["colunas"]
	_tipos = colunas.map(func(cl): return cl[1])
	var r := terreno.montar(colunas, batido, _quadros_agua[0], false, queimadas)
	var cor: Image = r.cor
	var tag: Image = r.tag
	_sup = r.sup
	var agua_mascara := _mascara_agua(tag)

	var frente := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var tag_frente := Image.create(LARGURA, ALTURA, false, Image.FORMAT_R8)
	var pecas := {}
	for item in _layout["pecas"]:
		var nome: String = item["peca"]
		if item["plano"] in ["pessoa", "fogo"] or nome == "cabana_galhos":
			continue
		if not _modo_layout and nome in PECAS_MIUDAS and _sob_construcao(item, obras):
			continue
		if item["plano"] == "mundo" and (int(item["x"]) + 8) / 8 in queimadas:
			if nome in ARVORES:  # tronco carbonizado no lugar da árvore
				var tronco: int = int(item["x"]) + ARVORES[nome]
				var pos_q := Vector2i(tronco - 15, int(item["base"]) - 31)
				terreno.colar(cor, tag, arvore_queimada, pos_q, Arte.MUNDO)
				continue
			if nome in PECAS_MIUDAS:
				continue
		if not pecas.has(nome):
			pecas[nome] = Arte.imagem("estagio1/%s.png" % nome)
		var img: Image = pecas[nome]
		if item.get("espelho", false):
			img = img.duplicate()
			img.flip_x()
		var pos := Vector2i(int(item["x"]), int(item["base"]) - img.get_height() + 1)
		if item["plano"] == "frente":
			terreno.colar(frente, tag_frente, img, pos, Arte.FRENTE)
		else:
			terreno.colar(cor, tag, img, pos, Arte.AGUA if item["plano"] == "agua" else Arte.MUNDO)
			# a peça fica por cima do reflexo, como em montar.py
			agua_mascara.blit_rect_mask(_vazio(img.get_size()), img, Rect2i(Vector2i.ZERO, img.get_size()), pos)

	var cabana := Arte.imagem("estagio1/cabana_galhos.png")
	var altar := Arte.imagem("estagio2/altar.png")
	var roca := Arte.imagem("estagio2/%s.png" % _fase_da_roca())
	for o in obras:
		var x := roundi(o.x)
		match o.tipo:
			"cabana":
				terreno.colar(cor, tag, cabana, Vector2i(x - 8, _chao(x) - 15), Arte.MUNDO)
			"altar":
				terreno.colar(cor, tag, altar, Vector2i(x - 8, _chao(x) - 15), Arte.MUNDO)
			"roca":
				# 24 px: a peça de 16 repete a cada 4 px, então duas cópias emendam
				for dx in [-12, -4]:
					terreno.colar(cor, tag, roca, Vector2i(x + dx, _sup[clampi(x, 0, LARGURA - 1)] - 15), Arte.MUNDO)
			"fogueira":
				var canto := Vector2i(x - 8, _chao(x) - 15)
				_fogos.append({"canto": canto, "centro": float(x),
					"luz": Vector2(snappedi(canto.x, 4) - 56, snappedi(canto.y, 4) - 32)})
	if sim:
		var pedra := Arte.imagem("memoria/pedra_erguida.png")
		for z in sim.zonas:
			if z["pedra_erguida"]:
				var x := roundi(z["pedra_x"])
				terreno.colar(cor, tag, pedra, Vector2i(x - 8, _chao(x) - 31), Arte.MUNDO)

	_mundo.texture = ImageTexture.create_from_image(cor)
	var corte := _recortar([frente])
	_frente.texture = corte[1][0]
	_frente.position = Vector2(corte[0].position)
	var refs := []
	for e in ESTADOS:
		var ref := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
		var fonte := Arte.imagem("camadas/reflexo_%s.png" % e)
		ref.blit_rect_mask(fonte, agua_mascara, Rect2i(0, 0, LARGURA, ALTURA), Vector2i.ZERO)
		refs.append(ref)
	corte = _recortar(refs)
	_tex_reflexo = corte[1]
	_reflexo.position = Vector2(corte[0].position)
	var sup_img := Image.create(LARGURA, 1, false, Image.FORMAT_R8)
	for x in LARGURA:
		sup_img.set_pixel(x, 0, Color8(_sup[x], 0, 0))
	var tex_tag := ImageTexture.create_from_image(tag)
	var tex_sup := ImageTexture.create_from_image(sup_img)
	var luzes := PackedVector2Array()
	for f in _fogos.slice(0, 4):
		luzes.append(f.luz)
	var n := luzes.size()
	luzes.resize(4)
	for m in _materiais:
		m.set_shader_parameter("etiquetas", tex_tag)
		m.set_shader_parameter("superficie", tex_sup)
		m.set_shader_parameter("fogos", luzes)
		m.set_shader_parameter("n_fogos", n)
	_montar_agua()
	_estado = []
	_fogueiras.queue_redraw()


func _fase_da_roca() -> String:
	if sim == null:
		return "roca_arada"
	if sim.clima.get("seca", false):
		return "roca_seca"
	match sim.tempo.get("estacao", ""):
		"primavera":
			return "roca_broto"
		"verão":
			return "roca_crescida"
		"outono":
			return "roca_madura"
	return "roca_arada"


## Construções do núcleo, ou as da cena-alvo no modo layout.
func _construcoes() -> Array:
	if not _modo_layout:
		return sim.construcoes.map(func(o): return {"tipo": o["tipo"], "x": float(o["x"])})
	var r := []
	for item in _layout["pecas"]:
		if item["peca"] == "cabana_galhos":
			r.append({"tipo": "cabana", "x": item["x"] + 8.0})
	r.append({"tipo": "fogueira", "x": _layout["fogueira"]["x"] + 8.0})
	return r


func _sob_construcao(item: Dictionary, obras: Array) -> bool:
	var x0 := float(item["x"])
	for o in obras:
		if abs(x0 + 4.0 - o.x) < 14.0:
			return true
	return false


## Onde uma partícula toca: a linha d'água no mar, o chão no resto.
func chao(x: int) -> int:
	return Terreno.NIVEL_AGUA - 1 if _na_agua(x) else _chao(x)


func cor_paleta(i: int) -> Color:
	return Arte.paleta[i]


## Linha do chão em x: a superfície menos 1, como as peças da cena-alvo.
func _chao(x: int) -> int:
	return _sup[clampi(x, 0, LARGURA - 1)] - 1


func _na_agua(x: int) -> bool:
	var c := clampi(x, 0, LARGURA - 1) / 8
	return _tipos[c] == "areia" and _sup[c * 8] > Terreno.NIVEL_AGUA


func _mascara_agua(tag: Image) -> Image:
	var m := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	for y in ALTURA:
		for x in LARGURA:
			if roundi(tag.get_pixel(x, y).r * 255.0) == Arte.AGUA:
				m.set_pixel(x, y, Color.WHITE)
	return m


## Recorta imagens do mesmo plano à área usada por qualquer uma delas, para
## não guardar texturas de tela inteira quase vazias. Devolve [canto, texturas].
static func _recortar(imgs: Array) -> Array:
	var r := Rect2i()
	for img in imgs:
		var usada: Rect2i = img.get_used_rect()
		if usada.has_area():
			r = usada if not r.has_area() else r.merge(usada)
	if not r.has_area():
		r = Rect2i(0, 0, 1, 1)
	return [r, imgs.map(func(img): return ImageTexture.create_from_image(img.get_region(r)))]


func _vazio(tamanho: Vector2i) -> Image:
	return Image.create(tamanho.x, tamanho.y, false, Image.FORMAT_RGBA8)


## A superfície da água é desenhada à parte, em 4 quadros que deslizam.
func _montar_agua() -> void:
	_tex_agua.clear()
	for q in 4:
		var faixa := Image.create(LARGURA, 8, false, Image.FORMAT_RGBA8)
		for c in LARGURA / 8:
			if _tipos[c] == "areia" and _sup[c * 8] > Terreno.NIVEL_AGUA:
				faixa.blit_rect_mask(_quadros_agua[q], _quadros_agua[q], Rect2i(0, 0, 8, 8), Vector2i(c * 8, 0))
		_tex_agua.append(ImageTexture.create_from_image(faixa))
	_agua.position = Vector2(0, 120)
	_quadro_agua = -1


# --- a cada quadro ---------------------------------------------------------

func _parado() -> bool:
	return _modo_layout or (sim != null and sim.congelado)


func _atualizar_agua() -> void:
	var q := 0 if _parado() else int(_relogio * 4.0) % 4
	if q != _quadro_agua:
		_quadro_agua = q
		_agua.texture = _tex_agua[q]
		_reflexo.material.set_shader_parameter("onda", q)
		_reflexo.material.set_shader_parameter("ondulacao", 0.0 if _parado() else 1.0)


func _atualizar_fogueiras() -> void:
	var q := 0 if _parado() else int(_relogio * 6.0) % 4
	if q != _quadro_fogo:
		_quadro_fogo = q
		_fogueiras.queue_redraw()


func _desenhar_fogueiras() -> void:
	if _fogos.is_empty():
		return
	if _tex_fogueira == null:
		_tex_fogueira = Arte.textura("estagio1/fogueira_acesa_4q.png")
	for f in _fogos:
		_fogueiras.draw_texture_rect_region(_tex_fogueira, Rect2(f.canto, Vector2(16, 16)),
			Rect2(maxi(_quadro_fogo, 0) * 16, 0, 16, 16))


## Mistura de estados do céu pela hora (com minutos), quantizada em 16 passos.
static func estado_da_hora(h: float) -> Array:
	var faixas := [
		[0.0, 5.0, NOITE, NOITE], [5.0, 6.0, NOITE, ENTARDECER], [6.0, 7.0, ENTARDECER, DIA],
		[7.0, 17.0, DIA, DIA], [17.0, 18.0, DIA, ENTARDECER], [18.0, 19.0, ENTARDECER, ENTARDECER],
		[19.0, 20.0, ENTARDECER, NOITE], [20.0, 24.0, NOITE, NOITE]]
	for f in faixas:
		if h >= f[0] and h < f[1]:
			var t: float = (h - f[0]) / (f[1] - f[0]) if f[2] != f[3] else 0.0
			return [f[2], f[3], floorf(t * 16.0) / 16.0]
	return [NOITE, NOITE, 0.0]


func _hora() -> float:
	return _hora_fixa if _hora_fixa >= 0.0 else sim.hora_continua() + _minutos


func _atualizar_horario() -> void:
	var e := estado_da_hora(_hora())
	if _atmosfera.em_clarao():
		e = [DIA, DIA, 0.0]
	var especial := ""
	if sim and _eclipse_ate >= sim.mundo.passo:
		especial = "eclipse"
	elif sim and sim.clima.get("seca", false):
		especial = "seca"
	e.append(especial)
	if e == _estado:
		return
	_estado = e
	var a: int = e[0]
	var b: int = e[1]
	for i in FUNDOS.size():
		_fundos[i].texture = _tex_fundo[_nome_fundo(i, a, especial)]
		_fundos[i].material.set_shader_parameter("tex_b", _tex_fundo[_nome_fundo(i, b, especial)])
	_reflexo.texture = _tex_reflexo[a]
	_reflexo.material.set_shader_parameter("tex_b", _tex_reflexo[b])
	for m in _materiais:
		m.set_shader_parameter("estado_a", a)
		m.set_shader_parameter("estado_b", b)
		m.set_shader_parameter("t", e[2])


## O céu de dia vira o de seca ou o de eclipse quando é o caso.
func _nome_fundo(i: int, estado: int, especial: String) -> String:
	if i == 0 and estado == DIA and especial != "":
		return "ceu_" + especial
	return "%s_%s" % [FUNDOS[i], ESTADOS[estado]]


## Seguindo, a vista aproxima 2x e centra a pessoa acompanhada.
func _atualizar_camera(delta: float) -> void:
	var alvo_zoom := 1
	var alvo := Vector2.ZERO
	if seguindo and sim and sim.mundo.acompanhada >= 0:
		for f in figuras:
			if f.id == sim.mundo.acompanhada:
				alvo_zoom = ZOOM_SEGUIR
				var meio := Vector2(f.x + f.largura / 2.0, f.base - 20)
				var vista := Vector2(LARGURA, ALTURA) / ZOOM_SEGUIR
				alvo = (meio - vista / 2.0).clamp(Vector2.ZERO, Vector2(LARGURA, ALTURA) - vista)
		if alvo_zoom == 1:  # a pessoa está numa cabana: mira a casa dela
			var x: float = sim.mundo.posicao_de(sim.mundo.acompanhada)
			if x >= 0.0:
				alvo_zoom = ZOOM_SEGUIR
				alvo = Vector2(clampf(x - 120.0, 0.0, 240.0), 40.0)
	if alvo_zoom != zoom:
		zoom = alvo_zoom
		camera = alvo
	else:
		camera = camera.move_toward(alvo, maxf(40.0, camera.distance_to(alvo) * 3.0) * delta)
	var c := camera.round()
	if [zoom, c] == _camera_aplicada:
		return
	_camera_aplicada = [zoom, c]
	scale = Vector2(zoom, zoom)
	position = -c * zoom
	# os planos de fundo andam menos que o mundo (paralaxe)
	for i in FUNDOS.size():
		_fundos[i].position = _canto_fundo[i] + (c * (1.0 - PARALAXE[i])).round()
	var origem: Vector2 = get_parent().global_position + position
	for m in _materiais:
		m.set_shader_parameter("origem", origem)
		m.set_shader_parameter("zoom", float(zoom))
	_atmosfera.definir_camera(origem, float(zoom))


# --- pessoas ---------------------------------------------------------------

func _fogo_mais_perto(x: float) -> float:
	var melhor := -10000.0
	for f in _fogos:
		if abs(f.centro - x) < abs(melhor - x):
			melhor = f.centro
	return melhor


func _figuras_layout() -> Array:
	var r := []
	for item in _layout["pecas"]:
		if item["plano"] != "pessoa":
			continue
		r.append({"id": -1, "folha": item["peca"], "quadro": int(item["quadro"]), "largura": int(item["larg_quadro"]),
			"x": int(item["x"]), "base": int(item["base"]), "espelho": item.get("espelho", false),
			"codigo": Arte.codigo_de_tabela(item.get("troca", {})),
			"fogo": _fogo_mais_perto(item["x"] + item["larg_quadro"] / 2.0)})
	return r


## Onde cada pessoa fica, sem amontoar. Quem está na fogueira quer um lugar
## da roda, dos dois lados do fogo; os outros querem o x do núcleo. Depois,
## todos são empacotados numa fila só, com ESPACO entre vizinhos: blocos que se
## encostam se juntam e se centram nas posições desejadas. A ordem é pelo x
## desejado e pelo id, então ninguém troca de lugar de um quadro para o outro.
func _lugares(pessoas: Array) -> Dictionary:
	var desejos := []  # [x desejado, id]
	var rodas := {}
	for p in pessoas:
		if p["acao"] == "dormir":
			continue
		if p["acao"] == "fogueira":
			var f := _fogo_mais_perto(p["x"])
			if not rodas.has(f):
				rodas[f] = []
			rodas[f].append(p["id"])
		else:
			desejos.append([float(p["x"]), p["id"]])
	for f in rodas:
		var roda: Array = rodas[f]
		roda.sort()
		for i in roda.size():
			var lado := -1.0 if i % 2 == 0 else 1.0
			desejos.append([f + lado * (11.0 + ESPACO * (i / 2)), roda[i]])
	desejos.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var xs := _empacotar(desejos.map(func(d): return d[0]))
	var lugar := {}
	for i in desejos.size():
		lugar[desejos[i][1]] = xs[i]
	return lugar


## Posições em ordem, a ESPACO ou mais umas das outras, o mais perto possível
## das desejadas (blocos que se encostam se juntam e se centram), dentro da
## terra e da tela.
static func _empacotar(desejado: Array) -> Array:
	var blocos := []  # [quantos, soma de (x - k × ESPACO)]
	for x in desejado:
		blocos.append([1, x])
		while blocos.size() >= 2:
			var a: Array = blocos[-2]
			var b: Array = blocos[-1]
			if a[1] / a[0] + a[0] * ESPACO <= b[1] / b[0]:
				break
			blocos.pop_back()
			blocos[-1] = [a[0] + b[0], a[1] + b[1] - b[0] * a[0] * ESPACO]
	var xs := []
	for bl in blocos:
		var inicio: float = bl[1] / bl[0]
		for k in bl[0]:
			xs.append(inicio + k * ESPACO)
	for i in xs.size():  # a margem do lago e a borda direita
		xs[i] = maxf(xs[i], MARGEM if i == 0 else xs[i - 1] + ESPACO)
	for i in range(xs.size() - 1, -1, -1):
		xs[i] = minf(xs[i], LARGURA - 4.0 if i == xs.size() - 1 else xs[i + 1] - ESPACO)
	return xs


var _maior_sobreposicao := [0, 0]


## Teste: quantas figuras cobrem a mesma coluna de pixels (a regra é no máximo 2).
## Conta só quem está parado no lugar, e à parte quem está andando.
func _contar_sobreposicao() -> void:
	var maiores := [0, 0]  # só os parados, e todos
	for so_parados in [true, false]:
		var colunas := PackedInt32Array()
		colunas.resize(LARGURA)
		for f in figuras:
			if so_parados and f.movendo:
				continue
			for x in range(maxi(0, f.x + 1), mini(LARGURA, f.x + f.largura - 1)):  # sem a borda de 1 px
				colunas[x] += 1
		for c in colunas:
			maiores[0 if so_parados else 1] = maxi(maiores[0 if so_parados else 1], c)
	if maiores[0] > _maior_sobreposicao[0] or maiores[1] > _maior_sobreposicao[1]:
		_maior_sobreposicao = [maxi(maiores[0], _maior_sobreposicao[0]), maxi(maiores[1], _maior_sobreposicao[1])]
		print("[sobreposicao] parados=%d todos=%d hora=%s figuras=%d" % [_maior_sobreposicao[0], _maior_sobreposicao[1],
			sim.tempo.get("hora"), figuras.size()])


func _figuras_nucleo(delta: float) -> Array:
	var r := []
	var opcoes := Arte.opcoes_troca()
	var lugar := _lugares(sim.pessoas)
	var vivos := {}
	for p in sim.pessoas:
		var id: int = p["id"]
		vivos[id] = true
		var destino: float = lugar.get(id, p["x"])
		var x: float = _x_visto.get(id, destino)
		# todos na mesma velocidade: quem sai em fila espaçada chega em fila espaçada
		var vel := PASSO_ANDAR * (4.0 if sim.ritmo == Simulacao.Ritmo.RAPIDO else 1.0)
		if absf(destino - x) > 120.0:  # salto no tempo: aparece no lugar novo
			x = destino
		var anterior := x
		x = move_toward(x, destino, vel * delta)
		_x_visto[id] = x
		if p["acao"] == "dormir":
			_acordou.erase(id)
			continue
		# quem acorda junto sai da cabana em fila, não empilhado
		if not _acordou.has(id):
			_acordou[id] = _relogio
		var espera := (id % 10) * ESPACO / vel
		if _relogio - _acordou[id] < espera and absf(destino - x) > ESPACO:
			_x_visto[id] = anterior
			continue
		var crianca: bool = p["crianca"]
		var idoso: bool = p["idade"] >= 55 and not crianca
		var movendo := absf(x - anterior) > 0.001
		var fogo := _fogo_mais_perto(x)
		if movendo:
			_virada[id] = x < anterior
		elif p["acao"] in ["fogueira", "rezar"]:
			_virada[id] = fogo < x
		var espelho: bool = _virada.get(id, id % 2 == 0)

		var folha: String
		var quadro := 0
		var largura := 6 if crianca else 8
		var feminina: bool = p["sexo"] == "f"
		if movendo:
			folha = "crianca_andar_4q" if crianca else ("idoso_andar_4q" if idoso else
				("adulto_b_andar_4q" if feminina else "adulto_a_andar_4q"))
			quadro = int(_relogio * 6.0 + id) % 4
		else:
			match p["acao"]:
				"colher":
					folha = "crianca_andar_4q" if crianca else "adulto_a_colher_4q"
					quadro = 0 if crianca else int(_relogio * 3.0 + id) % 4
				"rezar":
					folha = "crianca_andar_4q" if crianca else "adulto_a_rezar_2q"
					quadro = 0 if crianca else int(_relogio * 0.8 + id) % 2
				"fogueira":
					folha = "crianca_andar_4q" if crianca else "adulto_a_sentado_1q"
				_:  # parado, ou andar já no destino
					if crianca:
						folha = "crianca_andar_4q"
					elif idoso:
						folha = "idoso_andar_4q"
						quadro = 1
					else:
						folha = "adulto_b_parado_2q" if feminina else "adulto_a_parado_2q"
						quadro = int(_relogio + id * 0.37) % 2

		var pele: int = id % opcoes.peles.size()
		var cabelo: int = (id * 7 + 3) % (opcoes.cabelos.size() - 1)  # o último é o grisalho
		if idoso:
			cabelo = 5 if folha == "idoso_andar_4q" else opcoes.cabelos.size() - 1
		var roupa: int = (id * 5 + int(p["grupo"])) % opcoes.roupas.size()

		var xr := roundi(x)
		var base := _chao(xr)
		if _na_agua(xr):
			base = Terreno.NIVEL_AGUA + 2
		r.append({"id": id, "folha": folha, "quadro": quadro, "largura": largura, "x": xr - largura / 2,
			"base": base, "espelho": espelho, "codigo": Arte.codigo_troca(pele, cabelo, roupa), "fogo": fogo,
			"acompanhada": p.get("acompanhada", false), "movendo": movendo})
	for id in _x_visto.keys():
		if not vivos.has(id):
			_x_visto.erase(id)
			_virada.erase(id)
			_acordou.erase(id)
	return r


func _ler_argumentos() -> Dictionary:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var partes := a.substr(2).split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	return args

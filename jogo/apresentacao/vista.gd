extends Node2D
## Vista do mundo (480 × 160), montada com as peças de arte_claude/pecas.
##
## As partes fixas (terreno, vegetação, cabanas) viram uma imagem só, refeita
## apenas quando as construções do núcleo mudam. O horário (dia, entardecer,
## noite) e a luz das fogueiras saem de remap.gdshader, que troca as cores
## pelas tabelas da arte. Pessoas, fogueiras e água são desenhadas por cima.
##
## Argumentos (depois de "--"):
##   --cena=layout        monta exatamente arte/camadas/layout.json (teste de fidelidade)
##   --hora=dia|entardecer|noite|N   horário inicial
##   --congelar           o tempo não anda
##   --semente=N          semente do mundo
##   --capturar=ARQUIVO   grava a vista (480 × 160) em PNG e fecha

const Arte = preload("res://apresentacao/arte.gd")
const Terreno = preload("res://apresentacao/terreno.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")
const Pessoas = preload("res://apresentacao/pessoas.gd")
const REMAP = preload("res://apresentacao/remap.gdshader")

const LARGURA := 480
const ALTURA := 160
const ESTADOS := ["dia", "entardecer", "noite"]
const DIA := 0
const ENTARDECER := 1
const NOITE := 2
const FUNDOS := ["ceu", "montanhas_longe", "montanhas_perto", "mata_distante"]
## Quanto cada plano de fundo acompanha a câmera (0 = parado no infinito).
const PARALAXE := [0.0, 0.15, 0.3, 0.6]
const HORAS_NOMEADAS := {"dia": 12, "entardecer": 18, "noite": 22}
## Peças pequenas do cenário que somem quando uma construção cai em cima.
const PECAS_MIUDAS := ["capim", "capim_seco", "arbusto", "arbusto_frutas", "pedra_pequena",
	"pedra_grande", "tronco_deriva", "juncos"]

var camera_x := 0.0  # deslocamento da vista; a paralaxe entra quando houver aproximação

var sim: Simulacao
var _layout: Dictionary
var _modo_layout := false
var _hora_fixa := -1.0
var _capturar := ""
var _quadros_ate_capturar := 4

var _materiais: Array[ShaderMaterial] = []
var _fundos: Array[Sprite2D] = []
var _tex_fundo := {}       # "ceu_dia" -> Texture2D
var _tex_reflexo := []     # por estado
var _mundo: Sprite2D
var _agua: Sprite2D
var _reflexo: Sprite2D
var _frente: Sprite2D
var _fogueiras: Node2D
var _pessoas: Pessoas
var _quadros_agua: Array[Image] = []
var _tex_agua: Array[ImageTexture] = []
var _sup := PackedInt32Array()
var _tipos := []           # tipo do terreno por coluna de 8 px
var _fogos: Array = []     # [{canto: Vector2i, centro: float}]
var _estado := [-1, -1, -1.0]
var _relogio := 0.0
var _quadro_agua := -1
var _quadro_fogo := -1
var _refazer := true
var _virada := {}          # id da pessoa -> espelho (olhando para a esquerda)
var _tex_fogueira: Texture2D


func _ready() -> void:
	var args := _ler_argumentos()
	_modo_layout = args.get("cena", "") == "layout"
	_capturar = args.get("capturar", "")
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
		var semente := int(args.get("semente", str(randi())))
		var h := int(HORAS_NOMEADAS.get(hora, hora)) if hora != "" else -1
		sim.iniciar(semente, h)
		sim.congelado = args.has("congelar")
		print("[vista] semente=%d" % semente)


func avancar(delta: float, desenhar: bool) -> void:
	if sim:
		sim.avancar(delta)
	if not desenhar:
		return
	_relogio += delta
	if _refazer:
		_refazer = false
		_montar_fixo()
	_atualizar_horario()
	_atualizar_agua()
	_atualizar_fogueiras()
	_pessoas.definir(_figuras_layout() if _modo_layout else _figuras_nucleo())
	if _capturar != "":
		_quadros_ate_capturar -= 1
		if _quadros_ate_capturar == 0:
			queue_redraw()  # no modo de baixo consumo, sem mudança não há quadro novo
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image().get_region(Rect2i(0, 16, LARGURA, ALTURA))
			img.save_png(_capturar)
			print("[vista] capturada em %s" % _capturar)
			get_tree().quit()


func ao_clicar(_ponto: Vector2) -> void:
	pass


# --- montagem -----------------------------------------------------------

func _criar_nos() -> void:
	var paleta := Arte.paleta_vec3()
	var tabelas := Arte.textura_tabelas()
	for nome in FUNDOS:
		for e in ESTADOS:
			_tex_fundo["%s_%s" % [nome, e]] = Arte.textura("camadas/%s_%s.png" % [nome, e])
		_fundos.append(_sprite(0, paleta, tabelas))
	_agua = _sprite(4, paleta, tabelas)
	_mundo = _sprite(1, paleta, tabelas)
	_fogueiras = Node2D.new()
	_fogueiras.draw.connect(_desenhar_fogueiras)
	add_child(_fogueiras)
	_pessoas = Pessoas.new()
	_pessoas.material = _material(2, paleta, tabelas)
	add_child(_pessoas)
	_reflexo = _sprite(5, paleta, tabelas)
	_frente = _sprite(3, paleta, tabelas)
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


## Refaz tudo o que é fixo: terreno, vegetação, construções, reflexo e frente.
func _montar_fixo() -> void:
	var obras := _construcoes()
	_fogos.clear()
	var batido := []
	for o in obras:
		if o.tipo == "fogueira":
			var c := int(o.x) / 8
			for col in range(c - 3, c + 3):
				batido.append(col)

	var terreno := Terreno.new()
	var colunas: Array = _layout["colunas"]
	_tipos = colunas.map(func(cl): return cl[1])
	var r := terreno.montar(colunas, batido, _quadros_agua[0], false)
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
	var altar := Arte.imagem("estagio1/pedra_grande.png")  # provisório: ainda não há peça de altar
	for o in obras:
		var x := roundi(o.x)
		match o.tipo:
			"cabana":
				terreno.colar(cor, tag, cabana, Vector2i(x - 8, _chao(x) - 15), Arte.MUNDO)
			"altar":
				terreno.colar(cor, tag, altar, Vector2i(x - 8, _chao(x) - 14), Arte.MUNDO)
			"fogueira":
				var canto := Vector2i(x - 8, _chao(x) - 15)
				_fogos.append({"canto": canto, "centro": float(x),
					"luz": Vector2(snappedi(canto.x, 4) - 56, snappedi(canto.y, 4) - 32)})

	_mundo.texture = ImageTexture.create_from_image(cor)
	_frente.texture = ImageTexture.create_from_image(frente)
	_tex_reflexo.clear()
	for e in ESTADOS:
		var ref := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
		var fonte := Arte.imagem("camadas/reflexo_%s.png" % e)
		ref.blit_rect_mask(fonte, agua_mascara, Rect2i(0, 0, LARGURA, ALTURA), Vector2i.ZERO)
		_tex_reflexo.append(ImageTexture.create_from_image(ref))
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
	_montar_agua(tag)
	_estado = [-1, -1, -1.0]
	_fogueiras.queue_redraw()


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


func _vazio(tamanho: Vector2i) -> Image:
	return Image.create(tamanho.x, tamanho.y, false, Image.FORMAT_RGBA8)


## A superfície da água é desenhada à parte, em 4 quadros que deslizam.
func _montar_agua(tag: Image) -> void:
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

func _atualizar_agua() -> void:
	var q := 0 if (_modo_layout or (sim and sim.congelado)) else int(_relogio * 4.0) % 4
	if q != _quadro_agua:
		_quadro_agua = q
		_agua.texture = _tex_agua[q]


func _atualizar_fogueiras() -> void:
	var q := 0 if (_modo_layout or (sim and sim.congelado)) else int(_relogio * 6.0) % 4
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


func _atualizar_horario() -> void:
	var h := _hora_fixa if _hora_fixa >= 0.0 else sim.hora_continua()
	var e := estado_da_hora(h)
	if e == _estado:
		return
	_estado = e
	var a: int = e[0]
	var b: int = e[1]
	for i in FUNDOS.size():
		_fundos[i].texture = _tex_fundo["%s_%s" % [FUNDOS[i], ESTADOS[a]]]
		_fundos[i].material.set_shader_parameter("tex_b", _tex_fundo["%s_%s" % [FUNDOS[i], ESTADOS[b]]])
		_fundos[i].position.x = -camera_x * PARALAXE[i]
	_reflexo.texture = _tex_reflexo[a]
	_reflexo.material.set_shader_parameter("tex_b", _tex_reflexo[b])
	for m in _materiais:
		m.set_shader_parameter("estado_a", a)
		m.set_shader_parameter("estado_b", b)
		m.set_shader_parameter("t", e[2])


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
		r.append({"folha": item["peca"], "quadro": int(item["quadro"]), "largura": int(item["larg_quadro"]),
			"x": int(item["x"]), "base": int(item["base"]), "espelho": item.get("espelho", false),
			"troca": item.get("troca", {}), "fogo": _fogo_mais_perto(item["x"] + item["larg_quadro"] / 2.0)})
	return r


func _figuras_nucleo() -> Array:
	var r := []
	var opcoes := Arte.opcoes_troca()
	var f := sim.fracao()
	for p in sim.pessoas:
		if p["acao"] == "dormir":
			continue
		var id: int = p["id"]
		var crianca: bool = p["crianca"]
		var idoso: bool = p["idade"] >= 55 and not crianca
		var xa: float = p["x_anterior"]
		var xb: float = p["x"]
		var x := lerpf(xa, xb, f)
		var movendo: bool = absf(xb - xa) > 0.5 and p["acao"] == "andar"
		var fogo := _fogo_mais_perto(x)
		if movendo:
			_virada[id] = xb < xa
		elif p["acao"] in ["fogueira", "rezar"]:
			_virada[id] = fogo < x
		var espelho: bool = _virada.get(id, id % 2 == 0)

		var folha: String
		var quadro := 0
		var largura := 6 if crianca else 8
		var feminina: bool = p["sexo"] == "f"
		match p["acao"]:
			"andar":
				folha = "crianca_andar_4q" if crianca else ("idoso_andar_4q" if idoso else
					("adulto_b_andar_4q" if feminina else "adulto_a_andar_4q"))
				quadro = int(_relogio * 6.0) % 4 if movendo else 1
			"colher":
				folha = "crianca_andar_4q" if crianca else "adulto_a_colher_4q"
				quadro = 0 if crianca else int(_relogio * 3.0 + id) % 4
			"rezar":
				folha = "crianca_andar_4q" if crianca else "adulto_a_rezar_2q"
				quadro = 0 if crianca else int(_relogio * 0.8 + id) % 2
			"fogueira":
				folha = "crianca_andar_4q" if crianca else "adulto_a_sentado_1q"
			_:  # parado
				if crianca:
					folha = "crianca_andar_4q"
				elif idoso:
					folha = "idoso_andar_4q"
					quadro = 1
				else:
					folha = "adulto_b_parado_2q" if feminina else "adulto_a_parado_2q"
					quadro = int(_relogio + id * 0.37) % 2

		var pele := int(opcoes.peles[id % opcoes.peles.size()])
		var cabelos: Array = opcoes.cabelos
		var cabelo := int(cabelos[(id * 7 + 3) % (cabelos.size() - 1)])  # sem o grisalho
		var roupa := int(opcoes.roupas[int(p["grupo"]) % opcoes.roupas.size()])
		var troca := Arte.troca_pessoa(pele, cabelo, roupa)
		if idoso and folha == "idoso_andar_4q":
			troca.erase(30)
			troca.erase(8)

		var xi := roundi(x) - largura / 2
		var base := _chao(roundi(x))
		if _na_agua(roundi(x)):
			base = Terreno.NIVEL_AGUA + 2
		r.append({"folha": folha, "quadro": quadro, "largura": largura, "x": xi, "base": base,
			"espelho": espelho, "troca": troca, "fogo": fogo})
	return r


func _ler_argumentos() -> Dictionary:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var partes := a.substr(2).split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	return args

extends Node
## Atmosfera feita por código: neblina, fumaça e faíscas das fogueiras,
## vagalumes, chuva com respingos, raios e o clarão que eles fazem, e os
## efeitos dos 6 poderes.
## A vista chama avancar() a cada quadro visível; tudo usa um sorteio próprio,
## nunca o do núcleo.

const Efeitos = preload("res://apresentacao/efeitos.gd")
const NEBLINA = preload("res://apresentacao/neblina.gdshader")

const DIA := 0
const ENTARDECER := 1
const NOITE := 2
const CLARAO := 0.09  # segundos de céu claro num raio
## Força visual de cada grau do poder.
const FORCA := {"sinal": 0.5, "milagre": 1.0, "imposicao": 1.5}

var vista: Node2D
var fosco: Efeitos      # passa pela tabela de noite
var luminoso: Efeitos   # emite luz: não escurece
var forcar_chuva := Vector2i(-1, -1)  # faixa x de chuva forçada (teste), -1 = não
var forcar_raio := false

var _neblina: Node2D
var _mat_neblina: ShaderMaterial
var _neblina_estado := []
var _deriva := 0.0
var _rng := RandomNumberGenerator.new()
var _espera_fumaca := 0.0
var _espera_faisca := 0.0
var _espera_raio := 1.0
var _clarao := 0.0
var _nuvens_em := Vector2i(-1, -1)
var _chuva_divina := Vector2i(-1, -1)
var _chuva_divina_resta := 0.0


## `antes_de` é o nó que fica logo acima da neblina (o primeiro plano).
func criar(p_vista: Node2D, material_fosco: Material, antes_de: Node) -> void:
	vista = p_vista
	_rng.randomize()
	_neblina = Node2D.new()
	_mat_neblina = ShaderMaterial.new()
	_mat_neblina.shader = NEBLINA
	_neblina.material = _mat_neblina
	_neblina.draw.connect(func(): _neblina.draw_rect(Rect2(0, 0, 480, 160), Color.WHITE))
	vista.add_child(_neblina)
	vista.move_child(_neblina, antes_de.get_index())
	fosco = Efeitos.new()
	fosco.material = material_fosco
	vista.add_child(fosco)
	luminoso = Efeitos.new()
	vista.add_child(luminoso)


func definir_camera(origem: Vector2, zoom: float) -> void:
	_mat_neblina.set_shader_parameter("origem", origem)
	_mat_neblina.set_shader_parameter("zoom", zoom)


## Efeito visual de um poder usado em x. `alvo` é o x de quem foi atingido (raio,
## sonho), ou -1. No modo discreto, fogo e raio não mostram chamas nem impacto.
func poder(tipo: String, x: float, grau: String, alvo: float, discreto: bool) -> void:
	var f: float = FORCA.get(grau, 0.5)
	var chao: int = vista.chao(int(x))
	match tipo:
		"chuva_divina":
			var meia := int(30.0 + 30.0 * f)
			_chuva_divina = Vector2i(maxi(0, int(x) - meia), mini(479, int(x) + meia))
			_chuva_divina_resta = 4.0 + 8.0 * f
		"raio_divino":
			if discreto:
				_clarao = CLARAO
			else:
				raio(alvo if alvo >= 0.0 else x)
		"fogo_divino":
			var n := int(2 + 4 * f)
			for i in n:
				var px := x + _rng.randf_range(-18.0, 18.0) * f
				var c: int = vista.chao(int(px))
				if not discreto:
					luminoso.emitir("chamas_4q", 16, 4, Vector2(px, c + 1), Vector2.ZERO,
						_rng.randf_range(3.0, 6.0) * f, 8.0, _rng.randi_range(0, 3))
				luminoso.emitir("brasas_4q", 8, 4, Vector2(px, c + 1), Vector2.ZERO, 9.0, 3.0, i)
				fosco.emitir("fumaca_6q", 16, 6, Vector2(px, c - 10), Vector2(2.0, -8.0), 3.5)
		"fartura_divina":
			for i in int(3 + 3 * f):
				var px := x + _rng.randf_range(-20.0, 20.0)
				luminoso.emitir("fartura_aura_4q", 16, 4, Vector2(px, vista.chao(int(px)) + 1), Vector2.ZERO,
					3.0 + 2.0 * f, 6.0, i)
			for i in int(8 * f + 4):
				var px := x + _rng.randf_range(-24.0, 24.0)
				luminoso.emitir("fartura_brilho_4q", 8, 4, Vector2(px, vista.chao(int(px)) - _rng.randf_range(0, 6)),
					Vector2(0, -6), _rng.randf_range(1.5, 3.0), 6.0, i)
		"terra_erguida":
			fosco.emitir("terra_subindo_4q", 32, 4, Vector2(x, chao + 1), Vector2.ZERO, 1.4)
			fosco.emitir("poeira_4q", 16, 4, Vector2(x - 12, chao + 1), Vector2(-4, 0), 0.9)
			fosco.emitir("poeira_4q", 16, 4, Vector2(x + 12, chao + 1), Vector2(4, 0), 0.9)
		"sonho":
			var px := alvo if alvo >= 0.0 else x
			var c: int = vista.chao(int(px))
			luminoso.emitir("sonho_4q", 16, 4, Vector2(px, c - 26), Vector2(0, 7), 2.2, 4.0)
			for i in int(4 * f + 3):
				luminoso.emitir("sonho_brilho_4q", 8, 4, Vector2(px + _rng.randf_range(-10, 10), c - _rng.randf_range(8, 30)),
					Vector2(_rng.randf_range(-2, 2), -3), _rng.randf_range(1.5, 3.0), 5.0, i)


func em_clarao() -> bool:
	return _clarao > 0.0


func avancar(delta: float, hora: float, estado: int, fogos: Array, clima: Dictionary, parado: bool) -> void:
	if parado:  # teste de fidelidade: só o que a montagem da arte tem
		_neblina.visible = false
		return
	_atualizar_neblina(hora, estado)
	_fogueiras(delta, estado, fogos)
	_vagalumes(estado)
	_chuva(delta, clima)
	if _clarao > 0.0:
		_clarao -= delta
	fosco.avancar(delta)
	luminoso.avancar(delta)
	_respingos()


## Força 0..1 da neblina pela hora: forte de madrugada, rala à noite.
static func forca_neblina(h: float) -> float:
	if h >= 4.0 and h < 6.0:
		return lerpf(0.25, 1.0, (h - 4.0) / 2.0)
	if h >= 6.0 and h < 8.5:
		return lerpf(1.0, 0.0, (h - 6.0) / 2.5)
	if h >= 21.0 or h < 4.0:
		return 0.25
	return 0.0


func _atualizar_neblina(hora: float, estado: int) -> void:
	_deriva += get_process_delta_time() * 1.5
	var forca := floorf(forca_neblina(hora) * 16.0) / 16.0
	var cor: Color = vista.cor_paleta(4 if estado == NOITE else (1 if estado == ENTARDECER else 0))
	var novo := [forca, floori(_deriva), cor]
	if novo == _neblina_estado:
		return
	_neblina_estado = novo
	_neblina.visible = forca > 0.0
	_mat_neblina.set_shader_parameter("forca", forca)
	_mat_neblina.set_shader_parameter("deriva", float(floori(_deriva)))
	_mat_neblina.set_shader_parameter("cor", Vector3(cor.r, cor.g, cor.b))


func _fogueiras(delta: float, estado: int, fogos: Array) -> void:
	_espera_fumaca -= delta
	_espera_faisca -= delta
	for f in fogos:
		var topo := Vector2(f.centro, f.canto.y + 4)
		if estado != NOITE and _espera_fumaca <= 0.0:
			fosco.emitir("fumaca_6q", 16, 6, topo + Vector2(_rng.randf_range(-2, 2), 0),
				Vector2(_rng.randf_range(1.0, 4.0), -7.0), 3.2)
		if estado == NOITE and _espera_faisca <= 0.0:
			luminoso.emitir("faisca", 1, 1, topo + Vector2(_rng.randf_range(-3, 3), 4),
				Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-22, -12)), _rng.randf_range(0.6, 1.4),
				0.0, _rng.randi_range(0, 1))
	if _espera_fumaca <= 0.0:
		_espera_fumaca = _rng.randf_range(1.8, 3.0)
	if _espera_faisca <= 0.0:
		_espera_faisca = _rng.randf_range(0.15, 0.45)


func _vagalumes(estado: int) -> void:
	if estado != NOITE:
		return
	var vivos := 0
	for p in luminoso.particulas:
		if p.folha == "vagalume_4q":
			vivos += 1
	if vivos < 5 and _rng.randf() < 0.05:
		var x := _rng.randf_range(150, 470)
		luminoso.emitir("vagalume_4q", 8, 4, Vector2(x, vista.chao(int(x)) - _rng.randf_range(4, 26)),
			Vector2(_rng.randf_range(-3, 3), _rng.randf_range(-1.5, 1.5)), _rng.randf_range(4.0, 8.0),
			4.0, _rng.randi_range(0, 3))


func _chuva(delta: float, clima: Dictionary) -> void:
	var faixa := forcar_chuva
	var tempestade: Dictionary = clima.get("tempestade", {})
	if faixa.x < 0 and not tempestade.is_empty():
		faixa = Vector2i(int(tempestade["x_ini"]), int(tempestade["x_fim"]))
	if _chuva_divina_resta > 0.0:
		_chuva_divina_resta -= delta
		if faixa.x < 0:
			faixa = _chuva_divina
	elif _chuva_divina.x >= 0:
		_chuva_divina = Vector2i(-1, -1)
	if faixa != _nuvens_em:
		fosco.limpar("nuvem_chuva_2q")
		_nuvens_em = faixa
		if faixa.x >= 0:
			for x in range(faixa.x + 20, faixa.y, 40):
				fosco.emitir("nuvem_chuva_2q", 48, 2, Vector2(x, _rng.randf_range(26, 34)), Vector2.ZERO,
					1e9, 1.5, _rng.randi_range(0, 1))
	if faixa.x < 0:
		return
	var n := int((faixa.y - faixa.x) * delta * 1.2 + _rng.randf())
	for i in n:
		fosco.emitir("gotas_3v", 4, 3, Vector2(_rng.randf_range(faixa.x, faixa.y), _rng.randf_range(30, 40)),
			Vector2(-8, 150), 2.0, 0.0, _rng.randi_range(0, 2))
	if forcar_raio or not tempestade.is_empty():
		_espera_raio -= delta
		if _espera_raio <= 0.0:
			_espera_raio = _rng.randf_range(3.0, 8.0)
			raio(_rng.randf_range(faixa.x + 10, faixa.y - 10))


## Raio no ponto x: o canal, o impacto no chão e o clarão no céu.
func raio(x: float) -> void:
	var chao: int = vista.chao(int(x))
	var folha: String = ["raio_a_2q", "raio_b_2q", "raio_c_2q"][_rng.randi_range(0, 2)]
	luminoso.emitir(folha, 32, 2, Vector2(x, chao), Vector2.ZERO, 0.35)
	luminoso.emitir("raio_impacto_4q", 16, 4, Vector2(x, chao + 2), Vector2.ZERO, 0.5)
	fosco.emitir("poeira_4q", 16, 4, Vector2(x, chao + 1), Vector2.ZERO, 0.6)
	_clarao = CLARAO


func _respingos() -> void:
	var tocou := []
	for p in fosco.particulas:
		if p.folha == "gotas_3v" and p.pos.y >= vista.chao(int(p.pos.x)):
			p.idade = p.vida
			tocou.append(p.pos)
	for pos in tocou:
		if _rng.randf() < 0.35:
			fosco.emitir("respingo_4q", 8, 4, Vector2(pos.x, vista.chao(int(pos.x)) + 1), Vector2.ZERO, 0.3)

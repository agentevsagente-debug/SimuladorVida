extends Node2D
## O céu vivo, desenhado sobre o degradê e atrás das montanhas: nuvens em 3
## camadas de profundidade, sol e lua em arco ligados ao relógio, a lua com
## fases, estrelas que surgem aos poucos, giram devagar e cintilam, e uma
## estrela cadente de vez em quando. As nuvens são as soltas da arte
## (arte/nuvens/, LEIA-ME seção 21), em 3 tamanhos por camada e um desenho
## por clima; as estrelas vêm de jogo/ferramentas/preparar_ceu.py; sol e lua
## são desenhados aqui. Tudo em pixel inteiro, e só pede desenho quando algum
## pixel muda. Usa um sorteio próprio, nunca o do núcleo.

const Arte = preload("res://apresentacao/arte.gd")

## camada -> [px por segundo, faixa de altura (topo da nuvem), quantas]
const CAMADAS := {"longe": [1.0 / 20.0, Vector2(4, 30), 4], "meio": [1.0 / 8.0, Vector2(10, 40), 3],
	"perto": [1.0 / 3.0, Vector2(16, 48), 2]}
const ORDEM := ["longe", "meio", "perto"]
const TAMANHOS := ["p", "m", "g"]
## As nuvens de uma camada andam juntas numa volta de 540 px (30 além de cada
## borda), cada uma na sua vaga: assim nunca se encavalam.
const VOLTA := 540.0
const CLIMAS := ["dia", "entardecer", "noite", "tempestade", "seca"]
const HORIZONTE := 104.0      # onde o sol e a lua nascem e se põem (atrás das montanhas)
const ALTURA_ARCO := 86.0
const PIVO_ESTRELAS := Vector2(240, 300)  # o céu gira em volta de um ponto abaixo do horizonte

var vista: Node2D
var clima := "dia"            # o desenho das nuvens: dia, entardecer, noite, tempestade ou seca
var _rng := RandomNumberGenerator.new()
var _tex_nuvem := {}          # "clima_camada_tamanho" -> Texture2D
var _estrelas: Array = []     # [{x, y, sx, w, h, brilho}] em ordem de brilho
var _tex_estrelas: Texture2D
var _nuvens: Array = []       # [{camada, t, pos (0..VOLTA), y, espelho}]
var _sol := {}                # estilo -> Texture2D
var _lua: Texture2D
var _fase_lua := -1
var _hora := 12.0
var _visiveis := 0            # quantas estrelas aparecem
var _giro := 0.0
var _cintilam := []
var _cadente := {}            # {pos, vel, vida}
var _espera_cadente := 30.0
var _dia := -1
var _vento := 1.0
var _assinatura := []
var _relogio := 0.0
var mostrar_sol := true       # no céu de seca e de eclipse, o sol já vem na arte


func criar(p_vista: Node2D) -> void:
	vista = p_vista
	_rng.randomize()
	_estrelas = Arte.json("ceu/estrelas.json")
	_estrelas.sort_custom(func(a, b): return a["brilho"] > b["brilho"])
	_tex_estrelas = ImageTexture.create_from_image(Arte.imagem("ceu/estrelas.png"))
	for i in 4:
		_cintilam.append(_rng.randi_range(10, _estrelas.size() - 1))
	_sol["dia"] = _fazer_sol(7, 31, 31, 0)
	_sol["entardecer"] = _fazer_sol(9, 31, 22, -1)


func _textura_nuvem(camada: String, t: String) -> Texture2D:
	var nome := "nuvem_%s_%s_%s" % [clima, camada, t]
	if not _tex_nuvem.has(nome):
		_tex_nuvem[nome] = ImageTexture.create_from_image(Arte.imagem("nuvens/%s.png" % nome))
	return _tex_nuvem[nome]


## Disco do sol, com borda e halo pontilhado (como na arte da sessão C).
func _fazer_sol(raio: int, miolo: int, borda: int, halo: int) -> Texture2D:
	var lado := (raio + 5) * 2 + 1
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var c := lado / 2
	for y in lado:
		for x in lado:
			var d := Vector2(x - c, y - c).length()
			if d <= raio - 2:
				img.set_pixel(x, y, Arte.paleta[miolo])
			elif d <= raio:
				img.set_pixel(x, y, Arte.paleta[borda])
			elif halo >= 0 and d <= raio + 4 and (x + y) % 2 == 0 and (x % 2 == 0 or d <= raio + 2):
				img.set_pixel(x, y, Arte.paleta[halo])
	return ImageTexture.create_from_image(img)


## A lua na fase f (0 nova, 0,5 cheia): disco claro com a parte de sombra recortada.
func _fazer_lua(f: float) -> Texture2D:
	var raio := 5
	var lado := (raio + 4) * 2 + 1
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var c := lado / 2
	# a sombra é um disco igual deslocado: de um lado na crescente, do outro na minguante
	var desloc := (1.0 - absf(f - 0.5) * 2.0) * (raio * 2.0 + 1.0)
	var lado_sombra := -1.0 if f < 0.5 else 1.0
	for y in lado:
		for x in lado:
			var d := Vector2(x - c, y - c).length()
			var ds := Vector2(x - c - lado_sombra * desloc, y - c).length()
			if d <= raio and ds > raio:
				img.set_pixel(x, y, Arte.paleta[31] if d <= raio - 1 else Arte.paleta[12])
			elif d <= raio + 3 and d > raio and (x + y) % 2 == 0 and x % 2 == 0 and f > 0.15 and f < 0.85:
				img.set_pixel(x, y, Arte.paleta[4])  # halo pontilhado, ralo
	return ImageTexture.create_from_image(img)


## Nuvens espalhadas pelo céu, com tamanhos, alturas e lados sorteados. Cada
## uma fica numa vaga da volta da sua camada, com folga para a vizinha. Os
## tamanhos são os mesmos em todos os climas, então a troca de clima só troca
## o desenho, sem mexer nas nuvens.
func _espalhar_nuvens() -> void:
	_nuvens.clear()
	for camada in ORDEM:
		var regra: Array = CAMADAS[camada]
		var vaga: float = VOLTA / regra[2]
		var inicio := _rng.randf_range(0.0, vaga)
		for k in regra[2]:
			var t: String = TAMANHOS[_rng.randi_range(0, 2)]
			var largura := _textura_nuvem(camada, t).get_width()
			var folga := maxf(0.0, vaga - largura - 6.0)
			_nuvens.append({"camada": camada, "t": t, "pos": fposmod(inicio + k * vaga + _rng.randf_range(0.0, folga), VOLTA),
				"y": _rng.randf_range(regra[1].x, regra[1].y), "espelho": _rng.randf() < 0.5})


## `p_clima`: dia, entardecer ou noite pelo horário, ou tempestade e seca.
func avancar(delta: float, hora: float, p_clima: String, dia: int, tempestade: bool) -> void:
	_relogio += delta
	_hora = hora
	clima = p_clima if p_clima in CLIMAS else "dia"
	if _nuvens.is_empty():
		_espalhar_nuvens()
	if dia != _dia:  # o vento muda de direção de um dia para outro
		_dia = dia
		_vento = 1.0 if hash(dia) % 2 == 0 else -1.0
		_fase_lua = -1
	var forca := 4.0 if tempestade else 1.0
	for n in _nuvens:
		n.pos = fposmod(n.pos + CAMADAS[n.camada][0] * _vento * forca * delta, VOLTA)
	# estrelas: surgem aos poucos ao anoitecer (as mais fortes primeiro) e somem de madrugada
	var noite := 0.0
	if hora >= 19.0:
		noite = clampf((hora - 19.0) / 2.0, 0.0, 1.0)
	elif hora < 6.0:
		noite = clampf((5.5 - hora) / 1.0, 0.0, 1.0)
	_visiveis = int(noite * _estrelas.size())
	# o céu gira devagar ao longo da noite (cerca de 6 graus de 19h a 6h)
	var h := hora if hora >= 12.0 else hora + 24.0
	_giro = deg_to_rad(clampf(h - 19.0, 0.0, 11.0) * 0.55)
	# estrela cadente de vez em quando
	if noite >= 1.0:
		_espera_cadente -= delta
		if _espera_cadente <= 0.0:
			_espera_cadente = _rng.randf_range(40.0, 120.0)
			_cadente = {"pos": Vector2(_rng.randf_range(80, 420), _rng.randf_range(6, 30)),
				"vel": Vector2(_rng.randf_range(-90, -60) * (1 if _rng.randf() < 0.5 else -1), 30), "vida": 0.6}
	if not _cadente.is_empty():
		_cadente.vida -= delta
		_cadente.pos += _cadente.vel * delta
		if _cadente.vida <= 0.0:
			_cadente = {}
	var fase := float((dia - 1) % 10) / 10.0
	if int(fase * 10) != _fase_lua:
		_fase_lua = int(fase * 10)
		_lua = _fazer_lua(fase)
	var assinatura := [clima, _visiveis, snappedf(_giro, 0.004), int(_relogio * 1.5), mostrar_sol, _fase_lua]
	for n in _nuvens:
		assinatura.append(floori(n.pos))
	assinatura.append(_posicao_astro(hora, 6.0))
	assinatura.append(_posicao_astro(hora, 18.0))
	if not _cadente.is_empty():
		assinatura.append(Vector2i(_cadente.pos))
	if assinatura != _assinatura:
		_assinatura = assinatura
		queue_redraw()


## Onde está, em pixel inteiro, o astro que nasce na hora `nasce` e se põe 12 h depois.
func _posicao_astro(hora: float, nasce: float) -> Vector2i:
	var t := fposmod(hora - nasce, 24.0) / 12.0
	if t > 1.0:
		return Vector2i(-100, -100)
	return Vector2i(roundi(t * 480.0), roundi(HORIZONTE - sin(PI * t) * ALTURA_ARCO))


func _draw() -> void:
	# estrelas, girando em volta de um ponto abaixo do horizonte; umas poucas cintilam
	for k in _visiveis:
		if k in _cintilam and (int(_relogio * 1.5) + k) % 5 == 0:
			continue
		var e: Dictionary = _estrelas[k]
		var p := (Vector2(e["x"], e["y"]) - PIVO_ESTRELAS).rotated(_giro) + PIVO_ESTRELAS
		draw_texture_rect_region(_tex_estrelas, Rect2(p.round(), Vector2(e["w"], e["h"])),
			Rect2(e["sx"], 0, e["w"], e["h"]))
	if not _cadente.is_empty():
		var p: Vector2 = _cadente.pos.round()
		var dir: Vector2 = -_cadente.vel.normalized()
		for i in 6:
			draw_rect(Rect2((p + dir * i).round(), Vector2.ONE), Arte.paleta[31 if i < 2 else 0])
	# a lua faz o arco da noite; o sol, o do dia
	var lua := _posicao_astro(_hora, 18.0)
	if lua.x > -50 and _lua:
		draw_texture(_lua, Vector2(lua) - _lua.get_size() / 2)
	var sol := _posicao_astro(_hora, 6.0)
	if sol.x > -50 and mostrar_sol:
		var tex: Texture2D = _sol["entardecer" if (_hora < 8.0 or _hora > 16.0) else "dia"]
		draw_texture(tex, Vector2(sol) - tex.get_size() / 2)
	# nuvens: longe primeiro, perto por cima
	for camada in ORDEM:
		for n in _nuvens:
			if n.camada != camada:
				continue
			var tex := _textura_nuvem(camada, n.t)
			var pos := Vector2(floori(n.pos) - 30, floori(n.y))
			if n.espelho:
				draw_set_transform(pos + Vector2(tex.get_width(), 0), 0.0, Vector2(-1, 1))
				draw_texture(tex, Vector2.ZERO)
				draw_set_transform(Vector2.ZERO)
			else:
				draw_texture(tex, pos)

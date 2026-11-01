extends Node2D
## Conteúdo de teste da moldura: céu com ciclo de dia e noite, chão,
## 30 bonecos andando e chuva ao clicar no céu.
##
## Tudo é desenhado por código na resolução base (480 × 160). A lógica roda
## em passos fixos e só pede um novo desenho quando algo mudou de fato,
## para o modo de baixo consumo do Godot pular os quadros iguais.

const LARGURA := 480
const ALTURA := 160
const CHAO := 136  # y do topo do chão
const DIA_SEGUNDOS := 120.0  # um dia inteiro a cada 2 minutos
const PASSO_LOGICA := 1.0 / 12.0  # bonecos andam em passos de 1 pixel a 12 Hz
const PASSO_CEU := 0.5  # o céu é recalculado 2 vezes por segundo
const FAIXA_CEU := 8  # o gradiente do céu é feito em faixas de 8 pixels
const NUM_BONECOS := 30
const DURACAO_CHUVA := 2.5

## Cores do céu ao longo do dia: [fase, topo, horizonte].
const CICLO_CEU := [
	[0.00, Color8(10, 12, 40), Color8(30, 30, 70)],  # meia-noite
	[0.22, Color8(20, 24, 70), Color8(70, 50, 90)],
	[0.28, Color8(60, 80, 150), Color8(240, 140, 80)],  # amanhecer
	[0.36, Color8(70, 140, 220), Color8(170, 210, 240)],  # dia
	[0.64, Color8(70, 140, 220), Color8(170, 210, 240)],
	[0.72, Color8(70, 60, 140), Color8(240, 110, 70)],  # entardecer
	[0.80, Color8(20, 24, 70), Color8(60, 40, 90)],
	[1.00, Color8(10, 12, 40), Color8(30, 30, 70)],
]

const CORES_ROUPA := [
	Color8(180, 60, 50), Color8(60, 100, 170), Color8(200, 170, 60),
	Color8(80, 140, 70), Color8(140, 80, 150), Color8(220, 220, 210),
]
const CORES_PELE := [Color8(240, 200, 160), Color8(200, 150, 110), Color8(140, 95, 60)]

var andando := true
var tempo := 0.0  # tempo de mundo, em segundos
var _acumulado_logica := 0.0
var _acumulado_ceu := 0.0
var _faixas_ceu := PackedColorArray()
var _bonecos: Array[Dictionary] = []
var _nuvens: Array[Dictionary] = []  # {x, y, resta}
var _gotas := PackedVector2Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2026
	for i in NUM_BONECOS:
		var passo := _rng.randi_range(1, 3)
		_bonecos.append({
			"x": _rng.randi_range(0, LARGURA - 8),
			"dir": 1 if _rng.randf() < 0.5 else -1,
			"passo": passo,
			"conta": passo,
			"quadro": 0,
			"roupa": CORES_ROUPA[i % CORES_ROUPA.size()],
			"pele": CORES_PELE[i % CORES_PELE.size()],
		})
	_atualizar_ceu()


## Avança o mundo. Chamado pela moldura mesmo com ela escondida, porque o
## mundo não para enquanto a moldura está aberta.
func avancar(delta: float, desenhar: bool) -> void:
	tempo += delta
	var mudou := false

	_acumulado_logica += delta
	while _acumulado_logica >= PASSO_LOGICA:
		_acumulado_logica -= PASSO_LOGICA
		if andando and _passo_bonecos():
			mudou = true

	_acumulado_ceu += delta
	if _acumulado_ceu >= PASSO_CEU:
		_acumulado_ceu = fmod(_acumulado_ceu, PASSO_CEU)
		if _atualizar_ceu():
			mudou = true

	if not _nuvens.is_empty() or not _gotas.is_empty():
		_passo_chuva(delta)
		mudou = true

	if mudou and desenhar:
		queue_redraw()


func chover(ponto: Vector2) -> void:
	_nuvens.append({"x": clampi(int(ponto.x) - 12, 0, LARGURA - 24), "y": clampi(int(ponto.y) - 4, 2, CHAO - 20), "resta": DURACAO_CHUVA})
	queue_redraw()


func _passo_bonecos() -> bool:
	var mudou := false
	for b in _bonecos:
		b.conta -= 1
		if b.conta > 0:
			continue
		b.conta = b.passo
		if _rng.randf() < 0.01:
			b.dir = -b.dir
		b.x += b.dir
		if b.x <= 0 or b.x >= LARGURA - 8:
			b.x = clampi(b.x, 0, LARGURA - 8)
			b.dir = -b.dir
		b.quadro = 1 - b.quadro
		mudou = true
	return mudou


func _passo_chuva(delta: float) -> void:
	for n in _nuvens:
		n.resta -= delta
		for i in 3:
			_gotas.append(Vector2(n.x + 2 + _rng.randi_range(0, 19), n.y + 8))
	_nuvens = _nuvens.filter(func(n): return n.resta > 0.0)

	var vivas := PackedVector2Array()
	for g in _gotas:
		g.y += 120.0 * delta
		if g.y < CHAO:
			vivas.append(g)
	_gotas = vivas


## Recalcula as faixas do céu. As cores são quantizadas para a paleta não
## mudar a cada passo; só devolve true quando alguma faixa mudou de cor.
func _atualizar_ceu() -> bool:
	var fase := fmod(tempo / DIA_SEGUNDOS, 1.0)
	var topo := Color.BLACK
	var horizonte := Color.BLACK
	for i in CICLO_CEU.size() - 1:
		var a = CICLO_CEU[i]
		var b = CICLO_CEU[i + 1]
		if fase >= a[0] and fase <= b[0]:
			var t: float = (fase - a[0]) / (b[0] - a[0])
			topo = a[1].lerp(b[1], t)
			horizonte = a[2].lerp(b[2], t)
			break

	var num_faixas := ceili(float(CHAO) / FAIXA_CEU)
	var novas := PackedColorArray()
	for i in num_faixas:
		novas.append(_quantizar(topo.lerp(horizonte, float(i) / (num_faixas - 1))))
	if novas == _faixas_ceu:
		return false
	_faixas_ceu = novas
	return true


func _quantizar(c: Color) -> Color:
	return Color8(int(c.r8 / 16) * 16, int(c.g8 / 16) * 16, int(c.b8 / 16) * 16)


func _draw() -> void:
	for i in _faixas_ceu.size():
		var y := i * FAIXA_CEU
		draw_rect(Rect2(0, y, LARGURA, mini(FAIXA_CEU, CHAO - y)), _faixas_ceu[i])

	draw_rect(Rect2(0, CHAO, LARGURA, ALTURA - CHAO), Color8(110, 75, 45))
	draw_rect(Rect2(0, CHAO, LARGURA, 3), Color8(80, 140, 60))

	for b in _bonecos:
		var x: int = b.x
		var pe := CHAO
		draw_rect(Rect2(x + 2, pe - 12, 4, 4), b.pele)  # cabeça
		draw_rect(Rect2(x + 1, pe - 8, 6, 5), b.roupa)  # corpo
		if b.quadro == 0:  # pernas
			draw_rect(Rect2(x + 2, pe - 3, 1, 3), Color8(50, 40, 40))
			draw_rect(Rect2(x + 5, pe - 3, 1, 3), Color8(50, 40, 40))
		else:
			draw_rect(Rect2(x + 3, pe - 3, 2, 3), Color8(50, 40, 40))

	for n in _nuvens:
		draw_rect(Rect2(n.x, n.y + 2, 24, 6), Color8(150, 150, 160))
		draw_rect(Rect2(n.x + 5, n.y, 12, 4), Color8(170, 170, 180))
	for g in _gotas:
		draw_rect(Rect2(int(g.x), int(g.y), 1, 3), Color8(150, 190, 240))

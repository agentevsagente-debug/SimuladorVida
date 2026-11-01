extends Node
## Dono do mundo do núcleo na apresentação: faz o tempo andar e guarda uma
## foto do estado legível a cada passo (a API recomenda consultar uma vez por
## passo). Só usa a API de jogo/nucleo/API.md; nunca toca no sorteio do núcleo.

signal passo_dado
signal construcoes_mudaram

const Mundo = preload("res://nucleo/mundo.gd")
const SEGUNDOS_POR_PASSO := 1.9  # ritmo normal: 1 hora de jogo

var mundo: Mundo
var congelado := false
var tempo := {}
var clima := {}
var pessoas: Array = []
var construcoes: Array = []
var _acumulado := 0.0


func iniciar(semente: int, hora_inicial: int = -1) -> void:
	mundo = Mundo.new(semente)
	if hora_inicial >= 0:
		while mundo.tempo()["hora"] != hora_inicial:
			mundo.avancar_hora()
	_ler()


func avancar(delta: float) -> void:
	if mundo == null or congelado:
		return
	_acumulado += delta
	while _acumulado >= SEGUNDOS_POR_PASSO:
		_acumulado -= SEGUNDOS_POR_PASSO
		mundo.avancar_hora()
		_ler()


## Quanto do passo atual já passou (0..1), para interpolar movimentos e o céu.
func fracao() -> float:
	return 0.0 if congelado else clampf(_acumulado / SEGUNDOS_POR_PASSO, 0.0, 1.0)


func hora_continua() -> float:
	return float(tempo.get("hora", 12)) + fracao()


func _ler() -> void:
	tempo = mundo.tempo()
	clima = mundo.clima()
	pessoas = mundo.pessoas_visiveis()
	var novas: Array = mundo.construcoes()
	if novas != construcoes:
		construcoes = novas
		construcoes_mudaram.emit()
	passo_dado.emit()

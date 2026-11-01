extends Node
## Dono do mundo do núcleo na apresentação: faz o tempo andar no ritmo
## escolhido, salva e carrega, e guarda uma foto do estado legível a cada passo
## (a API recomenda consultar uma vez por passo). Só usa a API de
## jogo/nucleo/API.md; nunca toca no sorteio do núcleo.

signal passo_dado
signal construcoes_mudaram
signal zonas_mudaram
signal eventos_novos(eventos: Array)

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")

enum Ritmo { PAUSA, NORMAL, RAPIDO }
## Segundos reais por passo (1 hora de jogo) em cada ritmo.
const SEGUNDOS := {Ritmo.PAUSA: INF, Ritmo.NORMAL: Mundo.SEGUNDOS_POR_PASSO, Ritmo.RAPIDO: 1.9}
const PASSOS_POR_DIA := 24
## O salto procura o próximo acontecimento até este limite (um ano de jogo).
const SALTO_MAXIMO := 960

var mundo: Mundo
var ritmo := Ritmo.NORMAL
var congelado := false   # testes: o tempo não anda
var salvar_em_disco := true
var tempo := {}
var clima := {}
var pessoas: Array = []
var construcoes: Array = []
var zonas: Array = []
var preces: Array = []
var ausencia := {}       # retorno de avancar_ausencia() ao abrir, se houve
var _acumulado := 0.0
var _vistos := 0
var _ultimo_dia_salvo := -1
var _chave_zonas := []


## Carrega o mundo salvo (avançando a ausência) ou cria um novo.
func iniciar(semente: int, hora_inicial: int = -1, carregar := true) -> void:
	if carregar and Persistencia.existe():
		var r = Persistencia.carregar_e_avancar()
		if r != null:
			mundo = r["mundo"]
			ausencia = r["ausencia"]
	if mundo == null:
		mundo = Mundo.new(semente)
		if hora_inicial >= 0:
			while mundo.tempo()["hora"] != hora_inicial:
				mundo.avancar_hora()
	_vistos = mundo.eventos.size()
	_ultimo_dia_salvo = mundo.dia_abs()
	_ler(true)


## Recomeça a leitura depois de o mundo ter sido avançado por fora (testes).
func iniciar_de_mundo() -> void:
	_vistos = mundo.eventos.size()
	_ultimo_dia_salvo = mundo.dia_abs()
	_ler(true)


func avancar(delta: float) -> void:
	if mundo == null or congelado or ritmo == Ritmo.PAUSA:
		return
	_acumulado += delta
	var s: float = SEGUNDOS[ritmo]
	while _acumulado >= s:
		_acumulado -= s
		_passo()


## Quanto do passo atual já passou (0..1), para o céu andar entre as horas.
func fracao() -> float:
	if congelado or ritmo == Ritmo.PAUSA:
		return 0.0
	return clampf(_acumulado / SEGUNDOS[ritmo], 0.0, 1.0)


func hora_continua() -> float:
	return float(tempo.get("hora", 12)) + fracao()


func definir_ritmo(novo: int) -> void:
	ritmo = novo
	_acumulado = 0.0


## Avança até o próximo acontecimento de camada "nota" ou "chamado".
func saltar() -> Array:
	for i in SALTO_MAXIMO:
		mundo.avancar_hora()
		var novos: Array = mundo.eventos_desde(_vistos)
		for ev in novos:
			if ev["camada"] != "ambiente":
				_acumulado = 0.0
				_ler()
				return novos
	_ler()
	return []


func usar_poder(poder: String, x: float, intensidade: float) -> Dictionary:
	var r: Dictionary = mundo.usar_poder(poder, x, intensidade)
	_ler()
	return r


func salvar() -> void:
	if salvar_em_disco and mundo != null:
		Persistencia.salvar(mundo)


func _passo() -> void:
	mundo.avancar_hora()
	_ler()
	# o documento técnico pede salvar a cada dia de jogo e ao fechar
	if mundo.dia_abs() != _ultimo_dia_salvo:
		_ultimo_dia_salvo = mundo.dia_abs()
		salvar()


func _ler(inicio := false) -> void:
	tempo = mundo.tempo()
	clima = mundo.clima()
	pessoas = mundo.pessoas_visiveis()
	preces = mundo.preces_abertas()
	var novas: Array = mundo.construcoes()
	if inicio or novas != construcoes:
		construcoes = novas
		construcoes_mudaram.emit()
	zonas = mundo.zonas_visiveis()
	# só o que muda o desenho fixo: cinzas, pedra erguida, seca
	var chave := zonas.map(func(z): return [z["chave"], z["queimada"], z["pedra_erguida"], z["pedra_x"], z["seca"]])
	if inicio or chave != _chave_zonas:
		_chave_zonas = chave
		zonas_mudaram.emit()
	var eventos: Array = mundo.eventos_desde(_vistos)
	_vistos = mundo.eventos.size()
	if not eventos.is_empty() and not inicio:
		eventos_novos.emit(eventos)
	passo_dado.emit()

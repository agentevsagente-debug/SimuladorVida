extends Node
## Dono do mundo do núcleo na apresentação: faz o tempo andar no ritmo
## escolhido, salva e carrega, e guarda uma foto do estado legível a cada passo
## (a API recomenda consultar uma vez por passo). Só usa a API de
## jogo/nucleo/API.md; nunca toca no sorteio do núcleo.

signal passo_dado
signal construcoes_mudaram
signal zonas_mudaram
signal eventos_novos(eventos: Array)
signal mundo_trocado

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Estante = preload("res://nucleo/estante.gd")
const Obras = preload("res://apresentacao/obras.gd")
## Os mundos de teste (que não salvam) guardam os livros numa estante à parte.
const ESTANTE_TESTE := "user://estante_teste"

## RAPIDO é o 10x e MUITO_RAPIDO o 50x (documento funcional: velocidades 1x, 10x e 50x).
enum Ritmo { PAUSA, NORMAL, RAPIDO, MUITO_RAPIDO }
## Segundos reais por passo (1 hora de jogo) em cada ritmo.
const SEGUNDOS := {Ritmo.PAUSA: INF, Ritmo.NORMAL: Mundo.SEGUNDOS_POR_PASSO,
	Ritmo.RAPIDO: Mundo.SEGUNDOS_POR_PASSO / 10.0, Ritmo.MUITO_RAPIDO: Mundo.SEGUNDOS_POR_PASSO / 50.0}
## Nome do ritmo na alça, na linha de comando e no moldura.cfg.
const NOME_RITMO := {Ritmo.PAUSA: "pausa", Ritmo.NORMAL: "normal", Ritmo.RAPIDO: "rapido",
	Ritmo.MUITO_RAPIDO: "rapido2"}
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
var ruinas: Array = []
var grupos: Array = []
var cenas: Array = []    # cenas_ativas() da hora: caça, incidentes, festas...
var zonas: Array = []
var preces: Array = []
var ausencia := {}       # retorno de avancar_ausencia() ao abrir, se houve
var salvamento_falhou := false  # o último salvamento não foi ao disco (disco cheio?): a moldura avisa
var _acumulado := 0.0
var _fracao_parada := 0.0  # a fração da hora em que a pausa começou
var _vistos := 0
var _ultimo_dia_salvo := -1
var _chave_zonas := []
var _chave_ruinas := []


## Carrega o mundo salvo (avançando a ausência) ou cria um novo.
## com_povo: o mundo novo já nasce com o primeiro povo (testes e cenários); sem ele,
## nasce vazio, às 7h, e o primeiro gesto do jogador é criar o povo (QA, D-09).
func iniciar(semente: int, hora_inicial: int = -1, carregar := true, com_povo := false) -> void:
	if carregar and Persistencia.existe():
		var r = Persistencia.carregar_e_avancar()
		if r != null:
			mundo = r["mundo"]
			ausencia = r["ausencia"]
	if mundo == null:
		mundo = novo_mundo(semente, com_povo)
		if hora_inicial >= 0:
			while mundo.tempo()["hora"] != hora_inicial:
				mundo.avancar_hora()
	_vistos = mundo.eventos.size()
	_ultimo_dia_salvo = mundo.dia_abs()
	_ler(true)
	print("[simulacao] %s ano=%d dia=%d hora=%d passo=%d ausencia=%d passos" % ["carregado" if not ausencia.is_empty() else "novo",
		tempo["ano"], tempo["dia"], tempo["hora"], tempo["passo"], int(ausencia.get("passos", 0))])


## Mundo.new(semente, [], HORA_INICIAL, com_povo): o núcleo de antes (sem o 4º
## parâmetro) sempre nasce com o povo. callv para não depender da versão ao compilar.
static func novo_mundo(semente: int, com_povo := false) -> Mundo:
	var script: Script = Mundo
	for m in script.get_script_method_list():
		if m["name"] == "_init" and m["args"].size() >= 4:
			return script.callv("new", [semente, [], Mundo.HORA_INICIAL, com_povo])
	return Mundo.new(semente)


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
	if congelado:
		return 0.0
	if ritmo == Ritmo.PAUSA:
		return _fracao_parada
	return clampf(_acumulado / SEGUNDOS[ritmo], 0.0, 1.0)


func hora_continua() -> float:
	return float(tempo.get("hora", 12)) + fracao()


## Troca o ritmo sem pular a hora: a fração já passada da hora continua a mesma.
func definir_ritmo(novo: int) -> void:
	var f := fracao()
	ritmo = novo
	_fracao_parada = f
	_acumulado = 0.0 if novo == Ritmo.PAUSA else f * SEGUNDOS[novo]


## Avança até o próximo acontecimento de camada "nota" ou "chamado".
func saltar() -> Array:
	for i in SALTO_MAXIMO:
		mundo.avancar_hora()
		var novos: Array = mundo.eventos_desde(_vistos)
		for ev in novos:
			if ev["camada"] != "ambiente":
				_acumulado = 0.0
				_fracao_parada = 0.0
				_ler()
				return novos
	_ler()
	return []


## alvo: o id de quem está sob o cursor; minuto: o minuto da hora na tela. Com eles,
## o raio, o sonho e a cura acertam quem o jogador vê, e não onde ele estará (QA, D-02).
func usar_poder(poder: String, x: float, intensidade: float, alvo := -1, minuto := -1.0) -> Dictionary:
	var r: Dictionary
	if mundo.get_method_argument_count("usar_poder") >= 5:
		r = mundo.callv("usar_poder", [poder, x, intensidade, alvo, minuto])
	else:
		r = mundo.usar_poder(poder, x, intensidade)
	_ler()
	return r


## Só com o mundo vazio: o povo novo nasce na zona de x e começa outra era.
func criar_povo(x: float) -> Dictionary:
	var r: Dictionary = mundo.criar_povo(x)
	_ler()
	return r


## Fecha a crônica da era como livro, guarda na estante e começa outro mundo.
func abandonar() -> Dictionary:
	var livro: Dictionary
	if salvar_em_disco:
		livro = Persistencia.abandonar(mundo)
	else:
		livro = mundo.abandonar()
		for l in mundo.livros:
			if not l["na_estante"]:
				Estante.guardar(l, ESTANTE_TESTE)
				l["na_estante"] = true
	print("[simulacao] mundo abandonado: %s, anos %d a %d" % [livro.get("titulo", "?"), livro.get("ano_ini", 0),
		livro.get("ano_fim", 0)])
	mundo = novo_mundo(randi())
	ausencia = {}
	_acumulado = 0.0
	_fracao_parada = 0.0
	iniciar_de_mundo()
	salvar()
	mundo_trocado.emit()
	return livro


func pasta_estante() -> String:
	return Estante.PASTA_PADRAO if salvar_em_disco else ESTANTE_TESTE


## A aparência do povo (parede, telhado, símbolo, roupa), ou {}.
func aparencia(grupo_id: int) -> Dictionary:
	for g in grupos:
		if g["id"] == grupo_id:
			return g.get("aparencia", {})
	return {}


## Salva agora, na linha principal (ao fechar e ao abandonar).
func salvar() -> void:
	if salvar_em_disco and mundo != null:
		var ok: bool = Persistencia.salvar(mundo)
		salvamento_falhou = not ok  # o mundo salvo de antes fica intacto
		print("[simulacao] salvo=%s ano=%d dia=%d hora=%d passo=%d" % [ok, tempo["ano"], tempo["dia"], tempo["hora"], tempo["passo"]])


## Antes de o jogo fechar: espera as threads do núcleo (a montagem da rotina, a
## rotina velha sendo desmontada e o salvamento em segundo plano). Fechar com uma
## delas rodando derrubava o jogo (falha de segmentação ao sair).
func encerrar() -> void:
	if mundo == null:
		return
	congelado = true  # nenhum passo novo (que lançaria outra montagem) até o jogo sair
	if mundo.has_method("encerrar"):  # o núcleo espera as próprias threads (A, ece2046)
		mundo.encerrar()
	else:
		mundo._esperar_threads()
		for d in mundo._descartes:
			WorkerThreadPool.wait_for_task_completion(d[0])
		mundo._descartes.clear()
	print("[simulacao] threads encerradas")


## Salva numa thread, sem travar o jogo (o salvamento de cada dia).
func salvar_async() -> void:
	if salvar_em_disco and mundo != null:
		Persistencia.salvar_async(mundo)
		print("[simulacao] salvando em segundo plano: ano=%d dia=%d" % [tempo["ano"], tempo["dia"]])


func _passo() -> void:
	mundo.avancar_hora()
	_ler()
	# o documento técnico pede salvar a cada dia de jogo e ao fechar
	if mundo.dia_abs() != _ultimo_dia_salvo:
		_ultimo_dia_salvo = mundo.dia_abs()
		if mundo.get("ultimo_salvamento_ok") == false:  # o salvamento de ontem não foi ao disco
			salvamento_falhou = true
		salvar_async()


func _ler(inicio := false) -> void:
	tempo = mundo.tempo()
	clima = mundo.clima()
	grupos = mundo.grupos_visiveis()
	pessoas = mundo.pessoas_visiveis()
	cenas = mundo.cenas_ativas()
	preces = mundo.preces_abertas()
	var novas: Array = mundo.construcoes()
	var novas_ruinas: Array = mundo.ruinas_visiveis()
	# as ruínas mudam de desenho quando o mato cresce
	var chave_ruinas := novas_ruinas.map(func(o): return [o["x"], Obras.grau_natureza(int(o["anos"]))])
	if inicio or novas != construcoes or chave_ruinas != _chave_ruinas:
		construcoes = novas
		ruinas = novas_ruinas
		_chave_ruinas = chave_ruinas
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

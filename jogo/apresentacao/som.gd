extends Node
## O som (versão 0.2; documento funcional, "O som"): discreto, como o de uma janela
## aberta para fora. Quatro barramentos (Master, Ambiente, Acontecimentos e Interface),
## criados aqui ao abrir.
##
## O silêncio vem antes de tudo: `ligado` (o botão da alça e a tecla M) e `escondida`
## (a janela escondida ou minimizada) calam o Master na hora, sem fade.
##
## Os sons vêm da C (arte_claude/sons/, copiados para res://sons/). Enquanto um som
## não existe, ele simplesmente não toca: a estrutura toda funciona em silêncio.
##   res://sons/ambiente/<laço>.ogg         laços longos, tocados em streaming
##   res://sons/acontecimentos/<nome>.ogg   sons curtos dos eventos e dos gestos
##   res://sons/interface/<nome>.ogg        cliques da alça

const PASTA := "res://sons/"
const VOLUME_INICIAL := 0.4      # o volume começa baixo
const VOZES_MAX := 4             # acontecimentos tocando ao mesmo tempo, no máximo
const PASSO_AMBIENTE := 0.25     # s entre os ajustes dos laços (o cruzamento é lento)
const CRUZA := 0.35              # quanto do caminho até o volume-alvo cada ajuste anda
const MUDO_DB := -60.0

## Os laços do ambiente e quando soam: o volume-alvo (0 a 1) de cada um, a partir
## da hora, do clima, da estação e do tamanho da vila (veja _alvos_do_ambiente).
const LACOS := ["vento", "passaros", "agua", "grilos", "coruja", "fogo", "chuva", "tempestade", "neve", "vila"]
## Evento do núcleo ou gesto -> som. Os pesados não tocam no modo discreto.
const ACONTECIMENTOS := {"raio": "trovao", "terremoto": "terremoto", "fogo": "fogo_forte",
	"diluvio": "diluvio", "chuva": "chuva_comeca", "milagre": "sino", "cacada": "cacada",
	"arremesso": "arremesso", "nascimento": "choro_longe", "fartura": "sino", "sonho": "sino"}
const PESADOS := ["terremoto", "diluvio", "fogo_forte", "cacada"]

var ligado := true
var escondida := false
var volume := VOLUME_INICIAL
var discreto := false

var _lacos := {}      # laço -> AudioStreamPlayer (só os que têm arquivo)
var _alvos := {}      # laço -> volume-alvo (0 a 1)
var _vozes: Array = []
var _cache := {}
var _espera := 0.0
var _vista: Node2D


func criar(vista: Node2D) -> void:
	_vista = vista
	for nome in ["Ambiente", "Acontecimentos", "Interface"]:
		if AudioServer.get_bus_index(nome) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")
	for laco in LACOS:
		var s := _carregar("ambiente/" + laco)
		if s == null:
			continue
		if s is AudioStreamOggVorbis:
			s.loop = true
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = "Ambiente"
		p.volume_db = MUDO_DB
		add_child(p)
		_lacos[laco] = p
		_alvos[laco] = 0.0
	for i in VOZES_MAX:
		var v := AudioStreamPlayer2D.new()
		v.bus = "Acontecimentos"
		v.attenuation = 0.0     # o pan vem só do x na tela, sem cair com a distância
		v.max_distance = 100000.0
		vista.add_child(v)
		_vozes.append(v)
	_aplicar_master()


## O botão da alça e a tecla M. Muda na hora.
func definir_ligado(sim_: bool) -> void:
	ligado = sim_
	_aplicar_master()


## A janela escondida ou minimizada (H, o botão, o Ctrl+Alt+H, a bandeja) cala tudo na hora.
func definir_escondida(sim_: bool) -> void:
	escondida = sim_
	_aplicar_master()


func _aplicar_master() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, not ligado or escondida)
	# calado, os laços param de tocar: nada para misturar, nada para gastar
	var tocar := ligado and not escondida
	for laco in _lacos:
		var p: AudioStreamPlayer = _lacos[laco]
		if tocar and _alvos[laco] > 0.0 and not p.playing:
			p.play()
		elif not tocar and p.playing:
			p.stop()


func calado() -> bool:
	return not ligado or escondida


## Chamado a cada quadro pela moldura: ajusta os laços devagar.
func avancar(delta: float, estado: Dictionary) -> void:
	if calado() or _lacos.is_empty():
		return
	_espera -= delta
	if _espera > 0.0:
		return
	_espera = PASSO_AMBIENTE
	var alvos := _alvos_do_ambiente(estado)
	for laco in _lacos:
		var p: AudioStreamPlayer = _lacos[laco]
		var alvo: float = alvos.get(laco, 0.0)
		_alvos[laco] = alvo
		var atual := db_to_linear(p.volume_db) if p.volume_db > MUDO_DB else 0.0
		var novo := lerpf(atual, alvo, CRUZA)
		if absf(novo - alvo) < 0.01:
			novo = alvo
		p.volume_db = linear_to_db(novo) if novo > 0.001 else MUDO_DB
		if novo > 0.001 and not p.playing:
			p.play()
		elif novo <= 0.001 and p.playing:
			p.stop()


## estado: {hora: float, clima: String ("", "chuva", "tempestade", "neve", "seca"),
## estacao: String, pessoas: int (na vila visível), fogos: int}
func _alvos_do_ambiente(estado: Dictionary) -> Dictionary:
	var h: float = estado.get("hora", 12.0)
	var noite: bool = h < 5.5 or h >= 19.5
	var clima: String = estado.get("clima", "")
	var inverno: bool = estado.get("estacao", "") == "inverno"
	var gente: float = clampf(float(estado.get("pessoas", 0)) / 40.0, 0.0, 1.0)
	var chovendo: bool = clima in ["chuva", "tempestade"]
	var a := {}
	a["vento"] = 0.35 if not chovendo else 0.2
	a["agua"] = 0.3
	a["passaros"] = 0.0 if noite or chovendo or inverno else 0.45
	a["grilos"] = 0.4 if noite and not inverno and not chovendo else 0.0
	a["coruja"] = 0.25 if noite and not chovendo else 0.0
	a["fogo"] = 0.3 if noite and int(estado.get("fogos", 0)) > 0 else 0.0
	a["chuva"] = 0.5 if clima == "chuva" else 0.0
	a["tempestade"] = 0.6 if clima == "tempestade" else 0.0
	a["neve"] = 0.3 if clima == "neve" else 0.0
	a["vila"] = 0.0 if noite else 0.15 + 0.35 * gente
	return a


## Um acontecimento (evento do núcleo ou gesto) em x do mundo (0 a 480).
func tocar(chave: String, x: float) -> void:
	if calado():
		return
	var nome: String = ACONTECIMENTOS.get(chave, chave)
	if discreto and nome in PESADOS:
		return
	var s := _carregar("acontecimentos/" + nome)
	if s == null:
		return
	var voz: AudioStreamPlayer2D = null
	for v in _vozes:
		if not v.playing:
			voz = v
			break
	if voz == null:
		return  # vozes cheias: este fica de fora
	voz.stream = s
	voz.position = Vector2(x, 80.0)
	voz.play()


func _carregar(caminho: String) -> AudioStream:
	if _cache.has(caminho):
		return _cache[caminho]
	var s: AudioStream = null
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(PASTA + caminho + ext):
			s = load(PASTA + caminho + ext)
			break
	_cache[caminho] = s
	return s

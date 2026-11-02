extends Node
## O som (versão 0.2; documento funcional, "O som"): discreto, como o de uma janela
## aberta para fora. Quatro barramentos (Master, Ambiente, Acontecimentos e Interface),
## criados aqui ao abrir.
##
## O silêncio vem antes de tudo: `ligado` (o botão da alça, a tecla M e o menu da bandeja)
## e `escondida` (a janela escondida ou minimizada) calam o Master na hora, sem fade.
##
## O que soa vem do núcleo (API.md, "O som (versão 0.2)"): som_do_evento, o r["som"] dos
## gestos, sons_da_hora e ambiente_sonoro. A lança e o grito da caçada e do ensinar
## tocam pela vida, no quadro em que o desenho mostra. Os arquivos são da C
## (arte_claude/sons/, LEIA-ME, "Os nomes do núcleo"), copiados para res://sons/:
## Ogg mono de 22 050 Hz, nivelados para tocar a 0 dB. Os laços tocam em streaming.

const PASTA := "res://sons/"
const VOLUME_INICIAL_DB := -12.0  # o volume começa baixo (LEIA-ME: -10; o QA-189 pede de -60 a -12)
const VOZES_MAX := 4              # acontecimentos tocando ao mesmo tempo, no máximo
const VOZES_PESADAS := 2          # e os pesados, em vozes só deles (sempre no grupo som_pesado)
const PASSO_AMBIENTE := 0.25      # s entre os ajustes dos laços
const CRUZA := 0.3                # quanto do caminho até o volume-alvo cada ajuste anda (~2 a 3 s)
const MUDO_DB := -60.0

const LACOS := ["vento", "passaros", "lago", "grilos", "fogo", "chuva", "tempestade", "neve", "vila", "festa"]
## O nome que o núcleo (ou a vida, ou a interface) entrega -> o arquivo em eventos/.
const ARQUIVOS := {"trovao": "trovao", "trovao_longe": "trovao_2", "terremoto": "terremoto",
	"fogo": "fogo_acender", "fogo_brando": "fogo_brando", "diluvio": "diluvio", "vento_seco": "vento_seco",
	"pressagio": "pressagio", "terra": "terra", "sino": "milagre_sino", "fartura": "fartura", "sonho": "sonho",
	"cura": "cura", "choro_bebe": "choro_bebe", "lamento": "lamento", "batalha": "batalha",
	"lanca": "arremesso", "lanca_alvo": "arremesso", "baque": "lanca_cravar", "grito_caca": "grito_cacada",
	"grito_frustrado": "grito_frustrado", "sino_templo": "sino_templo", "galo": "galo", "coruja": "coruja"}
## Volume próprio de alguns (dB sobre o 0 dB do arquivo): a lança curta da criança (LEIA-ME).
const AJUSTE_DB := {"lanca_alvo": -4.0}
## O sino leve do milagre: a fartura, o sonho e a cura têm o som próprio (LEIA-ME).
const SINO_PROPRIO := {"fartura_divina": "fartura", "sonho": "sonho", "cura": "cura", "fartura": "fartura"}
## Os pesados não tocam no modo discreto (e ficam no grupo som_pesado enquanto tocam).
const PESADOS := ["terremoto", "diluvio", "fogo_acender", "grito_cacada", "batalha", "lamento"]
const TROVOES := ["trovao_1", "trovao_3"]   # o trovao_2 é o trovao_longe
## Os sons marcados da hora que a vida já toca no quadro do desenho (a lança e o grito).
const DA_VIDA := ["lanca", "lanca_alvo", "baque", "grito_caca"]
const CORUJA_A_CADA := Vector2(60.0, 180.0)  # s reais entre uma coruja e outra, à noite

var ligado := true
var escondida := false
var volume_db := VOLUME_INICIAL_DB
var discreto := false
var ja_tocados := {}  # id de evento -> true: o gesto já tocou na hora, o evento dele não repete

var _lacos := {}      # laço -> AudioStreamPlayer (só os que têm arquivo)
var _vozes: Array = []
var _vozes_pesadas: Array = []
var _clique: AudioStreamPlayer
var _cache := {}
var _espera := 0.0
var _ultimo_trovao := ""
var _coruja_em := 0.0
var _marcados_feitos := {}  # "hora:índice" dos sons da hora já tocados


func criar(vista: Node2D) -> void:
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
			s.loop = true  # sem ponto de laço: o número de amostras é exato (LEIA-ME)
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = "Ambiente"
		p.volume_db = MUDO_DB
		add_child(p)
		_lacos[laco] = p
	for i in VOZES_MAX + VOZES_PESADAS:
		var v := AudioStreamPlayer2D.new()
		v.bus = "Acontecimentos"
		v.attenuation = 0.0     # o pan vem só do x na tela, sem cair com a distância
		v.max_distance = 100000.0
		vista.add_child(v)
		if i < VOZES_MAX:
			_vozes.append(v)
		else:  # os pesados ficam marcados (o modo discreto não os toca)
			v.add_to_group("som_pesado")
			_vozes_pesadas.append(v)
	_clique = AudioStreamPlayer.new()
	_clique.bus = "Interface"
	_clique.stream = _carregar("eventos/clique_alca")
	add_child(_clique)
	_coruja_em = randf_range(CORUJA_A_CADA.x, CORUJA_A_CADA.y)
	_aplicar_master()


## O botão da alça, a tecla M e o menu da bandeja. Muda na hora.
func definir_ligado(sim_: bool) -> void:
	ligado = sim_
	_aplicar_master()


## A janela escondida ou minimizada cala tudo na hora.
func definir_escondida(sim_: bool) -> void:
	escondida = sim_
	_aplicar_master()


func _aplicar_master() -> void:
	AudioServer.set_bus_volume_db(0, volume_db)
	AudioServer.set_bus_mute(0, calado())
	if calado():  # calado, nada toca: nada para misturar, nada para gastar
		for laco in _lacos:
			_lacos[laco].stop()
			_lacos[laco].volume_db = MUDO_DB
		for v in _vozes + _vozes_pesadas:
			v.stop()


func calado() -> bool:
	return not ligado or escondida


## Chamado a cada quadro pela moldura: os laços cruzam devagar, e os sons marcados da hora.
func avancar(delta: float, mundo, hora: float) -> void:
	if calado() or mundo == null:
		return
	_espera -= delta
	_coruja_em -= delta
	if _espera > 0.0:
		return
	_espera = PASSO_AMBIENTE
	var amb: Dictionary = mundo.ambiente_sonoro() if mundo.has_method("ambiente_sonoro") else {}
	if bool(amb.get("noite", false)) and float(amb.get("chuva", 0.0)) < 0.3 and _coruja_em <= 0.0:
		_coruja_em = randf_range(CORUJA_A_CADA.x, CORUJA_A_CADA.y)
		tocar("coruja", randf_range(330.0, 470.0))  # na mata do morro, por cima dos grilos
	if mundo.has_method("sons_da_hora"):
		_tocar_marcados(mundo.sons_da_hora(), hora)
	var alvos := _alvos_do_ambiente(amb, hora)
	for laco in _lacos:
		var p: AudioStreamPlayer = _lacos[laco]
		var alvo: float = alvos.get(laco, 0.0)
		var atual := db_to_linear(p.volume_db) if p.volume_db > MUDO_DB else 0.0
		var novo := lerpf(atual, alvo, CRUZA)
		if absf(novo - alvo) < 0.01:
			novo = alvo
		p.volume_db = linear_to_db(novo) if novo > 0.001 else MUDO_DB
		if novo > 0.001 and not p.playing:
			p.play()
		elif novo <= 0.001 and p.playing:
			p.stop()


## Os sons marcados da hora (galo, sino do templo, o grito frustrado) no minuto deles.
## Só toca o que passou há menos de um minuto: ao religar o som, nada sai atrasado.
func _tocar_marcados(marcados: Array, hora: float) -> void:
	var h := int(hora)
	var minuto := (hora - h) * 60.0
	for i in marcados.size():
		var m: Dictionary = marcados[i]
		var chave := "%d:%d" % [h, i]
		if _marcados_feitos.has(chave) or minuto < float(m.get("minuto", 0.0)):
			continue
		_marcados_feitos[chave] = true
		if _marcados_feitos.size() > 100:
			_marcados_feitos.clear()
		if String(m.get("som", "")) in DA_VIDA or minuto > float(m.get("minuto", 0.0)) + 1.0:
			continue
		tocar(String(m["som"]), float(m.get("x", 240.0)), float(m.get("intensidade", 1.0)))


## O ambiente_sonoro do núcleo -> o volume-alvo de cada laço (os volumes do LEIA-ME da C,
## em fator linear: 0 dB = 1,0).
func _alvos_do_ambiente(amb: Dictionary, hora: float) -> Dictionary:
	var noite: bool = amb.get("noite", hora < 6.0 or hora >= 20.0)
	var inverno: bool = amb.get("estacao", "") == "inverno"
	var neve: bool = amb.get("neve", false)
	var tempestade: bool = not Dictionary(amb.get("tempestade", {})).is_empty()
	var chuva: float = float(amb.get("chuva", 0.0))
	var molhado: bool = tempestade or chuva >= 0.3
	var festa: bool = float(amb.get("festa", -1.0)) >= 0.0
	var gente: int = int(amb.get("pessoas", 0))
	var vazio: bool = amb.get("vazio", gente == 0)
	var a := {}
	a["vento"] = 0.0 if neve else (0.5 if noite or inverno else 1.0) * lerpf(0.8, 1.0, float(amb.get("vento", 0.2)))
	a["passaros"] = 0.0 if noite or molhado or neve or hora >= 17.0 or hora < 5.0 else (1.0 if hora < 9.0 else 0.8)
	a["lago"] = 0.63 if noite else 1.0                                       # -4 dB à noite
	a["grilos"] = 1.0 if noite and not inverno and not molhado and not neve else 0.0
	a["fogo"] = float(amb.get("fogo", 0.0)) if amb.get("fogo_aceso", false) else 0.0
	a["chuva"] = 0.0 if tempestade else chuva
	a["tempestade"] = 1.0 if tempestade else 0.0
	a["neve"] = 1.0 if neve else 0.0
	# a vila: de -6 dB (até 15 pessoas) a 0 dB (60 ou mais), das 6h às 21h; na festa, o tambor
	var acordada: bool = not vazio and hora >= 6.0 and hora < 21.0
	a["vila"] = 0.0 if not acordada or festa else lerpf(0.5, 1.0, clampf((gente - 15) / 45.0, 0.0, 1.0))
	a["festa"] = 1.0 if festa and acordada else 0.0
	return a


## Um som do núcleo ({som, x, intensidade[, sino]}): o do evento ou o do gesto. `tipo` é o
## do evento, para a fartura, o sonho e a cura tocarem o som próprio no lugar do sino.
func tocar_do_nucleo(s: Dictionary, tipo := "", grau := "") -> void:
	if s.is_empty():
		return
	var nome := String(s.get("som", ""))
	if nome == "sino" and SINO_PROPRIO.has(tipo):
		nome = SINO_PROPRIO[tipo]
	elif nome == "fogo" and grau == "brando":  # o fogo brando, que só aquece
		nome = "fogo_brando"
	var x := float(s.get("x", 240.0))
	tocar(nome, x, float(s.get("intensidade", 1.0)))
	if s.get("sino", false) and nome != "sino":
		tocar("sino", x, float(s.get("intensidade", 1.0)))


## Um som pelo nome do núcleo, em x do mundo (0 a 480), com intensidade de 0 a 1.
func tocar(chave: String, x: float, intensidade := 1.0) -> void:
	if calado():
		return
	var arquivo: String = ARQUIVOS.get(chave, "")
	if arquivo == "":
		return
	if arquivo == "trovao":  # sorteado, sem repetir o anterior
		arquivo = TROVOES[1] if _ultimo_trovao == TROVOES[0] else TROVOES[0] if _ultimo_trovao == TROVOES[1] \
			else TROVOES[randi() % TROVOES.size()]
		_ultimo_trovao = arquivo
	if discreto and arquivo in PESADOS:
		return
	var s := _carregar("eventos/" + arquivo)
	if s == null:
		return
	var voz: AudioStreamPlayer2D = null
	for v in (_vozes_pesadas if arquivo in PESADOS else _vozes):
		if not v.playing:
			voz = v
			break
	if voz == null:
		return  # vozes cheias: este fica de fora
	voz.stream = s
	# a intensidade do núcleo vai de 0 a 1: de -12 dB (um sinal) a 0 dB (o mais forte)
	voz.volume_db = lerpf(-12.0, 0.0, clampf(intensidade, 0.0, 1.0)) + float(AJUSTE_DB.get(chave, 0.0))
	voz.position = Vector2(x, 80.0)
	voz.play()


## Ao fechar: para tudo e solta os streams (senão o Godot avisa de recursos vivos na saída).
func encerrar() -> void:
	for p in _lacos.values() + _vozes + _vozes_pesadas + [_clique]:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_lacos.clear()
	_cache.clear()


## O clique dos botões da alça, bem baixo (não toca no botão de som).
func clique() -> void:
	if not calado() and _clique.stream != null:
		_clique.play()


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

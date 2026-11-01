extends RefCounted
## O arquivo dos antigos: eventos e pessoas de mais de 300 anos que a memória viva do mundo
## não usa mais. Cada um vira uma linha de texto ("e" ou "p", o id e os valores na ordem dos
## campos), guardada em memória como bytes UTF-8 (um texto do Godot ocupa 4 bytes por letra)
## e gravada num arquivo à parte, ao lado do mundo salvo. Quem precisar de um deles (a
## crônica, a API) recebe o objeto decodificado da linha, igual ao que era. Também guarda a
## codificação de valores do mundo salvo (reais pelos 64 bits, dicionários em ordem), usada
## pela persistência.

const Evento = preload("evento.gd")
const Pessoa = preload("pessoa.gd")

const CABECALHO := "# Simulador de vida: eventos e pessoas antigos. Arquivo de texto do Godot (var_to_str).\n"
const PREFIXO_REAL := "@f:"
const FIM_DE_LINHA := 10

var bytes := PackedByteArray()      # as linhas, cada uma terminada em "\n"
var inicios := PackedInt32Array()   # onde começa cada linha
var campos: Dictionary = {}         # "e"/"p" -> nomes dos campos, na ordem dos valores
var _e: Dictionary = {}             # id do evento -> número da linha
var _p: Dictionary = {}             # id da pessoa -> número da linha


func linhas() -> int:
	return inicios.size()


func guardar(tipo: String, o) -> void:
	if campos.is_empty():
		campos = campos_atuais()
	(_e if tipo == "e" else _p)[o.id] = inicios.size()
	inicios.append(bytes.size())
	bytes.append_array((linha(tipo, o) + "\n").to_utf8_buffer())


## O evento ("e") ou a pessoa ("p") de um id, decodificado; null se não está aqui.
func objeto(tipo: String, id: int):
	var i = (_e if tipo == "e" else _p).get(id)
	if i == null:
		return null
	return objeto_da_linha(_linha(i), campos[tipo])


func _linha(i: int) -> String:
	var fim: int = inicios[i + 1] if i + 1 < inicios.size() else bytes.size()
	return bytes.slice(inicios[i], fim - 1).get_string_from_utf8()


## As linhas a partir da `de`, como texto (as que ainda não estão no arquivo em disco).
func linhas_desde(de: int) -> PackedStringArray:
	var r := PackedStringArray()
	for i in range(de, inicios.size()):
		r.append(_linha(i))
	return r


## Acrescenta linhas já prontas (as que vieram dentro do mundo salvo).
func acrescentar(novas: Array) -> void:
	for l in novas:
		var k := chave(l)
		(_e if k[0] == "e" else _p)[k[1]] = inicios.size()
		inicios.append(bytes.size())
		bytes.append_array((String(l) + "\n").to_utf8_buffer())


## O conteúdo do arquivo: cabeçalho, quantas linhas e os campos, e as linhas.
func conteudo() -> PackedByteArray:
	var info := {"linhas": inicios.size(), "campos": campos}
	var r := (CABECALHO + var_to_str(info).replace("\n", " ") + "\n").to_utf8_buffer()
	r.append_array(bytes)
	return r


## Lê um arquivo dos antigos e fica com as `n` primeiras linhas (as que o mundo arquivou; um
## arquivo mais novo pode ter mais). Devolve false se ele não serve (ausente, cortado,
## estragado, com menos linhas).
func ler(caminho: String, n: int) -> bool:
	if n == 0:
		bytes = PackedByteArray()
		inicios = PackedInt32Array()
		_e.clear()
		_p.clear()
		if campos.is_empty():
			campos = campos_atuais()
		return true
	if not FileAccess.file_exists(caminho):
		return false
	var b := FileAccess.get_file_as_bytes(caminho)
	var cab := CABECALHO.to_utf8_buffer()
	if b.size() < cab.size() or b.slice(0, cab.size()) != cab:
		return false
	var fim_info := b.find(FIM_DE_LINHA, cab.size())
	if fim_info < 0:
		return false
	var info = str_to_var(b.slice(cab.size(), fim_info).get_string_from_utf8())
	if typeof(info) != TYPE_DICTIONARY or not info.has("linhas") or not info.has("campos") or int(info["linhas"]) < n:
		return false
	var corpo := b.slice(fim_info + 1)
	var ini := PackedInt32Array()
	var pos := 0
	while ini.size() < int(info["linhas"]):
		var f := corpo.find(FIM_DE_LINHA, pos)
		if f < 0:
			return false
		ini.append(pos)
		pos = f + 1
	if pos != corpo.size():
		return false
	bytes = corpo.slice(0, ini[n] if n < ini.size() else corpo.size())
	inicios = ini.slice(0, n)
	campos = info["campos"]
	var atuais := campos_atuais()
	if campos != atuais and n > 0:
		# Os campos mudaram desde a gravação: refaz as linhas na ordem de agora.
		var velhos := campos
		var antigas := PackedStringArray()
		for i in inicios.size():
			antigas.append(_linha(i))
		bytes = PackedByteArray()
		inicios = PackedInt32Array()
		campos = atuais
		for l in antigas:
			var k := chave(l)
			inicios.append(bytes.size())
			bytes.append_array((linha(k[0], objeto_da_linha(l, velhos[k[0]])) + "\n").to_utf8_buffer())
	_e.clear()
	_p.clear()
	for i in inicios.size():
		var k := chave(bytes.slice(inicios[i], mini(inicios[i] + 32, bytes.size())).get_string_from_utf8())
		(_e if k[0] == "e" else _p)[k[1]] = i
	return true


# ---------------------------------------------------------------- linhas

static var _campos_por_script := {}


## Os nomes dos campos de um objeto, na ordem em que os valores vão na linha.
static func campos_de(o) -> Array:
	var s = o.get_script()
	if not _campos_por_script.has(s):
		var l: Array = []
		for prop in o.get_property_list():
			if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				l.append(prop["name"])
		_campos_por_script[s] = l
	return _campos_por_script[s]


static func campos_atuais() -> Dictionary:
	return {"e": campos_de(Evento.new()), "p": campos_de(Pessoa.new())}


## A linha de um evento ("e") ou de uma pessoa ("p"), sem o fim de linha.
static func linha(tipo: String, o) -> String:
	var valores: Array = []
	for nome in campos_de(o):
		valores.append(o.get(nome))
	# var_to_str quebra linhas entre os itens de um dicionário; dentro de textos, as quebras
	# já vêm escapadas, então trocar as quebras por espaço não muda nada.
	return "%s\t%d\t%s" % [tipo, o.id, var_to_str(codificar(valores)).replace("\n", " ")]


## O tipo e o id de uma linha, sem decodificar o resto.
static func chave(l: String) -> Array:
	var a := l.find("\t")
	var b := l.find("\t", a + 1)
	return [l.substr(0, a), int(l.substr(a + 1, b - a - 1))]


static func objeto_da_linha(l: String, nomes: Array):
	var k := chave(l)
	var o = Evento.new() if k[0] == "e" else Pessoa.new()
	var valores: Array = decodificar(str_to_var(l.substr(l.find("\t", l.find("\t") + 1) + 1)))
	for j in mini(nomes.size(), valores.size()):
		o.set(nomes[j], valores[j])
	return o


# ---------------------------------------------------------------- codificação dos valores

static func codificar(v):
	match typeof(v):
		TYPE_FLOAT:
			return PREFIXO_REAL + str(PackedFloat64Array([v]).to_byte_array().decode_s64(0))
		TYPE_DICTIONARY:
			# O texto do Godot ordena as chaves; a ordem conta para o determinismo, então
			# cada dicionário vai como lista de pares.
			var pares: Array = []
			for k in v:
				pares.append([k, codificar(v[k])])
			return {"@ordem": pares}
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(codificar(x))
			return a
	return v


static func decodificar(v):
	match typeof(v):
		TYPE_STRING:
			if v.begins_with(PREFIXO_REAL):
				var b := PackedByteArray()
				b.resize(8)
				b.encode_s64(0, int(v.substr(PREFIXO_REAL.length())))
				return b.decode_double(0)
		TYPE_DICTIONARY:
			var d := {}
			if v.size() == 1 and v.has("@ordem"):
				for par in v["@ordem"]:
					d[par[0]] = decodificar(par[1])
				return d
			for k in v:
				d[k] = decodificar(v[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(decodificar(x))
			return a
	return v

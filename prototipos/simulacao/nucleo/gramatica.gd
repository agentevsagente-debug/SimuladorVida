extends RefCounted
## Gramática do português para a crônica: artigos, contrações, concordância
## de gênero e número, números por extenso e um pequeno motor de modelos.
##
## Um modelo de frase usa variáveis entre chaves. Cada variável é um dicionário
## {"t": texto, "g": "m"|"f", "n": 1|2, "art": bool}, criado por `termo()`.
##   {x}            texto da variável
##   {o:x}          artigo + texto ("o lago", "Ana")
##   {de:x}         contração ("do lago", "da praia", "de Ana")
##   {em:x} {a:x} {por:x}   idem
##   {x:o|a}        escolhe pela concordância de gênero
##   {x:o|a|os|as}  escolhe por gênero e número
##   {x#sing|plur}  escolhe só pelo número
## A primeira letra de cada frase é posta em maiúscula no fim.

const UNIDADES := ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete",
	"oito", "nove", "dez", "onze", "doze", "treze", "catorze", "quinze",
	"dezesseis", "dezessete", "dezoito", "dezenove", "vinte"]


static func termo(texto: String, genero: String = "m", numero: int = 1, com_artigo: bool = false) -> Dictionary:
	return {"t": texto, "g": genero, "n": numero, "art": com_artigo}


static func artigo(g: String, n: int = 1) -> String:
	if n > 1:
		return "os" if g == "m" else "as"
	return "o" if g == "m" else "a"


static func contracao(prep: String, g: String, n: int = 1) -> String:
	var a := artigo(g, n)
	match prep:
		"de":
			return "d" + a
		"em":
			return "n" + a
		"a":
			if a == "o":
				return "ao"
			if a == "os":
				return "aos"
			return "à" if a == "a" else "às"
		"por":
			return "pel" + a
	return a


## Flexiona uma raiz regular: flex("mort", "f", 2) = "mortas".
static func flex(raiz: String, g: String, n: int = 1) -> String:
	var fim := "o" if g == "m" else "a"
	if n > 1:
		fim += "s"
	return raiz + fim


static func extenso(n: int, g: String = "m") -> String:
	if n == 1:
		return "um" if g == "m" else "uma"
	if n == 2:
		return "dois" if g == "m" else "duas"
	if n >= 0 and n <= 20:
		return UNIDADES[n]
	return str(n)


static func lista(itens: Array) -> String:
	if itens.is_empty():
		return ""
	if itens.size() == 1:
		return str(itens[0])
	var inicio: Array = itens.slice(0, itens.size() - 1)
	return ", ".join(PackedStringArray(inicio)) + " e " + str(itens[-1])


static func maiuscula(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)


## Gênero de um conjunto de pessoas: masculino se houver algum homem.
static func genero_conjunto(generos: Array) -> String:
	for g in generos:
		if g == "m":
			return "m"
	return "f" if not generos.is_empty() else "m"


static func preencher(modelo: String, vars: Dictionary, capitalizar: bool = true) -> String:
	var saida := ""
	var i := 0
	while i < modelo.length():
		var c := modelo[i]
		if c != "{":
			saida += c
			i += 1
			continue
		var fim := modelo.find("}", i)
		if fim < 0:
			saida += modelo.substr(i)
			break
		saida += _token(modelo.substr(i + 1, fim - i - 1), vars)
		i = fim + 1
	return _maiusculas_de_frase(saida) if capitalizar else saida


static func _token(tok: String, vars: Dictionary) -> String:
	var hash_pos := tok.find("#")
	if hash_pos > 0:
		var v = vars.get(tok.substr(0, hash_pos), termo("?"))
		var formas := tok.substr(hash_pos + 1).split("|")
		return formas[0] if int(v["n"]) <= 1 else formas[min(1, formas.size() - 1)]
	var dois := tok.find(":")
	if dois < 0:
		return str(vars.get(tok, termo("{" + tok + "}"))["t"])
	var esq := tok.substr(0, dois)
	var dir := tok.substr(dois + 1)
	if dir.find("|") >= 0:
		var v2 = vars.get(esq, termo("?"))
		var formas2 := dir.split("|")
		var idx := 0 if v2["g"] == "m" else 1
		if formas2.size() >= 4 and int(v2["n"]) > 1:
			idx += 2
		return formas2[min(idx, formas2.size() - 1)]
	var v3 = vars.get(dir, termo("{" + dir + "}"))
	var prep := esq.to_lower()
	var maius := esq != prep
	var res := ""
	if not v3["art"]:
		if prep == "o":
			res = v3["t"]
		elif prep == "em":
			res = "em " + v3["t"]
		elif prep == "a":
			res = "a " + v3["t"]
		else:
			res = prep + " " + v3["t"]
	elif prep == "o":
		res = artigo(v3["g"], v3["n"]) + " " + v3["t"]
	else:
		res = contracao(prep, v3["g"], v3["n"]) + " " + v3["t"]
	return maiuscula(res) if maius else res


static func _maiusculas_de_frase(s: String) -> String:
	var r := ""
	var subir := true
	for i in s.length():
		var c := s[i]
		if subir and c != " " and c != "\"" and c != "«" and c != "—":
			r += c.to_upper()
			subir = false
		else:
			r += c
		if c == "." or c == "!" or c == "?":
			subir = true
	return r

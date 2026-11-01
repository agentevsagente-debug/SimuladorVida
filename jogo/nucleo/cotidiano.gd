extends RefCounted
## O cotidiano visível: onde cada pessoa está e o que faz em cada hora, e onde
## ficam as construções. Tudo é derivado do estado do mundo e da hora, sem
## sorteio do mundo: a apresentação pergunta quantas vezes quiser, e a
## simulação não muda por isso nem paga nada a cada passo.

const LARGURA_MUNDO := 480
## Faixa de x (em pixels do mundo) de cada zona, da esquerda para a direita.
const FAIXAS := {"praia": [0, 110], "lago": [110, 200], "floresta": [200, 350], "morro": [350, 480]}
const LARGURAS := {"fogueira": 8, "altar": 8, "cabana": 16, "roca": 24}
const ACOES := ["dormir", "andar", "parado", "colher", "rezar", "fogueira"]


static func zona_em(x: float) -> String:
	for chave in FAIXAS:
		if x < FAIXAS[chave][1]:
			return chave
	return "morro"


static func centro_da_zona(chave: String) -> float:
	return (FAIXAS[chave][0] + FAIXAS[chave][1]) * 0.5


## Número em [0, 1) fixo para cada combinação de inteiros.
static func ruido(a: int, b: int, c: int) -> float:
	return float(posmod(hash([a, b, c]), 10007)) / 10007.0


## Faixa de x do acampamento de um grupo: a zona dividida entre os grupos que vivem nela.
static func faixa_do_grupo(m, g) -> Array:
	var z: Array = FAIXAS[g.zona]
	var ali: Array = m.grupos_na_zona(g.zona)
	var n := maxi(1, ali.size())
	var i := maxi(0, ali.find(g))
	var w := float(z[1] - z[0]) / n
	return [z[0] + w * i, z[0] + w * (i + 1)]


## Construções de um grupo, com posição. A posição só muda se o número de peças mudar.
static func construcoes_do_grupo(m, g) -> Array:
	var r: Array = []
	var faixa := faixa_do_grupo(m, g)
	var a: float = faixa[0] + 8.0
	var b: float = faixa[1] - 8.0
	var c: float = (faixa[0] + faixa[1]) * 0.5
	r.append({"tipo": "fogueira", "x": c, "largura": LARGURAS["fogueira"], "grupo": g.id})
	if g.tem_crenca and not g.ceticos:
		r.append({"tipo": "altar", "x": clampf(c + 9.0, a, b), "largura": LARGURAS["altar"], "grupo": g.id})
	for i in g.abrigos:
		var lado := -1.0 if i % 2 == 0 else 1.0
		var x := clampf(c + lado * (18.0 + 18.0 * (i / 2)), a, b)
		r.append({"tipo": "cabana", "x": x, "largura": LARGURAS["cabana"], "grupo": g.id})
	if g.estagio == 2:
		var adultos := 0
		for id in g.membros:
			if m.pessoas[id].idade(m.ano()) >= 13:
				adultos += 1
		var rocas := clampi(int(ceil(adultos / 6.0)), 1, 4)
		var base = 18.0 + 18.0 * ceil(g.abrigos / 2.0) + 12.0
		for j in rocas:
			var lado2 := 1.0 if j % 2 == 0 else -1.0
			var x2 := clampf(c + lado2 * (base + 26.0 * (j / 2)), a + 4.0, b - 4.0)
			r.append({"tipo": "roca", "x": x2, "largura": LARGURAS["roca"], "grupo": g.id})
	return r


## Onde a pessoa está e o que faz no passo dado. `obras` são as construções do grupo dela.
static func pessoa_no_passo(m, p, g, obras: Array, passo: int) -> Dictionary:
	var h := passo % 24
	var dia := passo / 24
	var idade: int = p.idade(m.ano())
	var fogo_x := 0.0
	var altar_x := -1.0
	var cabanas: Array = []
	var rocas: Array = []
	for o in obras:
		match o["tipo"]:
			"fogueira":
				fogo_x = o["x"]
			"altar":
				altar_x = o["x"]
			"cabana":
				cabanas.append(o["x"])
			"roca":
				rocas.append(o["x"])
	if altar_x < 0.0:
		altar_x = fogo_x
	var casa_x: float = fogo_x - 6.0 if cabanas.is_empty() else cabanas[p.id % cabanas.size()]
	casa_x += (ruido(p.id, 0, 7) - 0.5) * 8.0
	var lugar_fogo := fogo_x + (ruido(p.id, 0, 1) - 0.5) * 24.0
	var faixa_zona: Array = FAIXAS[g.zona]
	var trabalho_x: float = faixa_zona[0] + 4.0 + ruido(p.id, dia, 3) * (faixa_zona[1] - faixa_zona[0] - 8.0)
	if g.estagio == 2 and not rocas.is_empty() and ruido(p.id, dia, 2) < 0.6:
		trabalho_x = rocas[p.id % rocas.size()] + (ruido(p.id, dia, 4) - 0.5) * 20.0
	# Quem tem uma prece aberta reza de manhã cedo e ao entardecer; quem fala pelo deus, também.
	var reza := false
	for nec in g.preces:
		if g.preces[nec]["autor"] == p.id:
			reza = true
	if g.sacerdote == p.id and (h == 7 or h == 18):
		return {"x": altar_x, "acao": "rezar"}
	if reza and (h == 6 or h == 18):
		return {"x": altar_x + (ruido(p.id, 0, 5) - 0.5) * 6.0, "acao": "rezar"}
	if h >= 21 or h <= 5 or p.doente > 0:
		return {"x": casa_x, "acao": "dormir"}
	var tempestade: Dictionary = m.tempestade
	if not tempestade.is_empty() and tempestade["zona"] == g.zona and h >= tempestade["inicio"]:
		return {"x": casa_x, "acao": "parado"}
	if idade < 10:
		var brinca := fogo_x + (ruido(p.id, dia, h) - 0.5) * 40.0
		if h >= 18:
			return {"x": lugar_fogo, "acao": "fogueira"}
		return {"x": brinca, "acao": "andar" if ruido(p.id, dia, h + 50) < 0.5 else "parado"}
	if h == 6:
		return {"x": trabalho_x, "acao": "andar"}
	if h == 17:
		return {"x": lugar_fogo, "acao": "andar"}
	if h >= 18:
		return {"x": lugar_fogo, "acao": "fogueira"}
	if idade > 60:
		return {"x": lugar_fogo, "acao": "fogueira"}
	return {"x": trabalho_x, "acao": "colher"}

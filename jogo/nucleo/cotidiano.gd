extends RefCounted
## O cotidiano visível: onde cada pessoa está e o que faz em cada hora, e onde
## ficam as construções. Tudo é derivado do estado do mundo e da hora, sem
## sorteio do mundo: a apresentação pergunta quantas vezes quiser, e a
## simulação não muda por isso nem paga nada a cada passo.

const LARGURA_MUNDO := 480
## Faixa de x (em pixels do mundo) de cada zona, da esquerda para a direita,
## casada com a arte da cena-alvo: o lago é a água à esquerda.
const FAIXAS := {"lago": [0, 136], "praia": [136, 200], "floresta": [200, 330], "morro": [330, 480]}
## Onde cada zona acampa. O povo do lago mora na margem e na areia próxima, nunca na água.
const ACAMPAMENTO := {"lago": [126, 168], "praia": [160, 200], "floresta": [200, 330], "morro": [330, 480]}
## Onde cada zona trabalha. No lago, pesca-se e busca-se água na margem.
const TRABALHO := {"lago": [126, 136], "praia": [136, 200], "floresta": [200, 330], "morro": [330, 480]}
## Ninguém fica parado à esquerda disto: é água.
const MARGEM := 126.0
const LARGURAS := {"fogueira": 8, "altar": 8, "cabana": 16, "roca": 16}
const ACOES := ["dormir", "andar", "parado", "colher", "rezar", "fogueira"]


static func zona_em(x: float) -> String:
	for chave in FAIXAS:
		if x < FAIXAS[chave][1]:
			return chave
	return "morro"


static func centro_da_zona(chave: String) -> float:
	return (FAIXAS[chave][0] + FAIXAS[chave][1]) * 0.5


## Número em [0, 1) fixo para cada combinação de inteiros. Mistura de inteiros (sem criar
## arrays), porque a rotina chama isto dezenas de milhares de vezes por dia de jogo.
static func ruido(a: int, b: int, c: int) -> float:
	var h: int = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 10007)) / 10007.0


## Faixa de x do acampamento de um grupo: a zona dividida entre os grupos que vivem nela.
static func faixa_do_grupo(m, g) -> Array:
	var z: Array = ACAMPAMENTO[g.zona]
	var ali: Array = m.grupos_na_zona(g.zona)
	var n := maxi(1, ali.size())
	var i := maxi(0, ali.find(g))
	var w := float(z[1] - z[0]) / n
	return [z[0] + w * i, z[0] + w * (i + 1)]


## Construções de um grupo, com posição, por estágio. Cada peça é posta no primeiro
## lugar livre perto da fogueira, numa ordem fixa: a posição só muda quando o número
## de peças muda ou quando o povo se muda.
static func construcoes_do_grupo(m, g) -> Array:
	var r: Array = []
	var faixa := faixa_do_grupo(m, g)
	var c: float = (faixa[0] + faixa[1]) * 0.5
	var ocupado: Array = []
	var est: int = g.estagio
	var por: Callable = func(tipo: String, largura: float, extra: Dictionary, obrigatoria: bool):
		var x := _lugar_livre(c, largura, faixa, ocupado)
		if x < -9000.0:
			if not obrigatoria:
				return
			x = clampf(c, faixa[0] + largura * 0.5, faixa[1] - largura * 0.5)
		ocupado.append([x - largura * 0.5, x + largura * 0.5])
		var o := {"tipo": tipo, "x": x, "largura": largura, "grupo": g.id, "estagio": est, "ruina": false}
		o.merge(extra)
		r.append(o)
	ocupado.append([c - 4.0, c + 4.0])
	r.append({"tipo": "fogueira", "x": c, "largura": LARGURAS["fogueira"], "grupo": g.id, "estagio": est, "ruina": false})
	if g.tem_crenca and not g.ceticos:
		por.call("altar", LARGURAS["altar"], {}, true)
		if est >= 2:
			por.call("templo", 32.0, {}, true)
	if est >= 5:
		por.call("arquivo", 32.0, {}, true)
	if est >= 4:
		por.call("forja", 24.0, {}, true)
	var largura_casa := 16.0 if est == 1 else (24.0 if est == 2 else 32.0)
	var casas: int = g.abrigos if est <= 2 else mini(g.abrigos, int(ceil(g.membros.size() / 8.0)))
	for i in casas:
		por.call("cabana", largura_casa, {}, false)
	if est >= 2 and g.tem_costume("estocar"):
		por.call("celeiro", 24.0, {}, false)
	if est >= 6:
		por.call("moinho", 32.0, {}, false)
	if est >= 2:
		var adultos := 0
		for id in g.membros:
			if m.pessoas[id].idade(m.ano()) >= 13:
				adultos += 1
		var rocas := clampi(int(ceil(adultos / 6.0)), 1, 4)
		for j in rocas:
			por.call("roca", LARGURAS["roca"], {"irrigada": est >= 6}, false)
	if est >= 6 and g.violencia >= 0.5:
		for borda in [faixa[0] + 8.0, faixa[1] - 8.0]:
			r.append({"tipo": "muralha", "x": borda, "largura": 16.0, "grupo": g.id, "estagio": est, "ruina": false})
	if est >= 6 and (g.zona == "lago" or g.zona == "praia"):
		r.append({"tipo": "barco", "x": 112.0, "largura": 24.0, "grupo": g.id, "estagio": est, "ruina": false})
	return r


## Centro do primeiro intervalo livre para uma peça, procurando para os dois lados do centro.
static func _lugar_livre(c: float, largura: float, faixa: Array, ocupado: Array) -> float:
	var passo := 4.0
	for i in 60:
		var desvio = passo * ceil(i / 2.0) * (1.0 if i % 2 == 1 else -1.0)
		var x = c + desvio
		var ini = x - largura * 0.5
		var fim = x + largura * 0.5
		if ini < faixa[0] or fim > faixa[1]:
			continue
		var livre := true
		for o in ocupado:
			if ini < o[1] + 1.0 and fim > o[0] - 1.0:
				livre = false
				break
		if livre:
			return x
	return -9999.0


## Onde a pessoa está e o que faz no passo dado. `obras` são as construções do grupo dela.
static func pessoa_no_passo(m, p, g, obras: Array, passo: int) -> Dictionary:
	var r := _pessoa_no_passo(m, p, g, obras, passo)
	r["x"] = clampf(r["x"], MARGEM, LARGURA_MUNDO - 2.0)
	return r


static func _pessoa_no_passo(m, p, g, obras: Array, passo: int) -> Dictionary:
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
	var faixa_trab: Array = TRABALHO[g.zona]
	var folga := minf(4.0, (faixa_trab[1] - faixa_trab[0]) * 0.2)
	var trabalho_x: float = faixa_trab[0] + folga + ruido(p.id, dia, 3) * (faixa_trab[1] - faixa_trab[0] - 2.0 * folga)
	if g.estagio >= 2 and not rocas.is_empty() and ruido(p.id, dia, 2) < 0.6:
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

extends RefCounted
## A dica sobre uma pessoa: o que ela está fazendo, o que está pensando e o humor.
## Tudo sai do estado real do mundo (a ação e o detalhe da rotina, a cena, a memória da
## pessoa, a família, os rancores, o povo, a crença e os traços); nada é sorteado do
## `mundo.rng`, e a escolha entre frases parecidas muda a cada 2 horas de jogo.
## O deus é invisível: a pessoa fala do que viu, pelo nome que o povo dá a ele.
## Uso: mundo.dica(pessoa_id) (veja nucleo/API.md).

const G = preload("gramatica.gd")
const Cotidiano = preload("cotidiano.gd")

const PENSAMENTO_MAX := 60
const BLOCO := 2          # horas de jogo em que o pensamento fica o mesmo
const RECENTE := 8        # dias em que um acontecimento ainda ocupa a cabeça

## O que se faz, pelo detalhe da rotina. "{a}" é o fim de concordância (o/a); "{lugar}" vira
## o lugar ("perto do fogo", "na praia", ...).
const FAZENDO_DETALHE := {
	"colher_arbusto": "colhendo frutinhas {lugar}", "cavar_raiz": "cavando raízes {lugar}",
	"catar_lenha": "catando lenha na borda da mata", "colher_roca": "colhendo na roça",
	"carregar_cesto": "trazendo um cesto cheio", "carregar_agua": "trazendo água do lago",
	"buscar_agua": "enchendo o pote no lago", "guardar": "guardando o que trouxe",
	"banho": "tomando banho no lago", "cozinhar": "cozinhando no fogo", "comer": "comendo perto do fogo",
	"brincar": "brincando {lugar}", "vigia": "vigiando o fogo", "olhar_ceu": "olhando as estrelas",
	"reza_noturna": "rezando sozinh{a} no escuro", "historias": "ouvindo histórias no fogo",
	"doente": "de cama, doente", "repartir": "repartindo a caça no fogo", "maos_vazias": "de volta da caçada, sem nada",
	"brigar": "brigando com outra criança", "separar": "apartando uma briga de crianças",
	"machucado": "chorando, machucad{a}", "espantar": "espantando um bicho",
	"perdido": "perdid{a}, chamando a mãe", "buscar": "procurando uma criança perdida",
	"discutir": "discutindo", "descansar": "descansando à sombra", "ninar": "ninando o pequeno",
	"carregar_feixe": "trazendo um feixe de lenha", "carregar_cesto_cabeca": "trazendo um cesto na cabeça",
	"espreitar": "espreitando um porco", "mirar": "mirando o porco com a lança",
	"arremessar": "arremessando a lança no porco", "apontar": "apontando o porco para quem mira",
	"espeto": "esperando a caça com o espeto", "pescar_lanca": "de lança erguida na água rasa, esperando o peixe",
	"golpear": "golpeando a água com a lança", "peixe_na_lanca": "com o peixe na ponta da lança",
	"despejar": "despejando o cesto perto do fogo", "lavar": "lavando na beira do lago", "recolher_caca": "amarrando o porco abatido",
	"caca_no_pau": "trazendo o porco no pau", "bocejar": "acordando, espreguiçando-se",
	"aticar": "atiçando as brasas", "cochilar": "cochilando na vigia",
	"levar_cesto": "indo colher, com o cesto", "levar_vara": "indo pescar, com a vara",
	"levar_machado": "indo buscar lenha", "levar_pote": "indo buscar água", "levar_lanca": "indo caçar"}

## O que se faz, pela ação, quando o detalhe não diz.
const FAZENDO_ACAO := {
	"dormir": "dormindo", "andar": "andando {lugar}", "parado": "parad{a} {lugar}", "colher": "colhendo {lugar}",
	"rezar": "rezando no altar", "fogueira": "sentad{a} junto ao fogo", "pescar": "pescando no lago",
	"lenha": "trazendo lenha", "construir": "trabalhando na obra", "forjar": "batendo metal na forja",
	"escrever": "escrevendo no arquivo", "remar": "remando no lago", "lutar": "lutando",
	"carregar_morto": "carregando um morto", "dancar": "dançando", "cuidar": "cuidando dos pequenos",
	"conversar": "conversando", "cacar": "caçando", "carregar_caca": "trazendo a caça", "brincar": "brincando {lugar}",
	"deitar": "deitad{a} à sombra", "tecer": "tecendo um cesto", "consertar": "consertando uma ferramenta",
	"cozinhar": "cozinhando no fogo", "comer": "comendo perto do fogo"}

## Cenas que mudam o sentido da ação.
const FAZENDO_CENA := {
	"funeral": "no enterro, com o povo", "casamento": "dançando no casamento", "festa": "dançando na festa",
	"nascimento": "vendo o bebê que nasceu", "prece": "rezando com o povo", "guerra": "na guerra",
	"migracao": "mudando de lugar com o povo", "colheita": "na colheita, com o povo",
	"construcao": "erguendo a obra nova"}

## O que alguém pensa, pelo traço (adulto e criança).
const TRACO := {
	"ambicioso": [["Um dia quem manda aqui sou eu", "Mereço mais do que tenho"], ["Quando crescer, vou mandar em todos", "Eu vou ser o chefe da brincadeira"]],
	"pacifico": [["Brigar não enche a barriga de ninguém", "Que dia calmo, assim é bom", "Paz é melhor que fartura"], ["Não gosto quando gritam", "Vamos brincar sem brigar"]],
	"rancoroso": [["Eu não esqueço o que me fizeram", "Quem me deve, um dia paga"], ["Ninguém mais pega o que é meu", "Ele me empurrou, vou contar"]],
	"curioso": [["O que será que há depois do morro?", "Por que a água do lago não acaba?", "Para onde vão as aves no frio?"], ["Por que o fogo dança?", "Aonde vai o sol de noite?"]],
	"devoto": [["É preciso agradecer pelo dia", "Hoje vou levar uma oferenda"], ["Mamãe diz que lá de cima nos veem", "Vou rezar igual aos grandes"]],
	"desconfiado": [["Não confio em quem chega de fora", "Tem gente aqui de olho no meu cesto"], ["Esse menino pegou minha pedra", "Não conto meu segredo pra ninguém"]],
	"generoso": [["Dá para repartir o meu cesto", "Ninguém aqui vai dormir com fome", "Quem tem pouco também pode dar"], ["Vou dar minha fruta ao pequeno", "Guardei um pedaço pro meu amigo"]],
	"engenhoso": [["Dá para fazer um cesto melhor que esse", "E se a lança fosse mais leve?"], ["Fiz um barquinho de folha!", "Vou fazer uma lança de graveto"]],
	"corajoso": [["Amanhã eu pego o porco sozinh{a}", "Não tenho medo da mata"], ["Quando crescer, vou caçar", "Eu subo na árvore mais alta"]],
	"medroso": [["Não gosto do escuro da mata", "E se o porco vier para cima?"], ["Tem bicho no escuro?", "Não vou longe da mamãe"]]}

const COSTUME := {
	"agua": "Bom que a água agora é guardada", "estocar": "Guardar comida é sabedoria",
	"festa_chuva": "Quero que chegue logo a festa da chuva", "lancas": "Com as lanças, ninguém nos pega",
	"oferendas": "As oferendas nos deixam em paz", "queimar_mortos": "Os mortos sobem com a fumaça",
	"tabu_tempestade": "Na tempestade, ninguém sai de casa"}

var m
var p
var g
var ctx: Dictionary = {}  # o que é igual para todo o povo, calculado uma vez (veja mundo.dica)
var adulto := true
var a := "o"              # fim de concordância da pessoa


func _init(mundo, pessoa, grupo, contexto: Dictionary = {}) -> void:
	m = mundo
	p = pessoa
	g = grupo
	ctx = contexto
	adulto = p.idade(m.ano()) >= 12
	a = "o" if p.sexo == "m" else "a"


## O que a pessoa faz, numa frase (a partir da ficha da hora: acao, detalhe, cena, x).
func fazendo(ficha: Dictionary) -> String:
	return _fazendo(ficha)


## As fontes do pensamento que só mudam com o dia (necessidades, memória, relações, o deus, o
## povo, os traços): [força, [frases], humor, sonho]. O mundo guarda por um dia.
func candidatos() -> Array:
	var cands: Array = []
	_necessidades(cands)
	_acontecimentos(cands)
	_relacoes(cands)
	_deus(cands)
	_povo(cands)
	_tracos(cands)
	cands.sort_custom(func(x, y): return x[0] > y[0])
	return cands


## [pensamento, humor] desta hora, a partir dos candidatos do dia (já em ordem de força) e do
## que a pessoa faz agora (o que se pensa fazendo aquilo, ali): a primeira frase, na ordem de
## preferência dela, com até 60 caracteres, que não está em `usadas` (o que outras pessoas já
## pensam nesta hora) nem em `proibidas` (o que ela mesma já pensou hoje, em outro bloco de 2
## horas). As frases do dia sobre um lugar ou uma ação não saem enquanto a pessoa já está ali ou
## fazendo aquilo (`_palavras_de_agora`). Sem nenhuma livre, fica sem pensamento.
func escolher(ficha: Dictionary, do_dia: Array, usadas: Dictionary, proibidas: Dictionary = {}) -> Array:
	var agora: Array = []
	_no_que_faz(agora, ficha)
	_do_momento(agora, ficha)
	var cands: Array = do_dia
	if not agora.is_empty():
		cands = do_dia.duplicate()
		for c in agora:
			c.append(true)        # [força, frases, humor, sonho, do momento]
			var i := 0
			while i < cands.size() and cands[i][0] >= c[0]:
				i += 1
			cands.insert(i, c)
	var bloco: int = m.passo / BLOCO
	if ficha.get("acao", "") == "dormir":
		for op in _dormindo(cands, bloco):
			var t := texto(op[0])
			if t.is_empty() or not (usadas.has(t) or proibidas.has(t)):
				return [t, op[1]]
	if cands.is_empty():
		return ["", _humor_calmo()]
	var evitar: Array = _palavras_de_agora(ficha)
	var sem := _semente()
	var k := 1 if cands[0][0] >= 9 else mini(3, cands.size())
	var ini := (bloco + sem) % k
	# Na primeira volta, nenhuma frase que alguém já pensa nesta hora; se todas estão tomadas
	# (mundos cheios), na segunda vale a de alguém de outro povo, nunca a de alguém do mesmo.
	for volta in 2:
		var r := _escolher_volta(cands, k, ini, bloco, sem, usadas, proibidas, evitar, volta == 1)
		if not r.is_empty():
			return r
	var c0: Array = cands[ini]
	return ["", c0[2] if not c0[2].is_empty() else _humor_calmo()]


func _escolher_volta(cands: Array, k: int, ini: int, bloco: int, sem: int, usadas: Dictionary, proibidas: Dictionary,
		evitar: Array, outro_povo: bool) -> Array:
	for n in cands.size():
		var c: Array = cands[(ini + n) % k] if n < k else cands[n]
		var frases: Array = c[1]
		var humor: String = c[2] if not c[2].is_empty() else _humor_calmo()
		var do_momento: bool = c.size() > 4
		var j0 := (bloco / k + sem / 7) % maxi(1, frases.size())
		for j in frases.size():
			var ix := (j0 + j) % frases.size()
			var t: String
			if frases[ix] is Array:
				# Preenchida uma vez e guardada nos candidatos do dia: as horas seguintes não
				# pagam a gramática de novo.
				t = texto(frases[ix])
				frases[ix] = t
			else:
				t = texto(frases[ix])
			if t.length() > PENSAMENTO_MAX or proibidas.has(t):
				continue
			if usadas.has(t) and (not outro_povo or usadas[t] == g.id):
				continue
			if not do_momento and _fala_de(t, evitar):
				continue
			return [t, humor]
	return []


## As palavras que um pensamento do dia não pode ter agora, pelo lugar e pelo que a pessoa faz:
## quem brinca na praia não pensa "amanhã vou na praia", quem pesca não pensa "quando crescer vou
## pescar".
func _palavras_de_agora(f: Dictionary) -> Array:
	var r: Array = []
	var x: float = f.get("x", -1.0)
	if x >= 0.0:
		match Cotidiano.zona_em(x):
			"praia":
				r.append_array(["praia", "concha", "areia"])
			"lago":
				r.append_array(["lago", "água", "peixe", "pesca"])
			"morro":
				r.append_array(["morro"])
	var acao: String = f.get("acao", "")
	var det: String = f.get("detalhe", "")
	if acao == "brincar" or det == "brincar":
		r.append_array(["brinc", "corr"])
	if acao == "pescar" or det in ["pescar_lanca", "golpear", "levar_vara"]:
		r.append_array(["pesca", "peixe"])
	if acao == "lenha" or det in ["catar_lenha", "carregar_feixe", "levar_machado"]:
		r.append_array(["lenha", "galho"])
	if acao in ["cacar", "carregar_caca"] or det in ["espreitar", "mirar", "arremessar", "apontar", "recolher_caca", "caca_no_pau", "levar_lanca"]:
		r.append_array(["porco", "caça", "lança"])
	if acao in ["fogueira", "cozinhar", "comer"] or det in ["vigia", "aticar"]:
		r.append_array(["fogo"])
	if acao == "rezar" or det == "reza_noturna":
		r.append_array(["rezar", "oferenda", "agradecer"])
	if acao == "tecer":
		r.append_array(["cesto"])
	return r


func _fala_de(t: String, palavras: Array) -> bool:
	var baixa := t.to_lower()
	for w in palavras:
		if baixa.contains(w):
			return true
	return false


## O que se pensa ali, fazendo aquilo, no momento: na praia, "Achei uma concha!"; pescando, "Esse
## lago tem peixe grande"; catando lenha, "Esse galho seco serve".
func _do_momento(cands: Array, f: Dictionary) -> void:
	var acao: String = f.get("acao", "")
	var det: String = f.get("detalhe", "")
	if acao in ["dormir", "andar", ""] or f.get("cena", {}).get("tipo", "") == "cacada":
		return
	var x: float = f.get("x", -1.0)
	var zona: String = Cotidiano.zona_em(x) if x >= 0.0 else ""
	if not adulto:
		match zona:
			"praia":
				_nec(cands, 4, ["Achei uma concha!", "A água está fria!", "Olha o caranguejo!", "Fiz um buraco na areia"], "alegre")
			"lago":
				_nec(cands, 4, ["Vi um peixe!", "A água está gelada!", "Um sapo pulou aqui!"], "alegre")
			"morro":
				_nec(cands, 4, ["Daqui de cima dá para ver tudo", "Achei uma pedra que brilha"], "alegre")
			_:
				if absf(x - _fogo()) < 20.0:
					_nec(cands, 4, ["O fogo estala!", "Quero ficar pertinho do fogo"], "alegre")
				else:
					_nec(cands, 4, ["Achei um ninho!", "Esse galho parece uma lança"], "alegre")
		return
	var frases: Array = []
	match det:
		"colher_arbusto":
			frases = ["As frutinhas estão maduras", "Esse arbusto está carregado", "Uma para o cesto, uma para a boca"]
		"cavar_raiz":
			frases = ["Raiz boa, das grandes", "A terra está dura hoje", "Mais uma e o cesto enche"]
		"catar_lenha":
			frases = ["Esse galho seco serve", "Mais uns galhos e volto", "Lenha boa para a noite"]
		"buscar_agua", "carregar_agua":
			frases = ["Pesa, mas a sede pesa mais", "Água limpa hoje"]
		"cozinhar":
			frases = ["Mais um pouco de lenha no fogo", "O cheiro já chama todo mundo"]
		"ninar":
			frases = ["Dorme, pequeno, dorme", "Esse aqui não quer dormir"]
	if frases.is_empty():
		match acao:
			"pescar":
				frases = ["Hoje o peixe não quer saber de mim", "Esse lago tem peixe grande", "Quieto, que eles sentem"]
			"tecer":
				frases = ["Mais umas voltas e o cesto fica pronto", "Esse trançado ficou bom"]
			"consertar":
				frases = ["Esse cabo não aguenta mais", "Amarrado assim, não solta"]
			"fogueira":
				frases = ["O fogo está bom hoje", "Que calor gostoso"]
			"construir":
				frases = ["Mais uma pedra e a parede sobe", "Essa obra vai ficar de pé"]
			"comer":
				frases = ["Comida quente, enfim", "Ninguém fala de boca cheia"]
	if not frases.is_empty():
		_nec(cands, 4, frases, "")


## Uma frase ainda por preencher: [modelo, variáveis]. Só vira texto (`texto`) quando é
## escolhida, para não pagar a gramática das opções que ninguém vê.
func _f(modelo: String, vars: Dictionary) -> Array:
	return [modelo, vars]


static func texto(x) -> String:
	if x is Array:
		return G.maiuscula(G.preencher(x[0], x[1], false))
	return G.maiuscula(String(x))


## A semente da pessoa: um número fixo dela, que espalha as escolhas entre pessoas parecidas.
func _semente() -> int:
	return absi((p.id * 2654435761 + p.nasc_ano * 40503 + p.nome.hash()) % 1000003)


# ---------------------------------------------------------------- fazendo

func _fazendo(f: Dictionary) -> String:
	var acao: String = f.get("acao", "")
	var det: String = f.get("detalhe", "")
	var cena: Dictionary = f.get("cena", {})
	var x: float = f.get("x", 0.0)
	var t := ""
	if acao == "dormir":
		t = "dormindo"
	elif FAZENDO_CENA.has(cena.get("tipo", "")) and acao != "andar":
		t = FAZENDO_CENA[cena["tipo"]]
	elif acao == "brincar" and cena.get("tipo", "") == "cacada":
		t = "correndo atrás dos caçadores"
	elif FAZENDO_DETALHE.has(det):
		t = FAZENDO_DETALHE[det]
	elif acao == "colher" and x < 140.0:
		t = "pescando na margem"
	else:
		t = FAZENDO_ACAO.get(acao, acao)
	if acao == "conversar" or det == "discutir":
		var outro := _com_quem(f)
		if not outro.is_empty():
			t += " com " + outro
	if acao == "cozinhar" and det in ["", "cozinhar"] and _caca_no_fogo():
		t = "cozinhando a caça"
	if not adulto and acao in ["parado", "andar"] and det == "":
		t = "correndo {lugar}" if acao == "andar" else "brincando {lugar}"
	return t.replace("{a}", a).replace("{lugar}", _lugar(x)).strip_edges()


## Onde a pessoa está, dito como se fala: perto do fogo, na vila, na praia...
func _lugar(x: float) -> String:
	var fogo := _fogo()
	if fogo >= 0.0 and absf(x - fogo) < 14.0:
		return "perto do fogo"
	if fogo >= 0.0 and absf(x - fogo) < 45.0:
		return "no acampamento" if g.estagio <= 1 else "na vila"   # no estágio 1, ainda é um acampamento
	match Cotidiano.zona_em(x):
		"lago":
			return "na beira do lago"
		"praia":
			return "na praia"
		"floresta":
			return "na mata"
		"morro":
			return "no morro"
	return ""


func _fogo() -> float:
	if ctx.has("fogo"):
		return ctx["fogo"]
	var x := -1.0
	for o in Cotidiano.construcoes_do_grupo(m, g):
		if o["tipo"] == "fogueira":
			x = o["x"]
	ctx["fogo"] = x
	return x


## Com quem a pessoa conversa: alguém do povo conversando a até 12 px.
func _com_quem(f: Dictionary) -> String:
	var melhor := ""
	var perto := 13.0
	for o in ctx.get("fichas", m.pessoas_visiveis()):
		if o["id"] == p.id or o.get("grupo", -1) != g.id or o["acao"] != f["acao"]:
			continue
		var d := absf(float(o["x"]) - float(f["x"]))
		if d < perto:
			perto = d
			melhor = o["nome"]
	return melhor


## A caça do povo já chegou ao fogo (a etapa `repartir` começou).
func _caca_no_fogo() -> bool:
	if not ctx.has("caca"):
		ctx["caca"] = _caca_no_fogo_agora()
	return ctx["caca"]


func _caca_no_fogo_agora() -> bool:
	var h: float = m.hora() + 0.5
	for c in m.cenas_ativas():
		if c["tipo"] == "cacada" and c.get("grupo", -1) == g.id and not c.get("vazia", false):
			for e in c.get("etapas", []):
				if e["etapa"] == "repartir" and h >= float(e["ini"]):
					return true
	return false


# ---------------------------------------------------------------- pensamento

## Os candidatos vêm em [força, [frases], humor, sonho]. Fica a fonte mais forte: uma
## necessidade urgente sozinha (força 9 ou mais); senão, a cada 2 horas, uma das três mais
## fortes, e a frase muda entre as variantes dela, numa ordem que sai da semente da pessoa.
## Quando a frase já está com outra pessoa do povo, passa para a seguinte: as outras variantes,
## depois as outras fontes, da mais forte para a mais fraca (veja `escolher`).


## Dormindo: o humor é "dormindo", ou o sono mexido quando há motivo (doença, fome, luto e
## aflição: "inquieto no sono"; frio, susto e medo: "sono leve"). O sonho vem da fonte mais
## forte que tem sonho: sempre, se ela pesa (força 5 ou mais); de vez em quando, se é fraca
## (um bloco de 2 horas em cada 3). Sem sonho, o pensamento fica vazio.
func _dormindo(cands: Array, bloco: int) -> Array:
	var humor := "dormindo"
	for c in cands:
		if c[0] < 4:
			break
		if c[2] in ["doente", "de luto", "faminto", "faminta", "aflito", "aflita", "amargurado", "amargurada"]:
			humor = "inquiet" + a + " no sono"
			break
		if c[2] in ["encolhido", "encolhida", "assustado", "assustada", "abalado", "abalada", "preocupado", "preocupada"]:
			humor = "sono leve"
			break
	var r: Array = []
	for c in cands:
		if c[3] is Array or not String(c[3]).is_empty():
			if c[0] >= 5 or (bloco + _semente()) % 3 == 0:
				r.append([c[3], humor])
			break
	# Sem sonho (ou com o mesmo sonho de outra pessoa), o pensamento fica vazio.
	r.append(["", humor])
	return r


func _humor_calmo() -> String:
	if not adulto:
		return "alegre"
	if p.tracos.has("medroso") or p.tracos.has("desconfiado"):
		return "desconfiad" + a
	if p.tracos.has("rancoroso") or p.tracos.has("ambicioso"):
		return "inquiet" + a
	return "tranquil" + a


func _nec(cands: Array, forca: int, frases: Array, humor: String, sonho = "") -> void:
	cands.append([forca, frases, humor, sonho])


func _necessidades(cands: Array) -> void:
	if p.doente > 0:
		_nec(cands, 10, ["O corpo arde, não consigo levantar", "Tomara que essa febre passe"] if adulto
			else ["Dói tudo, quero colo", "Não quero ficar doente"], "doente", "sonha que está bom de novo")
	if g.em_fome:
		_nec(cands, 9, ["Faz dias que ninguém come direito", "A barriga dói de fome", "Uma raiz, qualquer coisa serve"] if adulto
			else ["Quero comer, a barriga dói", "Mãe, tem comida?"], "faminto" if p.sexo == "m" else "faminta",
			"sonha com comida")
	var z = m.zonas.get(g.zona)
	if z != null and z.seca:
		_nec(cands, 7, ["Se não chover logo, a terra morre", "O lago está baixo demais"] if adulto
			else ["Por que não chove mais?"], "preocupad" + a, "sonha com chuva")
	if g.doenca_evento >= 0 and p.doente <= 0:
		_nec(cands, 7, ["Tomara que a doença não me pegue", "Quem será o próximo a cair doente?"] if adulto
			else ["Mamãe diz para não chegar perto dos doentes"], "aflit" + a, "sonha que a doença chega em casa")
	if m.estacao() == 3:
		_nec(cands, 4, ["Esse frio entra nos ossos", "Falta lenha para a noite"] if adulto
			else ["Que frio, quero ficar no fogo"], "encolhid" + a, "sonha com o calor do verão")
	if p.gravidez > 0:
		_nec(cands, 6, ["O bebê não para de chutar", "Falta pouco para o bebê chegar"], "esperançosa")
	if adulto and p.saude < 0.35:
		_nec(cands, 6, ["As pernas já não aguentam como antes", "Os ossos doem quando esfria"], "cansad" + a)


## Os acontecimentos dos últimos dias que a pessoa viveu ou que tocaram o povo.
func _acontecimentos(cands: Array) -> void:
	var hoje: int = m.dia_abs()
	var vistos := {}
	for i in range(p.memoria.size() - 1, -1, -1):
		var e = m.evento(p.memoria[i])
		if e == null or vistos.has(e.tipo):
			continue
		var dias: int = hoje - ((e.ano - 1) * m.DIAS_ANO + e.dia)
		if dias > RECENTE:
			break
		vistos[e.tipo] = true
		var deus := _termo_deus()
		var forca := 8 if dias <= 2 else 6
		match e.tipo:
			"morte":
				_morte(cands, e, forca)
			"nascimento":
				var bebe = m.pessoa(e.participantes[0]) if not e.participantes.is_empty() else null
				if bebe == null:
					continue
				var nb := G.termo(bebe.nome, bebe.sexo)
				if e.participantes.has(p.id) and bebe.id != p.id:
					_nec(cands, forca, [_f("{n} é tão pequenin{n:o|a}", {"n": nb}),
						_f("Tenho que cuidar bem de {n}", {"n": nb})], "contente", "sonha com " + bebe.nome)
				elif bebe.mae == p.mae and p.mae != -1 and bebe.id != p.id:
					_nec(cands, forca, [_f("Ganhei um{n:|a} irm{n:ãozinho|ãzinha}!", {"n": nb})] if not adulto
						else [_f("Nasceu {n}, mais um na família", {"n": nb})], "contente")
				elif bebe.id != p.id:
					_nec(cands, forca - 3, ["Nasceu mais um no povo", "Que bom ouvir choro de bebê"], "contente")
			"raio_divino", "fogo_divino":
				_nec(cands, forca, [_f("{o:d} mostrou a força {d:dele|dela}", {"d": deus}) if g.tem_crenca
					else "O fogo caiu do céu bem ali", "Ainda ouço o estrondo"] if adulto
					else ["O céu fez fogo, que medo!"], "assustad" + a, "sonha com o estrondo")
			"fogo_brando":
				_nec(cands, forca, [_f("{o:d} mandou o calor", {"d": deus}) if g.tem_crenca else "O céu acendeu nossa fogueira",
					"Que fogo bom, aquece e não queima", "Enfim, as mãos quentes"] if adulto
					else ["O fogo caiu do céu e não queimou!", "Agora não tem mais frio"], "aquecid" + a, "sonha com um fogo que não queima")
			"fartura_natural", "fartura_divina":
				var f2: Array = ["Nunca vi tanta comida", "Hoje ninguém dorme com fome"]
				if e.tipo == "fartura_divina" and g.tem_crenca:
					f2.push_front(_f("{o:d} encheu nossos cestos", {"d": deus}))
				_nec(cands, forca - 1, f2 if adulto else ["Comi até a barriga estufar!"], "contente")
			"prece_contrariada":
				var pediu: String = "Pedi " + {"seca": "chuva", "fome": "comida", "doenca": "a cura", "frio": "calor", "guerra": "proteção"}.get(
					e.dados.get("necessidade", ""), "ajuda")
				_nec(cands, 10 if e.participantes.has(p.id) and dias <= 2 else forca, [_f("{o:d} fez o contrário do que pedimos", {"d": deus}),
					pediu + ", e veio o castigo", _f("O que fizemos {a:d}?", {"d": deus})] if adulto
					else [_f("{o:d} está {d:zangado|zangada} com a gente", {"d": deus}), "Por que o céu fez isso?"],
					"revoltad" + a if p.fe < 0.0 else "aflit" + a, _f("sonha que {o:d} lhe vira as costas", {"d": deus}))
			"prece_atendida":
				if g.tem_crenca:
					_nec(cands, 10 if e.participantes.has(p.id) and dias <= 2 else forca, [_f("{o:d} ouviu a nossa prece", {"d": deus}),
						_f("Vou agradecer {a:d} hoje", {"d": deus})], "grat" + a)
			"prece_sem_resposta", "silencio", "desamparo":
				if g.tem_crenca:
					_nec(cands, 10 if e.participantes.has(p.id) and dias <= 2 else forca, [_f("Por que {o:d} não responde?", {"d": deus}),
						_f("{o:d} nos esqueceu", {"d": deus})] if adulto
						else [_f("{o:d} está bravo com a gente?", {"d": deus})], "aflit" + a)
			"ataque", "guerra_inicio":
				var outro = m.grupo(e.outro_grupo) if e.outro_grupo >= 0 else null
				var quem: String = ("os de " + outro.nome) if outro != null and outro.id != g.id else "eles"
				_nec(cands, forca, ["E se %s voltarem?" % quem, "Temos de guardar as lanças perto"] if adulto
					else ["Tenho medo dos estranhos"], "assustad" + a, "sonha que os estranhos voltam")
			"tempestade", "terremoto_divino", "diluvio", "terremoto":
				_nec(cands, forca - 1, ["A terra ainda treme na lembrança", "Quase perdemos as casas"] if adulto
					else ["O vento quis levar a casa!"], "abalad" + a, "sonha que a terra treme de novo")
			"eclipse", "cometa", "pressagio":
				_nec(cands, forca - 1, ["O que o céu quis dizer?", "Nunca vi o céu daquele jeito"] if adulto
					else ["O céu ficou estranho!"], "intrigad" + a)
			"fome_fim", "doenca_fim", "seca_fim":
				_nec(cands, forca - 2, ["Enfim, o pior passou", "Agora dá para respirar"], "aliviad" + a)
			"casamento":
				if e.participantes.has(p.id) and p.conjuge != -1:
					var c = m.pessoa(p.conjuge)
					if c != null:
						_nec(cands, forca, [_f("Agora {n} e eu temos uma casa", {"n": G.termo(c.nome, c.sexo)})], "apaixonad" + a,
							"sonha com " + c.nome)
			"novo_lider":
				var l = m.pessoa(g.lider) if g.lider >= 0 else null
				if l != null and l.id != p.id and adulto:
					_nec(cands, forca - 3, ["Agora quem manda é %s" % l.nome], "")
			"costume":
				if adulto:
					_nec(cands, forca - 3, [COSTUME.get(e.dados.get("costume", ""), "O povo mudou o jeito de fazer")], "")


func _morte(cands: Array, e, forca: int) -> void:
	if e.participantes.is_empty() or e.participantes[0] == p.id:
		return
	var morto = m.pessoa(e.participantes[0])
	if morto == null:
		return
	var nome := G.termo(morto.nome, morto.sexo)
	var laco := _laco(morto)
	if laco.is_empty():
		if morto.grupo == p.grupo and adulto:
			_nec(cands, forca - 4, [_f("Que pena de {n}", {"n": nome})], "")
		return
	var frases: Array
	if adulto:
		frases = [_f("Sinto falta de {n}", {"n": nome}), _f("{n} não volta mais", {"n": nome}),
			_f("Ainda ouço a voz de {n}", {"n": nome})]
	else:
		frases = ["Cadê %s?" % ("a mamãe" if laco == "mae" else ("o papai" if laco == "pai" else morto.nome)),
			_f("Quero {n} de volta", {"n": nome})]
	_nec(cands, forca + 1, frases, "de luto", "sonha com " + morto.nome)


## O laço com outra pessoa: "pai", "mae", "filho", "conjuge", "irmao" ou "".
func _laco(o) -> String:
	if o.id == p.pai:
		return "pai"
	if o.id == p.mae:
		return "mae"
	if p.filhos.has(o.id):
		return "filho"
	if o.id == p.conjuge or o.conjuge == p.id:
		return "conjuge"
	if (p.mae != -1 and o.mae == p.mae) or (p.pai != -1 and o.pai == p.pai):
		return "irmao"
	return ""


func _relacoes(cands: Array) -> void:
	# Rancor: o maior.
	var alvo := -1
	var maior := 0.4
	for id in p.rancores:
		if p.rancores[id] > maior and m.pessoas.has(id) and m.pessoas[id].vivo:
			maior = p.rancores[id]
			alvo = id
	if alvo != -1:
		var r = m.pessoas[alvo]
		var n := G.termo(r.nome, r.sexo)
		_nec(cands, 6 if maior > 0.7 else 5, [_f("Não perdoo {n}", {"n": n}),
			_f("{n} ainda vai me pagar", {"n": n}), _f("Não quero {n} perto de mim", {"n": n}),
			_f("Ainda me lembro do que {n} fez", {"n": n})] if adulto
			else [_f("Não brinco mais com {n}", {"n": n}), _f("{n} é chat{n:o|a}", {"n": n})], "magoad" + a)
	# Amor: o cônjuge vivo.
	if p.conjuge != -1 and m.pessoas.has(p.conjuge) and m.pessoas[p.conjuge].vivo:
		var c = m.pessoas[p.conjuge]
		var n2 := G.termo(c.nome, c.sexo)
		_nec(cands, 4, [_f("Gosto de ver {n} rir", {"n": n2}), _f("{n} me faz rir", {"n": n2}),
			_f("Com {n} por perto, o dia passa rápido", {"n": n2}), _f("À noite, {n} me espera no fogo", {"n": n2}),
			_f("Vou guardar a melhor fruta para {n}", {"n": n2})], "contente", "sonha com " + c.nome)
	# Saudade: um pai, mãe, filho ou cônjuge que já morreu.
	for id in [p.mae, p.pai, p.conjuge] + p.filhos:
		if id == -1:
			continue
		var o = m.pessoa(id)
		if o != null and not o.vivo:
			var n3 := G.termo(o.nome, o.sexo)
			_nec(cands, 3, [_f("Saudade de {n}", {"n": n3}), _f("{n} ia gostar de ver isso", {"n": n3}),
				_f("Lembrei de {n} hoje", {"n": n3}), _f("Que falta faz {n}", {"n": n3})], "saudos" + a, "sonha com " + o.nome)
			break
	# Os filhos pequenos.
	for id in p.filhos:
		if m.pessoas.has(id) and m.pessoas[id].vivo and m.pessoas[id].idade(m.ano()) <= 6:
			var f = m.pessoas[id]
			var nf := G.termo(f.nome, f.sexo)
			_nec(cands, 3, [_f("{n} cresce depressa", {"n": nf}), _f("{n} já anda para todo lado", {"n": nf}),
				_f("Tenho que ficar de olho em {n}", {"n": nf})], "contente")
			break


## O que a pessoa acha do deus, pelo nome que o povo dá a ele e pela fé dela.
func _deus(cands: Array) -> void:
	if not g.tem_crenca:
		if adulto and p.tracos.has("curioso"):
			_nec(cands, 2, ["Quem manda a chuva e o trovão?"], "")
		return
	var d := _termo_deus()
	var v := {"d": d}
	if not adulto:
		_nec(cands, 3, [_f("Mamãe diz que {o:d} vê tudo", v), _f("Será que {o:d} gosta de mim?", v),
			_f("De noite, {o:d} cuida da gente", v), _f("Vovó conta histórias {de:d}", v)], "")
	elif g.ceticos or p.fe < -0.4 or p.ferida_pelo_deus:
		_nec(cands, 5 if p.ferida_pelo_deus else 4, [_f("{o:d} nos esqueceu", v),
			_f("Rezar {a:d} para quê?", v), _f("{o:d} só tira, nunca dá", v)], "amargurad" + a,
			_f("sonha que {o:d} lhe vira as costas", v))
	elif p.fe > 0.5:
		_nec(cands, 4, [_f("{o:d} cuida de nós", v), _f("Hoje vou agradecer {a:d}", v), _f("Nada falta a quem confia {em:d}", v)], "seren" + a,
			_f("sonha com a voz {de:d}", v))
	elif g.silencios > 0:
		_nec(cands, 4, [_f("Por que {o:d} se cala?", v)], "inquiet" + a,
			_f("sonha que {o:d} volta a falar", v))
	else:
		_nec(cands, 2, [_f("Será que {o:d} nos ouve?", v)], "")


func _termo_deus() -> Dictionary:
	var nome: String = g.nome_deus
	if nome.is_empty():
		return G.termo("céu", "m", 1, true)
	return G.termo(nome.substr(nome.find(" ") + 1), g.genero_deus, 1, true)


## Opinião sobre o povo: os costumes, quem manda, o estoque, como reparte.
func _povo(cands: Array) -> void:
	if not adulto:
		_nec(cands, 2, ["Quero brincar mais um pouco", "Amanhã vou na praia de novo", "Quem chegar no fogo primeiro ganha!",
			"Achei uma pedra bonita", "Quando eu crescer vou pescar", "Vi um sapo na beira do lago!", "Ninguém me acha aqui",
			"Hoje eu corri mais que todo mundo", "Quero ver o porco de perto", "O céu tem tanta estrela!",
			"Vou fazer uma casinha de galho", "A água do lago é fria!"], "alegre")
		return
	for c in g.costumes:
		if not c["esquecido"] and COSTUME.has(c["tipo"]):
			_nec(cands, 2, [COSTUME[c["tipo"]]], "")
			break
	if g.lider != -1 and g.lider != p.id and m.pessoas.has(g.lider):
		var l = m.pessoas[g.lider]
		if (p.rancores.has(l.id) or p.tracos.has("ambicioso")) and l.id != p.conjuge:
			_nec(cands, 3, ["%s não sabe mandar" % l.nome, "Eu mandaria melhor que %s" % l.nome, "%s só pensa em si" % l.nome], "")
	if g.lider == p.id:
		_nec(cands, 3, ["O povo conta comigo", "Tenho de pensar no inverno"], "")
	if g.recursos == "acumula" and p.tracos.has("generoso"):
		_nec(cands, 3, ["Devíamos repartir mais o que temos"], "")
	if g.estoque > g.membros.size() * 30.0:
		_nec(cands, 2, ["O celeiro está cheio, que alívio"], "contente")


func _tracos(cands: Array) -> void:
	for t in p.tracos:
		if TRACO.has(t):
			var fr: Array = TRACO[t][0] if adulto else TRACO[t][1]
			_nec(cands, 1, fr.map(func(s): return s.replace("{a}", a)), "", "sonha que um bicho o persegue na mata".replace(" o ", " " + ("o" if a == "o" else "a") + " ") if t == "medroso" else "")


## O que se pensa fazendo certas coisas: a caçada, a vigia, a roda de histórias.
func _no_que_faz(cands: Array, f: Dictionary) -> void:
	if f.get("acao", "") == "brincar" and f.get("cena", {}).get("tipo", "") == "cacada":
		_nec(cands, 7, ["Lá vêm eles com o porco!", "Eu vi o porco no pau!", "Corre, que eles chegaram!"], "agitad" + a)
		return
	match f.get("detalhe", ""):
		"espreitar":
			_nec(cands, 6, ["Devagar... ele ainda não me viu", "Nem um galho pode estalar"], "atent" + a)
		"mirar", "arremessar":
			_nec(cands, 7, ["Agora ou nunca", "Só tenho uma lança"], "atent" + a)
		"apontar":
			_nec(cands, 6, ["Ali, perto da pedra!", "Vai, acerta ele!"], "agitad" + a)
		"recolher_caca", "caca_no_pau", "repartir":
			_nec(cands, 6, ["Hoje tem carne para todos", "Pesa, mas pesa bom"], "orgulhos" + a)
		"maos_vazias":
			_nec(cands, 6, ["O porco foi mais esperto hoje", "Amanhã a gente pega ele"], "frustrad" + a)
		"espeto":
			_nec(cands, 5, ["O cheiro da carne já me dá fome", "Lá vêm eles com a caça!"], "contente")
		"pescar_lanca", "golpear":
			_nec(cands, 6, ["Quieto, o peixe está bem ali", "Esse peixe não me escapa", "A água fria nos pés, e nada de peixe"], "atent" + a)
		"peixe_na_lanca":
			_nec(cands, 6, ["Peguei! E é dos grandes", "Hoje tem peixe no fogo"], "orgulhos" + a)
		"despejar":
			_nec(cands, 5, ["O cesto veio cheio do morro", "Ufa, que descida comprida"], "contente")
		"lavar":
			_nec(cands, 4, ["A água leva a sujeira e o cansaço", "Essas crianças não saem da água"], "tranquil" + a)
		"vigia", "cochilar":
			_nec(cands, 4, ["O fogo não pode apagar", "Algum bicho rondando lá fora?"], "sonolent" + a)
		"historias":
			_nec(cands, 4, ["Essa história eu nunca canso de ouvir"], "contente")

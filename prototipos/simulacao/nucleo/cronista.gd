extends RefCounted
## O cronista: lê os eventos do mundo e escreve a crônica em português,
## por gramática de frases. Escolhe o que importa a cada ano e não inventa
## fatos: tudo o que escreve está nos eventos.

const G = preload("res://nucleo/gramatica.gd")

const ORCAMENTO_ANO := 5
const LIMIAR := 5

const TRACO_RAIZ := {"ambicioso": "ambicios", "pacifico": "pacífic", "rancoroso": "rancoros",
	"curioso": "curios", "devoto": "devot", "desconfiado": "desconfiad", "generoso": "generos",
	"engenhoso": "engenhos", "corajoso": "corajos", "medroso": "medros"}

## Tipos que só servem de contexto: nunca viram frase própria.
const SILENCIOSOS := ["inicio", "rixa", "roubo", "casamento", "seca_inicio", "fome_inicio",
	"doenca_inicio", "fartura_natural"]

## Tipos que contam uma consequência: não ganham "No verão," na frente.
const SEM_ESTACAO := ["seca_fim", "fome_fim", "doenca_fim", "costume", "costume_esquecido",
	"lugar_nomeado", "nova_crenca", "deus_renomeado", "prece_atendida", "fusao", "extincao_grupo",
	"inverno_rigoroso"]

var m   # o mundo (nucleo/mundo.gd)
var rt := RandomNumberGenerator.new()
var _narrados: Dictionary = {}       # tipo -> [anos em que entrou na crônica]
var _primeiros: Dictionary = {}      # "tipo" e "tipo@grupo" já vistos
var _usados: Dictionary = {}         # ids de eventos já contados em outra frase


func _init(mundo) -> void:
	m = mundo


# ---------------------------------------------------------------- termos

func _p(id: int) -> Dictionary:
	if not m.pessoas.has(id):
		return G.termo("alguém", "m")
	var p = m.pessoas[id]
	return G.termo(p.nome, p.sexo)


func _g(id: int) -> Dictionary:
	if id < 0 or id >= m.grupos.size():
		return G.termo("um grupo", "m")
	return G.termo(m.grupos[id].nome, "m")


func _zona(chave: String) -> Dictionary:
	if not m.zonas.has(chave):
		return G.termo("região", "f", 1, true)
	var z = m.zonas[chave]
	return G.termo(z.nome, z.genero, 1, true)


## O lugar como o grupo o chama, se tiver dado nome; senão, o nome comum.
func _lugar(chave: String, grupo_id: int, ate_evento: int = 1 << 30) -> Dictionary:
	if not m.zonas.has(chave):
		return _zona(chave)
	var z = m.zonas[chave]
	if z.nomes.has(grupo_id) and z.nomes[grupo_id]["evento"] < ate_evento:
		return G.termo(z.nomes[grupo_id]["nome"], z.genero, 1, true)
	return _zona(chave)


func _deus(nome: String, genero: String) -> Dictionary:
	if nome.is_empty():
		return G.termo("deus", "m", 1, true)
	var resto := nome.substr(nome.find(" ") + 1)
	return G.termo(resto, genero, 1, true)


func _deus_do_grupo(gid: int) -> Dictionary:
	if gid < 0:
		return G.termo("deus", "m", 1, true)
	var g = m.grupos[gid]
	return _deus(g.nome_deus, g.genero_deus)


func _traco(id: int) -> String:
	var p = m.pessoas[id]
	var t: String = p.tracos[0]
	return G.flex(TRACO_RAIZ[t], p.sexo)


func _lista_pessoas(ids: Array) -> Dictionary:
	var nomes: Array = []
	var generos: Array = []
	for id in ids:
		if m.pessoas.has(id):
			nomes.append(m.pessoas[id].nome)
			generos.append(m.pessoas[id].sexo)
	return G.termo(G.lista(nomes), G.genero_conjunto(generos), nomes.size())


func _escolher(opcoes: Array) -> String:
	return opcoes[rt.randi_range(0, opcoes.size() - 1)]


func _frase(opcoes: Array, vars: Dictionary) -> String:
	return G.preencher(_escolher(opcoes), vars)


func _estacao(e) -> String:
	return ["primavera", "verão", "outono", "inverno"][e.dia / 10]


func _evento(id: int):
	if id < 0 or id >= m.eventos.size():
		return null
	return m.eventos[id]


# ---------------------------------------------------------------- crônica

func escrever(titulo: String, subtitulo: String) -> String:
	var linhas: PackedStringArray = []
	linhas.append("# " + titulo)
	linhas.append("")
	linhas.append("*" + subtitulo + "*")
	linhas.append("")
	linhas.append(_prologo())
	linhas.append("")
	var por_ano: Dictionary = {}
	var ultimo_ano := 1
	for e in m.eventos:
		if not por_ano.has(e.ano):
			por_ano[e.ano] = []
		por_ano[e.ano].append(e)
		ultimo_ano = maxi(ultimo_ano, e.ano)
	var ano_final: int = m.ano() - 1 if m.dia_do_ano() == 0 else m.ano()
	var quietos: Array = []
	for a in range(1, ano_final + 1):
		var paragrafo := _ano(a, por_ano.get(a, []))
		if paragrafo.is_empty():
			quietos.append(a)
		else:
			if not quietos.is_empty():
				linhas.append(_anos_quietos(quietos))
				linhas.append("")
				quietos.clear()
			linhas.append("### Ano %d" % a)
			linhas.append("")
			linhas.append(paragrafo)
			linhas.append("")
		if m.fim_do_mundo and _fim_no_ano(a):
			break
	if not quietos.is_empty():
		linhas.append(_anos_quietos(quietos))
		linhas.append("")
	linhas.append(_epilogo())
	return "\n".join(linhas)


func _fim_no_ano(a: int) -> bool:
	for e in m.eventos:
		if e.tipo == "fim_do_mundo":
			return e.ano == a
	return false


func _anos_quietos(anos: Array) -> String:
	rt.seed = m.semente * 7919 + anos[0]
	if anos.size() == 1:
		return "*" + _escolher(["O ano %d passou sem nada que a crônica precise guardar.",
			"No ano %d, nada de notável aconteceu.", "O ano %d foi calmo."]) % anos[0] + "*"
	return "*" + _escolher(["Os anos %d a %d passaram em paz.", "Do ano %d ao %d, a vida seguiu sem grandes acontecimentos.",
		"Entre os anos %d e %d, nada mudou o rumo do mundo."]) % [anos[0], anos[-1]] + "*"


## Escolhe os eventos do ano, escreve as frases e junta num parágrafo.
func _ano(a: int, evs: Array) -> String:
	var candidatos: Array = []
	var por_tipo_no_ano: Dictionary = {}
	for e in evs:
		if _usados.has(e.id) or SILENCIOSOS.has(e.tipo):
			continue
		var nota := _nota(e)
		if nota < LIMIAR:
			continue
		var n: int = por_tipo_no_ano.get(e.tipo, 0)
		nota -= n * 2
		por_tipo_no_ano[e.tipo] = n + 1
		candidatos.append([nota, e])
	candidatos.sort_custom(func(x, y): return x[0] > y[0] or (x[0] == y[0] and x[1].id < y[1].id))
	var escolhidos: Array = []
	for c in candidatos:
		if escolhidos.size() >= ORCAMENTO_ANO:
			break
		if c[0] >= LIMIAR:
			escolhidos.append(c[1])
	escolhidos.sort_custom(func(x, y): return x.id < y.id)
	var frases: PackedStringArray = []
	var est_anterior := ""
	for e in escolhidos:
		if _usados.has(e.id):
			continue
		rt.seed = m.semente * 100003 + e.id
		var f := _texto(e)
		if f.is_empty():
			continue
		_usados[e.id] = true
		if not _narrados.has(e.tipo):
			_narrados[e.tipo] = []
		_narrados[e.tipo].append(a)
		_primeiros[e.tipo] = true
		_primeiros[e.tipo + "@" + str(e.grupo)] = true
		if e.tipo == "costume_esquecido":
			_primeiros["esq@" + str(e.dados["origem"])] = true
		var est := _estacao(e)
		if est != est_anterior and not SEM_ESTACAO.has(e.tipo) and rt.randf() < 0.55:
			var abertura := ("No " if est == "verão" or est == "outono" or est == "inverno" else "Na ") + est
			if est_anterior == "" and rt.randf() < 0.5:
				abertura += " do ano %d" % a
			f = abertura + ", " + _minuscula_inicial(f)
		est_anterior = est
		frases.append(G.maiuscula(f))
	if a % 10 == 0:
		frases.append(_censo(a))
	return " ".join(frases)


## Põe em minúscula a primeira letra, salvo se a frase começa por um nome próprio.
func _minuscula_inicial(f: String) -> String:
	var primeira := f.split(" ")[0].strip_edges().trim_suffix(",")
	for p in m.pessoas.values():
		if p.nome == primeira:
			return f
	for g in m.grupos:
		if g.nome == primeira:
			return f
	return f.substr(0, 1).to_lower() + f.substr(1)


## Nota de importância para a crônica: a do evento, mais novidade, menos repetição.
func _nota(e) -> int:
	var n: int = e.importancia
	match e.tipo:
		"morte":
			var causa: String = e.dados["causa"]
			if causa in ["raio_natural", "raio_divino", "batalha", "fogo"]:
				return 0
			if causa == "culpado":
				n = 8
		"nascimento":
			if e.dados["motivo"] == "":
				return 0
		"prece":
			if not e.dados["primeira"] and e.dados["alvo"] == -1:
				n = 3
		"prece_atendida":
			n = 3
			if not _primeiros.has("prece_atendida"):
				n = 8
			elif not _primeiros.has("prece_atendida@" + str(e.grupo)) and m.grupos[e.grupo].origem.is_empty():
				n = 5
			elif not e.dados["falso_milagre"]:
				n = 6
			elif e.dados["necessidade"] in ["seca", "fome"]:
				n = 5
			elif e.dados["necessidade"] == "doenca":
				n = 4
		"prece_sem_resposta":
			if e.dados["morte"] == -1:
				n = 3
		"fome_fim":
			n = 4 + mini(e.dados["mortos"], 4)
			if e.dados["mortos"] == 0 and e.dados["dias"] < 15:
				n = 3
		"doenca_fim":
			n = 2 + mini(e.dados["mortos"], 5)
		"seca_fim":
			var ini = _evento(e.dados["inicio"])
			var dur := 0
			if ini != null:
				dur = (e.ano - ini.ano) * 40 + e.dia - ini.dia
			n = 5 if dur >= 18 else 3
		"tempestade":
			n = 2
			if not e.dados["mortos"].is_empty():
				n = 7
			elif e.dados["abrigos"] >= 2:
				n = 4
		"inverno_rigoroso":
			n = 3 + mini(_mortes_no_ano(e.ano, "frio"), 4)
		"lugar_nomeado":
			n = 6
		"nova_crenca":
			if e.dados["crenca"] in ["testando", "dormindo", "nao_existe", "favorece_outros"]:
				return 0
		"novo_lider":
			n = 5 if e.dados["disputa"] else 3
		"casamento_entre_grupos":
			n = 6 if e.dados["primeiro"] or e.dados["sabia"] else 2
		"sacerdote":
			n = 6 if not _primeiros.has("sacerdote@" + str(e.grupo)) else 4
		"costume_esquecido":
			if _primeiros.has("esq@" + str(e.dados["origem"])):
				return 0
			n = 6 if not _primeiros.has("costume_esquecido") else 5
		"mudanca":
			n = 6 if e.dados["primeira"] else 3
		"eclipse":
			n = 7 if not _primeiros.has("eclipse") else 5
	if not _primeiros.has(e.tipo):
		n += 2
	elif not _primeiros.has(e.tipo + "@" + str(e.grupo)):
		n += 1
	# Repetição recente cansa: perde nota o que já foi contado nos últimos anos.
	var recentes := 0
	for a in _narrados.get(e.tipo, []):
		if e.ano - a <= 8:
			recentes += 1
	n -= recentes / 2
	return n


func _mortos_entre(g1: int, g2: int, ate: int) -> int:
	var n := 0
	for e in m.eventos:
		if e.id >= ate:
			break
		if e.tipo == "ataque" and ((e.grupo == g1 and e.outro_grupo == g2) or (e.grupo == g2 and e.outro_grupo == g1)):
			n += e.dados["mortos"].size()
	return n


func _mortes_no_ano(a: int, causa: String) -> int:
	var n := 0
	for e in m.eventos:
		if e.ano == a and e.tipo == "morte" and e.dados["causa"] == causa:
			n += 1
	return n


func _censo(a: int) -> String:
	# Quantos viviam no fim do ano a: conta nascidos até ali e não mortos até ali.
	var por_grupo: Dictionary = {}
	for p in m.pessoas.values():
		if p.nasc_ano <= a and (p.vivo or p.morte_ano > a):
			var gid := _grupo_no_ano(p, a)
			if gid >= 0:
				por_grupo[gid] = por_grupo.get(gid, 0) + 1
	var total := 0
	var partes: Array = []
	for gid in por_grupo:
		total += por_grupo[gid]
	var ids: Array = por_grupo.keys()
	ids.sort()
	for gid in ids:
		partes.append("%s (%d)" % [m.grupos[gid].nome, por_grupo[gid]])
	if total == 0:
		return ""
	if partes.size() == 1:
		return "No fim do ano %d, %s pessoas viviam no mundo, todas em %s." % [a, _num(total), m.grupos[ids[0]].nome]
	return "No fim do ano %d, %s pessoas viviam no mundo: %s." % [a, _num(total), G.lista(partes)]


## Grupo de uma pessoa num ano passado, pelos eventos que a moveram.
func _grupo_no_ano(p, a: int) -> int:
	var gid: int = p.grupo
	# Desfaz as mudanças posteriores ao ano a, da mais recente para a mais antiga.
	for i in range(m.eventos.size() - 1, -1, -1):
		var e = m.eventos[i]
		if e.ano <= a:
			break
		if not e.participantes.has(p.id):
			continue
		match e.tipo:
			"separacao":
				gid = e.outro_grupo
			"casamento_entre_grupos":
				if e.participantes[0] == p.id:
					gid = e.dados["de"]
			"fusao":
				gid = e.grupo
			"conquista":
				gid = e.outro_grupo
			"culpado":
				gid = e.grupo
	return gid


func _num(n: int) -> String:
	return G.extenso(n, "f") if n <= 20 else str(n)


# ---------------------------------------------------------------- frases

func _texto(e) -> String:
	var v := {}
	if e.grupo >= 0:
		v["g"] = _g(e.grupo)
		v["deus"] = _deus(e.dados.get("_deus", ""), e.dados.get("_gdeus", "m"))
	if e.zona != "":
		v["lugar"] = _lugar(e.zona, e.grupo, e.id)
		v["zona"] = _zona(e.zona)
	if e.outro_grupo >= 0:
		v["outro"] = _g(e.outro_grupo)
	match e.tipo:
		"morte":
			return _morte(e, v)
		"nascimento":
			return _nascimento(e, v)
		"casamento_entre_grupos":
			v["a"] = _p(e.participantes[0])
			v["b"] = _p(e.participantes[1])
			v["de"] = _g(e.dados["de"])
			var t := ""
			if e.dados["primeiro"]:
				t = _frase(["{a}, de {de}, casou-se com {b} e foi viver em {g}. Foi o primeiro laço entre os dois povos.",
					"{b}, de {g}, tomou por esposa {a}, de {de}, e os dois povos passaram a se visitar."
					if m.pessoas[e.participantes[0]].sexo == "f" else
					"{a}, de {de}, casou-se com {b} e mudou-se para {g}, coisa que ninguém tinha feito antes."], v)
			else:
				t = _frase(["{a}, de {de}, casou-se com {b} e foi viver em {g}."], v)
			if e.dados["sabia"]:
				t += " " + _frase(["{a} levou consigo o segredo das sementes.",
					"Com {a} chegou a {g} o saber de plantar."], v)
			return t
		"novo_lider":
			v["p"] = _p(e.participantes[0])
			if e.dados["disputa"]:
				v["r"] = _p(e.participantes[1])
				return _frase(["{p} passou a guiar {g}, mas {r} não aceitou e guardou rancor.",
					"{g} escolheu {p} para guiar o grupo. {r} queria o lugar e nunca perdoou."], v)
			return _frase(["{p} passou a guiar {g}.", "{g} passou a ser {g:guiado|guiado} por {p}."], v)
		"fome_fim":
			v["n"] = G.termo(_num(e.dados["mortos"]), "f", e.dados["mortos"])
			v["d"] = G.termo(str(e.dados["dias"]))
			var ini = _evento(e.dados["inicio"])
			var causa := ""
			if ini != null and ini.dados.get("seca", false):
				causa = " por causa da seca"
			elif ini != null and ini.dados.get("inverno", false):
				causa = " no inverno"
			v["c"] = G.termo(causa)
			var pior := _pior_fome_antes(e)
			if e.dados["mortos"] >= 8 and e.dados["mortos"] > pior:
				v["nm"] = G.termo(str(e.dados["mortos"]))
				return _frase(["Veio a pior fome que o mundo tinha visto: {d} dias{c} em {g}, e {nm} mortos. As crianças foram as primeiras.",
					"{g} conheceu a maior fome da sua história{c}. Em {d} dias, morreram {nm}. Muitas cabanas ficaram vazias."], v)
			if e.dados["mortos"] == 0:
				return _frase(["{g} passou fome{c} por {d} dias, mas ninguém morreu.",
					"Houve fome em {g}{c}: {d} dias de barriga vazia, sem mortes."], v)
			return _frase(["{g} passou fome{c} por {d} dias, e {n} {n#pessoa morreu|pessoas morreram}.",
				"A fome{c} durou {d} dias em {g} e levou {n} {n#vida|vidas}.",
				"Foram {d} dias de fome{c} em {g}, com {nm} {nm#morto|mortos}."], v.merged({"nm": G.termo(G.extenso(e.dados["mortos"], "m") if e.dados["mortos"] <= 20 else str(e.dados["mortos"]), "m", e.dados["mortos"])}))
		"doenca_fim":
			var k: int = e.dados["mortos"]
			v["n"] = G.termo(_num(k), "f", k)
			if k == 0:
				return _frase(["Uma febre passou por {g}, mas todos se curaram."], v)
			return _frase(["Uma febre correu {g} e levou {n} {n#vida|vidas}.",
				"A doença entrou em {g} e {n#matou|matou} {n} {n#pessoa|pessoas}.",
				"Uma tosse que não passava matou {n} {n#pessoa|pessoas} em {g}."], v)
		"seca_fim":
			var ini2 = _evento(e.dados["inicio"])
			var dur := 0
			if ini2 != null:
				dur = (e.ano - ini2.ano) * 40 + e.dia - ini2.dia
			v["d"] = G.termo(str(dur))
			var anterior := _seca_anterior(e)
			if anterior > 0:
				v["ant"] = G.termo(str(anterior))
				return _frase(["A seca voltou, como no ano {ant}: {d} dias sem chuva, até que o céu se abriu.",
					"De novo a chuva sumiu, como no ano {ant}. Foram {d} dias de seca."], v)
			return _frase(["A chuva parou de cair. A seca durou {d} dias, e os riachos viraram pedra.",
				"Veio uma seca de {d} dias. O lago encolheu e a mata secou."], v)
		"tempestade":
			if e.dados["mortos"].is_empty():
				v["n"] = G.termo(_num(e.dados["abrigos"]), "f", e.dados["abrigos"])
				if e.grupo < 0:
					return ""
				return _frase(["Uma tempestade sobre {o:zona} derrubou {n} cabanas de {g}.",
					"O vento de uma tempestade levou {n} cabanas de {g}."], v)
			var vid: int = e.dados["mortos"][0]
			v["p"] = _p(vid)
			v["lugar"] = _lugar(e.zona, e.grupo, e.id)
			var t2 := _frase(["Numa tempestade sobre {o:zona}, um raio matou {p}.",
				"Um raio caiu {em:zona} durante a tempestade e matou {p}.",
				"A tempestade trouxe raios para {o:zona}. Um deles acertou {p}."], v)
			return t2 + " " + _leitura_raio(e, vid, v)
		"inverno_rigoroso":
			var k2 := _mortes_no_ano(e.ano, "frio")
			v["n"] = G.termo(_num(k2), "f", k2)
			if k2 == 0:
				return _frase(["O inverno foi duro, mas ninguém morreu de frio.", "Veio um inverno de gelo."], v)
			return _frase(["O inverno foi de gelo: {n} {n#pessoa morreu|pessoas morreram} de frio.",
				"Um inverno duro matou {n} {n#pessoa|pessoas} de frio."], v)
		"eclipse":
			if not _narrados.has("eclipse"):
				return _frase(["No meio do dia, o sol escureceu. Os pássaros calaram, e todos olharam para o alto sem entender.",
					"O sol se apagou no meio da tarde e voltou pouco depois. Ninguém soube dizer por quê."], v)
			return _frase(["O sol escureceu outra vez.", "De novo o sol se apagou no meio do dia."], v)
		"separacao":
			return _separacao(e, v)
		"mudanca":
			v["de"] = _zona(e.dados["de"])
			return _frase(["Com fome, {g} levantou acampamento {em:de} e foi buscar comida {em:zona}.",
				"{g} deixou {o:de}, onde a comida tinha acabado, e foi viver {em:zona}."], v)
		"expedicao":
			v["p"] = _p(e.dados["chefe"])
			var n2: int = e.dados["n"] - 1
			v["n"] = G.termo(G.extenso(n2, "f"), "f", n2)
			return _frase(["{p} partiu com {n} {n#pessoa|pessoas} da família para além da borda do mundo. Nunca voltaram.",
				"Sem lugar e sem comida, {p} e os seus atravessaram a borda do mundo. Ninguém soube deles."], v)
		"fusao":
			v["lista"] = _lista_pessoas(e.participantes)
			if e.participantes.size() == 1:
				return _frase(["{g} acabou: {lista}, {lista:o último|a última}, foi viver em {outro}."], v)
			return _frase(["Os últimos de {g}, {lista}, juntaram-se a {outro}. {g} deixou de existir.",
				"{g} acabou: {lista} foram viver em {outro}."], v)
		"extincao_grupo":
			return _frase(["Não restou ninguém em {g}.", "{g} desapareceu: morreu o último dos seus."], v)
		"conquista":
			v["n"] = G.termo(_num(e.participantes.size()), "f", e.participantes.size())
			v["venc"] = _g(e.outro_grupo)
			return _frase(["{g} venceu {venc} e levou os {n} sobreviventes para viver sob seu mando. {venc} deixou de existir, mas os vencidos guardaram seus costumes em segredo.",
				"Depois da derrota, {venc} não existia mais: os {n} que sobraram foram {venc:levados|levados} para {g}."], v)
		"ataque":
			return _ataque(e, v)
		"tregua":
			v["a"] = _g(e.grupo)
			v["b"] = _g(e.outro_grupo)
			if e.dados["motivo"] == "deus":
				return _frase(["A terra que se ergueu separou {a} e {b}, e ninguém ousou atravessá-la para lutar."], v)
			if _mortos_entre(e.grupo, e.outro_grupo, e.id) >= 3:
				return _frase(["{a} e {b}, cansados de enterrar os seus, fizeram as pazes {em:zona}.",
					"Depois de tantos mortos, {a} e {b} se encontraram {em:zona} e juraram paz."], v)
			return _frase(["Depois da luta, {a} e {b} se encontraram {em:zona} e juraram paz.",
				"{a} e {b} fizeram as pazes {em:zona}, antes que a briga crescesse."], v)
		"lugar_nomeado":
			return _lugar_nomeado(e, v)
		"costume":
			return _costume(e, v)
		"costume_esquecido":
			return _costume_esquecido(e, v)
		"descoberta":
			v["p"] = _p(e.participantes[0])
			v["t"] = G.termo(_traco(e.participantes[0]))
			var t3 := _frase(["{p}, {p:o|a} {t}, notou que as sementes jogadas perto do acampamento brotavam. Começou a enterrá-las de propósito.",
				"{p}, {p:o|a} {t}, descobriu que uma semente enterrada vira planta."], v)
			if e.dados["fome_recente"]:
				t3 += " " + _frase(["Foi a fome que {p:o|a} fez olhar para o chão.", "A lembrança da fome pesou."], v)
			return t3
		"agricultura":
			return _frase(["{g} fez as primeiras roças {em:lugar}. Deixou de viver só do que achava e passou a plantar.",
				"Nas terras {de:lugar}, {g} plantou suas primeiras roças. Já não precisava andar atrás de comida."], v)
		"conhecimento_perdido":
			v["p"] = _p(e.participantes[0])
			return _frase(["Com a morte de {p}, {g} perdeu o segredo das sementes: ninguém mais sabia plantar.",
				"{p} morreu sem ensinar o que sabia. O saber de plantar morreu com {p:ele|ela}."], v)
		"crenca":
			return _crenca(e, v)
		"nova_crenca":
			return _nova_crenca(e, v)
		"deus_renomeado":
			v["antigo"] = _deus(e.dados["antigo"], "m" if e.dados["antigo"].begins_with("o ") else "f")
			v["novo"] = _deus(e.dados["novo"], e.dados["genero"])
			v["an"] = G.termo(e.dados["antigo"])
			v["nn"] = G.termo(e.dados["novo"])
			return _frase(["Depois disso, {g} deixou de chamar o deus de «{an}» e passou a chamá-{novo:lo|la} de «{nn}».",
				"Para {g}, o deus já não era «{an}»: passou a ser «{nn}»."], v)
		"sacerdote":
			v["p"] = _p(e.participantes[0])
			if e.dados.has("sonho"):
				return _frase(["Depois do sonho, {p} passou a falar {por:deus} em {g}."], v)
			return _frase(["{p} passou a falar {por:deus} em {g}. Era {p:o primeiro|a primeira} a rezar e {p:o último|a última} a duvidar.",
				"Em {g}, {p} tomou para si o cuidado das preces {a:deus}."], v)
		"edito":
			v["s"] = _p(e.participantes[0])
			v["alvo"] = _g(e.dados["alvo"])
			return _frase(["{s} anunciou que {o:deus} proibia qualquer trato com {alvo}. O deus nunca disse isso, mas {g} obedeceu.",
				"Em nome {de:deus}, {s} proibiu casamentos e trocas com {alvo}. Era vontade de {s}, não do deus."], v)
		"prece":
			return _prece(e, v)
		"prece_atendida":
			return _prece_atendida(e, v)
		"prece_sem_resposta":
			return _prece_sem_resposta(e, v)
		"silencio":
			return _silencio(e, v)
		"culpado":
			v["p"] = _p(e.participantes[0])
			if e.dados["para"] >= 0:
				v["para"] = _g(e.dados["para"])
				return _frase(["{p} foi {p:expulso|expulsa} e foi viver entre os de {para}."], v)
			return ""
		"chuva_divina", "raio_divino", "fartura_divina", "fogo_divino", "terra_erguida", "sonho":
			return _divino(e, v)
		"fim_do_mundo":
			return _frase(["Não restou ninguém. A Primeira Era terminou no ano %d, e o mundo ficou vazio, com o vento passando pelas cabanas." % e.ano], v)
	return ""


func _morte(e, v: Dictionary) -> String:
	var id: int = e.participantes[0]
	var p = m.pessoas[id]
	v["p"] = _p(id)
	v["i"] = G.termo(str(e.dados["idade"]))
	var papel := ""
	if e.dados["fundador"] and e.dados["lider"]:
		papel = "{p}, que {p:fundou|fundou} {g} e o guiava,"
	elif e.dados["fundador"]:
		papel = "{p}, {p:fundador|fundadora} de {g},"
	elif e.dados["lider"]:
		papel = "{p}, que guiava {g},"
	elif e.dados["sacerdote"]:
		papel = "{p}, que falava {por:deus} em {g},"
	elif p.feitos >= 3:
		papel = "{p}, {p:o|a} {t},"
		v["t"] = G.termo(_traco(id))
	else:
		papel = "{p}"
	var causa: String = e.dados["causa"]
	var t := ""
	match causa:
		"velhice":
			t = _frase([papel + " morreu de velhice aos {i} anos.", papel + " morreu dormindo, aos {i} anos.",
				"Morreu " + papel.trim_suffix(",") + ", aos {i} anos."], v)
		"fome":
			t = _frase([papel + " morreu de fome.", papel + " não resistiu à fome."], v)
		"frio":
			t = _frase([papel + " morreu de frio.", "O frio levou " + papel.trim_suffix(",") + "."], v)
		"doenca":
			t = _frase([papel + " morreu de febre aos {i} anos.", "A febre levou " + papel.trim_suffix(",") + "."], v)
		"parto":
			t = _frase([papel + " morreu ao dar à luz.", papel + " deu à luz e não sobreviveu ao parto."], v)
		"doenca_subita":
			if e.dados["idade"] < 10:
				t = _frase(["Morreu {p}, {p:filho|filha} pequen{p:o|a} de {mae}.", "{p} morreu com {i} anos, de uma febre que ninguém entendeu."],
					v.merged({"mae": _p(p.mae)}))
			else:
				t = _frase([papel + " morreu de repente, aos {i} anos."], v)
		"culpado":
			t = _frase(["{p} foi {p:apontado|apontada} como culpad{p:o|a} pelo silêncio {de:deus} e morreu a pedradas.",
				"Acharam em {p} {p:o culpado|a culpada}: {p:ele|ela} duvidava. Mataram-{p:no|na} diante de todos."], v)
		"exilio":
			t = _frase(["{p} foi {p:expulso|expulsa} como culpad{p:o|a} e morreu sozinh{p:o|a} no mato."], v)
		_:
			t = _frase([papel + " morreu."], v)
	if e.dados["sabia"] and m.grupos[e.grupo].estagio == 1 and not _ninguem_mais_sabe_registrado(e):
		t += " " + _frase(["{p:Ele|Ela} sabia plantar."], v)
	return t


func _ninguem_mais_sabe_registrado(e) -> bool:
	var prox = _evento(e.id + 1)
	return prox != null and prox.tipo == "conhecimento_perdido"


func _nascimento(e, v: Dictionary) -> String:
	var filho: int = e.participantes[0]
	v["f"] = _p(filho)
	v["mae"] = _p(e.participantes[1])
	v["pai"] = _p(e.participantes[2])
	match e.dados["motivo"]:
		"primeiro":
			return _frase(["Nasceu {f}, {f:o primeiro|a primeira} de {g}.",
				"Em {g} nasceu a primeira criança: {f}, {f:filho|filha} de {mae} e {pai}."], v)
		"lider":
			var lider_e_mae: bool = m.grupos[e.grupo].lider == e.participantes[1]
			v["l"] = v["mae"] if lider_e_mae else v["pai"]
			return _frase(["Nasceu {f}, {f:filho|filha} de {l}, que guiava {g}.",
				"{l}, que guiava {g}, teve {f:um filho|uma filha}: {f}."], v)
		"fome":
			return _frase(["Em plena fome, {mae} deu à luz {f}.", "No meio da fome, nasceu {f}, {f:filho|filha} de {mae}."], v)
		"entre_grupos":
			var mae = m.pessoas[e.participantes[1]]
			var de: int = mae.veio_de if mae.veio_de != -1 else m.pessoas[e.participantes[2]].veio_de
			v["de"] = _g(de)
			return _frase(["Nasceu {f}, {f:filho|filha} de {mae} e {pai}, com sangue de {g} e de {de}."], v)
		"linhagem":
			return _frase(["Nasceu {f}, {f:neto|neta} da linhagem dos primeiros.", "Nasceu {f}, {f:filho|filha} de {mae} e {pai}."], v)
	return ""


func _pior_fome_antes(e) -> int:
	var pior := 0
	for x in m.eventos:
		if x.id >= e.id:
			break
		if x.tipo == "fome_fim":
			pior = maxi(pior, x.dados["mortos"])
	return pior


func _seca_anterior(e) -> int:
	var ini = _evento(e.dados["inicio"])
	var anterior := -1
	for x in m.eventos:
		if x.id >= e.id:
			break
		if x.tipo == "seca_fim" and _usados.has(x.id) and (ini == null or x.id < ini.id):
			anterior = x.ano
	return anterior


func _separacao(e, v: Dictionary) -> String:
	v["f"] = _p(e.dados["fundador"])
	v["t"] = G.termo(_traco(e.dados["fundador"]))
	v["pai"] = _g(e.outro_grupo)
	v["novo"] = _g(e.grupo)
	var n: int = e.dados["n"]
	v["n"] = G.termo(_num(n), "f", n)
	var t := ""
	match e.dados["causa"]:
		"migracao":
			t = _frase(["{f}, {f:o|a} {t}, cansou de dividir pouca comida. Partiu com {n} pessoas para {o:zona} e ali fundou {novo}.",
				"{pai} já não cabia {em:origem}. {f}, {f:o|a} {t}, levou {n} pessoas para {o:zona} e fundou {novo}.",
				"Com {f} à frente, {n} pessoas deixaram {pai} e fundaram {novo}, {em:zona}."],
				v.merged({"origem": _zona(e.dados["zona_origem"])}))
		"briga":
			v["d"] = _p(e.dados["desafeto"])
			t = _frase(["A rixa entre {f} e {d} rachou {pai}. {f} partiu com os seus, {n} pessoas, e fundou {novo} {em:zona}.",
				"{f} não podia mais viver perto de {d}. Saiu de {pai} com {n} pessoas e fundou {novo} {em:zona}."], v)
		"cisma":
			if e.dados.get("novo_cetico", false):
				t = _frase(["Os que já não acreditavam, com {f} à frente, deixaram {pai} e fundaram {novo} {em:zona}. Lá ninguém reza.",
					"{pai} se partiu por causa do deus. {f} levou {n} pessoas que duvidavam e fundou {novo} {em:zona}."], v)
			else:
				var gn = m.grupos[e.grupo]
				v["dn"] = _deus(gn.nome_deus, gn.genero_deus)
				t = _frase(["Os que ainda rezavam, com {f} à frente, deixaram {pai}, que tinha deixado de crer, e fundaram {novo} {em:zona}. Ali o deus se chama {o:dn}.",
					"{f} não aceitou um povo sem deus. Saiu de {pai} com {n} fiéis e fundou {novo} {em:zona}, onde rezam a {o:dn}."], v)
	if e.dados.get("perdeu_estagio", false):
		t += " " + _frase(["Nenhum deles sabia plantar direito: {novo} voltou a viver de coleta."], v)
	if not _primeiros.has("separacao"):
		t += " " + _frase(["Pela primeira vez, havia mais de um povo no mundo.", "Era o primeiro povo nascido de outro."], v)
	return t


func _ataque(e, v: Dictionary) -> String:
	v["a"] = _g(e.grupo)
	v["b"] = _g(e.outro_grupo)
	var venceu_atacante: bool = e.dados["vencedor"] == e.grupo
	var mortos: Array = e.dados["mortos"]
	v["mortos"] = _lista_pessoas(mortos)
	var t := ""
	var atacante = m.grupos[e.grupo]
	var motivo := ""
	if atacante.proibido.has(e.outro_grupo):
		motivo = " em nome {de:deus}"
	t = _frase(["{a} atacou {b} {em:zona}" + motivo + ".", "Os de {a} caíram sobre {b} {em:zona}" + motivo + ".",
		"Houve luta {em:zona}: {a} atacou {b}" + motivo + "."], v)
	if venceu_atacante:
		t += " " + _frase(["{a} venceu e levou a comida guardada.", "{b} foi {b:derrotado|derrotado} e perdeu o que tinha guardado."], v)
	else:
		t += " " + _frase(["{b} resistiu, e {a} voltou de mãos vazias.", "{b} expulsou os atacantes."], v)
	if not mortos.is_empty():
		t += " " + _frase(["{mortos} {mortos#morreu|morreram} na luta.", "Na luta {mortos#morreu|morreram} {mortos}."], v)
	if e.dados.get("primeiro", false) and not _primeiros.has("ataque"):
		t += " " + _frase(["Foi a primeira vez que gente matou gente no mundo." if not mortos.is_empty() else "Foi a primeira briga entre povos."], v)
	return t


func _lugar_nomeado(e, v: Dictionary) -> String:
	v["nome"] = G.termo(e.dados["nome"])
	var origem = _evento(e.dados["origem"])
	# Dois povos dão nomes diferentes ao mesmo lugar, pelo mesmo fato.
	var par = null
	for x in m.eventos:
		if x.id > e.id and x.tipo == "lugar_nomeado" and x.dados["origem"] == e.dados["origem"] and x.grupo != e.grupo:
			par = x
			break
		if x.id > e.id + 6:
			break
	if par != null:
		_usados[par.id] = true
		v["g2"] = _g(par.grupo)
		v["nome2"] = G.termo(par.dados["nome"])
		if par.dados["nome"] == e.dados["nome"]:
			return _frase(["Os dois povos passaram a chamar o lugar de {nome}.", "Desde então, {g} e {g2} chamam o lugar de {nome}."], v)
		return _frase(["Desde então, os de {g} chamam o lugar de {nome}; os de {g2}, de {nome2}.",
			"O mesmo chão ganhou dois nomes: {nome} para {g}, {nome2} para {g2}."], v)
	match e.dados["motivo"]:
		"fome":
			return _frase(["Desde então, {g} chama {o:zona} de {nome}.", "{o:zona} passou a ser {o:zona} da fome: {nome}."], v)
		"raio":
			return _frase(["O lugar ganhou nome: {nome}.", "Desde aquele dia, {g} chama {o:zona} de {nome}."], v)
	return _frase(["Desde então, {g} chama {o:zona} de {nome}.", "Para {g}, {o:zona} virou {nome}."], v)


const IR_A_ZONA := {"morro": "sobe o morro", "praia": "desce à praia", "lago": "chega perto do lago",
	"floresta": "entra na floresta"}

const ACOES_COSTUME := {
	"estocar": "se guardava tanta comida para o inverno",
	"agua": "ninguém desperdiçava uma gota d'água",
	"festa_chuva": "se fazia a festa da chuva",
	"tabu_tempestade": "ninguém saía de casa em dia de tempestade",
	"queimar_mortos": "os mortos eram queimados, e não enterrados",
	"lancas": "os jovens treinavam com lanças",
	"oferendas": "se deixavam oferendas no começo de cada estação",
}


func _costume(e, v: Dictionary) -> String:
	var origem = _evento(e.dados["origem"])
	match e.dados["costume"]:
		"estocar":
			return _frase(["Depois daquela fome, {g} passou a guardar comida para o inverno. Nunca mais deixaram o celeiro vazio.",
				"A fome ensinou: desde então, {g} estoca comida e não come tudo o que colhe."], v)
		"agua":
			return _frase(["Depois da seca, {g} jurou nunca desperdiçar água."], v)
		"festa_chuva":
			return _frase(["O dia em que a chuva voltou virou festa em {g}: todo ano, celebram a chuva que {o:deus} mandou.",
				"{g} passou a festejar todo ano o dia da volta da chuva, em honra {de:deus}."], v)
		"tabu_tempestade":
			var vid := -1
			if origem != null:
				vid = origem.dados.get("vitima", -1)
				if vid == -1 and not origem.dados.get("mortos", []).is_empty():
					vid = origem.dados["mortos"][0]
			v["p"] = _p(vid)
			v["lugar"] = _zona(origem.zona if origem != null else e.zona)
			v["ir"] = G.termo(IR_A_ZONA.get(origem.zona if origem != null else e.zona, "sai de casa"))
			return _frase(["Desde a morte de {p}, ninguém em {g} {ir} em dia de tempestade.",
				"Nasceu ali um costume: quando o céu escurece, ninguém em {g} sai de casa. Lembram de {p}."], v)
		"queimar_mortos":
			return _frase(["Depois da febre, {g} passou a queimar os seus mortos, para que a doença não voltasse.",
				"Desde a febre, {g} não enterra mais ninguém: os mortos vão para o fogo."], v)
		"lancas":
			return _frase(["Depois da derrota, os jovens de {g} passaram a treinar com lanças.",
				"{g} não quis ser {g:pego|pego} desprevenido outra vez: os jovens começaram a treinar com lanças."], v)
		"oferendas":
			return _frase(["Desde então, {g} deixa oferendas para {o:deus} no começo de cada estação.",
				"Começaram as oferendas: frutas e peixe deixados no chão para {o:deus}."], v)
	return ""


func _costume_esquecido(e, v: Dictionary) -> String:
	v["acao"] = G.termo(ACOES_COSTUME.get(e.dados["costume"], "faziam o que faziam"))
	v["ano"] = G.termo(str(e.dados["ano_origem"]))
	return _frase(["Em {g}, já ninguém lembrava por que {acao}. O que aconteceu no ano {ano}, só a crônica guarda.",
		"Morreu o último que tinha visto o ano {ano}. Em {g}, {acao}, mas ninguém sabia mais dizer por quê."], v)


func _crenca(e, v: Dictionary) -> String:
	v["deus"] = _deus(e.dados["deus"], e.dados["genero"])
	v["deusn"] = G.termo(e.dados["deus"])
	var origem = _evento(e.dados["origem"])
	if e.participantes.is_empty():
		v["p"] = G.termo("alguém")
	else:
		v["p"] = _p(e.participantes[0])
	var t := ""
	match e.dados["natureza"]:
		"eclipse":
			t = _frase(["{p} disse que alguém, lá em cima, tinha fechado o olho, e que estava zangado. {g} passou a chamá-{deus:lo|la} de «{deusn}».",
				"Depois que o sol escureceu, {p} começou a dizer que havia alguém por trás do céu. Em {g}, deram-lhe um nome: «{deusn}»."], v)
		"raio":
			t = _frase(["{p} disse que o raio não caíra por acaso: alguém no céu escolhe quem fere. Chamaram-{deus:no|na} de «{deusn}».",
				"Depois do raio, {p} começou a falar de alguém que vive no céu e mata quando quer. {g} passou a temer «{deusn}»."], v)
		"chuva":
			t = _frase(["Quando a chuva voltou, {p} disse que alguém tinha ouvido os lamentos. {g} passou a chamá-{deus:lo|la} de «{deusn}».",
				"{p} jurou que a chuva não veio sozinha: alguém a mandou. Em {g}, chamaram-{deus:no|na} de «{deusn}»."], v)
		"doenca":
			t = _frase(["Diante da febre, {p} disse que alguém vem buscar os doentes à noite. {g} chamou-{deus:o|a} de «{deusn}».",
				"{p} disse que a febre tinha dono. Em {g}, passaram a falar {de:deus}."], v)
		"seca", "fome":
			t = _frase(["{p} disse que alguém, lá em cima, segurava a comida e a chuva. {g} passou a chamá-{deus:lo|la} de «{deusn}»."], v)
		"terra":
			t = _frase(["Diante da pedra que se ergueu, {p} disse que alguém a tinha levantado. Chamaram-{deus:no|na} de «{deusn}»."], v)
		"fartura":
			t = _frase(["Diante de tanta comida, {p} disse que alguém tinha dado aquilo. Chamaram-{deus:no|na} de «{deusn}»."], v)
		_:
			t = _frase(["{p} disse que havia alguém por trás das coisas. {g} chamou-{deus:o|a} de «{deusn}»."], v)
	if not _primeiros.has("crenca"):
		t += " " + _frase(["Foi a primeira crença do mundo.", "Assim nasceu a primeira fé."], v)
	return t


func _nova_crenca(e, v: Dictionary) -> String:
	match e.dados["crenca"]:
		"ouve_preces":
			return _frase(["Em {g}, firmou-se a certeza de que {o:deus} ouve quem pede.",
				"Desde então, {g} acredita que {o:deus} escuta as preces."], v)
		"castiga":
			v["p"] = _p(e.dados.get("vitima", -1))
			return _frase(["{g} passou a acreditar que {o:deus} castiga quem duvida, e que {p} tinha duvidado.",
				"Para {g}, {p} foi {p:castigado|castigada}. Desde então, quem duvida {de:deus} duvida em silêncio."], v)
		"martir":
			v["p"] = _p(e.dados.get("vitima", -1))
			return _frase(["Os devotos de {g} não viram castigo: para eles, {o:deus} chamou {p} para perto. Nasceu ali a lembrança de {p} como {p:santo|santa}.",
				"Para os mais fiéis de {g}, {p} não foi {p:castigado|castigada}, mas {p:escolhido|escolhida}."], v)
		"alem_da_borda":
			return _frase(["Os que ficaram contam que, além da borda, há terras onde ninguém passa fome. Outros dizem que a borda engole quem passa."], v)
		"lugar_sagrado":
			return _frase(["{o:zona} virou lugar sagrado para {g}. Ninguém ali corta árvore nem caça perto da pedra."], v)
	return ""


const TEXTOS_PRECE := {
	"seca": ["{deus}, que a chuva volte.", "Manda água, {deus}, que as crianças têm sede.", "{deus}, não nos deixes secar."],
	"fome": ["{deus}, dá-nos o que comer.", "{deus}, não deixes nossos filhos morrerem de fome."],
	"doenca": ["{deus}, leva embora a febre.", "{deus}, não leves mais ninguém."],
	"frio": ["{deus}, que o inverno acabe.", "{deus}, manda o sol de volta."],
	"guerra": ["{deus}, protege-nos {de:inimigo}.", "{deus}, que {o:inimigo} não volte."],
}


func _texto_prece(e, v: Dictionary) -> String:
	var nec: String = e.dados["necessidade"]
	var vv: Dictionary = v.duplicate()
	vv["deus"] = G.termo(_deus(e.dados["deus"], e.dados["genero_deus"])["t"])
	if e.dados["alvo"] != -1:
		vv["alvo"] = _p(e.dados["alvo"])
		return G.preencher(_escolher(["{deus}, cura {alvo:meu filho|minha filha}.", "{deus}, não leves {alvo}.",
			"Cura {alvo}, {deus}. {alvo:Ele|Ela} é tão pequen{alvo:o|a}."]), vv)
	var inimigo: int = e.dados.get("inimigo", -1)
	vv["inimigo"] = G.termo("inimigo", "m", 1, true) if inimigo < 0 else _g(inimigo)
	return G.preencher(_escolher(TEXTOS_PRECE.get(nec, ["{deus}, ajuda-nos."])), vv)


func _prece(e, v: Dictionary) -> String:
	v["p"] = _p(e.participantes[0])
	v["txt"] = G.termo(_texto_prece(e, v))
	if e.dados["primeira"]:
		return _frase(["{p} foi {p:o primeiro|a primeira} de {g} a rezar em voz alta: «{txt}»",
			"Pela primeira vez, alguém em {g} pediu ao céu. Foi {p}: «{txt}»"], v)
	if e.dados["alvo"] != -1:
		return _frase(["{p} rezou a noite toda: «{txt}»", "Com o filho ardendo em febre, {p} pediu: «{txt}»"
			if m.pessoas[e.participantes[0]].sexo == "f" else "{p} rezou junto da criança doente: «{txt}»"], v)
	return _frase(["Em {g}, rezava-se: «{txt}»", "{p} rezou: «{txt}»"], v)


func _prece_atendida(e, v: Dictionary) -> String:
	v["p"] = _p(e.participantes[0])
	var prece = _evento(e.dados["prece"])
	var resposta = _evento(e.dados["resposta"])
	var t := ""
	if prece != null and not _usados.has(prece.id):
		_usados[prece.id] = true
		v["txt"] = G.termo(_texto_prece(prece, v))
		t = _frase(["{p} tinha rezado: «{txt}» ", "Em {g}, {p} pediu: «{txt}» "], v)
	match e.dados["necessidade"]:
		"seca":
			t += _frase(["Dias depois, a chuva voltou, e ninguém em {g} duvidou de que {o:deus} tinha ouvido.",
				"Quando a chuva voltou, {g} agradeceu {a:deus}."], v)
		"fome":
			t += _frase(["A comida voltou, e {g} deu graças {a:deus}.", "A fome passou, e {g} viu nisso a mão {de:deus}."], v)
		"doenca":
			t += _frase(["A febre passou, e {p} contou a todos que {o:deus} tinha ouvido.", "Os doentes se levantaram. Em {g}, o crédito foi {de:deus}."], v)
		"guerra":
			t += _frase(["Os inimigos não voltaram. {g} agradeceu {a:deus}."], v)
		_:
			t += _frase(["O pedido se cumpriu, e {g} agradeceu {a:deus}."], v)
	if e.dados["falso_milagre"]:
		t += " " + _frase(["O deus não tinha feito nada.", "Foi só o tempo, mas quem iria dizer?",
			"A crônica sabe que foi acaso.", "O deus nada fez: o crédito era de graça."], v)
	elif resposta != null:
		t += " " + _frase(["Dessa vez, tinha sido mesmo o deus."], v)
	return t


func _prece_sem_resposta(e, v: Dictionary) -> String:
	v["p"] = _p(e.participantes[0])
	if e.dados["morte"] != -1 and e.participantes.size() > 1:
		v["a"] = _p(e.participantes[1])
		_usados[e.dados["morte"]] = true
		return _frase(["{p} rezou por {a} até a voz acabar. {a} morreu mesmo assim, e {p} nunca mais rezou.",
			"{p} implorou {a:pelo filho|pela filha}. {a} morreu, e daquele dia em diante {p} cuspia no chão quando falavam {de:deus}."], v)
	return _frase(["{p} rezou, e nada aconteceu.", "As preces de {g} ficaram sem resposta."], v)


func _silencio(e, v: Dictionary) -> String:
	if e.outro_grupo >= 0:
		v["outro"] = _g(e.outro_grupo)
	var t := ""
	match e.dados["explicacao"]:
		"pecamos":
			t = _frase(["Depois de tantas preces sem resposta, {g} concluiu que tinha pecado. Era preciso pagar.",
				"O deus não respondia, e {g} achou que a culpa era sua: tinham feito algo errado."], v)
			if e.participantes.size() > 0:
				v["c"] = _p(e.participantes[0])
				t += " " + _frase(["Procuraram {c:um culpado|uma culpada} e acharam {c}, que duvidava."], v)
		"testando":
			t = _frase(["{g} rezou e não foi {g:ouvido|ouvido}. Os mais firmes disseram que {o:deus} os estava testando, e se orgulharam de aguentar."], v)
		"dormindo":
			t = _frase(["Tantas preces sem resposta fizeram {g} dizer que {o:deus} dormia, ou tinha ido embora. Rezava-se cada vez menos.",
				"Em {g}, começaram a dizer que {o:deus} tinha partido. As preces viraram costume, sem fé."], v)
		"favorece_outros":
			t = _frase(["Em {g}, disseram que {o:deus} só ouvia {outro}. A inveja virou rancor.",
				"{g} via {outro} ser {outro:atendido|atendido} e concluiu que {o:deus} tinha escolhido os outros."], v)
		"sacerdotes_mentem":
			if e.participantes.size() > 0:
				v["s"] = _p(e.participantes[0])
			else:
				v["s"] = G.termo("o sacerdote")
			t = _frase(["Em {g}, cansados do silêncio, acusaram {s} de mentir em nome {de:deus}. {s} perdeu o lugar junto ao altar."], v)
		"nao_existe":
			t = _frase(["Depois de tanto silêncio, muitos em {g} deixaram de acreditar: não havia ninguém no céu. As preces pararam.",
				"{g} parou de rezar. Diziam que {o:deus} nunca tinha existido."], v)
	return t


func _divino(e, v: Dictionary) -> String:
	match e.tipo:
		"chuva_divina":
			if e.dados["em_seca"]:
				return _frase(["No meio da seca, choveu só sobre {o:zona}. Em volta, o céu continuou limpo.",
					"Uma nuvem parou sobre {o:zona} e choveu ali, e só ali, no meio da seca."], v)
			return _frase(["Choveu sobre {o:zona} num dia sem nuvens.", "Uma chuva fina caiu sobre {o:zona}, sem aviso."], v)
		"raio_divino":
			var vid: int = e.dados.get("vitima", -1)
			if vid == -1:
				return _frase(["Do céu limpo, um raio caiu {em:zona} e queimou a terra. Não acertou ninguém."], v)
			v["p"] = _p(vid)
			var t := ""
			if e.dados.get("era_lider", false):
				t = _frase(["Do céu limpo, um raio caiu {em:zona} e matou {p}, que guiava {g}.",
					"Um raio sem nuvem acertou {p}, que guiava {g}, diante de todos."], v)
			else:
				t = _frase(["Do céu limpo, um raio caiu {em:zona} e matou {p}.", "Sem nuvem nenhuma, um raio acertou {p} {em:zona}."], v)
			return t + " " + _leitura_raio(e, vid, v)
		"fartura_divina":
			if e.dados["em_fome"]:
				return _frase(["No meio da fome, {o:zona} se encheu de frutos e peixes, como nunca. {g} comeu até cansar.",
					"De um dia para o outro, {o:zona} transbordou de comida. A fome de {g} acabou ali."], v)
			return _frase(["{o:zona} deu comida como nunca: frutos caindo dos galhos e peixe na beira d'água."], v)
		"fogo_divino":
			var mortos: Array = e.dados.get("mortos", [])
			var t2 := _frase(["Um fogo sem origem queimou {o:zona}.", "{o:zona} pegou fogo sem que ninguém acendesse nada."], v)
			if not mortos.is_empty():
				v["m"] = _lista_pessoas(mortos)
				t2 += " " + _frase(["{m} {m#morreu|morreram} nas chamas."], v)
			var leitura: String = e.dados.get("leitura_" + str(e.grupo), "")
			if leitura == "maldicao":
				t2 += " " + _frase(["Em {g}, disseram que o lugar estava amaldiçoado."], v)
			elif leitura == "purificacao":
				t2 += " " + _frase(["Em {g}, disseram que o fogo tinha limpado o lugar."], v)
			return t2
		"terra_erguida":
			return _frase(["A terra se ergueu {em:zona}: onde era plano, surgiu uma pedra alta, do tamanho de dez homens. Ninguém viu mão nenhuma.",
				"Numa noite, o chão {de:zona} tremeu e se levantou. De manhã, havia ali uma pedra que ninguém tinha posto."], v)
		"sonho":
			var sid: int = e.dados.get("sonhador", -1)
			if sid == -1:
				return ""
			v["p"] = _p(sid)
			if e.dados["ideia"] == "agricultura":
				if e.dados["aceita"]:
					return _frase(["{p} sonhou com sementes que viravam árvores dentro da terra. Acordou e foi cavar.",
						"Num sonho, {p} viu mãos enterrando sementes. Acordou {p:decidido|decidida} a tentar."], v)
				return _frase(["{p} sonhou com sementes enterradas, mas achou que era bobagem e esqueceu."], v)
			if e.dados["aceita"]:
				return _frase(["{p} teve um sonho que não sabia explicar, e acordou certa de que alguém tinha falado com ela."
					if m.pessoas[sid].sexo == "f" else "{p} teve um sonho que não sabia explicar, e acordou certo de que alguém tinha falado com ele."], v)
			return _frase(["{p} teve um sonho estranho e não deu importância."], v)
	return ""


func _leitura_raio(e, vid: int, v: Dictionary) -> String:
	var leitura: String = e.dados.get("leitura", "azar")
	v["p"] = _p(vid)
	var gid: int = m.pessoas[vid].grupo
	v["g"] = _g(gid)
	var crente: bool = m.grupos[gid].tem_crenca
	match leitura:
		"castigo":
			if crente:
				return _frase(["Em {g}, disseram que era castigo.", "Ninguém em {g} teve dúvida: era castigo."], v)
			return _frase(["Em {g}, ninguém soube explicar, mas todos tiveram medo.", "O medo tomou conta de {g}."], v)
		"martir":
			return _frase(["{p} era {p:dos|das} que mais rezavam, e {g} ficou sem entender.", "Logo {p}, que tanto rezava."], v)
	return _frase(["A família de {p} nunca perdoou o céu.", "Os seus nunca esqueceram."], v)


# ---------------------------------------------------------------- moldura

func _prologo() -> String:
	var e = m.eventos[0]
	var g = m.grupos[0]
	var v := {"g": _g(0), "avo": _p(e.dados["avo"]), "avoa": _p(e.dados["avoa"])}
	return G.preencher("No princípio, a região estava vazia: a praia, o lago, a floresta e o morro. " +
		"Então chegaram doze coletores, uma única família: {avo} e {avoa}, os três filhos com quem tinham casado, e os netos. " +
		"Acamparam na floresta e se chamavam {g}. Não tinham vila, nem plantação, nem deus.", v)


func _epilogo() -> String:
	var linhas: PackedStringArray = []
	linhas.append("---")
	linhas.append("")
	linhas.append("## O mundo no fim da crônica")
	linhas.append("")
	var vivos: Array = m.grupos_vivos()
	if vivos.is_empty():
		linhas.append("Não restou ninguém. Ficaram as cabanas vazias e os nomes que os mortos deram aos lugares.")
	for g in vivos:
		var v := {"g": _g(g.id), "deus": _deus(g.nome_deus, g.genero_deus), "lugar": _zona(g.zona)}
		var partes: Array = []
		partes.append(G.preencher("**{g}** vive {em:lugar}, com %d pessoas" % g.membros.size(), v, false))
		partes[0] += ", e planta roças" if g.estagio == 2 else ", e ainda vive de coleta"
		if g.origem.has("pai"):
			var causas := {"migracao": "de uma migração", "briga": "de uma briga", "cisma": "de um cisma"}
			partes.append("nasceu %s em %s no ano %d" % [causas[g.origem["causa"]], m.grupos[g.origem["pai"]].nome, g.origem["ano"]])
		else:
			partes.append("é o povo mais antigo")
		if g.ceticos:
			partes.append("não reza a ninguém")
		elif g.tem_crenca:
			partes.append("chama o deus de «%s»" % g.nome_deus)
		else:
			partes.append("não tem nome para o deus")
		var cs: Array = []
		for c in g.costumes:
			var acao: String = ACOES_COSTUME.get(c["tipo"], c["tipo"])
			cs.append(acao.replace("se guardava", "guarda").replace("ninguém desperdiçava", "não desperdiça")
				.replace("se fazia", "faz").replace("ninguém saía", "não sai").replace("os mortos eram queimados, e não enterrados", "queima os mortos")
				.replace("os jovens treinavam", "treina os jovens").replace("se deixavam oferendas", "deixa oferendas")
				+ (" (a origem foi esquecida)" if c["esquecido"] else " (desde o ano %d)" % c["ano"]))
		if not cs.is_empty():
			partes.append("costumes: " + "; ".join(PackedStringArray(cs)))
		linhas.append("- " + "; ".join(PackedStringArray(partes)) + ".")
	var extintos: Array = []
	for g in m.grupos:
		if g.extinto:
			extintos.append(g.nome)
	if not extintos.is_empty():
		linhas.append("")
		linhas.append("Povos que deixaram de existir: " + G.lista(extintos) + ".")
	var nomes: Array = []
	for chave in m.ORDEM_ZONAS:
		var z = m.zonas[chave]
		for gid in z.nomes:
			nomes.append("%s (%s, para %s)" % [z.nomes[gid]["nome"], z.nome, m.grupos[gid].nome])
	if not nomes.is_empty():
		linhas.append("")
		linhas.append("Lugares com nome: " + G.lista(nomes) + ".")
	var nasc := 0
	var mortes := 0
	for e in m.eventos:
		if e.tipo == "nascimento":
			nasc += 1
		elif e.tipo == "morte":
			mortes += 1
	linhas.append("")
	linhas.append("Em %d anos nasceram %d pessoas e morreram %d." % [m.ano() - 1, nasc, mortes])
	return "\n".join(linhas)

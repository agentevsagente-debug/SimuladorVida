extends RefCounted
## O cronista: lê os eventos do mundo e escreve a crônica em português,
## por gramática de frases. Escolhe o que importa a cada ano e não inventa
## fatos: tudo o que escreve está nos eventos.

const G = preload("gramatica.gd")

const ORCAMENTO_ANO := 5
const LIMIAR := 5

const TRACO_RAIZ := {"ambicioso": "ambicios", "pacifico": "pacífic", "rancoroso": "rancoros",
	"curioso": "curios", "devoto": "devot", "desconfiado": "desconfiad", "generoso": "generos",
	"engenhoso": "engenhos", "corajoso": "corajos", "medroso": "medros"}

## Tipos que só servem de contexto: nunca viram frase própria.
const SILENCIOSOS := ["inicio", "linhagem", "rixa", "roubo", "casamento", "seca_inicio", "fome_inicio",
	"doenca_inicio", "fartura_natural"]

## Tipos que sempre entram na crônica, mesmo num ano cheio: os atos do deus e
## o que muda a lista de povos (sem eles, a crônica citaria povos que não apresentou).
const OBRIGATORIOS := ["chuva_divina", "raio_divino", "fartura_divina", "fogo_divino", "terra_erguida",
	"sonho", "separacao", "conquista", "fusao", "extincao_grupo", "crenca", "fim_do_mundo", "os_ultimos",
	"guerra_inicio", "guerra_fim", "seca_divina", "diluvio", "terremoto_divino", "pressagio", "cura",
	"peste", "profeta", "secularizacao", "renascimento"]

## Tipos que cansam quando se repetem: perdem nota a cada vez que já foram contados há pouco.
const CANSAM := ["prece_sem_resposta", "prece_atendida", "gemeos", "fome_fim", "doenca_fim", "seca_fim",
	"sacerdote", "novo_lider", "inverno_rigoroso", "casamento_entre_grupos"]

## Tipos que contam uma consequência: não ganham "No verão," na frente.
const SEM_ESTACAO := ["seca_fim", "fome_fim", "doenca_fim", "costume", "costume_esquecido",
	"lugar_nomeado", "nova_crenca", "deus_renomeado", "prece_atendida", "fusao", "extincao_grupo",
	"inverno_rigoroso"]

## O mundo (nucleo/mundo.gd). Guardado como referência fraca, porque o mundo
## também guarda o cronista e as duas referências fortes nunca seriam liberadas.
var m:
	get:
		return _wm.get_ref()
var _wm: WeakRef
var rt := RandomNumberGenerator.new()
var _narrados: Dictionary = {}       # tipo -> [anos em que entrou na crônica]
var _primeiros: Dictionary = {}      # "tipo" e "tipo@grupo" já vistos
var _usados: Dictionary = {}         # ids de eventos já contados em outra frase
var anos_escritos: Dictionary = {}   # ano -> parágrafo ("" se o ano foi quieto)
var ultimo_ano_escrito: int = 0
var _cursor: int = 0                 # próximo evento ainda não lido
var cronicas_povos: Dictionary = {}  # id do grupo -> {ano: texto}: a história que o povo escreveu
# Índices para não percorrer a história inteira a cada frase (não são salvos; refeitos ao ler).
var _por_tipo: Dictionary = {}       # tipo -> eventos desse tipo, em ordem
var _por_tipo_ate: int = 0
var _nomes: Dictionary = {}          # nomes de pessoas e povos, para saber se a frase começa por nome próprio
var _nomes_pessoas_ate: int = 0
var _nomes_grupos_ate: int = 0


func _init(mundo) -> void:
	_wm = weakref(mundo)


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


## Monta de uma vez os índices que não são salvos. Chamado ao carregar um mundo, para que
## a primeira virada de ano depois não pague a história inteira num passo só.
func aquecer() -> void:
	_do_tipo("")
	_e_nome_proprio("")
	_indexar_ate(m.eventos.size())


## Os eventos de um tipo, em ordem. O índice cresce junto com a lista de eventos.
func _do_tipo(tipo: String) -> Array:
	var evs: Array = m.eventos
	while _por_tipo_ate < evs.size():
		var e = evs[_por_tipo_ate]
		if not _por_tipo.has(e.tipo):
			_por_tipo[e.tipo] = []
		_por_tipo[e.tipo].append(e)
		_por_tipo_ate += 1
	return _por_tipo.get(tipo, [])


func _e_nome_proprio(palavra: String) -> bool:
	while _nomes_pessoas_ate < m._proximo_id_pessoa:
		var p = m.pessoas.get(_nomes_pessoas_ate)
		if p != null:
			_nomes[p.nome] = true
		_nomes_pessoas_ate += 1
	while _nomes_grupos_ate < m.grupos.size():
		_nomes[m.grupos[_nomes_grupos_ate].nome] = true
		_nomes_grupos_ate += 1
	return _nomes.has(palavra)


func _evento(id: int):
	if id < 0 or id >= m.eventos.size():
		return null
	return m.eventos[id]


# ---------------------------------------------------------------- crônica

## Escreve os anos completos que faltam, até o ano a_final. Um ano escrito não
## muda mais: a crônica cresce ano a ano, como um livro.
func processar_ate(a_final: int) -> void:
	while ultimo_ano_escrito < a_final:
		var a := ultimo_ano_escrito + 1
		var evs: Array = []
		while _cursor < m.eventos.size() and m.eventos[_cursor].ano <= a:
			if m.eventos[_cursor].ano == a:
				evs.append(m.eventos[_cursor])
			_cursor += 1
		anos_escritos[a] = _ano(a, evs)
		_escrever_cronicas_dos_povos(a, evs)
		ultimo_ano_escrito = a


## Crônica de um período (a ausência): os anos que terminaram no período vêm da
## crônica oficial; o ano ainda em andamento é escrito à parte, sem marcar nada
## como contado, para que a crônica oficial desse ano saia inteira quando ele terminar.
func relato_periodo(ev_ini: int, ev_fim: int, ano_ini: int, ano_fim: int) -> String:
	var partes: PackedStringArray = []
	for a in range(ano_ini, ano_fim + 1):
		if a <= ultimo_ano_escrito:
			var t := texto_do_ano(a)
			if not t.is_empty():
				partes.append(t)
			continue
		var evs: Array = []
		for i in range(ev_ini, ev_fim):
			if m.eventos[i].ano == a:
				evs.append(m.eventos[i])
		var salvo := [_narrados.duplicate(true), _primeiros.duplicate(), _usados.duplicate()]
		var par := _ano(a, evs, false, LIMIAR - 1)
		_narrados = salvo[0]
		_primeiros = salvo[1]
		_usados = salvo[2]
		if not par.is_empty():
			partes.append("### Ano %d (até agora)

%s" % [a, par])
	if partes.is_empty():
		return "*Enquanto o deus esteve fora, nada de notável aconteceu.*"
	return "

".join(partes)


# ---------------------------------------------------------------- a crônica dos povos

## Povos que escrevem contam a própria história do seu jeito: o que o deus fez por eles,
## as vitórias que ele deu, os castigos que mereceram. Muitas vezes contradiz a crônica do deus.
func _escrever_cronicas_dos_povos(a: int, evs: Array) -> void:
	for g in m.grupos:
		if g.escrita_desde < 0 or g.escrita_desde > a:
			continue
		if g.extinto and not _tem_evento_do_grupo(evs, g.id):
			continue
		if not cronicas_povos.has(g.id):
			cronicas_povos[g.id] = {}
			cronicas_povos[g.id][a] = _origem_contada(g)
		var linhas: PackedStringArray = []
		for e in evs:
			var t := _linha_do_povo(g, e)
			if not t.is_empty() and not linhas.has(t):
				linhas.append(t)
			if linhas.size() >= 3:
				break
		if not linhas.is_empty():
			var antes: String = cronicas_povos[g.id].get(a, "")
			cronicas_povos[g.id][a] = (antes + " " if not antes.is_empty() else "") + " ".join(linhas)


func _tem_evento_do_grupo(evs: Array, gid: int) -> bool:
	for e in evs:
		if e.grupo == gid or e.outro_grupo == gid:
			return true
	return false


## O que o povo conta de si quando começa a escrever: a memória vira mito.
func _origem_contada(g) -> String:
	rt.seed = m.semente * 31337 + g.id
	var v := {"g": _g(g.id), "deus": _deus(g.nome_deus, g.genero_deus), "zona": _zona(g.zona)}
	if g.ceticos or not g.tem_crenca:
		return _frase(["No começo, nossos pais vieram para {o:zona} pelas próprias pernas, e com as próprias mãos fizeram {g}."], v)
	var t := _frase(["No começo, {o:deus} escolheu nossos pais entre todos e os trouxe para {o:zona}.",
		"Antes de tudo havia {o:deus}, e {o:deus} deu {o:zona} ao povo de {g}."], v)
	if g.origem.has("pai"):
		v["pai"] = _g(g.origem["pai"])
		t += " " + _frase(["Saímos de {pai} porque lá já não se ouvia {o:deus}.", "{pai} nos expulsou, mas {o:deus} estava conosco."], v)
	return t


func _linha_do_povo(g, e) -> String:
	rt.seed = m.semente * 7177 + e.id * 13 + g.id
	var v := {"g": _g(g.id), "deus": _deus(e.dados.get("_deus", g.nome_deus), e.dados.get("_gdeus", g.genero_deus))}
	if g.ceticos or not g.tem_crenca:
		v["deus"] = G.termo("sorte", "f", 1, true)
	if e.outro_grupo >= 0:
		v["outro"] = _g(e.outro_grupo if e.grupo == g.id else e.grupo)
	var nosso: bool = e.grupo == g.id
	match e.tipo:
		"prece_atendida":
			# Só as que a crônica do deus também contou: o povo escreve o que marcou.
			if nosso and _usados.has(e.id):
				match e.dados["necessidade"]:
					"seca":
						return _frase(["Pedimos chuva, e {o:deus} mandou chuva.", "A seca acabou porque rezamos."], v)
					"fome":
						return _frase(["Pedimos pão, e {o:deus} encheu os celeiros."], v)
					"doenca":
						return _frase(["{o:deus} curou os nossos doentes."], v)
				return _frase(["{o:deus} ouviu as nossas preces e nos atendeu."], v)
		"crenca", "deus_renomeado":
			if nosso:
				return _frase(["{o:deus} nos revelou o seu nome."], v)
		"costume":
			if nosso and _usados.has(e.id):
				return _frase(["Recebemos {de:deus} uma nova lei, e a cumprimos."], v)
		"conhecimento_perdido", "regressao":
			if nosso:
				return _frase(["Esquecemos o que os pais sabiam, e {o:deus} não nos deixou lembrar."], v)
		"ataque":
			if not (nosso or e.outro_grupo == g.id):
				return ""
			if e.dados["vencedor"] == g.id:
				return _frase(["{o:deus} nos deu a vitória sobre {outro}.", "Vencemos {outro}, porque {o:deus} lutou ao nosso lado."], v)
			return _frase(["{outro} nos atacou à traição.", "Sofremos nas mãos de {outro}, porque tínhamos pecado."], v)
		"fome_fim":
			if nosso and e.dados["mortos"] > 0:
				return _frase(["{o:deus} nos castigou com a fome, e nós merecíamos.", "Veio a fome, e aprendemos a obedecer."], v)
		"tregua":
			if nosso or e.outro_grupo == g.id:
				return _frase(["{outro} veio pedir paz, e nós concedemos.", "Perdoamos {outro}."], v)
		"guerra_fim":
			if (nosso or e.outro_grupo == g.id) and e.dados["vencedor"] == g.id:
				return _frase(["Terminou a guerra: {o:deus} quis a nossa vitória."], v)
		"separacao":
			if e.outro_grupo == g.id:
				v["novo"] = _g(e.grupo)
				return _frase(["Os ingratos de {novo} nos abandonaram."], v)
		"estagio":
			if nosso:
				return _frase(["{o:deus} nos ensinou um novo saber.", "Por graça {de:deus}, aprendemos o que nenhum povo sabia."], v)
		"chuva_divina", "fartura_divina", "cura":
			if nosso:
				return _frase(["{o:deus} mostrou que nos ama."], v)
		"raio_divino", "terremoto_divino", "diluvio", "fogo_divino", "seca_divina":
			if nosso or e.zona == g.zona:
				return _frase(["{o:deus} mostrou sua força, e tememos.", "Fomos castigados, e entendemos o porquê."], v)
		"conquista":
			if nosso:
				return _frase(["{outro} se curvou diante de nós."], v)
	return ""


## A história que um povo escreveu, em markdown. Vazio se ele nunca escreveu.
func cronica_do_povo(gid: int) -> String:
	if not cronicas_povos.has(gid):
		return ""
	var linhas: PackedStringArray = ["# A história de %s, contada pelos seus escribas" % m.grupos[gid].nome, ""]
	var anos: Array = cronicas_povos[gid].keys()
	anos.sort()
	for a in anos:
		linhas.append("**Ano %d.** %s" % [a, G.maiuscula(cronicas_povos[gid][a])])
		linhas.append("")
	return "\n".join(linhas)


## Texto de um ano já escrito, com título; vazio se o ano foi quieto ou ainda não foi escrito.
func texto_do_ano(a: int) -> String:
	var par: String = anos_escritos.get(a, "")
	if par.is_empty():
		return ""
	return "### Ano %d

%s" % [a, par]


## Junta os anos de ano_ini a ano_fim num texto só, resumindo os anos quietos.
func montar(ano_ini: int, ano_fim: int, titulo: String = "", subtitulo: String = "",
		com_prologo: bool = true, com_epilogo: bool = true) -> String:
	var linhas: PackedStringArray = []
	if not titulo.is_empty():
		linhas.append("# " + titulo)
		linhas.append("")
	if not subtitulo.is_empty():
		linhas.append("*" + subtitulo + "*")
		linhas.append("")
	if com_prologo:
		linhas.append(_prologo(ano_ini))
		linhas.append("")
	var quietos: Array = []
	for a in range(maxi(1, ano_ini), mini(ano_fim, ultimo_ano_escrito) + 1):
		var paragrafo: String = anos_escritos.get(a, "")
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
	if com_epilogo:
		linhas.append(_epilogo())
	return "
".join(linhas)


## Desfaz a escrita de um ano que ainda não terminou (quando um povo novo nasce no
## mesmo ano em que a era anterior se fechou).
func reabrir_ano(a: int) -> void:
	if ultimo_ano_escrito < a:
		return
	for k in range(a, ultimo_ano_escrito + 1):
		anos_escritos.erase(k)
	ultimo_ano_escrito = a - 1
	_cursor = 0
	while _cursor < m.eventos.size() and m.eventos[_cursor].ano < a:
		_cursor += 1


func escrever(titulo: String, subtitulo: String) -> String:
	var ano_final: int = m.ano() - 1 if m.dia_do_ano() == 0 else m.ano()
	processar_ate(ano_final)
	return montar(m.era_inicio_ano, ano_final, titulo, subtitulo)


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
func _ano(a: int, evs: Array, com_censo: bool = true, limiar: int = LIMIAR) -> String:
	var candidatos: Array = []
	var por_tipo_no_ano: Dictionary = {}
	for e in evs:
		if _usados.has(e.id) or SILENCIOSOS.has(e.tipo):
			continue
		var nota := _nota(e)
		if nota < limiar and not (OBRIGATORIOS.has(e.tipo) and nota > 0):
			continue
		var n: int = por_tipo_no_ano.get(e.tipo, 0)
		nota -= n * 2
		por_tipo_no_ano[e.tipo] = n + 1
		candidatos.append([nota, e])
	candidatos.sort_custom(func(x, y): return x[0] > y[0] or (x[0] == y[0] and x[1].id < y[1].id))
	var escolhidos: Array = []
	for c in candidatos:
		if OBRIGATORIOS.has(c[1].tipo):
			escolhidos.append(c[1])
	for c in candidatos:
		if escolhidos.size() >= ORCAMENTO_ANO:
			break
		if c[0] >= limiar and not escolhidos.has(c[1]):
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
	if com_censo and a % 10 == 0:
		var resumo := _resumo_da_decada(a)
		if not resumo.is_empty():
			frases.append(resumo)
		frases.append(_censo(a))
	return " ".join(frases)


## Põe em minúscula a primeira letra, salvo se a frase começa por um nome próprio.
func _minuscula_inicial(f: String) -> String:
	var primeira := f.split(" ")[0].strip_edges().trim_suffix(",")
	if _e_nome_proprio(primeira):
		return f
	return f.substr(0, 1).to_lower() + f.substr(1)


## Nota de importância para a crônica: a do evento, mais novidade, menos repetição.
func _nota(e) -> int:
	var n: int = e.importancia
	match e.tipo:
		"morte":
			var causa: String = e.dados["causa"]
			if causa in ["raio_natural", "raio_divino", "batalha", "fogo", "terremoto", "diluvio"]:
				return 0
			if m.pessoas[e.participantes[0]].feitos >= 2 and not _feito_de(e.participantes[0], e.id).is_empty():
				n += 2
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
		"ataque":
			if e.dados.get("batalha", 1) > 1 and e.dados["mortos"].size() < 2:
				n -= 2
		"gemeos", "cometa", "terremoto", "cultura", "reforma", "dependencia", "exigencia", "desamparo":
			n = maxi(n, 5)
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
	if e.tipo in CANSAM:
		n -= recentes
	return n


func _mortos_entre(g1: int, g2: int, ate: int) -> int:
	var n := 0
	for e in _do_tipo("ataque"):
		if e.id >= ate:
			break
		if (e.grupo == g1 and e.outro_grupo == g2) or (e.grupo == g2 and e.outro_grupo == g1):
			n += e.dados["mortos"].size()
	return n


## Uma linha com o que se repetiu na década: o que a crônica não contou um a um.
func _resumo_da_decada(a: int) -> String:
	var c := {"seca_fim": 0, "fome_fim": 0, "prece_atendida": 0, "prece_sem_resposta": 0, "ataque": 0,
		"nascimento": 0, "morte": 0}
	for tipo in c:
		var lista := _do_tipo(tipo)
		for i in range(lista.size() - 1, -1, -1):
			if lista[i].ano <= a - 10:
				break
			if lista[i].ano <= a:
				c[tipo] += 1
	var partes: Array = []
	if c["seca_fim"] >= 2:
		partes.append("%s secas" % G.extenso(c["seca_fim"], "f"))
	if c["fome_fim"] >= 2:
		partes.append("%s fomes" % G.extenso(c["fome_fim"], "f"))
	if c["ataque"] >= 2:
		partes.append("%s batalhas" % G.extenso(c["ataque"], "f"))
	if c["prece_atendida"] >= 3:
		partes.append("%s preces que pareceram atendidas" % _num(c["prece_atendida"]))
	if c["prece_sem_resposta"] >= 3:
		partes.append("%s preces sem resposta" % _num(c["prece_sem_resposta"]))
	if partes.is_empty():
		return ""
	var vida := "nasceram %s crianças e morreram %s pessoas" % [_num(c["nascimento"]), _num(c["morte"])]
	if c["morte"] == 0:
		vida = "nasceram %s crianças e ninguém morreu" % _num(c["nascimento"])
	return "Nos anos %d a %d houve %s; %s." % [a - 9, a, G.lista(partes), vida]


func _mortes_no_ano(a: int, causa: String) -> int:
	var n := 0
	var lista := _do_tipo("morte")
	for i in range(lista.size() - 1, -1, -1):
		var e = lista[i]
		if e.ano < a:
			break
		if e.ano == a and e.dados["causa"] == causa:
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
			if e.dados.get("zona_so", false):
				return _frase(["A chuva voltou {a:zona} depois de {d} dias de seca.", "Depois de {d} dias, choveu de novo {em:zona}."], v)
			if _chuva_divina_entre(ini2, e):
				return _frase(["Fora dali, a seca continuou: {d} dias sem chuva no resto da região.",
					"No resto da região, a seca durou {d} dias."], v)
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
			return _frase(["{p} partiu com {n} {n#pessoa|pessoas} para além da borda do mundo. Nunca voltaram.",
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
			v["n"] = G.termo(G.extenso(e.participantes.size(), "m"), "m", e.participantes.size())
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
		"descoberta_tecnica":
			v["p"] = _p(e.participantes[0])
			v["t"] = G.termo(_traco(e.participantes[0]))
			var tx := ""
			match e.dados["saber"]:
				"pedra":
					tx = _frase(["{p}, {p:o|a} {t}, aprendeu a cortar a pedra em blocos e a erguer paredes que o vento não leva.",
						"{p}, {p:o|a} {t}, descobriu como empilhar pedras cortadas sem que caíssem."], v)
				"metal":
					tx = _frase(["{p}, {p:o|a} {t}, viu uma pedra derreter no fogo e virar coisa dura e brilhante. Era o primeiro metal.",
						"{p}, {p:o|a} {t}, aprendeu a tirar metal da pedra no fogo alto."], v)
				"escrita":
					tx = _frase(["{p}, {p:o|a} {t}, começou a riscar sinais no barro para lembrar as coisas. Era a escrita.",
						"{p}, {p:o|a} {t}, inventou marcas que guardavam palavras."], v)
				"engenharia":
					tx = _frase(["{p}, {p:o|a} {t}, aprendeu a levar a água por canais e a fazer o vento moer o grão.",
						"{p}, {p:o|a} {t}, desenhou o primeiro canal e a primeira roda d'água."], v)
			if e.dados.get("motivo", "") == "guerra":
				tx += " " + _frase(["A guerra apressou a ideia."], v)
			elif e.dados.get("motivo", "") == "fome":
				tx += " " + _frase(["A lembrança da fome pesou."], v)
			return tx
		"estagio":
			match e.dados["estagio"]:
				3:
					return _frase(["{g} ergueu as primeiras casas de pedra, e um templo de degraus no meio delas. O templo virou o centro do povo.",
						"Em {g}, as cabanas deram lugar a casas de pedra. Os sacerdotes ganharam um templo e, com ele, força."], v)
				4:
					return _frase(["{g} passou a forjar metal: enxadas, facas e lanças com ponta que não quebra. As guerras ficariam mais duras.",
						"A forja de {g} não apagava mais. O metal mudou o trabalho e mudou a guerra."], v)
				5:
					return _frase(["{g} passou a escrever. As leis, os costumes e a história do povo começaram a ficar nas tabuletas, e já não dependiam da memória de ninguém.",
						"Em {g}, os escribas começaram a guardar tudo em tabuletas: as leis, os nomes do deus e a história do povo, contada do jeito deles."], v)
				6:
					return _frase(["{g} cavou canais e ergueu moinhos. A água chegava às roças mesmo sem chuva, e o povo passou a precisar menos {de:deus}.",
						"Com canais e moinhos, {g} já não olhava tanto para o céu. A chuva continuava bem-vinda, mas não era mais questão de vida ou morte."], v)
			return ""
		"regressao":
			var nomes_saber := {"pedra": "cortar pedra", "metal": "trabalhar o metal", "escrita": "escrever", "engenharia": "fazer canais e moinhos"}
			v["s"] = G.termo(nomes_saber.get(e.dados["saber"], e.dados["saber"]))
			return _frase(["Morreu o último que sabia {s}, e ninguém tinha aprendido. {g} perdeu o saber.",
				"Em {g}, já ninguém sabia {s}. O que fora feito começou a ruir."], v)
		"arquivo_salvou":
			v["p"] = _p(e.participantes[0])
			return _frase(["Morreram todos os que sabiam o ofício, mas as tabuletas guardavam o jeito. {p} leu e aprendeu: o saber não se perdeu.",
				"O arquivo salvou {g}: {p} reaprendeu nas tabuletas o que os mortos sabiam."], v)
		"estudo_do_ceu":
			return _frase(["Os sábios de {g} passaram a anotar o céu. Em pouco tempo já previam os eclipses, e os sinais do alto foram perdendo a força.",
				"Em {g}, contavam-se as luas e anotavam-se as estrelas. O céu deixou de assustar tanto."], v)
		"ruinas_saber":
			v["p"] = _p(e.participantes[0])
			v["povo"] = G.termo(e.dados["povo"])
			var nomes_s := {"agricultura": "plantar", "pedra": "cortar pedra", "metal": "trabalhar o metal",
				"escrita": "ler as marcas antigas", "engenharia": "fazer canais"}
			v["s"] = G.termo(nomes_s.get(e.dados["saber"], e.dados["saber"]))
			return _frase(["{p} passou dias nas ruínas de {povo} e voltou sabendo {s}.",
				"Nas ruínas de {povo}, {p} achou o que eles sabiam: aprendeu a {s}."], v)
		"mito_ruinas":
			v["povo"] = G.termo(e.dados["povo"])
			match e.dados["explicacao"]:
				"gigantes":
					return _frase(["{g} encontrou as ruínas de {povo} e disse que ali tinham vivido gigantes.",
						"Para {g}, as pedras de {povo} só podiam ter sido postas por gigantes."], v)
				"castigo":
					return _frase(["Diante das ruínas de {povo}, {g} disse que ali viveu um povo que o deus destruiu, e tomou cuidado para não fazer o mesmo.",
						"As ruínas de {povo} viraram aviso em {g}: era o que o deus fazia com quem o desagradava."], v)
			return _frase(["{g} encontrou as ruínas de {povo}. Diziam que tinha sido gente como eles, e que alguma coisa dera errado."], v)
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
			if e.dados.has("cura"):
				return _frase(["Quem tinha voltado da morte não podia calar: {p} passou a falar {por:deus} em {g}."], v)
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
		"livro_fechado", "novo_povo":
			return ""
		"chuva_divina", "raio_divino", "fartura_divina", "fogo_divino", "terra_erguida", "sonho", "seca_divina", "diluvio", "terremoto_divino", "pressagio", "cura":
			return _divino(e, v)
		"guerra_inicio":
			v["a"] = _g(e.grupo)
			v["b"] = _g(e.outro_grupo)
			v["nome"] = G.termo(e.dados["nome"])
			match e.dados["motivo"]:
				"fome":
					return _frase(["Começou a {nome}: {a}, com fome, foi buscar à força a comida de {b}."], v)
				"santa":
					return _frase(["Começou a {nome}: em nome {de:deus}, {a} pegou em lanças contra {b}."], v)
				"terra":
					return _frase(["Começou a {nome}: {a} e {b} disputavam a mesma terra {de:zona}."], v)
				"irmaos":
					return _frase(["Começou a {nome}: {a} e {b}, nascidos do mesmo povo, viraram inimigos."], v)
			return _frase(["Começou a {nome}: o rancor entre {a} e {b} virou guerra."], v)
		"guerra_fim":
			return _guerra_fim(e, v)
		"cultura":
			if e.dados["dimensao"] == "poder":
				v["l"] = _p(e.participantes[0]) if not e.participantes.is_empty() else G.termo("alguém")
				match e.dados.get("como", ""):
					"revolta":
						return _frase(["{g} se revoltou contra o templo. Os sacerdotes perderam o comando, e o povo voltou a ter um líder.",
							"Em {g}, gritaram que o templo mentia em nome {de:deus}. Os sacerdotes foram tirados do poder."], v)
					"golpe":
						return _frase(["{l} não esperou a vez: tomou o comando de {g} à força, e o conselho dos velhos se calou.",
							"Com lanças e promessas, {l} acabou com o conselho de {g} e passou a mandar sozinho."], v)
					"tirania":
						return _frase(["Cansado de um líder que mandava sozinho, {g} passou a decidir em conselho.",
							"Depois de anos sob um só, {g} sentou-se em roda: dali em diante, decidia-se juntos."], v)
					"templo":
						return _frase(["O templo de {g} ficou mais forte que o líder. {l}, que falava {por:deus}, passou a decidir tudo."], v)
				if e.dados["valor"] == "sacerdotes":
					return _frase(["Em {g}, quem passou a decidir foi o templo: os sacerdotes falavam {por:deus}, e o deus decidia tudo.",
						"O templo de {g} ficou mais forte que o líder. Dali em diante, guerra e paz eram decididas em nome {de:deus}."], v)
				return _frase(["Depois de tanta briga pelo comando, {g} passou a ser guiado por um conselho dos mais velhos.",
					"Em {g}, ninguém mais mandava sozinho: os mais velhos sentavam em roda e decidiam juntos."], v)
			if e.dados["dimensao"] == "recursos":
				return _frase(["Depois dos roubos da fome, {g} parou de dividir: cada família passou a guardar o que era seu.",
					"Em {g}, cada um passou a cercar o que tinha."], v)
			if e.dados["dimensao"] == "estranhos":
				if e.dados["valor"] == "desconfiada":
					return _frase(["{g} fechou-se aos de fora: não se casava mais com estrangeiros, e quem chegava era recebido com lanças.",
						"Depois de tanto sofrer nas mãos dos vizinhos, {g} passou a desconfiar de todo estrangeiro."], v)
				return _frase(["{g} passou a receber bem os de fora: um casamento com outro povo virava festa.",
					"Em {g}, quem vinha de fora era recebido com comida e lugar perto do fogo."], v)
			v["p"] = _p(e.participantes[0])
			match e.dados["valor"]:
				"queimam":
					return _frase(["Quando {p} morreu, {g} {p:o|a} queimou numa fogueira alta. Desde então, os mortos de {g} vão para o fogo."], v)
				"veneram":
					return _frase(["Quando {p} morreu, {g} guardou os ossos junto ao altar e passou a pedir {a:p} pelos vivos. Os mortos de {g} viraram ancestrais a quem se reza."], v)
			return _frase(["Quando {p} morreu, {g} {p:o|a} enterrou sob uma pedra. Desde então, os mortos de {g} vão para a terra."], v)
		"reforma":
			v["l"] = _p(e.participantes[0])
			v["c"] = G.termo(REFORMA_COSTUME.get(e.dados["costume"], "um costume antigo"))
			if e.dados["herdado"]:
				return _frase(["Com {l} à frente, a nova geração de {g} abandonou {c}, costume herdado dos avós.",
					"Em {g}, os jovens deixaram de lado {c}. Era coisa de outro povo, diziam."], v)
			return _frase(["Ninguém lembrava mais a razão, e {g} abandonou {c}.",
				"Com {l} à frente, {g} largou {c}: sem origem lembrada, o costume perdeu o sentido."], v)
		"dependencia":
			var t2 := _frase(["{g} já não se preparava para nada: {o:deus} sempre dava.",
				"Tantas preces atendidas fizeram {g} confiar no céu mais do que nas próprias mãos."], v)
			if e.dados["largou"] == "estocar":
				t2 += " " + _frase(["Deixaram de guardar comida para o inverno."], v)
			elif e.dados["largou"] == "agua":
				t2 += " " + _frase(["Deixaram de poupar água."], v)
			return t2
		"exigencia":
			return _frase(["As preces de {g} ficaram pequenas: pedia-se {a:deus} até sol para a pesca e sorte na caça.",
				"Em {g}, rezava-se por qualquer coisa: um peixe maior, um dia sem vento."], v)
		"desamparo":
			return _frase(["Dessa vez, {o:deus} não respondeu, e {g}, que tinha esquecido como se virar sozinho, pagou caro.",
				"O deus calou justo quando {g} mais dependia dele."], v)
		"cometa":
			v["n"] = G.termo(str(e.dados["noites"]))
			return _frase(["Uma estrela de cauda cruzou o céu por {n} noites. Ninguém dormia direito.",
				"Apareceu no céu uma luz com rabo, que ficou {n} noites e sumiu."], v)
		"terremoto":
			var k: int = e.dados["cabanas"]
			v["n"] = G.termo(G.extenso(k, "f"), "f", k)
			var t3 := _frase(["A terra tremeu."], v)
			if k > 0:
				t3 += " " + _frase(["{n#Caiu|Caíram} {n} {n#cabana|cabanas}."], v)
			var mortos_t: Array = e.dados["mortos"]
			if not mortos_t.is_empty():
				v["ms"] = _lista_pessoas(mortos_t)
				t3 += " " + _frase(["{ms} {ms#morreu|morreram} sob os escombros."], v)
			return t3
		"gemeos":
			v["f1"] = _p(e.participantes[0])
			v["f2"] = _p(e.participantes[1])
			v["mae"] = _p(e.participantes[2])
			return _frase(["{mae} deu à luz gêmeos, {f1} e {f2}. Uns viram bênção; outros, mau sinal."], v)
		"peste":
			return _frase(["Veio de longe uma peste. Entrou em todos os povos ao mesmo tempo, e não havia casa sem doente.",
				"Uma doença nova atravessou o mundo: febre, manchas e tosse, de povo em povo."], v)
		"profeta":
			v["p"] = _p(e.participantes[0])
			v["an"] = G.termo(e.dados["antigo"])
			v["nn"] = G.termo(e.dados["novo"])
			v["novo"] = _deus(e.dados["novo"], e.dados["genero"])
			if e.dados["aceito"]:
				return _frase(["{p} disse ter ouvido o deus de outro jeito: não era «{an}», era «{nn}». {g} acreditou, e o deus mudou de nome.",
					"Em {g}, {p} começou a pregar que o deus não era «{an}». Era «{nn}». Em poucos anos, todos rezavam assim."], v)
			return _frase(["{p} pregou em {g} que o deus não era «{an}», mas «{nn}». O templo chamou aquilo de heresia, e {p} saiu com os que {p:o|a} seguiam.",
				"O templo de {g} não aceitou {p}, que chamava o deus de «{nn}». Houve gritos, pedras, e os seguidores de {p} foram embora."], v)
		"secularizacao":
			v["dn"] = G.termo(e.dados.get("deus", ""))
			return _frase(["Em {g}, os sábios já explicavam a chuva e o raio. O templo foi esvaziando, e um dia ninguém mais chamou por «{dn}».",
				"{g} deixou de rezar. Ninguém proibiu nada: os canais davam água, as tabuletas davam respostas, e o deus foi ficando para os velhos."], v)
		"renascimento":
			v["dn"] = G.termo(e.dados.get("deus", ""))
			return _frase(["Fazia muito tempo que {g} não rezava. Diante do que viu, voltou a chamar por «{dn}», e o templo encheu de novo.",
				"O que aconteceu não tinha explicação. Em {g}, os que zombavam das preces foram os primeiros a ajoelhar."], v)
		"os_ultimos":
			var n: int = e.dados["restam"]
			v["n"] = G.termo(G.extenso(n, "f"), "f", n)
			return _frase(["{n#Restava|Restavam} só {n} {n#pessoa|pessoas} no mundo inteiro.",
				"O mundo encolheu até caber em volta de uma fogueira: {n#restava|restavam} {n} {n#pessoa|pessoas}."], v)
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
	elif p.feitos >= 2:
		var feito := _feito_de(id, e.id)
		if not feito.is_empty():
			t += " " + feito
	return t


## O que a pessoa fez de mais marcante, para lembrar quando ela morre. Prefere o que
## a crônica já contou, para o leitor reconhecer.
## Índice de eventos por pessoa, para achar depressa o que cada uma fez. Não é salvo:
## é refeito a partir dos eventos quando falta (por exemplo, depois de carregar).
var _por_pessoa: Dictionary = {}
var _indice_ate: int = 0


func _indexar_ate(fim: int) -> void:
	while _indice_ate < mini(fim, m.eventos.size()):
		var x = m.eventos[_indice_ate]
		var ids: Array = x.participantes.duplicate()
		for chave in ["fundador", "sonhador", "matador"]:
			if x.dados.has(chave):
				ids.append(x.dados[chave])
		for pid in ids:
			if not _por_pessoa.has(pid):
				_por_pessoa[pid] = []
			if _por_pessoa[pid].is_empty() or _por_pessoa[pid][-1] != _indice_ate:
				_por_pessoa[pid].append(_indice_ate)
		_indice_ate += 1


func _feito_de(pid: int, ate: int) -> String:
	var melhor := ""
	var melhor_nota := -1
	var matou := 0
	var v := {"p": _p(pid)}
	_indexar_ate(ate)
	for i in _por_pessoa.get(pid, []):
		if i >= ate:
			break
		var x = m.eventos[i]
		var nota := -1
		var f := ""
		match x.tipo:
			"separacao":
				if x.dados["fundador"] == pid:
					nota = 6
					v["g2"] = _g(x.grupo)
					f = _frase(["Tinha fundado {g2}.", "Foi {p:quem|quem} levou os seus a fundar {g2}."], v)
			"descoberta":
				if x.participantes[0] == pid:
					nota = 7
					f = _frase(["Tinha sido {p:o primeiro|a primeira} a plantar.", "Foi {p:quem|quem} descobriu que semente vira planta."], v)
			"crenca":
				if not x.participantes.is_empty() and x.participantes[0] == pid:
					nota = 7
					v["dn"] = G.termo(x.dados["deus"])
					f = _frase(["Foi {p:quem|quem} deu ao deus o nome de «{dn}»."], v)
			"sonho":
				if x.dados.get("sonhador", -1) == pid and x.dados.get("aceita", false):
					nota = 5
					f = _frase(["Um dia, tinha sonhado com o que ninguém sabia."], v)
			"prece_sem_resposta":
				if x.participantes[0] == pid and x.dados["morte"] != -1 and x.participantes.size() > 1:
					nota = 6
					v["a"] = _p(x.participantes[1])
					f = _frase(["Desde a morte de {a}, nunca mais tinha rezado.", "Nunca perdoou o deus pela morte de {a}."], v)
			"edito":
				if x.participantes[0] == pid:
					nota = 5
					v["al"] = _g(x.dados["alvo"])
					f = _frase(["Foi {p:quem|quem} proibiu, em nome do deus, o trato com {al}."], v)
			"casamento_entre_grupos":
				if x.participantes[0] == pid and x.dados.get("sabia", false):
					nota = 5
					v["g2"] = _g(x.grupo)
					f = _frase(["Tinha levado o saber de plantar para {g2}."], v)
			"morte":
				if x.dados.get("matador", -1) == pid:
					matou += 1
		if nota < 0:
			continue
		if _usados.has(x.id):
			nota += 3
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = f
	if melhor.is_empty() and matou >= 2:
		v["n"] = G.termo(G.extenso(matou, "f"), "f", matou)
		melhor = _frase(["Na guerra, tinha tirado {n} vidas."], v)
	return melhor


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
			var de: int = mae.veio_de if mae.veio_de != -1 and mae.veio_de != e.grupo else m.pessoas[e.participantes[2]].veio_de
			if de == -1 or de == e.grupo:
				return ""
			v["de"] = _g(de)
			return _frase(["Nasceu {f}, {f:filho|filha} de {mae} e {pai}, com sangue de {g} e de {de}."], v)
		"linhagem":
			return _frase(["Nasceu {f}, {f:neto|neta} da linhagem dos primeiros.", "Nasceu {f}, {f:filho|filha} de {mae} e {pai}."], v)
	return ""


func _chuva_divina_entre(ini, fim) -> bool:
	if ini == null:
		return false
	for i in range(ini.id, fim.id):
		if m.eventos[i].tipo == "chuva_divina":
			return true
	return false


func _pior_fome_antes(e) -> int:
	var pior := 0
	for x in _do_tipo("fome_fim"):
		if x.id >= e.id:
			break
		pior = maxi(pior, x.dados["mortos"])
	return pior


func _seca_anterior(e) -> int:
	var ini = _evento(e.dados["inicio"])
	var anterior := -1
	for x in _do_tipo("seca_fim"):
		if x.id >= e.id:
			break
		if _usados.has(x.id) and (ini == null or x.id < ini.id):
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
			var antes = _evento(e.id - 1)
			if antes != null and antes.tipo == "profeta" and not antes.dados.get("aceito", true):
				v["dnn"] = G.termo(antes.dados["novo"])
				return _frase(["Com {f} à frente, {n} pessoas fundaram {novo} {em:zona}, onde o deus se chama «{dnn}».",
					"Os seguidores de {f} fundaram {novo} {em:zona}. Ali, o deus se chama «{dnn}»."], v)
			if e.dados.get("novo_cetico", false):
				t = _frase(["Os que já não acreditavam, com {f} à frente, deixaram {pai} e fundaram {novo} {em:zona}. Lá ninguém reza.",
					"{pai} se partiu por causa do deus. {f} levou {n} pessoas que duvidavam e fundou {novo} {em:zona}."], v)
			else:
				var gn = m.grupos[e.grupo]
				v["dn"] = _deus(gn.nome_deus, gn.genero_deus)
				v["dnn"] = G.termo(gn.nome_deus)
				t = _frase(["Os que ainda rezavam, com {f} à frente, deixaram {pai}, que tinha deixado de crer, e fundaram {novo} {em:zona}. Ali o deus se chama «{dnn}».",
					"{f} não aceitou um povo sem deus. Saiu de {pai} com {n} fiéis e fundou {novo} {em:zona}, onde rezam {a:dn}."], v)
	if e.dados.get("perdeu_estagio", false):
		t += " " + _frase(["Nenhum deles sabia plantar direito: {novo} voltou a viver de coleta."], v)
	if not _primeiros.has("separacao"):
		t += " " + _frase(["Pela primeira vez, havia mais de um povo no mundo.", "Era o primeiro povo nascido de outro."], v)
	return t


const REFORMA_COSTUME := {"estocar": "o costume de guardar comida", "agua": "o cuidado com a água",
	"festa_chuva": "a festa da chuva", "tabu_tempestade": "o medo das tempestades",
	"queimar_mortos": "o costume de queimar os mortos", "lancas": "o treino com lanças",
	"oferendas": "as oferendas"}


func _guerra_fim(e, v: Dictionary) -> String:
	v["nome"] = G.termo(e.dados["nome"])
	v["a"] = _g(e.grupo)
	v["b"] = _g(e.outro_grupo)
	var anos: int = e.dados["anos"]
	var b: int = e.dados["batalhas"]
	var k: int = e.dados["mortos"]
	var conta := "%s %s e %s %s" % [G.extenso(b, "f"), "batalha" if b == 1 else "batalhas",
		G.extenso(k, "m") if k <= 20 else str(k), "morto" if k == 1 else "mortos"]
	if k == 0:
		conta = "%s batalhas e nenhum morto" % G.extenso(b, "f")
	if anos >= 1:
		conta = ("um ano, " if anos == 1 else "%s anos, " % G.extenso(anos, "m")) + conta
	v["conta"] = G.termo(conta)
	var t := ""
	match e.dados["desfecho"]:
		"tregua":
			t = _frase(["A {nome} acabou em trégua, depois de {conta}.", "Depois de {conta}, a {nome} terminou em paz."], v)
		"deus":
			t = _frase(["A {nome} acabou porque o céu se meteu no meio: {conta}."], v)
		"conquista":
			t = _frase(["A {nome} terminou com a conquista: {conta}."], v)
		"extincao":
			t = _frase(["A {nome} acabou porque um dos lados deixou de existir: {conta}."], v)
		_:
			t = _frase(["A {nome} esfriou sem acordo nem vencedor: {conta}, e ninguém sabia mais por que lutava."], v)
	var venc: int = e.dados["vencedor"]
	if venc >= 0 and e.dados["desfecho"] in ["tregua", "esfriou", "deus"]:
		v["v"] = _g(venc)
		t += " " + _frase(["{v} saiu dela mais forte."], v)
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
	var anterior := _ataque_recente(e)
	var guerra: int = e.dados.get("guerra", -1)
	if guerra >= 0 and e.dados.get("batalha", 1) > 1:
		v["nome"] = G.termo(m.guerras[guerra]["nome"])
		t = _frase(["Na {nome}, {a} atacou {b} {em:zona}" + motivo + ".", "A {nome} seguiu: {a} contra {b}, {em:zona}" + motivo + "."], v)
	elif anterior > 0:
		v["ant"] = G.termo(str(anterior))
		t = _frase(["A guerra entre {a} e {b} continuou: {a} voltou a atacar {em:zona}" + motivo + ".",
			"De novo {a} contra {b}" + motivo + ", como no ano {ant}.",
			"{a} não esqueceu o ano {ant} e atacou {b} outra vez."], v)
	else:
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


## Ano do último ataque narrado entre os mesmos dois povos, se foi há pouco.
func _ataque_recente(e) -> int:
	for i in range(e.id - 1, -1, -1):
		var x = m.eventos[i]
		if e.ano - x.ano > 6:
			break
		if x.tipo == "ataque" and _usados.has(x.id) and ((x.grupo == e.grupo and x.outro_grupo == e.outro_grupo) 				or (x.grupo == e.outro_grupo and x.outro_grupo == e.grupo)):
			return x.ano
	return -1


func _lugar_nomeado(e, v: Dictionary) -> String:
	v["nome"] = G.termo(e.dados["nome"])
	var origem = _evento(e.dados["origem"])
	# Dois povos dão nomes diferentes ao mesmo lugar, pelo mesmo fato.
	var par = null
	for i in range(e.id + 1, mini(e.id + 8, m.eventos.size())):
		var x = m.eventos[i]
		if x.tipo == "lugar_nomeado" and x.dados["origem"] == e.dados["origem"] and x.grupo != e.grupo:
			par = x
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
		"diluvio":
			t = _frase(["Depois da água, {p} disse que alguém tinha afogado o mundo de propósito. {g} passou a chamá-{deus:lo|la} de «{deusn}»."], v)
		"pressagio":
			t = _frase(["Diante do sinal no céu, {p} disse que alguém queria dizer alguma coisa. Chamaram-{deus:no|na} de «{deusn}»."], v)
		"cura":
			t = _frase(["{p} disse que a mão que levantou o doente era de alguém lá de cima. {g} passou a chamá-{deus:lo|la} de «{deusn}»."], v)
		"gemeos":
			t = _frase(["Diante dos gêmeos, {p} disse que alguém, lá em cima, tinha dado duas vidas de uma vez. {g} passou a chamá-{deus:lo|la} de «{deusn}»."], v)
		"cometa":
			t = _frase(["Diante da estrela de cauda, {p} disse que alguém riscava o céu para avisar. {g} passou a chamá-{deus:lo|la} de «{deusn}»."], v)
		"terremoto":
			t = _frase(["Depois que a terra tremeu, {p} disse que alguém, lá embaixo ou lá em cima, estava zangado. Chamaram-{deus:no|na} de «{deusn}»."], v)
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
			if e.dados.get("vitima", -1) == -1:
				return _frase(["{g} passou a acreditar que {o:deus} castiga, e se perguntou o que tinha feito.",
					"Em {g}, ninguém duvidou: era castigo. Só não sabiam de quê."], v)
			v["p"] = _p(e.dados.get("vitima", -1))
			return _frase(["{g} passou a acreditar que {o:deus} castiga quem duvida, e que {p} tinha duvidado.",
				"Para {g}, {p} foi {p:castigado|castigada}. Desde então, quem duvida {de:deus} duvida em silêncio."], v)
		"martir":
			v["p"] = _p(e.dados.get("vitima", -1))
			return _frase(["Os devotos de {g} não viram castigo: para eles, {o:deus} chamou {p} para perto. Nasceu ali a lembrança de {p} como {p:santo|santa}.",
				"Para os mais fiéis de {g}, {p} não foi {p:castigado|castigada}, mas {p:escolhido|escolhida}."], v)
		"alem_da_borda":
			return _frase(["Os que ficaram contam que, além da borda, há terras onde ninguém passa fome. Outros dizem que a borda engole quem passa."], v)
		"diluvio":
			return _frase(["Os que sobraram em {g} contam que {o:deus} lavou o mundo e poupou só os que merecia.",
				"Para {g}, a água foi o fim de um tempo e o começo de outro."], v)
		"lugar_sagrado":
			return _frase(["{o:zona} virou lugar sagrado para {g}. Ninguém ali corta árvore nem caça perto da pedra."], v)
	return ""


const TEXTOS_PRECE := {
	"seca": ["{deus}, que a chuva volte.", "Manda água, {deus}, que as crianças têm sede.", "{deus}, não nos deixes secar."],
	"fome": ["{deus}, dá-nos o que comer.", "{deus}, não deixes nossos filhos morrerem de fome."],
	"doenca": ["{deus}, leva embora a febre.", "{deus}, não leves mais ninguém."],
	"frio": ["{deus}, que o inverno acabe.", "{deus}, manda o sol de volta."],
	"guerra": ["{deus}, protege-nos {de:inimigo}.", "{deus}, que {o:inimigo} não volte."],
	"banal": ["{deus}, que amanhã faça sol para a pesca.", "{deus}, que a caça seja gorda.",
		"{deus}, que a festa seja bonita.", "{deus}, que o vento não leve o telhado."],
}


## Frase curta (até uns 40 caracteres) para a dica do cursor na moldura.
const LIMITE_CURTO := 40


func texto_curto(e) -> String:
	rt.seed = m.semente * 4099 + e.id
	var v := {}
	if e.grupo >= 0:
		v["g"] = _g(e.grupo)
	if e.outro_grupo >= 0:
		v["o"] = _g(e.outro_grupo)
	if not e.participantes.is_empty() and m.pessoas.has(e.participantes[0]):
		v["p"] = _p(e.participantes[0])
	var opcoes: Array = []
	match e.tipo:
		"prece":
			var nec: String = e.dados["necessidade"]
			if e.dados["alvo"] != -1:
				v["a"] = _p(e.dados["alvo"])
				opcoes = ["{p} pede a cura de {a}", "{p} pede a cura {a:do filho|da filha}", "{p} reza por um doente"]
			else:
				opcoes = {"seca": ["{p} pede chuva", "{g} pede chuva"], "fome": ["{p} pede comida", "{g} pede comida"],
					"doenca": ["{p} pede o fim da febre"], "frio": ["{p} pede o fim do frio"],
					"guerra": ["{p} pede proteção"], "banal": ["{p} pede sol para a pesca", "{p} pede uma caça gorda"]}.get(nec, ["{p} reza"])
		"fome_inicio":
			opcoes = ["Fome em {g}"]
		"doenca_inicio":
			opcoes = ["Febre em {g}"] if not e.dados.has("peste") else ["Peste em {g}"]
		"ataque":
			opcoes = ["{g} ataca {o}"]
		"os_ultimos":
			v["n"] = G.termo(G.extenso(e.dados["restam"], "f"), "f", e.dados["restam"])
			opcoes = ["{n#Resta|Restam} só {n} no mundo"]
		"fim_do_mundo":
			opcoes = ["Não resta ninguém"]
		"silencio":
			opcoes = ["{g} não entende o silêncio"]
		"culpado":
			opcoes = ["{p} é {p:apontado|apontada} como culpad{p:o|a}", "Culpam {p} pelo silêncio"]
		"conhecimento_perdido":
			opcoes = ["{g} esqueceu como plantar"]
		"regressao":
			opcoes = ["{g} perdeu um saber"]
		"estagio":
			opcoes = {3: ["{g} ergue casas de pedra"], 4: ["{g} forja metal"], 5: ["{g} aprende a escrever"],
				6: ["{g} cava canais"]}.get(e.dados["estagio"], ["{g} aprende algo novo"])
		"crenca":
			v["d"] = G.termo(e.dados["deus"])
			opcoes = ["{g} chama o deus de «{d}»", "{g} começa a crer"]
		"separacao":
			v["pai"] = _g(e.outro_grupo)
			opcoes = ["{g} nasce de {pai}", "Um novo povo: {g}"]
		"conquista":
			opcoes = ["{g} conquista {o}"]
		"guerra_inicio":
			v["n"] = G.termo(e.dados["nome"])
			opcoes = ["Começa a {n}", "{g} em guerra com {o}"]
		"guerra_fim":
			v["n"] = G.termo(e.dados["nome"])
			opcoes = ["Acaba a {n}", "Fim da guerra"]
		"agricultura":
			opcoes = ["{g} planta as primeiras roças"]
		"peste":
			opcoes = ["Peste em todo o mundo"]
		"profeta":
			opcoes = ["{p} prega outro deus", "Um profeta em {g}"]
		"secularizacao":
			opcoes = ["{g} deixou de rezar"]
		"renascimento":
			opcoes = ["{g} volta a rezar"]
		"extincao_grupo":
			opcoes = ["{g} deixou de existir"]
		"morte":
			opcoes = ["Morreu {p}"]
		"nascimento":
			opcoes = ["Nasceu {p}"]
		"expedicao":
			v["c"] = _p(e.dados["chefe"])
			opcoes = ["{c} parte além da borda"]
		"dependencia":
			opcoes = ["{g} já não se prepara"]
		"desamparo":
			opcoes = ["{g} se sente {g:abandonado|abandonado}"]
		"tregua":
			opcoes = ["Paz entre {g} e {o}", "Trégua: {g} e {o}"]
		"inicio":
			opcoes = ["{g} chega ao mundo", "Chega o primeiro povo"]
		"fome_fim":
			opcoes = ["A fome passou em {g}"]
		"doenca_fim":
			opcoes = ["A febre deixou {g}"]
		"linhagem":
			if e.dados["para"] != -1:
				v["pa"] = _p(e.dados["para"])
				opcoes = ["Agora você acompanha {pa}", "A linhagem segue com {pa}"]
			else:
				opcoes = ["A linhagem acabou"]
		"seca_inicio":
			opcoes = ["A chuva parou"]
		"seca_fim":
			opcoes = ["A chuva voltou"]
		"eclipse":
			opcoes = ["O sol escureceu"]
		"cometa":
			opcoes = ["Uma estrela de cauda no céu"]
		"terremoto", "terremoto_divino":
			opcoes = ["A terra tremeu"]
		"tempestade":
			opcoes = ["Tempestade"]
		"inverno_rigoroso":
			opcoes = ["Um inverno de gelo"]
		"chuva_divina":
			opcoes = ["Choveu onde o deus quis"]
		"raio_divino":
			if e.dados.get("vitima", -1) != -1:
				v["vi"] = _p(e.dados["vitima"])
				opcoes = ["Um raio matou {vi}"]
			else:
				opcoes = ["Um raio do céu limpo"]
		"fartura_divina":
			opcoes = ["Comida em abundância"]
		"fogo_divino":
			opcoes = ["Fogo sem origem"]
		"terra_erguida":
			opcoes = ["A terra se ergueu"]
		"sonho":
			opcoes = ["{p} teve um sonho"]
		"seca_divina":
			opcoes = ["Só ali não chove"]
		"diluvio":
			opcoes = ["A água subiu"]
		"pressagio":
			opcoes = ["Um sinal no céu"]
		"cura":
			opcoes = ["{p} se levantou" if e.dados.get("condenado", false) else "{p} se sente bem"] if e.dados.get("curado", -1) != -1 else []
		"costume":
			opcoes = ["{g} tem um novo costume"]
		"lugar_nomeado":
			v["nome"] = G.termo(e.dados["nome"])
			opcoes = ["{nome}", "Um lugar ganhou nome"]
		"sacerdote":
			opcoes = ["{p} fala pelo deus"]
		"novo_lider":
			opcoes = ["{p} guia {g}"]
		"edito":
			opcoes = ["{p} proíbe trato com {o}"]
		"descoberta", "descoberta_tecnica":
			opcoes = ["{p} descobriu algo"]
		"mito_ruinas":
			opcoes = ["{g} explica as ruínas"]
		"reforma":
			opcoes = ["{g} larga um costume"]
		"cultura":
			opcoes = ["{g} muda o jeito de viver"]
		"deus_renomeado":
			v["d"] = G.termo(e.dados["novo"])
			opcoes = ["Agora o deus é «{d}»", "{g} rebatiza o deus"]
		"casamento_entre_grupos":
			opcoes = ["Casamento entre {o} e {g}"]
		"gemeos":
			opcoes = ["Nasceram gêmeos"]
		"prece_atendida":
			opcoes = ["{g} se diz {g:atendido|atendido}"]
		"prece_sem_resposta":
			opcoes = ["Uma prece sem resposta"]
		"fusao":
			opcoes = ["{g} se junta a {o}"]
		"arquivo_salvou":
			opcoes = ["As tabuletas salvaram um saber"]
		"ruinas_saber":
			opcoes = ["{p} aprende nas ruínas"]
		"estudo_do_ceu":
			opcoes = ["{g} estuda o céu"]
		"mudanca":
			opcoes = ["{g} muda de lugar"]
		"nova_crenca":
			opcoes = ["{g} tem uma nova crença"]
		"exigencia":
			opcoes = ["{g} pede qualquer coisa"]
	if opcoes.is_empty():
		return ""
	# A primeira variante que couber; senão a mais curta, cortada.
	var melhor := ""
	for o in opcoes:
		var t := G.preencher(o, v)
		if t.length() <= LIMITE_CURTO:
			return t
		if melhor.is_empty() or t.length() < melhor.length():
			melhor = t
	return melhor.substr(0, LIMITE_CURTO - 1) + "…"


## Texto de uma prece, para a apresentação mostrar no sinal. Sempre o mesmo para o mesmo evento.
func texto_prece(e) -> String:
	rt.seed = m.semente * 100003 + e.id
	return _texto_prece(e, {})


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
			t += _frase(["A comida voltou, e {g} deu graças {a:deus}.", "A fome passou, e {g} viu nisso obra {de:deus}."], v)
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
	if e.dados["falso_milagre"] and m.grupos[e.grupo].escrita_desde >= 0 and m.grupos[e.grupo].escrita_desde <= e.ano:
		t += " " + _frase(["Nas tabuletas de {g}, ficou escrito que foi {o:deus}.", "Os escribas de {g} registraram o milagre."], v)
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
		"seca_divina":
			v["d"] = G.termo(str(e.dados["dias"]))
			if e.dados["grau"] == "sinal":
				return _frase(["{o:zona} secou um pouco, sem razão, enquanto em volta chovia."], v)
			return _frase(["Só {o:zona} secou: por {d} dias não caiu uma gota ali, enquanto em volta chovia.",
				"O céu fechou-se sobre {o:zona}. Os riachos sumiram, e só ali."], v)
		"diluvio":
			var zs: Array = e.dados["zonas"]
			var mortos_d: Array = e.dados["mortos"]
			var t4 := ""
			if zs.size() >= 4:
				t4 = _frase(["Choveu como nunca. A água subiu sobre o mundo inteiro, da praia ao morro."], v)
			elif zs.size() > 1:
				t4 = _frase(["Choveu sem parar, e a água subiu {de:zona} até as terras vizinhas."], v)
			else:
				t4 = _frase(["A água subiu e cobriu {o:zona}."], v)
			if e.dados["cabanas"] > 0:
				v["c"] = G.termo(G.extenso(e.dados["cabanas"], "f"), "f", e.dados["cabanas"])
				t4 += " " + _frase(["A correnteza levou {c} {c#cabana|cabanas}."], v)
			if not mortos_d.is_empty():
				v["ms"] = _lista_pessoas(mortos_d)
				if mortos_d.size() > 5:
					v["n"] = G.termo(str(mortos_d.size()))
					t4 += " " + _frase(["{n} pessoas se afogaram."], v)
				else:
					t4 += " " + _frase(["{ms} {ms#morreu|morreram} afogad{ms:o|a|os|as}."], v)
			return t4
		"terremoto_divino":
			var k5: int = e.dados["cabanas"]
			v["n"] = G.termo(G.extenso(k5, "f"), "f", k5)
			var t5 := _frase(["A terra tremeu {em:zona} como nunca, e em mais nenhum lugar.", "O chão {de:zona} se sacudiu sem aviso."], v)
			if k5 > 0:
				t5 += " " + _frase(["{n#Caiu|Caíram} {n} {n#cabana|cabanas}."], v)
			var mt: Array = e.dados["mortos"]
			if not mt.is_empty():
				v["ms"] = _lista_pessoas(mt)
				t5 += " " + _frase(["{ms} {ms#morreu|morreram} sob os escombros."], v)
			return t5
		"pressagio":
			var formas := {"cometa": "Uma luz com rabo atravessou o céu de ponta a ponta, rápida demais para ser estrela.",
				"eclipse": "O sol escureceu fora de hora, e voltou como se nada fosse.",
				"luzes": "O céu da noite se encheu de luzes verdes que dançavam."}
			var t6: String = formas.get(e.dados.get("forma", "luzes"), formas["luzes"])
			var leituras: Dictionary = e.dados.get("leituras", {})
			var partes: Array = []
			for gid in leituras:
				var nomes_l := {"bom": "um bom agouro", "mau": "um mau agouro", "aviso": "um aviso"}
				partes.append("%s viu ali %s" % [m.grupos[gid].nome, nomes_l[leituras[gid]]])
			if partes.size() == 1:
				t6 += " " + G.maiuscula(partes[0]) + "."
			elif partes.size() > 1:
				t6 += " Ninguém concordou: " + G.lista(partes) + "."
			return t6
		"cura":
			var cid: int = e.dados.get("curado", -1)
			if cid == -1:
				return ""
			v["p"] = _p(cid)
			if not e.dados.get("condenado", false):
				return _frase(["{p} acordou se sentindo forte como nunca, sem saber por quê."], v)
			var t7 := _frase(["{p} ardia em febre e já não falava. De manhã, levantou-se como se nada tivesse acontecido.",
				"Todos davam {p} por {p:morto|morta}. {p:Ele|Ela} se levantou, pediu água e sorriu."], v)
			if e.dados.get("n", 1) > 1:
				t7 += " " + _frase(["Na mesma noite, todos os doentes {de:zona} se levantaram."], v)
			return t7
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

func _prologo(ano_ini: int = 1) -> String:
	var e = m.eventos[0]
	for x in m.eventos:
		if x.tipo == "inicio" and x.ano >= ano_ini:
			e = x
			break
	var g = m.grupos[e.grupo]
	var v := {"g": _g(e.grupo), "avo": _p(e.dados["avo"]), "avoa": _p(e.dados["avoa"]), "zona": _zona(e.zona)}
	var era: int = e.dados.get("era", 1)
	if era > 1:
		v["era"] = G.termo(m.nome_da_era(era - 1).to_lower())
		var t := G.preencher("Depois que {era} terminou, o mundo ficou vazio. O vento passava pelas casas sem ninguém. " +
			"Então o deus fez um povo novo: {avo} e {avoa}, os três filhos com quem tinham casado, e os netos, doze ao todo. " +
			"Acamparam {em:zona} e se chamavam {g}. Não sabiam nada de quem tinha vivido antes.", v)
		if e.dados.get("ruinas", 0) > 0:
			t += " Mas as ruínas estavam lá."
		return t
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
		var estagios := {1: ", e ainda vive de coleta", 2: ", e planta roças", 3: ", em casas de pedra",
			4: ", e trabalha o metal", 5: ", e escreve", 6: ", com canais e moinhos"}
		partes[0] += estagios[g.estagio]
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

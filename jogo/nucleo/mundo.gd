extends RefCounted
## O núcleo da simulação. GDScript puro, sem nós nem gráficos.
## Recebe o tempo (passos de 1 hora) e os comandos do deus, e devolve o estado
## do mundo e a lista de eventos. Mesma semente e mesmos comandos, mesmo mundo.

const Pessoa = preload("pessoa.gd")
const Grupo = preload("grupo.gd")
const Zona = preload("zona.gd")
const Evento = preload("evento.gd")
const Nomes = preload("nomes.gd")
const Cotidiano = preload("cotidiano.gd")
const Cronista = preload("cronista.gd")
const Rotina = preload("rotina.gd")

const HORAS_DIA := 24
const DIAS_ANO := 40
const DIAS_ESTACAO := 10
const ESTACOES := ["primavera", "verão", "outono", "inverno"]

const TRACOS := ["ambicioso", "pacifico", "rancoroso", "curioso", "devoto",
	"desconfiado", "generoso", "engenhoso", "corajoso", "medroso"]
const TRACOS_OPOSTOS := {"devoto": "desconfiado", "desconfiado": "devoto",
	"corajoso": "medroso", "medroso": "corajoso", "pacifico": "rancoroso",
	"rancoroso": "pacifico"}

## Configuração das zonas: nome, gênero, comida, madeira, terra, água na seca, raio.
const CONFIG_ZONAS := {
	"praia": ["praia", "f", "Praia", 210.0, 60.0, 8, 0.15, 1.2],
	"lago": ["lago", "m", "Lago", 250.0, 120.0, 30, 0.45, 0.8],
	"floresta": ["floresta", "f", "Floresta", 300.0, 400.0, 22, 0.15, 0.7],
	"morro": ["morro", "m", "Morro", 160.0, 150.0, 14, 0.1, 2.5],
}
const ORDEM_ZONAS := ["praia", "lago", "floresta", "morro"]
const REGEN_ESTACAO := [0.065, 0.055, 0.07, 0.012]
const COLHEITA_ESTACAO := [1.0, 1.7, 1.5, 0.0]
const PESSOAS_POR_ABRIGO := 5
const CUSTO_ABRIGO := 12.0
const LIMIAR_CRENCA := 4.0
## Ritmo normal: um dia de jogo em 45 minutos reais, logo 112,5 s por passo.
const SEGUNDOS_POR_PASSO := 112.5
## Teto da ausência: um ano de jogo.
const TETO_AUSENCIA := 960

var semente: int = 0
var rng := RandomNumberGenerator.new()
var passo: int = 0
var pessoas: Dictionary = {}     # id -> Pessoa (vivas e mortas)
## Só as vivas, para os laços de todo dia: buscar num dicionário pequeno é bem mais rápido
## depois de séculos de mortos. Derivado de `pessoas`; não é salvo.
var vivos: Dictionary = {}
var peste_ate: int = -1
# A rotina visível (nucleo/rotina.gd). Nada disto é salvo.
## Se este mundo foi carregado de uma cópia de segurança (o salvo estava estragado), o
## caminho dela; senão, "". Não é salvo.
var recuperado_de: String = ""
var _rotina_cache = null          # a rotina em uso: a de hoje (de madrugada, ainda a de ontem)
var _montando = null              # a rotina sendo montada numa thread de trabalho
var _tarefa: int = -1             # a tarefa dessa montagem no WorkerThreadPool
var _descartes: Array = []        # [tarefa, rotina velha] que a thread está desmontando
var _rotina_versao: int = 0       # muda cada vez que a rotina em uso é trocada
var _consultado: bool = false     # a apresentação consultou o mundo desde o último passo
## Contadores para os testes de desempenho: montagens inteiras feitas dentro de uma consulta
## e esperas pela thread (as duas custam tempo na linha principal), e horas servidas a
## alguém acordado sem plano (fica parado em casa).
var desempenho: Dictionary = {"montagens_na_consulta": 0, "esperas": 0, "substitutos": 0}
var grupos: Array = []           # Grupo, inclusive extintos
var zonas: Dictionary = {}       # chave -> Zona
var eventos: Array = []
var comandos: Array = []
var _proximo_comando: int = 0
var _proximo_id_pessoa: int = 1
var fim_do_mundo: bool = false
var inverno_rigoroso: bool = false
var seca_global: bool = false
var seca_fim_dia: int = -1
var seca_evento: int = -1
var tempestade: Dictionary = {}  # {"zona", "horas", "evento", "mortos", "abrigos"}
var ultimo_milagre: Dictionary = {}  # id de grupo -> dia absoluto do último bem recebido
var linhagem: Array = []         # ids da linhagem dos primeiros (descendentes da matriarca)
var acompanhada: int = -1        # pessoa que o jogador acompanha
var _usos_recentes: Array = []   # poderes usados nos últimos dias: {"poder", "zona", "dia"}
var _ultimos_avisado: bool = false
var _cronista: Cronista
var salvo_em: int = 0            # hora real (Unix) do último salvamento
var guerras: Array = []          # {id, nome, a, b, motivo, inicio, batalhas, mortos, vitorias, ultimo_dia, ativa}
const MAX_POVOS := 4             # acima disto ninguém funda povo novo: parte além da borda
const MIN_FUNDADORES := 8
## O saber de cada estágio a partir do 3. O estágio 2 é a agricultura.
const SABERES := {3: "pedra", 4: "metal", 5: "escrita", 6: "engenharia"}
const ESTAGIO_MAX := 6
const PAREDES := ["taipa", "pedra", "madeira"]
const TELHADOS := ["palha", "telha", "tabuas"]
const SIMBOLOS := ["sol", "lua", "arvore"]
const ROUPAS := ["turquesa", "lilas", "rosa"]
var ruinas: Array = []           # construções abandonadas: {tipo, x, largura, estagio, povo, grupo, ano, saberes}
var era: int = 1
var era_inicio_ano: int = 1
var livros: Array = []           # crônicas fechadas deste mundo: {era, titulo, ano_ini, ano_fim, texto, na_estante}


# ---------------------------------------------------------------- criação

func _init(p_semente: int, p_comandos: Array = []) -> void:
	semente = p_semente
	rng.seed = p_semente
	comandos = p_comandos
	for chave in ORDEM_ZONAS:
		var c: Array = CONFIG_ZONAS[chave]
		var z := Zona.new()
		z.chave = chave
		z.nome = c[0]
		z.genero = c[1]
		z.cabeca = c[2]
		z.comida_cap = c[3]
		z.comida = c[3] * 0.8
		z.madeira_cap = c[4]
		z.madeira = c[4]
		z.terra_cultivavel = c[5]
		z.agua_min_seca = c[6]
		z.risco_raio = c[7]
		zonas[chave] = z
	_cronista = Cronista.new(self)
	_criar_primeiro_povo()


func _criar_primeiro_povo(zona: String = "floresta") -> void:
	var cultura := Nomes.cultura_inicial(rng)
	var g := _novo_grupo(_nome_de_grupo(cultura) if era > 1 else Nomes.grupo(cultura, rng), zona, cultura)
	g.aparencia = _aparencia_inicial(g.nome)
	g.estoque = 60.0
	g.abrigos = 3
	# Uma família estendida: os avós, três filhos casados e quatro netos.
	# As idades contam a partir do ano da criação (ano 1 no primeiro povo).
	var base := ano() - 1
	var avo := _nova_pessoa(g, "m", base - 48 - rng.randi_range(0, 6), -1, -1)
	var avoa := _nova_pessoa(g, "f", base - 45 - rng.randi_range(0, 6), -1, -1)
	_casar(avo, avoa)
	var netos_por_casal := [2, 1, 1]
	for i in 3:
		var sexo_filho := "m" if i != 1 else "f"
		var filho := _nova_pessoa(g, sexo_filho, base - 22 - rng.randi_range(0, 8), avo.id, avoa.id)
		var outro := "f" if sexo_filho == "m" else "m"
		var conj := _nova_pessoa(g, outro, filho.nasc_ano + rng.randi_range(-3, 3), -1, -1)
		_casar(filho, conj)
		var pai := filho if filho.sexo == "m" else conj
		var mae := filho if filho.sexo == "f" else conj
		for k in netos_por_casal[i]:
			_nova_pessoa(g, "m" if rng.randf() < 0.5 else "f", base - 1 - rng.randi_range(0, 9), pai.id, mae.id)
	for p in _membros(g):
		p.saude = 1.0
	g.estranhos = _inclinacao_estranhos(_membros(g))
	g.recursos = _inclinacao_recursos(_membros(g))
	g.fundador = avoa.id
	g.lider = avo.id
	acompanhada = avoa.id
	linhagem.append(avoa.id)
	linhagem.append(avo.id)
	for p in _membros(g):
		if p.mae == avoa.id or (p.mae != -1 and pessoas[p.mae].mae == avoa.id) \
				or (p.pai != -1 and pessoas[p.pai].mae == avoa.id):
			linhagem.append(p.id)
	registrar("inicio", "natural", 10, g.zona, g.id, g.membros.duplicate(),
		{"avo": avo.id, "avoa": avoa.id, "era": era, "ruinas": ruinas.size()})


func _novo_grupo(nome: String, zona: String, cultura: Dictionary) -> Grupo:
	var g := Grupo.new()
	g.id = grupos.size()
	g.nome = nome
	g.zona = zona
	g.cultura = cultura
	for outro in grupos:
		if not outro.extinto:
			outro.hostilidade[g.id] = 0.0
			g.hostilidade[outro.id] = 0.0
	grupos.append(g)
	return g


func _nova_pessoa(g: Grupo, sexo: String, nasc_ano: int, pai_id: int, mae_id: int) -> Pessoa:
	var p := Pessoa.new()
	p.id = _proximo_id_pessoa
	_proximo_id_pessoa += 1
	p.sexo = sexo
	p.nasc_ano = nasc_ano
	p.pai = pai_id
	p.mae = mae_id
	p.grupo = g.id
	p.nome = _nome_unico(g, sexo)
	p.tracos = _sortear_tracos(pai_id, mae_id)
	if pai_id != -1 and mae_id != -1:
		var pa: Pessoa = pessoas[pai_id]
		var ma: Pessoa = pessoas[mae_id]
		p.fe = clampf((pa.fe + ma.fe) * 0.4 + rng.randf_range(-0.15, 0.15), -1.0, 1.0)
		p.ferida_pelo_deus = pa.ferida_pelo_deus or ma.ferida_pelo_deus
		if p.ferida_pelo_deus:
			p.fe = clampf(p.fe - 0.25, -1.0, 1.0)
		pa.filhos.append(p.id)
		ma.filhos.append(p.id)
	pessoas[p.id] = p
	vivos[p.id] = p
	g.membros.append(p.id)
	return p


func _nome_unico(g: Grupo, sexo: String) -> String:
	var nome := ""
	for tentativa in 8:
		nome = Nomes.pessoa(g.cultura, sexo, rng)
		var repetido := false
		for gg in grupos:
			for id in gg.membros:
				if pessoas.has(id) and pessoas[id].nome == nome:
					repetido = true
		if not repetido:
			return nome
	return nome


func _sortear_tracos(pai_id: int, mae_id: int) -> Array:
	var herdaveis: Array = []
	if pai_id != -1:
		herdaveis.append_array(pessoas[pai_id].tracos)
	if mae_id != -1:
		herdaveis.append_array(pessoas[mae_id].tracos)
	var r: Array = []
	while r.size() < 2:
		var t: String
		if not herdaveis.is_empty() and rng.randf() < 0.4:
			t = herdaveis[rng.randi_range(0, herdaveis.size() - 1)]
		else:
			t = TRACOS[rng.randi_range(0, TRACOS.size() - 1)]
		if r.has(t) or (TRACOS_OPOSTOS.has(t) and r.has(TRACOS_OPOSTOS[t])):
			continue
		r.append(t)
	return r


# ---------------------------------------------------------------- tempo

func hora() -> int:
	return passo % HORAS_DIA


func dia_abs() -> int:
	return passo / HORAS_DIA


func dia_do_ano() -> int:
	return dia_abs() % DIAS_ANO


func ano() -> int:
	return dia_abs() / DIAS_ANO + 1


func estacao() -> int:
	return dia_do_ano() / DIAS_ESTACAO


## A rotina de cada dia é montada numa thread logo depois do passo que chega à HORA_MONTAR
## (o passo da 0h à 1h, em que acontecem os eventos do dia). A rotina nova entra assim que
## fica pronta (em décimos de segundo) e, no mais tardar, na HORA_TROCA, antes de alguém
## acordar. Até lá, todos dormem em casa.
const HORA_MONTAR := 1
const HORA_TROCA := 4
## Se o passo levou menos que isto, ele mesmo prepara as pessoas visíveis da hora nova.
const FOLGA_PARA_ADIANTAR_US := 2500


## Avança um passo de simulação: uma hora de jogo.
func avancar_hora() -> void:
	var t0 := Time.get_ticks_usec()
	_esperar_rotina()
	var h := hora()
	if h == 0:
		_novo_dia()
	elif h == 1 and dia_do_ano() == 0:
		# A crônica do ano que acabou é escrita uma hora depois da virada, para não somar
		# o custo dela ao passo mais caro do ano.
		_cronista.processar_ate(ano() - 1)
	_executar_comandos()
	if h == 12:
		_executar_condicionais()
	if not tempestade.is_empty():
		_tempestade_hora()
	if h == 8:
		_coleta()
	elif h == 19:
		_refeicao()
	passo += 1
	if _consultado:
		# Só com a apresentação olhando: quem avança muitas horas de uma vez sem consultar
		# (salto, ausência, testes) não monta rotina nenhuma.
		_consultado = false
		_cuidar_da_rotina()
		# Com folga no passo, já deixa pronta a resposta das consultas da hora nova.
		if Time.get_ticks_usec() - t0 < FOLGA_PARA_ADIANTAR_US:
			_no_passo = true
			pessoas_visiveis()
			cenas_ativas()
			_no_passo = false
			_consultado = false


func avancar_dias(n: int) -> void:
	for i in n * HORAS_DIA:
		avancar_hora()


# ---------------------------------------------------------------- utilidades

func chance(p: float) -> bool:
	return rng.randf() < p


func escolher(arr: Array):
	if arr.is_empty():
		return null
	return arr[rng.randi_range(0, arr.size() - 1)]


func embaralhar(arr: Array) -> Array:
	var r: Array = arr.duplicate()
	for i in range(r.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = r[i]
		r[i] = r[j]
		r[j] = t
	return r


func pessoa(id: int) -> Pessoa:
	return pessoas.get(id)


func grupo(id: int) -> Grupo:
	if id < 0 or id >= grupos.size():
		return null
	return grupos[id]


func _membros(g: Grupo) -> Array:
	var r: Array = []
	for id in g.membros:
		r.append(vivos[id])
	return r


func _adultos(g: Grupo, idade_min: int = 15, idade_max: int = 200) -> Array:
	var r: Array = []
	var a := ano()
	for id in g.membros:
		var p: Pessoa = vivos[id]
		var i := p.idade(a)
		if i >= idade_min and i <= idade_max:
			r.append(p)
	return r


func grupos_vivos() -> Array:
	var r: Array = []
	for g in grupos:
		if not g.extinto:
			r.append(g)
	return r


func grupos_na_zona(zona: String) -> Array:
	var r: Array = []
	for g in grupos:
		if not g.extinto and g.zona == zona:
			r.append(g)
	return r


func populacao() -> int:
	var n := 0
	for g in grupos:
		if not g.extinto:
			n += g.membros.size()
	return n


func _parentes_proximos(a: Pessoa, b: Pessoa) -> bool:
	if a.id == b.mae or a.id == b.pai or b.id == a.mae or b.id == a.pai:
		return true
	if a.mae != -1 and a.mae == b.mae:
		return true
	if a.pai != -1 and a.pai == b.pai:
		return true
	return false


## Pessoas que importam para a crônica: líderes, sacerdotes, fundadores, quem
## sabe algo raro, quem fez algo marcante e a linhagem acompanhada.
func peso_pessoa(p: Pessoa) -> int:
	var w := p.feitos
	var g := grupo(p.grupo)
	if g != null:
		if g.lider == p.id:
			w += 3
		if g.sacerdote == p.id:
			w += 1
		if g.fundador == p.id:
			w += 3
		if p.sabe_agricultura and g.estagio == 1:
			w += 2
	if linhagem.has(p.id):
		w += 1
	return w


# ---------------------------------------------------------------- eventos

func registrar(tipo: String, causa: String, importancia: int, zona: String, grupo_id: int,
		participantes: Array = [], dados: Dictionary = {}, outro_grupo: int = -1) -> Evento:
	var e := Evento.new()
	e.id = eventos.size()
	e.tipo = tipo
	e.ano = ano()
	e.dia = dia_do_ano()
	e.hora = hora()
	e.zona = zona
	e.grupo = grupo_id
	e.outro_grupo = outro_grupo
	e.participantes = participantes
	e.causa = causa
	e.importancia = clampi(importancia, 0, 10)
	e.dados = dados
	if grupo_id >= 0 and grupo_id < grupos.size() and grupos[grupo_id].tem_crenca:
		e.dados["_deus"] = grupos[grupo_id].nome_deus
		e.dados["_gdeus"] = grupos[grupo_id].genero_deus
	eventos.append(e)
	for id in participantes:
		if pessoas.has(id):
			pessoas[id].lembrar(e.id)
	if importancia >= 5 and grupo_id >= 0:
		for id in grupos[grupo_id].membros:
			if not participantes.has(id):
				pessoas[id].lembrar(e.id)
	return e


# ---------------------------------------------------------------- dia, estação, ano

func _novo_dia() -> void:
	if fim_do_mundo:
		# Depois da extinção, o mundo continua: o clima segue e a natureza retoma o espaço.
		_clima_do_dia()
		_presagios()
		_renovar_zonas()
		return
	var d := dia_do_ano()
	if d == 0 and passo > 0:
		_novo_ano()
	if d % DIAS_ESTACAO == 0:
		_nova_estacao()
	_clima_do_dia()
	_presagios()
	_renovar_zonas()
	_vida_do_dia()
	if dia_abs() % 5 == 0:
		_casamentos()
		_rancores_e_separacoes()
		_migracoes()
		_ensino()
		_progresso_tecnico()
		_sacerdotes()
	if dia_do_ano() % DIAS_ESTACAO == 5:
		_ruinas_e_memoria()
	_relacoes_entre_grupos()
	_preces_do_dia()
	_arrumar_grupos()
	var pop := populacao()
	if pop > 0 and pop <= 5 and not _ultimos_avisado:
		_ultimos_avisado = true
		registrar("os_ultimos", "natural", 10, "", -1, [], {"restam": pop})
	elif pop > 12:
		_ultimos_avisado = false
	if populacao() == 0 and not fim_do_mundo:
		fim_do_mundo = true
		registrar("fim_do_mundo", "natural", 10, "", -1, [], {"era": era})
		_fechar_livro("")


func _novo_ano() -> void:
	var a := ano()
	# Envelhecimento e morte natural.
	for g in grupos_vivos():
		for p in _membros(g):
			var i = p.idade(a)
			var risco := 0.005
			if i < 5:
				risco = 0.03
			elif i >= 70:
				risco = 0.3
			elif i >= 60:
				risco = 0.14
			elif i >= 50:
				risco = 0.06
			elif i >= 40:
				risco = 0.02
			if chance(risco):
				_morrer(p, "velhice" if i >= 45 else "doenca_subita")
			elif g.estagio >= 2 and i == 12 and not p.sabe_agricultura:
				p.sabe_agricultura = true
	_fe_e_poder_do_ano()
	# Rancores pequenos se apagam com os anos; os grandes ficam.
	for g in grupos_vivos():
		for p in _membros(g):
			for id in p.rancores.keys():
				if p.rancores[id] <= 2 and chance(0.4):
					p.rancores.erase(id)
	# Reforma: uma geração nova abandona costumes herdados ou sem origem lembrada.
	for g in grupos_vivos():
		if g.lider == -1:
			continue
		var l: Pessoa = pessoas[g.lider]
		var reformista := l.idade(a) < 35 or l.tem("ambicioso") or l.tem("curioso")
		for c in g.costumes.duplicate():
			var herdado: bool = g.origem.has("ano") and c["ano"] < g.origem["ano"]
			if c["tipo"] == "estocar" and g.estagio >= 2:
				continue   # o celeiro já é instituição, não costume
			if reformista and (herdado or c["esquecido"]) and chance(0.03):
				g.costumes.erase(c)
				if c["tipo"] == "queimar_mortos":
					g.mortos = "enterram"
				registrar("reforma", "social", 6, g.zona, g.id, [l.id], {"costume": c["tipo"],
					"ano_origem": c["ano"], "herdado": herdado})
				break
	# Costumes cuja origem ninguém vivo lembra.
	for g in grupos_vivos():
		if g.membros.size() < 4 or g.estagio >= 5:
			continue
		for c in g.costumes:
			if c["esquecido"]:
				continue
			var ano_origem: int = c["ano"]
			var alguem_lembra := false
			for p in _membros(g):
				# Quem cresceu ouvindo os que viveram aquilo ainda lembra.
				if p.nasc_ano <= ano_origem + 5:
					alguem_lembra = true
					break
			if not alguem_lembra:
				c["esquecido"] = true
				registrar("costume_esquecido", "social", 6, g.zona, g.id, [],
					{"costume": c["tipo"], "ano_origem": ano_origem, "origem": c["evento"]})
func _presagios() -> void:
	# Presságios naturais, em qualquer dia do ano: o sol escurece, uma estrela de cauda, a terra treme.
	if chance(0.025 / DIAS_ANO):
		var ec := registrar("cometa", "natural", 6, "", -1, [], {"noites": rng.randi_range(5, 15)})
		for g in grupos_vivos():
			_impressionar(g, 2.0 * _crenca_no_ceu(g), "cometa", ec, false)
	if chance(0.02 / DIAS_ANO):
		_terremoto()
	if chance(0.02 / DIAS_ANO):
		var e := registrar("eclipse", "natural", 6, "", -1, [], {})
		for g in grupos_vivos():
			_impressionar(g, 2.5 * _crenca_no_ceu(g), "eclipse", e, false)


## A terra treme. Natural, em todo o mundo; ou mandado pelo deus, mais forte na zona do gesto.
func _terremoto(zona: String = "", inten: float = 0.5, dados: Dictionary = {}, peso: float = 2.5) -> Evento:
	var divino := not zona.is_empty()
	var d := {"mortos": [], "cabanas": 0}
	d.merge(dados)
	var e := registrar("terremoto_divino" if divino else "terremoto", "divina" if divino else "natural", 6,
		zona, -1, [], d)
	for g in grupos_vivos():
		var forca := 1.0
		if divino:
			forca = 0.4 + 1.6 * inten if g.zona == zona else 0.3 * inten
		var caidas := int(round(g.abrigos * clampf(rng.randf_range(0.2, 0.6) * forca, 0.0, 1.0)))
		g.abrigos -= caidas
		e.dados["cabanas"] += caidas
		for p in _membros(g):
			if chance(0.025 * forca):
				e.dados["mortos"].append(p.id)
				e.participantes.append(p.id)
				_morrer(p, "terremoto")
		_impressionar(g, peso * (1.0 if not divino or g.zona == zona else 0.4), "terremoto", e, false)
	e.importancia = 6 + mini(e.dados["mortos"].size(), 3)
	return e


func _nova_estacao() -> void:
	var est := estacao()
	inverno_rigoroso = false
	if est == 1 and not seca_global and chance(0.2):
		seca_global = true
		seca_fim_dia = dia_abs() + rng.randi_range(12, 26)
		var e := registrar("seca_inicio", "natural", 5, "", -1, [], {})
		seca_evento = e.id
		for z in zonas.values():
			z.seca = true
	if est == 2 and chance(0.1):
		for z in zonas.values():
			z.comida = maxf(z.comida, z.comida_cap * 1.4)
		var e2 := registrar("fartura_natural", "natural", 3, "", -1, [], {})
		for g in grupos_vivos():
			_resolver_prece(g, "fome", e2)
	if est == 3 and chance(0.2):
		inverno_rigoroso = true
		registrar("inverno_rigoroso", "natural", 4, "", -1, [], {})


func _clima_do_dia() -> void:
	var dia := dia_abs()
	# Fim natural da seca: a chuva volta.
	if seca_global and dia >= seca_fim_dia:
		seca_global = false
		var e := registrar("seca_fim", "natural", 4, "", -1, [], {"inicio": seca_evento})
		for z in zonas.values():
			if z.seca and z.seca_ate <= dia:
				z.seca = false
		for g in grupos_vivos():
			if zonas[g.zona].seca:
				continue
			if g.preces.has("seca"):
				_impressionar(g, 1.5, "chuva", e, true)
			_resolver_prece(g, "seca", e)
			_avaliar_costume_seca(g, e)
	# Fim de uma seca mandada pelo deus: a chuva volta naquela zona.
	for z in zonas.values():
		if z.seca and z.seca_ate > 0 and dia >= z.seca_ate and not seca_global:
			z.seca = false
			z.seca_ate = -1
			var ef := registrar("seca_fim", "natural", 4, z.chave, -1, [], {"inicio": z.seca_evento, "zona_so": true})
			for g in grupos_na_zona(z.chave):
				if g.preces.has("seca"):
					_impressionar(g, 1.5, "chuva", ef, true)
				_resolver_prece(g, "seca", ef)
				_avaliar_costume_seca(g, ef)
	for z in zonas.values():
		if z.seca:
			z.agua = maxf(z.agua_min_seca, z.agua - 0.07)
		else:
			z.agua = minf(1.0, z.agua + 0.1)
	# Tempestade natural.
	if tempestade.is_empty():
		var p_temp: float = [0.02, 0.025, 0.04, 0.02][estacao()]
		if chance(p_temp):
			var pesos := {"praia": 1.4, "lago": 1.0, "floresta": 1.0, "morro": 1.6}
			var zona := _escolher_peso(pesos)
			var e2 := registrar("tempestade", "natural", 2, zona, -1, [], {"mortos": [], "abrigos": 0})
			tempestade = {"zona": zona, "horas": rng.randi_range(3, 9), "evento": e2.id,
				"inicio": rng.randi_range(6, 18)}
	# Doença.
	for g in grupos_vivos():
		if g.doenca_evento >= 0:
			continue
		var p_doenca = 0.0012 + 0.0001 * g.membros.size()
		if chance(p_doenca):
			_comecar_doenca(g)


func _escolher_peso(pesos: Dictionary) -> String:
	var total := 0.0
	for k in pesos:
		total += pesos[k]
	var r := rng.randf() * total
	for k in pesos:
		r -= pesos[k]
		if r <= 0.0:
			return k
	return pesos.keys()[-1]


func _renovar_zonas() -> void:
	var taxa: float = REGEN_ESTACAO[estacao()]
	if inverno_rigoroso:
		taxa = 0.0
	for z in zonas.values():
		var fator := clampf(z.agua * 1.2, 0.15, 1.0)
		if z.comida > z.comida_cap:
			z.comida -= (z.comida - z.comida_cap) * 0.04
		else:
			z.comida = minf(z.comida_cap, z.comida + z.comida_cap * taxa * fator)
		z.madeira = minf(z.madeira_cap, z.madeira + z.madeira_cap * 0.004)


func _tempestade_hora() -> void:
	var h := hora()
	if h < tempestade["inicio"]:
		return
	var e: Evento = eventos[tempestade["evento"]]
	tempestade["horas"] -= 1
	var z: Zona = zonas[tempestade["zona"]]
	for g in grupos_na_zona(z.chave):
		if g.abrigos > 0 and chance(0.05):
			g.abrigos -= 1
			e.dados["abrigos"] += 1
			e.importancia = maxi(e.importancia, 3)
		var risco := 0.012 * z.risco_raio
		if g.tem_costume("tabu_tempestade"):
			risco *= 0.2
		if h >= 6 and h <= 19 and chance(risco):
			var vitimas := _adultos(g, 10)
			if vitimas.is_empty():
				continue
			var v: Pessoa = escolher(vitimas)
			e.dados["mortos"].append(v.id)
			e.participantes.append(v.id)
			e.grupo = g.id
			e.importancia = maxi(e.importancia, 6)
			_morrer(v, "raio_natural")
			_reagir_raio(g, v, e, false)
	if tempestade["horas"] <= 0:
		tempestade = {}


# ---------------------------------------------------------------- economia

func _coleta() -> void:
	var est := estacao()
	var a := ano()
	# Demanda de coleta por zona, para dividir a comida selvagem.
	var demanda := {}
	var forca := {}
	for g in grupos_vivos():
		var f := 0.0
		for p in _membros(g):
			var i = p.idade(a)
			if i >= 15 and i <= 60:
				f += 1.9
			elif i >= 9 and i < 15:
				f += 0.7
			elif i > 60:
				f += 0.4
		if g.estagio >= 2:
			f *= 0.5
		forca[g.id] = f
		demanda[g.zona] = demanda.get(g.zona, 0.0) + f
	for g in grupos_vivos():
		var z: Zona = zonas[g.zona]
		var f: float = forca[g.id]
		var total: float = demanda[g.zona]
		var disponivel := z.comida * 0.12
		var colhido := minf(f, disponivel * (f / maxf(total, 0.001)))
		z.comida -= colhido
		var producao := colhido
		if g.estagio >= 2:
			var agricultores := mini(_adultos(g, 13, 60).size(), z.terra_cultivavel)
			var fator_agua := clampf(z.agua * 1.3, 0.05, 1.0)
			if g.estagio >= 6:
				# Irrigação: a seca pesa pouco.
				fator_agua = maxf(fator_agua, 0.75)
			producao += agricultores * 1.3 * (1.0 + 0.1 * (g.estagio - 2)) * COLHEITA_ESTACAO[est] * fator_agua
		g.estoque += producao
		var perda := 0.025
		if g.tem_costume("estocar"):
			perda = 0.006
		elif g.estagio >= 2:
			perda = 0.012
		if g.estagio >= 3:
			perda = minf(perda, 0.007 - 0.0005 * (g.estagio - 3))
		if g.recursos == "acumula":
			perda *= 0.8
		g.estoque *= 1.0 - perda
		# Abrigos: constroem fora do inverno, se houver madeira.
		var precisa := int(ceil(g.membros.size() / float(PESSOAS_POR_ABRIGO)))
		if est != 3 and g.abrigos < precisa and z.madeira >= CUSTO_ABRIGO:
			z.madeira -= CUSTO_ABRIGO
			g.abrigos += 1


func _refeicao() -> void:
	var a := ano()
	for g in grupos_vivos():
		var necessidade := 0.0
		var membros := _membros(g)
		for p in membros:
			necessidade += _consumo(p, a)
		var razao := 1.0
		if necessidade > 0.0:
			razao = clampf(g.estoque / necessidade, 0.0, 1.0)
		g.estoque = maxf(0.0, g.estoque - necessidade)
		var sem_abrigo := 0.0
		if estacao() == 3:
			var lugares = g.abrigos * PESSOAS_POR_ABRIGO
			if membros.size() > lugares:
				sem_abrigo = float(membros.size() - lugares) / membros.size()
		for p in membros:
			var i = p.idade(a)
			var fragil := (1.3 if g.recursos == "partilha" else 1.6) if (i < 6 or i > 60) else 1.0
			if razao < 1.0:
				p.saude -= (1.0 - razao) * rng.randf_range(0.03, 0.08) * fragil
			elif p.doente <= 0:
				p.saude = minf(1.0, p.saude + 0.04)
			if sem_abrigo > 0.0 and chance(sem_abrigo):
				p.saude -= (0.07 if inverno_rigoroso else 0.025) * fragil
			if p.doente > 0:
				p.doente -= 1
				p.saude -= 0.045 * fragil * (2.0 if dia_abs() < peste_ate else 1.0)
		# Fome do grupo.
		if razao < 0.7:
			g.fome_dias += 1
			if g.fome_dias == 6 and not g.em_fome:
				g.em_fome = true
				g.fome_mortos = 0
				var e := registrar("fome_inicio", "natural", 5, g.zona, g.id, [],
					{"inverno": estacao() == 3, "seca": zonas[g.zona].seca})
				g.fome_evento = e.id
				g.fome_ultima_ano = a
				_impressionar(g, 0.5, "seca" if zonas[g.zona].seca else "fome", e, false)
		else:
			g.fome_dias = maxi(0, g.fome_dias - 2)
			if g.em_fome and g.fome_dias == 0:
				g.em_fome = false
				var dur := dia_abs() - _dia_do_evento(g.fome_evento)
				var e2 := registrar("fome_fim", "natural", 4 + mini(g.fome_mortos, 4), g.zona, g.id, [],
					{"mortos": g.fome_mortos, "dias": dur, "inicio": g.fome_evento})
				_resolver_prece(g, "fome", e2)
				if (g.fome_mortos >= 1 or dur >= 10) and not g.tem_costume("estocar") and not g.dependente:
					_novo_costume(g, "estocar", e2)
				if g.fome_mortos >= 2:
					_nomear_lugar(g, g.zona, "fome", e2)
		for p in membros:
			if p.saude <= 0.0:
				var causa := "fome"
				if p.doente > 0:
					causa = "doenca"
				elif razao >= 0.7:
					causa = "frio"
				_morrer(p, causa)
		if g.doenca_evento >= 0:
			var algum := false
			for id in g.membros:
				if pessoas[id].doente > 0:
					algum = true
			if not algum:
				var ev: Evento = eventos[g.doenca_evento]
				var e3 := registrar("doenca_fim", "natural", 3 + mini(g.doenca_mortos, 5), g.zona, g.id, [],
					{"mortos": g.doenca_mortos, "inicio": ev.id})
				if g.doenca_mortos >= 3 and not g.tem_costume("queimar_mortos"):
					_novo_costume(g, "queimar_mortos", e3)
					g.mortos = "queimam"
				g.doenca_evento = -1
				_resolver_prece(g, "doenca", e3)


func _consumo(p: Pessoa, a: int) -> float:
	var i := p.idade(a)
	if i < 10:
		return 0.6
	if i > 60:
		return 0.8
	return 1.0


func _dia_do_evento(id: int) -> int:
	if id < 0:
		return dia_abs()
	var e: Evento = eventos[id]
	return (e.ano - 1) * DIAS_ANO + e.dia


func _comecar_doenca(g: Grupo) -> void:
	var infectados: Array = []
	var p_inf := 0.35
	if g.tem_costume("queimar_mortos"):
		p_inf = 0.15
	for p in _membros(g):
		if chance(p_inf):
			p.doente = rng.randi_range(5, 11)
			infectados.append(p.id)
	if infectados.is_empty():
		return
	g.doenca_mortos = 0
	var e := registrar("doenca_inicio", "natural", 4, g.zona, g.id, infectados, {"n": infectados.size()})
	g.doenca_evento = e.id
	_impressionar(g, 0.7, "doenca", e, false)


# ---------------------------------------------------------------- vida

func _vida_do_dia() -> void:
	var a := ano()
	for g in grupos_vivos():
		var bem_alimentado = g.fome_dias == 0
		for p in _membros(g):
			if p.gravidez > 0:
				p.gravidez -= 1
				if p.gravidez == 0:
					_parto(p, g)
			elif p.sexo == "f" and p.conjuge != -1 and p.gravidez < 0:
				var i = p.idade(a)
				if i >= 16 and i <= 42:
					var marido: Pessoa = pessoas[p.conjuge]
					if marido.vivo and marido.grupo == p.grupo:
						var c := 1.0 / 55.0 if bem_alimentado else 1.0 / 220.0
						# Com pouca comida guardada, nascem menos crianças.
						c *= clampf(g.estoque / (g.membros.size() * 3.0), 0.2, 1.0)
						if chance(c):
							p.gravidez = 12


func _parto(mae: Pessoa, g: Grupo) -> void:
	mae.gravidez = -1
	var pai_id := mae.conjuge
	var filho := _nova_pessoa(g, "m" if chance(0.5) else "f", ano(), pai_id, mae.id)
	filho.nasc_ano = ano()
	if linhagem.has(mae.id) or (pai_id != -1 and linhagem.has(pai_id)):
		linhagem.append(filho.id)
	var imp := 1
	var motivo := ""
	var pai: Pessoa = pessoas.get(pai_id)
	if g.lider == mae.id or (pai != null and g.lider == pai.id):
		imp = 4
		motivo = "lider"
	elif g.em_fome:
		imp = 3
		motivo = "fome"
	elif mae.veio_de != -1 or (pai != null and pai.veio_de != -1):
		imp = 4
		motivo = "entre_grupos"
	elif linhagem.has(mae.id) or linhagem.has(pai_id):
		imp = 2
		motivo = "linhagem"
	if g.nascimentos == 0:
		imp = maxi(imp, 5)
		motivo = "primeiro"
	g.nascimentos += 1
	registrar("nascimento", "natural", imp, g.zona, g.id, [filho.id, mae.id, pai_id],
		{"motivo": motivo})
	if chance(0.006):
		var irmao := _nova_pessoa(g, filho.sexo if chance(0.5) else ("f" if filho.sexo == "m" else "m"), ano(), pai_id, mae.id)
		if linhagem.has(filho.id):
			linhagem.append(irmao.id)
		var eg := registrar("gemeos", "natural", 5, g.zona, g.id, [filho.id, irmao.id, mae.id], {})
		_impressionar(g, 1.0, "gemeos", eg, true)
	if chance(0.03):
		_morrer(mae, "parto")


func _morrer(p: Pessoa, causa: String, dados_extra: Dictionary = {}) -> void:
	if not p.vivo:
		return
	var g := grupo(p.grupo)
	var a := ano()
	var imp := 2 + peso_pessoa(p)
	if p.idade(a) < 15 and causa != "velhice":
		imp += 1
	var dados := {"causa": causa, "idade": p.idade(a), "lider": g != null and g.lider == p.id,
		"sacerdote": g != null and g.sacerdote == p.id, "fundador": g != null and g.fundador == p.id,
		"sabia": p.sabe_agricultura}
	dados.merge(dados_extra)
	p.vivo = false
	vivos.erase(p.id)
	p.morte_ano = a
	p.causa_morte = causa
	p.gravidez = -1
	if g != null:
		g.membros.erase(p.id)
		match causa:
			"fome":
				g.fome_mortos += 1
			"doenca":
				g.doenca_mortos += 1
			"frio":
				g.frio_mortos += 1
	if p.conjuge != -1 and pessoas.has(p.conjuge):
		pessoas[p.conjuge].conjuge = -1
	var e := registrar("morte", "social" if causa in ["batalha", "culpado"] else ("divina" if causa == "raio_divino" else "natural"),
		imp, g.zona if g != null else "", p.grupo, [p.id], dados)
	if p.id == acompanhada:
		_passar_linhagem(p)
	if g == null:
		return
	if not g.extinto and not g.membros.is_empty():
		_rito_funebre(g, p)
	# A prece por esta pessoa ficou sem resposta.
	for nec in g.preces.keys():
		var pr: Dictionary = g.preces[nec]
		if pr.get("alvo", -1) == p.id:
			_prece_sem_resposta(g, nec, e)
	if g.lider == p.id:
		g.lider = -1
	if g.sacerdote == p.id:
		g.sacerdote = -1
	# O conhecimento se perde se ninguém mais sabe.
	if p.sabe_agricultura and g.estagio == 1:
		var alguem := false
		for id in g.membros:
			if pessoas[id].sabe_agricultura:
				alguem = true
		if not alguem:
			registrar("conhecimento_perdido", "social", 8, g.zona, g.id, [p.id], {})


# ---------------------------------------------------------------- sociedade

func _casar(a: Pessoa, b: Pessoa) -> void:
	a.conjuge = b.id
	b.conjuge = a.id


func _casamentos() -> void:
	var a := ano()
	for g in grupos_vivos():
		var solteiros_m: Array = []
		var solteiras_f: Array = []
		for p in _membros(g):
			if p.conjuge == -1 and p.idade(a) >= 16 and p.idade(a) <= 50:
				if p.sexo == "m":
					solteiros_m.append(p)
				else:
					solteiras_f.append(p)
		for m in solteiros_m:
			if not chance(0.3):
				continue
			for f in embaralhar(solteiras_f):
				if f.conjuge == -1 and not _parentes_proximos(m, f):
					_casar(m, f)
					var imp := 1
					if g.lider == m.id or g.lider == f.id:
						imp = 3
					registrar("casamento", "social", imp, g.zona, g.id, [m.id, f.id], {})
					break
	# Casamentos entre grupos: quem não acha par em casa procura nos vizinhos.
	for g in grupos_vivos():
		for p in _membros(g):
			if p.conjuge != -1 or p.idade(a) < 18 or p.idade(a) > 40 or not chance(0.06 * (1.0 + g.estranhos)):
				continue
			for outro in grupos_vivos():
				if outro.id == g.id or g.hostilidade.get(outro.id, 0.0) > 3.0 or g.proibido.has(outro.id) or outro.proibido.has(g.id):
					continue
				var par: Pessoa = null
				for q in _membros(outro):
					if q.sexo != p.sexo and q.conjuge == -1 and q.idade(a) >= 16 and q.idade(a) <= 45:
						par = q
						break
				if par == null:
					continue
				_casar(p, par)
				# A mulher muda para o grupo do marido, salvo se for líder.
				var muda: Pessoa = p if p.sexo == "f" else par
				if grupo(muda.grupo).lider == muda.id:
					muda = par if muda == p else p
				var fica: Pessoa = par if muda == p else p
				var destino: Grupo = grupo(fica.grupo)
				var de := grupo(muda.grupo)
				muda.veio_de = de.id
				_mudar_de_grupo(muda, destino)
				_mudar_estranhos(destino, 0.05, null)
				_mudar_estranhos(de, 0.05, null)
				var primeiro := not _ja_houve("casamento_entre_grupos", de.id, destino.id)
				registrar("casamento_entre_grupos", "social", 5 if primeiro else 2, destino.zona, destino.id,
					[muda.id, fica.id], {"de": de.id, "primeiro": primeiro,
					"sabia": muda.sabe_agricultura and destino.estagio == 1}, de.id)
				g.hostilidade[outro.id] = maxf(0.0, g.hostilidade.get(outro.id, 0.0) - 1.0)
				outro.hostilidade[g.id] = maxf(0.0, outro.hostilidade.get(g.id, 0.0) - 1.0)
				break


func _ja_houve(tipo: String, g1: int, g2: int = -1) -> bool:
	for e in do_tipo(tipo):
		if (e.grupo == g1 and (g2 == -1 or e.outro_grupo == g2)) or (g2 != -1 and e.grupo == g2 and e.outro_grupo == g1):
			return true
	return false


## Índice dos eventos por tipo, para não percorrer a história inteira (dezenas de milhares
## de eventos depois de séculos). Cresce junto com a lista de eventos; não é salvo.
var _eventos_por_tipo: Dictionary = {}
var _por_tipo_ate: int = 0


## Os eventos de um tipo, em ordem.
func do_tipo(tipo: String) -> Array:
	while _por_tipo_ate < eventos.size():
		var e: Evento = eventos[_por_tipo_ate]
		if not _eventos_por_tipo.has(e.tipo):
			_eventos_por_tipo[e.tipo] = []
		_eventos_por_tipo[e.tipo].append(e)
		_por_tipo_ate += 1
	return _eventos_por_tipo.get(tipo, [])


## Refaz os índices que não são salvos (depois de carregar).
func reindexar() -> void:
	_eventos_por_tipo = {}
	_por_tipo_ate = 0
	do_tipo("")


func _mudar_de_grupo(p: Pessoa, destino: Grupo) -> void:
	var origem := grupo(p.grupo)
	if origem != null:
		origem.membros.erase(p.id)
		if origem.lider == p.id:
			origem.lider = -1
		if origem.sacerdote == p.id:
			origem.sacerdote = -1
	p.grupo = destino.id
	destino.membros.append(p.id)


func _rancores_e_separacoes() -> void:
	var a := ano()
	for g in grupos_vivos():
		var adultos := _adultos(g, 16)
		if adultos.size() < 2:
			continue
		# Em tempo de fome, alguém esconde comida e cria rancor.
		if g.em_fome and chance(0.35 * (1.6 if g.recursos == "acumula" else 1.0)):
			var ladrao: Pessoa = escolher(adultos)
			if ladrao.tem("ambicioso") or ladrao.tem("rancoroso") or chance(0.15):
				var vitima: Pessoa = escolher(adultos)
				if vitima != ladrao:
					var intens := 2 if vitima.tem("rancoroso") else 1
					vitima.rancores[ladrao.id] = vitima.rancores.get(ladrao.id, 0) + intens
					registrar("roubo", "social", 2, g.zona, g.id, [ladrao.id, vitima.id], {})
					if g.recursos == "partilha" and chance(0.08):
						g.recursos = "acumula"
						registrar("cultura", "social", 6, g.zona, g.id, [], {"dimensao": "recursos", "valor": "acumula"})
		# Disputa pela liderança.
		if g.lider != -1 and chance(0.05):
			var lider: Pessoa = pessoas[g.lider]
			for p in adultos:
				if p != lider and p.tem("ambicioso") and p.idade(a) >= 20 and not _parentes_proximos(p, lider):
					p.rancores[lider.id] = p.rancores.get(lider.id, 0) + 1
					lider.rancores[p.id] = lider.rancores.get(p.id, 0) + 1
					registrar("rixa", "social", 2, g.zona, g.id, [p.id, lider.id], {"motivo": "lideranca"})
					break
		# Briga que divide o grupo.
		if g.membros.size() < 12:
			continue
		for p in adultos:
			var alvo := -1
			for id in p.rancores:
				if p.rancores[id] >= 4 and pessoas[id].vivo and pessoas[id].grupo == g.id:
					alvo = id
					break
			var n_grupos := grupos_vivos().size()
			if alvo != -1 and n_grupos < MAX_POVOS and chance(0.1 if n_grupos < 3 else 0.03):
				_separar(g, p, "briga", alvo)
				return


func _migracoes() -> void:
	var a := ano()
	# Coletores com fome levantam acampamento e vão para onde há comida.
	for g in grupos_vivos():
		if g.estagio == 1 and g.em_fome:
			var atual: Zona = zonas[g.zona]
			var melhor := ""
			var melhor_v := atual.comida / maxf(1.0, _ocupacao(g.zona))
			for chave in ORDEM_ZONAS:
				if chave == g.zona:
					continue
				var v: float = zonas[chave].comida / (_ocupacao(chave) + g.membros.size())
				if v > melhor_v * 1.5:
					melhor_v = v
					melhor = chave
			if melhor != "":
				_deixar_ruinas(g)
				var de: String = g.zona
				g.zona = melhor
				# Coletores levam as peles e as varas: metade das cabanas vai junto.
				g.abrigos = g.abrigos / 2
				var vizinhos: Array = []
				for outro in grupos_na_zona(melhor):
					if outro != g:
						vizinhos.append(outro.id)
						outro.hostilidade[g.id] = outro.hostilidade.get(g.id, 0.0) + 1.0
				registrar("mudanca", "natural", 5, melhor, g.id, [], {"de": de,
					"primeira": not _ja_houve("mudanca", g.id), "vizinhos": vizinhos})
	for g in grupos_vivos():
		if g.membros.size() < 12:
			continue
		var cheio := grupos_vivos().size() >= MAX_POVOS or _zona_destino(g) == ""
		if cheio and g.em_fome and g.fome_dias >= 6 and chance(0.08):
			var aventureiros: Array = []
			for p in _adultos(g, 18, 50):
				if p.id != g.lider and (p.tem("curioso") or p.tem("corajoso") or p.tem("ambicioso")):
					aventureiros.append(p)
			if not aventureiros.is_empty():
				_expedicao(g, escolher(aventureiros))
				continue
		var z: Zona = zonas[g.zona]
		var aperto = g.membros.size() / maxf(1.0, _capacidade(z, g))
		var p_mig := 0.0
		if g.em_fome:
			p_mig = 0.05
		elif aperto > 1.3:
			p_mig = 0.02
		if grupos_vivos().size() >= 4:
			p_mig *= 0.3
		if grupos_vivos().size() >= MAX_POVOS:
			p_mig = 0.0
		if g.amaldicoada:
			p_mig = 0.3
		if g.estagio >= 2:
			p_mig *= 0.4
		if p_mig <= 0.0 or not chance(p_mig):
			continue
		var candidatos: Array = []
		for p in _adultos(g, 20, 55):
			if p.id != g.lider and (p.tem("ambicioso") or p.tem("curioso") or p.tem("corajoso")):
				candidatos.append(p)
		if candidatos.is_empty():
			continue
		var lider_mig: Pessoa = escolher(candidatos)
		if _zona_destino(g) == "":
			# Não há para onde ir: alguns partem além da borda do mundo.
			if g.em_fome and chance(0.35):
				_expedicao(g, lider_mig)
			continue
		_separar(g, lider_mig, "migracao", -1)
		return


func _ocupacao(chave: String) -> int:
	var n := 0
	for gg in grupos_na_zona(chave):
		n += gg.membros.size()
	return n


func _capacidade(z: Zona, g: Grupo) -> float:
	var cap := z.comida_cap * 0.045 / 0.95
	if g.estagio >= 2:
		cap += z.terra_cultivavel * 0.85 * (1.0 + 0.1 * (g.estagio - 2))
	return cap


func _zona_destino(g: Grupo) -> String:
	var melhor := ""
	var melhor_v := 0.0
	for chave in ORDEM_ZONAS:
		if chave == g.zona:
			continue
		var z: Zona = zonas[chave]
		var ocup := 0
		for gg in grupos_na_zona(chave):
			ocup += gg.membros.size()
		var folga := z.comida_cap * 0.045 - ocup
		if folga > melhor_v:
			melhor_v = folga
			melhor = chave
	return melhor


## Separa parte de um grupo em um novo grupo. O fundador leva a própria
## família e quem pensa como ele.
func _separar(g: Grupo, fundador: Pessoa, causa: String, desafeto: int, novo_cetico: bool = false) -> void:
	if grupos_vivos().size() >= MAX_POVOS or g.membros.size() < 20:
		return
	var destino := _zona_destino(g)
	if destino == "":
		if causa == "migracao":
			return
		var menor := 9999
		for chave in ORDEM_ZONAS:
			var ocup := 0
			for gg in grupos_na_zona(chave):
				ocup += gg.membros.size()
			if chave != g.zona and ocup < menor:
				menor = ocup
				destino = chave
	var levar: Array = [fundador]
	var a := ano()
	if fundador.conjuge != -1 and pessoas[fundador.conjuge].grupo == g.id:
		levar.append(pessoas[fundador.conjuge])
	for p in _membros(g):
		if levar.has(p):
			continue
		var familia = p.mae == fundador.id or p.pai == fundador.id
		if fundador.conjuge != -1:
			familia = familia or p.mae == fundador.conjuge or p.pai == fundador.conjuge
		if familia:
			levar.append(p)
	for p in levar.duplicate():
		if p.conjuge != -1 and not levar.has(pessoas[p.conjuge]) and pessoas[p.conjuge].vivo \
				and pessoas[p.conjuge].grupo == g.id:
			levar.append(pessoas[p.conjuge])
	# Outros seguem o fundador: quem pensa parecido ou também tem rancor.
	for p in _membros(g):
		if levar.has(p) or p.id == g.lider or p.id == desafeto:
			continue
		var afinidade := 0.08
		if causa == "cisma" and novo_cetico and (p.tem("desconfiado") or p.fe < 0.0):
			afinidade = 0.7
		if causa == "cisma" and not novo_cetico and (p.tem("devoto") or p.fe > 0.3):
			afinidade = 0.7
		if causa == "briga" and desafeto != -1 and p.rancores.get(desafeto, 0) > 0:
			afinidade = 0.6
		if causa == "migracao" and (p.tem("curioso") or p.tem("ambicioso")):
			afinidade = 0.3
		if p.idade(a) >= 16 and chance(afinidade):
			levar.append(p)
			for q in _membros(g):
				if not levar.has(q) and (q.mae == p.id or q.pai == p.id) and q.idade(a) < 16:
					levar.append(q)
	if levar.size() < MIN_FUNDADORES or levar.size() > g.membros.size() - 4:
		return
	var cultura := Nomes.cultura_derivada(g.cultura, rng)
	var novo := _novo_grupo(_nome_de_grupo(cultura), destino, cultura)
	for p in levar:
		_mudar_de_grupo(p, novo)
	novo.lider = fundador.id
	novo.fundador = fundador.id
	# Separados, a rixa esfria: cada um foi viver longe do outro.
	if desafeto != -1 and pessoas.has(desafeto):
		fundador.rancores.erase(desafeto)
		pessoas[desafeto].rancores.erase(fundador.id)
	fundador.feitos += 2
	var parte := g.estoque * levar.size() / float(levar.size() + g.membros.size())
	g.estoque -= parte
	novo.estoque = parte
	novo.abrigos = mini(1, g.abrigos)
	g.abrigos = maxi(0, g.abrigos - 1)
	novo.violencia = g.violencia
	novo.estranhos = clampf(g.estranhos + _inclinacao_estranhos([fundador]) * 0.5, -1.0, 1.0)
	novo.mortos = g.mortos
	novo.poder = g.poder
	novo.recursos = _inclinacao_recursos([fundador]) if fundador.tem("generoso") or fundador.tem("ambicioso") else g.recursos
	novo.aparencia = _aparencia_derivada(g.aparencia, novo.nome)
	if novo.estagio >= 5:
		novo.escrita_desde = ano()
	novo.tem_crenca = g.tem_crenca
	novo.nome_deus = g.nome_deus
	novo.genero_deus = g.genero_deus
	novo.crencas = g.crencas.duplicate()
	for c in g.costumes:
		novo.costumes.append(c.duplicate())
	var sabem := 0
	for p in levar:
		if p.sabe_agricultura:
			sabem += 1
	novo.estagio = 2 if sabem >= 2 else 1
	if novo.estagio == 2:
		for k in range(3, g.estagio + 1):
			var tem := false
			for p in levar:
				if p.saberes.has(SABERES[k]):
					tem = true
			if not tem:
				break
			novo.estagio = k
	var hostis := {"briga": 3.5, "cisma": 3.0, "migracao": 0.5}
	var hostil: float = hostis[causa]
	g.hostilidade[novo.id] = hostil
	novo.hostilidade[g.id] = hostil
	var ids: Array = []
	for p in levar:
		ids.append(p.id)
	var e := registrar("separacao", "social", 8, destino, novo.id, ids,
		{"causa": causa, "fundador": fundador.id, "desafeto": desafeto, "n": levar.size(),
		"zona_origem": g.zona, "perdeu_estagio": g.estagio >= 2 and novo.estagio == 1}, g.id)
	novo.origem = {"pai": g.id, "causa": causa, "ano": a, "evento": e.id}
	e.dados["novo_cetico"] = novo_cetico
	if causa == "cisma":
		novo.tem_crenca = true
		novo.ceticos = novo_cetico
		if not novo_cetico:
			# Os fiéis que partem dão ao deus um nome novo.
			var nat := _natureza_do_nome(g.nome_deus)
			var opcoes: Array = NOMES_DEUS["sonho" if nat != "sonho" else "chuva"]
			var escolha: Array = opcoes[rng.randi_range(0, opcoes.size() - 1)]
			novo.nome_deus = escolha[0]
			novo.genero_deus = escolha[1]
			for p in levar:
				p.fe = maxf(p.fe, 0.3)
		else:
			novo.crencas = ["nao_existe"]
	if g.lider == -1:
		_escolher_lider(g)


func _expedicao(g: Grupo, chefe: Pessoa) -> void:
	var foram: Array = [chefe]
	if chefe.conjuge != -1 and pessoas[chefe.conjuge].grupo == g.id:
		foram.append(pessoas[chefe.conjuge])
	for p in _membros(g):
		if not foram.has(p) and (p.mae == chefe.id or p.pai == chefe.id) and p.conjuge == -1:
			foram.append(p)
	# Quem também está cansado de fome vai junto.
	for p in _adultos(g, 16, 45):
		if not foram.has(p) and p.id != g.lider and p.conjuge == -1 and (p.tem("curioso") or p.tem("corajoso")) and chance(0.5):
			foram.append(p)
	if foram.size() >= g.membros.size() - 2:
		return
	var ids: Array = []
	for p in foram:
		ids.append(p.id)
		g.membros.erase(p.id)
		p.vivo = false
		vivos.erase(p.id)
		p.morte_ano = ano()
		p.causa_morte = "alem_da_borda"
		if p.conjuge != -1 and not ids.has(p.conjuge) and pessoas.has(p.conjuge) and not foram.has(pessoas[p.conjuge]):
			pessoas[p.conjuge].conjuge = -1
	if g.lider in ids:
		g.lider = -1
	var e := registrar("expedicao", "social", 7, g.zona, g.id, ids, {"chefe": chefe.id, "n": foram.size()})
	if ids.has(acompanhada):
		_passar_linhagem(pessoas[acompanhada])
	if g.tem_crenca and not g.tem_crenca_chave("alem_da_borda"):
		_nova_crenca(g, "alem_da_borda", e)


func _nome_de_grupo(cultura: Dictionary) -> String:
	var nome := ""
	for tentativa in 20:
		nome = Nomes.grupo(cultura, rng)
		var repetido := false
		for g in grupos:
			if g.nome == nome:
				repetido = true
		if not repetido:
			return nome
	return nome + "a"


## Aparência de um povo (parede, telhado, símbolo, roupa), tirada do nome: não sorteia nada.
func _aparencia_inicial(nome: String) -> Dictionary:
	var h := hash(nome)
	return {"parede": PAREDES[posmod(h, 3)], "telhado": TELHADOS[posmod(h / 3, 3)],
		"simbolo": SIMBOLOS[posmod(h / 9, 3)], "roupa": ROUPAS[posmod(h / 27, 3)]}


## Um povo novo herda a aparência do povo de onde saiu e muda uma coisa.
func _aparencia_derivada(mae: Dictionary, nome: String) -> Dictionary:
	if mae.is_empty():
		return _aparencia_inicial(nome)
	var a := mae.duplicate()
	var h := hash(nome)
	var listas := {"parede": PAREDES, "telhado": TELHADOS, "simbolo": SIMBOLOS, "roupa": ROUPAS}
	var chave: String = listas.keys()[posmod(h, 4)]
	var opcoes: Array = listas[chave]
	a[chave] = opcoes[posmod(opcoes.find(a[chave]) + 1 + posmod(h / 4, 2), 3)]
	return a


func _inclinacao_recursos(lista: Array) -> String:
	var v := 0
	for p in lista:
		if p.tem("generoso"):
			v += 1
		if p.tem("ambicioso"):
			v -= 1
	return "acumula" if v < 0 else "partilha"


## De -1 (desconfiados) a 1 (acolhedores), pelos traços das pessoas dadas.
func _inclinacao_estranhos(lista: Array) -> float:
	if lista.is_empty():
		return 0.0
	var v := 0.0
	for p in lista:
		if p.tem("generoso"):
			v += 1.0
		if p.tem("curioso"):
			v += 0.5
		if p.tem("desconfiado"):
			v -= 1.0
		if p.tem("rancoroso"):
			v -= 0.5
	return clampf(v / lista.size() * 1.5, -1.0, 1.0)


## A relação de um povo com estranhos muda com o que ele vive.
func _mudar_estranhos(g: Grupo, delta: float, e: Evento) -> void:
	var antes := g.estranhos
	g.estranhos = clampf(g.estranhos + delta, -1.0, 1.0)
	if antes > -0.5 and g.estranhos <= -0.5:
		registrar("cultura", "social", 6, g.zona, g.id, [], {"dimensao": "estranhos", "valor": "desconfiada",
			"origem": e.id if e != null else -1})
	elif antes < 0.5 and g.estranhos >= 0.5:
		registrar("cultura", "social", 6, g.zona, g.id, [], {"dimensao": "estranhos", "valor": "acolhedora",
			"origem": e.id if e != null else -1})


## Na primeira morte de um adulto, o povo decide o que faz com os mortos.
func _rito_funebre(g: Grupo, morto: Pessoa) -> void:
	if not g.mortos.is_empty() or morto.idade(ano()) < 16:
		return
	var devotos := 0
	for p in _membros(g):
		if p.tem("devoto") or p.fe > 0.5:
			devotos += 1
	var rito := "enterram"
	if g.tem_costume("queimar_mortos"):
		rito = "queimam"
	elif g.tem_crenca and devotos * 3 >= g.membros.size():
		rito = "veneram"
	g.mortos = rito
	registrar("cultura", "social", 6, g.zona, g.id, [morto.id], {"dimensao": "mortos", "valor": rito})


func _escolher_lider(g: Grupo) -> void:
	var a := ano()
	var melhor: Pessoa = null
	var melhor_v := -1.0
	var segundo: Pessoa = null
	for p in _adultos(g, 18, 70):
		var v := minf(p.idade(a), 50) / 10.0 + rng.randf() * 2.0
		if p.tem("ambicioso"):
			v += 2.0
		if p.tem("corajoso"):
			v += 1.0
		if p.tem("generoso"):
			v += 0.7
		if p.tem("medroso"):
			v -= 1.5
		if v > melhor_v:
			segundo = melhor
			melhor_v = v
			melhor = p
	if melhor == null:
		return
	if g.poder == "sacerdotes" and g.sacerdote != -1 and pessoas[g.sacerdote].vivo and pessoas[g.sacerdote].grupo == g.id:
		melhor = pessoas[g.sacerdote]
		segundo = null
	g.lider = melhor.id
	var disputa := segundo != null and segundo.tem("ambicioso")
	if disputa:
		segundo.rancores[melhor.id] = segundo.rancores.get(melhor.id, 0) + 2
	registrar("novo_lider", "social", 5 if disputa else 3, g.zona, g.id,
		[melhor.id] + ([segundo.id] if disputa else []), {"disputa": disputa})
	# Quem decide: depois de disputas, um povo grande e de gente generosa passa a ter conselho.
	if disputa and g.poder == "lider" and g.membros.size() >= 20 and chance(0.3):
		g.poder = "conselho"
		registrar("cultura", "social", 6, g.zona, g.id, [], {"dimensao": "poder", "valor": "conselho"})


func _arrumar_grupos() -> void:
	for g in grupos_vivos():
		if g.membros.is_empty():
			_deixar_ruinas(g)
			g.extinto = true
			registrar("extincao_grupo", "social", 8, g.zona, g.id, [], {})
			continue
		if g.membros.size() <= 3:
			var destino: Grupo = null
			var menor := 999.0
			for outro in grupos_vivos():
				if outro.id != g.id and g.hostilidade.get(outro.id, 0.0) < menor:
					menor = g.hostilidade.get(outro.id, 0.0)
					destino = outro
			if destino != null:
				var ids = g.membros.duplicate()
				_deixar_ruinas(g)
				for id in ids:
					_mudar_de_grupo(pessoas[id], destino)
				g.extinto = true
				registrar("fusao", "social", 7, destino.zona, g.id, ids, {}, destino.id)
				continue
		if g.lider == -1 or not pessoas[g.lider].vivo or pessoas[g.lider].grupo != g.id:
			_escolher_lider(g)


func _ensino() -> void:
	var a := ano()
	for g in grupos_vivos():
		if g.estagio >= 2:
			continue
		var mestres: Array = []
		var aprendizes: Array = []
		for p in _membros(g):
			if p.sabe_agricultura:
				mestres.append(p)
			elif p.idade(a) >= 12:
				aprendizes.append(p)
		if mestres.is_empty():
			# Descoberta: da necessidade e de quem é engenhoso ou curioso.
			if dia_do_ano() % DIAS_ESTACAO == 0:
				var inventores: Array = []
				for p in _adultos(g, 16):
					if p.tem("engenhoso") or p.tem("curioso"):
						inventores.append(p)
				var p_desc := 0.004 * inventores.size()
				if a - g.fome_ultima_ano <= 3:
					p_desc += 0.03 * mini(inventores.size(), 2)
				if not inventores.is_empty() and chance(p_desc):
					var inv: Pessoa = escolher(inventores)
					inv.sabe_agricultura = true
					inv.feitos += 3
					registrar("descoberta", "social", 7, g.zona, g.id, [inv.id],
						{"fome_recente": a - g.fome_ultima_ano <= 3})
			continue
		for m in mestres:
			var p_ensinar := 0.025
			if m.tem("generoso"):
				p_ensinar = 0.05
			if m.tem("desconfiado") or m.tem("ambicioso"):
				p_ensinar = 0.008
			if g.em_fome:
				p_ensinar *= 0.5
			if aprendizes.is_empty() or not chance(p_ensinar):
				continue
			var ap: Pessoa = escolher(aprendizes)
			ap.sabe_agricultura = true
			aprendizes.erase(ap)
		var sabem := 0
		for p in _membros(g):
			if p.sabe_agricultura:
				sabem += 1
		var adultos := _adultos(g, 15).size()
		if sabem >= 4 and sabem >= adultos * 0.35:
			g.estagio = 2
			registrar("agricultura", "social", 9, g.zona, g.id, [], {"sabem": sabem})
			for p in _membros(g):
				if p.idade(a) >= 12:
					p.sabe_agricultura = true


# ---------------------------------------------------------------- progresso técnico (estágios 3 a 6)

## O saber de cada estágio vive em quem o tem: é descoberto, ensinado devagar e pode morrer.
## Com a escrita, aprende-se mais rápido e o arquivo pode salvar o que se perdeu.
func _progresso_tecnico() -> void:
	var a := ano()
	for g in grupos_vivos():
		if g.estagio < 2:
			continue
		_conferir_regressao(g)
		_manter_saberes(g)
		if g.estagio >= ESTAGIO_MAX:
			continue
		var k: int = g.estagio + 1
		var saber: String = SABERES[k]
		var mestres: Array = []
		var aprendizes: Array = []
		for p in _membros(g):
			if p.saberes.has(saber):
				mestres.append(p)
			elif p.idade(a) >= 14 and p.idade(a) <= 50:
				aprendizes.append(p)
		if mestres.is_empty():
			if dia_do_ano() % DIAS_ESTACAO == 0:
				_tentar_descoberta(g, k)
			continue
		for m in mestres:
			var p_ens := 0.03 * (3.0 if g.estagio >= 5 else 1.0)
			if m.tem("generoso"):
				p_ens *= 2.0
			if m.tem("desconfiado") or m.tem("ambicioso"):
				p_ens *= 0.4
			if aprendizes.is_empty() or not chance(p_ens):
				continue
			var ap: Pessoa = escolher(aprendizes)
			ap.saberes.append(saber)
			aprendizes.erase(ap)
		var adultos := _adultos(g, 15).size()
		var sabem := mestres.size()
		for p in _membros(g):
			if p.saberes.has(saber) and not mestres.has(p):
				sabem += 1
		if sabem >= 4 and sabem >= adultos * 0.15:
			g.estagio = k
			var e := registrar("estagio", "social", 9, g.zona, g.id, [], {"estagio": k, "saber": saber, "sabem": sabem})
			if k == 5:
				g.escrita_desde = a
			if k >= 5 and not g.estudou_ceu:
				g.estudou_ceu = true
				registrar("estudo_do_ceu", "social", 6, g.zona, g.id, [], {"origem": e.id})
			if k == 3 and g.tem_crenca and not g.ceticos and g.poder == "lider" and g.sacerdote != -1 and chance(0.5):
				g.poder = "sacerdotes"
				registrar("cultura", "social", 6, g.zona, g.id, [g.sacerdote], {"dimensao": "poder", "valor": "sacerdotes"})


## Os mestres de um saber já alcançado continuam formando aprendizes enquanto forem poucos.
func _manter_saberes(g: Grupo) -> void:
	var a := ano()
	for k in range(3, g.estagio + 1):
		var saber: String = SABERES[k]
		var mestres: Array = []
		var aprendizes: Array = []
		for p in _membros(g):
			if p.saberes.has(saber):
				mestres.append(p)
			elif p.idade(a) >= 14 and p.idade(a) <= 40:
				aprendizes.append(p)
		if mestres.is_empty() or mestres.size() >= 6 or aprendizes.is_empty():
			continue
		if chance(0.06 * mestres.size() * (2.0 if g.estagio >= 5 else 1.0)):
			escolher(aprendizes).saberes.append(saber)


func _tentar_descoberta(g: Grupo, k: int) -> void:
	var a := ano()
	var inventores: Array = []
	for p in _adultos(g, 16):
		if p.tem("engenhoso") or (p.tem("curioso") and k != 4):
			inventores.append(p)
	if inventores.is_empty():
		return
	var p_desc := 0.0012 * inventores.size()
	var motivo := ""
	match k:
		3:
			if g.membros.size() < 18:
				return
			if _ja_houve_desde("terremoto", g.id, a - 4) or _ja_houve_desde("tempestade", g.id, a - 4) or _ja_houve_desde("diluvio", g.id, a - 4):
				p_desc += 0.008
				motivo = "abrigo"
		4:
			for gu in guerras:
				if (gu["a"] == g.id or gu["b"] == g.id) and a - gu["inicio"] <= 10:
					p_desc += 0.008
					motivo = "guerra"
					break
		5:
			if g.sacerdote != -1:
				p_desc += 0.008
				motivo = "sacerdote"
		6:
			if g.membros.size() < 30:
				return
			if a - g.fome_ultima_ano <= 5:
				p_desc += 0.008
				motivo = "fome"
	if not chance(p_desc):
		return
	var inv: Pessoa = escolher(inventores)
	inv.saberes.append(SABERES[k])
	inv.feitos += 3
	registrar("descoberta_tecnica", "social", 7, g.zona, g.id, [inv.id], {"saber": SABERES[k], "estagio": k, "motivo": motivo})


func _ja_houve_desde(tipo: String, gid: int, desde_ano: int) -> bool:
	for i in range(eventos.size() - 1, -1, -1):
		var e: Evento = eventos[i]
		if e.ano < desde_ano:
			return false
		if e.tipo == tipo and (e.grupo == gid or e.grupo == -1 or e.zona == grupos[gid].zona):
			return true
	return false


## Se morreu o último que sabia o saber de um estágio, o povo regride. Com a escrita, o
## arquivo pode salvar o saber.
func _conferir_regressao(g: Grupo) -> void:
	for k in range(3, g.estagio + 1):
		var saber: String = SABERES[k]
		var alguem := false
		for id in g.membros:
			if pessoas[id].saberes.has(saber):
				alguem = true
				break
		if alguem:
			continue
		if g.estagio >= 5 and k != 5 and chance(0.6):
			var leitores := _adultos(g, 16, 60)
			if not leitores.is_empty():
				var leitor: Pessoa = escolher(leitores)
				leitor.saberes.append(saber)
				registrar("arquivo_salvou", "social", 6, g.zona, g.id, [leitor.id], {"saber": saber})
				continue
		var antes := g.estagio
		g.estagio = k - 1
		registrar("regressao", "social", 8, g.zona, g.id, [], {"saber": saber, "de": antes, "para": g.estagio})
		return


## Mudanças lentas que impedem um mundo de parar: profetas e heresias, a ciência
## esvaziando os templos, revoltas e golpes, e a peste rara.
func _fe_e_poder_do_ano() -> void:
	var a := ano()
	if chance(0.006):
		_peste()
	for g in grupos_vivos():
		if g.membros.size() < 6:
			continue
		# A ciência esfria a fé: no estágio 5 em diante, quem não é devoto crê um pouco menos a cada ano.
		if g.estagio >= 5:
			for p in _membros(g):
				if not p.tem("devoto"):
					p.fe *= 0.95
		var fe_media := 0.0
		for p in _membros(g):
			fe_media += p.fe
		fe_media /= g.membros.size()
		if g.tem_crenca and not g.ceticos:
			if g.estagio >= 5 and fe_media < 0.45 and chance(0.04):
				g.ceticos = true
				g.preces.clear()
				registrar("secularizacao", "social", 8, g.zona, g.id, [], {"deus": g.nome_deus})
				continue
			if a - g.deus_renomeado_ano >= 30 and chance(0.035):
				_profeta(g)
				continue
		_mudar_poder(g)


## Alguém diz ter ouvido o deus de outro jeito. O povo aceita o nome novo, ou se divide.
func _profeta(g: Grupo) -> void:
	var candidatos: Array = []
	for p in _adultos(g, 18, 60):
		if p.id != g.sacerdote and (p.tem("devoto") or p.tem("curioso")) and p.fe > 0.3:
			candidatos.append(p)
	if candidatos.is_empty():
		return
	var profeta: Pessoa = escolher(candidatos)
	var naturezas: Array = NOMES_DEUS.keys()
	var atual := _natureza_do_nome(g.nome_deus)
	var nat: String = naturezas[rng.randi_range(0, naturezas.size() - 1)]
	if nat == atual:
		nat = naturezas[(naturezas.find(nat) + 1) % naturezas.size()]
	var opcoes: Array = NOMES_DEUS[nat]
	var escolha: Array = opcoes[rng.randi_range(0, opcoes.size() - 1)]
	profeta.feitos += 3
	profeta.fe = 1.0
	var templo_forte = g.poder == "sacerdotes" or (g.sacerdote != -1 and (pessoas[g.sacerdote].tem("rancoroso") or pessoas[g.sacerdote].tem("ambicioso")))
	var antigo := g.nome_deus
	if templo_forte and g.membros.size() >= 18 and grupos_vivos().size() < MAX_POVOS:
		var e := registrar("profeta", "social", 8, g.zona, g.id, [profeta.id], {"antigo": antigo, "novo": escolha[0],
			"genero": escolha[1], "aceito": false})
		var antes := grupos.size()
		_separar(g, profeta, "cisma", g.sacerdote, false)
		if grupos.size() > antes:
			grupos[-1].nome_deus = escolha[0]
			grupos[-1].genero_deus = escolha[1]
			grupos[-1].deus_renomeado_ano = ano()
			e.dados["novo_grupo"] = grupos[-1].id
		return
	g.nome_deus = escolha[0]
	g.genero_deus = escolha[1]
	g.deus_renomeado_ano = ano()
	registrar("profeta", "social", 8, g.zona, g.id, [profeta.id], {"antigo": antigo, "novo": escolha[0],
		"genero": escolha[1], "aceito": true})


## Quem decide muda: o povo se revolta contra o templo, um ambicioso toma o conselho,
## um povo cansado de tiranos senta em roda.
func _mudar_poder(g: Grupo) -> void:
	if g.membros.size() < 15 or not chance(0.015):
		return
	var adultos := _adultos(g, 18)
	var desconfiados := 0
	var ambicioso: Pessoa = null
	for p in adultos:
		if p.tem("desconfiado"):
			desconfiados += 1
		if p.tem("ambicioso") and p.tem("corajoso") == false and ambicioso == null and p.idade(ano()) < 50:
			ambicioso = p
	var novo := ""
	var como := ""
	match g.poder:
		"sacerdotes":
			if desconfiados >= 2 or g.estagio >= 5:
				novo = "lider"
				como = "revolta"
		"conselho":
			if ambicioso != null and (g.em_fome or not _guerra_do_grupo(g).is_empty() or chance(0.3)):
				novo = "lider"
				como = "golpe"
		"lider":
			if g.lider != -1 and (pessoas[g.lider].tem("ambicioso") or pessoas[g.lider].tem("rancoroso")):
				novo = "conselho"
				como = "tirania"
			elif g.tem_crenca and not g.ceticos and g.sacerdote != -1 and g.estagio >= 3:
				novo = "sacerdotes"
				como = "templo"
	if novo.is_empty():
		return
	g.poder = novo
	var part: Array = []
	if como == "golpe":
		g.lider = ambicioso.id
		part.append(ambicioso.id)
	elif novo == "sacerdotes":
		part.append(g.sacerdote)
		g.lider = g.sacerdote
	registrar("cultura", "social", 7, g.zona, g.id, part, {"dimensao": "poder", "valor": novo, "como": como})


func _guerra_do_grupo(g: Grupo) -> Dictionary:
	for gu in guerras:
		if gu["ativa"] and (gu["a"] == g.id or gu["b"] == g.id):
			return gu
	return {}


## A grande peste: vem de longe, entra em todos os povos e mata muito.
func _peste() -> void:
	peste_ate = dia_abs() + 20
	var e := registrar("peste", "natural", 9, "", -1, [], {})
	for g in grupos_vivos():
		if g.doenca_evento >= 0:
			continue
		var infectados: Array = []
		for p in _membros(g):
			if chance(0.65 if not g.tem_costume("queimar_mortos") else 0.4):
				p.doente = rng.randi_range(9, 16)
				p.saude = minf(p.saude, 0.7)
				infectados.append(p.id)
		if infectados.is_empty():
			continue
		g.doenca_mortos = 0
		var ed := registrar("doenca_inicio", "natural", 4, g.zona, g.id, infectados, {"n": infectados.size(), "peste": e.id})
		g.doenca_evento = ed.id
		_impressionar(g, 2.0, "doenca", ed, false)


## Um povo que acaba ou se muda deixa ruínas, que guardam o que ele sabia.
func _deixar_ruinas(g: Grupo) -> void:
	var saberes: Array = []
	if g.estagio >= 2:
		saberes.append("agricultura")
	for k in range(3, g.estagio + 1):
		saberes.append(SABERES[k])
	for o in Cotidiano.construcoes_do_grupo(self, g):
		if o["tipo"] in ["fogueira", "roca", "irrigacao", "barco"] and g.estagio < 3:
			continue
		ruinas.append({"tipo": o["tipo"], "x": o["x"], "largura": o["largura"], "estagio": o["estagio"],
			"povo": g.nome, "grupo": g.id, "era": era, "ano": ano(), "saberes": saberes})
	while ruinas.size() > 40:
		ruinas.pop_front()


## A cada estação: povos explicam ruínas de quem não existe mais e às vezes aprendem com elas.
func _ruinas_e_memoria() -> void:
	# A natureza retoma o espaço: cabanas somem em 30 anos; pedra, em 200.
	var restam: Array = []
	for r in ruinas:
		if ano() - r["ano"] < (30 if r["estagio"] <= 2 else 200):
			restam.append(r)
	ruinas = restam
	if ruinas.is_empty():
		return
	for g in grupos_vivos():
		var explicou := false
		for r in ruinas:
			var dono := grupo(r["grupo"])
			if dono == null or (not dono.extinto and r["era"] == era):
				continue
			# Ruínas guardam conhecimento.
			var proximo = "agricultura" if g.estagio == 1 else (SABERES[g.estagio + 1] if g.estagio < ESTAGIO_MAX else "")
			if not proximo.is_empty() and r["saberes"].has(proximo) and Cotidiano.zona_em(r["x"]) == g.zona and chance(0.04):
				var curiosos: Array = []
				for p in _adultos(g, 16):
					if p.tem("curioso") or p.tem("engenhoso"):
						curiosos.append(p)
				if not curiosos.is_empty():
					var c: Pessoa = escolher(curiosos)
					if proximo == "agricultura":
						c.sabe_agricultura = true
					else:
						c.saberes.append(proximo)
					c.feitos += 2
					registrar("ruinas_saber", "social", 7, g.zona, g.id, [c.id], {"saber": proximo, "povo": r["povo"], "era": r["era"]})
			# Quem vê as ruínas de um povo que acabou cria uma explicação.
			if not explicou and not g.ruinas_vistas.has(r["povo"]):
				explicou = true
				g.ruinas_vistas.append(r["povo"])
				var expl := _explicar_ruinas(g)
				registrar("mito_ruinas", "social", 6, g.zona, g.id, [], {"povo": r["povo"], "explicacao": expl,
					"era": r["era"], "estagio": r["estagio"]})


func _explicar_ruinas(g: Grupo) -> String:
	var votos := {"gigantes": 0.5, "castigo": 0.5, "gente": 0.5}
	for p in _adultos(g, 16):
		if p.tem("curioso"):
			votos["gigantes"] += 1.0
		if p.tem("devoto") or p.tem("medroso"):
			votos["castigo"] += 1.0
		if p.tem("desconfiado") or p.tem("engenhoso"):
			votos["gente"] += 1.0
	var melhor := "gente"
	var mv := -1.0
	for k in votos:
		var v: float = votos[k] + rng.randf()
		if v > mv:
			mv = v
			melhor = k
	return melhor


# ---------------------------------------------------------------- fim do mundo e eras

const ORDINAIS_ERA := ["Primeira", "Segunda", "Terceira", "Quarta", "Quinta", "Sexta", "Sétima", "Oitava", "Nona", "Décima"]


func nome_da_era(n: int = -1) -> String:
	if n < 0:
		n = era
	return "A %s Era" % ORDINAIS_ERA[mini(n, ORDINAIS_ERA.size()) - 1]


## Fecha a crônica da era como um livro. `motivo`: "" (extinção) ou "abandono".
func _fechar_livro(motivo: String) -> Dictionary:
	_cronista.processar_ate(ano())
	var titulo := nome_da_era()
	var sub := "Crônica do mundo da semente %d, do ano %d ao ano %d." % [semente, era_inicio_ano, ano()]
	if motivo == "abandono":
		sub += " O deus abandonou este mundo com o povo ainda vivo."
	var livro := {"era": era, "titulo": titulo, "ano_ini": era_inicio_ano, "ano_fim": ano(), "semente": semente,
		"texto": _cronista.montar(era_inicio_ano, ano(), titulo, sub, true, true), "na_estante": false}
	livros.append(livro)
	registrar("livro_fechado", "natural", 5, "", -1, [], {"era": era, "titulo": titulo})
	return livro


## O deus abandona o mundo: a crônica da era se fecha como livro, mesmo com o povo vivo.
func abandonar() -> Dictionary:
	_esperar_rotina()
	if fim_do_mundo and not livros.is_empty() and livros[-1]["era"] == era:
		return livros[-1]
	return _fechar_livro("abandono")


## Só com o mundo vazio: o deus cria um novo povo onde fizer o gesto (x em pixels do mundo).
## O novo povo encontra as ruínas de quem viveu antes.
func criar_povo(x: float = 275.0) -> Dictionary:
	_esperar_rotina()
	if not fim_do_mundo or populacao() > 0:
		return {"ok": false, "motivo": "só se cria um povo com o mundo vazio"}
	var zona := Cotidiano.zona_em(clampf(x, 0.0, Cotidiano.LARGURA_MUNDO - 1))
	if zona == "lago":
		zona = "praia"
	era += 1
	era_inicio_ano = ano()
	_cronista.reabrir_ano(ano())
	fim_do_mundo = false
	_ultimos_avisado = false
	linhagem.clear()
	_criar_primeiro_povo(zona)
	return {"ok": true, "grupo": grupos[-1].id, "era": era}


# ---------------------------------------------------------------- conflito

func _relacoes_entre_grupos() -> void:
	_rever_guerras()
	var vivos := grupos_vivos()
	var dia := dia_abs()
	for a_g in vivos:
		for b_g in vivos:
			if a_g == b_g:
				continue
			var h: float = a_g.hostilidade.get(b_g.id, 0.0) * 0.996
			if a_g.em_fome and b_g.estoque > a_g.estoque + 15.0:
				h += 0.12
				if a_g.lider != -1 and pessoas[a_g.lider].tem("ambicioso"):
					h += 0.08
			if a_g.zona == b_g.zona:
				h += 0.008
				if zonas[a_g.zona].comida < zonas[a_g.zona].comida_cap * 0.35:
					h += 0.03
			if a_g.estranhos < 0.0 and h > 0.5:
				h += 0.004 * -a_g.estranhos
			if a_g.proibido.has(b_g.id):
				h += 0.004
			a_g.hostilidade[b_g.id] = h
	for a_g in vivos:
		for b_g in vivos:
			if a_g == b_g or a_g.extinto or b_g.extinto:
				continue
			if a_g.tregua_ate.get(b_g.id, -1) > dia:
				continue
			var h: float = a_g.hostilidade.get(b_g.id, 0.0)
			if h < 4.0:
				continue
			var p_ataque := 0.008
			if a_g.em_fome:
				p_ataque += 0.03
			p_ataque *= 0.5 + a_g.violencia
			if a_g.poder == "conselho":
				p_ataque *= 0.6
			if a_g.lider != -1:
				var l: Pessoa = pessoas[a_g.lider]
				if l.tem("pacifico") or l.tem("medroso"):
					p_ataque *= 0.4
				if l.tem("ambicioso") or l.tem("rancoroso"):
					p_ataque *= 1.6
			if chance(p_ataque):
				_atacar(a_g, b_g)


func _forca(g: Grupo) -> Array:
	var guerreiros: Array = []
	var f := 0.0
	for p in _adultos(g, 16, 50):
		var w := 1.0
		if p.tem("corajoso"):
			w = 1.4
		elif p.tem("medroso"):
			w = 0.6
		elif p.tem("pacifico"):
			w = 0.8
		if p.sexo == "f":
			w *= 0.6
		f += w
		guerreiros.append(p)
	if g.tem_costume("lancas"):
		f *= 1.3
	if g.estagio >= 4:
		f *= 1.3
	if g.estagio >= 6 and g.violencia >= 0.5:
		f *= 1.3   # muralha
	return [f, guerreiros]


func _atacar(a_g: Grupo, b_g: Grupo) -> void:
	var fa := _forca(a_g)
	var fb := _forca(b_g)
	if fa[1].is_empty() or fb[1].is_empty():
		return
	var pa: float = fa[0] / (fa[0] + fb[0] * 1.15)
	var venceu_a := chance(pa)
	var vencedor: Grupo = a_g if venceu_a else b_g
	var perdedor: Grupo = b_g if venceu_a else a_g
	var g_venc: Array = fa[1] if venceu_a else fb[1]
	var g_perd: Array = fb[1] if venceu_a else fa[1]
	var mortos_perd := rng.randi_range(0, 2) + (1 if chance(0.3) else 0) + (1 if vencedor.estagio >= 4 else 0)
	var mortos_venc := rng.randi_range(0, 1) if chance(0.5) else 0
	var mortos: Array = []
	var zona := b_g.zona
	var guerra := _guerra_entre(a_g.id, b_g.id)
	if guerra.is_empty():
		guerra = _comecar_guerra(a_g, b_g, zona)
	elif guerra["nome"].is_empty():
		_nomear_guerra(guerra, zona)
	var e := registrar("ataque", "social", 6, zona, a_g.id, [], {"vencedor": vencedor.id,
		"mortos": [], "saque": 0.0, "primeiro": not _ja_houve("ataque", a_g.id, b_g.id),
		"guerra": guerra["id"], "batalha": guerra["batalhas"] + 1}, b_g.id)
	for lista_mortos in [[g_perd, mortos_perd, vencedor, g_venc], [g_venc, mortos_venc, perdedor, g_perd]]:
		var lado: Array = lista_mortos[0]
		for i in mini(lista_mortos[1], lado.size()):
			var v: Pessoa = lado[rng.randi_range(0, lado.size() - 1)]
			if not v.vivo:
				continue
			var matador: Pessoa = escolher(lista_mortos[3])
			mortos.append(v.id)
			e.participantes.append(v.id)
			_morrer(v, "batalha", {"matador": matador.id, "inimigo": lista_mortos[2].id, "ataque": e.id})
			matador.feitos += 1
			for q in _membros(grupo(v.grupo) if grupo(v.grupo) != null else perdedor):
				if q.mae == v.id or q.pai == v.id or q.id == v.conjuge or (q.mae == v.mae and q.mae != -1):
					q.rancores[matador.id] = q.rancores.get(matador.id, 0) + 3
	var saque := perdedor.estoque * 0.4
	perdedor.estoque -= saque
	vencedor.estoque += saque
	e.dados["mortos"] = mortos
	e.dados["saque"] = saque
	guerra["batalhas"] += 1
	guerra["mortos"] += mortos.size()
	guerra["ultimo_dia"] = dia_abs()
	guerra["vitorias"][str(vencedor.id)] = guerra["vitorias"].get(str(vencedor.id), 0) + 1
	e.importancia = 6 + mini(mortos.size(), 3)
	perdedor.hostilidade[vencedor.id] = perdedor.hostilidade.get(vencedor.id, 0.0) + 1.5 + mortos.size() * 0.5
	vencedor.hostilidade[perdedor.id] = maxf(0.0, vencedor.hostilidade.get(perdedor.id, 0.0) - 0.5)
	_impressionar(perdedor, 0.3, "guerra", e, false)
	if mortos.size() >= 2:
		_nomear_lugar(vencedor, zona, "vitoria", e)
		_nomear_lugar(perdedor, zona, "luto", e)
	if perdedor.membros.size() > 0 and not perdedor.tem_costume("lancas") and perdedor.violencia < 0.9:
		perdedor.violencia += 0.2
		if mortos.size() >= 2:
			_novo_costume(perdedor, "lancas", e)
	perdedor.ultimo_ataque_sofrido = dia_abs()
	_mudar_estranhos(perdedor, -0.15, e)
	b_g.ultimo_ataque_sofrido = dia_abs()
	_abrir_prece(perdedor, "guerra", e, -1)
	# Conquista: o vencido pequeno é absorvido.
	if perdedor.membros.size() > 0 and perdedor.membros.size() * 3 < vencedor.membros.size() \
			and perdedor.membros.size() <= 7 and chance(0.5):
		var ids := perdedor.membros.duplicate()
		_deixar_ruinas(perdedor)
		for id in ids:
			_mudar_de_grupo(pessoas[id], vencedor)
			pessoas[id].rancores[vencedor.lider] = 2
		perdedor.extinto = true
		registrar("conquista", "social", 9, zona, vencedor.id, ids, {"vencido": perdedor.id}, perdedor.id)
		_terminar_guerra(guerra, "conquista", vencedor.id)
		return
	# Trégua.
	var p_tregua := 0.06 + 0.05 * mortos.size()
	for lado in [a_g, b_g]:
		if lado.poder == "conselho":
			p_tregua += 0.12
	for lado in [a_g, b_g]:
		if lado.lider != -1 and pessoas[lado.lider].tem("pacifico"):
			p_tregua += 0.2
		if lado.lider != -1 and pessoas[lado.lider].tem("rancoroso"):
			p_tregua -= 0.1
	if chance(p_tregua):
		_tregua(a_g, b_g, zona, "cansaco")


func _guerra_entre(g1: int, g2: int) -> Dictionary:
	for gu in guerras:
		if gu["ativa"] and ((gu["a"] == g1 and gu["b"] == g2) or (gu["a"] == g2 and gu["b"] == g1)):
			return gu
	return {}


const ORDINAIS := ["", "Segunda ", "Terceira ", "Quarta ", "Quinta ", "Sexta ", "Sétima ", "Oitava ",
	"Nona ", "Décima "]


func _comecar_guerra(a_g: Grupo, b_g: Grupo, zona: String) -> Dictionary:
	var motivo := "rancor"
	if a_g.proibido.has(b_g.id):
		motivo = "santa"
	elif a_g.em_fome:
		motivo = "fome"
	elif a_g.zona == b_g.zona:
		motivo = "terra"
	elif (a_g.origem.get("pai", -1) == b_g.id or b_g.origem.get("pai", -1) == a_g.id):
		motivo = "irmaos"
	var gu := {"id": guerras.size(), "nome": "", "a": a_g.id, "b": b_g.id, "motivo": motivo,
		"inicio": ano(), "batalhas": 0, "mortos": 0, "vitorias": {}, "ultimo_dia": dia_abs(), "ativa": true}
	guerras.append(gu)
	return gu


## Na segunda batalha, a briga vira uma guerra com nome.
func _nomear_guerra(gu: Dictionary, zona: String) -> void:
	var z: Zona = zonas[zona]
	var base := ""
	match gu["motivo"]:
		"santa":
			base = "Guerra Santa"
		"fome":
			base = "Guerra da Fome"
		"irmaos":
			base = "Guerra dos Irmãos"
		_:
			base = "Guerra " + _contr_de(z.genero, 1) + " " + z.cabeca
	var usados := {}
	for outra in guerras:
		usados[outra["nome"]] = true
	var nome := base
	if usados.has(nome) and not base.contains(z.cabeca):
		nome = base + " " + _contr_de(z.genero, 1) + " " + z.cabeca
	var n := 1
	while usados.has(nome) and n < ORDINAIS.size():
		nome = ORDINAIS[n] + base
		n += 1
	gu["nome"] = nome
	registrar("guerra_inicio", "social", 8, zona, gu["a"], [], {"guerra": gu["id"], "nome": nome,
		"motivo": gu["motivo"], "ano_primeira": gu["inicio"]}, gu["b"])


func _terminar_guerra(gu: Dictionary, desfecho: String, vencedor: int) -> void:
	if not gu["ativa"]:
		return
	gu["ativa"] = false
	# O fim de uma guerra esfria os dois lados: o édito que a motivou cai, e vêm anos de trégua.
	var ga: Grupo = grupos[gu["a"]]
	var gb: Grupo = grupos[gu["b"]]
	ga.proibido.erase(gb.id)
	gb.proibido.erase(ga.id)
	var ate := dia_abs() + DIAS_ANO * 3
	ga.tregua_ate[gb.id] = maxi(ga.tregua_ate.get(gb.id, -1), ate)
	gb.tregua_ate[ga.id] = maxi(gb.tregua_ate.get(ga.id, -1), ate)
	ga.hostilidade[gb.id] = minf(ga.hostilidade.get(gb.id, 0.0), 2.0)
	gb.hostilidade[ga.id] = minf(gb.hostilidade.get(ga.id, 0.0), 2.0)
	if gu["nome"].is_empty():
		return
	if vencedor == -1:
		var va: int = gu["vitorias"].get(str(gu["a"]), 0)
		var vb: int = gu["vitorias"].get(str(gu["b"]), 0)
		if va > vb + 1:
			vencedor = gu["a"]
		elif vb > va + 1:
			vencedor = gu["b"]
	registrar("guerra_fim", "social", 8, grupos[gu["a"]].zona, gu["a"], [], {"guerra": gu["id"],
		"nome": gu["nome"], "desfecho": desfecho, "vencedor": vencedor, "batalhas": gu["batalhas"],
		"mortos": gu["mortos"], "anos": ano() - gu["inicio"]}, gu["b"])


## Guerras sem batalha há 3 anos esfriam; guerras de um povo que acabou terminam.
func _rever_guerras() -> void:
	for gu in guerras:
		if not gu["ativa"]:
			continue
		if grupos[gu["a"]].extinto or grupos[gu["b"]].extinto:
			var vivo: int = gu["b"] if grupos[gu["a"]].extinto else gu["a"]
			_terminar_guerra(gu, "extincao", vivo if not grupos[vivo].extinto else -1)
		elif dia_abs() - gu["ultimo_dia"] > DIAS_ANO * 3:
			_terminar_guerra(gu, "esfriou", -1)


func _mortos_entre(g1: int, g2: int) -> int:
	var n := 0
	for e in do_tipo("ataque"):
		if (e.grupo == g1 and e.outro_grupo == g2) or (e.grupo == g2 and e.outro_grupo == g1):
			n += e.dados["mortos"].size()
	return n


func _tregua(a_g: Grupo, b_g: Grupo, zona: String, motivo: String) -> void:
	var ate := dia_abs() + DIAS_ANO * (6 if motivo == "deus" else 4)
	a_g.tregua_ate[b_g.id] = ate
	b_g.tregua_ate[a_g.id] = ate
	a_g.hostilidade[b_g.id] = 1.0
	b_g.hostilidade[a_g.id] = 1.0
	var lideres: Array = []
	for lado in [a_g, b_g]:
		if lado.lider != -1:
			lideres.append(lado.lider)
	var guerra := _guerra_entre(a_g.id, b_g.id)
	var e := registrar("tregua", "divina" if motivo == "deus" else "social", 7, zona, a_g.id, lideres,
		{"motivo": motivo, "guerra": guerra.get("id", -1)}, b_g.id)
	if not guerra.is_empty():
		_terminar_guerra(guerra, "deus" if motivo == "deus" else "tregua", -1)
	_nomear_lugar(a_g, zona, "tregua", e)
	_nomear_lugar(b_g, zona, "tregua", e)


# ---------------------------------------------------------------- memória e cultura

const QUALIFICADORES := {
	"fome": ["Fome", "f", 1], "vitoria": ["Vitória", "f", 1], "luto": ["Luto", "m", 1],
	"tregua": ["Trégua", "f", 1], "raio": ["Raio", "m", 1], "chuva": ["Chuva", "f", 1],
	"fartura": ["Fartura", "f", 1], "cinzas": ["Cinzas", "f", 2], "pedra": ["Pedra Erguida", "f", 1],
	"lagrimas": ["Lágrimas", "f", 2], "sonho": ["Sonho", "m", 1], "aguas": ["Águas", "f", 2],
}


func _nomear_lugar(g: Grupo, zona: String, motivo: String, e: Evento) -> void:
	var z: Zona = zonas[zona]
	if z.nomes.has(g.id) or g.extinto:
		return
	var q: Array = QUALIFICADORES[motivo]
	z.nomes[g.id] = {"nome": z.cabeca + " " + _contr_de(q[1], q[2]) + " " + q[0], "evento": e.id, "motivo": motivo}
	registrar("lugar_nomeado", "social", 5, zona, g.id, [], {"nome": z.nomes[g.id]["nome"],
		"motivo": motivo, "origem": e.id})


func _contr_de(g: String, n: int) -> String:
	if n > 1:
		return "dos" if g == "m" else "das"
	return "do" if g == "m" else "da"


func nome_do_lugar(zona: String, grupo_id: int) -> String:
	var z: Zona = zonas[zona]
	if z.nomes.has(grupo_id):
		return z.nomes[grupo_id]["nome"]
	return ""


func _novo_costume(g: Grupo, tipo: String, e: Evento) -> void:
	if g.tem_costume(tipo):
		return
	g.costumes.append({"tipo": tipo, "ano": ano(), "evento": e.id, "esquecido": false})
	registrar("costume", "social", 7, g.zona, g.id, [], {"costume": tipo, "origem": e.id,
		"origem_tipo": e.tipo})


func _avaliar_costume_seca(g: Grupo, fim: Evento) -> void:
	if g.fome_mortos > 0 and g.em_fome and not g.tem_costume("agua"):
		_novo_costume(g, "agua", fim)


# ---------------------------------------------------------------- religião

const NOMES_DEUS := {
	"chuva": [["o Que Rega", "m"], ["a Mãe da Chuva", "f"], ["o Pai das Águas", "m"]],
	"raio": [["o Que Fere", "m"], ["o Senhor do Trovão", "m"], ["a Voz do Céu", "f"]],
	"fartura": [["o Que Dá", "m"], ["a Mãe da Fartura", "f"], ["o Generoso", "m"]],
	"fogo": [["o Que Queima", "m"], ["a Chama de Cima", "f"]],
	"terra": [["o Que Ergue", "m"], ["o Pai das Pedras", "m"]],
	"sonho": [["o Que Fala no Sono", "m"], ["a Voz dos Sonhos", "f"]],
	"doenca": [["o Que Leva", "m"], ["a Sombra", "f"]],
	"eclipse": [["o Olho Escuro", "m"], ["o Que Apaga o Sol", "m"]],
	"cometa": [["o Que Risca o Céu", "m"], ["a Estrela de Cauda", "f"]],
	"gemeos": [["a Mãe de Dois", "f"], ["o Que Dá em Dobro", "m"]],
	"diluvio": [["o Que Afoga", "m"], ["a Grande Água", "f"]],
	"pressagio": [["o Que Acende o Céu", "m"], ["a Luz Que Avisa", "f"]],
	"cura": [["o Que Levanta", "m"], ["a Mão Que Cura", "f"]],
	"terremoto": [["o Que Sacode", "m"], ["a Terra Brava", "f"]],
	"seca": [["o Sedento", "m"], ["o Que Seca", "m"]],
	"fome": [["o Que Nega", "m"], ["a Mão Fechada", "f"]],
	"guerra": [["o Que Julga", "m"], ["o Senhor das Lanças", "m"]],
	"tempestade": [["o Que Ruge", "m"], ["a Voz do Céu", "f"]],
}


## Uma coisa inexplicável aconteceu diante do grupo. Cada um interpreta conforme
## os próprios traços; a soma das impressões faz nascer a crença.
func _impressionar(g: Grupo, peso: float, natureza: String, e: Evento, benigno: bool) -> void:
	if g.extinto:
		return
	for p in _membros(g):
		var d := 0.05 * peso
		if p.tem("devoto"):
			d *= 2.5
		elif p.tem("desconfiado"):
			d *= -0.5
		elif p.tem("curioso"):
			d *= 1.4
		if not benigno and (p.tem("rancoroso") or p.ferida_pelo_deus):
			d = -absf(d)
		p.fe = clampf(p.fe + d, -1.0, 1.0)
	var devotos := 0
	for p in _membros(g):
		if p.tem("devoto") or p.fe > 0.4:
			devotos += 1
	if g.estagio >= 6:
		peso *= 0.6
	if g.ceticos and peso >= 2.5 and g.membros.size() >= 4 and chance(0.35):
		# O retorno do deus: depois de tanto tempo, algo inegável.
		g.ceticos = false
		for p in _membros(g):
			p.fe = maxf(p.fe, 0.4)
		registrar("renascimento", "social", 8, g.zona, g.id, [], {"origem": e.id, "deus": g.nome_deus})
	g.misterio += peso * (1.0 + 0.15 * devotos)
	if not g.tem_crenca and g.misterio >= LIMIAR_CRENCA:
		_nascer_crenca(g, natureza, e)
	elif g.tem_crenca and not g.ceticos and peso >= 2.0 and ano() - g.deus_renomeado_ano >= 12 			and (peso >= 3.0 or chance(0.5)):
		var atual := _natureza_do_nome(g.nome_deus)
		if atual != natureza and NOMES_DEUS.has(natureza):
			var antigo := g.nome_deus
			var opcoes: Array = NOMES_DEUS[natureza]
			var escolha: Array = opcoes[rng.randi_range(0, opcoes.size() - 1)]
			g.nome_deus = escolha[0]
			g.genero_deus = escolha[1]
			g.deus_renomeado_ano = ano()
			registrar("deus_renomeado", "social", 7, g.zona, g.id, [], {"antigo": antigo,
				"novo": g.nome_deus, "genero": g.genero_deus, "origem": e.id})


func _natureza_do_nome(nome: String) -> String:
	for k in NOMES_DEUS:
		for par in NOMES_DEUS[k]:
			if par[0] == nome:
				return k
	return ""


func _nascer_crenca(g: Grupo, natureza: String, e: Evento) -> void:
	if not NOMES_DEUS.has(natureza):
		natureza = "tempestade"
	var opcoes: Array = NOMES_DEUS[natureza]
	var escolha: Array = opcoes[rng.randi_range(0, opcoes.size() - 1)]
	g.tem_crenca = true
	g.ceticos = false
	g.nome_deus = escolha[0]
	g.genero_deus = escolha[1]
	g.deus_renomeado_ano = ano()
	var profeta: Pessoa = null
	var melhor := -9.0
	for p in _adultos(g, 14):
		var v = p.fe + rng.randf() * 0.3
		if p.tem("devoto"):
			v += 0.5
		if p.tem("curioso"):
			v += 0.2
		if v > melhor:
			melhor = v
			profeta = p
	var part: Array = []
	if profeta != null:
		profeta.fe = maxf(profeta.fe, 0.7)
		profeta.feitos += 3
		part.append(profeta.id)
	g.crencas.append("origem_" + natureza)
	registrar("crenca", "social", 9, g.zona, g.id, part, {"deus": g.nome_deus, "genero": g.genero_deus,
		"natureza": natureza, "origem": e.id})


func _nova_crenca(g: Grupo, chave: String, e: Evento, dados: Dictionary = {}) -> void:
	if g.tem_crenca_chave(chave):
		return
	g.crencas.append(chave)
	var d := {"crenca": chave, "origem": e.id}
	d.merge(dados)
	registrar("nova_crenca", "social", 6, g.zona, g.id, [], d)


## Um raio matou alguém. O grupo lê o fato pelos olhos de quem morreu.
func _reagir_raio(g: Grupo, vitima: Pessoa, e: Evento, divino: bool) -> void:
	for p in _membros(g):
		if p.mae == vitima.id or p.pai == vitima.id or p.id == vitima.conjuge \
				or (vitima.mae != -1 and p.mae == vitima.mae):
			p.ferida_pelo_deus = true
			p.fe = clampf(p.fe - 0.5, -1.0, 1.0)
	var leitura := "azar"
	if vitima.fe < 0.0 or vitima.tem("desconfiado"):
		leitura = "castigo"
	elif vitima.tem("devoto") or g.sacerdote == vitima.id:
		leitura = "martir"
	elif divino or chance(0.5):
		leitura = "castigo"
	e.dados["leitura"] = leitura
	_impressionar(g, 3.0 if divino else 2.0, "raio", e, false)
	if g.tem_crenca and leitura == "castigo":
		_nova_crenca(g, "castiga", e, {"vitima": vitima.id})
	if leitura == "martir" and g.tem_crenca:
		_nova_crenca(g, "martir", e, {"vitima": vitima.id})
	if not g.tem_costume("tabu_tempestade"):
		_novo_costume(g, "tabu_tempestade", e)
	_nomear_lugar(g, e.zona if e.zona != "" else g.zona, "raio", e)


func _sacerdotes() -> void:
	for g in grupos_vivos():
		if not g.tem_crenca or g.ceticos or g.sacerdote != -1 or g.membros.size() < 7:
			continue
		var melhor: Pessoa = null
		for p in _adultos(g, 20):
			if p.fe > 0.65 and p.id != g.lider and (melhor == null or p.fe > melhor.fe):
				melhor = p
		if melhor != null and chance(0.15):
			g.sacerdote = melhor.id
			melhor.feitos += 2
			registrar("sacerdote", "social", 6, g.zona, g.id, [melhor.id], {})
		continue
	# Éditos: o sacerdote fala pelo deus.
	for g in grupos_vivos():
		if g.sacerdote == -1:
			continue
		var s: Pessoa = pessoas[g.sacerdote]
		for outro in grupos_vivos():
			if outro.id == g.id or g.proibido.has(outro.id):
				continue
			var h: float = g.hostilidade.get(outro.id, 0.0)
			var p_edito := 0.1 * (2.0 if g.estagio >= 3 or g.poder == "sacerdotes" else 1.0)
			if h > 3.0 and (s.tem("rancoroso") or s.tem("ambicioso") or s.tem("desconfiado")) and chance(p_edito):
				g.proibido[outro.id] = true
				g.hostilidade[outro.id] = h + 2.0
				registrar("edito", "social", 7, g.zona, g.id, [s.id], {"alvo": outro.id}, outro.id)


func _necessidades(g: Grupo) -> Array:
	var r: Array = []
	if zonas[g.zona].seca and zonas[g.zona].agua < 0.4 and g.estagio < 6:
		r.append("seca")
	if g.em_fome:
		r.append("fome")
	if g.doenca_evento >= 0:
		r.append("doenca")
	if inverno_rigoroso and g.abrigos * PESSOAS_POR_ABRIGO < g.membros.size():
		r.append("frio")
	if dia_abs() - g.ultimo_ataque_sofrido < 20:
		r.append("guerra")
	return r


func _preces_do_dia() -> void:
	var dia := dia_abs()
	for g in grupos_vivos():
		if not g.tem_crenca or g.ceticos:
			continue
		var necessidades := _necessidades(g)
		# A necessidade passou sozinha: o grupo vê nisso a resposta.
		# Se dura demais, a prece fica sem resposta.
		for nec in g.preces.keys():
			if not g.preces.has(nec):
				continue
			var pr: Dictionary = g.preces[nec]
			if nec == "banal":
				# Pedidos pequenos somem sem resposta e sem mágoa.
				if dia - pr["dia"] > 6:
					g.preces.erase(nec)
				continue
			if not necessidades.has(nec):
				_resolver_prece(g, nec, eventos[pr["evento"]])
			elif dia - pr["dia"] > 14 and nec != "doenca":
				_prece_sem_resposta(g, nec, null)
		for nec in necessidades:
			if not g.preces.has(nec):
				_abrir_prece(g, nec, eventos[g.doenca_evento] if nec == "doenca" else null, -1)
		if g.exigente and g.preces.is_empty() and chance(0.03):
			_abrir_prece(g, "banal", null, -1)


func _abrir_prece(g: Grupo, nec: String, origem: Evento, alvo: int) -> void:
	if not g.tem_crenca or g.ceticos or g.preces.has(nec) or g.extinto:
		return
	var autor: Pessoa = null
	var crentes: Array = []
	for p in _adultos(g, 14):
		if p.fe > 0.15:
			crentes.append(p)
	if crentes.is_empty():
		return
	if nec == "doenca":
		# Uma mãe ou um pai reza por um filho doente.
		for p in crentes:
			for f in p.filhos:
				var filho: Pessoa = pessoas[f]
				if filho.vivo and filho.doente > 0 and filho.grupo == g.id and filho.idade(ano()) < 15:
					autor = p
					alvo = filho.id
					break
			if autor != null:
				break
	if autor == null:
		autor = crentes[0]
		for p in crentes:
			if p.fe > autor.fe:
				autor = p
	var part: Array = [autor.id]
	if alvo != -1:
		part.append(alvo)
	var primeira := not _ja_houve("prece", g.id) and not g.origem.has("pai")
	var imp := 6 if primeira else 3
	if nec == "banal":
		primeira = false
		imp = 2
	if alvo != -1:
		imp = 3
	var e := registrar("prece", "social", imp, g.zona, g.id, part, {"necessidade": nec,
		"alvo": alvo, "primeira": primeira, "deus": g.nome_deus, "genero_deus": g.genero_deus,
		"inimigo": origem.grupo if origem != null and nec == "guerra" else -1})
	g.preces[nec] = {"evento": e.id, "dia": dia_abs(), "autor": autor.id, "alvo": alvo}


## A necessidade de uma prece acabou: o grupo vê nisso a resposta do deus.
func _resolver_prece(g: Grupo, nec: String, resposta: Evento) -> void:
	if not g.preces.has(nec):
		return
	var pr: Dictionary = g.preces[nec]
	g.preces.erase(nec)
	var autor: Pessoa = pessoas[pr["autor"]]
	for p in _membros(g):
		p.fe = clampf(p.fe + (0.15 if not p.tem("desconfiado") else 0.03), -1.0, 1.0)
	autor.fe = clampf(autor.fe + 0.2, -1.0, 1.0)
	autor.feitos += 1
	g.silencios = maxi(0, g.silencios - 2)
	ultimo_milagre[g.id] = dia_abs()
	g.atendidas_seguidas += 1
	var falso := resposta.causa != "divina"
	registrar("prece_atendida", "social", 6, g.zona, g.id, [autor.id], {"necessidade": nec,
		"prece": pr["evento"], "resposta": resposta.id, "falso_milagre": falso})
	if not g.tem_crenca_chave("ouve_preces"):
		_nova_crenca(g, "ouve_preces", resposta)
	if nec == "seca" and not g.tem_costume("festa_chuva"):
		_novo_costume(g, "festa_chuva", resposta)
	# Um deus que sempre responde cria dependência e, depois, exigências banais.
	if g.atendidas_seguidas >= 5 and not g.dependente and not _ja_houve("dependencia", g.id) 			and g.membros.size() >= 15 and ano() - _ano_da_primeira_prece(g) >= 10:
		g.dependente = true
		var largou := ""
		for c in g.costumes:
			if c["tipo"] in ["estocar", "agua"] and (c["tipo"] != "estocar" or g.estagio < 2):
				largou = c["tipo"]
				g.costumes.erase(c)
				break
		registrar("dependencia", "social", 7, g.zona, g.id, [], {"largou": largou, "deus": g.nome_deus})
	elif g.atendidas_seguidas >= 8 and g.dependente and not g.exigente and not _ja_houve("exigencia", g.id):
		g.exigente = true
		registrar("exigencia", "social", 6, g.zona, g.id, [], {"deus": g.nome_deus})


func _ano_da_primeira_prece(g: Grupo) -> int:
	for e in do_tipo("prece"):
		if e.grupo == g.id:
			return e.ano
	return ano()


func _prece_sem_resposta(g: Grupo, nec: String, morte: Evento) -> void:
	var pr: Dictionary = g.preces[nec]
	g.preces.erase(nec)
	g.silencios += 1
	g.atendidas_seguidas = 0
	if g.dependente and not _ja_houve("desamparo", g.id):
		g.dependente = false
		g.exigente = false
		registrar("desamparo", "social", 6, g.zona, g.id, [pr["autor"]], {"deus": g.nome_deus})
	var autor: Pessoa = pessoas[pr["autor"]]
	autor.fe = clampf(autor.fe - (0.45 if morte != null else 0.2), -1.0, 1.0)
	for p in _membros(g):
		p.fe = clampf(p.fe - 0.04, -1.0, 1.0)
	var imp := 6 if morte != null else 3
	registrar("prece_sem_resposta", "social", imp, g.zona, g.id, [autor.id] + ([pr["alvo"]] if pr["alvo"] != -1 else []),
		{"necessidade": nec, "prece": pr["evento"], "morte": morte.id if morte != null else -1})
	if g.silencios >= 3:
		g.silencios = 0
		_explicar_silencio(g)


## Depois de muitas preces sem resposta, o grupo explica o silêncio do deus.
## A explicação que vence depende dos traços de quem está vivo.
func _explicar_silencio(g: Grupo) -> void:
	var votos := {"pecamos": 0.5, "testando": 0.5, "dormindo": 0.6, "favorece_outros": 0.0,
		"sacerdotes_mentem": 0.0, "nao_existe": 0.0}
	var favorecido := -1
	for outro_id in ultimo_milagre:
		if outro_id != g.id and not grupos[outro_id].extinto and dia_abs() - ultimo_milagre[outro_id] < DIAS_ANO * 2:
			favorecido = outro_id
	for p in _adultos(g, 16):
		if p.tem("devoto"):
			votos["pecamos"] += 1.0
			votos["testando"] += 0.8
		if p.tem("corajoso"):
			votos["testando"] += 0.6
		if p.tem("desconfiado"):
			votos["nao_existe"] += 0.8
			if g.sacerdote != -1:
				votos["sacerdotes_mentem"] += 1.0
		if p.tem("rancoroso") and favorecido != -1:
			votos["favorece_outros"] += 1.2
		if p.tem("ambicioso") and favorecido != -1:
			votos["favorece_outros"] += 0.6
		if p.fe < -0.2:
			votos["nao_existe"] += 0.5
		if p.tem("medroso"):
			votos["pecamos"] += 0.6
	var melhor := "dormindo"
	var total := 0.0
	for k in votos:
		total += votos[k]
	var r := rng.randf() * total
	for k in votos:
		r -= votos[k]
		if r <= 0.0:
			melhor = k
			break
	var dados := {"explicacao": melhor, "favorecido": favorecido}
	var e := registrar("silencio", "social", 8, g.zona, g.id, [], dados, favorecido)
	match melhor:
		"pecamos":
			_novo_costume(g, "oferendas", e)
			# Busca de culpados: alguém que duvida paga pelo silêncio.
			var suspeito: Pessoa = null
			for p in _adultos(g, 16):
				if p.id != g.lider and p.id != g.sacerdote and (p.tem("desconfiado") or p.fe < -0.1):
					suspeito = p
					break
			if suspeito != null and chance(0.6):
				var destino := "expulso"
				if g.violencia > 0.6 or chance(0.3):
					destino = "morto"
				e.participantes.append(suspeito.id)
				suspeito.feitos += 2
				if destino == "morto":
					_morrer(suspeito, "culpado", {"silencio": e.id})
				else:
					var abrigo_para: Grupo = null
					for outro in grupos_vivos():
						if outro.id != g.id and outro.hostilidade.get(g.id, 0.0) < 5.0:
							abrigo_para = outro
							break
					var ev := registrar("culpado", "social", 7, g.zona, g.id, [suspeito.id],
						{"destino": destino, "para": abrigo_para.id if abrigo_para != null else -1})
					if abrigo_para != null:
						_mudar_de_grupo(suspeito, abrigo_para)
					else:
						_morrer(suspeito, "exilio", {"culpado": ev.id})
		"testando":
			for p in _membros(g):
				if p.fe > 0.0:
					p.fe = minf(1.0, p.fe + 0.2)
			_nova_crenca(g, "testando", e)
		"dormindo":
			for p in _membros(g):
				p.fe *= 0.6
			_nova_crenca(g, "dormindo", e)
		"favorece_outros":
			g.hostilidade[favorecido] = g.hostilidade.get(favorecido, 0.0) + 3.0
			_nova_crenca(g, "favorece_outros", e, {"favorecido": favorecido})
		"sacerdotes_mentem":
			var s := g.sacerdote
			g.sacerdote = -1
			pessoas[s].fe -= 0.3
			e.participantes.append(s)
			if g.membros.size() >= 10:
				var lider_cisma: Pessoa = null
				for p in _adultos(g, 18):
					if p.tem("desconfiado") and p.id != g.lider:
						lider_cisma = p
						break
				if lider_cisma != null:
					_separar(g, lider_cisma, "cisma", s, true)
		"nao_existe":
			for p in _membros(g):
				p.fe = minf(p.fe, 0.0) if not p.tem("devoto") else p.fe
			g.ceticos = true
			g.preces.clear()
			_nova_crenca(g, "nao_existe", e)
			if g.membros.size() >= 10:
				var fiel: Pessoa = null
				for p in _adultos(g, 18):
					if p.tem("devoto") and p.id != g.lider:
						fiel = p
						break
				if fiel != null and chance(0.5):
					_separar(g, fiel, "cisma", g.lider, false)


# ---------------------------------------------------------------- o deus

const PODERES := ["chuva", "raio", "fartura", "fogo", "erguer", "sonho",
	"seca", "diluvio", "terremoto", "pressagio", "cura"]
const PESO_GRAU := {"sinal": 1.0, "milagre": 3.0, "imposicao": 4.5}
const ALCANCE_ALVO := 6.0   # pixels: raio e sonho acertam quem está a esta distância de x


func _executar_comandos() -> void:
	while _proximo_comando < comandos.size():
		var c: Dictionary = comandos[_proximo_comando]
		if c.has("condicao"):
			break
		var quando: int = ((c["ano"] - 1) * DIAS_ANO + c["dia"]) * HORAS_DIA + c["hora"]
		if quando > passo:
			return
		_proximo_comando += 1
		if not fim_do_mundo:
			_comando_de_cenario(c)


## Comandos condicionais: disparam uma vez, quando a condição acontece.
func _executar_condicionais() -> void:
	for i in range(_proximo_comando, comandos.size()):
		var c: Dictionary = comandos[i]
		if not c.has("condicao") or c["usado"] or ano() < c["desde_ano"]:
			continue
		if c.get("repetir", false) and ano() - c["ultimo_ano"] < 1:
			continue
		var onde := _onde_acontece(c["condicao"])
		if onde.is_empty():
			continue
		c["usado"] = not c.get("repetir", false)
		c["ultimo_ano"] = ano()
		var cc := c.duplicate()
		if cc["zona"].is_empty():
			cc["zona"] = onde
		if not fim_do_mundo:
			_comando_de_cenario(cc)


## Zona onde a condição está acontecendo agora, ou "".
func _onde_acontece(condicao: String) -> String:
	match condicao:
		"seca":
			if seca_global and seca_evento >= 0 and dia_abs() - _dia_do_evento(seca_evento) >= 3:
				for g in grupos_vivos():
					if zonas[g.zona].seca:
						return g.zona
		"fome":
			for g in grupos_vivos():
				if g.em_fome:
					return g.zona
		"doenca":
			for g in grupos_vivos():
				if g.doenca_evento >= 0:
					return g.zona
		"prece":
			for g in grupos_vivos():
				if not g.preces.is_empty():
					return g.zona
		"guerra":
			for gu in guerras:
				if gu["ativa"] and gu["ultimo_dia"] == dia_abs():
					return grupos[gu["b"]].zona
	return ""


## Um comando de cenário vira um gesto: x no centro da zona, ou sobre o alvo.
func _comando_de_cenario(c: Dictionary) -> void:
	var z: String = c["zona"]
	var ali := grupos_na_zona(z)
	var alvo := -1
	if not ali.is_empty():
		var g0: Grupo = ali[0]
		if c["alvo"] == "lider" and g0.lider != -1:
			alvo = g0.lider
		elif c["poder"] == "raio":
			var adultos := _adultos(g0, 14)
			if not adultos.is_empty():
				alvo = escolher(adultos).id
	var x := Cotidiano.centro_da_zona(z)
	if alvo != -1:
		x = _rotina_de_hoje().instante(alvo, hora() * 60.0 + 30.0)["x"]
	_poder({"poder": c["poder"], "zona": z, "x": x, "intensidade": c.get("intensidade", 0.8),
		"alvo": alvo, "texto": c["texto"]})


func _poder(c: Dictionary) -> Dictionary:
	var z: Zona = zonas[c["zona"]]
	var ali := grupos_na_zona(z.chave)
	var g0_id: int = ali[0].id if not ali.is_empty() else -1
	var inten: float = c["intensidade"]
	var x: float = c["x"]
	# Repetição: o mesmo poder na mesma zona em poucos dias.
	var rep := 0
	var novos_usos: Array = []
	for u in _usos_recentes:
		if dia_abs() - u["dia"] <= 3:
			novos_usos.append(u)
			if u["poder"] == c["poder"] and u["zona"] == z.chave:
				rep += 1
	novos_usos.append({"poder": c["poder"], "zona": z.chave, "dia": dia_abs()})
	_usos_recentes = novos_usos
	# Precisão: raio e sonho acertam quem está sob o gesto.
	var alvo: Pessoa = null
	if c["poder"] in ["raio", "sonho"]:
		if c["alvo"] != -1 and pessoas.has(c["alvo"]) and pessoas[c["alvo"]].vivo:
			alvo = pessoas[c["alvo"]]
		else:
			alvo = _pessoa_perto(x)
	var grau := "sinal"
	if rep >= 2:
		grau = "imposicao"
	elif inten >= 0.5:
		grau = "milagre"
	var peso: float = PESO_GRAU[grau]
	var dados := {"comando": c["texto"], "grau": grau, "x": x, "intensidade": inten, "repeticao": rep}
	var e: Evento = null
	match c["poder"]:
		"chuva":
			var em_seca := z.seca or z.agua < 0.5
			z.agua = minf(1.0, z.agua + 0.4 + 0.6 * inten)
			var acabou_seca := em_seca and (inten >= 0.5 or grau == "imposicao")
			if acabou_seca:
				z.seca = false
			z.comida = minf(z.comida_cap, z.comida + z.comida_cap * 0.2 * inten)
			dados["em_seca"] = em_seca
			dados["acabou_seca"] = acabou_seca
			e = registrar("chuva_divina", "divina", (7 if acabou_seca else 4) if em_seca else 3, z.chave, g0_id, [], dados)
			for g in ali:
				_impressionar(g, peso if em_seca else peso * 0.3, "chuva", e, true)
				if acabou_seca:
					_resolver_prece(g, "seca", e)
			if acabou_seca:
				# Quem continua na seca vê a chuva cair só sobre os outros.
				for g in grupos_vivos():
					if g.zona != z.chave and zonas[g.zona].seca:
						for favorecido in ali:
							g.hostilidade[favorecido.id] = g.hostilidade.get(favorecido.id, 0.0) + 1.0
						_impressionar(g, 1.0, "chuva", e, false)
				for g in ali:
					_nomear_lugar(g, z.chave, "chuva", e)
			if grau == "imposicao":
				_impor_paz(ali, z.chave)
		"raio":
			e = registrar("raio_divino", "divina", 7, z.chave, g0_id, [], dados)
			if alvo == null or grau == "sinal":
				# Raio solitário: cai perto, não mata.
				e.importancia = 4
				e.dados["vitima"] = -1
				for g in ali:
					_impressionar(g, peso * 0.6, "raio", e, false)
			else:
				var g_v: Grupo = grupos[alvo.grupo]
				e.dados["vitima"] = alvo.id
				e.dados["era_lider"] = g_v.lider == alvo.id
				e.participantes.append(alvo.id)
				e.importancia = 9 if g_v.lider == alvo.id else 8
				_morrer(alvo, "raio_divino")
				_reagir_raio(g_v, alvo, e, true)
				for g in ali:
					if g != g_v:
						_impressionar(g, 2.0, "raio", e, false)
			if grau == "imposicao":
				_impor_paz(ali, z.chave)
				for g in ali:
					g.amaldicoada = true
		"fartura":
			z.comida = z.comida_cap * (1.0 + 0.8 * inten)
			var em_fome := false
			for g in ali:
				em_fome = em_fome or g.em_fome
			dados["em_fome"] = em_fome
			e = registrar("fartura_divina", "divina", 7 if em_fome and grau != "sinal" else 4, z.chave, g0_id, [], dados)
			for g in ali:
				g.estoque += (2.0 + 6.0 * inten) * g.membros.size()
				_impressionar(g, peso * (1.0 if em_fome else 0.4), "fartura", e, true)
				_resolver_prece(g, "fome", e)
				if em_fome and grau != "sinal":
					_nomear_lugar(g, z.chave, "fartura", e)
			for g in grupos_vivos():
				if g.zona != z.chave and g.em_fome and not ali.is_empty():
					g.hostilidade[ali[0].id] = g.hostilidade.get(ali[0].id, 0.0) + 1.5
		"fogo":
			var f := 0.3 + 0.6 * inten
			z.comida *= 1.0 - f
			z.madeira *= 1.0 - f
			z.queimada_ate = dia_abs() + int(DIAS_ANO * inten)
			e = registrar("fogo_divino", "divina", 7 if grau != "sinal" else 4, z.chave, g0_id, [], dados)
			var mortos: Array = []
			for g in ali:
				g.abrigos = maxi(0, g.abrigos - int(round(g.abrigos * f * 0.8)))
				g.estoque *= 1.0 - f * 0.5
				for p in _membros(g):
					if chance(0.08 * inten):
						mortos.append(p.id)
						_morrer(p, "fogo")
				_impressionar(g, peso, "fogo", e, false)
				if grau != "sinal":
					_nomear_lugar(g, z.chave, "cinzas", e)
				var amaldicoados := 0
				for p in _membros(g):
					if p.tem("desconfiado") or p.tem("rancoroso") or p.tem("medroso"):
						amaldicoados += 1
				g.amaldicoada = g.amaldicoada or (grau != "sinal" and amaldicoados * 2 >= g.membros.size())
				e.dados["leitura_" + str(g.id)] = "maldicao" if g.amaldicoada else "purificacao"
			e.dados["mortos"] = mortos
			e.participantes = mortos
		"erguer":
			z.monte_erguido = true
			z.pedra_x = x
			e = registrar("terra_erguida", "divina", 8 if grau != "sinal" else 5, z.chave, g0_id, [], dados)
			for g in grupos_vivos():
				var p_imp := peso if g.zona == z.chave else peso * 0.4
				_impressionar(g, p_imp, "terra", e, true)
				if grau != "sinal":
					if g.tem_crenca and g.zona == z.chave:
						_nova_crenca(g, "lugar_sagrado", e, {"zona": z.chave})
					_nomear_lugar(g, z.chave, "pedra", e)
			# A terra erguida separa grupos em guerra.
			if grau != "sinal":
				_impor_paz(ali, z.chave)
		"sonho":
			if alvo == null:
				for g in ali:
					var melhor := -9.0
					for p in _adultos(g, 15):
						var v := rng.randf()
						if p.tem("engenhoso") or p.tem("curioso"):
							v += 1.0
						if v > melhor:
							melhor = v
							alvo = p
					break
			if alvo == null:
				e = registrar("sonho", "divina", 2, z.chave, -1, [], dados.merged({"sonhador": -1}))
				return {"ok": true, "grau": grau, "evento": e.id, "zona": z.chave, "alvo": -1}
			var g: Grupo = grupos[alvo.grupo]
			var ideia := "visao"
			if g.estagio == 1 and not alvo.sabe_agricultura:
				ideia = "agricultura"
			elif g.estagio >= 2 and g.estagio < ESTAGIO_MAX and not alvo.saberes.has(SABERES[g.estagio + 1]):
				ideia = SABERES[g.estagio + 1]
			var p_aceita := 0.4 if alvo.tem("desconfiado") else 0.85
			if grau == "sinal":
				p_aceita *= 0.5
			elif grau == "imposicao":
				p_aceita = 1.0
			var aceita := chance(p_aceita)
			dados.merge({"sonhador": alvo.id, "ideia": ideia, "aceita": aceita})
			e = registrar("sonho", "divina", 7, g.zona, g.id, [alvo.id], dados)
			alvo.feitos += 2
			if aceita:
				alvo.fe = clampf(alvo.fe + 0.5, -1.0, 1.0)
				if ideia == "agricultura":
					alvo.sabe_agricultura = true
				elif ideia != "visao":
					alvo.saberes.append(ideia)
				_impressionar(g, peso * 0.4, "sonho", e, true)
				if ideia == "visao" and g.sacerdote == -1 and g.tem_crenca:
					g.sacerdote = alvo.id
					registrar("sacerdote", "divina", 7, g.zona, g.id, [alvo.id], {"sonho": e.id})
			if grau == "imposicao":
				# Os líderes em guerra têm o mesmo sonho.
				_impor_paz([g], g.zona)
		"seca":
			var dias := int(6 + 22 * inten) * (2 if grau == "imposicao" else 1)
			e = registrar("seca_divina", "divina", 7 if grau != "sinal" else 4, z.chave, g0_id, [],
				dados.merged({"dias": dias}))
			z.seca = true
			z.seca_ate = maxi(z.seca_ate, dia_abs() + dias)
			z.seca_evento = e.id
			z.agua = minf(z.agua, 0.6 - 0.4 * inten)
			for g in ali:
				_impressionar(g, peso, "seca", e, false)
				# "Estamos sendo castigados. O que fizemos?"
				if g.tem_crenca and not g.ceticos and grau != "sinal":
					_nova_crenca(g, "castiga", e, {"vitima": -1})
					if grau == "imposicao" or g.silencios >= 1:
						_novo_costume(g, "oferendas", e)
		"diluvio":
			var alcance: Array = [z.chave]
			var ordem := Cotidiano.FAIXAS.keys()
			if grau == "imposicao":
				alcance = ordem.duplicate()
			elif inten >= 0.7:
				var i := ordem.find(z.chave)
				for j in [i - 1, i + 1]:
					if j >= 0 and j < ordem.size():
						alcance.append(ordem[j])
			e = registrar("diluvio", "divina", 9 if grau != "sinal" else 5, z.chave, g0_id, [],
				dados.merged({"zonas": alcance, "mortos": [], "cabanas": 0}))
			for chave in alcance:
				var zz: Zona = zonas[chave]
				zz.alagada_ate = dia_abs() + int(4 + 10 * inten)
				zz.seca = false
				zz.seca_ate = -1
				zz.agua = 1.0
				zz.comida *= 1.0 - 0.6 * inten
				for g in grupos_na_zona(chave):
					var perdidas := int(round(g.abrigos * (0.3 + 0.7 * inten)))
					g.abrigos -= perdidas
					e.dados["cabanas"] += perdidas
					g.estoque *= 1.0 - 0.7 * inten
					for p in _membros(g):
						if chance(0.18 * inten * (1.6 if p.idade(ano()) < 8 or p.idade(ano()) > 60 else 1.0)):
							e.dados["mortos"].append(p.id)
							e.participantes.append(p.id)
							_morrer(p, "diluvio")
			for g in grupos_vivos():
				var atingido: bool = alcance.has(g.zona)
				_impressionar(g, peso * (1.3 if atingido else 0.5), "diluvio", e, false)
				if atingido and grau != "sinal":
					_nomear_lugar(g, g.zona, "aguas", e)
					if g.tem_crenca:
						_nova_crenca(g, "diluvio", e)
			e.importancia = mini(10, e.importancia + mini(e.dados["mortos"].size() / 3, 1))
		"terremoto":
			e = _terremoto(z.chave, inten, dados, peso)
			for g in ali:
				if g.tem_crenca and not g.ceticos and grau != "sinal":
					_nova_crenca(g, "castiga", e, {"vitima": -1})
		"pressagio":
			e = registrar("pressagio", "divina", 7 if grau != "sinal" else 5, "", -1, [],
				dados.merged({"leituras": {}, "forma": ["cometa", "eclipse", "luzes"][int(inten * 2.99)]}))
			# Ninguém sabe o que significa, e todos opinam: cada povo lê do seu jeito.
			for g in grupos_vivos():
				var p_imp := peso * _crenca_no_ceu(g)
				_impressionar(g, p_imp, "pressagio", e, true)
				var leitura := _ler_pressagio(g)
				e.dados["leituras"][g.id] = leitura
				match leitura:
					"bom":
						for p in _membros(g):
							p.fe = clampf(p.fe + 0.1, -1.0, 1.0)
					"mau":
						for outro in grupos_vivos():
							if outro != g and g.hostilidade.get(outro.id, 0.0) > 2.0:
								g.hostilidade[outro.id] += 1.0
					"aviso":
						g.estoque += 0.0
						if not g.tem_costume("estocar") and not g.dependente and grau != "sinal":
							_novo_costume(g, "estocar", e)
		"cura":
			if alvo == null:
				alvo = _pessoa_perto(x)
			if alvo == null:
				e = registrar("cura", "divina", 2, z.chave, g0_id, [], dados.merged({"curado": -1}))
				return {"ok": true, "grau": grau, "evento": e.id, "zona": z.chave, "alvo": -1}
			var g_c: Grupo = grupos[alvo.grupo]
			var condenado := alvo.doente > 0 or alvo.saude < 0.5
			var curados: Array = [alvo]
			if grau == "imposicao":
				for p in _membros(g_c):
					if p != alvo and p.doente > 0:
						curados.append(p)
			for p in curados:
				p.doente = 0
				p.saude = 1.0
			if not condenado and grau != "imposicao":
				grau = "sinal"
				peso = PESO_GRAU["sinal"]
			var ids: Array = []
			for p in curados:
				ids.append(p.id)
			e = registrar("cura", "divina", 8 if condenado else 3, g_c.zona, g_c.id, ids,
				dados.merged({"curado": alvo.id, "condenado": condenado, "grau": grau, "n": curados.size()}))
			if condenado:
				# Milagre pessoal: nasce um devoto, às vezes um profeta.
				alvo.fe = 1.0
				alvo.feitos += 3
				alvo.ferida_pelo_deus = false
				_impressionar(g_c, peso, "cura", e, true)
				for nec in g_c.preces.keys():
					if g_c.preces[nec]["alvo"] == alvo.id or (nec == "doenca" and grau == "imposicao"):
						_resolver_prece(g_c, nec, e)
				if g_c.tem_crenca and not g_c.ceticos and g_c.sacerdote == -1 and alvo.idade(ano()) >= 16:
					g_c.sacerdote = alvo.id
					registrar("sacerdote", "divina", 7, g_c.zona, g_c.id, [alvo.id], {"cura": e.id})
	return {"ok": true, "grau": grau, "evento": e.id if e != null else -1, "zona": z.chave,
		"alvo": alvo.id if alvo != null else -1}


## Quanto um povo ainda se impressiona com sinais no céu (cai com o estudo do céu).
func _crenca_no_ceu(g: Grupo) -> float:
	if g.estagio >= 6:
		return 0.25
	if g.estagio >= 5:
		return 0.5
	return 1.0


## Como um povo lê um presságio: pelos traços de quem está vivo e pelo que viveu.
func _ler_pressagio(g: Grupo) -> String:
	var votos := {"bom": 0.5, "mau": 0.5, "aviso": 0.5}
	for p in _adultos(g, 16):
		if p.tem("devoto") or p.tem("generoso"):
			votos["bom"] += 1.0
		if p.tem("medroso") or p.tem("rancoroso") or p.ferida_pelo_deus:
			votos["mau"] += 1.0
		if p.tem("desconfiado") or p.tem("engenhoso"):
			votos["aviso"] += 0.8
	if g.em_fome or g.doenca_evento >= 0:
		votos["mau"] += 1.5
	var total := 0.0
	for k in votos:
		total += votos[k]
	var r := rng.randf() * total
	for k in votos:
		r -= votos[k]
		if r <= 0.0:
			return k
	return "aviso"


## Imposição: os grupos dados fazem trégua com todos os inimigos.
func _impor_paz(lista: Array, zona: String) -> void:
	for g in lista:
		if g.extinto:
			continue
		for outro in grupos_vivos():
			if outro != g and g.hostilidade.get(outro.id, 0.0) >= 3.0:
				_tregua(g, outro, zona, "deus")


## A pessoa viva mais perto de x, se estiver a no máximo ALCANCE_ALVO pixels.
func _pessoa_perto(x: float) -> Pessoa:
	var melhor: Pessoa = null
	var dist := ALCANCE_ALVO
	var ro = _rotina_de_hoje()
	var h := hora()
	for g in grupos_vivos():
		for id in g.membros:
			var d: float = absf(ro.agenda(id, h)[-1]["x1"] - x)
			if d <= dist:
				dist = d
				melhor = pessoas[id]
	return melhor


# ---------------------------------------------------------------- API para a apresentação
# Documentada em nucleo/API.md. A apresentação só lê por estas funções e só
# age por usar_poder(), acompanhar() e avancar_hora().

## Eventos que pedem a atenção do deus.
const TIPOS_CHAMADO := ["prece", "fome_inicio", "doenca_inicio", "ataque", "os_ultimos",
	"silencio", "culpado", "conhecimento_perdido", "fim_do_mundo"]


func tempo() -> Dictionary:
	var h := hora()
	return {"passo": passo, "hora": h, "dia": dia_do_ano() + 1, "ano": ano(),
		"estacao": ESTACOES[estacao()], "noite": h >= 20 or h < 6}


func clima() -> Dictionary:
	var temp := {}
	if not tempestade.is_empty() and hora() >= tempestade["inicio"]:
		var f: Array = Cotidiano.FAIXAS[tempestade["zona"]]
		temp = {"zona": tempestade["zona"], "x_ini": f[0], "x_fim": f[1]}
	return {"seca": seca_global, "inverno_rigoroso": inverno_rigoroso, "tempestade": temp}


func zonas_visiveis() -> Array:
	var r: Array = []
	for chave in Cotidiano.FAIXAS:
		var z: Zona = zonas[chave]
		var f: Array = Cotidiano.FAIXAS[chave]
		var nomes := {}
		for gid in z.nomes:
			nomes[gid] = z.nomes[gid]["nome"]
		r.append({"chave": chave, "nome": z.nome, "x_ini": f[0], "x_fim": f[1],
			"agua": z.agua, "comida": clampf(z.comida / z.comida_cap, 0.0, 2.0), "seca": z.seca,
			"queimada": z.queimada_ate > dia_abs(), "alagada": z.alagada_ate > dia_abs(),
			"pedra_erguida": z.monte_erguido,
			"pedra_x": z.pedra_x, "nomes": nomes})
	return r


func grupos_visiveis() -> Array:
	var r: Array = []
	for g in grupos_vivos():
		var f := Cotidiano.faixa_do_grupo(self, g)
		r.append({"id": g.id, "nome": g.nome, "zona": g.zona, "x_ini": f[0], "x_fim": f[1],
			"membros": g.membros.size(), "estagio": g.estagio, "lider": g.lider, "sacerdote": g.sacerdote,
			"nome_deus": g.nome_deus if g.tem_crenca and not g.ceticos else "",
			"ceticos": g.ceticos, "em_fome": g.em_fome, "doenca": g.doenca_evento >= 0,
			"costumes": g.costumes.map(func(c): return c["tipo"]),
			"estranhos": g.estranhos, "mortos": g.mortos, "dependente": g.dependente,
			"cultura": cultura_do_grupo(g), "aparencia": g.aparencia.duplicate(),
			"escreve": g.escrita_desde >= 0,
			"origem": g.origem.duplicate()})
	return r


## Guerras em andamento que já têm nome (duas batalhas ou mais).
func guerras_ativas() -> Array:
	var r: Array = []
	for gu in guerras:
		if gu["ativa"] and not gu["nome"].is_empty():
			r.append({"id": gu["id"], "nome": gu["nome"], "a": gu["a"], "b": gu["b"], "motivo": gu["motivo"],
				"inicio": gu["inicio"], "batalhas": gu["batalhas"], "mortos": gu["mortos"]})
	return r


## As 6 dimensões culturais de um povo, como palavras (documento funcional, "Culturas").
func cultura_do_grupo(g: Grupo) -> Dictionary:
	var deus := ""
	if g.tem_crenca:
		if g.ceticos:
			deus = "cetica"
		elif g.tem_crenca_chave("castiga") or g.tem_costume("oferendas"):
			deus = "temerosa"
		else:
			deus = "devota"
	return {"deus": deus, "estranhos": "acolhedora" if g.estranhos >= 0.0 else "desconfiada",
		"poder": g.poder, "recursos": g.recursos,
		"violencia": "guerreira" if g.violencia >= 0.6 else "pacifica", "mortos": g.mortos}


## Construções abandonadas, de povos que acabaram ou se mudaram, e de eras anteriores.
func ruinas_visiveis() -> Array:
	var r: Array = []
	for ru in ruinas:
		var g: Grupo = grupo(ru.get("grupo", -1))
		r.append({"tipo": ru["tipo"], "x": ru["x"], "largura": ru["largura"], "estagio": ru["estagio"],
			"povo": ru["povo"], "era": ru["era"], "ano": ru["ano"], "anos": ano() - ru["ano"], "ruina": true,
			"aparencia": g.aparencia if g != null else {}})
	return r


var _construcoes_chave: Array = []
var _construcoes: Array = []
var _obras_por_grupo: Dictionary = {}   # id do grupo -> [assinatura, construções] (não é salvo)


## Guardadas por hora: o mesmo array volta até a hora seguinte (copie se precisar guardar).
func construcoes() -> Array:
	var chave := [passo, eventos.size()]
	if chave == _construcoes_chave:
		return _construcoes
	var r: Array = []
	for g in grupos_vivos():
		# Cada povo só refaz as peças quando algo que as define muda.
		var assinatura := [g.zona, g.abrigos, g.estagio, g.membros.size(), g.tem_crenca, g.ceticos,
			g.tem_costume("estocar"), g.violencia >= 0.5, grupos_na_zona(g.zona).size()]
		var guardado: Array = _obras_por_grupo.get(g.id, [])
		if guardado.is_empty() or guardado[0] != assinatura:
			var obras := Cotidiano.construcoes_do_grupo(self, g)
			for o in obras:
				o["aparencia"] = g.aparencia   # a cultura do povo: parede, telhado, símbolo
			guardado = [assinatura, obras]
			_obras_por_grupo[g.id] = guardado
		r.append_array(guardado[1])
	_construcoes = r
	_construcoes_chave = chave
	return r


## A rotina em uso: planos de todos e cenas. Uma consulta pura, que não toca no sorteio do
## mundo. Normalmente vem pronta da thread (veja _cuidar_da_rotina); só a primeira consulta
## depois de criar, carregar ou saltar dias a monta aqui, de uma vez.
func rotina():
	_consultado = true
	_receber_rotina(false)
	var d := dia_abs()
	var ro = _rotina_cache
	if ro == null or ro.dia < d - 1 or (ro.dia < d and hora() >= HORA_TROCA):
		var a_tempo: bool = _montando != null and _montando.dia == d
		_receber_rotina(true)
		if not a_tempo:
			var nova = Rotina.new(self, d)
			nova.montar()
			nova.eventos_vistos = eventos.size()
			_trocar_rotina(nova)
			desempenho["montagens_na_consulta"] += 1
	elif ro.dia < d and hora() >= HORA_MONTAR and _montando == null:
		# Chegou de madrugada sem a rotina do dia ter começado (um salto que parou às 3h, por
		# exemplo): começa agora, para o passo das 4h não ter de esperar por ela inteira.
		_montar_em_paralelo()
	return _rotina_cache


## A rotina de hoje, mesmo antes de ela entrar em uso (então espera por ela ou a monta
## aqui). É o que a simulação usa quando lê posições (o alvo de um poder): o resultado não
## pode depender de a apresentação estar olhando.
func _rotina_de_hoje():
	var d := dia_abs()
	var consultado := _consultado   # a simulação lendo posições não conta como consulta
	var ro = rotina()
	_consultado = consultado
	if ro.dia != d:
		_esperar_rotina()
		ro = _rotina_cache
	if ro.dia != d:
		ro = Rotina.new(self, d)
		ro.montar()
		ro.eventos_vistos = eventos.size()
		_trocar_rotina(ro)
		desempenho["montagens_na_consulta"] += 1
	return ro


func _trocar_rotina(nova) -> void:
	var velha = _rotina_cache
	_rotina_cache = nova
	_rotina_versao += 1
	while not _descartes.is_empty() and WorkerThreadPool.is_task_completed(_descartes[0][0]):
		WorkerThreadPool.wait_for_task_completion(_descartes.pop_front()[0])
	if velha != null:
		# Soltar a rotina velha custa vários ms na linha principal: a thread esvazia as listas
		# dela, e a lista de descartes a segura viva até lá.
		_descartes.append([WorkerThreadPool.add_task(velha.desmontar, false, "rotina velha"), velha])


## Chamado no fim do passo, quando a apresentação está olhando. Na virada do dia, a partir
## da HORA_MONTAR, manda montar a rotina do dia numa thread; ela entra quando fica pronta
## (na HORA_TROCA, se ainda não ficou, espera por ela). No meio do dia, um evento que vira cena (nascimento,
## ataque, tempestade...) ou alguém sem plano manda montar de novo; até a nova ficar
## pronta, vale a anterior.
func _cuidar_da_rotina() -> void:
	if _rotina_cache == null:
		return
	_receber_rotina(false)
	var d := dia_abs()
	if _rotina_cache.dia != d:
		if _montando == null and hora() >= HORA_MONTAR:
			_montar_em_paralelo()
		if hora() >= HORA_TROCA:
			_receber_rotina(true)
	elif _montando == null and _rotina_mudou():
		_montar_em_paralelo()


func _montar_em_paralelo() -> void:
	var d := dia_abs()
	_montando = Rotina.new(self, d)
	_montando.eventos_vistos = eventos.size()
	# A tarefa segura o mundo (bind) até ser recolhida: ele não pode sumir no meio da montagem.
	_tarefa = WorkerThreadPool.add_task(_montando.montar.bind(self), false, "rotina do dia")


## Põe em uso a rotina montada na thread, se ficou pronta (ou esperando por ela).
func _receber_rotina(esperar: bool) -> void:
	if _montando == null:
		return
	if not WorkerThreadPool.is_task_completed(_tarefa):
		if not esperar:
			return
		desempenho["esperas"] += 1
	WorkerThreadPool.wait_for_task_completion(_tarefa)
	var nova = _montando
	_montando = null
	if _rotina_cache == null or nova.dia >= _rotina_cache.dia:
		_trocar_rotina(nova)


## A thread só lê o mundo enquanto monta a rotina: antes de qualquer mudança (um passo, um
## poder, um povo novo), espera por ela. No jogo ela termina em décimos de segundo, muito
## antes de o passo seguinte chegar, e a espera não acontece.
func _esperar_rotina() -> void:
	if _montando != null:
		_receber_rotina(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _montando != null:
			WorkerThreadPool.wait_for_task_completion(_tarefa)
		for d in _descartes:
			WorkerThreadPool.wait_for_task_completion(d[0])


## Algo novo pede refazer a rotina de hoje: um evento que vira cena, ou uma consulta que
## achou alguém sem plano (quem chegou ao mundo no meio do dia).
func _rotina_mudou() -> bool:
	var ro = _rotina_cache
	var mudou: bool = ro.faltou
	ro.faltou = false
	for i in range(ro.eventos_vistos, eventos.size()):
		if Rotina.GERAM_CENA.has(eventos[i].tipo):
			mudou = true
			break
	ro.eventos_vistos = eventos.size()
	return mudou


## Os eventos desde o dia absoluto `dia_min`, em ordem.
func eventos_recentes(dia_min: int) -> Array:
	var i := eventos.size()
	while i > 0 and (eventos[i - 1].ano - 1) * DIAS_ANO + eventos[i - 1].dia >= dia_min:
		i -= 1
	return eventos.slice(i)


func evento(id: int) -> Evento:
	if id < 0 or id >= eventos.size():
		return null
	return eventos[id]


## Pessoas vivas com posição (x em pixels do mundo) e ação nesta hora.
## `x_anterior` é onde a pessoa está no começo da hora, e `x`, no fim; `agenda` traz os
## trechos da hora em detalhe (veja nucleo/API.md). A resposta é guardada por hora e o
## mesmo array é devolvido de novo: copie o que precisar guardar além da hora.
var _visiveis_chave: Array = []
var _visiveis: Array = []
var _fichas: Dictionary = {}      # id -> ficha da pessoa, reaproveitada a cada hora (não é salva)
var _fichas_chave: Array = []     # o que, mudando, pede refazer os campos que não mudam toda hora
var _no_passo: bool = false       # pessoas_visiveis chamada pelo próprio passo, com folga
var _cenas_chave: Array = []
var _cenas: Array = []


func pessoas_visiveis() -> Array:
	var ro = rotina()
	var de_hoje: bool = ro.dia == dia_abs()
	if de_hoje:
		ro.ver_tempestade()
	var chave := [_rotina_versao, passo, populacao(), acompanhada]
	if chave == _visiveis_chave:
		return _visiveis
	var a := ano()
	var h := hora()
	var r: Array = []
	# Idade, papel, doença, cônjuge... só mudam com o dia ou com um evento.
	var chave_lenta := [dia_abs(), eventos.size(), acompanhada]
	var lento := chave_lenta != _fichas_chave
	if lento and not _no_passo and h < 5 and not _fichas_chave.is_empty() and _fichas_chave[0] == dia_abs() 			and _fichas_chave[2] == acompanhada:
		# De madrugada, todos dormem: o que mudou com os eventos da noite (cônjuge, papel,
		# doença) entra na ficha no passo seguinte, e não pesa na consulta.
		lento = false
	if lento:
		_fichas_chave = chave_lenta
	for g in grupos_vivos():
		for id in g.membros:
			var p: Pessoa = pessoas[id]
			var f: Dictionary = _fichas.get(id, {})
			if f.is_empty():
				f = {"id": id, "nome": p.nome, "sexo": p.sexo, "tracos": p.tracos.duplicate(), "pai": p.pai,
					"mae": p.mae}
				_fichas[id] = f
				_ficha_lenta(f, p, g, a)
			elif lento:
				_ficha_lenta(f, p, g, a)
			# De madrugada, antes de a rotina do dia entrar, todos dormem em casa.
			var ag: Array = ro.agenda(id, h) if de_hoje else ro.dormindo(id)
			# A ação, o lado e a cena do meio da hora saem do trecho que cobre a metade dela.
			var meio: Dictionary = ag[-1]
			for tr in ag:
				if tr["ate"] > 0.5:
					meio = tr
					break
			f["x_anterior"] = ag[0]["x0"]
			f["x"] = ag[-1]["x1"]
			f["acao"] = meio["acao"]
			f["virado"] = meio["virado"]
			f["cena"] = meio["cena"]
			f["agenda"] = ag
			r.append(f)
	if _fichas.size() > r.size() * 2 + 50:
		var vivas := {}
		for f in r:
			vivas[f["id"]] = _fichas[f["id"]]
		_fichas = vivas
	_visiveis = r
	_visiveis_chave = chave
	return r


func _ficha_lenta(f: Dictionary, p: Pessoa, g: Grupo, a: int) -> void:
	var idade: int = p.idade(a)
	if f["tracos"] != p.tracos:
		f["tracos"] = p.tracos.duplicate()
	f["idade"] = idade
	f["crianca"] = idade < 12
	f["grupo"] = g.id
	f["papel"] = "lider" if g.lider == p.id else ("sacerdote" if g.sacerdote == p.id else "")
	f["doente"] = p.doente > 0
	f["gravida"] = p.gravidez > 0
	f["acompanhada"] = p.id == acompanhada
	f["conjuge"] = p.conjuge


## Mantida por compatibilidade: a rotina é montada numa thread e não precisa mais ser
## adiantada. Devolve quantas pessoas vivas estão sem plano na rotina em uso.
func adiantar_rotina(_n: int = 4) -> int:
	return rotina().faltam()


## Cenas que acontecem nesta hora: funeral, nascimento, casamento, festa, migração,
## guerra, corvos, prece coletiva, colheita e construção. Guardadas por hora, como acima.
func cenas_ativas() -> Array:
	rotina()
	var chave := [_rotina_versao, passo]
	if chave == _cenas_chave:
		return _cenas
	var r: Array = []
	var ro = rotina()
	for c in (ro.cenas_na_hora(hora()) if ro.dia == dia_abs() else []):
		var d: Dictionary = c.duplicate()
		d["ini"] = c["ini"] / 60.0
		d["fim"] = c["fim"] / 60.0
		r.append(d)
	_cenas = r
	_cenas_chave = chave
	return r


func posicao_de(pessoa_id: int) -> float:
	var p: Pessoa = pessoas.get(pessoa_id)
	if p == null or not p.vivo:
		return -1.0
	var ro = rotina()
	if ro.dia != dia_abs():
		return ro.casa_de(pessoa_id)
	return ro.instante(pessoa_id, hora() * 60.0 + 30.0)["x"]


## Preces esperando resposta: os sinais da moldura.
var _preces_chave: Array = []
var _preces: Array = []
var _textos_prece: Dictionary = {}   # id do evento -> [texto, curto] (não é salvo)


## Guardadas por hora, como as construções.
func preces_abertas() -> Array:
	var chave := [passo, eventos.size()]
	if chave == _preces_chave:
		return _preces
	var r: Array = []
	for g in grupos_vivos():
		for nec in g.preces:
			var pr: Dictionary = g.preces[nec]
			var e: Evento = eventos[pr["evento"]]
			if not _textos_prece.has(e.id):
				_textos_prece[e.id] = [_cronista.texto_prece(e), _cronista.texto_curto(e)]
			r.append({"evento": e.id, "grupo": g.id, "autor": pr["autor"], "alvo": pr["alvo"],
				"necessidade": nec, "desde": pr["dia"], "dias": dia_abs() - pr["dia"],
				"x": posicao_de(pr["autor"]), "texto": _textos_prece[e.id][0], "curto": _textos_prece[e.id][1]})
	_preces = r
	_preces_chave = chave
	return r


## Camada de atenção de um evento: "ambiente", "nota" ou "chamado".
func camada(e: Evento) -> String:
	if e.tipo == "prece" and e.dados.get("necessidade", "") == "banal":
		return "nota"
	if e.importancia >= 8 or TIPOS_CHAMADO.has(e.tipo):
		return "chamado"
	if e.importancia >= 4:
		return "nota"
	return "ambiente"


## Eventos com id maior ou igual a `desde`, como dicionários, com a camada.
func eventos_desde(desde: int) -> Array:
	var r: Array = []
	for i in range(maxi(0, desde), eventos.size()):
		var d: Dictionary = eventos[i].para_dict()
		d["camada"] = camada(eventos[i])
		d["curto"] = _cronista.texto_curto(eventos[i]) if d["camada"] != "ambiente" else ""
		r.append(d)
	return r


## O deus age. x em pixels do mundo (0..479); intensidade de 0 a 1, vinda do gesto.
func usar_poder(poder: String, x: float, intensidade: float = 0.7) -> Dictionary:
	_esperar_rotina()
	if fim_do_mundo:
		return {"ok": false, "motivo": "o mundo está vazio"}
	if not PODERES.has(poder):
		return {"ok": false, "motivo": "poder desconhecido: " + poder}
	x = clampf(x, 0.0, Cotidiano.LARGURA_MUNDO - 1)
	return _poder({"poder": poder, "zona": Cotidiano.zona_em(x), "x": x,
		"intensidade": clampf(intensidade, 0.0, 1.0), "alvo": -1, "texto": ""})


# ---------------------------------------------------------------- linhagem acompanhada

func acompanhar(pessoa_id: int) -> bool:
	if not pessoas.has(pessoa_id) or not pessoas[pessoa_id].vivo:
		return false
	acompanhada = pessoa_id
	return true


## Quando a pessoa acompanhada morre, o acompanhamento passa ao descendente vivo mais velho.
func _passar_linhagem(morto: Pessoa) -> void:
	var fila: Array = morto.filhos.duplicate()
	var proximo := -1
	while not fila.is_empty() and proximo == -1:
		var vivos: Array = []
		var seguinte: Array = []
		for id in fila:
			var p: Pessoa = pessoas[id]
			if p.vivo:
				vivos.append(p)
			seguinte.append_array(p.filhos)
		if not vivos.is_empty():
			vivos.sort_custom(func(a, b): return a.nasc_ano < b.nasc_ano or (a.nasc_ano == b.nasc_ano and a.id < b.id))
			proximo = vivos[0].id
		fila = seguinte
	acompanhada = proximo
	registrar("linhagem", "natural", 6 if proximo != -1 else 8, zonas_de(proximo), pessoas[proximo].grupo if proximo != -1 else -1,
		[morto.id] + ([proximo] if proximo != -1 else []), {"de": morto.id, "para": proximo})


func zonas_de(pessoa_id: int) -> String:
	if not pessoas.has(pessoa_id) or grupo(pessoas[pessoa_id].grupo) == null:
		return ""
	return grupo(pessoas[pessoa_id].grupo).zona


const MOTIVOS_SUGESTAO := {"sonho": "acabou de ter uma visão", "prece": "está rezando",
	"prece_sem_resposta": "perdeu alguém depois de rezar", "separacao": "fundou um povo",
	"descoberta": "descobriu como plantar", "crenca": "deu nome ao deus", "sacerdote": "passou a falar pelo deus",
	"novo_lider": "passou a guiar o seu povo", "casamento_entre_grupos": "casou com alguém de outro povo",
	"nascimento": "acabou de nascer", "culpado": "foi apontada como culpada"}


## Quem vale acompanhar agora: pessoas que acabaram de viver algo marcante.
func sugestoes(n: int = 5) -> Array:
	var notas := {}
	var motivos := {}
	var limite := (ano() - 2) * DIAS_ANO
	for i in range(eventos.size() - 1, -1, -1):
		var e: Evento = eventos[i]
		if (e.ano - 1) * DIAS_ANO + e.dia < limite:
			break
		if not MOTIVOS_SUGESTAO.has(e.tipo) or e.importancia < 3 or e.participantes.is_empty():
			continue
		var id: int = e.participantes[0]
		if not pessoas.has(id) or not pessoas[id].vivo or motivos.has(id):
			continue
		notas[id] = e.importancia + peso_pessoa(pessoas[id])
		var motivo: String = MOTIVOS_SUGESTAO[e.tipo]
		if pessoas[id].sexo == "m":
			motivo = motivo.replace("apontada", "apontado").replace("culpada", "culpado")
		motivos[id] = motivo
	var ids: Array = notas.keys()
	ids.sort_custom(func(a, b): return notas[a] > notas[b] or (notas[a] == notas[b] and a < b))
	var r: Array = []
	for id in ids.slice(0, n):
		r.append({"id": id, "nome": pessoas[id].nome, "grupo": pessoas[id].grupo, "motivo": motivos[id]})
	return r


# ---------------------------------------------------------------- crônica

## A crônica dos anos completos, do ano_ini ao ano_fim (-1: até o último completo).
func cronica(ano_ini: int = -1, ano_fim: int = -1, com_prologo: bool = true, com_epilogo: bool = false) -> String:
	if ano_ini < 0:
		ano_ini = era_inicio_ano
	if ano_fim < 0:
		ano_fim = _cronista.ultimo_ano_escrito
	return _cronista.montar(ano_ini, ano_fim, "", "", com_prologo, com_epilogo)


func cronica_ano(a: int) -> String:
	return _cronista.texto_do_ano(a)


## Frase curta (até uns 40 caracteres) de um evento, para a dica do cursor. Vazia se o tipo não tem.
func texto_curto(evento_id: int) -> String:
	if evento_id < 0 or evento_id >= eventos.size():
		return ""
	return _cronista.texto_curto(eventos[evento_id])


## A história que um povo que escreve contou de si, em markdown; vazio se ele nunca escreveu.
func cronica_do_povo(grupo_id: int) -> String:
	return _cronista.cronica_do_povo(grupo_id)


func ultimo_ano_na_cronica() -> int:
	return _cronista.ultimo_ano_escrito


## A crônica inteira com título, prólogo e epílogo (para as ferramentas).
func cronica_completa(titulo: String, subtitulo: String) -> String:
	return _cronista.escrever(titulo, subtitulo)


# ---------------------------------------------------------------- ausência

## Avança o tempo em que a moldura ficou fechada, sem gráfico, até o teto de 1 ano.
## Devolve {passos, teto_atingido, de, ate, relato, chamados}: `de` e `ate` são tempo(),
## `relato` é a crônica do período em markdown e `chamados` são os eventos de camada
## "chamado" que aconteceram enquanto o deus estava fora.
func avancar_ausencia(segundos_reais: float, segundos_por_passo: float = SEGUNDOS_POR_PASSO) -> Dictionary:
	var pedidos := int(maxf(0.0, segundos_reais) / segundos_por_passo)
	var passos := mini(pedidos, TETO_AUSENCIA)
	var de := tempo()
	var ev_ini := eventos.size()
	for i in passos:
		avancar_hora()
	var chamados: Array = []
	for d in eventos_desde(ev_ini):
		if d["camada"] == "chamado":
			chamados.append(d)
	return {"passos": passos, "teto_atingido": pedidos > TETO_AUSENCIA, "de": de, "ate": tempo(),
		"relato": _cronista.relato_periodo(ev_ini, eventos.size(), de["ano"], ano()), "chamados": chamados}

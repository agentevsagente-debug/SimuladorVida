extends SceneTree
## Nenhuma chave de modelo chega ao texto (versão 0.2.1): o jogador viu "{p} teve um sonho" na
## crônica viva, depois de um sonho num lugar sem ninguém. Em várias sementes, o mundo anda 40 anos
## e o deus usa todos os poderes, em todas as forças, em pontos sorteados do mundo inteiro (onde há
## gente e onde não há ninguém). Falha se aparecer "{", "}" ou "|" (resto de molde) em:
## - a frase curta (texto_curto) de cada evento do mundo, de todos os tipos;
## - a crônica em curso, logo depois de cada gesto, e a crônica viva;
## - o texto de cada ano, a crônica completa e a crônica de cada povo que escreve;
## - a dica de cada pessoa viva, no fim.
## Confere também que os casos do defeito aconteceram: um sonho sem sonhador e uma cura sem curado,
## e que todo tipo de gesto teve texto.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_textos.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Cotidiano = preload("res://nucleo/cotidiano.gd")
const G = preload("res://nucleo/gramatica.gd")
const Cronista = preload("res://nucleo/cronista.gd")

const SEMENTES := [1, 2, 3, 4, 5]
const ANOS := 40
## Um mundo longo (os estágios altos, as tabuletas, as ruínas) com o deus insistente (a dependência,
## a exigência), e no fim todos morrem (os últimos, o fim do mundo).
const SEMENTE_LONGA := 6
const ANOS_LONGO := 300
## Um deus que atende toda prece por 50 anos (a dependência, a exigência) e depois se cala por 40
## (o silêncio, o culpado, o desamparo).
const ATENDE := {"seca": "chuva", "fome": "fartura", "doenca": "cura", "guerra": "terremoto", "banal": "sonho"}
## Os tipos que a frase curta conhece (os ramos de texto_curto): os que não aparecerem vão para a
## saída, como aviso.
const TIPOS := ["agricultura", "arquivo_salvou", "ataque", "casamento", "casamento_entre_grupos", "chuva_divina",
	"cometa", "conhecimento_perdido", "conquista", "costume", "crenca", "culpado", "cultura", "cura", "dependencia",
	"desamparo", "descoberta", "descoberta_tecnica", "deus_renomeado", "diluvio", "doenca_fim", "doenca_inicio",
	"eclipse", "edito", "estagio", "estranhos", "estudo_do_ceu", "exigencia", "expedicao", "extincao_grupo",
	"fartura_divina", "fim_do_mundo", "fogo_brando", "fogo_divino", "fome_fim", "fome_inicio", "fusao", "gemeos",
	"guerra_fim", "guerra_inicio", "inicio", "inverno_rigoroso", "linhagem", "lugar_nomeado", "mito_ruinas", "morte",
	"mudanca", "nascimento", "nova_crenca", "novo_lider", "os_ultimos", "peste", "prece", "prece_atendida",
	"prece_contrariada", "prece_sem_resposta", "pressagio", "profeta", "raio_divino", "reforma", "regressao",
	"renascimento", "rito", "rixa", "roubo", "ruinas_saber", "sacerdote", "seca_divina", "seca_fim", "seca_inicio",
	"secularizacao", "separacao", "silencio", "sonho", "tempestade", "terra_erguida", "terremoto", "terremoto_divino",
	"tregua"]

var falhas := 0
var textos := 0
var tipos := {}
var sonho_sem_ninguem := 0
var cura_sem_ninguem := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		if falhas <= 20:
			print("FALHOU  ", msg)


func _sem_chave(t: String, onde: String) -> void:
	textos += 1
	conferir(t.find("{") < 0 and t.find("}") < 0 and t.find("|") < 0, "%s: %s" % [onde, t.substr(0, 300)])


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	# A regra geral: a variável sem valor não fica no texto, e a frase escolhida é uma que cabe.
	for modelo in ["{p} teve um sonho", "Chegou {em:z}", "{p} foi {p:expulso|expulsa}", "{n#Resta|Restam} {n}"]:
		_sem_chave(G.preencher(modelo, {}), "preencher sem variáveis: " + modelo)
	conferir(G.chaves("{p} viu {em:z} e {x:o|a} {n#um|uns}") == ["p", "z", "x", "n"], "chaves: %s" % [G.chaves("{p} viu {em:z} e {x:o|a} {n#um|uns}")])
	conferir(Cronista._que_cabem(["{p} teve um sonho", "Alguém sonhou"], {}) == ["Alguém sonhou"], "a frase sem o nome não foi a escolhida")
	conferir(G.chaves_faltando.size() == 6, "preencher sem variáveis não anotou as chaves: %s" % [G.chaves_faltando])
	# Daqui em diante, nenhum texto do mundo pode precisar do "alguém" de reserva: a frase certa
	# é sempre uma que tem todos os valores.
	G.chaves_faltando.clear()
	for s in SEMENTES:
		_mundo(s, ANOS, 4, false)
	_mundo(SEMENTE_LONGA, ANOS_LONGO, 8, true)
	for s in [7, 8, 9]:
		_deus_que_atende(s)
	for tipo in ["chuva_divina", "raio_divino", "fartura_divina", "fogo_divino", "terra_erguida", "sonho",
			"seca_divina", "diluvio", "terremoto_divino", "pressagio", "cura"]:
		conferir(tipos.has(tipo), "nenhum gesto do tipo %s teve frase curta" % tipo)
	conferir(sonho_sem_ninguem > 0, "nenhum sonho caiu num lugar sem ninguém")
	conferir(cura_sem_ninguem > 0, "nenhuma cura caiu num lugar sem ninguém")
	var lista := tipos.keys()
	lista.sort()
	print("%d tipos de evento com frase curta" % lista.size())
	var faltam := TIPOS.filter(func(t): return not tipos.has(t))
	if not faltam.is_empty():
		print("aviso: tipos que não aconteceram: %s" % ", ".join(faltam))
	print("%d sonhos e %d curas sem ninguém; %d textos conferidos em %d s" % [sonho_sem_ninguem, cura_sem_ninguem,
		textos, (Time.get_ticks_msec() - t0) / 1000])
	conferir(G.chaves_faltando.is_empty(), "%d textos sem valor para uma chave (viraram \"alguém\"), por exemplo: %s"
		% [G.chaves_faltando.size(), G.chaves_faltando.slice(0, 5)])
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


func _deus_que_atende(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	while m.ano() <= 50 and not m.fim_do_mundo:
		m.avancar_dias(1)
		for pr in m.preces_abertas():
			_sem_chave(pr["texto"], "semente %d: prece aberta" % semente)
			var poder: String = ATENDE.get(pr["necessidade"], "")
			if poder.is_empty() or (poder == "terremoto" and m.grupo(pr["inimigo"]) == null):
				continue
			var x: float = m._fogo_do_povo(m.grupo(pr["inimigo"])) if poder == "terremoto" else pr["x_povo"]
			var r: Dictionary = m.usar_poder(poder, x, 0.8)
			if r.get("evento", -1) >= 0:
				_sem_chave(m.cronica_em_curso(), "semente %d, prece atendida com %s: crônica em curso" % [semente, poder])
	# O deus se cala: 40 anos, os 10 primeiros como uma ausência do jogador (o relato da volta).
	_ausencia(m, semente)
	m.avancar_dias(Mundo.DIAS_ANO * 30)
	_conferir_mundo(m, semente)


## O jogador fica fora 10 dias de jogo: o relato e o resto do que a ausência devolve.
func _ausencia(m, semente: int) -> void:
	_cada_texto(m.avancar_ausencia(10.0 * Mundo.HORAS_DIA * Mundo.SEGUNDOS_POR_PASSO), "semente %d: ausência" % semente)


func _mundo(semente: int, anos: int, gestos: int, acabar: bool) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente * 7919
	var forcas := [0.2, 0.6, 1.0]
	for a in anos:
		# Os gestos do ano, em dias e pontos sorteados; o resto do ano anda de uma vez.
		for k in gestos:
			m.avancar_dias(rng.randi_range(2, 40 / gestos * 2))
			if m.fim_do_mundo:
				break
			var poder: String = Mundo.PODERES[rng.randi() % Mundo.PODERES.size()]
			var x := rng.randf_range(0.0, Cotidiano.LARGURA_MUNDO)
			var r: Dictionary = m.usar_poder(poder, x, forcas[rng.randi() % forcas.size()])
			if r.get("evento", -1) >= 0:
				var e = m.evento(r["evento"])
				if e.tipo == "sonho" and e.dados.get("sonhador", 0) == -1:
					sonho_sem_ninguem += 1
				if e.tipo == "cura" and e.dados.get("curado", 0) == -1:
					cura_sem_ninguem += 1
				_sem_chave(m.texto_curto(e.id), "semente %d, %s: texto_curto" % [semente, e.tipo])
				_sem_chave(m.cronica_em_curso(), "semente %d, depois de %s: crônica em curso" % [semente, e.tipo])
		if m.fim_do_mundo:
			break
		m.avancar_dias(Mundo.DIAS_ANO - m.dia_do_ano())
	if acabar:
		# Morrem todos menos três; os três, um a um, cada um num dia.
		var vivos: Array = []
		for g in m.grupos_vivos():
			for id in g.membros:
				vivos.append(m.pessoas[id])
		for p in vivos:
			m._morrer(p, "doenca")
			if m.populacao() <= 3:
				m.avancar_dias(1)
		m.avancar_dias(2)
		conferir(m.fim_do_mundo, "semente %d: o mundo não acabou" % semente)
	_conferir_mundo(m, semente)


## Todo texto dentro de um valor (dicionários e listas, por dentro).
func _cada_texto(v, onde: String) -> void:
	if v is String:
		_sem_chave(v, onde)
	elif v is Dictionary:
		for k in v:
			_cada_texto(v[k], "%s, %s" % [onde, k])
	elif v is Array:
		for x in v:
			_cada_texto(x, onde)


## Os textos de tudo o que aconteceu no mundo.
func _conferir_mundo(m, semente: int) -> void:
	for e in m.eventos:
		if e == null:
			continue
		var t: String = m.texto_curto(e.id)
		if not t.is_empty():
			tipos[e.tipo] = true
		_sem_chave(t, "semente %d, evento %d (%s): texto_curto" % [semente, e.id, e.tipo])
		if e.tipo == "prece":
			_sem_chave(m._cronista.texto_prece(e), "semente %d, evento %d: texto da prece" % [semente, e.id])
	for a in range(1, m.ultimo_ano_na_cronica() + 1):
		_sem_chave(m.cronica_ano(a), "semente %d, ano %d" % [semente, a])
	_sem_chave(m.cronica_viva(), "semente %d: crônica viva" % semente)
	_sem_chave(m.cronica_completa("Teste", "sub"), "semente %d: crônica completa" % semente)
	for g in m.grupos:
		_sem_chave(m.cronica_do_povo(g.id), "semente %d: crônica do povo %d" % [semente, g.id])
	for g in m.grupos_vivos():
		for id in g.membros:
			_cada_texto(m.dica(id), "semente %d: dica de %d" % [semente, id])
	m.encerrar()

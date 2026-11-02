extends RefCounted
## A vida das pessoas na tela: o que cada uma faz neste quadro, com que folha,
## em que quadro e onde. Lê a agenda da hora de cada pessoa (API v8: trechos
## {de, ate, x0, x1, acao, virado, cena}) e as cenas, e escolhe as folhas pelo
## mapa da seção 18 do LEIA-ME da arte.
##
## Ritmo: a agenda espalha cada caminhada pelo trecho inteiro (uma hora são
## 112,5 s). Aqui a pessoa anda em passo natural até o destino do trecho, com
## pausas curtas no caminho, e espera fazendo a ação; parada, ela tem
## microanimações (olhar para os lados, esticar, sentar, agachar, coçar a
## cabeça, bocejar) em intervalos irregulares, fixos por pessoa.
##
## Ninguém se amontoa: os parados são empacotados numa fila só, com ESPACO
## entre vizinhos; a roda da fogueira fica em volta do fogo, em dois arcos, com a
## metade de trás mais alta, até RODA_CHEIA pessoas.

const Arte = preload("res://apresentacao/arte.gd")
const Terreno = preload("res://apresentacao/terreno.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")

const LARGURA := 480
const PASSO_ANDAR := 9.0      # px/s médio de quem anda; cada pessoa varia de 0,8 a 1,2 disto
const ESPACO := 7             # distância mínima entre pessoas paradas lado a lado
const MARGEM := 130.0         # ninguém fica à esquerda disto (é água; API: x ≥ 126)
## A roda do entardecer é uma roda de verdade (auditoria 10, Q4): dois arcos, um de
## cada lado do fogo, com a metade de trás mais alta e desenhada antes. No máximo
## RODA_CHEIA pessoas por fogo; o resto fica em casa, como no V1.
const RODA_CHEIA := 12
const RODA_RAIO := 22.0       # px do fogo até a roda (nos arcos de -60° a 60°, nunca a menos de 11 px)
const MULTIDAO := 14          # acima disto, os parados formam duas fileiras
## Ninguém parado com o centro a menos disto do centro do fogo (auditoria 3, D1):
## o fogo de 16 px fica à vista entre as pessoas da roda.
const FOGO_LIVRE := 9.0
## Quem fica nestas ações (ou detalhes) perto do fogo olha para ele.
const OLHA_O_FOGO := ["fogueira", "rezar", "cozinhar", "comer", "aticar", "cochilar", "historias"]
## Quantos parados aparecem fora da roda do fogo (auditoria 2, N2). Com mais
## gente, os ociosos ficam "dentro de casa": não são desenhados, para a
## multidão não cobrir as construções. Quem está numa cena sempre aparece.
const PARADOS_MAX := 28
## Auditoria 7, V1: no máximo 3 parados por casa na frente da vila (nunca menos
## de 10), e ninguém além de VISIVEIS_MAX na tela ao mesmo tempo: o resto está em
## casa nesta hora (quem está numa cena e a linhagem seguida sempre aparecem).
const PARADOS_POR_CASA := 3
const PARADOS_MIN := 10
const VISIVEIS_MAX := 45
## Quanto o passo e a animação de andar aceleram em cada ritmo (10x e 50x).
const ACELERA := {Simulacao.Ritmo.RAPIDO: 2.5, Simulacao.Ritmo.MUITO_RAPIDO: 4.0}
## Cor da roupa do povo -> índice em opcoes_troca().roupas ([28 turquesa, 27 rosa, 29 lilás]).
const ROUPAS := {"turquesa": 0, "rosa": 1, "lilas": 2}
## Microanimações de quem está parado: folha, quadros, segundos.
const MICRO := [["acoes/olhar_lados_4q", 4, 4.0], ["acoes/esticar_4q", 4, 2.0], ["acoes/sentar_chao_4q", 4, 7.0],
	["acoes/agachar_2q", 2, 3.0], ["acoes/cocar_cabeca_4q", 4, 2.4], ["acoes/bocejar_4q", 4, 2.2]]
## Ações paradas com folha de 4 quadros em laço (acao -> folha).
const ACOES := {"construir": "acoes/construir_4q", "forjar": "acoes/forjar_4q", "escrever": "acoes/escrever_4q",
	"remar": "acoes/remar_4q", "lutar": "acoes/lutar_4q", "dancar": "acoes/dancar_4q", "pescar": "acoes/pescar_4q"}
## Ações de caminhada com carga (acao -> folha).
const CARGAS := {"lenha": "acoes/carregar_lenha_4q", "carregar_morto": "acoes/funeral_carregar_4q",
	"carregar_caca": "acoes/carregar_caca_4q", "cacar": "acoes/cacar_espreitar_forte_4q"}
## Detalhes da rotina (API v10, campo `detalhe`; arte, seção 20) com folha de 4
## quadros em laço. Sem folha própria, vale a da `acao`, como antes.
## detalhe -> [folha, largura do quadro]. As versões "de 1x" (seção 22 da arte)
## mudam a silhueta e trazem objetos maiores, para quem olha de canto de olho.
const DETALHES := {"colher_arbusto": ["acoes/colher_arbusto_4q", 8], "cavar_raiz": ["acoes/cavar_raiz_4q", 8],
	"catar_lenha": ["acoes/catar_lenha_forte_4q", 12], "buscar_agua": ["acoes/buscar_agua_forte_4q", 12],
	"banho": ["acoes/banhar_4q", 8], "espantar": ["acoes/espantar_forte_4q", 12], "discutir": ["acoes/discutir_4q", 8],
	"separar": ["acoes/conversar_falar_4q", 8], "arremessar": ["acoes/cacar_arremessar_forte_4q", 12],
	"bocejar": ["acoes/bocejar_4q", 8], "espreitar": ["acoes/cacar_espreitar_forte_4q", 12],
	"espeto": ["acoes/cozinhar_espeto_4q", 8], "lavar": ["acoes/lavar_margem_forte_4q", 12]}
## Detalhes andando: a carga ou a ferramenta da ida e da volta.
const DETALHES_ANDANDO := {"carregar_cesto": "acoes/carregar_cesto_cabeca_forte_4q",
	"carregar_cesto_cabeca": "acoes/carregar_cesto_cabeca_forte_4q", "levar_cesto": "acoes/andar_cesto_4q",
	"carregar_agua": "acoes/carregar_agua_forte_4q", "carregar_feixe": "acoes/carregar_lenha_4q",
	"caca_no_pau": "acoes/carregar_caca_forte_4q", "espreitar": "acoes/cacar_espreitar_forte_4q",
	"peixe_na_lanca": "acoes/carregar_peixe_forte_4q"}
## Folhas andando com quadro de 12 px (as outras cargas têm 8).
const LARGAS := ["acoes/cacar_espreitar_forte_4q", "acoes/carregar_peixe_forte_4q"]
## As cenas do começo da tarde (API: pesca_lanca, lavagem) que acontecem dentro da água rasa.
const NA_AGUA := ["pescar_lanca", "golpear", "peixe_na_lanca", "banho"]
## No arremesso (0..1 da etapa; a lança já ficou erguida na mira): até SOLTA o
## caçador ainda a segura, de SOLTA a CRAVA ela voa; depois ele acompanha e o porco cambaleia.
const SOLTA := 0.04
const CRAVA := 0.12
## Na volta, os dois que carregam o pau ficam a 16 px um do outro (arte, seção 22).
const VAO_DO_PAU := 16.0
## A chegada de quem vem de além da borda (estranhos e o povo novo), em segundos reais:
## andam da borda até o fogo; no recomeço, um deles gira o pau, sopra e a fogueira acende.
const RECOMECO_GIRA := 9.0      # chegaram: quem acende ajoelha e gira o pau
const RECOMECO_SOPRA := 14.0    # sai a fumaça; ele sopra a brasa
const RECOMECO_ACESA := 17.0    # a fogueira acende
const RECOMECO_CABANAS := 19.0  # as cabanas aparecem
const CHEGADA_DURA := 40.0      # quanto tempo os que chegam ficam juntos no fogo
## Na espreita, os caçadores vão em fila, a 7 px um do outro (auditoria 6, H2).
const FILA_CACADA := 7.0
## Folhas que têm a roupa dos estágios 3 a 6 em estagioN/, com o mesmo nome (arte, seção 25).
const COM_ROUPA_DO_ESTAGIO := ["catar_lenha_forte_4q", "carregar_cesto_cabeca_forte_4q", "espantar_forte_4q",
	"tropecar_cair_forte_4q", "carregar_agua_forte_4q", "buscar_agua_forte_4q", "carregar_caca_forte_4q",
	"crianca_pegapega_fugir_4q", "crianca_pegapega_pegar_4q", "crianca_ciranda_4q", "crianca_ciranda_costas_4q",
	"cacar_apontar_2q", "cacar_comemorar_4q", "cacar_amarrar_4q", "cacar_espreitar_forte_4q", "cacar_arremessar_forte_4q", "pescar_espreitar_forte_2q", "pescar_arpoar_forte_4q",
	"carregar_peixe_forte_4q", "lavar_margem_forte_4q", "crianca_banho_4q",
	# as folhas de sempre (auditoria 7, A1)
	"adulto_a_andar_4q", "adulto_b_andar_4q", "adulto_a_parado_2q", "adulto_b_parado_2q", "adulto_a_rezar_2q",
	"adulto_a_colher_4q", "adulto_a_sentado_1q", "crianca_andar_4q", "idoso_andar_4q",
	# as três cenas da tarde da 0.1.2 (arte, seção 29)
	"sesta_lado_2q", "crianca_cutucar_2q", "ralhar_2q", "idoso_mostrar_4q", "idoso_aprovar_2q", "ensinar_apontar_4q",
	"crianca_mirar_2q", "crianca_arremessar_4q", "buscar_lanca_2q", "crianca_comemorar_4q", "trancar_cesto_4q",
	"moldar_pote_4q", "afiar_lanca_4q", "mostrar_peca_cesto_2q", "mostrar_peca_pote_2q", "mostrar_peca_lanca_2q"]
## As cenas da tarde (API: sesta, ensinar, artesanato): a carga de quem leva a peça para casa.
const CARGA_DA_PECA := {"cesto": "acoes/carregar_cesto_cabeca_forte_4q", "pote": "acoes/carregar_agua_forte_4q"}
## No arremesso ao alvo (o minuto 2 a 3 da etapa, em minutos de jogo): a lança sai da mão
## em SOLTA_ALVO e chega ao alvo em CRAVA_ALVO (frações do minuto), num arco de ARCO_ALVO px,
## acima do beiral das casas (auditoria 13: o voo curto e raso se perdia no telhado).
const SOLTA_ALVO := 0.4
const CRAVA_ALVO := 0.9
const ARCO_ALVO := 9.0
## No ensinar, o mestre fica a esta distância da criança, e não colado nela (auditoria 13).
const MESTRE_LONGE := 9.0
## No estágio 6, os homens andam e param de chapéu de aba larga (auditoria 11, D2).
const CHAPEU_DO_ESTAGIO6 := {"adulto_a_andar_4q": "adulto_e6_andar_4q", "adulto_a_parado_2q": "adulto_e6_parado_2q"}

const CALCULOS_DEVAGAR := 10.0  # cálculos por segundo das pessoas em 1x e na pausa
var _desenho: Array = []        # o último resultado de atualizar(), reaproveitado entre os cálculos
var _proximo_calculo := 0.0
var _delta_guardado := 0.0
var _trechos := {}             # trecho da agenda de cada um (refeito 6 vezes por segundo)
var _lugar := {}               # lugar de cada parado (idem)
var _refazer_lugares_em := 0.0
var _pessoas_vistas: Array = []
var _chegando := {}  # id -> {ini, fogo, k (a ordem), recomeco}
var vista
var sim
var figuras: Array = []
var objetos: Array = []       # objetos de cena desenhados junto das pessoas
var _x := {}                  # id -> x desenhado
var _virada := {}             # id -> espelho (olhando para a esquerda)
var _acordou := {}            # id -> quando saiu da cabana (para saírem em fila)
var _atras := {}              # ids na segunda fileira da roda
var _ocultos := {}            # ids que ficam dentro de casa nesta hora (multidão)
var _existe := {}
var _ultimo_registro := -1             # caminho -> se a folha existe (variantes por estágio)
var _maior_sobreposicao := [0, 0]


func _init(p_vista, p_sim) -> void:
	vista = p_vista
	sim = p_sim


## Número fixo por pessoa e por fatia de tempo, 0..1 (não usa o sorteio do núcleo).
static func _dado(id: int, fatia: int, sal: int = 0) -> float:
	var h := hash([id, fatia, sal])
	return float(h & 0xFFFF) / 65535.0


## O trecho da agenda na fração f da hora: {x, destino, acao, virado, anda, cena}.
static func trecho(p: Dictionary, f: float) -> Dictionary:
	var agenda: Array = p.get("agenda", [])
	for i in agenda.size():
		var t: Dictionary = agenda[i]
		if f < t["ate"] or i == agenda.size() - 1:
			var anda: bool = absf(t["x1"] - t["x0"]) > 0.5
			return {"destino": float(t["x1"]), "acao": t["acao"], "virado": int(t.get("virado", 0)),
				"anda": anda, "cena": t.get("cena", {}), "detalhe": t.get("detalhe", "")}
	return {"destino": float(p["x"]), "acao": p["acao"], "virado": int(p.get("virado", 0)), "anda": false,
		"cena": p.get("cena", {}), "detalhe": p.get("detalhe", "")}


func atualizar(delta: float, relogio: float) -> Array:
	# em 1x e na pausa, quem anda vai a ~9 px/s e as animações vão a até 10 quadros/s:
	# 10 cálculos por segundo bastam (1 px por passo); entre eles, vale o desenho de antes
	# (QA, D-08: o laço das pessoas era metade do custo da vista num mundo grande)
	_delta_guardado += delta
	var devagar: bool = sim.ritmo == Simulacao.Ritmo.NORMAL or sim.ritmo == Simulacao.Ritmo.PAUSA
	if devagar and relogio < _proximo_calculo and not _desenho.is_empty() and _chegando.is_empty():
		return _desenho
	_proximo_calculo = relogio + 1.0 / CALCULOS_DEVAGAR
	delta = _delta_guardado
	_delta_guardado = 0.0
	# o trecho da agenda de cada um e os lugares dos parados mudam devagar (a agenda
	# anda em minutos de jogo): refeitos 6 vezes por segundo, ou quando a gente muda
	if relogio >= _refazer_lugares_em or not is_same(sim.pessoas, _pessoas_vistas) or sim.ritmo != Simulacao.Ritmo.NORMAL:
		_refazer_lugares_em = relogio + 1.0 / 6.0
		_pessoas_vistas = sim.pessoas
		var f: float = sim.fracao()
		_trechos = {}
		for p in sim.pessoas:
			_trechos[p["id"]] = trecho(p, f)
		_lugar = _lugares(sim.pessoas, _trechos)
	var trechos: Dictionary = _trechos
	var lugar: Dictionary = _lugar
	vista._medir("v_trechos_lugares")  # DEPURAR_TEMPO
	var opcoes := Arte.opcoes_troca()
	var r := []
	objetos = []
	var vivos := {}
	# andam mais depressa nos ritmos rápidos, com teto, para ninguém "teletransportar"
	var rapido: float = ACELERA.get(sim.ritmo, 1.0)
	for p in sim.pessoas:
		var id: int = p["id"]
		vivos[id] = true
		var t: Dictionary = trechos[id]
		var acao: String = t.acao
		if acao == "dormir":  # quem dorme ou passa a hora em casa não é desenhado: nada a calcular
			_acordou.erase(id)
			continue
		if _ocultos.has(id):
			continue
		var destino: float = lugar.get(id, t.destino)
		var no_lago := _no_lago(t, id)
		if no_lago.is_empty():
			if acao != "remar":  # só no barco se fica sobre a água
				destino = maxf(destino, MARGEM)
		else:  # a pesca e o banho na água rasa, e a lavagem na beira, de frente para o lago
			destino = no_lago.x
		var chega: Dictionary = _chegando.get(id, {})
		if not chega.is_empty():
			if relogio - float(chega.ini) > CHEGADA_DURA:
				_chegando.erase(id)
				chega = {}
			else:  # da borda até o fogo, e ali ficam juntos, uns de cada lado
				var lado_k := 1.0 if int(chega.k) % 2 == 0 else -1.0
				destino = float(chega.fogo) + lado_k * (10.0 + 7.0 * (int(chega.k) / 2))
				if bool(chega.recomeco) and int(chega.k) == 0:
					destino = float(chega.fogo) - 4.0  # quem acende, ajoelhado junto da lenha
		if t.cena.get("tipo", "") == "ensinar" and String(t.get("detalhe", "")) in ["mostrar", "aprovar"]:
			destino = _lugar_do_mestre(t.cena, destino)
		var abate := _lugar_na_cacada(t, id)
		if not abate.is_empty():  # a caçada encenada: em fila na espreita, e no abate em volta do bicho
			destino = abate.x
		if not t.anda:  # ninguém parado em cima da fogueira: afasta para o lado em que já está
			var fogo_d: float = vista.fogo_mais_perto(destino)
			if absf(destino - fogo_d) < FOGO_LIVRE:
				var lado := signf(destino - fogo_d) if destino != fogo_d else (1.0 if id % 2 == 0 else -1.0)
				destino = fogo_d + lado * FOGO_LIVRE
		var x: float = _x.get(id, destino)
		var vel := PASSO_ANDAR * (0.8 + 0.4 * _dado(id, 0)) * rapido
		if not chega.is_empty() and bool(chega.recomeco):  # o povo novo chega ao fogo antes de acendê-lo
			var falta := RECOMECO_GIRA - 1.0 - (relogio - float(chega.ini))
			vel = maxf(vel, absf(destino - x) / maxf(falta, 0.5))
		if absf(destino - x) > 120.0 and chega.is_empty():  # salto no tempo: aparece no lugar novo
			x = destino
		# pausas curtas no caminho: de vez em quando para e olha
		var fatia := int((relogio + id * 1.7) / 3.0)
		var pausa := _dado(id, fatia, 1) < 0.12 and fmod(relogio + id * 1.7, 3.0) < 0.6
		var anterior := x
		if not pausa:
			x = move_toward(x, destino, vel * delta)
		_x[id] = x
		# quem acorda junto sai da cabana em fila, não empilhado
		if not _acordou.has(id):
			_acordou[id] = relogio
		if relogio - _acordou[id] < (id % 10) * ESPACO / vel and absf(destino - x) > ESPACO:
			_x[id] = anterior
			continue
		var movendo := absf(x - anterior) > 0.001
		var fogo: float = vista.fogo_mais_perto(x)
		if not abate.is_empty() and not movendo:
			_virada[id] = abate.espelho  # olhando para o bicho
		elif not no_lago.is_empty() and not movendo:
			_virada[id] = no_lago.espelho
		elif movendo:
			_virada[id] = x < anterior
		elif (acao in OLHA_O_FOGO or t.get("detalhe", "") in OLHA_O_FOGO) and absf(fogo - x) < 40.0:
			_virada[id] = fogo < x  # a roda olha para o fogo (quem está à direita, espelhado)
		elif String(t.get("detalhe", "")) in ["sesta", "ralhar"]:  # a cabeça (à esquerda na folha) do lado da casa
			_virada[id] = float(t.cena.get("x", _cena_ativa(t.cena).get("x", x))) > x
		elif t.virado != 0:
			_virada[id] = t.virado < 0
		var espelho: bool = _virada.get(id, id % 2 == 0)

		var visual := _visual(p, acao, t, movendo or absf(destino - x) > 0.5, relogio)
		if not chega.is_empty():
			visual = _visual_da_chegada(chega, p, movendo or absf(destino - x) > 0.5, relogio, visual)
		visual[0] = _com_roupa_do_estagio(visual[0], int(p["grupo"]))
		var crianca: bool = p["crianca"]
		var idoso: bool = p["idade"] >= 55 and not crianca
		var pele: int = id % opcoes.peles.size()
		var cabelo: int = (id * 7 + 3) % (opcoes.cabelos.size() - 1)  # o último é o grisalho
		if idoso:
			cabelo = 5 if String(visual[0]).begins_with("habitantes/idoso") or String(visual[0]).ends_with("idoso_parado_2q") \
				else opcoes.cabelos.size() - 1
		# a roupa é a cor do povo (aparencia.roupa): turquesa, rosa ou lilás
		var roupa: int = ROUPAS.get(sim.aparencia(int(p["grupo"])).get("roupa", ""), (id * 5 + int(p["grupo"])) % opcoes.roupas.size())
		var xr := roundi(x)
		var base: int = vista.chao_pessoa(xr) - (2 if _atras.has(id) else 0) - int(visual[3])
		var largura: int = visual[1]
		r.append({"id": id, "folha": visual[0], "quadro": visual[2], "largura": largura,
			"x": xr - (6 if crianca else 8) / 2, "base": base, "espelho": espelho, "corpo": 6 if crianca else 8,
			"codigo": Arte.codigo_troca(pele, cabelo, roupa), "fogo": fogo, "acompanhada": p.get("acompanhada", false),
			"movendo": movendo, "atras": _atras.has(id), "acao": acao, "cena": t.cena, "nucleo": t.destino,
			"detalhe": t.get("detalhe", "")})
	vista._medir("v_pessoas")  # DEPURAR_TEMPO
	_objetos_de_cena(r, relogio)
	_objetos_do_cotidiano(r, relogio)
	_animais_das_cenas(r, relogio)
	_alvos_de_capim()
	vista._medir("v_objetos")  # DEPURAR_TEMPO
	r.sort_custom(func(a, b): return a.atras and not b.atras)  # a segunda fileira fica atrás
	for id in _x.keys():
		if not vivos.has(id):
			_x.erase(id)
			_virada.erase(id)
			_acordou.erase(id)
	figuras = r
	if OS.has_environment("CONTAR_SOBREPOSICAO"):
		_contar_sobreposicao()
	if OS.has_environment("REGISTRAR_LUGARES") and int(relogio / 10.0) != _ultimo_registro:
		_ultimo_registro = int(relogio / 10.0)  # teste: onde estão os parados (auditoria 4, N5)
		print("[lugares] %d %s" % [_ultimo_registro, JSON.stringify(r.filter(func(f): return not f.movendo).map(
			func(f): return [f.id, f.x, f.acao, roundi(f.get("nucleo", -1.0))]))])
	_desenho = r + objetos
	return _desenho


## A folha com a roupa do estágio do povo (estagioN/), se a arte tiver; senão, a de acoes/.
func _com_roupa_do_estagio(folha: String, grupo: int) -> String:
	if not folha.get_file() in COM_ROUPA_DO_ESTAGIO:
		return folha
	var estagio := 1
	for g in sim.grupos:
		if g["id"] == grupo:
			estagio = int(g.get("estagio", 1))
	if estagio >= 6 and folha.get_file() in CHAPEU_DO_ESTAGIO6:  # o chapéu de palha e as calças (arte, seção 11)
		return "estagio6/" + CHAPEU_DO_ESTAGIO6[folha.get_file()]
	for e in range(mini(estagio, 6), 2, -1):
		var caminho := "estagio%d/%s" % [e, folha.get_file()]
		if not _existe.has(caminho):
			_existe[caminho] = ResourceLoader.exists(Arte.RAIZ + caminho + ".png")
		if _existe[caminho]:
			return caminho
	return folha


## [folha, largura, quadro, subida] para o que a pessoa faz agora.
func _visual(p: Dictionary, acao: String, t: Dictionary, anda: bool, relogio: float) -> Array:
	var id: int = p["id"]
	var crianca: bool = p["crianca"]
	var idoso: bool = p["idade"] >= 55 and not crianca
	var feminina: bool = p["sexo"] == "f"
	# andando num ritmo rápido, as pernas acompanham o passo maior
	var fase: float = relogio * (ACELERA.get(sim.ritmo, 1.0) if anda else 1.0) + id * 0.37
	var cena: String = t.cena.get("tipo", "")
	var q4 := int(fase * 5.0) % 4
	var detalhe: String = t.get("detalhe", "")
	if crianca:
		match detalhe:  # as cenas da tarde (arte, seção 29)
			"cutucar":
				if not anda:
					return ["acoes/crianca_cutucar_2q", 6, int(fase / 0.7) % 2, 0]
			"fugir":
				return ["acoes/crianca_pegapega_fugir_4q", 6, int(fase * 10.0) % 4, 0]
			"mirar_alvo":
				return ["acoes/crianca_mirar_2q", 12, int(fase) % 2, 0]
			"arremessar_alvo":
				return ["acoes/crianca_arremessar_4q", 12, _quadro_do_alvo(t), 0]
			"buscar_lanca":
				if not anda:
					return ["habitantes/crianca_andar_4q", 6, 0, 0]
			"comemorar":  # agacha, salta com os braços em V e pousa; sobe 2 px no ar
				var qc := int(fase * 5.0) % 4
				return ["acoes/crianca_comemorar_4q", 6, qc, 2 if qc in [1, 2] else 0]
		if detalhe == "banho" and not anda:
			return ["acoes/crianca_banho_4q", 6, (int(fase * 2.0) + id) % 4, 0]
		if detalhe == "brigar":  # duas crianças de frente, com quadros defasados
			return ["acoes/criancas_brigar_4q", 6, (int(fase * 5.0) + id) % 4, 0]
		if detalhe == "perdido" and not anda:
			return ["habitantes/crianca_andar_4q", 6, 0, 0]
		if acao == "brincar" or detalhe == "brincar":
			if anda:  # pega-pega: os papéis trocam a cada uns 7 s
				var pega := (id + int(relogio / 7.0)) % 2 == 0
				return ["acoes/crianca_pegapega_pegar_4q" if pega else "acoes/crianca_pegapega_fugir_4q", 6,
					int(fase * 10.0) % 4, 0]
			return ["acoes/crianca_ciranda_4q", 6, (int(fase * 4.0) + id) % 4, 0]  # a roda, de mãos dadas
		if anda:
			return ["acoes/crianca_correr_4q", 6, int(fase * 10.0) % 4, 0]
		# de vez em quando, pula no lugar (sobe o sprite nos quadros 1 e 2)
		if _dado(id, int(fase / 4.0), 2) < 0.3:
			var q := int(fase * 6.0) % 4
			return ["acoes/crianca_pular_4q", 6, q, 3 if q in [1, 2] else 0]
		return ["habitantes/crianca_andar_4q", 6, 0, 0]
	if anda:
		var carga: String = DETALHES_ANDANDO.get(detalhe, CARGAS.get(acao, ""))
		if detalhe == "levar_peca":  # o cesto na cabeça ou o pote; a lança vai na mão
			carga = CARGA_DA_PECA.get(String(_cena_ativa(t.cena).get("peca", "")), "")
		if detalhe == "caca_no_pau" and _posto_na_cacada(t.cena, id) >= 2:
			carga = ""  # só os dois do pau carregam; os outros voltam andando atrás
		if carga != "":
			return [carga, 12 if carga in LARGAS else 8, int(fase * 5.0) % 4, 0]
		if cena == "migracao":
			return ["acoes/andar_trouxa_4q" if id % 2 else "acoes/andar_cesto_4q", 8, int(fase * 6.0) % 4, 0]
		if cena == "guerra" and _porta_estandarte(id, t):
			return ["acoes/carregar_estandarte_sol_4q", 12, int(fase * 6.0) % 4, 0]
		if acao == "cuidar" and feminina:
			return ["acoes/mae_bebe_andar_4q", 8, int(fase * 6.0) % 4, 0]
		if idoso:
			return ["habitantes/idoso_andar_4q", 8, int(fase * 4.0) % 4, 0]
		return ["habitantes/adulto_b_andar_4q" if feminina else "habitantes/adulto_a_andar_4q", 8, int(fase * 6.0) % 4, 0]
	if detalhe == "arremessar":  # no compasso da lança: ergue, segura, solta e acompanha
		var e := _etapa_da_cena(t.cena)
		if e.get("etapa", "") == "arremesso":
			var pa: float = e.p
			return [DETALHES[detalhe][0], 12, 1 if pa < SOLTA else 2 if pa < CRAVA else 3, 0]
	if acao == "lutar" and vista.modo_discreto:  # o modo discreto não mostra a luta: as linhas, frente a frente
		return _parado(id, idoso, feminina, fase)
	match detalhe:  # as cenas da tarde (arte, seção 29)
		"sesta":  # deitado de lado; 1,8 s por quadro
			return ["acoes/sesta_lado_2q", 12, int(fase / 1.8) % 2, 0]
		"ralhar":
			return ["acoes/ralhar_2q", 12, int(fase * 3.0) % 2, 0]
		"mostrar":  # o velho, de bengala; quem ainda não é velho aponta com um galho
			return ["acoes/idoso_mostrar_4q" if idoso else "acoes/ensinar_apontar_4q", 12, int(fase * 2.0) % 4, 0]
		"aprovar":
			return ["acoes/idoso_aprovar_2q", 12, int(fase * 2.0) % 2, 0] if idoso \
				else ["acoes/ensinar_apontar_4q", 12, int(fase * 2.0) % 2, 0]
		"mirar_alvo":  # a lança erguida, mirando (o quadro 1 do arremesso, como na caçada)
			return ["acoes/cacar_arremessar_forte_4q", 12, 1, 0]
		"arremessar_alvo":
			return ["acoes/cacar_arremessar_forte_4q", 12, _quadro_do_alvo(t), 0]
		"buscar_lanca":
			return ["acoes/buscar_lanca_2q", 12, int(fase) % 2, 0]
		"trancar_cesto", "moldar_pote", "afiar_lanca":
			return ["acoes/%s_4q" % detalhe, 12, int(fase * 3.0) % 4, 0]
		"mostrar_peca":
			var peca := String(_cena_ativa(t.cena).get("peca", "cesto"))
			return ["acoes/mostrar_peca_%s_2q" % peca, 12, int(fase * 2.0) % 2, 0]
	if DETALHES.has(detalhe):
		return [DETALHES[detalhe][0], DETALHES[detalhe][1], q4, 0]
	match detalhe:
		"pescar_lanca":  # na água rasa, curvado, com a lança apontada para a água; segura cada quadro 2 s
			return ["acoes/pescar_espreitar_forte_2q", 12, int(fase / 2.0) % 2, 0]
		"golpear":  # mira (segura), arpoa e, no golpe certo, ergue o peixe se debatendo
			var g := _etapa_de(t.cena)
			var pg: float = g.get("p", 0.0)
			if pg < 0.35:
				return ["acoes/pescar_arpoar_forte_4q", 12, 0, 0]
			if pg < 0.6 or not g.get("acerto", false):
				return ["acoes/pescar_arpoar_forte_4q", 12, 1, 0]
			return ["acoes/pescar_arpoar_forte_4q", 12, 2 + int(fase * 2.5) % 2, 0]
		"peixe_na_lanca":  # parado, mostrando o peixe na ponta
			return ["acoes/pescar_arpoar_forte_4q", 12, 2 + int(fase * 2.5) % 2, 0]
		"banho":  # as crianças na água: jogam água, batem, mergulham e sacodem
			return ["acoes/crianca_banho_4q", 6, (int(fase * 2.0) + id) % 4, 0]
		"despejar":  # vira o cesto no chão, perto do fogo (o cesto vem em _objetos_do_cotidiano)
			return ["acoes/agachar_2q", 8, 1, 0]
		"mirar":  # parado um instante com a lança erguida, antes de soltar
			return ["acoes/cacar_arremessar_forte_4q", 12, 1, 0]
		"apontar":  # os de trás apontam o porco
			return ["acoes/cacar_apontar_2q", 8, (int(fase * 1.2) + id) % 2, 0]
		"colher_roca":
			return ["estagio2/adulto_enxada_trabalhar_4q", 12, q4, 0]
		"cozinhar":  # mexendo a panela ou girando o espeto (o objeto vem em _objetos_do_cotidiano)
			return ["acoes/cozinhar_mexer_4q" if id % 2 == 0 else "acoes/cozinhar_espeto_4q", 8, int(fase * 3.0) % 4, 0]
		"vigia":  # de madrugada, a cabeça pesa de sono de vez em quando
			var sono: bool = int(sim.tempo.get("hora", 0)) < 5 and fmod(fase, 9.0) > 6.0
			return ["acoes/vigia_2q", 8, 1 if sono else 0, 0]
		"historias":  # o mais novo da roda conta, de pé; os outros ouvem sentados
			if _menor_da_cena(t.cena) == id:
				return ["acoes/contar_historia_4q", 8, int(fase * 2.5) % 4, 0]
			return ["acoes/ouvir_sentado_2q", 8, int(fase * 0.5) % 2, 0]
		"machucado":  # tropeça, cai, fica tonto no chão (o quadro 3) e depois levanta
			var queda := fmod(fase, 14.0)
			if queda < 1.2:
				return ["acoes/tropecar_cair_forte_4q", 12, int(queda / 0.3), 0]
			if queda < 10.0:
				return ["acoes/tropecar_cair_forte_4q", 12, 3, 0]
			return ["acoes/agachar_2q", 8, 1, 0]
		"recolher_caca":  # acertou: os dois que vão carregar amarram o bicho, os outros comemoram e esperam
			if _posto_na_cacada(t.cena, id) <= 1:
				return ["acoes/cacar_amarrar_4q", 12, (int(fase * 2.0) + id) % 4, 0]
			if float(_etapa_da_cena(t.cena).get("p", 1.0)) < 0.15:
				return ["acoes/cacar_comemorar_4q", 12, (int(fase * 5.0) + id) % 4, 0]
			return _parado(id, idoso, feminina, fase)
		"aticar":  # de madrugada, quem acordou atiça o fogo
			return ["acoes/agachar_2q", 8, int(fase * 1.5) % 2, 0]
		"cochilar":  # o vigia cochila sentado (o balão de pensamento vem dos sinais)
			return ["acoes/vigia_2q", 8, 1, 0]
		"ninar":
			return ["acoes/mae_bebe_parado_2q", 8, int(fase) % 2, 0]
		"guardar", "repartir":
			return ["acoes/agachar_2q", 8, int(fase * 0.7) % 2, 0]
		"comer", "descansar", "olhar_ceu", "doente":
			return ["acoes/sentar_chao_4q", 8, 2 + int(fase * 0.7) % 2, 0]
	match acao:
		"deitar":  # descansando deitado à sombra
			return ["acoes/dormir_2q", 12, int(fase * 0.4) % 2, 0]
		"tecer", "consertar":
			return ["acoes/sentar_chao_4q", 8, 2 + int(fase * 0.9) % 2, 0]
		"cozinhar":
			return ["acoes/cozinhar_mexer_4q" if id % 2 == 0 else "acoes/cozinhar_espeto_4q", 8, int(fase * 3.0) % 4, 0]
		"comer":
			return ["acoes/sentar_chao_4q", 8, 2 + int(fase * 0.7) % 2, 0]
		"cacar":  # espreita parado e, de vez em quando, arremessa
			var ciclo := fmod(fase, 6.0)
			if ciclo < 2.0:
				return ["acoes/cacar_arremessar_forte_4q", 12, int(ciclo * 2.0), 0]
			return ["acoes/cacar_espreitar_forte_4q", 12, 0, 0]
		"colher":
			if vista.perto_de_roca(_x[id]):
				return ["estagio2/adulto_enxada_trabalhar_4q", 12, q4, 0]
			if _x[id] < 140.0:  # colher na margem é pescar
				return _pescar(id, fase)
			return ["habitantes/adulto_a_colher_4q", 8, int(fase * 3.0) % 4, 0]
		"pescar":
			return _pescar(id, fase)
		"rezar":
			return ["habitantes/adulto_a_rezar_2q", 8, int(fase * 0.8) % 2, 0]
		"fogueira":
			if id % 2 == 0 or idoso:
				return ["acoes/sentar_chao_4q", 8, 2 + int(fase * 0.7) % 2, 0]
			return ["habitantes/adulto_a_sentado_1q", 8, 0, 0]
		"conversar":  # um fala, o outro ouve; os papéis se alternam
			var fala := (int(fase / 2.5) + id) % 2 == 0
			return ["acoes/conversar_falar_4q" if fala else "acoes/conversar_ouvir_4q", 8, int(fase * 3.0) % 4, 0]
		"cuidar":
			return ["acoes/mae_bebe_parado_2q", 8, int(fase) % 2, 0] if feminina else _parado(id, idoso, feminina, fase)
		"dancar":
			if cena in ["festa", "casamento"] and _tocador(id, t):
				return ["acoes/tocar_tambor_4q", 8, int(fase * 6.0) % 4, 0]
			return ["acoes/dancar_4q", 8, int(fase * 4.0) % 4, 0]
		"lenha":
			return ["acoes/carregar_lenha_4q", 8, 0, 0]
		"carregar_morto":
			return ["acoes/funeral_carregar_4q", 8, 0, 0]
	if ACOES.has(acao):
		return [ACOES[acao], 8, q4, 0]
	return _parado(id, idoso, feminina, fase)


func _pescar(id: int, fase: float) -> Array:
	# espera, puxa e mostra o peixe; de vez em quando segura o peixe
	if _dado(id, int(fase / 6.0), 3) < 0.25:
		return ["acoes/segurar_peixe_2q", 8, int(fase * 2.0) % 2, 0]
	return ["acoes/pescar_4q", 8, mini(int(fmod(fase, 6.0) * 1.2), 3), 0]


## Parado com vida: respira, e de tempos em tempos faz uma microanimação.
func _parado(id: int, idoso: bool, feminina: bool, fase: float) -> Array:
	if idoso:
		return ["acoes/idoso_parado_2q", 8, int(fase * 0.8) % 2, 0]
	# fatias de tempo irregulares por pessoa, de 3 a 6 s: em 4 de cada 5, uma
	# microanimação, para o ocioso parecer vivo mesmo em 1x (auditoria 3, D2)
	var tamanho := 3.0 + 3.0 * _dado(id, 0, 4)
	var fatia := int(fase / tamanho)
	var dentro := fmod(fase, tamanho)
	if _dado(id, fatia, 5) < 0.8:
		var m: Array = MICRO[int(_dado(id, fatia, 6) * MICRO.size()) % MICRO.size()]
		if dentro < m[2]:
			var q: int = int(dentro / m[2] * m[1] * (2 if m[0].ends_with("olhar_lados_4q") else 1)) % m[1]
			if m[0].ends_with("sentar_chao_4q"):  # senta (0, 1) e fica sentado (2, 3 em laço)
				q = mini(int(dentro * 1.5), 1) if dentro < 1.4 else 2 + int(dentro * 0.8) % 2
			return [m[0], 8, q, 0]
	return ["habitantes/adulto_b_parado_2q" if feminina else "habitantes/adulto_a_parado_2q", 8, int(fase) % 2, 0]


## Na festa, o primeiro participante (menor id) toca o tambor.
func _tocador(id: int, t: Dictionary) -> bool:
	return _menor_da_cena(t.cena) == id


## Na guerra, o primeiro de cada cena leva o estandarte.
func _porta_estandarte(id: int, t: Dictionary) -> bool:
	return _menor_da_cena(t.cena) == id


func _menor_da_cena(c: Dictionary) -> int:
	var menor := 1 << 30
	for p in sim.pessoas:
		var pc: Dictionary = p.get("cena", {})
		if str(pc.get("id", -1)) == str(c.get("id", -2)):  # há cenas com id em texto
			menor = mini(menor, p["id"])
	return menor


## Objetos de cena: a mortalha sobre os dois carregadores, o tambor da festa e
## as bandeirolas sobre a roda de dança.
func _objetos_de_cena(r: Array, relogio: float) -> void:
	var por_cena := {}
	for f in r:
		var c: Dictionary = f.cena
		if c.is_empty():
			continue
		var chave := "%s:%s" % [c.get("tipo", ""), c.get("id", 0)]
		if not por_cena.has(chave):
			por_cena[chave] = []
		por_cena[chave].append(f)
	for chave in por_cena:
		var fs: Array = por_cena[chave]
		var tipo: String = chave.get_slice(":", 0)
		match tipo:
			"funeral":
				var carregam := fs.filter(func(f): return f.acao == "carregar_morto")
				if carregam.size() >= 2:
					carregam.sort_custom(func(a, b): return a.x < b.x)
					var a: Dictionary = carregam[0]
					var b: Dictionary = carregam[1]
					var meio: float = (a.x + b.x + 8) / 2.0
					objetos.append(_objeto("objetos/corpo_mortalha", 16, roundi(meio) - 8, a.base - 8, a.codigo))
			"cacada":  # a caça no pau, entre os dois que voltam carregando
				var carregam := fs.filter(func(f): return f.folha.ends_with("carregar_caca_forte_4q"))  # andando ou esperando
				carregam.sort_custom(func(a, b): return a.x < b.x)
				if carregam.size() >= 2 and absf(carregam[-1].x - carregam[0].x) <= 30:
					# dois no pau, a 16 px um do outro, em volta do meio da fila; os outros atrás
					var dir := -1.0 if carregam[0].espelho else 1.0
					if dir < 0.0:
						carregam.reverse()  # do da frente para os de trás
					var meio: float = (carregam[0].x + carregam[1].x) / 2.0
					carregam[0].x = roundi(meio + dir * VAO_DO_PAU / 2.0)
					carregam[1].x = roundi(meio - dir * VAO_DO_PAU / 2.0)
					for k in range(2, carregam.size()):
						carregam[k].x = roundi(meio - dir * (VAO_DO_PAU / 2.0 + 7.0 * (k - 1)))
					var a: Dictionary = carregam[0] if carregam[0].x < carregam[1].x else carregam[1]
					var b: Dictionary = carregam[1] if a == carregam[0] else carregam[0]
					# o pau (linhas 0 e 1 do objeto) nas linhas 3 e 4 dos carregadores; o
					# objeto sai do carregador de trás, e o bicho pende no vão entre os dois
					var o := _objeto("objetos/caca_no_pau_porco_forte", 24, a.x if not a.espelho else b.x - 16,
						a.base - 11 + 3 + 8, 0)
					o.espelho = a.espelho
					o.fogo = a.fogo
					objetos.append(o)
			"festa", "casamento":
				var xs: Array = fs.map(func(f): return f.x)
				var ini: int = xs.min() - 4
				var fim: int = xs.max() + 12
				var y: int = vista.chao_pessoa(roundi((ini + fim) / 2.0)) - 17
				for x in range(ini, fim, 16):
					objetos.append(_objeto("objetos/bandeirolas", 16, x, y, 0))
				for f in fs:
					if f.folha == "acoes/tocar_tambor_4q":
						objetos.append(_objeto("objetos/tambor", 8, f.x + (-7 if f.espelho else 7), f.base, f.codigo))


## Objetos do cotidiano: a panela ou o espeto diante de quem cozinha, e as
## rodas d'água dos canais (paradas e congeladas no inverno, pela própria arte).
func _objetos_do_cotidiano(r: Array, relogio: float) -> void:
	for e in vista.estandartes:  # a bandeira do povo, ao vento
		var est := _objeto(e.folha, 4, int(e.x), int(e.base), 0)
		est.quadro = int(relogio * 1.3 + e.x) % 2
		est.fogo = vista.fogo_mais_perto(float(e.x))
		objetos.append(est)
	for roda in vista.rodas:
		var o := _objeto("estagio6/roda_dagua_4q", 16, roundi(roda.x) - 8, int(roda.base) + 1, 0)
		o.quadro = 0 if sim.ritmo == Simulacao.Ritmo.PAUSA else int(relogio * 4.0) % 4
		o.fogo = vista.fogo_mais_perto(roda.x)
		objetos.append(o)
	for f in r:
		var frente: int = -7 if f.espelho else 7
		match f.folha:
			"acoes/cozinhar_mexer_4q":
				objetos.append(_objeto("objetos/panela", 8, f.x + frente, f.base, 0))
			"acoes/cozinhar_espeto_4q":
				objetos.append(_objeto("objetos/espeto", 12, f.x + frente - 2, f.base, 0))
		match f.get("detalhe", ""):
			"despejar":  # o cesto virado no chão, à frente
				objetos.append(_objeto("objetos/cesto_cheio", 8, f.x + frente, vista.chao(f.x + frente + 4), 0))
			"pescar_lanca":  # de vez em quando um peixe pula à frente de quem pesca: ali tem peixe
				var ciclo := fmod(relogio + f.id * 3.7, 9.0)
				if ciclo < 1.2:
					var px: int = f.x + (-16 if f.espelho else 20)
					var peixe := _objeto("criaturas/peixe_pular_forte_4q", 10, px, Terreno.NIVEL_AGUA, 0)
					peixe.quadro = mini(int(ciclo / 0.3), 3)
					peixe.espelho = f.espelho
					objetos.append(peixe)


## Quem chega de além da borda: entram pela borda da direita (o lado do morro,
## longe do lago) e andam até o fogo. `recomeco`: o povo novo do mundo vazio.
func chegada(ids: Array, fogo: float, recomeco: bool) -> void:
	var lista := ids.duplicate()
	lista.sort()
	for k in lista.size():
		var id: int = lista[k]
		_chegando[id] = {"ini": vista._relogio, "fogo": fogo, "k": k, "recomeco": recomeco}
		_x[id] = float(LARGURA + 6 + 9 * k)  # fora da tela, em fila


func _visual_da_chegada(chega: Dictionary, p: Dictionary, anda: bool, relogio: float, visual: Array) -> Array:
	var fase: float = relogio + int(p["id"]) * 0.37
	if anda:
		if p["crianca"]:
			return ["habitantes/crianca_andar_4q", 6, int(fase * 6.0) % 4, 0]
		return ["acoes/andar_trouxa_4q", 8, int(fase * 6.0) % 4, 0]
	var t: float = relogio - float(chega.ini)
	if bool(chega.recomeco) and int(chega.k) == 0 and t < RECOMECO_ACESA:
		if t < RECOMECO_GIRA:
			return ["acoes/acender_fogo_4q", 12, 0, 0]
		if t < RECOMECO_SOPRA:
			return ["acoes/acender_fogo_4q", 12, int(t * 2.0) % 2, 0]  # gira o pau entre as mãos
		return ["acoes/acender_fogo_4q", 12, 2 if t < RECOMECO_SOPRA + 0.8 else 3, 0]  # a fumaça; sopra
	if not p["crianca"] and t > RECOMECO_GIRA:
		return ["acoes/conversar_falar_4q", 8, int(fase * 2.0) % 4, 0]  # recebidos no fogo
	return visual


## A etapa atual de uma cena com `etapas` (pesca, coleta, lavagem): a etapa da
## API, mais `p` (0..1 dela), ou {}.
func _etapa_de(cena: Dictionary) -> Dictionary:
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		if str(c.get("id", -1)) != str(cena.get("id", -2)):
			continue
		for e in c.get("etapas", []):
			if h >= float(e["ini"]) and h < float(e["fim"]):
				var r: Dictionary = e.duplicate()
				r["p"] = (h - float(e["ini"])) / maxf(float(e["fim"]) - float(e["ini"]), 0.001)
				return r
	return {}


## A ordem de alguém entre os participantes da cena (ou entre as crianças dela,
## com `criancas`), ou 99.
func _posto_na_cena(cena: Dictionary, id: int, criancas := false) -> int:
	for c in sim.cenas:
		if str(c.get("id", -1)) == str(cena.get("id", -2)):
			var k: int = c.get("criancas" if criancas else "participantes", []).find(id)
			return k if k >= 0 else 99
	return 99


## A beira do lago como se vê: a primeira coluna depois da água desenhada.
func _beira() -> int:
	return vista.beira_visivel


## Na pesca e no banho, dentro da água rasa; na lavagem, ajoelhado na beira
## com o pano sobre a água. {x (o centro), espelho}, ou {} fora dessas cenas.
func _no_lago(t: Dictionary, id: int) -> Dictionary:
	var detalhe: String = t.get("detalhe", "")
	var beira := float(_beira())
	if detalhe == "lavar":
		# o corpo nas colunas 4 a 11 (na terra), o pano nas 0 a 3 (sobre a água), a 10 px um do outro
		return {"x": beira + 10.0 * mini(_posto_na_cena(t.cena, id), 3), "espelho": true}
	if not detalhe in NA_AGUA or (t.anda and detalhe == "peixe_na_lanca"):
		return {}
	if detalhe == "banho":  # duas a duas, frente a frente, a 7 px
		var k := mini(_posto_na_cena(t.cena, id, true), 5)
		return {"x": vista.chao_aberto(beira - 6.0, -1.0, true) - 7.0 * k, "espelho": k % 2 == 0}
	return {"x": vista.chao_aberto(beira - 9.0, -1.0, true), "espelho": true}  # sem mato na frente


## Os bichos das cenas: a caça no lugar da caçada (até voltarem com ela) e o
## animal que aparece na beira do acampamento.
func _animais_das_cenas(r: Array, relogio: float) -> void:
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		var tipo: String = c.get("tipo", "")
		if tipo == "cacada" and c.has("etapas"):
			_cacada_em_etapas(c, h, relogio, r)
			continue
		if tipo != "animal" and not (tipo == "cacada" and not c.get("vazia", false)):
			continue
		if h < float(c.get("ini", 0.0)) or h > float(c.get("fim", 24.0)):
			continue
		if tipo == "cacada" and r.any(func(f): return f.acao == "carregar_caca" and str(f.cena.get("id", -1)) == str(c.get("id", -2))):
			continue  # já abatida: vai no pau, com os carregadores
		var x := roundi(float(c.get("x", 300.0)))
		var ave := int(c.get("id", 0)) % 2 == 1
		var o := _objeto("criaturas/ave_grande_4q" if ave else "criaturas/porco_do_mato_4q", 8 if ave else 10,
			x - (4 if ave else 5), vista.chao(x), 0)
		o.quadro = int(relogio * 4.0) % 4
		o.espelho = int(relogio / 5.0 + int(c.get("id", 0))) % 2 == 0
		o.fogo = vista.fogo_mais_perto(float(x))
		objetos.append(o)


## A etapa da caçada agora: {etapa, xb (o bicho, em chão aberto), lado (de onde
## vêm os caçadores), p (0..1 da etapa), vazia}, ou {}.
func _etapa_da_cacada(c: Dictionary, h: float) -> Dictionary:
	var etapas: Array = c.get("etapas", [])
	if etapas.is_empty():
		return {}
	# o lado da mata: do fogo (de onde saem) para o porco
	var lado := signf(float(etapas[0].get("x_bicho", 0.0)) - float(etapas[0].get("x", 0.0)))
	lado = lado if lado != 0.0 else 1.0
	var antes := -1.0
	var xc_antes := -1.0
	for e in etapas:
		var xb := float(e.get("x_bicho", -1.0))
		var xc := float(e.get("x", xb))
		if h >= float(e["ini"]) and h < float(e["fim"]):
			var p := (h - float(e["ini"])) / maxf(float(e["fim"]) - float(e["ini"]), 0.001)
			if e["etapa"] == "espreita" and antes >= 0.0 and xb >= 0.0:  # o porco fuçando vai de um ponto ao outro
				xb = lerpf(antes, xb, minf(p / 0.4, 1.0))
			if e["etapa"] == "espreita" and xc_antes >= 0.0:  # e os caçadores avançam uns passos
				xc = lerpf(xc_antes, xc, minf(p / 0.3, 1.0))
			return {"etapa": String(e["etapa"]), "xb": vista.chao_aberto(xb, -lado) if xb >= 0.0 else xb,
				"xc": xc, "lado": lado, "p": p, "vazia": c.get("vazia", false),
				"mira": e.get("mira", false), "fogo": float(etapas[0].get("x", 0.0)), "cozinha": int(c.get("cozinha", -1))}
		antes = xb
		xc_antes = xc if e["etapa"] == "espreita" else -1.0
	return {}


## A etapa da caçada de uma cena (pelo id), ou {}.
func _etapa_da_cena(cena: Dictionary) -> Dictionary:
	if cena.get("tipo", "") != "cacada":
		return {}
	for c in sim.cenas:
		if str(c.get("id", -1)) == str(cena.get("id", -2)):
			return _etapa_da_cacada(c, sim.hora_continua())
	return {}


## A ordem de quem caça na cena (0 é quem arremessa), ou 99.
func _posto_na_cacada(cena: Dictionary, id: int) -> int:
	for c in sim.cenas:
		if str(c.get("id", -1)) == str(cena.get("id", -2)):
			var k: int = c.get("participantes", []).find(id)
			return k if k >= 0 else 99
	return 99


## Onde cada caçador fica: {x, espelho}, ou {}. Na espreita, na mira e no
## arremesso, em fila atrás do da frente, a 7 px um do outro. No abate, os dois
## que vão carregar amarram o bicho, um de cada lado; os outros esperam atrás.
func _lugar_na_cacada(t: Dictionary, id: int) -> Dictionary:
	var detalhe: String = t.get("detalhe", "")
	if not detalhe in ["espreitar", "mirar", "apontar", "arremessar", "recolher_caca"]:
		return {}
	var e := _etapa_da_cena(t.cena)
	var etapa: String = e.get("etapa", "")
	var lado: float = e.get("lado", 1.0)
	var k := _posto_na_cacada(t.cena, id)
	if k == 99:
		return {}
	if etapa in ["espreita", "arremesso"] and detalhe != "recolher_caca":
		return {"x": float(e.xc) - lado * FILA_CACADA * k, "espelho": lado < 0.0}
	if etapa == "abatido" and detalhe == "recolher_caca":
		match k:
			0:
				return {"x": float(e.xb) - lado * 7.0, "espelho": lado < 0.0}
			1:
				return {"x": float(e.xb) + lado * 7.0, "espelho": lado > 0.0}
		return {"x": float(e.xb) - lado * (14.0 + FILA_CACADA * (k - 1)), "espelho": lado < 0.0}
	return {}


## A caçada em sequência (API: `etapas`; arte, seção 24): o porco fuçando
## enquanto os caçadores espreitam, a lança voando, o porco atingido e caído com
## o pau no chão (ou fugindo para a mata) e, na volta, a caça no pau.
func _cacada_em_etapas(c: Dictionary, h: float, relogio: float, r: Array) -> void:
	var e := _etapa_da_cacada(c, h)
	var no_pau := r.any(func(f): return f.folha.ends_with("carregar_caca_forte_4q") and str(f.cena.get("id", -1)) == str(c.get("id", -2)))
	if e.get("etapa", "") == "repartir" and not e.vazia and float(e.p) < 0.45 and not no_pau:
		# a caça chega ao fogo: fica no chão, do lado de quem espera com o espeto, até ir para o espeto
		var xr: float = float(e.fogo) + float(e.lado) * 15.0
		_bicho("criaturas/porco_abatido", 10, xr - 5, vista.chao(roundi(xr)), 0, float(e.lado) > 0, vista.fogo_mais_perto(xr))
		return
	if e.is_empty() or float(e.xb) < 0.0:
		return
	var xb: float = e.xb
	var lado: float = e.lado
	var p: float = e.p
	var chao_b: int = vista.chao(roundi(xb))
	var fogo_b: float = vista.fogo_mais_perto(xb)
	match String(e.etapa):
		"saida", "espreita":  # fuçando, de costas para quem chega
			_bicho("criaturas/porco_do_mato_4q", 10, xb - 5, chao_b, int(relogio * 3.0) % 4, lado < 0, fogo_b)
		"arremesso":
			if vista.modo_discreto and not e.vazia and p >= CRAVA:  # o discreto pula o golpe: o porco já caído
				_bicho("criaturas/porco_abatido", 10, xb - 5, chao_b, 0, lado < 0, fogo_b)
			elif e.vazia or p < CRAVA:  # fuçando até a lança chegar (e, se errou, assustado no lugar)
				_bicho("criaturas/porco_do_mato_4q", 10, xb - 5, chao_b, 0 if e.vazia else int(relogio * 3.0) % 4, lado < 0, fogo_b)
			else:  # a lança crava, ele cambaleia e tomba (desenhado 2 px à esquerda)
				_bicho("criaturas/porco_atingido_4q", 12, xb - 7, chao_b, mini(int((p - CRAVA) * 12.0), 3), lado < 0, fogo_b)
			if p >= SOLTA and p < CRAVA and not vista.modo_discreto:  # a lança voando, num arco raso, da mão do caçador ao bicho
				var q := (p - SOLTA) / (CRAVA - SOLTA)
				var lx := lerpf(float(e.xc) + lado * 2.0, xb, q)
				var lanca := _objeto("objetos/lanca_voando_forte", 14, roundi(lx) - 7, chao_b - 7 - roundi(sin(q * PI) * 6.0), 0)
				lanca.espelho = lado < 0
				objetos.append(lanca)
		"abatido":  # o bicho caído em chão aberto, e o pau do outro lado dele
			_bicho("criaturas/porco_abatido", 10, xb - 5, chao_b, 0, lado < 0, fogo_b)
			var xp := roundi(xb + 7.0) if lado > 0 else roundi(xb - 31.0)
			objetos.append(_objeto("objetos/pau_no_chao", 24, xp, vista.chao(xp + 12), 0))
		"fuga":  # errou: o porco foge a galope para dentro da mata, e a lança fica cravada
			var xf := xb + lado * 40.0 * minf(p * 3.0, 1.0)
			if p < 0.34:
				_bicho("criaturas/porco_correr_4q", 10, xf - 5, vista.chao(roundi(xf)), int(relogio * 8.0) % 4, lado < 0, fogo_b)
			if not vista.modo_discreto:
				objetos.append(_objeto("objetos/lanca_cravada", 8, roundi(xb) - 4, chao_b, 0))


func _bicho(folha: String, largura: int, x: float, base: int, quadro: int, espelho: bool, fogo: float) -> void:
	var o := _objeto(folha, largura, roundi(x), base, 0)
	o.quadro = quadro
	o.espelho = espelho
	o.fogo = fogo
	objetos.append(o)


## A cena ativa (de sim.cenas) com o mesmo id da cena do trecho, que traz só tipo e id.
func _cena_ativa(cena: Dictionary) -> Dictionary:
	for c in sim.cenas:
		if str(c.get("id", -1)) == str(cena.get("id", -2)):
			return c
	return {}


## Onde o mestre fica enquanto a criança tenta: MESTRE_LONGE atrás de quem atira (o
## núcleo o põe a 4 px, e as duas figuras de 12 px viravam uma silhueta só).
func _lugar_do_mestre(cena: Dictionary, destino: float) -> float:
	var c := _cena_ativa(cena)
	if c.get("etapas", []).is_empty():
		return destino
	var xa: float = float(c["etapas"][0]["x"])
	var lado: float = 1.0 if float(c.get("alvo", xa)) >= xa else -1.0
	return xa - lado * MESTRE_LONGE


## O minuto (de jogo) dentro da etapa atual da cena, e a etapa.
func _minuto_da_etapa(cena: Dictionary) -> Array:
	var e := _etapa_de(cena)
	if e.is_empty():
		return [e, 0.0]
	return [e, (sim.hora_continua() - float(e["ini"])) * 60.0]


## O quadro do arremesso ao alvo: recolhe, ergue, solta (a lança sai) e acompanha, no
## minuto 2 a 3 da etapa (a do velho, mostrar, e as da criança, tentativa).
func _quadro_do_alvo(t: Dictionary) -> int:
	var sub: float = clampf(float(_minuto_da_etapa(t.cena)[1]) - 2.0, 0.0, 0.999)
	return 0 if sub < 0.2 else 1 if sub < SOLTA_ALVO else 2 if sub < 0.6 else 3


## O alvo de capim da cena ensinar, na borda da vila, do começo ao fim dela, e a lança:
## voando, cravada no alvo quando acerta, ou caída ao lado quando erra, até alguém buscar.
func _alvos_de_capim() -> void:
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		if c.get("tipo", "") != "ensinar" or c.get("etapas", []).is_empty():
			continue
		var etapas: Array = c["etapas"]
		if h < float(etapas[0]["ini"]) or h >= float(etapas[-1]["fim"]):
			continue
		var xa: float = float(etapas[0]["x"])
		var alvo: float = float(c.get("alvo", xa))
		var lado: float = 1.0 if alvo >= xa else -1.0
		var me := _minuto_da_etapa(c)
		var e: Dictionary = me[0]
		var m: float = me[1]
		var dura: float = (float(e.get("fim", 0.0)) - float(e.get("ini", 0.0))) * 60.0
		var estado := "mao"
		match String(e.get("etapa", "")):
			"mostrar", "tentativa":
				var buscar := (dura - 4.0) / 2.0  # no mostrar, o velho busca a lança no alvo
				if m >= 2.0 + SOLTA_ALVO and m < 2.0 + CRAVA_ALVO:
					estado = "voando"
				elif m >= 2.0 + CRAVA_ALVO:
					estado = ("cravada" if e.get("acerto", false) else "chao")
					if e["etapa"] == "mostrar" and m >= 3.0 + buscar + 0.5:
						estado = "mao"
			"buscar":  # depois de um erro: a lança no chão até a criança chegar a ela
				if m < (dura - 1.0) / 2.0 + 0.5:
					estado = "chao"
			"aprovar":
				estado = "cravada"
		var chao_a: int = vista.chao(int(alvo))
		var fogo: float = vista.fogo_mais_perto(alvo)
		var o: Dictionary
		if estado == "cravada":  # a lança entra pela esquerda (cols. 0 a 3); vinda da direita, espelha
			o = _objeto("objetos/alvo_capim_lanca", 12, roundi(alvo) - (8 if lado > 0.0 else 4), chao_a, 0)
			o.espelho = lado < 0.0
		else:
			o = _objeto("objetos/alvo_capim", 8, roundi(alvo) - 4, chao_a, 0)
		o["corpo"] = o.largura
		o.fogo = fogo
		objetos.append(o)
		if estado == "chao":  # caída à frente do alvo, do lado de quem atira
			var lc := _objeto("objetos/lanca_no_chao", 14, roundi(alvo - lado * 6.0) - 7, vista.chao(int(alvo - lado * 6.0)), 0)
			lc.espelho = lado < 0.0
			lc["corpo"] = 14
			lc.fogo = fogo
			objetos.append(lc)
		elif estado == "voando":  # num arco, da mão ao miolo do alvo
			# a lança de 2 px (arte: a ponta no pixel (11, 1); espelhada, em (0, 1)) leva a ponta
			# da mão até o miolo (colunas 2 e 3 e linha 3 do alvo de 8 × 14)
			var q: float = (m - 2.0 - SOLTA_ALVO) / (CRAVA_ALVO - SOLTA_ALVO)
			var px: float = lerpf(xa + lado * 4.0, alvo - (2.0 if lado > 0.0 else 1.0), q)
			var py: float = lerpf(vista.chao(int(xa)) - 8.0, chao_a - 10.0, q) - sin(q * PI) * ARCO_ALVO
			var lv := _objeto("objetos/lanca_voando_alvo", 12, roundi(px) - (11 if lado > 0.0 else 0), roundi(py), 0)
			lv.espelho = lado < 0.0
			lv["corpo"] = 12
			lv.fogo = fogo
			objetos.append(lv)


func _objeto(folha: String, largura: int, x: int, base: int, codigo: int) -> Dictionary:
	return {"id": -1, "folha": folha, "quadro": 0, "largura": largura, "x": x, "base": base, "espelho": false,
		"codigo": codigo, "fogo": -10000.0, "acompanhada": false, "movendo": false, "atras": false, "acao": "", "cena": {}}


# --- lugares ---------------------------------------------------------------------

## Onde cada pessoa parada fica, sem amontoar. Quem está na fogueira quer um
## lugar da roda; os outros querem o destino do trecho. Todos os da frente são
## empacotados numa fila só. A ordem é pelo x desejado e pelo id, então ninguém
## troca de lugar de um quadro para o outro. Quem anda não entra: vai direto.
func _lugares(pessoas: Array, trechos: Dictionary) -> Dictionary:
	_atras.clear()
	_ocultos.clear()
	var desejos := []  # [x desejado, id]
	var lugar := {}
	var rodas := {}
	_em_casa_nesta_hora(pessoas, trechos)
	for p in pessoas:
		var t: Dictionary = trechos[p["id"]]
		if t.acao == "dormir" or t.anda or _ocultos.has(p["id"]):
			continue
		# os pares que conversam e quem rema ficam onde o núcleo pôs
		if t.acao in ["conversar", "remar", "lutar", "carregar_morto"]:
			continue
		if t.acao == "fogueira":
			var f: float = vista.fogo_mais_perto(t.destino)
			if not rodas.has(f):
				rodas[f] = []
			rodas[f].append(p["id"])
		else:
			desejos.append([t.destino, p["id"]])
	for f in rodas:
		var roda: Array = rodas[f]
		roda.sort()
		var n := mini(roda.size(), RODA_CHEIA)
		# junto da água (ou da borda), a roda toda fica do lado que cabe
		var esquerda: bool = f - RODA_RAIO >= MARGEM + 2.0
		var direita: bool = f + RODA_RAIO <= LARGURA - 4.0
		var dois_lados: bool = esquerda and direita
		var por_lado := ceili(n / 2.0) if dois_lados else n
		for i in roda.size():
			if i >= n:  # a roda cheia: o resto fica em casa
				_ocultos[roda[i]] = true
				continue
			# alternando os lados; em cada arco, de trás (no alto) para a frente
			var lado := (1.0 if i % 2 == 0 else -1.0) if dois_lados else (1.0 if direita else -1.0)
			var t := ((int(i / 2) if dois_lados else i) + 0.5) / por_lado
			var angulo := deg_to_rad(-60.0 + 120.0 * t)
			lugar[roda[i]] = f + lado * RODA_RAIO * cos(angulo)
			if sin(angulo) < 0.0:
				_atras[roda[i]] = true
	var casas: int = maxi(1, sim.construcoes.filter(func(o): return o["tipo"] == "cabana").size())
	var limite := clampi(PARADOS_POR_CASA * casas, PARADOS_MIN, PARADOS_MAX)
	if desejos.size() > limite:
		desejos = _sem_os_ociosos(desejos, trechos, limite, lugar)
	desejos.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	# com muita gente, duas fileiras: os de índice ímpar ficam meio passo atrás,
	# 2 px acima e desenhados antes, em vez de uma fila só de ponta a ponta
	var denso := desejos.size() > MULTIDAO
	var xs := _empacotar(desejos.map(func(d): return d[0]), ESPACO / 2.0 if denso else float(ESPACO))
	for i in desejos.size():
		lugar[desejos[i][1]] = xs[i]
		if denso and i % 2 == 1:
			_atras[desejos[i][1]] = true
	return lugar


## Com parados demais, os ociosos (parados sem cena, descansando ou guardando)
## vão para dentro de casa primeiro, depois os outros sem cena, até sobrarem
## PARADOS_MAX. A escolha muda a cada dia, mas fica a mesma dentro do dia.
func _sem_os_ociosos(desejos: Array, trechos: Dictionary, limite: int, lugar: Dictionary) -> Array:
	var dia: int = int(sim.tempo.get("dia", 1))
	var ordem := desejos.duplicate()
	ordem.sort_custom(func(a, b):
		var pa := _prioridade(trechos[a[1]])
		var pb := _prioridade(trechos[b[1]])
		return pa < pb or (pa == pb and hash(a[1] * 31 + dia) < hash(b[1] * 31 + dia)))
	var sobra := desejos.size() - limite
	var zonas := _cantos_das_zonas()
	var ficam := []
	var k := 0
	for d in ordem:
		if sobra > 0 and _prioridade(trechos[d[1]]) < 2:
			sobra -= 1
			k += 1
			if k % 2 == 0 or zonas.is_empty():  # metade fica em casa...
				_ocultos[d[1]] = true
			else:  # ...e a outra metade passa a hora na roça, na beira do lago ou no morro
				var z: Vector2 = zonas[(d[1] + k) % zonas.size()]
				lugar[d[1]] = z.x + (k * 7) % int(z.y)
		else:
			ficam.append(d)
	return ficam


## Trechos fora da frente da vila onde quem sobra passa a hora: {x inicial, largura}.
func _cantos_das_zonas() -> Array:
	var r := [Vector2(MARGEM + 2.0, 12.0), Vector2(380.0, 70.0)]  # a beira do lago e o morro
	for o in sim.construcoes:
		if o["tipo"] == "roca":
			r.append(Vector2(float(o["x"]) - 8.0, 16.0))
	return r


## Com gente demais, uma parte passa a hora em casa (não é desenhada). A escolha
## muda a cada hora e é a mesma dentro dela; nunca quem está numa cena ou é seguido.
func _em_casa_nesta_hora(pessoas: Array, trechos: Dictionary) -> void:
	var acordados := pessoas.filter(func(p): return trechos[p["id"]].acao != "dormir")
	var sobra := acordados.size() - VISIVEIS_MAX
	if sobra <= 0:
		return
	var hora: int = int(sim.tempo.get("dia", 1)) * 24 + int(sim.tempo.get("hora", 0))
	var podem := acordados.filter(func(p): return trechos[p["id"]].cena.is_empty() and not p.get("acompanhada", false))
	podem.sort_custom(func(a, b): return hash(a["id"] * 131 + hora) < hash(b["id"] * 131 + hora))
	for i in mini(sobra, podem.size()):
		_ocultos[podem[i]["id"]] = true


## 0: ocioso; 1: fazendo algo, sem cena; 2: numa cena (nunca some).
func _prioridade(t: Dictionary) -> int:
	if not t.cena.is_empty():
		return 2
	if t.acao == "parado" and t.get("detalhe", "") in ["", "descansar", "guardar", "doente"]:
		return 0
	return 1


## Posições em ordem, a ESPACO ou mais umas das outras, o mais perto possível
## das desejadas (blocos que se encostam se juntam e se centram), dentro da
## terra e da tela.
static func _empacotar(desejado: Array, espaco: float = ESPACO) -> Array:
	var blocos := []  # [quantos, soma de (x - k × espaco)]
	for x in desejado:
		blocos.append([1, x])
		while blocos.size() >= 2:
			var a: Array = blocos[-2]
			var b: Array = blocos[-1]
			if a[1] / a[0] + a[0] * espaco <= b[1] / b[0]:
				break
			blocos.pop_back()
			blocos[-1] = [a[0] + b[0], a[1] + b[1] - b[0] * a[0] * espaco]
	var xs := []
	for bl in blocos:
		var inicio: float = bl[1] / bl[0]
		for k in bl[0]:
			xs.append(inicio + k * espaco)
	for i in xs.size():  # a margem do lago e a borda direita
		xs[i] = maxf(xs[i], MARGEM if i == 0 else xs[i - 1] + espaco)
	for i in range(xs.size() - 1, -1, -1):
		xs[i] = minf(xs[i], LARGURA - 4.0 if i == xs.size() - 1 else xs[i + 1] - espaco)
	return xs


## Teste: quantas figuras cobrem a mesma coluna de pixels (a regra é no máximo 2).
func _contar_sobreposicao() -> void:
	var maiores := [0, 0]  # só os parados, e todos
	for so_parados in [true, false]:
		var colunas := PackedInt32Array()
		colunas.resize(LARGURA)
		for f in figuras:
			if so_parados and f.movendo:
				continue
			for x in range(maxi(0, f.x + 1), mini(LARGURA, f.x + 7)):  # sem a borda de 1 px
				colunas[x] += 1
		for c in colunas:
			maiores[0 if so_parados else 1] = maxi(maiores[0 if so_parados else 1], c)
	if maiores[0] > _maior_sobreposicao[0] or maiores[1] > _maior_sobreposicao[1]:
		_maior_sobreposicao = [maxi(maiores[0], _maior_sobreposicao[0]), maxi(maiores[1], _maior_sobreposicao[1])]
		print("[sobreposicao] parados=%d todos=%d hora=%s figuras=%d" % [_maior_sobreposicao[0], _maior_sobreposicao[1],
			sim.tempo.get("hora"), figuras.size()])

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
## entre vizinhos; a roda da fogueira pula as cabanas e, com mais de RODA_MAX
## pessoas, ganha uma segunda fileira meio passo atrás.

const Arte = preload("res://apresentacao/arte.gd")
const Terreno = preload("res://apresentacao/terreno.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")

const LARGURA := 480
const PASSO_ANDAR := 9.0      # px/s médio de quem anda; cada pessoa varia de 0,8 a 1,2 disto
const ESPACO := 7             # distância mínima entre pessoas paradas lado a lado
const MARGEM := 130.0         # ninguém fica à esquerda disto (é água; API: x ≥ 126)
const RODA_MAX := 10          # quantos cabem na primeira fileira da roda da fogueira
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
	"carregar_caca": "acoes/carregar_caca_4q", "cacar": "acoes/cacar_espreitar_4q"}
## Detalhes da rotina (API v10, campo `detalhe`; arte, seção 20) com folha de 4
## quadros em laço. Sem folha própria, vale a da `acao`, como antes.
## detalhe -> [folha, largura do quadro]. As versões "de 1x" (seção 22 da arte)
## mudam a silhueta e trazem objetos maiores, para quem olha de canto de olho.
const DETALHES := {"colher_arbusto": ["acoes/colher_arbusto_4q", 8], "cavar_raiz": ["acoes/cavar_raiz_4q", 8],
	"catar_lenha": ["acoes/catar_lenha_forte_4q", 12], "buscar_agua": ["acoes/buscar_agua_forte_4q", 12],
	"banho": ["acoes/banhar_4q", 8], "espantar": ["acoes/espantar_forte_4q", 12], "discutir": ["acoes/discutir_4q", 8],
	"separar": ["acoes/conversar_falar_4q", 8], "arremessar": ["acoes/cacar_arremessar_4q", 8],
	"bocejar": ["acoes/bocejar_4q", 8], "espreitar": ["acoes/cacar_espreitar_4q", 8]}
## Detalhes andando: a carga ou a ferramenta da ida e da volta.
const DETALHES_ANDANDO := {"carregar_cesto": "acoes/carregar_cesto_cabeca_forte_4q",
	"carregar_cesto_cabeca": "acoes/carregar_cesto_cabeca_forte_4q", "levar_cesto": "acoes/andar_cesto_4q",
	"carregar_agua": "acoes/carregar_agua_forte_4q", "carregar_feixe": "acoes/carregar_lenha_4q",
	"caca_no_pau": "acoes/carregar_caca_forte_4q", "espreitar": "acoes/cacar_espreitar_4q"}
## Folhas que têm a roupa dos estágios 3 a 6 em estagioN/, com o mesmo nome (arte, seção 25).
const COM_ROUPA_DO_ESTAGIO := ["catar_lenha_forte_4q", "carregar_cesto_cabeca_forte_4q", "espantar_forte_4q",
	"tropecar_cair_forte_4q", "carregar_agua_forte_4q", "buscar_agua_forte_4q", "carregar_caca_forte_4q",
	"crianca_pegapega_fugir_4q", "crianca_pegapega_pegar_4q", "crianca_ciranda_4q", "crianca_ciranda_costas_4q",
	"cacar_apontar_2q", "cacar_comemorar_4q", "cacar_amarrar_4q"]

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
	var f: float = sim.fracao()
	var trechos := {}
	for p in sim.pessoas:
		trechos[p["id"]] = trecho(p, f)
	var lugar := _lugares(sim.pessoas, trechos)
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
		var destino: float = lugar.get(id, t.destino)
		if acao != "remar":  # só no barco se fica sobre a água
			destino = maxf(destino, MARGEM)
		var abate := _no_abate(t, id)
		if not abate.is_empty():  # o abate encenado em chão aberto: quem amarra a 8 px, os outros de pé
			destino = abate.x
		if not t.anda:  # ninguém parado em cima da fogueira: afasta para o lado em que já está
			var fogo_d: float = vista.fogo_mais_perto(destino)
			if absf(destino - fogo_d) < FOGO_LIVRE:
				var lado := signf(destino - fogo_d) if destino != fogo_d else (1.0 if id % 2 == 0 else -1.0)
				destino = fogo_d + lado * FOGO_LIVRE
		var x: float = _x.get(id, destino)
		var vel := PASSO_ANDAR * (0.8 + 0.4 * _dado(id, 0)) * rapido
		if absf(destino - x) > 120.0:  # salto no tempo: aparece no lugar novo
			x = destino
		# pausas curtas no caminho: de vez em quando para e olha
		var fatia := int((relogio + id * 1.7) / 3.0)
		var pausa := _dado(id, fatia, 1) < 0.12 and fmod(relogio + id * 1.7, 3.0) < 0.6
		var anterior := x
		if not pausa:
			x = move_toward(x, destino, vel * delta)
		_x[id] = x
		if acao == "dormir":
			_acordou.erase(id)
			continue
		if _ocultos.has(id):
			continue
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
		elif movendo:
			_virada[id] = x < anterior
		elif (acao in OLHA_O_FOGO or t.get("detalhe", "") in OLHA_O_FOGO) and absf(fogo - x) < 40.0:
			_virada[id] = fogo < x  # a roda olha para o fogo (quem está à direita, espelhado)
		elif t.virado != 0:
			_virada[id] = t.virado < 0
		var espelho: bool = _virada.get(id, id % 2 == 0)

		var visual := _visual(p, acao, t, movendo or absf(destino - x) > 0.5, relogio)
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
			"x": xr - (6 if crianca else 8) / 2, "base": base, "espelho": espelho,
			"codigo": Arte.codigo_troca(pele, cabelo, roupa), "fogo": fogo, "acompanhada": p.get("acompanhada", false),
			"movendo": movendo, "atras": _atras.has(id), "acao": acao, "cena": t.cena, "nucleo": t.destino})
	_objetos_de_cena(r, relogio)
	_objetos_do_cotidiano(r, relogio)
	_animais_das_cenas(r, relogio)
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
	return r + objetos


## A folha com a roupa do estágio do povo (estagioN/), se a arte tiver; senão, a de acoes/.
func _com_roupa_do_estagio(folha: String, grupo: int) -> String:
	if not folha.get_file() in COM_ROUPA_DO_ESTAGIO:
		return folha
	var estagio := 1
	for g in sim.grupos:
		if g["id"] == grupo:
			estagio = int(g.get("estagio", 1))
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
		if DETALHES_ANDANDO.has(detalhe):
			return [DETALHES_ANDANDO[detalhe], 8, int(fase * 5.0) % 4, 0]
		if CARGAS.has(acao):
			return [CARGAS[acao], 8, int(fase * 5.0) % 4, 0]
		if cena == "migracao":
			return ["acoes/andar_trouxa_4q" if id % 2 else "acoes/andar_cesto_4q", 8, int(fase * 6.0) % 4, 0]
		if cena == "guerra" and _porta_estandarte(id, t):
			return ["acoes/carregar_estandarte_sol_4q", 12, int(fase * 6.0) % 4, 0]
		if acao == "cuidar" and feminina:
			return ["acoes/mae_bebe_andar_4q", 8, int(fase * 6.0) % 4, 0]
		if idoso:
			return ["habitantes/idoso_andar_4q", 8, int(fase * 4.0) % 4, 0]
		return ["habitantes/adulto_b_andar_4q" if feminina else "habitantes/adulto_a_andar_4q", 8, int(fase * 6.0) % 4, 0]
	if DETALHES.has(detalhe):
		return [DETALHES[detalhe][0], DETALHES[detalhe][1], q4, 0]
	match detalhe:
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
		"recolher_caca":  # acertou: o primeiro da cena amarra o bicho, os outros comemoram de pé
			if _menor_da_cena(t.cena) == id:
				return ["acoes/cacar_amarrar_4q", 12, int(fase * 2.0) % 4, 0]
			return ["acoes/cacar_comemorar_4q", 12, (int(fase * 5.0) + id) % 4, 0]
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
				return ["acoes/cacar_arremessar_4q", 8, int(ciclo * 2.0), 0]
			return ["acoes/cacar_espreitar_4q", 8, 0, 0]
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
				var carregam := fs.filter(func(f): return f.acao == "carregar_caca")
				carregam.sort_custom(func(a, b): return a.x < b.x)
				if carregam.size() >= 2 and absf(carregam[1].x - carregam[0].x) <= 22:
					var a: Dictionary = carregam[0]
					var b: Dictionary = carregam[1]
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


## Os bichos das cenas: a caça no lugar da caçada (até voltarem com ela) e o
## animal que aparece na beira do acampamento.
func _animais_das_cenas(r: Array, relogio: float) -> void:
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		var tipo: String = c.get("tipo", "")
		if tipo == "cacada" and c.has("etapas"):
			_cacada_em_etapas(c, h, relogio)
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
	for e in c.get("etapas", []):
		if h >= float(e["ini"]) and h < float(e["fim"]):
			var xb := float(e.get("x_bicho", -1.0))
			var xc := float(e.get("x", xb))
			var lado := signf(xb - xc) if xb != xc else 1.0
			return {"etapa": String(e["etapa"]), "xb": vista.chao_aberto(xb, -lado) if xb >= 0.0 else xb,
				"xc": xc, "lado": lado, "p": (h - float(e["ini"])) / maxf(float(e["fim"]) - float(e["ini"]), 0.001),
				"vazia": c.get("vazia", false)}
	return {}


## No abate, onde cada caçador fica: {x, espelho}, ou {} fora do abate. Quem
## amarra fica a 8 px do bicho; os outros, de pé com a lança, a 12 a 20 px.
func _no_abate(t: Dictionary, id: int) -> Dictionary:
	if t.cena.get("tipo", "") != "cacada" or t.get("detalhe", "") != "recolher_caca":
		return {}
	for c in sim.cenas:
		if str(c.get("id", -1)) != str(t.cena.get("id", -2)):
			continue
		var e := _etapa_da_cacada(c, sim.hora_continua())
		if e.get("etapa", "") != "abatido":
			return {}
		var lado: float = e.lado
		var distancia := 8.0 if _menor_da_cena(t.cena) == id else 8.0 + 4.0 * (1 + posmod(id, 3))
		return {"x": float(e.xb) - lado * distancia, "espelho": lado < 0.0}
	return {}


## A caçada em sequência (API: `etapas`; arte, seção 24): o porco fuçando
## enquanto os caçadores espreitam, a lança voando, o porco atingido e caído com
## o pau no chão (ou fugindo para a mata) e, na volta, a caça no pau.
func _cacada_em_etapas(c: Dictionary, h: float, relogio: float) -> void:
	var e := _etapa_da_cacada(c, h)
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
			if e.vazia:
				_bicho("criaturas/porco_do_mato_4q", 10, xb - 5, chao_b, 0, lado < 0, fogo_b)
			else:  # a lança crava, ele cambaleia e tomba (desenhado 2 px à esquerda)
				_bicho("criaturas/porco_atingido_4q", 12, xb - 7, chao_b, mini(int(p * 12.0), 3), lado < 0, fogo_b)
			if p < 0.08:  # a lança voando, num arco raso, do caçador ao bicho
				var q := p / 0.08
				var lx := lerpf(float(e.xc), xb, q)
				var lanca := _objeto("objetos/lanca_voando", 12, roundi(lx) - 6, chao_b - 8 - roundi(sin(q * PI) * 6.0), 0)
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
			objetos.append(_objeto("objetos/lanca_cravada", 8, roundi(xb) - 4, chao_b, 0))


func _bicho(folha: String, largura: int, x: float, base: int, quadro: int, espelho: bool, fogo: float) -> void:
	var o := _objeto(folha, largura, roundi(x), base, 0)
	o.quadro = quadro
	o.espelho = espelho
	o.fogo = fogo
	objetos.append(o)


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
	for p in pessoas:
		var t: Dictionary = trechos[p["id"]]
		if t.acao == "dormir" or t.anda:
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
	var cabanas: Array = sim.construcoes.filter(func(o): return o["tipo"] == "cabana").map(func(o): return float(o["x"]))
	for f in rodas:
		var roda: Array = rodas[f]
		roda.sort()
		var lugares := _lugares_da_roda(f, mini(roda.size(), RODA_MAX), cabanas)
		for i in roda.size():
			if i < lugares.size():
				desejos.append([lugares[i], roda[i]])
			elif not lugares.is_empty():  # segunda fileira: entre dois da frente
				var k := (i - lugares.size()) % lugares.size()
				if i >= lugares.size() * 2:  # a roda tem duas fileiras; o resto fica em casa
					_ocultos[roda[i]] = true
					continue
				lugar[roda[i]] = lugares[k] + (ESPACO / 2.0 if lugares[k] > f else -ESPACO / 2.0)
				_atras[roda[i]] = true
	if desejos.size() > PARADOS_MAX:
		desejos = _sem_os_ociosos(desejos, trechos)
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
func _sem_os_ociosos(desejos: Array, trechos: Dictionary) -> Array:
	var dia: int = int(sim.tempo.get("dia", 1))
	var ordem := desejos.duplicate()
	ordem.sort_custom(func(a, b):
		var pa := _prioridade(trechos[a[1]])
		var pb := _prioridade(trechos[b[1]])
		return pa < pb or (pa == pb and hash(a[1] * 31 + dia) < hash(b[1] * 31 + dia)))
	var sobra := desejos.size() - PARADOS_MAX
	var ficam := []
	for d in ordem:
		if sobra > 0 and _prioridade(trechos[d[1]]) < 2:
			_ocultos[d[1]] = true
			sobra -= 1
		else:
			ficam.append(d)
	return ficam


## 0: ocioso; 1: fazendo algo, sem cena; 2: numa cena (nunca some).
func _prioridade(t: Dictionary) -> int:
	if not t.cena.is_empty():
		return 2
	if t.acao == "parado" and t.get("detalhe", "") in ["", "descansar", "guardar", "doente"]:
		return 0
	return 1


## Lugares da roda em volta do fogo em f: dos dois lados, alternando, a partir
## de 11 px do centro, pulando o que cairia na frente de uma cabana.
func _lugares_da_roda(f: float, n: int, cabanas: Array) -> Array:
	var r := []
	var d := [11.0, 11.0]  # próxima distância livre à esquerda e à direita
	var lado := 0
	while r.size() < n:
		var x: float = f + (-1.0 if lado == 0 else 1.0) * d[lado]
		d[lado] += ESPACO
		var livre := x > MARGEM and x < LARGURA - 4
		for c in cabanas:
			if absf(c - x) < 12.0:
				livre = false
		if livre:
			r.append(x)
		if d[0] > 80.0 and d[1] > 80.0:
			break  # não há mais lugar perto do fogo
		lado = 1 - lado
	return r


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

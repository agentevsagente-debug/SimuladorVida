extends SceneTree
## Testa se a cena tem vida, hora a hora, em 5 sementes e nas 4 estações (dias 4, 14, 24 e 34
## do primeiro ano). Metas:
## - de dia (7h às 17h), nunca mais de 40% das pessoas na mesma ação (em gente inteira,
##   arredondado para cima: de 12 pessoas, no máximo 5), como a tela mostra: a
##   `acao`, salvo em `colher` e nas caminhadas (`andar`, `lenha`), em que o `detalhe` é o que
##   se vê (arbusto, raiz, lenha; cesto, vara, machado). `parado` é parado, com ou sem detalhe;
## - no fim de tarde e à noite (17h às 21h), nunca mais de 75% na mesma ação: sempre alguns
##   fazendo outra coisa (cozinhar, ninar, tecer, buscar lenha);
## - de dia, gente em pelo menos 3 das 4 zonas (lago, praia, floresta, morro), pelo lugar de
##   cada um no meio da hora;
## - à noite (22h às 5h), pelo menos 1 pessoa acordada;
## - a cada hora, pelo menos 1 pessoa mudando de lugar;
## - de 6h às 20h, a cada hora, um acontecimento legível em 1x: alguém atravessando pelo menos
##   40 px com uma carga grande (água, feixe, cesto, caça) ou com a ferramenta, crianças
##   correndo, ou um incidente;
## - de madrugada (0h às 4h), a cada hora, algo além do vigia: alguém que acorda, o fogo em
##   brasas, um bicho da noite.
## - ninguém parado a menos de 6 px do centro da fogueira do seu povo;
## - de dia (6h às 17h), ninguém de pé, deitado, sentado no fogo ou conversando no mesmo ponto
##   por mais de 21 min seguidos, fora das cenas;
## - à tarde, das 12h45 às 16h45, em média uma conversa a cada 20 min de jogo ou menos, num
##   povo de 12 pessoas (o povo inicial, com 2 a 4 caçadores, o pescador e quem busca água fora
##   das conversas). Com três ou quatro povos na tela, é um balão a cada poucos segundos em 1x.
## Imprime a tabela hora a hora da semente 1, dia 4. Sai com código 1 se alguma meta falhar.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_vida.gd [-- so_tabela]

const Mundo = preload("res://nucleo/mundo.gd")
const ZONAS := [["lago", 0.0, 136.0], ["praia", 136.0, 200.0], ["floresta", 200.0, 330.0], ["morro", 330.0, 480.0]]

var falhas := 0
var total_conversas := [0]   # conversas que começaram à tarde, em todos os dias testados


func _initialize() -> void:
	var so_tabela := OS.get_cmdline_user_args().has("so_tabela")
	print(_tabela(1, 4))
	if so_tabela:
		quit()
		return
	var problemas: Array = []
	for semente in [1, 2, 3, 4, 5]:
		for dia in [4, 14, 24, 34]:
			for linha in _horas(semente, dia):
				for p in linha["problemas"]:
					problemas.append("semente %d, dia %d, %dh: %s" % [semente, dia, linha["hora"], p])
	for p in problemas.slice(0, 400):
		print("FALHOU: ", p)
	var media := 240.0 * 20 / maxi(1, total_conversas[0])
	print("à tarde (12h45 às 16h45), uma conversa a cada %.0f min de jogo, em média, num povo de 12 pessoas" % media)
	if media > 20.0:
		problemas.append("à tarde, uma conversa a cada %.0f min (meta: 20 ou menos)" % media)
	print("%d horas fora da meta em 5 sementes x 4 estações (480 horas)" % problemas.size())
	quit(1 if not problemas.is_empty() else 0)


## As 24 horas de um dia: para cada uma, o que se vê e o que falha nas metas.
func _horas(semente: int, dia: int) -> Array:
	var m := Mundo.new(semente)
	# Começa a olhar na tarde anterior: a madrugada passa pela troca de rotina, como no jogo.
	while m.passo < dia * 24 - 12:
		m.avancar_hora()
	while m.dia_abs() < dia:
		m.pessoas_visiveis()
		m.avancar_hora()
	var r: Array = []
	var parados := {}   # id -> [x, desde, até] do trecho parado em curso
	var conversas := {}  # janela de 15 min (12h45 às 16h45) -> conversas que começaram nela
	var conversando := {}
	for i in 24:
		var h: int = m.hora()
		var ps: Array = m.pessoas_visiveis()
		var acoes := {}
		var zonas := {}
		var acordados := 0
		var movendo := 0
		var fogos := {}
		for o in m.construcoes():
			if o["tipo"] == "fogueira":
				fogos[o["grupo"]] = o["x"]
		var no_fogo := 0
		var legivel := false
		for cn in m.cenas_ativas():
			if cn["tipo"] in ["briga_criancas", "tombo", "animal", "perdido", "discussao", "cacada", "caca_vazia"]:
				legivel = true
		var madrugada := false
		for cn in m.cenas_ativas():
			if cn["tipo"] in ["brasas", "bicho_noturno", "acordou"]:
				madrugada = true
		var xmin := 999.0
		var xmax := -1.0
		var parado_demais := 0
		for p in ps:
			for tr in p["agenda"]:
				var t0: float = h * 60.0 + tr["de"] * 60.0
				var t1: float = h * 60.0 + tr["ate"] * 60.0
				var fala: bool = tr["acao"] == "conversar"
				if fala and not conversando.get(p["id"], false) and t0 >= 765.0 and t0 < 1005.0:
					var jan := int((t0 - 765.0) / 60.0)
					total_conversas[0] += 1
					conversas[jan] = conversas.get(jan, 0) + 1
				conversando[p["id"]] = fala
				var conta: bool = h >= 6 and h < 17 and tr["x0"] == tr["x1"] and tr["acao"] in ["parado", "deitar", "fogueira", "conversar"] 					and tr["cena"].is_empty()
				if not conta:
					parados.erase(p["id"])
					continue
				var pr: Array = parados.get(p["id"], [])
				if pr.is_empty() or absf(pr[0] - tr["x0"]) > 0.01 or absf(pr[2] - t0) > 0.01:
					pr = [tr["x0"], t0, t1]
				else:
					pr[2] = t1
				parados[p["id"]] = pr
				if pr[2] - pr[1] > 21.0 and pr[2] - pr[1] - (t1 - t0) <= 21.0:
					parado_demais += 1
			var vis: String = p["acao"]
			if vis in ["colher", "andar", "lenha"] and not p.get("detalhe", "").is_empty():
				vis = p["detalhe"]
			acoes[vis] = acoes.get(vis, 0) + 1
			# Onde a pessoa está no meio da hora.
			var xm: float = p["x"]
			for tr in p["agenda"]:
				if tr["de"] <= 0.5 and tr["ate"] >= 0.5:
					xm = lerpf(tr["x0"], tr["x1"], (0.5 - tr["de"]) / maxf(0.001, tr["ate"] - tr["de"]))
			for z in ZONAS:
				if xm >= z[1] and xm < z[2]:
					zonas[z[0]] = true
			if p["acao"] != "dormir":
				acordados += 1
			var anda := absf(p["x_anterior"] - p["x"]) > 0.5
			for tr in p["agenda"]:
				anda = anda or absf(tr["x0"] - tr["x1"]) > 0.5
			if anda:
				movendo += 1
			for tr in p["agenda"]:
				if tr["x0"] == tr["x1"] and fogos.has(p["grupo"]) and absf(tr["x0"] - fogos[p["grupo"]]) < 5.99:
					no_fogo += 1
					break
			var carga := 0.0
			for tr in p["agenda"]:
				if tr.get("detalhe", "") in ["carregar_agua", "carregar_feixe", "carregar_cesto_cabeca", "carregar_cesto", "caca_no_pau",
						"levar_pote", "levar_machado", "levar_cesto", "levar_lanca", "levar_vara"] 						or tr["acao"] == "brincar":
					carga += absf(tr["x1"] - tr["x0"])
			if carga >= 40.0 or (p["acao"] == "brincar" and anda):
				legivel = true
			if p.get("detalhe", "") in ["bocejar", "aticar"]:
				madrugada = true
			xmin = minf(xmin, p["x"])
			xmax = maxf(xmax, p["x"])
		var top := ""
		var topn := 0
		for a in acoes:
			if acoes[a] > topn:
				topn = acoes[a]
				top = a
		var problemas: Array = []
		var dia_claro := h >= 7 and h <= 17
		# 40% em gente inteira, arredondado para cima: de 12 pessoas, no máximo 5.
		if dia_claro and topn > ceili(0.4 * ps.size()):
			problemas.append("%d%% em %s" % [100 * topn / ps.size(), top])
		if h >= 17 and h <= 21 and topn > 0.75 * ps.size():
			problemas.append("%d%% em %s à noitinha" % [100 * topn / ps.size(), top])
		if dia_claro and zonas.size() < 3:
			problemas.append("só %d zonas (%s)" % [zonas.size(), ", ".join(zonas.keys())])
		if (h >= 22 or h <= 4) and acordados == 0:
			problemas.append("ninguém acordado")
		if movendo == 0:
			problemas.append("ninguém mudou de lugar")
		if no_fogo > 0:
			problemas.append("%d em cima da fogueira" % no_fogo)
		if h >= 6 and h <= 20 and not legivel:
			problemas.append("nenhum acontecimento legível")
		if h <= 4 and not madrugada:
			problemas.append("madrugada vazia")
		if parado_demais > 0:
			problemas.append("%d parados no mesmo ponto mais de 21 min" % parado_demais)
		if h == 17:
			pass
		r.append({"hora": h, "n": ps.size(), "top": top, "topn": topn, "zonas": zonas.keys(), "acordados": acordados,
			"movendo": movendo, "x": [xmin, xmax], "acoes": acoes, "problemas": problemas})
		m.avancar_hora()
	return r


func _tabela(semente: int, dia: int) -> String:
	var l: PackedStringArray = ["Semente %d, dia %d: hora a hora" % [semente, dia], "",
		"| Hora | Pessoas | Ação mais comum | Zonas | Acordados | Mudando de lugar | x | Ações |", "|---|---|---|---|---|---|---|---|"]
	for h in _horas(semente, dia):
		var ac: PackedStringArray = []
		for a in h["acoes"]:
			ac.append("%s %d" % [a, h["acoes"][a]])
		l.append("| %02dh | %d | %s %d%% | %s | %d | %d | %d-%d | %s |" % [h["hora"], h["n"], h["top"], 100 * h["topn"] / h["n"],
			"/".join(h["zonas"]), h["acordados"], h["movendo"], h["x"][0], h["x"][1], ", ".join(ac)])
	return "\n".join(l)


func _hm(minuto: int) -> String:
	return "%dh%02d" % [minuto / 60, minuto % 60]

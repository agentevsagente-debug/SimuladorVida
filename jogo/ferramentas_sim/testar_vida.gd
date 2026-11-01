extends SceneTree
## Testa se a cena tem vida, hora a hora, em 5 sementes e nas 4 estações (dias 4, 14, 24 e 34
## do primeiro ano). Metas:
## - de dia (7h às 17h), nunca mais de 40% das pessoas na mesma ação visível (o `detalhe`,
##   quando há, senão a `acao`);
## - de dia, gente em pelo menos 3 das 4 zonas (lago, praia, floresta, morro), pelo lugar de
##   cada um no meio da hora;
## - à noite (22h às 5h), pelo menos 1 pessoa acordada;
## - a cada hora, pelo menos 1 pessoa mudando de lugar.
## Imprime a tabela hora a hora da semente 1, dia 4. Sai com código 1 se alguma meta falhar.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_vida.gd [-- so_tabela]

const Mundo = preload("res://nucleo/mundo.gd")
const ZONAS := [["lago", 0.0, 136.0], ["praia", 136.0, 200.0], ["floresta", 200.0, 330.0], ["morro", 330.0, 480.0]]

var falhas := 0


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
	for p in problemas.slice(0, 40):
		print("FALHOU: ", p)
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
	for i in 24:
		var h: int = m.hora()
		var ps: Array = m.pessoas_visiveis()
		var acoes := {}
		var zonas := {}
		var acordados := 0
		var movendo := 0
		var xmin := 999.0
		var xmax := -1.0
		for p in ps:
			var vis: String = p.get("detalhe", "")
			if vis.is_empty():
				vis = p["acao"]
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
		if dia_claro and topn > 0.4 * ps.size():
			problemas.append("%d%% em %s" % [100 * topn / ps.size(), top])
		if dia_claro and zonas.size() < 3:
			problemas.append("só %d zonas (%s)" % [zonas.size(), ", ".join(zonas.keys())])
		if (h >= 22 or h <= 4) and acordados == 0:
			problemas.append("ninguém acordado")
		if movendo == 0:
			problemas.append("ninguém mudou de lugar")
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

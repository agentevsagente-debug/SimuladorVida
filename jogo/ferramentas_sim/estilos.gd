extends SceneTree
## Estilos de jogador: o custo de intervir é a interpretação. Simula 4 deuses por 100 anos,
## em 3 sementes cada, e compara os povos que saem de cada um:
## - benevolente: atende toda prece, com o poder que ela pede;
## - cruel: raios uma vez por mês de jogo (um em cada quatro acerta alguém), secas fortes e
##   fogo de tempos em tempos. Com menos de 25 pessoas no mundo, os raios só assustam (um
##   povo de 12 a 20 pessoas acaba em poucos anos com dois mortos por ano);
## - ausente: nunca intervém;
## - caprichoso: intervém ao acaso (uma vez a cada 20 dias, em média), com qualquer poder, em
##   qualquer lugar e qualquer força.
## Os estilos são fortes, mas não genocidas: com raios todo dia, qualquer povo acaba, e o
## que se mede é a extinção, não o estilo.
## Grava a tabela e um trecho de crônica de cada estilo em ferramentas_sim/estilos/.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/estilos.gd [-- anos]

const Mundo = preload("res://nucleo/mundo.gd")
const Cotidiano = preload("res://nucleo/cotidiano.gd")
const ESTILOS := ["benevolente", "cruel", "ausente", "caprichoso"]
const SEMENTES := [1, 2, 3]
const PASTA := "res://ferramentas_sim/estilos"
## O deus começa a agir no ano 5: antes disso, a família inicial (12 pessoas) não aguenta
## nenhum estilo forte, e o que se mediria é a extinção.
const ANO_INICIO := 5

var deus := RandomNumberGenerator.new()


func _initialize() -> void:
	var anos := 100
	if OS.get_cmdline_user_args().size() > 0:
		anos = int(OS.get_cmdline_user_args()[0])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	var linhas: Array = []
	var medias := {}
	for estilo in ESTILOS:
		var soma := {}
		for semente in SEMENTES:
			var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
			deus.seed = semente * 7919 + ESTILOS.find(estilo)
			var gestos := 0
			for d in anos * Mundo.DIAS_ANO:
				m.avancar_dias(1)
				if m.fim_do_mundo or m.ano() < ANO_INICIO:
					continue
				gestos += _agir(m, estilo)
			var r := _medir(m)
			r["gestos"] = gestos
			linhas.append([estilo, semente, r])
			for k in r:
				if typeof(r[k]) in [TYPE_INT, TYPE_FLOAT]:
					soma[k] = soma.get(k, 0.0) + float(r[k]) / SEMENTES.size()
			if semente == SEMENTES[0]:
				_trecho(m, estilo, anos)
			print("%s, semente %d: %s" % [estilo, semente, r])
		medias[estilo] = soma
	var texto := _tabela(linhas, medias, anos)
	var f := FileAccess.open(PASTA + "/tabela.md", FileAccess.WRITE)
	f.store_string(texto + "\n")
	f.close()
	print(texto)
	quit()


## Um dia de deus: o que o estilo faz. Devolve quantos gestos fez.
func _agir(m, estilo: String) -> int:
	match estilo:
		"benevolente":
			# Atende toda prece aberta, com o poder que ela pede, onde está quem rezou.
			# (Lê as preces direto dos povos: preces_abertas() calcula a posição de quem rezou,
			# e isso montaria a rotina visível todo dia, o que só a apresentação precisa.)
			var n := 0
			var pedidos: Array = []
			for g in m.grupos_vivos():
				for nec in g.preces:
					pedidos.append([g, nec, g.preces[nec]])
			for pd in pedidos:
				var g = pd[0]
				if g.extinto or not g.preces.has(pd[1]):
					continue
				var x: float = Cotidiano.centro_da_zona(g.zona)
				var poder: String = {"seca": "chuva", "fome": "fartura", "doenca": "cura", "frio": "fartura",
					"guerra": "sonho"}.get(pd[1], "fartura")
				if poder == "cura" and pd[2]["alvo"] != -1:
					x = _onde(m, pd[2]["alvo"])
				if m.usar_poder(poder, x, 0.8).get("ok", false):
					n += 1
			return n
		"cruel":
			var n := 0
			# Raios em gente, uns dois por estação; e seca forte de vez em quando.
			if deus.randf() < 0.07:
				# Um raio em cada quatro cai em alguém; os outros são sinais fracos, que caem perto e
				# assustam sem matar. Com menos de 25 pessoas no mundo, só sinais: um povo pequeno não
				# aguenta perder dois por ano, e o mundo acabaria em poucos anos.
				var ids: Array = m.vivos.keys()
				if not ids.is_empty():
					var x := _onde(m, ids[deus.randi_range(0, ids.size() - 1)])
					var mata: bool = deus.randf() < 0.25 and m.populacao() >= 25
					m.usar_poder("raio", x, 0.9 if mata else 0.3)
					n += 1
			if deus.randf() < 0.006:
				m.usar_poder("seca", deus.randf_range(140.0, 470.0), 0.95)
				n += 1
			if deus.randf() < 0.005:
				m.usar_poder("fogo", deus.randf_range(140.0, 470.0), 0.9)
				n += 1
			return n
		"caprichoso":
			if deus.randf() < 0.04:
				var poder: String = m.PODERES[deus.randi_range(0, m.PODERES.size() - 1)]
				m.usar_poder(poder, deus.randf_range(130.0, 470.0), deus.randf_range(0.3, 0.95))
				return 1
	return 0


## Onde a pessoa está agora (sem deixar o mundo achando que a apresentação está olhando).
func _onde(m, pid: int) -> float:
	var x: float = m.posicao_de(pid)
	m._consultado = false
	return x


## O nome do deus em cada povo vivo. Povos que se separaram de um mesmo povo levam a mesma fé:
## o nome aparece uma vez, com quantos povos o usam.
func _nomes_agora(m) -> String:
	var conta := {}
	var ordem: Array = []
	for g in m.grupos_vivos():
		var n: String = g.nome_deus if g.tem_crenca else "-"
		if not conta.has(n):
			ordem.append(n)
		conta[n] = conta.get(n, 0) + 1
	return ", ".join(ordem.map(func(n): return n if conta[n] == 1 else "%s (%d povos)" % [n, conta[n]]))


func _medir(m) -> Dictionary:
	var fe := 0.0
	for g in m.grupos_vivos():
		for id in g.membros:
			fe += m.pessoas[id].fe
	var nomes := {}
	var conta := {}
	for e in m.eventos:
		conta[e.tipo] = conta.get(e.tipo, 0) + 1
		for k in ["novo", "nome_deus", "deus"]:
			if e.tipo in ["crenca", "deus_renomeado", "profeta", "nova_crenca"] and e.dados.has(k) and typeof(e.dados[k]) == TYPE_STRING:
				nomes[e.dados[k]] = true
	var santas := 0
	for e in m.eventos:
		if e.tipo == "guerra_inicio" and e.dados.get("motivo", "") == "santa":
			santas += 1
	var costumes := 0
	var tipos_costume := {}
	var dependentes := 0
	var estoque := 0.0
	var ceticos := 0
	var crentes := 0
	for g in m.grupos_vivos():
		for c in g.costumes:
			if not c.get("esquecido", false):
				costumes += 1
				tipos_costume[c["tipo"]] = true
		if g.dependente:
			dependentes += 1
		estoque += g.estoque
		if g.ceticos:
			ceticos += 1
		elif g.tem_crenca:
			crentes += 1
	var pop: int = m.populacao()
	return {"populacao": pop, "povos": m.grupos_vivos().size(), "fe_media": fe / maxi(1, pop),
		"nomes_do_deus": nomes.size(), "nomes_agora": _nomes_agora(m),
		"costumes": costumes, "tipos_costume": ", ".join(tipos_costume.keys()), "povos_dependentes": dependentes,
		"estoque_por_pessoa": estoque / maxi(1, pop), "guerras_santas": santas, "ataques": conta.get("ataque", 0),
		"secularizacoes": conta.get("secularizacao", 0), "profetas": conta.get("profeta", 0),
		"preces_atendidas": conta.get("prece_atendida", 0), "preces_sem_resposta": conta.get("prece_sem_resposta", 0),
		"povos_ceticos": ceticos, "povos_crentes": crentes, "fins_do_mundo": conta.get("fim_do_mundo", 0),
		"dependencias": conta.get("dependencia", 0), "exigencias": conta.get("exigencia", 0),
		"desamparos": conta.get("desamparo", 0), "silencios": conta.get("silencio", 0),
		"renascimentos": conta.get("renascimento", 0), "nomes_mudados": conta.get("deus_renomeado", 0) + conta.get("profeta", 0),
		"mortos_pelo_deus": _mortos_pelo_deus(m)}


func _mortos_pelo_deus(m) -> int:
	var n := 0
	for e in m.eventos:
		if e.tipo == "morte" and e.causa == "divina":
			n += 1
	return n


## Um trecho da crônica de cada estilo: os anos 41 a 60 da primeira semente.
func _trecho(m, estilo: String, anos: int) -> void:
	var ini := mini(41, maxi(1, anos - 20))
	var texto: String = m.cronica(ini, mini(ini + 19, m._cronista.ultimo_ano_escrito), false, false)
	var f := FileAccess.open("%s/%s.md" % [PASTA, estilo], FileAccess.WRITE)
	f.store_string("# O deus %s: semente %d, anos %d a %d\n\n%s\n" % [estilo, SEMENTES[0], ini, ini + 19, texto])
	f.close()


func _tabela(linhas: Array, medias: Dictionary, anos: int) -> String:
	var l: PackedStringArray = ["# Estilos de jogador: %d anos, sementes %s" % [anos, str(SEMENTES)], "",
		"Média das 3 sementes no fim:", "",
		"| | " + " | ".join(ESTILOS) + " |", "|---|" + "---|".repeat(ESTILOS.size())]
	var campos := [["populacao", "População", "%.0f"], ["povos", "Povos", "%.1f"], ["fe_media", "Fé média (-1 a 1)", "%.2f"],
		["nomes_do_deus", "Nomes do deus na história", "%.1f"], ["costumes", "Costumes vivos", "%.1f"],
		["povos_dependentes", "Povos dependentes", "%.1f"], ["estoque_por_pessoa", "Estoque por pessoa", "%.1f"],
		["guerras_santas", "Guerras santas", "%.1f"], ["ataques", "Ataques", "%.1f"], ["secularizacoes", "Secularizações", "%.1f"],
		["profetas", "Profetas", "%.1f"], ["preces_atendidas", "Preces atendidas", "%.1f"],
		["preces_sem_resposta", "Preces sem resposta", "%.1f"], ["povos_crentes", "Povos que creem", "%.1f"],
		["povos_ceticos", "Povos céticos", "%.1f"], ["fins_do_mundo", "Fins do mundo", "%.1f"], ["gestos", "Gestos do deus", "%.0f"],
		["dependencias", "Povos que ficaram dependentes", "%.1f"], ["exigencias", "Povos que passaram a exigir", "%.1f"],
		["desamparos", "Desamparos", "%.1f"], ["silencios", "Silêncios sentidos", "%.1f"], ["renascimentos", "Renascimentos da fé", "%.1f"],
		["nomes_mudados", "Vezes que o deus mudou de nome", "%.1f"], ["mortos_pelo_deus", "Mortos pelo deus", "%.1f"]]
	for c in campos:
		var cel: PackedStringArray = []
		for e in ESTILOS:
			cel.append(c[2] % medias[e].get(c[0], 0.0))
		l.append("| %s | %s |" % [c[1], " | ".join(cel)])
	l.append_array(["", "Por semente:", "", "| Estilo | Semente | Pop. | Fé | Nomes do deus (agora) | Costumes | Dependentes | Santas | Secul. |",
		"|---|---|---|---|---|---|---|---|---|"])
	for li in linhas:
		var r: Dictionary = li[2]
		l.append("| %s | %d | %d | %.2f | %d (%s) | %d (%s) | %d | %d | %d |" % [li[0], li[1], r["populacao"], r["fe_media"],
			r["nomes_do_deus"], r["nomes_agora"], r["costumes"], r["tipos_costume"], r["povos_dependentes"], r["guerras_santas"],
			r["secularizacoes"]])
	return "\n".join(l)

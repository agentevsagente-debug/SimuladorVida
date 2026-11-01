extends SceneTree
## Os 11 poderes vistos como jogador. Para cada poder, em 3 intensidades (0,2, 0,6 e 0,95) e em
## 3 mundos de estágios diferentes (o primeiro povo no ano 5; a agricultura no ano 60; um mundo
## de estágios altos no ano 165), um gesto sobre o povo maior, e o que mudou um dia depois:
## mortos, abrigos, estoque, comida e água da zona, a fé média, o nome do deus, crenças e
## costumes novos, os eventos do gesto, a linha da crônica e o pensamento de quem estava perto.
## E a repetição: o mesmo poder 10 vezes, um gesto a cada 2 dias, no mundo da agricultura.
## Grava uma tabela por poder em ferramentas_sim/poderes/<poder>.md.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/poderes.gd [-- <poder> ...]

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const PASTA := "res://ferramentas_sim/poderes"
const BASES := [[1, 5, "estágio 1, ano 5"], [1, 60, "agricultura, ano 60"], [3, 165, "estágios altos, ano 165"]]
const INTENSIDADES := [0.2, 0.6, 0.95]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/poderes")
	var caminhos: Array = []
	for b in BASES:
		var c := "user://poderes/base-%d-%d.txt" % [b[0], b[1]]
		if not FileAccess.file_exists(c):
			var m := Mundo.new(b[0], [], Mundo.HORA_INICIAL, true)
			while m.ano() < b[1]:
				m.avancar_dias(Mundo.DIAS_ANO)
			while m.hora() != 10:
				m.avancar_hora()
			Persistencia.salvar(m, c)
		caminhos.append(c)
	var poderes: Array = args if not args.is_empty() else Mundo.PODERES
	for poder in poderes:
		var linhas: PackedStringArray = ["# O poder `%s`" % poder, "",
			"Um gesto sobre o povo maior (`x_povo`; no raio, no sonho e na cura, sobre a pessoa mais perto), e o que mudou um dia depois.", "",
			"| Mundo | Intensidade | Grau | Mortos | Abrigos | Estoque | Comida da zona | Água | Fé média | Nome do deus | Novos (crença, costume, lugar) | Eventos | Crônica |",
			"|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
		var pensamentos: PackedStringArray = []
		for bi in BASES.size():
			for inten in INTENSIDADES:
				var r := _gesto(caminhos[bi], poder, inten)
				linhas.append("| %s | %.2f | %s |" % [BASES[bi][2], inten, r["linha"]])
				if not r["pensa"].is_empty():
					pensamentos.append("- %s, %.2f: %s" % [BASES[bi][2], inten, r["pensa"]])
		linhas.append("")
		linhas.append("**O que pensam no dia seguinte** (alguém do povo, ao meio-dia):")
		linhas.append_array(pensamentos)
		linhas.append("")
		linhas.append("**10 vezes seguidas** (um gesto a cada 2 dias, intensidade 0,6, no mundo da agricultura):")
		linhas.append("")
		linhas.append(_repetir(caminhos[1], poder))
		var f := FileAccess.open("%s/%s.md" % [PASTA, poder], FileAccess.WRITE)
		f.store_string("\n".join(linhas) + "\n")
		f.close()
		print("feito: ", poder)
	quit()


func _maior(m):
	var g = null
	for o in m.grupos_vivos():
		if g == null or o.membros.size() > g.membros.size():
			g = o
	return g


func _fe(m, g) -> float:
	var s := 0.0
	for id in g.membros:
		s += m.pessoas[id].fe
	return s / maxf(1.0, g.membros.size())


func _alvo_x(m, g, poder: String) -> float:
	if poder in ["raio", "sonho", "cura"]:
		# A pessoa: na cura, um doente, se houver; senão, quem estiver mais perto do fogo.
		for id in g.membros:
			if poder == "cura" and m.pessoas[id].doente > 0:
				return m.posicao_de(id)
		return m.posicao_de(g.membros[0])
	return m._fogo_do_povo(g)


func _gesto(caminho: String, poder: String, inten: float) -> Dictionary:
	var m = Persistencia.carregar(caminho)
	var g = _maior(m)
	var z = m.zonas[g.zona]
	var antes := {"pop": m.populacao(), "abrigos": g.abrigos, "estoque": g.estoque, "comida": z.comida, "agua": z.agua,
		"fe": _fe(m, g), "deus": g.nome_deus, "crencas": g.crencas.size(), "costumes": g.costumes.size()}
	var ev0: int = m.eventos.size()
	var lugares0: int = z.nomes.size()
	var r: Dictionary = m.usar_poder(poder, _alvo_x(m, g, poder), inten)
	var cron: String = m.cronica_em_curso()
	var ultima := ""
	for l in cron.split("\n"):
		if l.begins_with("Dia "):
			ultima = l
	m.avancar_dias(1)
	while m.hora() != 12:
		m.avancar_hora()
	var tipos: Array = []
	for i in range(ev0, m.eventos.size()):
		var e = m.evento(i)
		if e != null and not e.tipo in ["nascimento", "casamento"]:
			tipos.append(e.tipo)
	var novos: Array = []
	if g.crencas.size() > antes["crencas"]:
		novos.append("crença")
	if g.costumes.size() > antes["costumes"]:
		novos.append("costume")
	if z.nomes.size() > lugares0:
		novos.append("lugar")
	var pensa := ""
	for id in g.membros:
		var d: Dictionary = m.dica(id)
		if not d.get("pensamento", "").is_empty() and m.pessoas[id].vivo:
			pensa = "\"%s\" (%s)" % [d["pensamento"], d["humor"]]
			break
	var linha := "%s | %d | %d → %d | %.0f → %.0f | %.0f → %.0f | %.2f → %.2f | %+.2f | %s | %s | %s | %s" % [
		r.get("grau", r.get("motivo", "?")), antes["pop"] - m.populacao(), antes["abrigos"], g.abrigos, antes["estoque"], g.estoque,
		antes["comida"], z.comida, antes["agua"], z.agua, _fe(m, g) - antes["fe"],
		("«%s» → «%s»" % [antes["deus"], g.nome_deus]) if g.nome_deus != antes["deus"] else (g.nome_deus if not g.nome_deus.is_empty() else "—"),
		", ".join(PackedStringArray(novos)) if not novos.is_empty() else "—",
		", ".join(PackedStringArray(tipos.slice(0, 6))), ultima.replace("|", "/").substr(0, 160)]
	return {"linha": linha, "pensa": pensa}


func _repetir(caminho: String, poder: String) -> String:
	var m = Persistencia.carregar(caminho)
	var g = _maior(m)
	var antes := {"pop": m.populacao(), "fe": _fe(m, g), "deus": g.nome_deus, "crencas": g.crencas.duplicate(),
		"costumes": g.costumes.map(func(c): return c["tipo"])}
	var ev0: int = m.eventos.size()
	var graus: Array = []
	for k in 10:
		var r: Dictionary = m.usar_poder(poder, _alvo_x(m, g, poder), 0.6)
		graus.append(r.get("grau", "-"))
		m.avancar_dias(2)
	var conta := {}
	for i in range(ev0, m.eventos.size()):
		var e = m.evento(i)
		if e != null and not e.tipo in ["nascimento", "casamento"]:
			conta[e.tipo] = conta.get(e.tipo, 0) + 1
	var crencas_novas: Array = g.crencas.filter(func(c): return not antes["crencas"].has(c))
	var costumes_novos: Array = g.costumes.map(func(c): return c["tipo"]).filter(func(c): return not antes["costumes"].has(c))
	var pensa := ""
	for id in g.membros:
		var d: Dictionary = m.dica(id)
		if not d.get("pensamento", "").is_empty():
			pensa = "\"%s\" (%s)" % [d["pensamento"], d["humor"]]
			break
	return "- graus: %s\n- população: %d → %d; fé média: %+.2f; deus: %s\n- crenças novas: %s; costumes novos: %s; dependência: %s\n- eventos em 20 dias: %s\n- pensa: %s" % [
		", ".join(PackedStringArray(graus)), antes["pop"], m.populacao(), _fe(m, g) - antes["fe"],
		("«%s» → «%s»" % [antes["deus"], g.nome_deus]) if g.nome_deus != antes["deus"] else g.nome_deus,
		str(crencas_novas), str(costumes_novos), "sim" if g.dependente else "não", str(conta), pensa]

extends SceneTree
## O uso real: 4 semanas de um jogador típico. De segunda a sexta, o jogo fica aberto em 1x por
## 8 h (256 passos, uns 11 dias de jogo); de segunda a quinta, a noite fora são 16 h de ausência;
## de sexta à noite a segunda de manhã, 64 h (o teto: um ano). O jogador faz 3 gestos por dia,
## respondendo às preces abertas com o poder que as atende; sem prece aberta, um sinal bom.
## Para cada dia real, o que o jogador viu: os chamados e as notas, as preces, a mudança de
## estágio, nascimentos e mortes com nome, e o resumo da ausência que abriu o dia. Para o fim de
## semana, se o mundo voltou reconhecível (os mesmos povos, líderes, deus).
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/uso_real.gd -- <semente>

const Mundo = preload("res://nucleo/mundo.gd")
const PASTA := "res://ferramentas_sim/uso_real"
const SESSAO := 256          # 8 h em 1x (112,5 s por passo)
const NOITE := 16 * 3600.0
const FIM_DE_SEMANA := 64 * 3600.0
const DIAS := ["seg", "ter", "qua", "qui", "sex"]


func _initialize() -> void:
	var semente := int(OS.get_cmdline_user_args()[0])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	var linhas: PackedStringArray = ["# Uso real: semente %d, 4 semanas" % semente, "",
		"| Semana | Dia | Ano (dia) | Chamados | Notas | Do mundo (sem os gestos) | Preces | Gestos | Estágio | Nascimentos | Mortes com nome | O resumo da ausência que abriu o dia (o começo) |",
		"|---|---|---|---|---|---|---|---|---|---|---|---|"]
	var fins: PackedStringArray = ["", "**Os fins de semana** (antes → depois de 64 h fora):", ""]
	var relato := "(o jogo começa)"
	var vazios := 0
	var vazios_mundo := 0
	var estagio_fora := ""
	var gestos_total := 0
	var inicio := _retrato(m)
	for semana in 4:
		for d in 5:
			var ev0: int = m.eventos.size()
			var gestos := 0
			for k in SESSAO:
				if k in [60, 140, 220]:
					gestos += _gesto(m, k)
				m.avancar_hora()
			gestos_total += gestos
			var c := _contar(m, ev0)
			if c["chamados"] + c["notas"] == 0:
				vazios += 1
			if c["mundo"] == 0:
				vazios_mundo += 1
			var est_txt: String = c["estagio"] + ((" (fora: %s)" % estagio_fora) if not estagio_fora.is_empty() else "")
			linhas.append("| %d | %s | %d (%d) | %d | %d | %d | %d | %d | %s | %d | %d | %s |" % [semana + 1, DIAS[d], m.ano(), m.dia_do_ano() + 1,
				c["chamados"], c["notas"], c["mundo"], c["preces"], gestos, est_txt, c["nasc"], c["mortes"], _primeira_frase(relato)])
			# A ausência: a noite, ou o fim de semana.
			var ev_fora: int = m.eventos.size()
			if d < 4:
				relato = m.avancar_ausencia(NOITE)["relato"]
			else:
				var antes := _retrato(m)
				var r := m.avancar_ausencia(FIM_DE_SEMANA)
				relato = r["relato"]
				var depois := _retrato(m)
				fins.append("- semana %d: %s → %s. %s" % [semana + 1, antes["texto"], depois["texto"], _reconhecivel(antes, depois)])
			estagio_fora = _contar(m, ev_fora)["estagio"]
	var fim := _retrato(m)
	linhas.append_array(fins)
	linhas.append("")
	linhas.append("**Em 4 semanas:** %s → %s. Dias reais sem nenhum chamado nem nota: %d de 20; sem nada notável do mundo (fora os gestos do jogador e as reações a eles): %d de 20. Gestos: %d." % [
		inicio["texto"], fim["texto"], vazios, vazios_mundo, gestos_total])
	var f := FileAccess.open("%s/semente-%d.md" % [PASTA, semente], FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	print("semente %d: %d dias vazios, %d sem nada do mundo; %s → %s" % [semente, vazios, vazios_mundo, inicio["texto"], fim["texto"]])
	quit()


## Um gesto: a prece aberta mais antiga, com o poder que a atende; sem prece, um sinal bom.
func _gesto(m, k: int) -> int:
	var preces: Array = m.preces_abertas()
	for pr in preces:
		var atendem: Array = pr["atendem"]
		if atendem.is_empty():
			continue
		var poder: String = atendem[0]
		var x: float = pr["x_povo"]
		var inten := 0.7
		if poder == "cura":
			x = m.posicao_de(pr["alvo"]) if pr["alvo"] >= 0 else x
		elif poder == "fogo":
			inten = 0.2
		elif pr["necessidade"] == "guerra":
			var ini = m.grupo(pr["inimigo"])
			if ini == null:
				continue
			x = m._fogo_do_povo(ini)
		if x < 0.0:
			continue
		m.usar_poder(poder, x, inten)
		return 1
	var vivos: Array = m.grupos_vivos()
	if vivos.is_empty():
		return 0
	var g = vivos[(m.dia_abs() + k) % vivos.size()]
	m.usar_poder(["chuva", "fartura", "erguer"][(m.dia_abs() / 3 + k) % 3], m._fogo_do_povo(g), 0.4)
	return 1


func _contar(m, ev0: int) -> Dictionary:
	var c := {"chamados": 0, "notas": 0, "mundo": 0, "preces": 0, "estagio": "", "nasc": 0, "mortes": 0}
	var do_deus := {}   # os gestos e o que vem deles (resposta, origem)
	for i in range(ev0, m.eventos.size()):
		var e = m.evento(i)
		if e == null:
			continue
		var camada: String = m.camada(e)
		if camada == "chamado":
			c["chamados"] += 1
		elif camada == "nota":
			c["notas"] += 1
		if e.causa == "divina" or do_deus.has(e.dados.get("resposta", -2)) or do_deus.has(e.dados.get("origem", -2)):
			do_deus[e.id] = true
		elif camada != "ambiente" and not e.tipo in ["prece_atendida", "deus_renomeado", "nova_crenca", "costume", "lugar_nomeado", "dependencia"]:
			c["mundo"] += 1
		match e.tipo:
			"prece":
				c["preces"] += 1
			"agricultura":
				c["estagio"] = "2"
			"estagio":
				c["estagio"] = str(e.dados.get("estagio", ""))
			"nascimento", "gemeos":
				c["nasc"] += 1
			"morte":
				if camada != "ambiente":
					c["mortes"] += 1
	return c


func _retrato(m) -> Dictionary:
	var povos := {}
	for g in m.grupos_vivos():
		povos[g.nome] = {"lider": g.lider, "deus": g.nome_deus, "estagio": g.estagio, "n": g.membros.size()}
	var partes: Array = []
	for n in povos:
		partes.append("%s %d (est. %d%s)" % [n, povos[n]["n"], povos[n]["estagio"], ", «%s»" % povos[n]["deus"] if not povos[n]["deus"].is_empty() else ""])
	return {"povos": povos, "texto": "ano %d: %s" % [m.ano(), ", ".join(PackedStringArray(partes)) if not partes.is_empty() else "ninguém"]}


func _reconhecivel(a: Dictionary, b: Dictionary) -> String:
	var mesmos := 0
	var lideres := 0
	var deuses := 0
	for n in a["povos"]:
		if b["povos"].has(n):
			mesmos += 1
			if b["povos"][n]["lider"] == a["povos"][n]["lider"]:
				lideres += 1
			if b["povos"][n]["deus"] == a["povos"][n]["deus"]:
				deuses += 1
	return "Povos que continuam: %d de %d; com o mesmo líder: %d; com o mesmo nome do deus: %d; povos novos: %d." % [
		mesmos, a["povos"].size(), lideres, deuses, b["povos"].size() - mesmos]


func _primeira_frase(t: String) -> String:
	var s := t.replace("\n", " ").replace("|", "/").replace("### ", "").strip_edges()
	return s.substr(0, 110) + ("…" if s.length() > 110 else "")

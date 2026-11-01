extends SceneTree
## As preces e os chamados, vistos como jogador: roda mundos por 50 anos em três modos (o deus
## calado; o deus que atende cada prece com o poder que faz sentido, dois dias depois; e o deus
## que faz o contrário) e grava, em ferramentas_sim/preces/, por década: as preces (texto,
## necessidade, desfecho), os chamados por tipo, e a reação a cada prece atendida, sem resposta
## ou contrariada: se aparece na crônica do ano, na memória de quem rezou e no pensamento dele
## no dia seguinte (a dica, ao meio-dia).
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/preces.gd [-- <semente> <modo>]
##   modo: calado, atende ou contraria (sem argumentos: sementes 1 a 3 nos três modos)

const Mundo = preload("res://nucleo/mundo.gd")
const PASTA := "res://ferramentas_sim/preces"
const ANOS := 50

## O poder que atende cada necessidade (o frio não tem), e o que a contraria. O gesto vai no
## povo que reza (`x_povo`); o da guerra, no povo inimigo.
const ATENDE := {"seca": "chuva", "fome": "fartura", "doenca": "cura", "guerra": "terremoto", "banal": "sonho"}
const CONTRARIA := {"seca": "seca", "fome": "seca", "doenca": "raio", "frio": "diluvio", "guerra": "terremoto", "banal": "seca"}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	if args.size() >= 2:
		_rodar(int(args[0]), args[1])
	else:
		for modo in ["calado", "atende", "contraria"]:
			for semente in [1, 2, 3]:
				_rodar(semente, modo)
	quit()


func _rodar(semente: int, modo: String) -> void:
	var m := Mundo.new(semente)
	while m.hora() != 12:
		m.avancar_hora()
	var visto := 0
	var por_decada := {}      # década -> {"preces": [], "chamados": {tipo: n}, "reacoes": []}
	var a_responder := {}     # id do evento da prece -> dia em que o deus responde
	var a_ver: Array = []     # [dia, autor, evento de desfecho, tipo]: olhar a dica no dia seguinte
	var gestos := 0
	while m.ano() <= ANOS and not m.fim_do_mundo:
		m.avancar_dias(1)
		var dec: int = (m.ano() - 1) / 10
		if not por_decada.has(dec):
			por_decada[dec] = {"preces": [], "chamados": {}, "reacoes": [], "abertas_max": 0}
		var d: Dictionary = por_decada[dec]
		for i in range(visto, m.eventos.size()):
			var e = m.evento(i)
			if e == null:
				continue
			if m.camada(e) == "chamado":
				d["chamados"][e.tipo] = d["chamados"].get(e.tipo, 0) + 1
			match e.tipo:
				"prece":
					var autor = m.pessoa(e.participantes[0])
					d["preces"].append("ano %d, %s: %s (%s%s)" % [e.ano, m.grupo(e.grupo).nome, m._cronista.texto_prece(e),
						e.dados["necessidade"], ", por %s" % m.pessoa(e.dados["alvo"]).nome if e.dados["alvo"] != -1 else ""])
					if modo != "calado":
						a_responder[e.id] = m.dia_abs() + 2
				"prece_atendida", "prece_sem_resposta":
					a_ver.append([m.dia_abs() + 1, e.participantes[0], e.id, e.tipo + (" (acaso)" if e.dados.get("falso_milagre", false) else "")])
		visto = m.eventos.size()
		d["abertas_max"] = maxi(d["abertas_max"], m.preces_abertas().size())
		# O deus responde.
		for pr in m.preces_abertas():
			var quando: int = a_responder.get(pr["evento"], -1)
			if quando < 0 or m.dia_abs() < quando:
				continue
			a_responder.erase(pr["evento"])
			var nec: String = pr["necessidade"]
			var poder: String = (ATENDE if modo == "atende" else CONTRARIA).get(nec, "")
			if poder.is_empty():
				continue
			var x: float = pr["x_povo"]   # o gesto vai no povo (quem reza pode estar trabalhando longe)
			if poder == "cura" and pr["alvo"] != -1:
				x = m.posicao_de(pr["alvo"])
			if nec == "guerra" and modo == "atende":
				# O terremoto vai no inimigo.
				var ini = m.grupo(pr["inimigo"])
				if ini == null:
					continue
				x = m._fogo_do_povo(ini)
			var r: Dictionary = m.usar_poder(poder, x, 0.8)
			gestos += 1
			var ev = m.evento(r.get("evento", -1)) if r.get("evento", -1) >= 0 else null
			d["reacoes"].append("ano %d: o deus respondeu a «%s» (%s) com %s → %s" % [m.ano(), pr["texto"], nec, poder,
				m._cronista.texto_curto(ev) if ev != null else str(r.get("motivo", "nada"))])
			if modo == "contraria":
				a_ver.append([m.dia_abs() + 1, pr["autor"], r.get("evento", -1), "contrariada com " + poder])
		# A reação, um dia depois: crônica, memória e dica de quem rezou.
		var resto: Array = []
		for v in a_ver:
			if m.dia_abs() < v[0]:
				resto.append(v)
				continue
			var p = m.pessoa(v[1])
			if p == null or not p.vivo:
				continue
			var lembra: bool = v[2] >= 0 and p.memoria.has(v[2])
			var dc: Dictionary = m.dica(v[1])
			d["reacoes"].append("ano %d, %s (%s): na memória: %s; humor \"%s\"; pensa \"%s\"" % [m.ano(), p.nome, v[3],
				"sim" if lembra else "não", dc.get("humor", ""), dc.get("pensamento", "")])
		a_ver = resto
	# A crônica dos 50 anos, para procurar as reações.
	var cron: String = m.cronica(1, -1, false)
	var linhas: PackedStringArray = ["# Preces e chamados: semente %d, deus %s, %d anos" % [semente, modo, ANOS], "",
		"Gestos do deus: %d. Preces na crônica: %d menções a \"rez\" ou \"pediu\"." % [gestos, cron.count("rez") + cron.count("pediu")], ""]
	for dec in por_decada:
		var d: Dictionary = por_decada[dec]
		linhas.append("## Anos %d a %d" % [dec * 10 + 1, dec * 10 + 10])
		linhas.append("")
		linhas.append("Chamados: %s. Preces abertas ao mesmo tempo, no máximo: %d." % [str(d["chamados"]), d["abertas_max"]])
		linhas.append("")
		linhas.append("**Preces (%d):**" % d["preces"].size())
		for t in d["preces"]:
			linhas.append("- " + t)
		linhas.append("")
		if not d["reacoes"].is_empty():
			linhas.append("**Respostas e reações:**")
			for t in d["reacoes"]:
				linhas.append("- " + t)
			linhas.append("")
	var f := FileAccess.open("%s/%s-semente-%d.md" % [PASTA, modo, semente], FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()
	var cf := FileAccess.open("%s/%s-semente-%d-cronica.md" % [PASTA, modo, semente], FileAccess.WRITE)
	cf.store_string(cron)
	cf.close()
	print("semente %d, %s: %d gestos; %d anos" % [semente, modo, gestos, m.ano() - 1])

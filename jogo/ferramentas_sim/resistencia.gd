extends SceneTree
## Teste de resistência: um mundo por muitos anos, num processo só, medindo o que pesa com o
## tempo. A cada 50 anos: tamanho do mundo salvo, tempo de salvar e de carregar (e se o mundo
## carregado dá a mesma crônica), memória, objetos vivos e o tempo do avanço máximo de
## ausência (1 ano) sobre o mundo carregado. Também o pior dia (24 passos) e o pior ano.
## Estilos: "nenhum" (sem intervenção) ou "caprichoso" (como em estilos.gd: um poder qualquer,
## em qualquer lugar e força, a cada 25 dias em média, a partir do ano 5).
## Quando o mundo fica vazio, um jogador cria um povo novo 10 anos depois, nas ruínas.
## Grava as medidas em ferramentas_sim/resistencia/medidas/<estilo>-semente-N.txt e a crônica
## dos últimos 200 anos em ferramentas_sim/resistencia/cronicas/.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/resistencia.gd -- <semente> <estilo> [anos]

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const PASTA := "res://ferramentas_sim/resistencia"
const A_CADA := 50

var deus := RandomNumberGenerator.new()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var semente := int(args[0])
	var estilo: String = args[1]
	var anos := int(args[2]) if args.size() > 2 else 1000
	for sub in ["medidas", "cronicas"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA + "/" + sub))
	var caminho := "user://resistencia/%s-%d.txt" % [estilo, semente]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://resistencia"))
	deus.seed = semente * 7919 + 3
	var m := Mundo.new(semente)
	var linhas: PackedStringArray = ["# Resistência: semente %d, estilo %s, %d anos" % [semente, estilo, anos], "",
		"| Ano | Pessoas | Povos | Eventos | Arquivo (KB) | Salvar (ms) | Carregar (ms) | Igual depois de carregar | Ausência de 1 ano (ms) | Memória (MB) | Pico (MB) | Objetos | Pior dia (ms) | Pior ano (s) |",
		"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
	var gestos := 0
	var pior_dia := 0.0
	var pior_ano := 0.0
	var pior_dia_total := 0.0
	var pior_ano_total := 0.0
	var ano_pior_dia := 0
	var fins: Array = []
	var povos_novos: Array = []
	var t_total := Time.get_ticks_usec()
	for a in anos:
		var ta := Time.get_ticks_usec()
		for d in Mundo.DIAS_ANO:
			var td := Time.get_ticks_usec()
			m.avancar_dias(1)
			var dt := (Time.get_ticks_usec() - td) / 1000.0
			if dt > pior_dia:
				pior_dia = dt
			if dt > pior_dia_total:
				pior_dia_total = dt
				ano_pior_dia = m.ano()
			if estilo == "caprichoso" and not m.fim_do_mundo and m.ano() >= 5 and deus.randf() < 0.04:
				var poder: String = m.PODERES[deus.randi_range(0, m.PODERES.size() - 1)]
				m.usar_poder(poder, deus.randf_range(130.0, 470.0), deus.randf_range(0.3, 0.95))
				gestos += 1
		if m.fim_do_mundo and fins.find(m.livros[-1]["ano_fim"]) < 0:
			fins.append(m.livros[-1]["ano_fim"])
		if m.fim_do_mundo and m.ano() - m.livros[-1]["ano_fim"] >= 10:
			m.criar_povo(260.0)
			povos_novos.append(m.ano())
		var dano := (Time.get_ticks_usec() - ta) / 1e6
		pior_ano = maxf(pior_ano, dano)
		pior_ano_total = maxf(pior_ano_total, dano)
		if m.ano() % A_CADA == 0 or a == anos - 1:
			linhas.append(_medir(m, caminho, pior_dia, pior_ano))
			print(linhas[-1])
			pior_dia = 0.0
			pior_ano = 0.0
	var conta := {}
	for e in m.eventos:
		conta[e.tipo] = conta.get(e.tipo, 0) + 1
	linhas.append("")
	linhas.append("Tempo total: %.1f s. Pior dia: %.1f ms (ano %d). Pior ano: %.2f s. Gestos do deus: %d." % [
		(Time.get_ticks_usec() - t_total) / 1e6, pior_dia_total, ano_pior_dia, pior_ano_total, gestos])
	linhas.append("Fins do mundo: %s. Povos novos criados pelo jogador: %s. Eras: %d. Livros na estante do mundo: %d." % [
		str(fins), str(povos_novos), m.era, m.livros.size()])
	linhas.append("Eventos por tipo (os 15 mais comuns): " + _top(conta, 15))
	_gravar("%s/medidas/%s-semente-%d.txt" % [PASTA, estilo, semente], "\n".join(linhas) + "\n")
	var ini := maxi(1, m.ultimo_ano_na_cronica() - 199)
	_gravar("%s/cronicas/%s-semente-%d.md" % [PASTA, estilo, semente], m.cronica(ini, -1, false))
	print("FIM semente %d %s" % [semente, estilo])
	quit()


func _medir(m, caminho: String, pior_dia: float, pior_ano: float) -> String:
	var t0 := Time.get_ticks_usec()
	var ok := Persistencia.salvar(m, caminho)
	var t_salvar := (Time.get_ticks_usec() - t0) / 1000.0
	var tam := FileAccess.get_file_as_bytes(caminho).size() / 1024.0
	t0 = Time.get_ticks_usec()
	var c = Persistencia.carregar(caminho)
	var t_carregar := (Time.get_ticks_usec() - t0) / 1000.0
	var igual := "não carregou"
	var t_aus := -1.0
	if c != null:
		var ini := maxi(1, m.ultimo_ano_na_cronica() - 20)
		igual = "sim" if c.cronica(ini) == m.cronica(ini) and c.rng.state == m.rng.state and c.passo == m.passo else "NÃO"
		t0 = Time.get_ticks_usec()
		c.avancar_ausencia(1e9)
		t_aus = (Time.get_ticks_usec() - t0) / 1000.0
		c = null
	if not ok:
		igual = "falhou ao salvar"
	return "| %d | %d | %d | %d | %.0f | %.0f | %.0f | %s | %.0f | %.1f | %.1f | %d | %.1f | %.2f |" % [m.ano(), m.populacao(),
		m.grupos_vivos().size(), m.eventos.size(), tam, t_salvar, t_carregar, igual, t_aus,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, OS.get_static_memory_peak_usage() / 1048576.0,
		Performance.get_monitor(Performance.OBJECT_COUNT), pior_dia, pior_ano]


func _top(conta: Dictionary, n: int) -> String:
	var ks: Array = conta.keys()
	ks.sort_custom(func(a, b): return conta[a] > conta[b])
	var r: PackedStringArray = []
	for k in ks.slice(0, n):
		r.append("%s %d" % [k, conta[k]])
	return ", ".join(r)


func _gravar(res: String, texto: String) -> void:
	var f := FileAccess.open(res, FileAccess.WRITE)
	f.store_string(texto)
	f.close()

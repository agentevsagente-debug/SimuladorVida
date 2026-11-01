extends SceneTree
## Sondagem de longo prazo: o mundo continua interessante por centenas de anos?
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/sondagem_longa.gd -- <anos> <cenario|-> <rotulo> <semente> [semente...]
## Grava as crônicas em ferramentas_sim/sondagem/<rotulo>-semente-N.md e imprime as métricas.
##
## Métricas por mundo:
## - população e povos vivos a cada 50 anos; estágio máximo alcançado (e em que ano);
## - extinções de povos, fins do mundo e eras;
## - "marcos": anos com algum evento de importância 7 ou mais que entrou na crônica.
##   Lacuna média e maior lacuna entre marcos, em anos;
## - "viradas": mudanças de rumo (crença, separação, guerra com nome, estágio, regressão,
##   conquista, cisma, fim de povo, deus rebatizado, silêncio, dependência...). Lacuna máxima;
## - anos quietos na crônica: proporção e maior sequência;
## - repetição: em cada década, a parte das frases da crônica que é do tipo mais frequente.

const Mundo = preload("res://nucleo/mundo.gd")
const Cenario = preload("res://nucleo/cenario.gd")
const VIRADAS := ["crenca", "separacao", "guerra_inicio", "estagio", "regressao", "conquista",
	"extincao_grupo", "fim_do_mundo", "deus_renomeado", "silencio", "dependencia", "desamparo",
	"descoberta", "agricultura", "conhecimento_perdido", "expedicao", "reforma", "cultura", "diluvio",
	"mito_ruinas", "os_ultimos"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var anos := int(args[0])
	var cenario: String = args[1]
	var rotulo: String = args[2]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ferramentas_sim/sondagem"))
	var totais := {}
	var n := 0
	for i in range(3, args.size()):
		var semente := int(args[i])
		var cmds: Array = [] if cenario == "-" else Cenario.ler_arquivo(cenario)
		var m := Mundo.new(semente, cmds)
		var linha := "semente %3d:" % semente
		var t0 := Time.get_ticks_usec()
		var max_ano_dt := 0.0
		var est_max := 1
		var ano_est_max := 1
		for a in anos:
			var ta := Time.get_ticks_usec()
			m.avancar_dias(Mundo.DIAS_ANO)
			# Um jogador que encontra o mundo vazio cria um povo novo depois de 10 anos.
			if m.fim_do_mundo and m.ano() - m.livros[-1]["ano_fim"] >= 10:
				m.criar_povo(260.0)
			max_ano_dt = maxf(max_ano_dt, (Time.get_ticks_usec() - ta) / 1e6)
			for g in m.grupos_vivos():
				if g.estagio > est_max:
					est_max = g.estagio
					ano_est_max = m.ano()
			if (a + 1) % 50 == 0:
				linha += " %d/%dp" % [m.populacao(), m.grupos_vivos().size()]
		var dt := (Time.get_ticks_usec() - t0) / 1e6
		var texto := m.cronica_completa("Crônica de %d anos da semente %d" % [anos, semente],
			"%s." % ("sem intervenção do deus" if cenario == "-" else "cenário " + cenario.get_file()))
		var f := FileAccess.open("res://ferramentas_sim/sondagem/%s-semente-%d.md" % [rotulo, semente], FileAccess.WRITE)
		f.store_string(texto + "\n")
		f.close()
		var met := _metricas(m, anos)
		met["estagio_max"] = est_max
		met["ano_estagio_max"] = ano_est_max
		met["s_por_ano_max"] = max_ano_dt
		met["s_total"] = dt
		print(linha)
		print("   estágio máx %d (ano %d) | povos extintos %d | fins do mundo %d | eras %d | marcos: lacuna média %.1f, máx %d | viradas: lacuna máx %d | quietos %d%%, maior seq %d | repetição %.0f%% | %.2f s (ano mais lento %.3f s)" % [
			est_max, ano_est_max, met["extintos"], met["fins"], m.era, met["lacuna_media"], met["lacuna_max"],
			met["virada_max"], met["quietos"] * 100, met["quieto_seq"], met["repeticao"] * 100, dt, max_ano_dt])
		print("   fomes/década %.1f | guerras %d | profetas %d | secularizações %d | renascimentos %d | pestes %d | mudanças de poder %d | regressões %d" % [
			met["fomes_decada"], met["guerras"], met["profetas"], met["secularizacoes"], met["renascimentos"], met["pestes"],
			met["mudancas_poder"], met["regressoes"]])
		for k in met:
			totais[k] = totais.get(k, 0.0) + float(met[k])
		n += 1
	print("MÉDIA (%d mundos): " % n, _fmt(totais, n))
	quit()


func _fmt(t: Dictionary, n: int) -> String:
	var r := ""
	for k in ["fomes_decada", "guerras", "profetas", "secularizacoes", "mudancas_poder", "estagio_max", "extintos", "fins", "lacuna_media", "lacuna_max", "virada_max", "quietos", "quieto_seq", "repeticao", "s_por_ano_max"]:
		r += "%s=%.2f " % [k, t.get(k, 0.0) / n]
	return r


func _metricas(m, anos: int) -> Dictionary:
	var cr = m._cronista
	var marcos: Array = []
	var viradas: Array = [0]
	var extintos := 0
	var fins := 0
	for e in m.eventos:
		if e.tipo == "extincao_grupo" or e.tipo == "conquista" or e.tipo == "fusao":
			extintos += 1
		if e.tipo == "fim_do_mundo":
			fins += 1
		if cr._usados.has(e.id) and e.importancia >= 7 and (marcos.is_empty() or marcos[-1] != e.ano):
			marcos.append(e.ano)
		if VIRADAS.has(e.tipo) and cr._usados.has(e.id) and viradas[-1] != e.ano:
			viradas.append(e.ano)
	viradas.append(anos)
	var lac := 0.0
	var lac_max := 0
	var anterior := 0
	for a in marcos + [anos]:
		lac_max = maxi(lac_max, a - anterior)
		anterior = a
	lac = float(anos) / maxf(1.0, marcos.size())
	var vir_max := 0
	for i in range(1, viradas.size()):
		vir_max = maxi(vir_max, viradas[i] - viradas[i - 1])
	var quietos := 0
	var seq := 0
	var seq_max := 0
	for a in range(1, anos + 1):
		if cr.anos_escritos.get(a, "").is_empty():
			quietos += 1
			seq += 1
			seq_max = maxi(seq_max, seq)
		else:
			seq = 0
	# Repetição: por década, a fatia do tipo mais frequente entre os eventos contados.
	var rep_total := 0.0
	var decadas := 0
	for d in range(0, anos, 10):
		var cont := {}
		var tot := 0
		for e in m.eventos:
			if e.ano > d and e.ano <= d + 10 and cr._usados.has(e.id):
				cont[e.tipo] = cont.get(e.tipo, 0) + 1
				tot += 1
		if tot >= 5:
			var mx := 0
			for k in cont:
				mx = maxi(mx, cont[k])
			rep_total += float(mx) / tot
			decadas += 1
	var conta := {}
	for e in m.eventos:
		if e.tipo in ["fome_fim", "profeta", "secularizacao", "renascimento", "peste", "estagio", "regressao", "guerra_inicio"]:
			conta[e.tipo] = conta.get(e.tipo, 0) + 1
		if e.tipo == "cultura" and e.dados.get("dimensao", "") == "poder":
			conta["poder"] = conta.get("poder", 0) + 1
	return {"fomes_decada": conta.get("fome_fim", 0) * 10.0 / anos, "profetas": conta.get("profeta", 0),
		"secularizacoes": conta.get("secularizacao", 0), "renascimentos": conta.get("renascimento", 0),
		"pestes": conta.get("peste", 0), "mudancas_poder": conta.get("poder", 0), "guerras": conta.get("guerra_inicio", 0),
		"regressoes": conta.get("regressao", 0), "extintos": extintos, "fins": fins, "lacuna_media": lac, "lacuna_max": lac_max,
		"virada_max": vir_max, "quietos": float(quietos) / anos, "quieto_seq": seq_max,
		"repeticao": rep_total / maxi(1, decadas)}

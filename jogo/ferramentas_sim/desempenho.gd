extends RefCounted
## Mede o jogo como a apresentação o usa: a cada passo, avança uma hora e consulta tudo o
## que apresentacao/simulacao.gd lê (_ler), e de novo na mesma hora. Usado pela regressão
## e por medir_desempenho.gd.
##
## Esta máquina tem picos de outros processos (e esquenta em processos longos): cada janela
## é medida em processos novos, várias vezes, e vale o menor tempo de cada passo. Um custo
## de verdade se repete em todas as execuções; um pico de fora, não.

const Persistencia = preload("res://nucleo/persistencia.gd")

## Metas: nenhum passo e nenhuma consulta acima disto, com a população máxima.
const PASSO_MAX_MS := 5.0
const CONSULTA_MAX_MS := 2.0
## O mundo grande (estágio 6, população máxima), gerado por medir_desempenho.gd.
const MUNDO_GRANDE := "res://ferramentas_sim/mundo_grande.bin"
const TEMPORARIO := "user://mundo_grande.txt"
const MARCA := "RESULTADO "
## Janelas medidas: [ano, dia (0 a 39), hora, passos]. A primeira cruza dois dias e uma virada
## de ano com a população máxima; a segunda, uma virada de década (a crônica faz o censo).
const JANELAS := [[285, 38, 12, 48], [290, 39, 12, 24]]
## No jogo, um passo leva de 1,9 s (ritmo rápido) a 112 s.
const RAPIDO_MS := 1900


## O que a apresentação consulta a cada passo.
static func ler(w, vistos: int) -> int:
	w.tempo()
	w.clima()
	w.pessoas_visiveis()
	w.preces_abertas()
	w.construcoes()
	w.zonas_visiveis()
	w.cenas_ativas()
	w.eventos_desde(vistos)
	return w.eventos.size()


## Avança `passos` horas consultando a cada uma, com `pausa_ms` entre um passo e outro.
## Quando há uma rotina sendo montada na thread, a pausa vai até ela ficar pronta, mas
## nunca passa de RAPIDO_MS. Devolve os tempos de cada passo e de cada consulta, a
## montagem mais demorada na thread e os contadores do mundo.
static func medir(w, passos: int, pausa_ms: int = 30) -> Dictionary:
	var vistos: int = ler(w, w.eventos.size())   # a primeira consulta monta a rotina inteira
	var antes: Dictionary = w.desempenho.duplicate()
	var r := {"passos": passos, "tempos_passo": [], "tempos_consulta": [], "horas": [], "repetida": 0.0,
		"montagem_ms": 0}
	for i in passos:
		var espera := Time.get_ticks_msec()
		OS.delay_msec(pausa_ms)
		while w._montando != null and not WorkerThreadPool.is_task_completed(w._tarefa) and Time.get_ticks_msec() - espera < RAPIDO_MS:
			OS.delay_msec(5)
		if w._montando != null:
			r["montagem_ms"] = maxi(r["montagem_ms"], Time.get_ticks_msec() - espera)
		r["horas"].append("ano %d dia %d hora %d" % [w.ano(), w.dia_do_ano(), w.hora()])
		var t := Time.get_ticks_usec()
		w.avancar_hora()
		r["tempos_passo"].append((Time.get_ticks_usec() - t) / 1000.0)
		t = Time.get_ticks_usec()
		vistos = ler(w, vistos)
		r["tempos_consulta"].append((Time.get_ticks_usec() - t) / 1000.0)
		t = Time.get_ticks_usec()
		ler(w, vistos)
		r["repetida"] = maxf(r["repetida"], (Time.get_ticks_usec() - t) / 1000.0)
	for k in w.desempenho:
		r[k] = w.desempenho[k] - antes.get(k, 0)
	r["populacao"] = w.populacao()
	return r


static func carregar_mundo_grande():
	var f := FileAccess.open_compressed(MUNDO_GRANDE, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		push_error("Falta %s: gere com medir_desempenho.gd -- gerar" % MUNDO_GRANDE)
		return null
	var t := FileAccess.open(TEMPORARIO, FileAccess.WRITE)
	t.store_string(f.get_as_text())
	t.close()
	return Persistencia.carregar(TEMPORARIO)


## Mede a janela neste processo: carrega o mundo grande, avança sem consultar até o
## começo dela e mede.
static func janela_aqui(ano: int, dia: int, hora: int, passos: int) -> Dictionary:
	var w = carregar_mundo_grande()
	if w == null:
		return {}
	var alvo: int = ((ano - 1) * w.DIAS_ANO + dia) * w.HORAS_DIA + hora
	while w.passo < alvo:
		w.avancar_hora()
	return medir(w, passos)


## Mede a janela `n` vezes, cada uma num processo novo, e junta: o tempo de cada passo e de
## cada consulta é o menor entre as execuções; os contadores, o maior.
static func medir_em_processos(janela: Array, n: int) -> Dictionary:
	var execs: Array = []
	for i in n:
		var saida: Array = []
		# --quit-after: um erro de compilação no filho abriria a cena principal e nunca sairia.
		OS.execute(OS.get_executable_path(), ["--headless", "--quit-after", "600", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://ferramentas_sim/medir_desempenho.gd", "--", "janela", str(janela[0]), str(janela[1]),
			str(janela[2]), str(janela[3])], saida, true)
		for linha in "".join(saida).split("\n"):
			if linha.begins_with(MARCA):
				var e = JSON.parse_string(linha.substr(MARCA.length()))
				if e is Dictionary and not e.is_empty():
					execs.append(e)
	var r := {"janela": janela, "execucoes": execs.size(), "pedidas": n}
	if execs.is_empty():
		return r
	r["horas"] = execs[0]["horas"]
	r["passos"] = int(execs[0]["passos"])
	r["populacao"] = int(execs[0]["populacao"])
	for k in ["montagens_na_consulta", "esperas", "substitutos", "montagem_ms", "repetida"]:
		var mx := 0.0
		for e in execs:
			mx = maxf(mx, e[k])
		r[k] = mx
	for k in ["tempos_passo", "tempos_consulta"]:
		var l: Array = []
		for i in r["passos"]:
			var mn: float = INF
			for e in execs:
				mn = minf(mn, e[k][i])
			l.append(mn)
		r[k] = l
	return r


## O que ficou acima das metas: passos, consultas e contadores que deviam ser zero.
static func falhas(r: Dictionary) -> Array:
	var f: Array = []
	if r.get("execucoes", 0) < r.get("pedidas", 1):
		f.append("só %d de %d execuções deram resultado" % [r.get("execucoes", 0), r.get("pedidas", 1)])
		if r.get("execucoes", 0) == 0:
			return f
	for i in r["passos"]:
		if r["tempos_passo"][i] > PASSO_MAX_MS:
			f.append("passo de %s: %.2f ms" % [r["horas"][i], r["tempos_passo"][i]])
		if r["tempos_consulta"][i] > CONSULTA_MAX_MS:
			f.append("consulta depois do passo de %s: %.2f ms" % [r["horas"][i], r["tempos_consulta"][i]])
	for k in ["montagens_na_consulta", "esperas", "substitutos"]:
		if r[k] > 0:
			f.append("%s: %d" % [k, r[k]])
	return f


static func texto(r: Dictionary) -> String:
	if r.get("execucoes", 0) == 0:
		return "janela %s: nenhuma execução deu resultado" % [r.get("janela", [])]
	var pp := 0.0
	var pc := 0.0
	var hp := ""
	var hc := ""
	var mp := 0.0
	var mc := 0.0
	for i in r["passos"]:
		mp += r["tempos_passo"][i] / r["passos"]
		mc += r["tempos_consulta"][i] / r["passos"]
		if r["tempos_passo"][i] > pp:
			pp = r["tempos_passo"][i]
			hp = r["horas"][i]
		if r["tempos_consulta"][i] > pc:
			pc = r["tempos_consulta"][i]
			hc = r["horas"][i]
	return ("%d pessoas, %d passos a partir de %s (menor de %d execuções): passo pior %.2f ms (%s), média %.2f | " +
		"consulta pior %.2f ms (%s), média %.2f, repetida %.2f | montagens na consulta %d, esperas pela thread %d, " +
		"horas sem plano %d | montagem na thread até %d ms") % [r["populacao"], r["passos"], r["horas"][0], r["execucoes"],
		pp, hp, mp, pc, hc, mc, r["repetida"], r["montagens_na_consulta"], r["esperas"], r["substitutos"], r["montagem_ms"]]

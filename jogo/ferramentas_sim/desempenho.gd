extends RefCounted
## Mede o jogo como a apresentação o usa: a cada passo, avança uma hora e consulta tudo o
## que apresentacao/simulacao.gd lê (_ler), e de novo na mesma hora. Usado pela regressão
## e por medir_desempenho.gd.

## Metas: nenhum passo e nenhuma consulta acima disto, com a população máxima.
const PASSO_MAX_MS := 5.0
const CONSULTA_MAX_MS := 2.0


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


## Avança `passos` horas consultando a cada uma. Devolve os piores tempos (e em que hora),
## a média, e os contadores do mundo (montagens na consulta, horas sem plano).
static func medir(w, passos: int) -> Dictionary:
	var vistos: int = ler(w, w.eventos.size())   # a primeira consulta monta a rotina inteira
	var antes: Dictionary = w.desempenho.duplicate()
	var r := {"pior_passo": 0.0, "pior_consulta": 0.0, "hora_passo": "", "hora_consulta": "", "media_passo": 0.0,
		"media_consulta": 0.0, "repetida": 0.0, "passos": passos}
	for i in passos:
		var quando := "ano %d dia %d hora %d" % [w.ano(), w.dia_do_ano(), w.hora()]
		var t := Time.get_ticks_usec()
		w.avancar_hora()
		var dp := (Time.get_ticks_usec() - t) / 1000.0
		t = Time.get_ticks_usec()
		vistos = ler(w, vistos)
		var dc := (Time.get_ticks_usec() - t) / 1000.0
		t = Time.get_ticks_usec()
		ler(w, vistos)
		r["repetida"] = maxf(r["repetida"], (Time.get_ticks_usec() - t) / 1000.0)
		r["media_passo"] += dp / passos
		r["media_consulta"] += dc / passos
		if dp > r["pior_passo"]:
			r["pior_passo"] = dp
			r["hora_passo"] = quando
		if dc > r["pior_consulta"]:
			r["pior_consulta"] = dc
			r["hora_consulta"] = quando
	for k in w.desempenho:
		r[k] = w.desempenho[k] - antes.get(k, 0)
	return r


static func texto(r: Dictionary) -> String:
	return ("%d passos: passo pior %.2f ms (%s), média %.2f | consulta pior %.2f ms (%s), média %.2f, repetida %.2f | " +
		"montagens na consulta %d, horas sem plano %d") % [r["passos"], r["pior_passo"], r["hora_passo"], r["media_passo"],
		r["pior_consulta"], r["hora_consulta"], r["media_consulta"], r["repetida"], r["montagens_na_consulta"], r["substitutos"]]

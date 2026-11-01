extends SceneTree
## Bateria de QA da sessão D: os cenários de qa/cenarios.md que dão para testar sem tela,
## pelo núcleo e pela persistência, com sementes fixas.
##
## Uso (da raiz do repositório):
##   Godot_console.exe --headless --path jogo --script res://qa/rodar_qa.gd [-- --longo] [-- --so=QA-0xx,QA-1xx]
##
## Isolamento: a persistência do núcleo grava a estante sempre em user://estante, qualquer que
## seja o caminho do mundo. Para nunca tocar a pasta de dados real do jogador, a bateria se
## relança com APPDATA numa pasta temporária (%TEMP%/simvida_qa_appdata), onde fica o user://.
## Imprime PASSOU, FALHOU ou PULADO por cenário e sai com 1 se algum falhou.

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Estante = preload("res://nucleo/estante.gd")
const Arquivo = preload("res://nucleo/arquivo.gd")
const Cotidiano = preload("res://nucleo/cotidiano.gd")

const TMP := "user://qa_tmp"
const MARCA_ISOLADO := "simvida_qa_appdata"
const RUIDO := ["RID alloc", "BUG: Unref", "PagedAlloc", "Thread object", "wait_to_finish", "~Thread", "unref (core",
	"paged_allocator", "Godot Engine v", "string_name.cpp", "thread.cpp", "leaked at exit", "ObjectDB instances"]

var resultados := {}      # id -> {"estado": "PASSOU"|"FALHOU"|"PULADO", "notas": []}
var ordem: Array = []
var longo := false
var so: Array = []
var snapshots := {}       # nome -> caminho do mundo salvo


# ---------------------------------------------------------------- arranque e isolamento

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if OS.get_environment("SIMVIDA_QA") != "1":
		_relancar_isolado(args)
		return
	if not OS.get_user_data_dir().contains(MARCA_ISOLADO):
		print("FALHOU QA-000  a bateria não está isolada: user:// = ", OS.get_user_data_dir())
		quit(2)
		return
	longo = args.has("--longo")
	for a in args:
		if a.begins_with("--so="):
			so = Array(a.trim_prefix("--so=").split(","))
	_limpar_pasta("user://qa_tmp")
	_limpar_pasta("user://estante")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP))
	print("user:// isolado em ", OS.get_user_data_dir())
	var t0 := Time.get_ticks_msec()
	_rodar_tudo()
	_resumo()
	print("  [tempo] bateria: %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(1 if _contar("FALHOU") > 0 else 0)


func _relancar_isolado(args: PackedStringArray) -> void:
	var tmp := OS.get_environment("TEMP").path_join(MARCA_ISOLADO)
	DirAccess.make_dir_recursive_absolute(tmp)
	OS.set_environment("APPDATA", tmp)
	OS.set_environment("SIMVIDA_QA", "1")
	var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://qa/rodar_qa.gd"]
	if not args.is_empty():
		a.append("--")
		a.append_array(args)
	var saida: Array = []
	var codigo := OS.execute(OS.get_executable_path(), a, saida, true)
	for bloco in saida:
		for linha in _de_cp1252(str(bloco)).split("\n"):
			if linha.strip_edges().is_empty() or RUIDO.any(func(r): return linha.contains(r)):
				continue
			print(linha)
	quit(codigo)


## No Windows, OS.execute lê a saída do filho (UTF-8) como se fosse da página de código 1252.
## Desfaz: volta cada caractere ao byte de origem e lê de novo como UTF-8.
const CP1252 := "€\u0081‚ƒ„…†‡ˆ‰Š‹Œ\u008dŽ\u008f\u0090‘’“”•–—˜™š›œ\u009džŸ"


func _de_cp1252(s: String) -> String:
	var bytes := PackedByteArray()
	for i in s.length():
		var c := s.unicode_at(i)
		var k := CP1252.find(s[i])
		if k >= 0:
			bytes.append(0x80 + k)
		elif c < 256:
			bytes.append(c)
		else:
			return s   # já veio certo
	return bytes.get_string_from_utf8()


func _limpar_pasta(pasta: String) -> void:
	# só roda isolado (conferido antes): nunca na pasta de dados do jogador
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	for d in dir.get_directories():
		_limpar_pasta(pasta.path_join(d))
		dir.remove(d)


# ---------------------------------------------------------------- registro

func _quer(id: String) -> bool:
	return so.is_empty() or so.has(id)


func conferir(id: String, cond: bool, msg: String) -> bool:
	if not resultados.has(id):
		resultados[id] = {"estado": "PASSOU", "notas": []}
		ordem.append(id)
	if not cond:
		resultados[id]["estado"] = "FALHOU"
	resultados[id]["notas"].append(("ok: " if cond else "NÃO: ") + msg)
	print("   %s %s %s" % [id, "ok " if cond else "NÃO", msg])
	return cond


func pular(id: String, motivo: String) -> void:
	if not resultados.has(id):
		resultados[id] = {"estado": "PULADO", "notas": []}
		ordem.append(id)
	resultados[id]["notas"].append("pulado: " + motivo)
	print("   %s --  pulado: %s" % [id, motivo])


func info(msg: String) -> void:
	print("  [info] " + msg)


func _contar(estado: String) -> int:
	return ordem.filter(func(i): return resultados[i]["estado"] == estado).size()


func _resumo() -> void:
	print("\n================ RESUMO POR CENÁRIO ================")
	var ids := ordem.duplicate()
	ids.sort()
	for id in ids:
		var r: Dictionary = resultados[id]
		var falhas: Array = r["notas"].filter(func(n): return n.begins_with("NÃO"))
		var nota: String = (falhas[0] if not falhas.is_empty() else r["notas"][-1]) if not r["notas"].is_empty() else ""
		print("%s %s  %s" % [r["estado"], id, nota.substr(0, 150)])
	print("====================================================")
	print("Cenários testados: %d | PASSOU: %d | FALHOU: %d | PULADO: %d" % [ordem.size(), _contar("PASSOU"),
		_contar("FALHOU"), _contar("PULADO")])


# ---------------------------------------------------------------- ajudas

func _caminho(nome: String) -> String:
	return TMP.path_join(nome + ".txt")


func _apagar_mundo(caminho: String) -> void:
	for base in [caminho, Persistencia.caminho_antigos(caminho)]:
		for c in [base, base + ".novo"] + range(1, Arquivo.COPIAS + 2).map(func(n): return Arquivo.copia(base, n)):
			if FileAccess.file_exists(c):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(c))


## Guarda o mundo como estava (para testar dois caminhos a partir do mesmo ponto).
func _guardar(nome: String, m) -> void:
	var c := _caminho("snap_" + nome)
	_apagar_mundo(c)
	Persistencia.salvar(m, c)
	snapshots[nome] = c


func _abrir(nome: String):
	return Persistencia.carregar(snapshots[nome])


func _fogo(m, gid: int) -> float:
	for o in m.construcoes():
		if o["grupo"] == gid and o["tipo"] == "fogueira":
			return float(o["x"])
	return 260.0


func _ate_hora(m, h: int) -> void:
	while m.tempo()["hora"] != h:
		m.avancar_hora()


func _tipos(m, desde: int = 0) -> Dictionary:
	var r := {}
	for e in m.eventos_desde(desde):
		r[e["tipo"]] = r.get(e["tipo"], 0) + 1
	return r


func _eventos_tipo(m, tipo: String, desde: int = 0) -> Array:
	return m.eventos_desde(desde).filter(func(e): return e["tipo"] == tipo)


## A semente que dá o mundo de referência dos testes longos (chega ao estágio 6, API).
const SEMENTE_LONGA := 3


# ---------------------------------------------------------------- bateria

func _rodar_tudo() -> void:
	var blocos := [
		["começo do mundo", _bloco_comeco],
		["cotidiano e tempo", _bloco_cotidiano],
		["poderes", _bloco_poderes],
		["preces", _bloco_preces],
		["religião e culturas", _bloco_religiao_culturas],
		["estágios e mundo longo", _bloco_estagios],
		["linhagem", _bloco_linhagem],
		["ausência", _bloco_ausencia],
		["persistência", _bloco_persistencia],
		["fim do mundo", _bloco_fim],
		["estante e abandono", _bloco_estante],
		["guerra (TDD)", _bloco_guerra],
		["inspeção do código", _bloco_inspecao],
	]
	for b in blocos:
		print("\n--- %s ---" % b[0])
		var t := Time.get_ticks_msec()
		b[1].call()
		print("  [tempo] %s: %.1f s" % [b[0], (Time.get_ticks_msec() - t) / 1000.0])


# ---------------------------------------------------------------- 1. começo do mundo

func _bloco_comeco() -> void:
	var m := Mundo.new(1)
	if _quer("QA-001"):
		var chaves := m.zonas_visiveis().map(func(z): return z["chave"])
		chaves.sort()
		conferir("QA-001", chaves == ["floresta", "lago", "morro", "praia"], "zonas: %s" % [chaves])
	if _quer("QA-002"):
		conferir("QA-002", m.populacao() == 0, "o mundo novo começa vazio, à espera do primeiro gesto (população: %d)" % m.populacao())
	if _quer("QA-003"):
		var gv: Array = m.grupos_visiveis()
		conferir("QA-003", m.populacao() >= 10 and m.populacao() <= 14, "cerca de 12 pessoas (%d)" % m.populacao())
		conferir("QA-003", gv.size() == 1 and gv[0]["estagio"] == 1, "um povo, no estágio 1")
		conferir("QA-003", gv.size() == 1 and gv[0]["nome_deus"] == "", "sem religião: nome do deus vazio")
		var sagrado := m.construcoes().filter(func(o): return o["tipo"] in ["altar", "templo"])
		conferir("QA-003", sagrado.is_empty(), "sem altar nem templo")
		var pais := m.pessoas_visiveis().filter(func(p): return p["pai"] != -1 or p["mae"] != -1).size()
		conferir("QA-003", pais > 0, "uma família estendida: %d pessoas com pai ou mãe no povo" % pais)
	if _quer("QA-004"):
		var a = _mundo_com_gestos(11, 30)
		var b = _mundo_com_gestos(11, 30)
		conferir("QA-004", a.cronica() == b.cronica(), "mesma crônica em 30 anos (%d caracteres)" % a.cronica().length())
		conferir("QA-004", a.eventos.size() == b.eventos.size(), "mesmo número de eventos (%d)" % a.eventos.size())
		conferir("QA-004", a.rng.state == b.rng.state, "mesmo estado do sorteio")
	if _quer("QA-005") or _quer("QA-010") or _quer("QA-012"):
		_consultas_puras()


func _mundo_com_gestos(semente: int, anos: int):
	var m := Mundo.new(semente)
	for ano in anos:
		m.avancar_dias(13)
		m.usar_poder(["chuva", "fartura", "sonho", "raio", "pressagio"][ano % 5], 120.0 + 11.0 * (ano % 30), 0.3 + 0.1 * (ano % 7))
		m.avancar_dias(27)
	return m


func _consultas_puras() -> void:
	var a := Mundo.new(5)
	var b := Mundo.new(5)
	var na_agua := 0
	var horas := 24 * 40 * 2
	if not longo:
		horas = 24 * 40
	var noites_sem_ninguem := 0
	var horas_paradas := 0
	for h in horas:
		a.avancar_hora()
		b.avancar_hora()
		var acordado := false
		var mudou := false
		for p in a.pessoas_visiveis():
			if (p["x"] < 126.0 or p["x_anterior"] < 126.0) and p["acao"] != "remar":
				na_agua += 1
			if p["acao"] != "dormir":
				acordado = true
			if p["agenda"].size() > 1 or p["x"] != p["x_anterior"]:
				mudou = true
		if a.tempo()["noite"] and not acordado:
			noites_sem_ninguem += 1
		if not mudou:
			horas_paradas += 1
		a.cenas_ativas()
		a.construcoes()
		a.preces_abertas()
		if h % 6 == 0 and a.populacao() > 0:
			a.dica(a.pessoas_visiveis()[0]["id"])
			a.sugestoes()
	conferir("QA-005", a.rng.state == b.rng.state, "consultar toda hora não muda o sorteio (%d horas)" % horas)
	conferir("QA-005", a.eventos.size() == b.eventos.size() and a.cronica() == b.cronica(), "nem os eventos, nem a crônica")
	conferir("QA-012", noites_sem_ninguem == 0, "toda hora da noite tem alguém acordado (%d horas sem ninguém)" % noites_sem_ninguem)
	conferir("QA-012", horas_paradas == 0, "toda hora alguém muda de lugar (%d horas paradas em %d)" % [horas_paradas, horas])
	conferir("QA-010", na_agua == 0, "ninguém na água fora do barco em %d horas consultadas (%d casos)" % [horas, na_agua])


# ---------------------------------------------------------------- 2. cotidiano e tempo

func _bloco_cotidiano() -> void:
	var m := Mundo.new(2)
	if _quer("QA-011"):
		var ruins := m.pessoas_visiveis().filter(func(p): return p["tracos"].size() != 2 or p["tracos"].any(func(t): return not Mundo.TRACOS.has(t)))
		conferir("QA-011", ruins.is_empty(), "todos com dois traços da lista (%d fora)" % ruins.size())
	if _quer("QA-016"):
		conferir("QA-016", is_equal_approx(Mundo.SEGUNDOS_POR_PASSO * 24.0, 2700.0), "um dia = 45 min reais (%.0f s)" % (Mundo.SEGUNDOS_POR_PASSO * 24.0))
		var noite := 0
		for h in 24:
			m.avancar_hora()
			if m.tempo()["noite"]:
				noite += 1
		var min_noite := noite * Mundo.SEGUNDOS_POR_PASSO / 60.0
		conferir("QA-016", absf(min_noite - 15.0) <= 2.0, "noite de cerca de 15 min reais (tem %d horas de jogo = %.2f min)" % [noite, min_noite])
	if _quer("QA-017"):
		var w := Mundo.new(2)
		var ano0: int = w.tempo()["ano"]
		var estacoes := []
		for d in 40:
			var e: String = w.tempo()["estacao"]
			if estacoes.is_empty() or estacoes[-1] != e:
				estacoes.append(e)
			w.avancar_dias(1)
		conferir("QA-017", Mundo.DIAS_ANO == 40 and w.tempo()["ano"] == ano0 + 1, "40 dias fazem um ano")
		conferir("QA-017", estacoes == ["primavera", "verão", "outono", "inverno"], "4 estações em ordem: %s" % [estacoes])
	var l := Mundo.new(4)
	l.avancar_dias(40 * 50)
	var tipos := _tipos(l)
	if _quer("QA-013"):
		var crise := ["fome_inicio", "doenca_inicio", "seca_inicio"].filter(func(t): return tipos.has(t))
		conferir("QA-013", not crise.is_empty(), "50 anos sem deus geram crises sozinhos: %s" % [crise])
		conferir("QA-013", tipos.has("nascimento") and tipos.has("morte"), "nascimentos (%d) e mortes (%d)" % [tipos.get("nascimento", 0), tipos.get("morte", 0)])
		conferir("QA-013", tipos.has("ataque") or tipos.has("rixa") or tipos.has("separacao"), "algum conflito social (ataque %d, rixa %d, separação %d)" % [tipos.get("ataque", 0), tipos.get("rixa", 0), tipos.get("separacao", 0)])
	if _quer("QA-014"):
		l.avancar_dias(40 * 50)
		var nomes := []
		for z in l.zonas_visiveis():
			for gid in z["nomes"]:
				nomes.append(str(z["nomes"][gid]))
		conferir("QA-014", not nomes.is_empty(), "em 100 anos, lugares com nome: %s" % [nomes.slice(0, 4)])
	if _quer("QA-015"):
		var w := Mundo.new(6)
		w.avancar_dias(40 * 3)
		_ate_hora(w, 10)
		var ruins := 0
		var vistas := 0
		for h in 8:
			for p in w.pessoas_visiveis():
				var d: Dictionary = w.dica(p["id"])
				if p["acao"] == "dormir":
					continue
				vistas += 1
				var pens: String = d.get("pensamento", "")
				var proibido := pens.to_lower().contains("jogador") or pens.to_lower().contains("você")
				if d.get("fazendo", "") == "" or d.get("humor", "") == "" or pens.length() > 60 or proibido or pens.contains("{"):
					ruins += 1
					if ruins <= 3:
						info("dica ruim: %s" % [d])
			w.avancar_hora()
		conferir("QA-015", vistas > 0 and ruins == 0, "%d dicas de gente acordada, %d com problema" % [vistas, ruins])


# ---------------------------------------------------------------- 3. poderes

func _bloco_poderes() -> void:
	var fogo0 := _fogo(Mundo.new(3), 0)
	if _quer("QA-020") or _quer("QA-026"):
		for poder in Mundo.PODERES:
			var m := Mundo.new(3)
			var g0: int = m.grupos_vivos()[0].id
			var x := _fogo(m, g0)
			var r: Dictionary = m.usar_poder(poder, x, 0.6)
			conferir("QA-020", r.get("ok", false), "%s funciona no primeiro dia (%s)" % [poder, r.get("grau", r.get("motivo", ""))])
			if r.get("ok", false) and r.get("evento", -1) >= 0:
				var e: Dictionary = m.eventos_desde(r["evento"])[0]
				var dd: Dictionary = e["dados"]
				conferir("QA-026", dd.has("x") and dd.has("grau") and dd.has("intensidade") and e["camada"] in ["nota", "chamado"],
					"%s: evento %s com x, grau e intensidade, camada %s" % [poder, e["tipo"], e["camada"]])
			else:
				conferir("QA-026", false, "%s: sem evento (%s)" % [poder, r])
	if _quer("QA-021"):
		for par in [[0.0, "sinal"], [0.2, "sinal"], [0.499, "sinal"], [0.5, "milagre"], [1.0, "milagre"]]:
			var m := Mundo.new(3)
			var r: Dictionary = m.usar_poder("chuva", fogo0, par[0])
			conferir("QA-021", r.get("grau", "") == par[1], "chuva %.3f → %s (veio %s)" % [par[0], par[1], r.get("grau", "?")])
	if _quer("QA-022"):
		var m := Mundo.new(3)
		var graus := []
		for i in 3:
			graus.append(m.usar_poder("chuva", fogo0, 0.2)["grau"])
			m.avancar_dias(1)
		conferir("QA-022", graus[2] == "imposicao", "3ª chuva na mesma zona em 3 dias é imposição: %s" % [graus])
	if _quer("QA-023"):
		var m := Mundo.new(3)
		var graus := []
		for x in [150.0, 260.0, 400.0]:
			graus.append(m.usar_poder("chuva", x, 0.2)["grau"])
		conferir("QA-023", not graus.has("imposicao"), "3 zonas diferentes, nenhuma imposição: %s" % [graus])
		var w := Mundo.new(3)
		graus = []
		for i in 3:
			graus.append(w.usar_poder("chuva", fogo0, 0.2)["grau"])
			w.avancar_dias(2)
		conferir("QA-023", graus[2] != "imposicao", "dias 0, 2 e 4 (4 dias entre o 1º e o 3º): %s" % [graus])
	if _quer("QA-024"):
		var m := Mundo.new(3)
		var r: Dictionary = m.usar_poder("chuva", -50.0, 3.0)
		var dd: Dictionary = m.eventos_desde(r["evento"])[0]["dados"] if r.get("ok", false) else {}
		conferir("QA-024", r.get("ok", false) and is_equal_approx(dd.get("intensidade", -1.0), 1.0) and dd.get("x", -1.0) == 0.0,
			"x -50 e intensidade 3 viram x 0 e 1 (%s)" % [dd.get("x", "?")])
		r = m.usar_poder("fogo", 99999.0, -1.0)
		conferir("QA-024", r.get("ok", false), "x 99999 e intensidade -1 também não quebram")
	if _quer("QA-025"):
		var r: Dictionary = Mundo.new(3).usar_poder("praga", 200.0, 0.5)
		conferir("QA-025", not r.get("ok", true) and r.has("motivo"), "poder desconhecido recusado: %s" % r.get("motivo", ""))
	if _quer("QA-027") or _quer("QA-028"):
		_raio_na_pessoa()
	if _quer("QA-030"):
		_cura()
	if _quer("QA-031"):
		var formas := []
		for i in [0.2, 0.5, 0.9]:
			var m := Mundo.new(3)
			var r: Dictionary = m.usar_poder("pressagio", 260.0, i)
			var dd: Dictionary = m.eventos_desde(r["evento"])[0]["dados"]
			formas.append(dd.get("forma", "?"))
			if i == 0.9:
				conferir("QA-031", dd.get("leituras", {}).size() == m.grupos_vivos().size(), "todos os povos leem o presságio: %s" % [dd.get("leituras", {})])
		conferir("QA-031", formas == ["cometa", "eclipse", "luzes"], "formas: %s" % [formas])
	if _quer("QA-033") or _quer("QA-130"):
		var m := Mundo.new(3)
		var antes := m.populacao()
		var r: Dictionary = {}
		for i in 3:
			r = m.usar_poder("diluvio", fogo0, 1.0)
		var dd: Dictionary = m.eventos_desde(r["evento"])[0]["dados"]
		conferir("QA-033", r.get("grau", "") == "imposicao" and dd.get("zonas", []).size() == 4, "dilúvio imposto alaga as 4 zonas: %s" % [dd.get("zonas", [])])
		m.avancar_dias(1)
		info("dilúvio imposto 3 vezes: população %d → %d" % [antes, m.populacao()])
		if m.populacao() > 0 and m.populacao() < antes:
			conferir("QA-130", true, "o quase fim: sobraram %d de %d" % [m.populacao(), antes])
		else:
			pular("QA-130", "a semente 3 não deu um quase fim com 3 dilúvios (%d de %d)" % [m.populacao(), antes])
	if _quer("QA-035"):
		var m := Mundo.new(3)
		var x := fogo0
		var ini := m.eventos.size()
		for i in 6:
			m.usar_poder("chuva", x, 0.8)
			m.avancar_dias(5)
		var t := _tipos(m, ini)
		var costumes: Array = m.grupos_visiveis()[0]["costumes"]
		conferir("QA-035", costumes.has("festa_chuva"), "4 chuvas em um ano viram a festa da chuva: %s" % [costumes])
		conferir("QA-035", t.has("dependencia"), "6 chuvas viram dependência (%s)" % [t.keys()])
	if _quer("QA-032"):
		var achou := false
		for s in range(1, 9):
			var m := Mundo.new(s)
			_ate_hora(m, 10)
			var alvo: Dictionary = m.pessoas_visiveis().filter(func(p): return not p["crianca"])[0]
			var r: Dictionary = m.usar_poder("sonho", m.posicao_de(alvo["id"]), 0.8)
			var dd: Dictionary = m.eventos_desde(r["evento"])[0]["dados"]
			if r.get("alvo", -1) >= 0:
				achou = true
				info("sonho de milagre sobre %d: %s" % [r["alvo"], dd])
				break
		conferir("QA-032", achou, "o sonho de milagre acerta uma pessoa sob o gesto")


func _raio_na_pessoa() -> void:
	var m := Mundo.new(3)
	_ate_hora(m, 10)
	var p: Dictionary = m.pessoas_visiveis().filter(func(q): return not q["crianca"] and q["acao"] != "dormir")[0]
	var antes := m.populacao()
	var r: Dictionary = m.usar_poder("raio", m.posicao_de(p["id"]), 0.2)
	m.avancar_hora()
	conferir("QA-028", m.populacao() == antes, "raio de sinal não mata ninguém (%d → %d)" % [antes, m.populacao()])
	# O raio de milagre mira o x do fim da hora (agenda[-1].x1, o `x` de pessoas_visiveis)...
	var w := Mundo.new(3)
	_ate_hora(w, 10)
	p = w.pessoas_visiveis().filter(func(q): return not q["crianca"] and q["acao"] != "dormir")[0]
	r = w.usar_poder("raio", p["x"], 0.9)
	var alvo: int = r.get("alvo", -1)
	conferir("QA-027", alvo >= 0 and not w.pessoa(alvo).vivo, "raio de milagre no x do fim da hora mata a pessoa (alvo %d)" % alvo)
	# ...mas na tela a pessoa anda pela agenda durante a hora. Quanto tempo da hora ela fica a
	# mais de 6 px do ponto que o raio acerta? É a chance de errar quem se toca na tela.
	var amostras := 0
	var longe := 0
	var longe_min := 0
	var meio_longe := 0
	var gente := 0
	for s in range(1, 6):
		var v := Mundo.new(s)
		v.avancar_dias(3)
		for h in range(8, 17):
			_ate_hora(v, h)
			for q in v.pessoas_visiveis():
				if q["acao"] == "dormir":
					continue
				gente += 1
				if absf(v.posicao_de(q["id"]) - q["x"]) > Mundo.ALCANCE_ALVO:
					meio_longe += 1
				for f in range(20):
					amostras += 1
					if absf(_x_na_agenda(q["agenda"], (f + 0.5) / 20.0) - q["x"]) > Mundo.ALCANCE_ALVO:
						longe += 1
					if absf(_x_na_agenda(q["agenda"], (f + 0.5) / 20.0, true) - q["x"]) > Mundo.ALCANCE_ALVO:
						longe_min += 1
	var pct := 100.0 * longe / maxi(1, amostras)
	var pct_min := 100.0 * longe_min / maxi(1, amostras)
	info("raio: %d pessoas acordadas (8h às 16h, 5 sementes); a mais de 6 px do ponto que o raio acerta: %.1f%% do tempo andando em linha reta, %.1f%% se cada trecho chega logo ao destino e espera (limite inferior); no meio da hora (posicao_de), %d de %d" % [gente, pct, pct_min, meio_longe, gente])
	conferir("QA-027", pct_min <= 5.0, "quem se toca na tela é quem o raio acerta: a pessoa está longe do alvo do núcleo de %.1f%% a %.1f%% do tempo" % [pct_min, pct])
	r = w.usar_poder("raio", w.posicao_de(p["id"]), 0.9)


## O x da pessoa na fração f da hora. `no_destino`: como a vista anda (rápido, e espera no fim
## do trecho), a pessoa já está no x1 do trecho em que está (limite inferior da distância).
func _x_na_agenda(agenda: Array, f: float, no_destino := false) -> float:
	for t in agenda:
		if f >= t["de"] and f <= t["ate"]:
			if no_destino:
				return t["x1"]
			var span: float = maxf(0.0001, t["ate"] - t["de"])
			return lerpf(t["x0"], t["x1"], (f - t["de"]) / span)
	return agenda[-1]["x1"] if not agenda.is_empty() else 0.0


func _cura() -> void:
	var m := Mundo.new(3)
	_ate_hora(m, 10)
	var g = m.grupos_vivos()[0]
	var doentes := []
	# Preparação (gancho interno, como faz o cenário "doentes" da apresentação): 3 adultos doentes.
	for p in m._adultos(g, 16).slice(0, 3):
		p.doente = 8
		doentes.append(p.id)
	m.avancar_dias(1)
	_ate_hora(m, 10)
	var alvo: int = doentes[0]
	var r: Dictionary = m.usar_poder("cura", m.posicao_de(alvo), 0.8)
	var dd: Dictionary = m.eventos_desde(r["evento"])[0]["dados"]
	conferir("QA-030", dd.get("curado", -1) == alvo and m.pessoa(alvo).doente == 0, "a cura de milagre levanta o doente (%s)" % [dd])
	m.usar_poder("cura", m.posicao_de(alvo), 0.8)
	r = m.usar_poder("cura", m.posicao_de(alvo), 0.8)
	var ainda := doentes.filter(func(id): return m.pessoa(id).vivo and m.pessoa(id).doente > 0)
	conferir("QA-030", r.get("grau", "") == "imposicao" and ainda.is_empty(), "a cura imposta cura todos os doentes (%d ainda doentes)" % ainda.size())


# ---------------------------------------------------------------- 4. preces

## Roda as sementes dia a dia e guarda o mundo no dia em que surge a primeira prece de cada
## necessidade (para testar respostas diferentes a partir do mesmo ponto).
func _procurar_preces(precisa: Array) -> void:
	var faltam := precisa.duplicate()
	for s in [1, 2, 3, 4, 5, 6]:
		if faltam.is_empty():
			break
		var m := Mundo.new(s)
		var vistos := m.eventos.size()
		for d in 40 * (60 if longo else 45):
			m.avancar_dias(1)
			for e in m.eventos_desde(vistos):
				var nec: String = e["dados"].get("necessidade", "")
				if e["tipo"] == "prece" and faltam.has(nec):
					_guardar("prece_" + nec, m)
					info("prece de %s: semente %d, ano %d dia %d" % [nec, s, e["ano"], e["dia"]])
					faltam.erase(nec)
			vistos = m.eventos.size()
			if faltam.is_empty():
				break


func _prece_aberta(m, nec: String) -> Dictionary:
	for pr in m.preces_abertas():
		if pr["necessidade"] == nec:
			return pr
	return {}


func _bloco_preces() -> void:
	_procurar_preces(["fome", "seca", "frio", "doenca"])
	if _quer("QA-040") or _quer("QA-041") or _quer("QA-042") or _quer("QA-045"):
		if not snapshots.has("prece_fome"):
			pular("QA-040", "nenhuma prece de fome nas sementes")
		else:
			var m = _abrir("prece_fome")
			var pr := _prece_aberta(m, "fome")
			conferir("QA-040", not pr.is_empty(), "a prece de fome está em preces_abertas")
			if not pr.is_empty():
				conferir("QA-040", pr["texto"] != "" and pr["curto"].length() <= 40 and pr["atendem"] == ["fartura"],
					"texto «%s», curto «%s», atendem %s" % [pr["texto"], pr["curto"], pr["atendem"]])
				# atendida pelo poder certo, no fogo do povo
				var ini: int = m.eventos.size()
				m.usar_poder("fartura", pr["x_povo"], 0.8)
				m.avancar_dias(1)
				var at := _eventos_tipo(m, "prece_atendida", ini).filter(func(e): return e["dados"].get("prece", -1) == pr["evento"])
				conferir("QA-041", not at.is_empty() and not at[0]["dados"].get("falso_milagre", true), "fartura no fogo do povo atende a prece de fome")
				conferir("QA-041", _prece_aberta(m, "fome").is_empty() or _prece_aberta(m, "fome")["evento"] != pr["evento"], "e a prece sai de preces_abertas")
				# o silêncio
				var w = _abrir("prece_fome")
				ini = w.eventos.size()
				w.avancar_dias(5)
				var pr5 := _prece_aberta(w, "fome")
				var resolvida5 := _eventos_tipo(w, "prece_atendida", ini).size() + _eventos_tipo(w, "prece_sem_resposta", ini).size()
				conferir("QA-045", (not pr5.is_empty() and pr5["dias"] >= 5) or resolvida5 > 0, "5 dias depois, a prece segue esperando (ou se resolveu)")
				w.avancar_dias(11)
				var sem := _eventos_tipo(w, "prece_sem_resposta", ini).filter(func(e): return e["dados"].get("prece", -1) == pr["evento"])
				var falso := _eventos_tipo(w, "prece_atendida", ini).filter(func(e): return e["dados"].get("prece", -1) == pr["evento"])
				conferir("QA-042", not sem.is_empty() or not falso.is_empty(), "em 16 dias de silêncio a prece termina: sem resposta (%d) ou falso milagre (%d)" % [sem.size(), falso.size()])
				if not falso.is_empty():
					info("a fome passou sozinha: falso milagre = %s" % falso[0]["dados"].get("falso_milagre"))
	if _quer("QA-043"):
		if not snapshots.has("prece_seca"):
			pular("QA-043", "nenhuma prece de seca nas sementes")
		else:
			var m = _abrir("prece_seca")
			var pr := _prece_aberta(m, "seca")
			var ini: int = m.eventos.size()
			m.usar_poder("seca", pr.get("x_povo", 260.0), 0.8)
			var c := _eventos_tipo(m, "prece_contrariada", ini)
			conferir("QA-043", not c.is_empty(), "seca sobre quem pede chuva contraria a prece")
	if _quer("QA-029") or _quer("QA-048"):
		if not snapshots.has("prece_frio"):
			pular("QA-029", "nenhuma prece de frio nas sementes (%s)" % ("longo" if longo else "use --longo para procurar mais"))
			pular("QA-048", "idem")
		else:
			var m = _abrir("prece_frio")
			var pr := _prece_aberta(m, "frio")
			conferir("QA-048", pr.get("atendem", []).has("fogo") and pr.get("fogo_brando", false), "frio: atendem %s, brando %s" % [pr.get("atendem"), pr.get("fogo_brando")])
			var ini: int = m.eventos.size()
			var pop: int = m.populacao()
			m.usar_poder("fogo", pr.get("x_povo", 260.0), 0.2)
			var t := _tipos(m, ini)
			var at := _eventos_tipo(m, "prece_atendida", ini).filter(func(e): return e["dados"].get("necessidade", "") == "frio")
			conferir("QA-029", t.has("fogo_brando") and not at.is_empty() and m.populacao() == pop, "fogo 0,2: brando, atende o frio, ninguém morre (%s)" % [t.keys()])
			var w = _abrir("prece_frio")
			ini = w.eventos.size()
			w.usar_poder("fogo", pr.get("x_povo", 260.0), 0.35)
			t = _tipos(w, ini)
			conferir("QA-029", not t.has("fogo_brando") and t.has("prece_contrariada"), "fogo 0,35: já queima e contraria a prece (%s)" % [t.keys()])
	if _quer("QA-044") or _quer("QA-046") or _quer("QA-047") or _quer("QA-052") or _quer("QA-053") or _quer("QA-054"):
		_preces_mundo_longo()


## Um mundo sem deus por muitos anos: ponto cego, falso milagre e silêncio prolongado.
func _preces_mundo_longo() -> void:
	var m := Mundo.new(1)
	var violacoes := 0
	var anos := 150 if longo else 100
	var crentes_antes := -1
	for a in anos:
		m.avancar_dias(40)
		for pr in m.preces_abertas():
			var g = m.grupo(pr["grupo"])
			if not g.tem_crenca or g.ceticos:
				violacoes += 1
	conferir("QA-044", violacoes == 0, "%d anos: nenhuma prece de povo sem crença ou cético (%d casos)" % [anos, violacoes])
	var t := _tipos(m)
	var falsos := _eventos_tipo(m, "prece_atendida").filter(func(e): return e["dados"].get("falso_milagre", false))
	if falsos.is_empty():
		pular("QA-046", "nenhum falso milagre em %d anos na semente 1" % anos)
	else:
		var cr := m.cronica(1, -1, false)
		conferir("QA-046", cr.contains("acaso"), "%d falsos milagres; a crônica diz que foi acaso" % falsos.size())
	var mudou := ["silencio", "secularizacao", "profeta", "renascimento"].filter(func(x): return t.has(x))
	var ceticos := m.grupos_visiveis().filter(func(g): return g["ceticos"]).size()
	conferir("QA-047", not mudou.is_empty() or ceticos > 0, "%d anos sem deus mudam a religião: %s, %d povos céticos" % [anos, mudou, ceticos])
	if t.has("renascimento"):
		conferir("QA-053", true, "%d renascimentos da fé em %d anos" % [t["renascimento"], anos])
	else:
		pular("QA-053", "nenhum renascimento em %d anos na semente 1 (é raro: precisa de um povo cético diante de algo inegável)" % anos)
	conferir("QA-052", t.has("edito") or t.has("sacerdote"), "sacerdotes falam pelo deus (édito %d, sacerdote %d)" % [t.get("edito", 0), t.get("sacerdote", 0)])
	info("religião em %d anos: %s" % [anos, ["crenca", "edito", "silencio", "secularizacao", "profeta", "renascimento", "prece", "prece_atendida", "prece_sem_resposta"].map(func(k): return "%s=%d" % [k, t.get(k, 0)])])
	var fes := []
	for g in m.grupos_vivos():
		if g.tem_crenca:
			for id in g.membros:
				fes.append(snappedf(m.pessoa(id).fe, 0.01))
			break
	var distintos := {}
	for f in fes:
		distintos[f] = true
	conferir("QA-054", distintos.size() > 1, "a fé varia de pessoa para pessoa: %d valores em %d crentes" % [distintos.size(), fes.size()])


# ---------------------------------------------------------------- 5 e 6. religião e culturas

func _bloco_religiao_culturas() -> void:
	if _quer("QA-050"):
		var m := Mundo.new(1)
		var ini := m.eventos.size()
		var dias := 0
		while dias < 40 * 3 and m.grupos_visiveis()[0]["nome_deus"] == "":
			_ate_hora(m, 11)
			m.usar_poder(["erguer", "pressagio", "fartura"][dias % 3], _fogo(m, 0), 0.9)
			m.avancar_dias(2)
			dias += 2
		var cr := _eventos_tipo(m, "crenca", ini)
		conferir("QA-050", not cr.is_empty() and m.grupos_visiveis()[0]["nome_deus"] != "",
			"milagres fazem nascer a crença em %d dias: «%s»" % [dias, m.grupos_visiveis()[0]["nome_deus"]])
	var m := Mundo.new(SEMENTE_LONGA)
	var mesmos_nomes := 0
	var anos := 200 if longo else 120
	var exemplo := ""
	for a in anos:
		m.avancar_dias(40)
		var gv: Array = m.grupos_visiveis()
		for i in gv.size():
			for j in range(i + 1, gv.size()):
				if gv[i]["nome_deus"] != "" and gv[i]["nome_deus"] == gv[j]["nome_deus"] and not _parentes(m, gv[i]["id"], gv[j]["id"]):
					mesmos_nomes += 1
					exemplo = "%s e %s: «%s»" % [gv[i]["nome"], gv[j]["nome"], gv[i]["nome_deus"]]
	if _quer("QA-051"):
		conferir("QA-051", mesmos_nomes == 0, "%d anos: dois povos sem parentesco nunca chamam o deus igual (%d casos; %s)" % [anos, mesmos_nomes, exemplo])
		info("nomes do deus no ano %d: %s" % [m.tempo()["ano"], m.grupos_visiveis().map(func(g): return "%s=«%s»" % [g["nome"], g["nome_deus"]])])
	var gv: Array = m.grupos_visiveis()
	if _quer("QA-060"):
		var validos := {"deus": ["devota", "temerosa", "cetica", ""], "estranhos": ["acolhedora", "desconfiada"], "poder": ["lider", "conselho", "sacerdotes"],
			"recursos": ["partilha", "acumula"], "violencia": ["pacifica", "guerreira"], "mortos": ["enterram", "queimam", "veneram", ""]}
		var ruins := []
		for g in gv:
			for k in validos:
				if not g["cultura"].has(k) or not validos[k].has(g["cultura"][k]):
					ruins.append("%s.%s=%s" % [g["nome"], k, g["cultura"].get(k, "?")])
		conferir("QA-060", ruins.is_empty() and not gv.is_empty(), "6 dimensões com valores válidos em %d povos %s" % [gv.size(), ruins])
	if _quer("QA-061") or _quer("QA-062"):
		var filhos: Array = m.grupos.filter(func(g): return not g.origem.is_empty())
		conferir("QA-061", m.grupos.size() > 1, "do primeiro povo saíram outros: %d povos na história" % m.grupos.size())
		var ruins := filhos.filter(func(g): return not (g.origem.has("pai") and g.origem.get("causa", "") in ["migracao", "briga", "cisma"] and g.origem.has("ano")))
		conferir("QA-061", ruins.is_empty(), "cada povo novo tem a origem completa (%d sem)" % ruins.size())
		var cr := m.cronica(1, -1, false)
		var sem_registro := filhos.filter(func(g): return not cr.contains(g.nome))
		conferir("QA-062", filhos.is_empty() or sem_registro.size() < filhos.size(), "a crônica registra o nascimento dos povos novos (%d de %d sem o nome)" % [sem_registro.size(), filhos.size()])
	if _quer("QA-063"):
		var sem_origem := 0
		var total := 0
		for g in m.grupos_vivos():
			for c in g.costumes:
				total += 1
				if c.get("evento", -1) < 0:
					sem_origem += 1
		conferir("QA-063", sem_origem == 0, "%d costumes, todos com o acontecimento de origem (%d sem)" % [total, sem_origem])
	if _quer("QA-064"):
		var aparencias := {}
		for g in gv:
			aparencias[str(g["aparencia"])] = true
		conferir("QA-064", gv.size() < 2 or aparencias.size() > 1, "%d povos, %d aparências diferentes" % [gv.size(), aparencias.size()])
		# «o mesmo lago tem um nome para cada povo»
		var vivos_ids := gv.map(func(g): return g["id"])
		var repetidos := []
		var com_nome := 0
		for z in m.zonas_visiveis():
			var por_nome := {}
			for gid in z["nomes"]:
				if not vivos_ids.has(gid):
					continue
				com_nome += 1
				var n := str(z["nomes"][gid])
				if por_nome.has(n):
					repetidos.append("%s: %s e %s chamam de «%s»" % [z["chave"], m.grupo(por_nome[n]).nome, m.grupo(gid).nome, n])
				por_nome[n] = gid
		conferir("QA-064", repetidos.is_empty(), "cada povo dá o seu nome ao lugar: %d nomes de povos vivos, %d repetidos %s" % [com_nome, repetidos.size(), repetidos.slice(0, 3)])
	if _quer("QA-065"):
		var t := _tipos(m)
		conferir("QA-065", t.has("cultura") or t.has("reforma"), "as culturas mudam: cultura %d, reforma %d" % [t.get("cultura", 0), t.get("reforma", 0)])


func _parentes(m, a: int, b: int) -> bool:
	var anc_a := _ancestrais(m, a)
	var anc_b := _ancestrais(m, b)
	for x in anc_a:
		if anc_b.has(x):
			return true
	return false


func _ancestrais(m, gid: int) -> Array:
	var r := [gid]
	var g = m.grupo(gid)
	while g != null and not g.origem.is_empty():
		r.append(g.origem["pai"])
		g = m.grupo(g.origem["pai"])
	return r


# ---------------------------------------------------------------- 7. estágios

func _bloco_estagios() -> void:
	if _quer("QA-070"):
		var sementes := range(1, 21) if longo else range(1, 6)
		var tarde := []
		for s in sementes:
			var m := Mundo.new(s)
			var ano := -1
			for a in 50:
				m.avancar_dias(40)
				if m.grupos_vivos().any(func(g): return g.estagio >= 2):
					ano = a + 1
					break
			if ano < 0:
				tarde.append(s)
		conferir("QA-070", tarde.is_empty(), "agricultura em até 50 anos em %d sementes (falharam: %s)" % [sementes.size(), tarde])
	var m := Mundo.new(SEMENTE_LONGA)
	var anos := 250
	var fora := 0
	var maior := 0
	var guardou := false
	var subiu_construcao := 0
	for a in anos:
		m.avancar_dias(40)
		for g in m.grupos_vivos():
			if g.estagio < 1 or g.estagio > 6:
				fora += 1
			maior = maxi(maior, g.estagio)
			if not guardou and g.estagio in [3, 4] and g.escrita_desde < 0:
				_guardar("estagio34", m)
				guardou = true
		if a % 25 == 24:
			for o in m.construcoes():
				var minimo: int = {"forja": 4, "arquivo": 5, "moinho": 6, "roda_dagua": 6, "estela": 5}.get(o["tipo"], 1)
				if o["estagio"] < minimo:
					subiu_construcao += 1
	if _quer("QA-071"):
		conferir("QA-071", fora == 0, "%d anos: estágio sempre entre 1 e 6 (maior: %d)" % [anos, maior])
	if _quer("QA-074"):
		conferir("QA-074", subiu_construcao == 0, "nenhuma construção de estágio que o povo não tem (%d casos)" % subiu_construcao)
	if _quer("QA-073"):
		var escritores: Array = m.grupos.filter(func(g): return g.escrita_desde >= 0)
		if escritores.is_empty():
			pular("QA-073", "ninguém chegou à escrita em %d anos" % anos)
		else:
			conferir("QA-073", not m.cronica_do_povo(escritores[0].id).is_empty(), "%s escreve a própria crônica" % escritores[0].nome)
	if _quer("QA-072"):
		if not snapshots.has("estagio34"):
			pular("QA-072", "nenhum povo no estágio 3 ou 4 sem escrita")
		else:
			var w = _abrir("estagio34")
			var g = w.grupos_vivos().filter(func(x): return x.estagio in [3, 4] and x.escrita_desde < 0)[0]
			var saber: String = Mundo.SABERES[g.estagio]
			var de: int = g.estagio
			# Preparação (gancho interno): morrem todos os que sabem o saber do estágio.
			var mortos := 0
			for id in g.membros.duplicate():
				if w.pessoa(id).saberes.has(saber):
					w._morrer(w.pessoas[id], "doenca")
					mortos += 1
			var ini: int = w.eventos.size()
			w.avancar_dias(6)   # o progresso técnico (e a regressão) é conferido a cada 5 dias
			var reg := _eventos_tipo(w, "regressao", ini).filter(func(e): return e["grupo"] == g.id)
			conferir("QA-072", not reg.is_empty() and g.estagio == de - 1, "%s perde %s (%d mortos) e volta do %d ao %d" % [g.nome, saber, mortos, de, g.estagio])
	if _quer("QA-170") or _quer("QA-176"):
		# Como o jogo usa o mundo no 50x: um passo, a consulta, e 2,25 s até o passo seguinte. As
		# horas das 21h às 3h são as da rotina de amanhã (montada às 23h e de novo depois da 0h).
		var t1 := Time.get_ticks_usec()
		m.pessoas_visiveis()
		info("primeira consulta depois do salto de 250 anos: %.0f ms (API: ~100 ms, um momento de carregamento)" % ((Time.get_ticks_usec() - t1) / 1000.0))
		_ate_hora(m, 21)
		m.pessoas_visiveis()
		var tempos := []
		var linha := []
		for h in 7:
			OS.delay_msec(2250)
			var t := Time.get_ticks_usec()
			m.avancar_hora()
			var dt := (Time.get_ticks_usec() - t) / 1000.0
			m.pessoas_visiveis()
			m.cenas_ativas()
			m.construcoes()
			m.preces_abertas()
			tempos.append(dt)
			linha.append("%dh %.0f ms" % [m.tempo()["hora"], dt])
		var pior: float = tempos.max()
		info("passos no 50x, mundo de %d anos (%d pessoas): %s; esperas pela thread: %d (o tempo de cada passo depende da carga da máquina: a medida de 5 ms é a de desempenho.gd, da A)" % [anos, m.populacao(), linha, m.desempenho.get("esperas", 0)])
		conferir("QA-170", m.desempenho.get("esperas", 0) == 0 and pior < 100.0, "no 50x, nenhum passo espera a thread da rotina nem trava (pior %.1f ms, com %d pessoas)" % [pior, m.populacao()])
		var c := _caminho("aus_grande")
		_apagar_mundo(c)
		Persistencia.salvar(m, c)
		var t0 := Time.get_ticks_msec()
		var r = Persistencia.carregar_e_avancar(c, Persistencia.carregar(c).salvo_em + 400 * 24 * 3600)
		var seg := (Time.get_ticks_msec() - t0) / 1000.0
		conferir("QA-176", r != null and r["ausencia"]["passos"] == 960 and seg < 5.0, "carregar e avançar um ano no mundo de %d anos: %.1f s" % [anos, seg])
		_apagar_mundo(c)


# ---------------------------------------------------------------- 8. linhagem

func _bloco_linhagem() -> void:
	var m := Mundo.new(1)
	if _quer("QA-080"):
		conferir("QA-080", m.acompanhada >= 0 and m.pessoa(m.acompanhada).vivo, "há uma pessoa acompanhada, viva (%d)" % m.acompanhada)
	if _quer("QA-082"):
		var antes: int = m.acompanhada
		conferir("QA-082", not m.acompanhar(999999) and m.acompanhada == antes, "acompanhar quem não existe é recusado")
	if _quer("QA-081"):
		var feito := false
		for s in range(1, 10):
			var w := Mundo.new(s)
			w.avancar_dias(40 * 8)
			_ate_hora(w, 10)
			var alvo: int = w.acompanhada
			var esperado := _descendente_mais_velho(w, alvo)
			if esperado < 0:
				continue
			for tentativa in 8:
				var ini := w.eventos.size()
				var r: Dictionary = w.usar_poder("raio", w.posicao_de(alvo), 0.9)
				if r.get("alvo", -1) != alvo:
					w.avancar_hora()
					continue
				var lin := _eventos_tipo(w, "linhagem", ini)
				conferir("QA-081", not w.pessoa(alvo).vivo, "o raio do deus mata a pessoa acompanhada (semente %d)" % s)
				conferir("QA-081", w.acompanhada == esperado, "o acompanhamento passa ao descendente vivo mais velho (%d; veio %d)" % [esperado, w.acompanhada])
				conferir("QA-081", not lin.is_empty() and lin[0]["dados"].get("de", -1) == alvo and lin[0]["dados"].get("para", -2) == esperado, "evento linhagem de %d para %d" % [alvo, esperado])
				if _quer("QA-082"):
					conferir("QA-082", not w.acompanhar(alvo) and w.acompanhada == esperado, "acompanhar um morto é recusado")
				feito = true
				break
			if feito:
				break
		if not feito:
			pular("QA-081", "nenhuma semente com o raio acertando a pessoa acompanhada com descendentes")
	if _quer("QA-083"):
		var w := Mundo.new(2)
		w.avancar_dias(40 * 10)
		info("sugestões num mundo de 10 anos sem deus (semente 2): %s" % [w.sugestoes()])
		# O exemplo do documento: «esta mulher acabou de ter uma visão».
		_ate_hora(w, 10)
		var adulto: Dictionary = w.pessoas_visiveis().filter(func(p): return not p["crianca"] and p["acao"] != "dormir")[0]
		var r: Dictionary = w.usar_poder("sonho", adulto["x"], 0.8)
		var sug: Array = w.sugestoes()
		var ruins := sug.filter(func(s): return not w.pessoa(s["id"]).vivo or s["motivo"] == "")
		var sonhador := sug.filter(func(s): return s["id"] == r.get("alvo", -2))
		conferir("QA-083", not sonhador.is_empty() and ruins.is_empty(), "depois do sonho, quem sonhou é sugerido (%s); %d sugestões, todas vivas e com motivo" % [sonhador[0]["motivo"] if not sonhador.is_empty() else "não", sug.size()])


func _descendente_mais_velho(m, id: int) -> int:
	var fila: Array = m.pessoa(id).filhos.duplicate()
	while not fila.is_empty():
		var vivos := []
		var seguinte := []
		for f in fila:
			var p = m.pessoa(f)
			if p.vivo:
				vivos.append(p)
			seguinte.append_array(p.filhos)
		if not vivos.is_empty():
			vivos.sort_custom(func(a, b): return a.nasc_ano < b.nasc_ano or (a.nasc_ano == b.nasc_ano and a.id < b.id))
			return vivos[0].id
		fila = seguinte
	return -1


# ---------------------------------------------------------------- 9. ausência

func _bloco_ausencia() -> void:
	var m := Mundo.new(7)
	m.avancar_dias(40 * 10)
	var c := _caminho("ausencia")
	_apagar_mundo(c)
	Persistencia.salvar(m, c)
	var salvo: int = Persistencia.carregar(c).salvo_em
	var h := 3600
	if _quer("QA-090") or _quer("QA-094"):
		var r = Persistencia.carregar_e_avancar(c, salvo + 16 * h)
		var aus: Dictionary = r["ausencia"]
		conferir("QA-090", aus["passos"] == 512 and not aus["teto_atingido"], "16 horas fora = 512 passos (%d), %d dias" % [aus["passos"], aus["passos"] / 24])
		var rel: String = aus["relato"]
		conferir("QA-094", rel.strip_edges() != "" and not rel.contains("{") and not rel.contains("nada de notável") and not rel.contains("%"),
			"o relato é uma crônica sem modelo vazio (%d caracteres)" % rel.length())
		info("relato de 16 h: " + rel.substr(0, 300).replace("\n", " "))
	if _quer("QA-091"):
		var aus: Dictionary = Persistencia.carregar_e_avancar(c, salvo + 30 * 24 * h)["ausencia"]
		conferir("QA-091", aus["passos"] == 960 and aus["teto_atingido"], "30 dias fora param no teto: %d passos, teto %s" % [aus["passos"], aus["teto_atingido"]])
	if _quer("QA-092"):
		var aus: Dictionary = Persistencia.carregar_e_avancar(c, salvo + int(960 * Mundo.SEGUNDOS_POR_PASSO))["ausencia"]
		conferir("QA-092", aus["passos"] == 960 and aus["teto_atingido"], "exatamente um ano fora: %d passos, teto atingido = %s" % [aus["passos"], aus["teto_atingido"]])
	if _quer("QA-093"):
		var w = Persistencia.carregar(c)
		var antes: Dictionary = w.tempo()
		var aus: Dictionary = w.avancar_ausencia(-3 * 24 * h)
		conferir("QA-093", aus["passos"] == 0 and w.tempo()["passo"] == antes["passo"], "relógio 3 dias para trás: nenhum passo, nada quebra")
		var r = Persistencia.carregar_e_avancar(c, salvo - 400 * 24 * h)
		conferir("QA-093", r != null and r["ausencia"]["passos"] == 0, "salvamento um ano «no futuro»: abre, sem avançar")
		var rel: String = r["ausencia"]["relato"] if r != null else ""
		info("relato com 0 passos: «%s»" % rel.strip_edges().substr(0, 200))
		conferir("QA-093", not rel.contains("{") and not rel.contains("%"), "relato de 0 passos sem modelo vazio")
	if _quer("QA-095") or _quer("QA-096"):
		var t := Time.get_ticks_msec()
		var aus: Dictionary = Persistencia.carregar_e_avancar(c, salvo + 5 * 365 * 24 * h)["ausencia"]
		var seg := (Time.get_ticks_msec() - t) / 1000.0
		conferir("QA-095", aus["passos"] == 960, "5 anos fora avançam só 1 ano (%d passos)" % aus["passos"])
		conferir("QA-096", seg < 3.0, "carregar e avançar um ano leva %.2f s" % seg)
	if _quer("QA-097"):
		var w := Mundo.new(7)
		w.avancar_dias(40 * 10)
		# Preparação (gancho interno): resta uma pessoa, muito fraca.
		var vivos: Array = w.vivos.keys()
		vivos.sort()
		for id in vivos.slice(1):
			w._morrer(w.pessoas[id], "doenca")
		w.pessoas[vivos[0]].saude = 0.02
		w.pessoas[vivos[0]].doente = 30
		var cw := _caminho("aus_fim")
		_apagar_mundo(cw)
		Persistencia.salvar(w, cw)
		var r = Persistencia.carregar_e_avancar(cw, Persistencia.carregar(cw).salvo_em + 40 * 24 * h)
		var aus: Dictionary = r["ausencia"]
		var tipos: Array = aus["chamados"].map(func(e): return e["tipo"])
		conferir("QA-097", tipos.has("fim_do_mundo"), "a extinção na ausência vem nos chamados: %s" % [tipos])
		conferir("QA-097", r["mundo"].fim_do_mundo and r["mundo"].livros.size() == 1, "o mundo volta vazio, com o livro fechado")
		info("relato da extinção: " + aus["relato"].substr(0, 400).replace("\n", " "))
		_apagar_mundo(cw)
	_apagar_mundo(c)


# ---------------------------------------------------------------- 10. persistência

func _bloco_persistencia() -> void:
	if _quer("QA-100") or _quer("QA-101"):
		var a := Mundo.new(1)
		a.avancar_dias(40 * 20 + 7)
		for i in 5:
			a.avancar_hora()
		a.usar_poder("chuva", 150.0, 0.6)
		var cont := Mundo.new(1)
		cont.avancar_dias(40 * 20 + 7)
		for i in 5:
			cont.avancar_hora()
		cont.usar_poder("chuva", 150.0, 0.6)
		var c := _caminho("ida_volta")
		_apagar_mundo(c)
		var antes_s := int(Time.get_unix_time_from_system())
		conferir("QA-100", Persistencia.salvar(a, c), "salvar")
		var b = Persistencia.carregar(c)
		conferir("QA-100", b != null, "carregar")
		if b != null:
			b.avancar_dias(40 * 10)
			cont.avancar_dias(40 * 10)
			conferir("QA-100", b.cronica() == cont.cronica() and b.rng.state == cont.rng.state and b.eventos.size() == cont.eventos.size(),
				"o mundo carregado segue igual ao que nunca parou, 10 anos depois")
			var txt := FileAccess.get_file_as_string(c)
			conferir("QA-101", txt.begins_with("# Simulador de vida: mundo salvo.") and b.salvo_em >= antes_s,
				"arquivo de texto com cabeçalho e hora real do salvamento (%d)" % b.salvo_em)
		_apagar_mundo(c)
	if _quer("QA-102") or _quer("QA-103") or _quer("QA-106"):
		_corrompidos()
	if _quer("QA-104") or _quer("QA-105"):
		_versao_futura()
	if _quer("QA-107"):
		var m := Mundo.new(2)
		m.avancar_dias(40 * 5)
		var c := _caminho("async")
		_apagar_mundo(c)
		Persistencia.salvar_async(m, c)
		m.avancar_hora()
		m.usar_poder("chuva", 260.0, 0.4)
		var ok: bool = Persistencia.terminar_salvamento(m)
		var b = Persistencia.carregar(c)
		conferir("QA-107", ok and b != null and b.tempo()["passo"] == m.tempo()["passo"] - 1, "salvar_async com o mundo avançando: arquivo válido do passo de antes")
		_apagar_mundo(c)
	if _quer("QA-108"):
		var pasta := TMP.path_join("estante_corrompida")
		var l1 := {"era": 1, "titulo": "A Primeira Era: teste", "ano_ini": 1, "ano_fim": 10, "semente": 1, "texto": "# A Primeira Era: teste\n\nUm."}
		var l2 := {"era": 2, "titulo": "A Segunda Era: teste", "ano_ini": 11, "ano_fim": 20, "semente": 1, "texto": "# A Segunda Era: teste\n\nDois."}
		Estante.guardar(l1, pasta)
		Estante.guardar(l2, pasta)
		for n in [0, 1, 2, 3]:
			var arq := pasta.path_join("indice.txt") if n == 0 else Arquivo.copia(pasta.path_join("indice.txt"), n)
			if FileAccess.file_exists(arq):
				var f := FileAccess.open(arq, FileAccess.WRITE)
				f.store_string("lixo00010002")
				f.close()
		var lv := Estante.livros(pasta)
		conferir("QA-108", lv.size() == 2 and Estante.ler(lv[1]["id"], pasta).contains("Dois"), "índice e cópias estragados: a estante se refaz com %d livros" % lv.size())
	if _quer("QA-109"):
		var w := Mundo.new(2)
		w.avancar_dias(40 * 5)
		for g in w.grupos_vivos():
			for id in g.membros.duplicate():
				w._morrer(w.pessoas[id], "doenca")
		w.avancar_dias(1)
		var antes := Estante.livros().size()
		var c := TMP.path_join("isolado/mundo.txt")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP.path_join("isolado")))
		Persistencia.salvar(w, c)
		var depois := Estante.livros().size()
		conferir("QA-109", depois == antes, "salvar um mundo de teste em %s não escreve na estante padrão user://estante (%d → %d livros)" % [c, antes, depois])
		_apagar_mundo(c)
		_limpar_pasta("user://estante")
	if _quer("QA-111"):
		# O mesmo arquivo, carregado várias vezes e avançado do mesmo jeito, tem de dar o mesmo mundo
		# e a mesma crônica (documento técnico: determinismo; API: "um mundo salvo e carregado segue igual").
		var m := Mundo.new(7)
		m.avancar_dias(40 * 10)
		var c := _caminho("det")
		_apagar_mundo(c)
		Persistencia.salvar(m, c)
		var textos := {}
		var sorteios := {}
		for i in 6:
			var w = Persistencia.carregar(c)
			var vivos: Array = w.vivos.keys()
			vivos.sort()
			for id in vivos.slice(1):
				w._morrer(w.pessoas[id], "doenca")   # preparação (gancho interno), igual nas 6 vezes
			w.pessoas[vivos[0]].saude = 0.02
			w.pessoas[vivos[0]].doente = 30
			var rel: String = w.avancar_ausencia(40 * 24 * 3600)["relato"]
			textos[rel] = true
			sorteios[w.rng.state] = true
		conferir("QA-111", sorteios.size() == 1, "6 cargas do mesmo arquivo: o mesmo sorteio no fim (%d estados)" % sorteios.size())
		conferir("QA-111", textos.size() == 1, "e a mesma crônica (%d textos diferentes)" % textos.size())
		_apagar_mundo(c)
	if _quer("QA-110"):
		pular("QA-110", "o arquivo dos antigos só nasce depois de 300 anos; coberto por testar_persistencia.gd e testar_antigos.gd da A")


func _escrever(caminho: String, conteudo) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if conteudo is PackedByteArray:
		f.store_buffer(conteudo)
	else:
		f.store_string(conteudo)
	f.close()


func _corrompidos() -> void:
	var m := Mundo.new(3)
	m.avancar_dias(40 * 3)
	var c := _caminho("corrompido")
	var bom := ""
	var bin := PackedByteArray()
	for i in 4096:
		bin.append((i * 7919 + 13) % 256)
	var estragos := {
		"cortado ao meio": func(t: String): return t.substr(0, t.length() / 2),
		"vazio": func(_t: String): return "",
		"lixo": func(_t: String): return "isto não é um mundo\n{[(" ,
		"só o cabeçalho": func(t: String): return t.get_slice("\n", 0) + "\n",
		"sem os 10 últimos caracteres": func(t: String): return t.substr(0, t.length() - 10),
		"binário": func(_t: String): return bin,
		"cabeçalho trocado": func(t: String): return "# Outro jogo\n" + t.split("\n", true, 1)[1],
	}
	for nome in estragos:
		_apagar_mundo(c)
		Persistencia.salvar(m, c)
		m.avancar_hora()
		Persistencia.salvar(m, c)   # agora mundo.1.txt é o bom anterior
		bom = FileAccess.get_file_as_string(c)
		_escrever(c, estragos[nome].call(bom))
		var b = Persistencia.carregar(c)
		conferir("QA-102", b != null and b.recuperado_de.ends_with(".1.txt"), "mundo %s: volta da cópia (%s)" % [nome, b.recuperado_de if b != null else "null"])
		var r = Persistencia.carregar_e_avancar(c, int(Time.get_unix_time_from_system()) + 3600)
		conferir("QA-102", r != null and r["ausencia"]["relato"].begins_with("*O mundo salvo estava estragado"), "mundo %s: o relato avisa o jogador" % nome)
	# Todas as cópias estragadas.
	_apagar_mundo(c)
	for i in 4:
		Persistencia.salvar(m, c)
		m.avancar_hora()
	for n in [0, 1, 2, 3]:
		var arq := c if n == 0 else Arquivo.copia(c, n)
		_escrever(arq, "lixo")
	conferir("QA-103", Persistencia.carregar(c) == null, "mundo e 3 cópias estragados: carregar devolve null sem quebrar")
	conferir("QA-103", Persistencia.carregar_e_avancar(c) == null, "e carregar_e_avancar também")
	# Só as cópias.
	_apagar_mundo(c)
	Persistencia.salvar(m, c)
	m.avancar_hora()
	Persistencia.salvar(m, c)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(c))
	var b = Persistencia.carregar(c)
	conferir("QA-106", Persistencia.existe(c) and b != null and b.recuperado_de != "", "sem mundo.txt, só cópias: existe e volta da cópia")
	_apagar_mundo(c)


## Um mundo salvo por uma versão mais nova do jogo: o núcleo não o lê. O que acontece com ele
## quando a apresentação (simulacao.gd) cria um mundo novo e passa a salvar todo dia?
func _versao_futura() -> void:
	var m := Mundo.new(3)
	m.avancar_dias(40 * 2)
	var c := _caminho("futuro")
	_apagar_mundo(c)
	for i in 4:
		Persistencia.salvar(m, c)
		m.avancar_hora()
	var marca := "[\"versao\", %d]" % Persistencia.VERSAO
	var trocados := 0
	for n in [0, 1, 2, 3]:
		var arq := c if n == 0 else Arquivo.copia(c, n)
		var t := FileAccess.get_file_as_string(arq)
		if t.contains(marca):
			trocados += 1
		_escrever(arq, t.replace(marca, "[\"versao\", 99]"))
	if not conferir("QA-104", trocados == 4, "preparação: os 4 arquivos marcados como versão 99"):
		return
	var b = Persistencia.carregar(c)
	conferir("QA-104", b == null, "um mundo de versão futura não é lido (e não volta de uma cópia velha)")
	conferir("QA-104", Persistencia.existe(c), "mas existe() continua verdadeiro: a apresentação sabe que havia um mundo")
	# O que simulacao.iniciar faz: carregar falhou, cria um mundo novo e salva (a cada dia e ao fechar).
	var novo := Mundo.new(77)
	for dia in 4:
		Persistencia.salvar(novo, c)
		novo.avancar_dias(1)
	var restam := 0
	for n in [0, 1, 2, 3]:
		var arq := c if n == 0 else Arquivo.copia(c, n)
		if FileAccess.file_exists(arq) and FileAccess.get_file_as_string(arq).contains("[\"versao\", 99]"):
			restam += 1
	conferir("QA-105", restam > 0, "depois de 4 dias salvos do mundo novo, o mundo ilegível sobrevive em algum arquivo (%d de 4)" % restam)
	_apagar_mundo(c)


# ---------------------------------------------------------------- 11. fim do mundo

func _bloco_fim() -> void:
	var m := Mundo.new(1)
	var ini := m.eventos.size()
	var raios := 0
	var dias := 0
	# Só os poderes, pela API pública: um raio de milagre sobre cada pessoa visível.
	while m.populacao() > 0 and dias < 60:
		for h in range(8, 18):
			_ate_hora(m, h)
			var vis: Array = m.pessoas_visiveis()
			if vis.is_empty():
				continue
			var alvo: int = vis[0]["id"]
			var x := m.posicao_de(alvo)
			if x >= 0.0:
				m.usar_poder("raio", x, 0.9)
				raios += 1
		m.avancar_dias(1)
		dias += 1
	_ate_hora(m, 6)
	if _quer("QA-120"):
		conferir("QA-120", m.populacao() == 0, "o deus acaba com o povo só com raios: %d raios em %d dias (restam %d)" % [raios, dias, m.populacao()])
	if m.populacao() > 0:
		# não deu pelos poderes: força pelo gancho interno, para testar o resto do fim
		for id in m.vivos.keys():
			m._morrer(m.pessoas[id], "doenca")
		m.avancar_dias(1)
	var t := _tipos(m, ini)
	if _quer("QA-121"):
		var ult := _eventos_tipo(m, "os_ultimos", ini)
		conferir("QA-121", not ult.is_empty() and ult[0]["camada"] == "chamado", "os últimos: chamado (%s)" % [ult[0]["dados"] if not ult.is_empty() else "nenhum"])
	if _quer("QA-122"):
		var fim := _eventos_tipo(m, "fim_do_mundo", ini)
		conferir("QA-122", not fim.is_empty() and m.fim_do_mundo, "fim_do_mundo registrado")
		conferir("QA-122", m.livros.size() == 1 and m.livros[0]["titulo"].begins_with("A Primeira Era"), "a crônica fecha como livro: «%s»" % (m.livros[0]["titulo"] if not m.livros.is_empty() else ""))
	if _quer("QA-143") and not m.livros.is_empty():
		var tx: String = m.livros[0]["texto"]
		conferir("QA-143", tx.contains("## Em resumo") and tx.contains("## Capítulo I") and tx.contains("*Aqui termina") and m.livros[0]["titulo"].contains(":"),
			"o livro da extinção tem epíteto, resumo, capítulos e epitáfio")
	var c := _caminho("vazio")
	_apagar_mundo(c)
	Persistencia.salvar(m, c)
	if _quer("QA-123"):
		var ruinas0: Array = m.ruinas_visiveis()
		var t0: Dictionary = m.tempo()
		m.avancar_dias(40 * 3)
		var ruinas1: Array = m.ruinas_visiveis()
		conferir("QA-123", m.tempo()["ano"] == t0["ano"] + 3, "o tempo segue no mundo vazio")
		conferir("QA-123", not ruinas1.is_empty() and ruinas1[0]["anos"] > ruinas0[0]["anos"], "as ruínas ficam e envelhecem (%d ruínas, %d → %d anos)" % [ruinas1.size(), ruinas0[0]["anos"] if not ruinas0.is_empty() else -1, ruinas1[0]["anos"] if not ruinas1.is_empty() else -1])
		var r: Dictionary = m.usar_poder("chuva", 260.0, 0.8)
		conferir("QA-123", not r.get("ok", true), "os poderes devolvem ok falso: %s" % r.get("motivo", ""))
		conferir("QA-123", m.clima().has("seca"), "o clima continua")
	if _quer("QA-124") or _quer("QA-126") or _quer("QA-127"):
		var r: Dictionary = m.criar_povo(260.0)
		conferir("QA-124", r.get("ok", false) and m.era == 2 and m.populacao() == 12, "criar povo no mundo vazio: era %d, %d pessoas" % [m.era, m.populacao()])
		conferir("QA-124", not m.criar_povo(260.0).get("ok", true), "criar povo num mundo habitado é recusado")
		var ini2 := m.eventos.size()
		m.avancar_dias(40 * 15)
		var t2 := _tipos(m, ini2)
		conferir("QA-126", t2.has("mito_ruinas"), "o povo novo explica as ruínas (%d mitos)" % t2.get("mito_ruinas", 0))
		if t2.has("ruinas_saber"):
			conferir("QA-127", true, "aprendeu nas ruínas")
		else:
			pular("QA-127", "o primeiro povo não passou do estágio 1: não havia saber nas ruínas")
	if _quer("QA-131"):
		# O último morre às 10h (pelo raio do deus): o mundo vazio deve valer já, e não à meia-noite.
		var w := Mundo.new(1)
		_ate_hora(w, 10)
		var vivos: Array = w.vivos.keys()
		vivos.sort()
		for id in vivos.slice(1):
			w._morrer(w.pessoas[id], "doenca")   # preparação (gancho interno): resta um
		var ultimo: int = vivos[0]
		var r: Dictionary = {}
		for tentativa in 6:
			w.pessoas_visiveis()
			r = w.usar_poder("raio", w.pessoas_visiveis()[0]["x"] if w.populacao() > 0 else 260.0, 0.9)
			if w.populacao() == 0:
				break
			w.avancar_hora()
		var hora_morte: int = w.tempo()["hora"]
		conferir("QA-131", w.populacao() == 0, "o raio mata o último às %dh" % hora_morte)
		w.avancar_hora()
		var r_morto: Dictionary = w.usar_poder("chuva", 260.0, 0.8)
		info("poder sobre o mundo sem ninguém, antes da meia-noite: %s" % [r_morto])
		conferir("QA-131", not r_morto.get("ok", true), "sem ninguém vivo, o poder já é recusado (ok %s)" % r_morto.get("ok", "?"))
		var vazio_ja: bool = w.fim_do_mundo
		var criar: Dictionary = w.criar_povo(260.0) if not vazio_ja else {"ok": true}
		var horas := 1
		while not w.fim_do_mundo and horas < 30:
			w.avancar_hora()
			horas += 1
		conferir("QA-131", vazio_ja, "1 hora depois da última morte, o mundo já está vazio (fim_do_mundo %s; só veio depois de %d horas, às %dh)" % [vazio_ja, horas, w.tempo()["hora"]])
		conferir("QA-131", criar.get("ok", false), "e criar povo já funciona (%s)" % criar.get("motivo", "ok"))
	if _quer("QA-125"):
		var w := Mundo.new(2)
		for id in w.vivos.keys():
			w._morrer(w.pessoas[id], "doenca")
		w.avancar_dias(1)
		var r: Dictionary = w.criar_povo(50.0)
		conferir("QA-125", r.get("ok", false) and w.grupo(r["grupo"]).zona == "praia", "povo criado no lago nasce na praia (%s)" % (w.grupo(r["grupo"]).zona if r.get("ok", false) else "?"))
	if _quer("QA-128"):
		var b = Persistencia.carregar(c)
		conferir("QA-128", b != null and b.fim_do_mundo and b.populacao() == 0 and b.livros.size() == 1 and b.era == 1, "o mundo vazio salvo volta vazio, com o livro")
		if b != null:
			conferir("QA-128", b.criar_povo(300.0).get("ok", false) and b.era == 2, "e aceita o povo novo depois de carregado")
	_apagar_mundo(c)


# ---------------------------------------------------------------- 12. estante e abandono

func _bloco_estante() -> void:
	_limpar_pasta("user://estante")
	var m := Mundo.new(9)
	m.avancar_dias(40 * 6)
	var c := _caminho("abandono")
	_apagar_mundo(c)
	Persistencia.salvar(m, c)
	m.avancar_hora()
	Persistencia.salvar(m, c)
	var livro: Dictionary = Persistencia.abandonar(m, c)
	var restos := [c, Arquivo.copia(c, 1), Arquivo.copia(c, 2), Persistencia.caminho_antigos(c)].filter(func(x): return FileAccess.file_exists(x))
	var est := Estante.livros()
	if _quer("QA-140"):
		conferir("QA-140", livro.get("titulo", "").begins_with("A Primeira Era"), "abandonar fecha a crônica como livro: «%s»" % livro.get("titulo", ""))
		conferir("QA-140", est.size() == 1, "o livro vai para a estante (%d)" % est.size())
		conferir("QA-140", restos.is_empty(), "o mundo salvo e as cópias foram apagados (%s)" % [restos])
	if _quer("QA-141"):
		var novo := Mundo.new(10)
		novo.avancar_dias(3)
		var est2 := Estante.livros()
		conferir("QA-141", est2.size() == 1 and Estante.ler(est2[0]["id"]).begins_with("# A Primeira Era"), "com outro mundo, o livro continua lá e se lê")
	if _quer("QA-144"):
		var w := Mundo.new(11)
		w.avancar_dias(40 * 2)
		var c2 := _caminho("abandono2")
		Persistencia.salvar(w, c2)
		Persistencia.abandonar(w, c2)
		var est3 := Estante.livros()
		conferir("QA-144", est3.size() == 2 and est3[0]["id"] != est3[1]["id"], "dois abandonos, dois livros com ids diferentes")
		_apagar_mundo(c2)
	if _quer("QA-142") and not est.is_empty():
		var id: String = est[0]["id"]
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://estante/" + id + ".md"))
		conferir("QA-142", Estante.ler(id).begins_with("# A Primeira Era"), "o livro sem o arquivo principal se lê pela cópia")
	_limpar_pasta("user://estante")


# ---------------------------------------------------------------- 16. guerra (TDD para A)

## Um ataque registrado às 8h (forçado como faz `--cenario-raro=batalha`) deve virar a cena
## `guerra` 2 horas depois (API, cenas_ativas: começa em hora + 2, luta de hora + 3h30 a hora + 5h).
func _bloco_guerra() -> void:
	if not _quer("QA-180") and not _quer("QA-034"):
		return
	var m := Mundo.new(SEMENTE_LONGA)
	m.avancar_dias(40 * 60)
	if m.grupos_vivos().size() < 2:
		pular("QA-180", "a semente %d não tem dois povos no ano 60" % SEMENTE_LONGA)
		return
	if _quer("QA-034"):
		_guardar("guerra60", m)
		var w = _abrir("guerra60")
		var a = w.grupos_vivos()[0]
		var b = w.grupos_vivos()[1]
		# preparação (gancho interno, como o cenário "guerra" da apresentação): guerra e hostilidade
		w._comecar_guerra(a, b, a.zona)
		a.hostilidade[b.id] = 4.0
		b.hostilidade[a.id] = 4.0
		var antes: int = w.guerras_ativas().size()
		var ini: int = w.eventos.size()
		var r: Dictionary = w.usar_poder("erguer", _fogo(w, a.id), 0.8)
		var t := _tipos(w, ini)
		var nomes := []
		for z in w.zonas_visiveis():
			if z["chave"] == a.zona:
				nomes = z["nomes"].values().map(func(n): return str(n))
		var em_tregua: bool = a.tregua_ate.get(b.id, -1) > w.dia_abs()
		conferir("QA-034", r.get("grau", "") == "milagre" and em_tregua, "terra erguida de milagre entre povos em guerra força a trégua (%d guerras antes; eventos %s)" % [antes, t.keys()])
		conferir("QA-034", not nomes.is_empty(), "e nasce um lugar com nome: %s" % [nomes])
	if not _quer("QA-180"):
		return
	_ate_hora(m, 6)
	for h in 2:   # a apresentação consulta a cada passo
		m.pessoas_visiveis()
		m.cenas_ativas()
		m.avancar_hora()
	m.pessoas_visiveis()
	var vivos: Array = m.grupos_vivos()
	var hora_ataque: int = m.tempo()["hora"]
	m._atacar(vivos[0], vivos[1])   # o mesmo gancho de cenarios_raros.gd ("batalha")
	var vista := {}
	var guerra := {}
	for i in 8:
		m.avancar_hora()
		m.pessoas_visiveis()
		for cena in m.cenas_ativas():
			if cena["tipo"] == "guerra" and guerra.is_empty():
				guerra = cena
				vista = m.tempo()
	if guerra.is_empty():
		conferir("QA-180", false, "ataque às %dh: nenhuma cena de guerra nas 8 horas seguintes" % hora_ataque)
		return
	info("cena de guerra: ini %.2f, fim %.2f, vista primeiro na hora %d" % [guerra["ini"], guerra["fim"], vista["hora"]])
	conferir("QA-180", absf(float(guerra["ini"]) - (hora_ataque + 2)) <= 0.5, "ataque às %dh: a cena começa às %dh (veio %.2f)" % [hora_ataque, hora_ataque + 2, guerra["ini"]])
	conferir("QA-180", absf(float(guerra["fim"]) - (hora_ataque + 6.5)) <= 0.5, "e termina às %.1fh (veio %.2f)" % [hora_ataque + 6.5, guerra["fim"]])


# ---------------------------------------------------------------- inspeção do código

func _bloco_inspecao() -> void:
	if _quer("QA-150"):
		var achou := []
		for f in DirAccess.get_files_at("res://nucleo"):
			if f.ends_with(".gd") and FileAccess.get_file_as_string("res://nucleo/" + f).to_lower().contains("discreto"):
				achou.append(f)
		conferir("QA-150", achou.is_empty(), "o núcleo não conhece o modo discreto: a crônica é a mesma com ele ligado %s" % [achou])
	if _quer("QA-181"):
		var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
		var linha := ""
		for l in cfg.split("\n"):
			if l.begins_with("exclude_filter="):
				linha = l
		conferir("QA-181", linha.contains("qa/"), "a exportação exclui qa/ (%s)" % linha)
	if _quer("QA-182"):
		var perigosos := []
		for f in DirAccess.get_files_at("res://ferramentas_sim"):
			if not f.ends_with(".gd"):
				continue
			var t := FileAccess.get_file_as_string("res://ferramentas_sim/" + f)
			if t.contains("\"user://estante\"") and (t.contains(".remove(") or t.contains("remove_absolute")):
				perigosos.append(f)
		conferir("QA-182", perigosos.is_empty(), "nenhuma ferramenta de teste apaga a estante real do jogador (apagam: %s)" % [perigosos])
	if _quer("QA-166"):
		var achou := false
		for f in DirAccess.get_files_at("res://apresentacao"):
			if f.ends_with(".gd"):
				var t := FileAccess.get_file_as_string("res://apresentacao/" + f)
				if t.contains("config/version") or t.contains("versao_do_jogo") or t.contains("\"v0.") or t.contains("0.1.0"):
					achou = true
		conferir("QA-166", achou, "a apresentação mostra o número da versão (busca por config/version no código)")
	if _quer("QA-174"):
		var p := FileAccess.get_file_as_string("res://project.godot")
		conferir("QA-174", p.contains("run/max_fps=30"), "no máximo 30 quadros por segundo (project.godot)")

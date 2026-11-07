extends SceneTree
## Cenários do painel da população (QA-220 a QA-227), escritos antes do painel, pela regra de TDD.
## Abre o jogo inteiro (principal.tscn), clica e aperta teclas por Viewport.push_input (sem o mouse nem
## o teclado reais) e lê o painel, a vista e o núcleo.
##
## Uso (da raiz do repositório):
##   Godot_console.exe --headless --path jogo --script res://qa/populacao/testar_populacao.gd
##
## Cada etapa roda num processo próprio, com APPDATA em %TEMP%/simvida_qa_populacao/<etapa>: nunca na
## pasta de dados do jogador. Os jogos abrem calados (--sem-som) e sem gravar nada (--sem-config).
##
## O contrato (proposto à B, revisável):
## - o botão de id "populacao" na alça (interface.botoes); a dica dele traz o total do mundo e a tecla
##   entre parênteses, por exemplo "População: 42 (X)";
## - o painel em interface._populacao, com visible, nivel (1 povos, 2 habitantes), povo (o gid do nível 2,
##   ou -1), total (o número do topo), linhas (o que está listado, na ordem da tela), ponto_da_linha(i)
##   (o centro da linha em coordenadas da janela base, ou Vector2(-1, -1) fora da área visível),
##   ponto_do_voltar(), rolagem e rolagem_max();
## - nível 1: {id, nome, membros, zona, estagio, deus}, um por povo vivo; nível 2: {id, nome, idade, papel},
##   na ordem líder, sacerdote, adultos do mais velho ao mais novo e, por último, as crianças (idade < 12);
##   sem fé individual nem números internos;
## - clicar numa pessoa faz como a caixa de preces: o painel fecha, vista.foco == id e vista.zoom == 2;
## - o total do topo e o da dica acompanham populacao() até a hora seguinte do jogo;
## - se o povo aberto no nível 2 se extingue, o painel volta ao nível 1 sem erro de script;
## - a tecla do painel é nova: abre e fecha o painel e não muda mais nada.
##
## O teste também aceita os nomes que a B usa no painel (apresentacao/povos_tela.gd): o botão "povos", o
## painel em interface._povos, modo "povos"/"pessoas" no lugar de nivel, as listas povos e pessoas, a
## "linha" de texto do povo ("a floresta, agricultura, crê em …"), o papel como "líder", "sacerdote",
## "sacerdotisa" ou "criança", e a geometria das linhas (CAIXA, LISTA_TOPO, _altura_item(), _rolagem,
## VOLTAR) quando não há ponto_da_linha().

const MARCA := "simvida_qa_populacao"
const BASE_ARGS := ["--sem-foco", "--sem-atalho", "--sem-som", "--sem-config"]
const ETAPAS := [
	["vazio", ["--mundo-novo"]],
	["dados", ["--mundo-novo", "--com-povo", "--semente=7"]],
	["extinto", ["--semente=3", "--anos=25"]],
	["grande", ["--semente=3", "--anos=225"]],
]
const NOMES := {
	"QA-220": "o botão da população está na alça, e a dica traz o total do mundo e a tecla",
	"QA-221": "o nível 1 lista cada povo vivo, com nome, tamanho, lugar, estágio e deus",
	"QA-222": "o nível 2 lista as pessoas do povo na ordem combinada, e o voltar retorna",
	"QA-223": "clicar numa pessoa leva a vista até ela",
	"QA-224": "o total muda na hora seguinte quando alguém nasce ou morre",
	"QA-225": "o povo aberto no nível 2 se extingue, e o painel volta ao nível 1 sem erro",
	"QA-226": "um povo de mais de 100 pessoas tem rolagem, e a última pessoa é alcançável",
	"QA-227": "a tecla do painel é nova e não muda mais nada",
}
## As teclas que o jogo já usava antes do painel (interface.tecla e moldura._unhandled_input, na 0.3.0).
const TECLAS_ANTIGAS := ["C", "E", "L", "D", "S", "P", "M", "H", "Q", "F8", "0", "1", "2", "3", "4", "Space",
	"Escape", "Left", "Right", "Up", "Down", "PageUp", "PageDown"]
const CHAVES_POVO := ["id", "nome", "membros", "zona", "estagio", "deus"]
const CHAVES_PESSOA := ["id", "nome", "idade", "papel"]

var moldura: Node
var erros: Array = []
var _logger


class Captura extends Logger:
	var dono

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
		if error_type != 1:
			dono.erros.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


# ---------------------------------------------------------------- o processo pai: roda as etapas

func _initialize() -> void:
	var etapa := OS.get_environment("SIMVIDA_QA_POPULACAO")
	if etapa == "":
		_rodar_etapas()
		return
	if not OS.get_user_data_dir().contains(MARCA):
		print("RES QA-000 FALHOU a etapa %s não está isolada: user:// = %s" % [etapa, OS.get_user_data_dir()])
		quit(2)
		return
	_logger = Captura.new()
	_logger.dono = self
	OS.add_logger(_logger)
	call_deferred("_etapa", etapa)


func _rodar_etapas() -> void:
	var raiz := OS.get_environment("TEMP").path_join(MARCA)
	var res := {}
	for e in ETAPAS:
		var dir: String = raiz.path_join(e[0])
		_limpar(dir)   # só as pastas desta bateria, em %TEMP%
		DirAccess.make_dir_recursive_absolute(dir)
		OS.set_environment("APPDATA", dir)
		OS.set_environment("SIMVIDA_QA_POPULACAO", e[0])
		var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
			"res://qa/populacao/testar_populacao.gd", "--"]
		a.append_array(BASE_ARGS + e[1])
		var saida: Array = []
		var t0 := Time.get_ticks_msec()
		OS.execute(OS.get_executable_path(), a, saida, true)
		print("[etapa %s] %.1f s" % [e[0], (Time.get_ticks_msec() - t0) / 1000.0])
		for bloco in saida:
			for linha in _de_cp1252(str(bloco)).split("\n"):
				if linha.begins_with("RES "):
					var p := linha.split(" ", false, 3)
					var id := p[1]
					var antes: String = res.get(id, {}).get("estado", "")
					var estado := p[2]
					if antes == "FALHOU" or (antes == "PASSOU" and estado == "PULADO"):
						estado = antes
					if not res.has(id):
						res[id] = {"notas": []}
					res[id]["estado"] = estado
					res[id]["notas"].append("[%s] %s %s" % [e[0], p[2], p[3] if p.size() > 3 else ""])
				elif linha.begins_with("[populacao-qa]"):
					print("  ", linha)
	OS.set_environment("SIMVIDA_QA_POPULACAO", "")
	var falhas := 0
	var ids := NOMES.keys()
	ids.sort()
	var cont := {"PASSOU": 0, "FALHOU": 0, "PULADO": 0}
	for id in ids:
		var r: Dictionary = res.get(id, {"estado": "FALHOU", "notas": ["nenhuma etapa testou"]})
		cont[r["estado"]] += 1
		if r["estado"] == "FALHOU":
			falhas += 1
		print("%s %s  %s" % [r["estado"], id, NOMES[id]])
		for n in r["notas"]:
			print("      ", n)
	print("RESUMO população: %d passam, %d falham, %d pulados" % [cont["PASSOU"], cont["FALHOU"], cont["PULADO"]])
	quit(1 if falhas > 0 else 0)


func _limpar(pasta: String) -> void:
	if not pasta.contains(MARCA):
		return
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	for d in dir.get_directories():
		_limpar(pasta.path_join(d))
		dir.remove(d)


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
			return s
	return bytes.get_string_from_utf8()


# ---------------------------------------------------------------- uma etapa (processo filho)

func _res(id: String, ok: bool, texto: String) -> void:
	print("RES %s %s %s" % [id, "PASSOU" if ok else "FALHOU", texto])


func _pulado(id: String, texto: String) -> void:
	print("RES %s PULADO %s" % [id, texto])


func _etapa(etapa: String) -> void:
	moldura = load("res://principal.tscn").instantiate()
	root.add_child(moldura)
	await process_frame
	# o mundo de muitos anos leva alguns segundos para ficar pronto
	var limite := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < limite and (_sim() == null or (etapa != "vazio" and _mundo().populacao() == 0)):
		await process_frame
	await _esperar(0.5)
	if _sim() == null:
		for id in NOMES:
			_res(id, false, "o jogo não abriu o mundo em 180 s")
		quit(0)
		return
	if _painel() == null or _botao(_id_botao()).is_empty():
		var falta := "não há botão de id \"populacao\" (nem \"povos\") na alça (há %s)" % [_ids()] if _botao(_id_botao()).is_empty() else "não há interface._populacao (nem _povos)"
		for id in NOMES:
			_res(id, false, falta)
		quit(0)
		return
	match etapa:
		"vazio":
			await _vazio()
		"dados":
			await _dados()
		"extinto":
			await _extinto()
		"grande":
			await _grande()
	if not erros.is_empty():
		print("[populacao-qa] erros de script na etapa %s: %s" % [etapa, erros.slice(0, 5)])
	quit(0)


func _i() -> Node:
	return moldura.get("interface")


func _vista() -> Node:
	return moldura.get("vista")


func _sim():
	var v := _vista()
	return v.get("sim") if v != null else null


func _mundo():
	return _sim().mundo


func _painel() -> Node:
	if _i() == null:
		return null
	return _i().get("_populacao") if _i().get("_populacao") != null else _i().get("_povos")


func _id_botao() -> String:
	return "populacao" if not _botao("populacao").is_empty() else "povos"


func _nivel(p: Node) -> int:
	if p.get("nivel") != null:
		return int(p.get("nivel"))
	return 1 if String(p.get("modo")) == "povos" else 2


func _linhas(p: Node) -> Array:
	if p.get("linhas") != null:
		return p.get("linhas")
	return p.get("povos") if _nivel(p) == 1 else p.get("pessoas")


func _rolagem(p: Node) -> int:
	return int(p.get("rolagem")) if p.get("rolagem") != null else int(p.get("_rolagem"))


func _rolagem_max(p: Node) -> int:
	return int(p.call("rolagem_max")) if p.has_method("rolagem_max") else int(p.call("_rolagem_max"))


## O centro da linha i em coordenadas da janela base (480 × 178), ou Vector2(-1, -1) fora da área visível.
func _ponto_da_linha(p: Node, i: int) -> Vector2:
	if p.has_method("ponto_da_linha"):
		return p.call("ponto_da_linha", i)
	var caixa: Rect2i = p.get("CAIXA")
	var altura := int(p.call("_altura_item"))
	var y0: int = caixa.position.y + int(p.get("LISTA_TOPO"))
	var y: int = y0 + i * altura - _rolagem(p) + altura / 2
	if y < y0 or y >= y0 + int(p.call("_altura_lista")):
		return Vector2(-1, -1)
	return Vector2(caixa.position.x + 40, y + 18)


func _ponto_do_voltar(p: Node) -> Vector2:
	if p.has_method("ponto_do_voltar"):
		return p.call("ponto_do_voltar")
	return Vector2((p.get("VOLTAR") as Rect2i).get_center()) + Vector2(0, 18)


## O papel como o núcleo diz: "lider", "sacerdote" ou "".
static func _papel(texto) -> String:
	var t := String(texto).to_lower()
	if t in ["lider", "líder"]:
		return "lider"
	if t in ["sacerdote", "sacerdotisa"]:
		return "sacerdote"
	return ""


static func _sem_artigo(nome: String) -> String:
	for a in ["os ", "as ", "o ", "a "]:
		if nome.to_lower().begins_with(a):
			return nome.substr(a.length())
	return nome


func _ids() -> Array:
	return _i().get("botoes").map(func(b): return b.get("id", ""))


func _botao(id: String) -> Dictionary:
	if _i() == null or _i().get("botoes") == null:
		return {}
	for b in _i().get("botoes"):
		if b.get("id", "") == id:
			return b
	return {}


func _mover(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	root.push_input(m, true)


func _clicar(p: Vector2, botao := MOUSE_BUTTON_LEFT) -> void:
	_mover(p)
	for apertado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = p
		ev.global_position = p
		ev.button_index = botao
		ev.pressed = apertado
		root.push_input(ev, true)
	await process_frame


func _tecla(k: int) -> void:
	for apertado in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = apertado
		root.push_input(ev, true)
		await process_frame


func _esperar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame


func _abrir() -> void:
	if not _painel().visible:
		await _clicar(Vector2((_botao(_id_botao())["rect"] as Rect2i).get_center()))
		await _esperar(0.2)


## O texto da dica visível agora, ou "" se não há dica.
func _texto_da_dica() -> String:
	var d = _i().get("_dica")
	if d == null or not d.visible:
		return ""
	var linhas := []
	for l in _i().get("_dica_textos"):
		if l.visible:
			linhas.append(l.text)
	return " / ".join(linhas)


func _dica_do_botao() -> String:
	var r: Rect2i = _botao(_id_botao())["rect"]
	_mover(Vector2(r.get_center()) + Vector2(0, 1))
	await _esperar(0.3)
	_mover(Vector2(r.get_center()))
	await _esperar(0.3)
	return _texto_da_dica()


## A tecla entre parênteses na dica, como "(X)" ou "(F7)".
static func _tecla_da_dica(texto: String) -> String:
	var re := RegEx.new()
	re.compile("\\(([A-Z0-9]|F[0-9]{1,2})\\)")
	var m := re.search(texto)
	return m.get_string(1) if m != null else ""


## Avança o jogo até a próxima hora (em 50x, uns 1,3 s por hora de jogo).
func _proxima_hora() -> void:
	var sim = _sim()
	var antes: int = _mundo().passo
	sim.definir_ritmo(3)
	var limite := Time.get_ticks_msec() + 20000
	while _mundo().passo == antes and Time.get_ticks_msec() < limite:
		await process_frame
	await _esperar(0.1)
	sim.definir_ritmo(0)


## A ordem combinada do nível 2, pelos dados do núcleo: líder, sacerdote, adultos do mais velho ao mais
## novo, crianças. Devolve o tipo de cada id, para comparar sem depender da ordem entre iguais.
static func _ordem_esperada(fichas: Array) -> Array:
	var lider := fichas.filter(func(f): return f["papel"] == "lider")
	var sacerdote := fichas.filter(func(f): return f["papel"] == "sacerdote")
	var adultos := fichas.filter(func(f): return f["papel"] == "" and not f["crianca"])
	adultos.sort_custom(func(a, b): return int(a["idade"]) > int(b["idade"]))
	var criancas := fichas.filter(func(f): return f["papel"] == "" and f["crianca"])
	return lider + sacerdote + adultos + criancas


# ---------------------------------------------------------------- as etapas

## Mundo vazio: o botão existe, o painel abre com total 0 e sem povos, sem erro.
func _vazio() -> void:
	await _abrir()
	var p := _painel()
	_res("QA-220", p.visible and int(p.get("total")) == 0 and _linhas(p).is_empty() and erros.is_empty(),
		"mundo vazio: painel aberto=%s, total=%s, %d linhas, erros=%s" % [p.visible, p.get("total"), _linhas(p).size(), erros.slice(0, 2)])


func _dados() -> void:
	var m = _mundo()
	var p := _painel()
	# QA-220: a dica traz o total e a tecla
	var dica := await _dica_do_botao()
	var tecla := _tecla_da_dica(dica)
	_res("QA-220", dica.contains(str(m.populacao())) and tecla != "",
		"dica do botão: \"%s\" (total do mundo %d, tecla \"%s\")" % [dica, m.populacao(), tecla])
	# QA-221: o nível 1
	await _abrir()
	var visiveis: Array = m.grupos_visiveis()
	var linhas: Array = _linhas(p)
	var erros_n1 := []
	if _nivel(p) != 1:
		erros_n1.append("abriu no nível %s" % _nivel(p))
	var soma := 0
	for g in visiveis:
		soma += int(g["membros"])
	if int(p.get("total")) != m.populacao() or soma != m.populacao() or m.pessoas_visiveis().size() != m.populacao():
		erros_n1.append("total %s, populacao %d, soma dos povos %d, pessoas visíveis %d" % [p.get("total"), m.populacao(), soma, m.pessoas_visiveis().size()])
	if linhas.size() != visiveis.size():
		erros_n1.append("%d linhas para %d povos vivos" % [linhas.size(), visiveis.size()])
	for g in visiveis:
		var l = linhas.filter(func(x): return int(x.get("id", -1)) == int(g["id"]))
		if l.is_empty():
			erros_n1.append("o povo %s não está na lista" % g["nome"])
			continue
		var linha: Dictionary = l[0]
		var deus: String = g["nome_deus"] if g["nome_deus"] != "" else ("cético" if g["ceticos"] else "não crê")
		if linha.has("linha") and not linha.has("zona"):
			# a linha de texto da B: o nome e o tamanho à parte; o lugar, o estágio e o deus no texto
			var texto := String(linha["linha"])
			var nome_zona: String = p.get("NOME_ZONA").get(g["zona"], g["zona"]) if p.get("NOME_ZONA") != null else g["zona"]
			var nome_estagio: String = p.get("NOME_ESTAGIO").get(int(g["estagio"]), "") if p.get("NOME_ESTAGIO") != null else ""
			var deus_no_texto := _sem_artigo(deus) if g["nome_deus"] != "" and not g["ceticos"] else deus
			if str(linha.get("nome")) != str(g["nome"]) or int(linha.get("membros", -1)) != int(g["membros"]):
				erros_n1.append("%s: nome ou tamanho diferente (%s, %s)" % [g["nome"], linha.get("nome"), linha.get("membros")])
			for parte in [nome_zona, nome_estagio, deus_no_texto]:
				if parte != "" and not texto.contains(parte):
					erros_n1.append("%s: a linha \"%s\" não diz %s" % [g["nome"], texto, parte])
			continue
		var falta := CHAVES_POVO.filter(func(k): return not linha.has(k))
		if not falta.is_empty():
			erros_n1.append("%s sem %s" % [g["nome"], falta])
			continue
		var esperado := {"nome": g["nome"], "membros": g["membros"], "zona": g["zona"], "estagio": g["estagio"], "deus": deus}
		for k in esperado:
			if str(linha[k]) != str(esperado[k]):
				erros_n1.append("%s: %s = %s, esperado %s" % [g["nome"], k, linha[k], esperado[k]])
	_res("QA-221", erros_n1.is_empty(), "%d povos: %s" % [visiveis.size(), erros_n1.slice(0, 4) if not erros_n1.is_empty() else "cada linha bate com grupos_visiveis()"])
	# QA-222: o nível 2 do maior povo, a ordem e o voltar
	var maior: Dictionary = visiveis[0]
	for g in visiveis:
		if int(g["membros"]) > int(maior["membros"]):
			maior = g
	var k_maior := -1
	for k in linhas.size():
		if int(linhas[k].get("id", -1)) == int(maior["id"]):
			k_maior = k
	var erros_n2 := []
	if k_maior >= 0:
		await _clicar(_ponto_da_linha(p, k_maior))
		await _esperar(0.2)
	var pessoas: Array = _linhas(p)
	if _nivel(p) != 2 or int(p.get("povo")) != int(maior["id"]):
		erros_n2.append("o clique no povo %s abriu nivel=%s povo=%s" % [maior["nome"], _nivel(p), p.get("povo")])
	else:
		var fichas: Array = m.pessoas_visiveis().filter(func(f): return int(f["grupo"]) == int(maior["id"]))
		var por_id := {}
		for f in fichas:
			por_id[int(f["id"])] = f
		var ids_tela := pessoas.map(func(x): return int(x.get("id", -1)))
		var ids_nucleo := fichas.map(func(f): return int(f["id"]))
		ids_tela.sort()
		ids_nucleo.sort()
		if ids_tela != ids_nucleo:
			erros_n2.append("as pessoas da lista não são as de pessoas_visiveis() com grupo %d (%d e %d)" % [maior["id"], ids_tela.size(), ids_nucleo.size()])
		else:
			var esperada := _ordem_esperada(fichas)
			for k in pessoas.size():
				var fe: Dictionary = esperada[k]
				var ft: Dictionary = por_id[int(pessoas[k]["id"])]
				var mesmo_lugar: bool = ft["papel"] == fe["papel"] and ft["crianca"] == fe["crianca"] \
					and (ft["papel"] != "" or ft["crianca"] or int(ft["idade"]) == int(fe["idade"]))
				if not mesmo_lugar:
					erros_n2.append("posição %d: %s (%s, %d anos), esperado alguém como %s (%s, %d anos)" % [k, ft["nome"], ft["papel"], ft["idade"], fe["nome"], fe["papel"], fe["idade"]])
					break
			for x in pessoas:
				var falta := CHAVES_PESSOA.filter(func(c): return not x.has(c))
				if not falta.is_empty():
					erros_n2.append("pessoa %s sem %s" % [x.get("id"), falta])
					break
				if x.has("fe"):
					erros_n2.append("a lista expõe a fé de %s" % x["nome"])
					break
				var f: Dictionary = por_id[int(x["id"])]
				if str(x["nome"]) != str(f["nome"]) or int(x["idade"]) != int(f["idade"]) or _papel(x["papel"]) != str(f["papel"]):
					erros_n2.append("%s: nome, idade ou papel diferente do núcleo" % x["nome"])
					break
		await _clicar(_ponto_do_voltar(p))
		await _esperar(0.2)
		if _nivel(p) != 1:
			erros_n2.append("o voltar deixou no nível %s" % _nivel(p))
	_res("QA-222", erros_n2.is_empty(), "povo %s (%d pessoas): %s" % [maior["nome"], int(maior["membros"]), erros_n2.slice(0, 3) if not erros_n2.is_empty() else "a ordem e os campos certos, e o voltar volta"])
	# QA-223: clicar numa pessoa viva
	if k_maior >= 0:
		await _clicar(_ponto_da_linha(p, k_maior))
		await _esperar(0.2)
	var alvo := -1
	var lista: Array = _linhas(p)
	for k in lista.size():
		var pt: Vector2 = _ponto_da_linha(p, k)
		if pt.x >= 0 and k > 0:
			alvo = int(lista[k]["id"])
			await _clicar(pt)
			break
	await _esperar(0.3)
	var v := _vista()
	_res("QA-223", alvo >= 0 and not p.visible and int(v.get("foco")) == alvo and int(v.get("zoom")) == 2,
		"clique na pessoa %d: painel aberto=%s, vista.foco=%s, vista.zoom=%s" % [alvo, p.visible, v.get("foco"), v.get("zoom")])
	# QA-224: alguém morre e alguém nasce; na hora seguinte, o total do topo e o da dica acompanham
	await _abrir()
	if p.visible and _nivel(p) != 1:
		await _clicar(_ponto_do_voltar(p))
	var antes: int = m.populacao()
	m._esperar_threads()
	var vitima = m.pessoa(int(maior["lider"])) if int(maior["lider"]) >= 0 else null
	if vitima == null:
		vitima = m.pessoa(int(m.grupos_vivos()[0].membros[-1]))
	m._morrer(vitima, "doenca")
	await _proxima_hora()
	await _esperar(0.3)
	var depois_morte: int = m.populacao()
	var topo_morte := int(p.get("total"))
	var dica_morte := await _dica_do_botao()
	# e os nascimentos e mortes naturais por 30 horas de jogo: o total nunca fica mais de uma hora atrás
	var atrasos := []
	var anterior: int = m.populacao()
	for h in 30:
		await _proxima_hora()
		var agora: int = m.populacao()
		var mostrado := int(p.get("total"))
		if mostrado != agora and mostrado != anterior:
			atrasos.append("passo %d: mostra %d, população %d (hora antes %d)" % [m.passo, mostrado, agora, anterior])
		anterior = agora
	_res("QA-224", depois_morte == antes - 1 and topo_morte == depois_morte and dica_morte.contains(str(depois_morte)) and atrasos.is_empty(),
		"morte de %s: população %d → %d; na hora seguinte o topo mostra %d e a dica \"%s\"; em 30 horas, atrasos: %s" % [vitima.nome, antes, depois_morte, topo_morte, dica_morte, atrasos.slice(0, 3) if not atrasos.is_empty() else "nenhum"])
	# QA-227: a tecla do painel
	await _tecla_sem_colisao(tecla)


func _estado_do_jogo() -> Dictionary:
	var i := _i()
	var v := _vista()
	return {"ritmo": _sim().ritmo, "cronica": i.get("_cronica").visible if i.get("_cronica") else null,
		"estante": i.get("_estante").visible if i.get("_estante") else null,
		"preces": i.get("_preces").visible if i.get("_preces") else null, "discreto": v.get("modo_discreto"),
		"som": i.get("som_ligado"), "escala": moldura.get("escala"), "escondida": moldura.get("escondida"),
		"seguindo": v.get("seguindo"), "poder": i.get("poder")}


## QA-227: a tecla da dica é nova (não estava entre as do jogo antes do painel) e só abre e fecha o painel.
func _tecla_sem_colisao(tecla: String) -> void:
	var p := _painel()
	if tecla == "":
		_res("QA-227", false, "a dica do botão não diz a tecla")
		return
	if p.visible:
		await _clicar(Vector2((_botao(_id_botao())["rect"] as Rect2i).get_center()))
		await _esperar(0.2)
	var k := OS.find_keycode_from_string(tecla)
	var antes := _estado_do_jogo()
	await _tecla(k)
	await _esperar(0.2)
	var abriu: bool = p.visible
	var durante := _estado_do_jogo()
	await _tecla(k)
	await _esperar(0.2)
	var fechou: bool = not p.visible
	var depois := _estado_do_jogo()
	var mudou := []
	for c in antes:
		if str(antes[c]) != str(durante[c]) or str(antes[c]) != str(depois[c]):
			mudou.append("%s: %s → %s → %s" % [c, antes[c], durante[c], depois[c]])
	var nova := not tecla in TECLAS_ANTIGAS
	_res("QA-227", nova and abriu and fechou and mudou.is_empty(),
		"tecla %s: nova=%s, abriu=%s, fechou=%s, mudou mais alguma coisa: %s" % [tecla, nova, abriu, fechou, mudou if not mudou.is_empty() else "nada"])


## QA-225: com 2 povos, o painel aberto no nível 2 de um deles; todos dele morrem; na hora seguinte, o
## painel está no nível 1, sem esse povo e sem erro de script.
func _extinto() -> void:
	var m = _mundo()
	var p := _painel()
	if m.grupos_vivos().size() < 2:
		_pulado("QA-225", "a semente 3 no ano 25 tem %d povo(s) vivo(s)" % m.grupos_vivos().size())
		return
	await _abrir()
	var linhas: Array = _linhas(p)
	if linhas.is_empty():
		_res("QA-225", false, "o nível 1 está vazio")
		return
	var gid := int(linhas[0]["id"])
	await _clicar(_ponto_da_linha(p, 0))
	await _esperar(0.2)
	var no_nivel2 := _nivel(p) == 2 and int(p.get("povo")) == gid
	var erros_antes := erros.size()
	m._esperar_threads()
	for id in m.grupo(gid).membros.duplicate():
		m._morrer(m.pessoa(id), "doenca")
	# o núcleo só tira o povo vazio de grupos_visiveis() na virada do dia: espera isso (até 30 horas) e dá
	# mais uma hora ao painel
	var horas := 0
	while horas < 30 and m.grupos_visiveis().any(func(x): return int(x["id"]) == gid):
		await _proxima_hora()
		horas += 1
	await _proxima_hora()
	await _esperar(0.5)
	var ids_n1: Array = _linhas(p).map(func(x): return int(x.get("id", -1)))
	var novos := erros.slice(erros_antes)
	_res("QA-225", no_nivel2 and _nivel(p) == 1 and not gid in ids_n1 and novos.is_empty(),
		"povo %d aberto no nível 2=%s; o núcleo o tirou de grupos_visiveis() %d hora(s) depois; uma hora mais tarde: nível %s, povos %s, erros de script: %s" % [gid, no_nivel2, horas, _nivel(p), ids_n1, novos.slice(0, 2)])


## QA-226: o povo de mais de 100 pessoas (semente 3, ano 225): o nível 2 tem rolagem, a roda rola até o
## fim, e o clique na última pessoa leva a vista até ela.
func _grande() -> void:
	var m = _mundo()
	var p := _painel()
	await _abrir()
	var linhas: Array = _linhas(p)
	var k_grande := -1
	for k in linhas.size():
		if int(linhas[k].get("membros", 0)) > 100:
			k_grande = k
	if k_grande < 0:
		var maior := 0
		for g in m.grupos_vivos():
			maior = maxi(maior, g.membros.size())
		_pulado("QA-226", "nenhum povo de mais de 100 pessoas na semente 3, ano 225 (o maior tem %d)" % maior)
		return
	await _clicar(_ponto_da_linha(p, k_grande))
	await _esperar(0.2)
	var pessoas: Array = _linhas(p)
	var n := pessoas.size()
	var rmax := _rolagem_max(p)
	var ultima_antes: Vector2 = _ponto_da_linha(p, n - 1)
	var onde: Vector2 = _ponto_da_linha(p, 0)
	var rodas := 0
	while _rolagem(p) < rmax and rodas < 400:
		for apertado in [true, false]:
			var ev := InputEventMouseButton.new()
			ev.position = onde
			ev.global_position = onde
			ev.button_index = MOUSE_BUTTON_WHEEL_DOWN
			ev.pressed = apertado
			root.push_input(ev, true)
		await process_frame
		rodas += 1
	var ultima: Vector2 = _ponto_da_linha(p, n - 1)
	var alvo := int(pessoas[n - 1]["id"])
	if ultima.x >= 0:
		await _clicar(ultima)
		await _esperar(0.3)
	var v := _vista()
	_res("QA-226", n > 100 and rmax > 0 and ultima_antes.x < 0 and ultima.x >= 0 and int(v.get("foco")) == alvo,
		"%d pessoas: rolagem_max=%d; a última fora da área antes=%s; depois de %d giros da roda, visível=%s; clique nela: vista.foco=%s (esperado %d)" % [n, rmax, ultima_antes.x < 0, rodas, ultima.x >= 0, v.get("foco"), alvo])

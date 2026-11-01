extends RefCounted
## Cenários de teste que forçam o que é raro de ver na tela (--cenario-raro=NOME),
## para conferir a encenação e para as auditorias da arte. Mexem no mundo pelo
## próprio núcleo (métodos dele, inclusive os internos); nunca rodam no jogo de verdade.
##
##   estranhos   3 adultos chegam de além da borda e são recebidos no fogo
##   doentes     3 adultos ficam doentes e a cura fica escolhida (a cruzinha sobre eles)
##   sonho       um sonho sobre o fogo (a estrelinha de quem sonhou)
##   dependencia 6 chuvas sobre o mesmo povo, uma a cada 2 dias (costume e dependência na alça)
##   coleta      avança até o primeiro dia com a volta da coleta do morro, às 14h
##   guerra      dois povos em guerra, e o primeiro reza contra o outro (a seta no fogo inimigo)
##   notas       as notas de povo pequeno na alça: um rito de passagem e, 7 s depois, um roubo
##   profeta     alguém é chamado como profeta (o facho e depois a estrela sobre ele)
##   separacao   o segundo povo se separa do primeiro (a luz que se parte e a marca no povo novo)
##   fome        fome e prece do mesmo povo no mesmo dia: um sinal só, com o cursor em cima
##   batalha     o primeiro povo ataca o segundo agora (A, edb5598: um ataque às H vira cena de
##               H + 2h a H + 6h30, com a luta de H + 3h30 a H + 5h; a rotina é refeita numa thread,
##               então deixe o jogo correr: --hora=8 --ritmo=rapido e capture uns 45 s depois)

const NOMES := ["estranhos", "doentes", "sonho", "dependencia", "coleta", "guerra", "batalha", "notas", "profeta",
	"separacao", "fome"]


## Antes do primeiro quadro: o que muda o mundo.
static func preparar(nome: String, vista: Node2D) -> void:
	var sim = vista.sim
	var m = sim.mundo
	match nome:
		"doentes":
			var g = m.grupos_vivos()[0]
			var n := 0
			for p in m._adultos(g, 16):
				p.doente = 8
				n += 1
				if n == 3:
					break
			for h in 24:  # a ficha das pessoas (com o "doente") se refaz uma vez por dia
				m.avancar_hora()
			sim.iniciar_de_mundo()
		"dependencia":
			var antes: int = m.eventos.size()
			var x := _fogo(m, m.grupos_vivos()[0].id)
			for i in 6:
				m.usar_poder("chuva", x, 0.8)
				for h in 48:
					m.avancar_hora()
			sim.iniciar_de_mundo()
			vista.set_meta("eventos_do_cenario", m.eventos_desde(antes))
		"coleta":
			for d in 120:
				while m.tempo()["hora"] != 14:
					m.avancar_hora()
				if m.cenas_ativas().any(func(c): return c["tipo"] == "coleta_morro"):
					break
				m.avancar_hora()
			for h in 1:  # a descida começa no meio da tarde
				m.avancar_hora()
			sim.iniciar_de_mundo()
		"fome":
			var g = m.grupos_vivos()[0]
			g.tem_crenca = true
			g.ceticos = false
			for p in m._adultos(g, 14):
				p.fe = maxf(p.fe, 0.5)
			m._abrir_prece(g, "fome", null, -1)
			sim.iniciar_de_mundo()
		"batalha":
			var vivos: Array = m.grupos_vivos()
			if vivos.size() >= 2:
				m._atacar(vivos[0], vivos[1])
				sim.iniciar_de_mundo()
		"guerra":
			var vivos: Array = m.grupos_vivos()
			if vivos.size() >= 2:
				var a = vivos[0]
				var b = vivos[1]
				a.tem_crenca = true
				a.ceticos = false
				for p in m._adultos(a, 14):
					p.fe = maxf(p.fe, 0.5)
				m._comecar_guerra(a, b, a.zona)
				m._abrir_prece(a, "guerra", m.eventos[-1], -1)
				m.avancar_hora()
				sim.iniciar_de_mundo()


## Depois que a tela está pronta: o que é encenação, eventos e cursor.
static func encenar(nome: String, vista: Node2D, interface: Node2D, arvore: SceneTree) -> void:
	var sim = vista.sim
	var m = sim.mundo
	match nome:
		"estranhos":
			var g = m.grupos_vivos()[0]
			var ids: Array = m._adultos(g, 16).slice(0, 3).map(func(p): return p.id)
			vista._ao_receber_eventos([{"tipo": "estranhos", "grupo": g.id, "participantes": ids, "dados": {}}])
		"doentes":
			interface.poder = "cura"
		"sonho":
			interface.demo("sonho", _fogo(m, m.grupos_vivos()[0].id) + 10.0, 0.8)
		"dependencia":
			vista._ao_receber_eventos(vista.get_meta("eventos_do_cenario", []))
		"notas":  # pelo próprio núcleo, como o mundo registra
			var g = m.grupos_vivos()[0]
			var gente: Array = m._adultos(g, 12)
			var antes: int = m.eventos.size()
			m.registrar("rito", "social", 4, g.zona, g.id, [gente[0].id], {"lida": "caca"})
			vista._ao_receber_eventos(m.eventos_desde(antes))
			arvore.create_timer(7.0).timeout.connect(func():
				var depois: int = m.eventos.size()
				m.registrar("roubo", "social", m._no_povo_pequeno(g, 2), g.zona, g.id, [gente[1].id, gente[2].id], {})
				vista._ao_receber_eventos(m.eventos_desde(depois)))
		"profeta":
			var g = m.grupos_vivos()[0]
			vista._ao_receber_eventos([{"tipo": "profeta", "grupo": g.id, "participantes": [m._adultos(g, 20)[0].id],
				"dados": {}}])
		"separacao":
			var vivos: Array = m.grupos_vivos()
			if vivos.size() >= 2:
				vista._ao_receber_eventos([{"tipo": "separacao", "grupo": vivos[1].id, "outro_grupo": vivos[0].id,
					"participantes": [], "dados": {}}])
		"fome":
			_cursor_no_sinal(vista, interface, "fome")
		"guerra":  # o cursor sobre o sinal da prece, para a dica e a seta no fogo inimigo
			_cursor_no_sinal(vista, interface, "guerra")


## O cursor fica sobre o sinal da prece de uma necessidade (para a dica), a cada 0,25 s.
static func _cursor_no_sinal(vista: Node2D, interface: Node2D, necessidade: String) -> void:
	var t := Timer.new()
	t.wait_time = 0.25
	vista.add_child(t)
	t.timeout.connect(func():
		var achados: Array = vista._sinais.sinais.filter(func(x): return x.prece.get("necessidade", "") == necessidade)
		if achados.is_empty():
			return
		var s: Dictionary = achados[0]
		var ev := InputEventMouseMotion.new()
		interface.tratar(ev, vista.para_tela(Vector2(s.x, s.base - 3)) + Vector2(0, interface.ALTURA_ALCA),
			interface.ALTURA_ALCA))
	t.start()


static func _fogo(m, grupo: int) -> float:
	for o in m.construcoes():
		if o["tipo"] == "fogueira" and int(o.get("grupo", -1)) == grupo:
			return float(o["x"])
	return 240.0

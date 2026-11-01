extends Node
## Vida ambiente (arte/criaturas/): bichos que não fazem parte da simulação e
## só dão vida ao cotidiano. Aparecem conforme a estação e o horário da tabela
## do LEIA-ME da arte (seção 17). Usam um sorteio próprio, nunca o do núcleo.
## Todos passam pela tabela de noite, menos os morcegos, que já são escuros.

const Efeitos = preload("res://apresentacao/efeitos.gd")

## tipo -> [estações, hora de início, hora de fim, intervalo mínimo e máximo em s, quantos no máximo]
const REGRAS := {
	"passaros": [["primavera", "verão", "outono"], 7.0, 17.0, 18.0, 40.0, 1],
	"pousado": [["primavera", "verão", "outono"], 7.0, 17.0, 10.0, 22.0, 4],
	"peixe": [["primavera", "verão", "outono"], 7.0, 19.0, 8.0, 25.0, 1],
	"sapo": [["primavera", "verão"], 18.0, 23.5, 10.0, 30.0, 2],
	"garca": [["primavera", "verão", "outono"], 5.5, 16.0, 30.0, 90.0, 1],
	"coelho": [["primavera", "verão", "outono", "inverno"], 5.0, 8.5, 12.0, 35.0, 2],
	"coelho_tarde": [["primavera", "verão", "outono", "inverno"], 17.0, 19.5, 12.0, 35.0, 2],
	"coelho_dia": [["primavera", "verão", "outono"], 8.5, 17.0, 60.0, 150.0, 1],  # na borda da roça
	"cervo": [["primavera", "verão", "outono"], 5.0, 9.0, 25.0, 70.0, 1],
	"morcego": [["primavera", "verão", "outono"], 18.5, 22.0, 6.0, 18.0, 3],
	"migrando": [["inverno"], 8.0, 16.0, 40.0, 100.0, 1],
	"porco": [["primavera", "verão", "outono", "inverno"], 7.0, 17.0, 25.0, 70.0, 1],
	"ave_grande": [["primavera", "verão", "outono"], 7.0, 17.0, 20.0, 60.0, 2],
}
const FOLHAS := {
	"passaros": "passaro_voar_4q", "pousado": "passaro_pousado_forte_2q", "peixe": "peixe_saltar_4q",
	"sapo": "sapo_2q", "garca": "garca_2q", "coelho": "coelho_4q", "coelho_tarde": "coelho_4q", "coelho_dia": "coelho_4q",
	"cervo": "cervo_4q", "morcego": "morcego_4q", "migrando": "bando_migrando_4q",
	"porco": "porco_do_mato_4q", "ave_grande": "ave_grande_4q",
}

var vista: Node2D
var fosco: Efeitos
var luminoso: Efeitos
var _rng := RandomNumberGenerator.new()
var _espera := {}
## O mundo que nunca teve gente (o convite está no chão): os primeiros segundos não
## podem parecer parados. Um bicho grande entre 4 e 8 s, e os bandos de pássaros 3
## vezes mais frequentes até o primeiro povo (auditoria 12, V2).
var vazio := false
var _acolhida := -1.0  # s até o bicho da acolhida; < 0: ainda não marcado
const PASSAROS_NO_VAZIO := 3.0


func criar(p_vista: Node2D, p_fosco: Efeitos, p_luminoso: Efeitos) -> void:
	vista = p_vista
	fosco = p_fosco
	luminoso = p_luminoso
	_rng.randomize()
	for tipo in REGRAS:
		_espera[tipo] = _rng.randf_range(2.0, REGRAS[tipo][3])


func avancar(delta: float, hora: float, estacao: String, pessoas_x: Array) -> void:
	if vazio:
		if _acolhida < 0.0:
			_acolhida = _rng.randf_range(4.0, 8.0)
		elif _acolhida < 1000.0:
			_acolhida -= delta
			if _acolhida <= 0.0:
				_acolhida = 1e9  # uma vez só
				if estacao == "inverno":
					_nascer("coelho", pessoas_x)
				else:
					_nascer("cervo", pessoas_x)
					_nascer("garca", pessoas_x)
	for tipo in REGRAS:
		var r: Array = REGRAS[tipo]
		if not estacao in r[0] or hora < r[1] or hora >= r[2]:
			continue
		_espera[tipo] -= delta * (PASSAROS_NO_VAZIO if vazio and tipo == "passaros" else 1.0)
		if _espera[tipo] > 0.0:
			continue
		_espera[tipo] = _rng.randf_range(r[3], r[4])
		if _quantos(FOLHAS[tipo]) >= r[5]:
			continue
		_nascer(tipo, pessoas_x)


func _quantos(folha: String) -> int:
	var n := 0
	for e in [fosco, luminoso]:
		for p in e.particulas:
			if p.folha == "../criaturas/" + folha:
				n += 1
	return n


func _longe_de_gente(x: float, pessoas_x: Array, distancia: float) -> bool:
	for px in pessoas_x:
		if absf(px - x) < distancia:
			return false
	return true


func _nascer(tipo: String, pessoas_x: Array) -> void:
	var folha: String = "../criaturas/" + FOLHAS[tipo]
	match tipo:
		"passaros":  # bando de 3 a 5 atravessando, com quadros defasados
			var dir := 1.0 if _rng.randf() < 0.5 else -1.0
			var y := _rng.randf_range(18.0, 60.0)
			var vel := _rng.randf_range(22.0, 30.0) * dir
			var x0 := -10.0 if dir > 0.0 else 490.0
			for i in _rng.randi_range(3, 5):
				var p := Vector2(x0 - dir * i * _rng.randf_range(7, 12), y + _rng.randf_range(-6, 6))
				fosco.emitir(folha, 6, 4, p, Vector2(vel, _rng.randf_range(-2, 2)), 520.0 / absf(vel), 10.0, i,
					{"espelho": dir < 0.0})
		"migrando":
			var dir := 1.0 if _rng.randf() < 0.5 else -1.0
			fosco.emitir(folha, 24, 4, Vector2(-20.0 if dir > 0.0 else 500.0, _rng.randf_range(12, 26)),
				Vector2(18.0 * dir, 0), 540.0 / 18.0, 6.0, 0, {"espelho": dir < 0.0})
		"pousado":  # a maioria nos telhados (contra o céu), o resto no chão da clareira ou da praia, longe de gente
			if not vista.telhados.is_empty() and _rng.randf() < 0.6:
				var t: Vector2 = vista.telhados[_rng.randi() % vista.telhados.size()]
				fosco.emitir(folha, 5, 2, Vector2(t.x, t.y - 1), Vector2.ZERO, _rng.randf_range(20, 45),
					_rng.randf_range(0.8, 1.6), 0, {"espelho": _rng.randf() < 0.5})
				return
			for tentativa in 6:
				var x := _rng.randf_range(140, 330)
				if _longe_de_gente(x, pessoas_x, 16.0):
					fosco.emitir(folha, 5, 2, Vector2(x, vista.chao(int(x))), Vector2.ZERO, _rng.randf_range(15, 35),
						_rng.randf_range(0.8, 1.6), 0, {"espelho": _rng.randf() < 0.5})
					break
		"peixe":  # salta do lago e volta
			var x := _rng.randf_range(20, 115)
			fosco.emitir(folha, 8, 4, Vector2(x, 124), Vector2.ZERO, 0.9, 0.0, 0, {"espelho": _rng.randf() < 0.5})
		"sapo":
			var x := _rng.randf_range(128, 150)
			fosco.emitir(folha, 6, 2, Vector2(x, vista.chao(int(x))), Vector2.ZERO, _rng.randf_range(20, 40),
				_rng.randf_range(0.6, 1.2), 0, {"espelho": _rng.randf() < 0.5})
		"garca":  # parada na água rasa da margem
			var x := _rng.randf_range(112, 124)
			fosco.emitir(folha, 8, 2, Vector2(x, 124), Vector2.ZERO, _rng.randf_range(40, 90), 0.4, 0, {"espelho": true})
		"coelho", "coelho_tarde":  # pula pelo mato e foge de gente
			var x := _rng.randf_range(150, 200) if _rng.randf() < 0.5 else _rng.randf_range(300, 330)
			var dir := 1.0 if _rng.randf() < 0.5 else -1.0
			for px in pessoas_x:
				if absf(px - x) < 40.0:
					dir = signf(x - px) if x != px else dir
			fosco.emitir(folha, 6, 4, Vector2(x, vista.chao(int(x))), Vector2(14.0 * dir, 0), _rng.randf_range(3, 6),
				8.0, 0, {"espelho": dir < 0.0, "rente": true})
		"coelho_dia":  # sai do mato e atravessa a borda de uma roça (sem roça, a ponta da vila), aos pulos
			var obras: Array = vista.sim.construcoes if vista.sim else []
			var rocas: Array = obras.filter(func(o): return o["tipo"] == "roca")
			var xs: Array = rocas.map(func(o): return float(o["x"]))
			if xs.is_empty() and not obras.is_empty():
				var todos: Array = obras.map(func(o): return float(o["x"]))
				xs = [todos.min() - 24.0, todos.max() + 24.0]
			if xs.is_empty():
				return
			var meio: float = obras.reduce(func(soma, o): return soma + float(o["x"]), 0.0) / obras.size()
			xs.shuffle()
			for borda in xs:  # a primeira borda sem gente perto; foge para fora da vila
				var dir := 1.0 if borda >= meio else -1.0
				# em chão aberto (sem arbusto ou capim na frente), nunca na praia nem no lago
				var x: float = vista.chao_aberto(clampf(borda - dir * 10.0, 150.0, 440.0), dir)
				if _longe_de_gente(x, pessoas_x, 12.0):
					fosco.emitir(folha, 6, 4, Vector2(x, vista.chao(int(x))), Vector2(14.0 * dir, 0), 40.0 / 14.0 + 0.4,
						8.0, 0, {"espelho": dir < 0.0, "rente": true})
					break
		"cervo":  # pastando na borda da floresta do morro (no mundo vazio, no capim aberto antes dela, à vista)
			var x := _rng.randf_range(345, 375) if vazio else _rng.randf_range(400, 470)
			if _longe_de_gente(x, pessoas_x, 50.0):
				fosco.emitir(folha, 10, 4, Vector2(x, vista.chao(int(x))), Vector2.ZERO, _rng.randf_range(30, 70), 1.5, 0,
					{"espelho": _rng.randf() < 0.5})
		"porco":  # anda e fuça na borda da floresta e no mato; foge de gente
			var x := _rng.randf_range(330, 470) if _rng.randf() < 0.6 else _rng.randf_range(150, 210)
			if _longe_de_gente(x, pessoas_x, 30.0):
				var dir := 1.0 if _rng.randf() < 0.5 else -1.0
				fosco.emitir(folha, 10, 4, Vector2(x, vista.chao(int(x))), Vector2(3.0 * dir, 0), _rng.randf_range(12, 25),
					3.0, 0, {"espelho": dir < 0.0, "rente": true})
		"ave_grande":  # anda e bica o chão nos campos e na margem
			var x := _rng.randf_range(130, 330)
			if _longe_de_gente(x, pessoas_x, 20.0):
				fosco.emitir(folha, 8, 4, Vector2(x, vista.chao(int(x))), Vector2.ZERO, _rng.randf_range(15, 35),
					2.0, 0, {"espelho": _rng.randf() < 0.5})
		"morcego":  # sai da floresta e voa em zigue-zague
			var x := _rng.randf_range(340, 460)
			var dir := -1.0 if _rng.randf() < 0.7 else 1.0
			luminoso.emitir(folha, 6, 4, Vector2(x, _rng.randf_range(55, 85)),
				Vector2(_rng.randf_range(20, 32) * dir, _rng.randf_range(-6, 2)), _rng.randf_range(6, 10), 12.0, 0,
				{"espelho": dir < 0.0, "zigue": _rng.randf_range(4, 9)})

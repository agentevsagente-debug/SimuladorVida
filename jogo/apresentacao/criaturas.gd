extends Node
## Vida ambiente (arte/criaturas/): bichos que não fazem parte da simulação e
## só dão vida ao cotidiano. Aparecem conforme a estação e o horário da tabela
## do LEIA-ME da arte (seção 17). Usam um sorteio próprio, nunca o do núcleo.
## Todos passam pela tabela de noite, menos os morcegos, que já são escuros.

const Efeitos = preload("res://apresentacao/efeitos.gd")

## tipo -> [estações, hora de início, hora de fim, intervalo mínimo e máximo em s, quantos no máximo]
const REGRAS := {
	"passaros": [["primavera", "verão", "outono"], 7.0, 17.0, 18.0, 40.0, 1],
	"pousado": [["primavera", "verão", "outono"], 7.0, 17.0, 15.0, 30.0, 3],
	"peixe": [["primavera", "verão", "outono"], 7.0, 19.0, 8.0, 25.0, 1],
	"sapo": [["primavera", "verão"], 18.0, 23.5, 10.0, 30.0, 2],
	"garca": [["primavera", "verão", "outono"], 5.5, 16.0, 30.0, 90.0, 1],
	"coelho": [["primavera", "verão", "outono", "inverno"], 5.0, 8.5, 12.0, 35.0, 2],
	"coelho_tarde": [["primavera", "verão", "outono", "inverno"], 17.0, 19.5, 12.0, 35.0, 2],
	"cervo": [["primavera", "verão", "outono"], 5.0, 9.0, 25.0, 70.0, 1],
	"morcego": [["primavera", "verão", "outono"], 18.5, 22.0, 6.0, 18.0, 3],
	"migrando": [["inverno"], 8.0, 16.0, 40.0, 100.0, 1],
	"porco": [["primavera", "verão", "outono", "inverno"], 7.0, 17.0, 25.0, 70.0, 1],
	"ave_grande": [["primavera", "verão", "outono"], 7.0, 17.0, 20.0, 60.0, 2],
}
const FOLHAS := {
	"passaros": "passaro_voar_4q", "pousado": "passaro_pousado_2q", "peixe": "peixe_saltar_4q",
	"sapo": "sapo_2q", "garca": "garca_2q", "coelho": "coelho_4q", "coelho_tarde": "coelho_4q",
	"cervo": "cervo_4q", "morcego": "morcego_4q", "migrando": "bando_migrando_4q",
	"porco": "porco_do_mato_4q", "ave_grande": "ave_grande_4q",
}

var vista: Node2D
var fosco: Efeitos
var luminoso: Efeitos
var _rng := RandomNumberGenerator.new()
var _espera := {}


func criar(p_vista: Node2D, p_fosco: Efeitos, p_luminoso: Efeitos) -> void:
	vista = p_vista
	fosco = p_fosco
	luminoso = p_luminoso
	_rng.randomize()
	for tipo in REGRAS:
		_espera[tipo] = _rng.randf_range(2.0, REGRAS[tipo][3])


func avancar(delta: float, hora: float, estacao: String, pessoas_x: Array) -> void:
	for tipo in REGRAS:
		var r: Array = REGRAS[tipo]
		if not estacao in r[0] or hora < r[1] or hora >= r[2]:
			continue
		_espera[tipo] -= delta
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
		"pousado":  # no chão da clareira ou da praia, longe de gente
			for tentativa in 6:
				var x := _rng.randf_range(140, 330)
				if _longe_de_gente(x, pessoas_x, 16.0):
					fosco.emitir(folha, 4, 2, Vector2(x, vista.chao(int(x))), Vector2.ZERO, _rng.randf_range(15, 35),
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
		"cervo":  # pastando na borda da floresta do morro
			var x := _rng.randf_range(400, 470)
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

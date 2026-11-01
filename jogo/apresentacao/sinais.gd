extends Node2D
## Sinais das preces abertas (arte/sinais/): uma luz acima de quem reza, que
## continua visível até a prece ser atendida ou ficar sem resposta. Os sinais
## emitem luz, então não passam pela tabela de noite.
##
## Intensidade (decisão do orquestrador): até 10 dias de espera é comum, até 30
## é urgente, e acima disso, ou com importância 8 ou mais, é desesperado. Uma
## prece banal é sempre comum. "Os últimos" é um facho sobre a vila enquanto
## restarem 5 pessoas ou menos.

const Arte = preload("res://apresentacao/arte.gd")

const FOLHAS := {
	"comum": ["prece_comum_4q", 8],
	"urgente": ["prece_urgente_4q", 12],
	"desesperado": ["prece_desesperada_4q", 16],
	"os_ultimos": ["os_ultimos_4q", 24],
}
const NECESSIDADES := ["seca", "fome", "doenca", "frio", "guerra"]

var sinais: Array = []  # [{folha, largura, x, base, prece}]
var _importancia := {}  # id do evento da prece -> importância
var _texturas := {}
var _assinatura := []
var _quadro := 0


static func intensidade(prece: Dictionary, importancia: int) -> String:
	if prece.get("necessidade", "") == "banal":
		return "comum"
	if importancia >= 8 or prece["dias"] > 30:
		return "desesperado"
	if prece["dias"] > 10:
		return "urgente"
	return "comum"


func atualizar(sim: Node, vista: Node2D, relogio: float, figuras: Array) -> void:
	var cabecas := {}
	for f in figuras:
		cabecas[f.id] = f
	var novos := []
	for p in sim.preces:
		var ev: int = p["evento"]
		if not _importancia.has(ev):
			var lista: Array = sim.mundo.eventos_desde(ev)
			_importancia[ev] = int(lista[0]["importancia"]) if not lista.is_empty() else 0
		var nivel := intensidade(p, _importancia[ev])
		var x: float = p["x"]
		var base: int = vista.chao(int(x)) - 18  # dormindo: acima do telhado da cabana
		if cabecas.has(p["autor"]):
			var f: Dictionary = cabecas[p["autor"]]
			x = f.x + f.largura / 2.0
			base = f.base - (8 if f.folha.contains("crianca") else 12) - 1
		novos.append({"folha": FOLHAS[nivel][0], "largura": FOLHAS[nivel][1], "x": roundi(x), "base": base,
			"prece": p, "nivel": nivel})
	if _os_ultimos(sim) and not sim.construcoes.is_empty():
		var x: float = sim.construcoes[0]["x"]
		novos.append({"folha": "os_ultimos_4q", "largura": 24, "x": roundi(x), "base": vista.chao(int(x)) - 17,
			"prece": {}, "nivel": "os_ultimos"})
	# dois sinais no mesmo ponto: o segundo vai para o lado
	for i in novos.size():
		for j in i:
			if absi(novos[i].x - novos[j].x) < 6 and absi(novos[i].base - novos[j].base) < 8:
				novos[i].x = novos[j].x + 8
	sinais = novos
	_quadro = int(relogio * 4.0) % 4
	var assinatura := [_quadro]
	for s in sinais:
		assinatura.append([s.folha, s.x, s.base])
	if assinatura != _assinatura:
		_assinatura = assinatura
		queue_redraw()


func _os_ultimos(sim: Node) -> bool:
	var n: int = sim.pessoas.size()
	return n > 0 and n <= 5


## A prece aberta de uma pessoa, ou {}.
func prece_de(id: int) -> Dictionary:
	for s in sinais:
		if not s.prece.is_empty() and s.prece["autor"] == id:
			return s.prece
	return {}


## O sinal sob um ponto do mundo, com a prece e a intensidade, ou {}.
func sinal_em(p: Vector2) -> Dictionary:
	for s in sinais:
		var tex := _textura(s.folha)
		var r := Rect2(s.x - s.largura / 2.0, s.base - tex.get_height() + 1, s.largura, tex.get_height())
		if r.grow(1).has_point(p) and not s.prece.is_empty():
			var d: Dictionary = s.prece.duplicate()
			d["nivel"] = s.nivel
			return d
	return {}


func _textura(folha: String) -> Texture2D:
	if not _texturas.has(folha):
		_texturas[folha] = Arte.textura("sinais/%s.png" % folha)
	return _texturas[folha]


func _draw() -> void:
	for s in sinais:
		var tex := _textura(s.folha)
		var w: int = s.largura
		var h := tex.get_height()
		draw_texture_rect_region(tex, Rect2(s.x - w / 2, s.base - h + 1, w, h), Rect2(_quadro * w, 0, w, h))

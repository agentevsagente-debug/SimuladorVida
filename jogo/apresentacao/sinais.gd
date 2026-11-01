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
var baloes: Array = []  # [{x, base, variacao, espelho}] balões de fala sobre a cabeça
var bichos: Array = []  # [{folha, largura, x, base, quadro, espelho}] bichos da madrugada, já em tons de noite
## folha da pessoa -> variação do balão: 0 fala, 1 história, 2 pensamento, 3 coração, 4 raiva
const BALOES := {"acoes/conversar_falar_4q": 0, "acoes/contar_historia_4q": 1, "acoes/vigia_2q": 2,
	"acoes/mae_bebe_parado_2q": 3, "acoes/discutir_4q": 4, "acoes/criancas_brigar_4q": 4}
## por quanto tempo o balão aparece, de quanto em quanto tempo (s), por variação
const RITMO_BALAO := [[2.0, 4.5], [2.5, 4.5], [2.5, 6.0], [2.0, 7.0], [1.5, 3.5]]
const MAX_BALOES := 3
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
	_baloes(figuras, relogio)
	_bichos_da_madrugada(sim, vista, relogio)
	var assinatura := [_quadro, baloes.hash(), bichos.hash()]
	for s in sinais:
		assinatura.append([s.folha, s.x, s.base])
	for b in baloes:
		assinatura.append([b.x, b.base, b.variacao])
	if assinatura != _assinatura:
		_assinatura = assinatura
		queue_redraw()


## Balões de fala (arte, seção 9): sobre quem conversa, conta história,
## cochila, nina ou discute, de vez em quando e no máximo 3 de cada vez.
func _baloes(figuras: Array, relogio: float) -> void:
	baloes = []
	for f in figuras:
		if baloes.size() >= MAX_BALOES:
			break
		if f.id < 0 or not BALOES.has(f.folha):
			continue
		var v: int = BALOES[f.folha]
		if f.folha == "acoes/vigia_2q" and f.quadro != 1:
			continue  # só o vigia cochilando pensa
		var r: Array = RITMO_BALAO[v]
		if fmod(relogio + f.id * 1.37, r[1]) >= r[0]:
			continue
		var crianca: bool = f.folha.contains("crianca")
		var dx := (1 if not f.espelho else -1) if crianca else (2 if not f.espelho else 0)
		var topo: int = f.base - (8 if crianca else 12) + 1
		baloes.append({"x": f.x + dx, "base": topo - 6, "variacao": v, "espelho": f.espelho})


## Os bichos da madrugada (cena `bicho_noturno`): a coruja no alto de uma
## árvore (com neve no inverno, encolhida na chuva), o morcego sobre o lago e o
## sapo na margem. Já vêm em tons de noite, então não passam pela tabela.
func _bichos_da_madrugada(sim: Node, vista: Node2D, relogio: float) -> void:
	bichos = []
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		if c.get("tipo", "") != "bicho_noturno":
			continue
		if h < float(c.get("ini", 0.0)) or h > float(c.get("fim", 24.0)):
			continue
		var x := roundi(float(c.get("x", 300.0)))
		match String(c.get("bicho", "")):
			"coruja":  # fica olhando e, de vez em quando, pisca ou vira a cabeça
				var folha := "coruja_neve_4q" if Arte.estacao == "inverno" else (
					"coruja_chuva_4q" if not sim.clima.get("tempestade", {}).is_empty() else "coruja_pousada_4q")
				var ciclo := fmod(relogio + x, 3.2)
				var q := 0 if ciclo < 2.9 else (1 if int(relogio / 3.2) % 2 == 0 else 2)
				bichos.append({"folha": "../criaturas/" + folha, "largura": 7, "x": x, "base": vista.chao(x) - 18,
					"quadro": q, "espelho": false})
			"morcego":
				var bx := x + roundi(sin(relogio * 0.9) * 18.0)
				bichos.append({"folha": "../criaturas/morcego_noite_4q", "largura": 8, "x": bx,
					"base": vista.chao(x) - 22 + roundi(sin(relogio * 3.1) * 3.0), "quadro": int(relogio * 10.0) % 4,
					"espelho": cos(relogio * 0.9) < 0.0})
			"sapo":
				bichos.append({"folha": "../criaturas/sapo_2q", "largura": 6, "x": x, "base": vista.chao(x),
					"quadro": int(relogio * 1.5) % 2, "espelho": false})


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
	for b in bichos:
		var tex_b := _textura(b.folha)
		var h_b := tex_b.get_height()
		draw_texture_rect_region(tex_b, Rect2(b.x - b.largura / 2, b.base - h_b + 1, b.largura, h_b),
			Rect2(b.quadro * b.largura, 0, b.largura, h_b))
	var tex_balao := _textura("balao_5v")
	for b in baloes:
		var origem := Rect2(b.variacao * 6, 0, 6, 5)
		if b.espelho:
			draw_set_transform(Vector2(b.x + 6, b.base), 0.0, Vector2(-1, 1))
			draw_texture_rect_region(tex_balao, Rect2(0, 0, 6, 5), origem)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect_region(tex_balao, Rect2(b.x, b.base, 6, 5), origem)
	for s in sinais:
		var tex := _textura(s.folha)
		var w: int = s.largura
		var h := tex.get_height()
		draw_texture_rect_region(tex, Rect2(s.x - w / 2, s.base - h + 1, w, h), Rect2(_quadro * w, 0, w, h))

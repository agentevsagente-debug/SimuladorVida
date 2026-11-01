extends RefCounted
## Montagem do terreno em blocos de 8 × 8, porta de arte_claude/pecas/terreno/
## terreno.py (pilha e montar_terreno). Devolve a imagem de cores, a imagem
## de etiquetas (R8, valores de Arte.CEU..FRENTE) e a superfície por coluna x.

const Arte = preload("res://apresentacao/arte.gd")

const W := 480
const H := 160
const T := 8
const NIVEL_AGUA := 121
## Colunas com raízes: embaixo das árvores fixas da cena.
const COLUNAS_RAIZ := [20, 23, 37, 38, 40, 43, 47, 50, 54, 55, 57]

var _blocos := {}
var _solidos := {}


func _bloco(nome: String) -> Image:
	if not _blocos.has(nome):
		var caminho: String = nome if nome.contains("/") else "terreno/" + nome
		_blocos[nome] = Arte.imagem(Arte.da_estacao(caminho) + ".png")
	return _blocos[nome]


## colunas: [[superfície y, tipo], ...] uma por coluna de 8 px.
## batido: colunas de terra batida (clareira em volta das fogueiras).
## Sem superficie_na_cor, a linha de cima da água só ganha etiqueta: ela é
## desenhada à parte, animada.
## queimadas: colunas em que o fogo do deus passou (grama vira terra queimada).
## gelo: colunas de água congelada (no inverno, as mais perto da praia).
func montar(colunas: Array, batido: Array, quadro_agua: Image, superficie_na_cor := true,
		queimadas: Array = [], gelo: Array = []) -> Dictionary:
	var cor := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var tag := Image.create(W, H, false, Image.FORMAT_R8)
	var sup := PackedInt32Array()
	sup.resize(W)
	# rocha em grade fixa, por baixo das pilhas das colunas
	for y0 in range(128, H, T):
		for x0 in range(0, W, T):
			var k := (x0 / T) % 8 + 8 * ((y0 / T) % 2) + 1
			colar(cor, tag, _bloco("rocha_%d" % k), Vector2i(x0, y0), Arte.MUNDO)
	for c in colunas.size():
		var s := int(colunas[c][0])
		var tp: String = colunas[c][1]
		for x in range(c * T, c * T + T):
			sup[x] = s
		for item in pilha(c, s, tp, c in batido, c in queimadas):
			var nome_bloco: String = item[1]
			if nome_bloco == "agua_superficie" and c in gelo:
				nome_bloco = "gelo_superficie"
			var bloco := quadro_agua if nome_bloco == "agua_superficie" else _bloco(nome_bloco)
			var etiqueta := Arte.AGUA if nome_bloco.begins_with("agua") else Arte.MUNDO
			if nome_bloco == "agua_superficie" and not superficie_na_cor:
				var r := Rect2i(Vector2i.ZERO, bloco.get_size())
				tag.blit_rect_mask(_solido(bloco.get_size(), etiqueta), bloco, r, Vector2i(c * T, item[0]))
			else:
				colar(cor, tag, bloco, Vector2i(c * T, item[0]), etiqueta)
	_blocos.clear()
	return {"cor": cor, "tag": tag, "sup": sup}


## Copia os pixels opacos de `peca` e marca a etiqueta deles.
func colar(cor: Image, tag: Image, peca: Image, pos: Vector2i, etiqueta: int) -> void:
	var r := Rect2i(Vector2i.ZERO, peca.get_size())
	cor.blit_rect_mask(peca, peca, r, pos)
	tag.blit_rect_mask(_solido(peca.get_size(), etiqueta), peca, r, pos)


func _solido(tamanho: Vector2i, etiqueta: int) -> Image:
	var chave := "%d,%d,%d" % [tamanho.x, tamanho.y, etiqueta]
	if not _solidos.has(chave):
		var img := Image.create(tamanho.x, tamanho.y, false, Image.FORMAT_R8)
		img.fill(Color8(etiqueta, 0, 0))
		_solidos[chave] = img
	return _solidos[chave]


static func _escolher(a: String, b: String, c: int, y: int) -> String:
	return a if (c * 7 + (y / 8) * 3 + (c * y) % 5) % 3 else b


## Lista [y, nome do bloco] de uma coluna, de cima para baixo.
static func pilha(c: int, s: int, tp: String, batido: bool, queimada := false) -> Array:
	var itens := []
	if tp == "areia" and s > NIVEL_AGUA:
		for y in [120, 128, 136, 144, 152]:
			if y < s:
				itens.append([y, "agua_superficie" if y == 120 else ("agua" if y == 128 else "agua_funda")])
	var y: int
	if tp == "grama" and batido:
		itens.append([s - 2, "chao_batido"])
		y = s + 6
	elif tp == "grama" and queimada:
		itens.append([s - 2, "memoria/terra_queimada_a" if c % 2 else "memoria/terra_queimada_b"])
		y = s + 6
	elif tp == "grama":
		itens.append([s - 2, _escolher("grama_a", "grama_b", c, s)])
		y = s + 6
	elif tp == "seca":
		itens.append([s - 2, "grama_seca"])
		y = s + 6
	else:
		itens.append([s, "areia_superficie"])
		y = s + 8
	var fase := "terra" if tp == "grama" else "areia"
	var raizes := 3 if c in COLUNAS_RAIZ else 0
	while y < H:
		var centro := y + 4
		if fase == "areia" or (fase == "terra" and centro >= 130):
			var variante: String = ["", "_b", "_c"][(c * 5 + c / 3) % 3]
			itens.append([y, "terra_escura_topo" + variante if fase == "terra" else "areia_base"])
			fase = "escura"
		elif fase == "escura" and centro >= 139:
			itens.append([y, "rocha_borda" + ["", "_b", "_c"][(c * 7 + c / 2) % 3]])
			break  # daqui para baixo vale a grade fixa de rocha
		elif fase == "terra":
			if raizes:
				itens.append([y, "terra_raiz_b" if raizes == 2 else "terra_raiz"])
				raizes -= 1
			else:
				itens.append([y, _escolher("terra_a", "terra_b", c, y)])
		elif fase == "escura":
			var h := (c * 13 + y * 7) % 11
			if raizes:
				itens.append([y, "terra_escura_raiz"])
				raizes = 0
			elif h in [0, 4, 8]:
				itens.append([y, "pedra_solo"])
			else:
				itens.append([y, _escolher("terra_escura_a", "terra_escura_b", c, y)])
		y += 8
	return itens

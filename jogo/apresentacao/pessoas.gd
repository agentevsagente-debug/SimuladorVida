extends Node2D
## Desenha as pessoas e os objetos de cena. Cada figura é {folha (caminho em
## arte/, sem .png), quadro, largura, x, base,
## espelho, codigo, fogo}: x é o canto esquerdo e base a linha do chão.
## As folhas ficam em cache (normal e espelhada): um conjunto fixo, que não
## cresce com a população.
##
## O shader de troca recebe pelo modulate o centro da figura (r) e o x da
## fogueira mais perto (g), em pixels / 512, para a regra da metade do corpo
## virada para longe do fogo descer um nível de luz, e o código de troca de
## pele, cabelo e roupa (b, / 255).

const Arte = preload("res://apresentacao/arte.gd")

var figuras: Array = []
var _cache := {}
var _assinatura := []


## Troca as figuras e só pede desenho se algo visível mudou.
func definir(novas: Array) -> void:
	var assinatura := []
	for f in novas:
		assinatura.append([f.folha, f.quadro, f.x, f.base, f.espelho, f.codigo, f.fogo, f.get("atras", false)])
	if assinatura == _assinatura:
		return
	_assinatura = assinatura
	figuras = novas
	queue_redraw()


func _folha(nome: String, espelho: bool) -> Texture2D:
	var chave := "%s|%s" % [nome, espelho]
	if not _cache.has(chave):
		var img := Arte.imagem("%s.png" % nome)
		if espelho:
			img.flip_x()
		_cache[chave] = ImageTexture.create_from_image(img)
	return _cache[chave]


func _draw() -> void:
	for f in figuras:
		var tex := _folha(f.folha, f.espelho)
		var w: int = f.largura
		var h := tex.get_height()
		var n := tex.get_width() / w
		# a folha espelhada tem os quadros em ordem inversa
		var q: int = (n - 1 - f.quadro) if f.espelho else f.quadro
		# alfa 0,5 marca a segunda fileira da roda (o shader a escurece; o alfa não é usado como transparência)
		var info := Color((f.x + w / 2.0) / 512.0, f.fogo / 512.0, f.codigo / 255.0, 0.5 if f.get("atras", false) else 1.0)
		# folhas de 12 px têm o corpo nas colunas 0 a 7; espelhadas, o corpo vai para 4 a 11
		var x: int = f.x - (w - 8 if f.espelho and w > 8 else 0)
		draw_texture_rect_region(tex, Rect2(x, f.base - h + 1, w, h), Rect2(q * w, 0, w, h), info)

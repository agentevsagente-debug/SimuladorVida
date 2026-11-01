extends Node2D
## Desenha as pessoas. Cada figura é {folha, quadro, largura, x, base,
## espelho, troca, fogo}: x é o canto esquerdo e base a linha do chão.
## As folhas com as cores trocadas (e espelhadas) ficam em cache.
##
## O shader de troca recebe pelo modulate o centro da figura (r) e o x da
## fogueira mais perto (g), em pixels / 512, para a regra da metade do corpo
## virada para longe do fogo descer um nível de luz.

const Arte = preload("res://apresentacao/arte.gd")

var figuras: Array = []
var _cache := {}
var _assinatura := []


## Troca as figuras e só pede desenho se algo visível mudou.
func definir(novas: Array) -> void:
	var assinatura := []
	for f in novas:
		assinatura.append([f.folha, f.quadro, f.x, f.base, f.espelho, f.troca, f.fogo])
	if assinatura == _assinatura:
		return
	_assinatura = assinatura
	figuras = novas
	queue_redraw()


func _folha(nome: String, troca: Dictionary, espelho: bool) -> Texture2D:
	var chave := "%s|%s|%s" % [nome, troca, espelho]
	if not _cache.has(chave):
		var img := Arte.trocar(Arte.imagem("habitantes/%s.png" % nome), troca)
		if espelho:
			img.flip_x()
		_cache[chave] = ImageTexture.create_from_image(img)
	return _cache[chave]


func _draw() -> void:
	for f in figuras:
		var tex := _folha(f.folha, f.troca, f.espelho)
		var w: int = f.largura
		var h := tex.get_height()
		var n := tex.get_width() / w
		# a folha espelhada tem os quadros em ordem inversa
		var q: int = (n - 1 - f.quadro) if f.espelho else f.quadro
		var info := Color((f.x + w / 2.0) / 512.0, f.fogo / 512.0, 0.0, 1.0)
		draw_texture_rect_region(tex, Rect2(f.x, f.base - h + 1, w, h), Rect2(q * w, 0, w, h), info)

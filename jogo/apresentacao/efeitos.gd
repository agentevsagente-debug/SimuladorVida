extends Node2D
## Partículas da atmosfera e dos poderes, com as folhas de arte/efeitos/.
## Cada partícula é {folha, largura, quadros, pos, vel, vida, idade, fps,
## variacao}. `quadros` > 1 anima ao longo da vida (fps = 0) ou em laço
## (fps > 0); folhas "_Nv" usam `variacao` para escolher o quadro.
##
## Há duas instâncias na vista: uma passa pela tabela de noite (gotas,
## fumaça, nuvem) e outra não, porque o que ela desenha emite luz (faíscas,
## vagalumes, raio). Só pede desenho quando algum pixel ou quadro muda.

const Arte = preload("res://apresentacao/arte.gd")

var particulas: Array = []
var _texturas := {}
var _assinatura := []


func emitir(folha: String, largura: int, quadros: int, pos: Vector2, vel: Vector2, vida: float,
		fps := 0.0, variacao := 0) -> void:
	particulas.append({"folha": folha, "largura": largura, "quadros": quadros, "pos": pos,
		"vel": vel, "vida": vida, "idade": 0.0, "fps": fps, "variacao": variacao})


func ativo() -> bool:
	return not particulas.is_empty()


func avancar(delta: float) -> void:
	if particulas.is_empty() and _assinatura.is_empty():
		return
	var vivas := []
	var assinatura := []
	for p in particulas:
		p.idade += delta
		if p.idade >= p.vida:
			continue
		p.pos += p.vel * delta
		vivas.append(p)
		assinatura.append([p.folha, _quadro(p), floori(p.pos.x), floori(p.pos.y),
			int(p.idade * 8.0) if p.folha == "faisca" else 0])
	particulas = vivas
	if assinatura != _assinatura:
		_assinatura = assinatura
		queue_redraw()


func limpar(folha: String) -> void:
	particulas = particulas.filter(func(p): return p.folha != folha)


func _quadro(p: Dictionary) -> int:
	if p.quadros <= 1:
		return 0
	if p.fps > 0.0:
		return (p.variacao + int(p.idade * p.fps)) % p.quadros
	if p.variacao >= 0 and String(p.folha).ends_with("v"):
		return p.variacao % p.quadros
	return mini(int(p.idade / p.vida * p.quadros), p.quadros - 1)


func _textura(folha: String) -> Texture2D:
	if not _texturas.has(folha):
		_texturas[folha] = Arte.textura("efeitos/%s.png" % folha) if not folha.begins_with("estagio1/") \
			else Arte.textura(folha + ".png")
	return _texturas[folha]


func _draw() -> void:
	for p in particulas:
		if p.folha == "faisca":  # um pixel de brasa, alternando entre dois tons
			var cor := Arte.paleta[22 if (p.variacao + int(p.idade * 8.0)) % 2 else 21]
			draw_rect(Rect2(floori(p.pos.x), floori(p.pos.y), 1, 1), cor)
			continue
		var tex := _textura(p.folha)
		var w: int = p.largura
		var h := tex.get_height()
		var canto := Vector2(floori(p.pos.x) - w / 2, floori(p.pos.y) - h + 1)
		draw_texture_rect_region(tex, Rect2(canto, Vector2(w, h)), Rect2(_quadro(p) * w, 0, w, h))

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
var chao: Callable  # x -> linha do chão, para quem anda rente (coelhos)
var _texturas := {}
var _assinatura := []


## extra: {espelho: bool, rente: bool (segue o chão), zigue: float (oscila em y)}.
func emitir(folha: String, largura: int, quadros: int, pos: Vector2, vel: Vector2, vida: float,
		fps := 0.0, variacao := 0, extra := {}) -> void:
	var p := {"folha": folha, "largura": largura, "quadros": quadros, "pos": pos,
		"vel": vel, "vida": vida, "idade": 0.0, "fps": fps, "variacao": variacao}
	p.merge(extra)
	particulas.append(p)


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
		if p.get("rente", false) and chao.is_valid():
			p.pos.y = chao.call(int(p.pos.x))
		vivas.append(p)
		assinatura.append([p.folha, _quadro(p), floori(p.pos.x), floori(p.pos.y + _zigue(p)),
			int(p.idade * 8.0) if p.folha == "faisca" else 0])
	particulas = vivas
	if assinatura != _assinatura:
		_assinatura = assinatura
		queue_redraw()


func _zigue(p: Dictionary) -> float:
	return roundf(sin(p.idade * p.get("zigue", 0.0)) * 3.0) if p.has("zigue") else 0.0


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
		var fora := folha.begins_with("estagio1/") or folha.begins_with("memoria/")
		var caminho := folha + ".png" if fora else "efeitos/%s.png" % folha
		# a memória (terra queimada) é importada como Image, para os blocos do chão
		_texturas[folha] = ImageTexture.create_from_image(Arte.imagem(caminho)) if folha.begins_with("memoria/") \
			else Arte.textura(caminho)
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
		var canto := Vector2(floori(p.pos.x) - w / 2, floori(p.pos.y + _zigue(p)) - h + 1)
		var origem := Rect2(_quadro(p) * w, 0, w, h)
		if p.get("espelho", false):  # as criaturas olham para a direita; espelhar é virar
			draw_set_transform(Vector2(canto.x + w, canto.y), 0.0, Vector2(-1, 1))
			draw_texture_rect_region(tex, Rect2(Vector2.ZERO, Vector2(w, h)), origem)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect_region(tex, Rect2(canto, Vector2(w, h)), origem)

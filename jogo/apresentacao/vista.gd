extends Node2D
## Vista do mundo (480 × 160). Provisória: mostra a cena-alvo parada até o
## mundo desenhado da tarefa 2 chegar. A moldura chama avancar() todo quadro
## e ao_clicar() quando o jogador clica no mundo.

const LARGURA := 480
const ALTURA := 160

var _cena: Texture2D = preload("res://arte/alvo/alvo_dia.png")


func avancar(_delta: float, _desenhar: bool) -> void:
	pass


func ao_clicar(_ponto: Vector2) -> void:
	pass


func _draw() -> void:
	draw_texture(_cena, Vector2.ZERO)

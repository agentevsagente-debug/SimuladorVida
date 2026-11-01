extends SceneTree
## Casos difíceis da gramática: contrações, concordância de gênero e número.
const G = preload("res://nucleo/gramatica.gd")

func _initialize() -> void:
	var ana := G.termo("Ana", "f")
	var tobe := G.termo("Tobe", "m")
	var dois := G.termo("Ana e Tobe", "m", 2)
	var duas := G.termo("Ana e Lia", "f", 2)
	var lago := G.termo("lago", "m", 1, true)
	var praia := G.termo("praia", "f", 1, true)
	var deus := G.termo("Sombra", "f", 1, true)
	var casos := [
		["{p} foi {p:expulso|expulsa}.", {"p": ana}, "Ana foi expulsa."],
		["{p} foi {p:expulso|expulsa}.", {"p": tobe}, "Tobe foi expulso."],
		["{x} {x#morreu|morreram} na luta.", {"x": dois}, "Ana e Tobe morreram na luta."],
		["{x} foram {x:mortos|mortas|mortos|mortas}.", {"x": duas}, "Ana e Lia foram mortas."],
		["Choveu {em:z}.", {"z": lago}, "Choveu no lago."],
		["Choveu {em:z}.", {"z": praia}, "Choveu na praia."],
		["Saíram {de:z}.", {"z": praia}, "Saíram da praia."],
		["Foram {a:z}.", {"z": praia}, "Foram à praia."],
		["Rezaram {a:d}.", {"d": deus}, "Rezaram à Sombra."],
		["Falava {por:d}.", {"d": deus}, "Falava pela Sombra."],
		["Chamaram-{d:no|na}.", {"d": deus}, "Chamaram-na."],
	]
	var falhas := 0
	for c in casos:
		var r := G.preencher(c[0], c[1])
		if r != c[2]:
			falhas += 1
			print("FALHOU: ", c[0], " -> ", r, " (esperado: ", c[2], ")")
	print("extenso: ", G.extenso(1, "f"), " ", G.extenso(2, "f"), " ", G.extenso(2, "m"), " ", G.extenso(21, "f"))
	print("%d casos, %d falhas" % [casos.size(), falhas])
	quit()

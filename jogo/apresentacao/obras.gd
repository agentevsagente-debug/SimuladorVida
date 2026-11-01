extends RefCounted
## Que peça da arte desenha cada construção e cada ruína, pelo tipo e pelo
## estágio do povo (API: construcoes() e ruinas_visiveis(); arte: seções 3,
## 7, 8, 9, 11 e 15 do LEIA-ME). Casas e templos se montam em camadas com a
## parede, o telhado e o símbolo da cultura do povo (`aparencia`); as ruínas
## se cobrem de mato com a idade.

## tipo -> peça por estágio (1 a 6). Um estágio sem peça própria usa a do
## estágio anterior que tiver.
const PECAS := {
	"cabana": {1: "estagio1/cabana_galhos", 2: "estagio2/casa_taipa", 3: "estagio3/casa_pedra",
		4: "estagio4/casa_enxaimel", 6: "estagio6/casa_tijolo"},
	"templo": {2: "estagio2/templo", 3: "estagio3/templo_pedra", 4: "estagio4/templo_colunas",
		5: "estagio5/templo_escrita", 6: "estagio6/templo_cupula"},
	"altar": {1: "estagio2/altar"},
	"celeiro": {2: "estagio2/celeiro"},
	"forja": {4: "estagio4/forja"},
	"arquivo": {5: "estagio5/biblioteca"},
	"moinho": {6: "estagio6/moinho_4q"},
	"muralha": {6: "estagio6/muralha_torre"},
	"barco": {6: "estagio6/barco_2q"},
}
## Ruínas: peça inteira -> a sua ruína.
const RUINAS := {
	"estagio1/cabana_galhos": "memoria/cabana_abandonada", "estagio2/casa_taipa": "memoria/casa_ruina",
	"estagio2/celeiro": "memoria/casa_ruina", "estagio2/templo": "memoria/casa_ruina",
	"estagio2/altar": "memoria/cabana_abandonada",
	"estagio3/casa_pedra": "estagio3/casa_pedra_ruina", "estagio3/templo_pedra": "estagio3/templo_pedra_ruina",
	"estagio4/casa_enxaimel": "estagio4/casa_enxaimel_ruina", "estagio4/templo_colunas": "estagio4/templo_colunas_ruina",
	"estagio4/forja": "estagio4/forja_ruina", "estagio5/biblioteca": "estagio5/biblioteca_ruina",
	"estagio5/templo_escrita": "estagio5/templo_escrita_ruina", "estagio6/casa_tijolo": "estagio6/casa_tijolo_ruina",
	"estagio6/templo_cupula": "estagio6/templo_cupula_ruina", "estagio6/moinho_4q": "estagio6/moinho_ruina",
	"estagio6/muralha_torre": "estagio6/muralha_torre_ruina", "estagio6/barco_2q": "estagio6/barco_naufragado",
}
## Camadas de cultura por tipo e estágio (a primeira é a de baixo). {p} é a
## parede, {t} o telhado e {s} o símbolo, da `aparencia` do povo (API).
const CAMADAS_CULTURA := {
	"cabana": {2: ["culturas/casa_parede_{p}", "culturas/casa_telhado_{t}"],
		3: ["estagio3/casa_pedra_parede", "estagio3/casa_pedra_telhado_{t}"],
		4: ["estagio4/casa_enxaimel_parede", "estagio4/casa_enxaimel_telhado_{t}"],
		6: ["estagio6/casa_tijolo_parede", "estagio6/casa_tijolo_telhado_{t}"]},
	"templo": {2: ["culturas/templo_parede_{p}", "culturas/templo_telhado_{t}", "culturas/templo_simbolo_{s}"],
		3: ["estagio3/templo_pedra_base", "estagio3/templo_pedra_simbolo_{s}"],
		4: ["estagio4/templo_colunas_parede", "estagio4/templo_colunas_telhado_{t}", "estagio4/templo_colunas_simbolo_{s}"],
		5: ["estagio5/templo_escrita_parede", "estagio4/templo_colunas_telhado_{t}", "estagio4/templo_colunas_simbolo_{s}"],
		6: ["estagio6/templo_cupula_base", "estagio6/templo_cupula_simbolo_{s}"]},
	"arquivo": {5: ["estagio5/biblioteca_parede", "estagio5/biblioteca_telhado_{t}"]},
}
## Folhas com vários quadros lado a lado: largura de um quadro (a peça fixa usa o primeiro).
const QUADRO := {"estagio6/moinho_4q": 32, "estagio6/barco_2q": 24}


## Caminho da peça (sem .png, a partir de arte/), ou "" se o tipo não se desenha
## na imagem fixa (fogueira, roça: tratadas à parte).
static func peca(tipo: String, estagio: int, ruina := false) -> String:
	if not PECAS.has(tipo):
		return ""
	var porestagio: Dictionary = PECAS[tipo]
	var caminho := ""
	for e in range(clampi(estagio, 1, 6), 0, -1):
		if porestagio.has(e):
			caminho = porestagio[e]
			break
	if caminho == "":  # estágio menor que o primeiro com peça: usa a primeira
		var menores := porestagio.keys()
		menores.sort()
		caminho = porestagio[menores[0]]
	if ruina:
		return RUINAS.get(caminho, "memoria/casa_ruina")
	return caminho


## As camadas da construção na cultura do povo, de baixo para cima. Sem
## variação de cultura (estágio 1, celeiro, forja...), é a peça inteira.
static func camadas(tipo: String, estagio: int, aparencia: Dictionary) -> Array:
	if CAMADAS_CULTURA.has(tipo) and not aparencia.is_empty():
		var porestagio: Dictionary = CAMADAS_CULTURA[tipo]
		for e in range(clampi(estagio, 1, 6), 1, -1):
			if porestagio.has(e):
				return porestagio[e].map(func(c): return String(c).format({
					"p": aparencia.get("parede", "taipa"), "t": aparencia.get("telhado", "palha"),
					"s": aparencia.get("simbolo", "sol")}))
	var inteira := peca(tipo, estagio)
	return [inteira] if inteira != "" else []


## Idades (anos) em que a natureza avança sobre uma ruína: mato 1, mato 2,
## uma muda ao lado, mato 3 com uma árvore jovem.
const IDADES_NATUREZA := [3, 10, 15, 25]


## Quantos passos da natureza a ruína já deu (0 a 4).
static func grau_natureza(anos: int) -> int:
	var g := 0
	for idade in IDADES_NATUREZA:
		if anos >= idade:
			g += 1
	return g


## A ruína coberta de mato conforme a idade (natureza/<ruína>_mato_N), ou a ruína limpa.
static func ruina_com_mato(caminho: String, anos: int) -> String:
	var grau := 0 if anos < 3 else (1 if anos < 10 else (2 if anos < 25 else 3))
	if grau == 0 or caminho == "":
		return caminho
	return "natureza/%s_mato_%d" % [caminho.get_file(), grau]


## O que nasce ao lado de uma ruína velha: muda, depois árvore ou pinheiro jovem.
static func planta_da_ruina(anos: int, x: float) -> String:
	if anos >= IDADES_NATUREZA[3]:
		return "natureza/pinheiro_jovem" if int(x) % 3 == 0 else "natureza/arvore_jovem"
	if anos >= IDADES_NATUREZA[2]:
		return "natureza/muda"
	return ""


## O primeiro quadro de uma folha de vários quadros, ou a imagem inteira.
static func primeiro_quadro(caminho: String, img: Image) -> Image:
	if QUADRO.has(caminho):
		return img.get_region(Rect2i(0, 0, QUADRO[caminho], img.get_height()))
	return img

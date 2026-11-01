extends RefCounted
## Que peça da arte desenha cada construção e cada ruína, pelo tipo e pelo
## estágio do povo (API: construcoes() e ruinas_visiveis(); arte: seções 3,
## 7, 8 e 11 do LEIA-ME). As peças montadas, sem sufixo de cultura, são as de
## exemplo da arte; as variações de cultura entram quando a API disser a
## cultura de cada povo.

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


## O primeiro quadro de uma folha de vários quadros, ou a imagem inteira.
static func primeiro_quadro(caminho: String, img: Image) -> Image:
	if QUADRO.has(caminho):
		return img.get_region(Rect2i(0, 0, QUADRO[caminho], img.get_height()))
	return img

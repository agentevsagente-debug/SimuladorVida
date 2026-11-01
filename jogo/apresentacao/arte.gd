extends RefCounted
## Leitura da arte copiada de arte_claude/ para jogo/arte/: paleta, tabelas
## de luz, opções de troca de cor das pessoas e recortes de folhas de quadros.
## Tudo estático; use com `const Arte = preload("res://apresentacao/arte.gd")`.

const RAIZ := "res://arte/"

## Etiquetas de plano, as mesmas de alvo/cena.py.
const CEU := 0
const MUNDO := 1
const PESSOA := 2
const FOGO := 3
const AGUA := 4
const FRENTE := 5

## Linhas da textura de tabelas, na ordem que remap.gdshader espera.
const LINHAS_TABELA := ["", "entardecer", "noite", "fogo_medio", "fogo_perto",
	"noite_agua", "halo_ceu", "noite_primeiro_plano", "entardecer_contorno_pessoas"]

static var paleta := PackedColorArray()
static var _trocas := {}
## Estação corrente ("primavera", "verão", "outono", "inverno"). As peças são
## procuradas primeiro em estacoes/<estação>/ e, se não estiverem lá, valem as
## de verão (como montagem/montar.py, função ler_pasta).
static var estacao := "verão"
## Na arte, as camadas do motor ficam em montagem/; aqui, em camadas/.
const PASTA_DA_ARTE := {"camadas": "montagem"}


## Caminho (sem .png, a partir de arte/) da versão da peça na estação corrente.
static func da_estacao(caminho: String) -> String:
	if estacao == "verão":
		return caminho
	var pasta := caminho.get_slice("/", 0)
	var nome := caminho.substr(pasta.length())
	var sazonal := "estacoes/%s/%s%s" % [estacao, PASTA_DA_ARTE.get(pasta, pasta), nome]
	return sazonal if ResourceLoader.exists(RAIZ + sazonal + ".png") else caminho


static func carregar_paleta() -> void:
	if not paleta.is_empty():
		return
	for linha in FileAccess.get_file_as_string(RAIZ + "paleta.hex").split("\n", false):
		paleta.append(Color.html(linha.strip_edges()))


static func json(caminho: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(RAIZ + caminho))


## Imagem RGBA8 de um PNG importado. A textura importada é solta logo depois.
static func imagem(caminho: String) -> Image:
	var tex: Texture2D = load(RAIZ + caminho)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


static func textura(caminho: String) -> Texture2D:
	return load(RAIZ + caminho)


static func quadro(folha: Image, i: int, largura: int) -> Image:
	return folha.get_region(Rect2i(i * largura, 0, largura, folha.get_height()))


## Textura 32 × 9 com as tabelas; cor que a tabela não cita fica igual.
static func textura_tabelas() -> ImageTexture:
	carregar_paleta()
	var tab: Dictionary = json("camadas/tabelas_luz.json")
	var img := Image.create(32, LINHAS_TABELA.size(), false, Image.FORMAT_RGBA8)
	for linha in LINHAS_TABELA.size():
		var mapa: Dictionary = tab.get(LINHAS_TABELA[linha], {})
		for i in 32:
			var destino := i
			if mapa.has(str(i)):
				destino = int(mapa[str(i)])
			elif mapa.has("outras"):
				destino = int(mapa["outras"])
			img.set_pixel(i, linha, paleta[destino])
	return ImageTexture.create_from_image(img)


static func paleta_vec3() -> PackedVector3Array:
	carregar_paleta()
	var v := PackedVector3Array()
	for c in paleta:
		v.append(Vector3(c.r, c.g, c.b))
	return v


## Opções de troca das pessoas, na ordem de trocas.json:
## {peles: [[pele, sombra]...], cabelos: [[cabelo, brilho]...], roupas: [...]}.
static func opcoes_troca() -> Dictionary:
	if _trocas.is_empty():
		var t: Dictionary = json("habitantes/trocas.json")
		var peles := []
		for k in t["peles"]:
			peles.append(Vector2i(int(t["peles"][k]["pele"]), int(t["peles"][k]["pele_sombra"])))
		var cabelos := []
		for k in t["cabelos"]:
			cabelos.append(Vector2i(int(t["cabelos"][k]["cabelo"]), int(t["cabelos"][k]["cabelo_brilho"])))
		_trocas = {"peles": peles, "cabelos": cabelos, "roupas": t["roupas"].map(func(r): return int(r))}
	return _trocas


## Código de troca que remap.gdshader entende: pele + 4 × cabelo + 24 × roupa.
## cabelo = 5 deixa o cabelo como está (idosos).
static func codigo_troca(pele: int, cabelo: int, roupa: int) -> int:
	return pele + 4 * cabelo + 24 * roupa


## Código a partir de uma tabela de troca de layout.json ({"26": 24, ...}).
static func codigo_de_tabela(troca: Dictionary) -> int:
	var o := opcoes_troca()
	var pele := 0
	var cabelo := 5
	var roupa := 0
	for i in o.peles.size():
		if o.peles[i].x == int(troca.get("26", 26)):
			pele = i
	for i in o.cabelos.size():
		if o.cabelos[i].x == int(troca.get("30", 30)):
			cabelo = i
	roupa = maxi(0, o.roupas.find(int(troca.get("28", 28))))
	return codigo_troca(pele, cabelo, roupa)

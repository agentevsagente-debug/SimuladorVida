extends RefCounted
## Leitura da arte copiada de arte_claude/ para jogo/arte/: paleta, tabelas
## de luz, trocas de cor das pessoas e recortes de folhas de quadros.
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


## Troca simultânea de cores (índices da paleta), como em comum.trocar().
static func trocar(img: Image, mapa: Dictionary) -> Image:
	var cores := {}
	for de in mapa:
		cores[paleta[int(de)].to_rgba32()] = paleta[int(mapa[de])]
	var nova: Image = img.duplicate()
	for y in nova.get_height():
		for x in nova.get_width():
			var c := nova.get_pixel(x, y)
			if c.a > 0.0 and cores.has(c.to_rgba32()):
				nova.set_pixel(x, y, cores[c.to_rgba32()])
	return nova


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


## Tabela de troca de uma pessoa a partir de pele, cabelo e roupa (trocas.json).
static func troca_pessoa(pele: int, cabelo: int, roupa: int) -> Dictionary:
	if _trocas.is_empty():
		_trocas = json("habitantes/trocas.json")
	var base: Dictionary = _trocas["cores_base"]
	var p: Dictionary = _trocas["peles"][str(pele)]
	var c: Dictionary = _trocas["cabelos"][str(cabelo)]
	return {
		int(base["pele"]): int(p["pele"]), int(base["pele_sombra"]): int(p["pele_sombra"]),
		int(base["cabelo"]): int(c["cabelo"]), int(base["cabelo_brilho"]): int(c["cabelo_brilho"]),
		int(base["roupa"]): roupa,
	}


static func opcoes_troca() -> Dictionary:
	if _trocas.is_empty():
		_trocas = json("habitantes/trocas.json")
	return {"peles": _trocas["peles"].keys(), "cabelos": _trocas["cabelos"].keys(), "roupas": _trocas["roupas"]}

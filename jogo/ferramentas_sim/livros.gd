extends SceneTree
## Os livros da estante, para ler como leitor. Gera três livros completos em
## ferramentas_sim/livros/:
## - `extincao.md`: a semente 4, 160 anos, e depois um deus cruel (dilúvios, fogo e raios)
##   até não restar ninguém;
## - `era-nova.md`: no mesmo mundo vazio, 10 anos depois, um povo novo nas ruínas, por 120 anos,
##   e o deus vai embora (a Segunda Era);
## - `abandono.md`: a semente 5, 200 anos, e o deus abandona o mundo com o povo vivo.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/livros.gd [-- <prefixo>]

const Mundo = preload("res://nucleo/mundo.gd")
const PASTA := "res://ferramentas_sim/livros"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var prefixo: String = args[0] if not args.is_empty() else ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	# Extinção, e a era nova nas ruínas.
	var m := Mundo.new(4)
	while m.ano() < 160:
		m.avancar_dias(Mundo.DIAS_ANO)
	var k := 0
	while not m.fim_do_mundo and k < 400:
		var alvo := 0.0
		for g in m.grupos_vivos():
			alvo = m._fogo_do_povo(g)
			break
		m.usar_poder(["diluvio", "fogo", "raio", "terremoto"][k % 4], alvo, 0.95)
		m.avancar_dias(1)
		k += 1
	_gravar(prefixo + "extincao.md", m.livros[-1]["texto"] if not m.livros.is_empty() else "(o mundo não acabou)")
	while m.ano() - m.livros[-1]["ano_fim"] < 10:
		m.avancar_dias(Mundo.DIAS_ANO)
	m.criar_povo(265.0)
	var fim := m.ano() + 120
	while m.ano() < fim and not m.fim_do_mundo:
		m.avancar_dias(Mundo.DIAS_ANO)
	var l: Dictionary = m.abandonar()
	_gravar(prefixo + "era-nova.md", l["texto"])
	# Abandono.
	var a := Mundo.new(5)
	while a.ano() < 200:
		a.avancar_dias(Mundo.DIAS_ANO)
	_gravar(prefixo + "abandono.md", a.abandonar()["texto"])
	quit()


func _gravar(nome: String, texto: String) -> void:
	var f := FileAccess.open("%s/%s" % [PASTA, nome], FileAccess.WRITE)
	f.store_string(texto + "\n")
	f.close()
	print("gravado: ", nome, " (", texto.length(), " caracteres)")

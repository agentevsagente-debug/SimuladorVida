extends SceneTree
## A vida do povo na crônica (pedido do autor em 03/11/2026): nascimentos, casamentos e mortes
## entram todo ano, numa linha própria, mesmo num ano cheio de atos do deus.
## - O mundo do autor (qa/save-sergio-ano3.txt, ano 3, dia 19): a Zeya (evento 20, o primeiro
##   nascimento de Mokon) aparece no ano 3 da crônica viva, ainda em curso, e no texto do ano 3
##   quando o ano fecha.
## - Povo pequeno, 12 anos com 5 gestos do deus por ano (presságio, chuva, fartura, sonho e terra
##   erguida, no fogo do povo): no ano 4 o deus age e, no mesmo ano, há um casamento e uma morte
##   (feitos à mão, se o mundo não os fez). Em todo ano, todo nascimento, casamento e morte de
##   povo pequeno (as mortes sem frase própria) está no texto do ano pelo nome, e a morte com a idade.
## - Povo grande (semente 3, 150 anos): o ano dá a conta ("nasceram ... crianças"), e a linha da
##   vida de um povo grande nunca passa de 400 caracteres.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_cronica_vida.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")

const GESTOS := ["pressagio", "chuva", "fartura", "sonho", "erguer"]
const CONTADAS := ["raio_natural", "raio_divino", "batalha", "fogo", "terremoto", "diluvio", "culpado", "exilio"]

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU  ", msg)


func _initialize() -> void:
	_save_do_autor()
	_povo_pequeno(2)
	_povo_grande(3)
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)


## O texto de um ano dentro da crônica viva ("### Ano 3 (em curso)" até o próximo título).
func _secao(texto: String, titulo: String) -> String:
	var i := texto.find(titulo)
	if i < 0:
		return ""
	var fim := texto.find("\n#", i + titulo.length())
	var fim2 := texto.find("\n*Ano", i + titulo.length())
	if fim < 0 or (fim2 >= 0 and fim2 < fim):
		fim = fim2
	return texto.substr(i, fim - i if fim >= 0 else -1)


func _save_do_autor() -> void:
	var orig := ProjectSettings.globalize_path("res://").path_join("../qa/save-sergio-ano3.txt")
	if not FileAccess.file_exists(orig):
		conferir(false, "não achei o save do autor em " + orig)
		return
	var pasta := "user://testar_cronica_vida"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	# O git do Windows grava o arquivo com CRLF; a soma do mundo salvo é do texto com LF.
	var f := FileAccess.open(pasta + "/mundo.txt", FileAccess.WRITE)
	f.store_string(FileAccess.get_file_as_string(orig).replace("\r", ""))
	f.close()
	var m = Persistencia.carregar(pasta + "/mundo.txt")
	if m == null:
		conferir(false, "o save do autor não carregou")
		return
	var zeya = m.pessoa(m.evento(20).participantes[0])
	conferir(m.evento(20).tipo == "nascimento" and zeya.nome == "Zeya", "o evento 20 não é o nascimento da Zeya")
	var ano3 := _secao(m.cronica_viva(), "### Ano 3 (em curso)")
	conferir(ano3.contains("Zeya"), "a crônica viva não cita a Zeya no ano 3: " + ano3)
	print("save do autor, ano 3 (em curso):\n" + ano3)
	while m.ano() < 4:
		m.avancar_dias(1)
	m.avancar_dias(1)
	var fechado: String = m.cronica_ano(3)
	conferir(fechado.contains("Zeya"), "o ano 3, fechado, não cita a Zeya: " + fechado)
	print("save do autor, ano 3 fechado:\n" + fechado)
	m.encerrar()


func _povo_pequeno(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	var visto := 0
	var forcado := false
	for a in range(1, 13):
		var g = m.grupos_vivos()[0]
		for k in GESTOS.size():
			m.avancar_dias(6)
			m.usar_poder(GESTOS[k], m._fogo_do_povo(g), 0.6)
		if a == 4:
			forcado = _casar_e_morrer(m, g, visto)
		m.avancar_dias(Mundo.DIAS_ANO - m.dia_do_ano())
		m.avancar_dias(1)
		var texto: String = m.cronica_ano(a)
		var divinos := 0
		for i in range(visto, m.eventos.size()):
			var e = m.evento(i)
			if e == null or e.ano != a:
				continue
			if e.causa == "divina":
				divinos += 1
			if m.grupo(e.grupo) == null or m.grupo(e.grupo).membros.size() > 40:
				continue
			var nomes: Array = []
			match e.tipo:
				"nascimento":
					nomes = [e.participantes[0]]
				"casamento":
					nomes = [e.participantes[0], e.participantes[1]]
				"morte":
					if not CONTADAS.has(e.dados["causa"]):
						nomes = [e.participantes[0]]
						var idade: int = e.dados["idade"]
						if idade >= 2:
							conferir(texto.contains("%d anos" % idade), "ano %d: a morte de %s sem a idade (%d): %s" % [a, m.pessoa(nomes[0]).nome, idade, texto])
			for id in nomes:
				conferir(texto.contains(m.pessoa(id).nome), "ano %d: %s (%s) não está no texto do ano: %s" % [a, m.pessoa(id).nome, e.tipo, texto])
		if a == 4:
			conferir(divinos >= 4, "ano 4 com só %d atos do deus" % divinos)
			conferir(texto.contains("casaram-se") or texto.contains("se casaram") or texto.contains("casou"), "ano 4 sem casamento no texto: " + texto)
			conferir(texto.contains("morreu") or texto.contains("morreram"), "ano 4 sem morte no texto: " + texto)
			print("povo pequeno, ano 4 (%d atos do deus%s):\n%s" % [divinos, ", casamento e morte à mão" if forcado else "", texto])
		visto = m.eventos.size()
	m.encerrar()


## Garante um casamento e uma morte no ano: se o mundo ainda não os fez, faz à mão.
func _casar_e_morrer(m, g, desde: int) -> bool:
	var tem := {}
	for i in range(desde, m.eventos.size()):
		var e = m.evento(i)
		if e != null and e.grupo == g.id:
			tem[e.tipo] = true
	var forcou := false
	if not tem.has("morte"):
		# O mais velho dos casados: quem fica viúvo pode casar de novo, logo abaixo.
		var velho = null
		for id in g.membros:
			var p = m.pessoa(id)
			if p.conjuge != -1 and (velho == null or p.nasc_ano < velho.nasc_ano):
				velho = p
		m._morrer(velho, "doenca")
		forcou = true
	if not tem.has("casamento"):
		var homem = null
		var mulher = null
		for id in g.membros:
			var p = m.pessoa(id)
			if p.conjuge == -1 and p.idade(m.ano()) >= 16:
				if p.sexo == "m" and homem == null:
					homem = p
				elif p.sexo == "f" and mulher == null:
					mulher = p
		# Sem par solteiro, um jovem do sexo que falta faz 16 anos agora (só para o teste).
		if homem == null or mulher == null:
			var falta := "m" if homem == null else "f"
			for id in g.membros:
				var p = m.pessoa(id)
				if p.sexo == falta and p.conjuge == -1 and p.idade(m.ano()) >= 10:
					p.nasc_ano = m.ano() - 16
					if falta == "m":
						homem = p
					else:
						mulher = p
					break
		conferir(homem != null and mulher != null, "não achei um par para casar à mão")
		if homem != null and mulher != null:
			m._casar(homem, mulher)
			m.registrar("casamento", "social", 4, g.zona, g.id, [homem.id, mulher.id], {})
			forcou = true
	return forcou


func _povo_grande(semente: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	m.avancar_dias(Mundo.DIAS_ANO * 150 + 1)
	var grandes := 0
	for a in range(100, 151):
		var texto: String = m.cronica_ano(a)
		for linha in texto.split("\n"):
			if linha.contains("crianças") or linha.contains("nasceu uma criança"):
				grandes += 1
				for frase in linha.split(". "):
					if frase.contains("crianças") or frase.contains("nasceu uma criança"):
						conferir(frase.length() <= 400, "ano %d: a vida de um povo grande ficou longa (%d): %s" % [a, frase.length(), frase])
	conferir(grandes > 0, "nenhum ano de povo grande deu a conta da vida")
	print("povo grande, ano 150:\n" + m.cronica_ano(150))
	m.encerrar()

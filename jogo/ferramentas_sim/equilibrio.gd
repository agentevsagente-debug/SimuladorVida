extends SceneTree
## O equilíbrio de longo prazo, visto como jogador. Três medidas, sem o deus:
## - `estagio2 <de> <ate>`: em quantos anos o primeiro povo chega à agricultura (até 150 anos),
##   e se o mundo morre antes;
## - `ausencia <de> <ate>`: o mundo de cada semente, a partir de vários anos (estágios), e um ano
##   inteiro de ausência (o teto): quantos voltam vivos, e quanto a população mudou;
## - `monotonia <semente> <anos>`: as décadas de um mundo e o que houve de notável em cada uma.
## Cada execução grava uma linha por mundo em ferramentas_sim/equilibrio/<modo>-<de>-<ate>.txt
## (ou <modo>-<semente>.txt); o LEIAME junta as tabelas.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/equilibrio.gd -- estagio2 1 20

const Mundo = preload("res://nucleo/mundo.gd")
const PASTA := "res://ferramentas_sim/equilibrio"
## O que conta como notável numa década: os marcos e as crises que um jogador nota (camada
## "chamado", menos as preces e as fomes de rotina, mais estes tipos de "nota").
const NOTAVEIS_NOTA := ["separacao", "migracao", "mudanca", "peste", "profeta", "cisma", "guerra_inicio", "guerra_fim",
	"conquista", "fusao", "extincao_grupo", "descoberta", "descoberta_tecnica", "estagio", "agricultura", "regressao",
	"novo_lider", "costume", "nova_crenca", "crenca", "secularizacao", "renascimento", "expedicao", "edito", "reforma",
	"cultura", "silencio", "dependencia", "desamparo", "estudo_do_ceu", "mito_ruinas", "casamento_entre_grupos", "sucessao",
	"estranhos"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	match args[0]:
		"estagio2":
			_estagio2(int(args[1]), int(args[2]))
		"ausencia":
			_ausencia(int(args[1]), int(args[2]))
		"monotonia":
			_monotonia(int(args[1]), int(args[2]))
	quit()


func _gravar(nome: String, linhas: PackedStringArray) -> void:
	var f := FileAccess.open("%s/%s" % [PASTA, nome], FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\n")
	f.close()


## semente | ano da primeira descoberta | ano do estágio 2 (-1: não chegou) | regrediu? | morreu antes?
func _estagio2(de: int, ate: int) -> void:
	var linhas: PackedStringArray = []
	for s in range(de, ate + 1):
		var m := Mundo.new(s, [], Mundo.HORA_INICIAL, true)
		var desc := -1
		var est2 := -1
		var visto := 0
		var esqueceu := 0
		while m.ano() <= 150 and not m.fim_do_mundo and est2 < 0:
			m.avancar_dias(Mundo.DIAS_ANO)
			for i in range(visto, m.eventos.size()):
				var e = m.evento(i)
				if e == null:
					continue
				if e.tipo == "descoberta" and desc < 0:
					desc = e.ano
				elif e.tipo == "agricultura" and est2 < 0:
					est2 = e.ano
				elif e.tipo == "conhecimento_perdido":
					esqueceu += 1
			visto = m.eventos.size()
		linhas.append("%d\t%d\t%d\t%d\t%s\t%d" % [s, desc, est2, esqueceu, "sim" if m.fim_do_mundo else "não", m.populacao()])
		print(linhas[-1])
	_gravar("estagio2-%d-%d.txt" % [de, ate], linhas)


## semente | ano de partida | estágio | população antes | depois de 1 ano fora | vivo?
func _ausencia(de: int, ate: int) -> void:
	var linhas: PackedStringArray = []
	for s in range(de, ate + 1):
		var m := Mundo.new(s, [], Mundo.HORA_INICIAL, true)
		for partida in [3, 25, 60, 120]:
			while m.ano() < partida and not m.fim_do_mundo:
				m.avancar_dias(Mundo.DIAS_ANO)
			if m.fim_do_mundo:
				linhas.append("%d\t%d\t-\t0\t0\tjá estava morto" % [s, partida])
				break
			var est := 0
			for g in m.grupos_vivos():
				est = maxi(est, g.estagio)
			var antes := m.populacao()
			var r := m.avancar_ausencia(1.0e9)
			var chamados: Array = r["chamados"].map(func(d): return d["tipo"])
			linhas.append("%d\t%d\t%d\t%d\t%d\t%s\t%s" % [s, partida, est, antes, m.populacao(), "sim" if not m.fim_do_mundo else "NÃO",
				", ".join(PackedStringArray(chamados.filter(func(t): return t in ["os_ultimos", "fim_do_mundo", "peste", "guerra_inicio"])))])
			print(linhas[-1])
	_gravar("ausencia-%d-%d.txt" % [de, ate], linhas)


## década | eventos notáveis (tipos) | população
func _monotonia(semente: int, anos: int) -> void:
	var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
	var linhas: PackedStringArray = []
	var visto := 0
	while m.ano() <= anos and not m.fim_do_mundo:
		var dec: int = (m.ano() - 1) / 10
		var notaveis: Array = []
		while (m.ano() - 1) / 10 == dec and not m.fim_do_mundo:
			m.avancar_dias(Mundo.DIAS_ANO)
			for i in range(visto, m.eventos.size()):
				var e = m.evento(i)
				if e == null:
					continue
				var camada := m.camada(e)
				if (camada == "chamado" and not e.tipo in ["prece", "fome_inicio", "doenca_inicio", "morte", "linhagem"]) \
						or (camada != "ambiente" and NOTAVEIS_NOTA.has(e.tipo)):
					notaveis.append(e.tipo)
			visto = m.eventos.size()
		linhas.append("%d\t%d\t%d\t%s" % [dec * 10 + 1, notaveis.size(), m.populacao(), ", ".join(PackedStringArray(notaveis))])
		print(linhas[-1].substr(0, 160))
	_gravar("monotonia-%d.txt" % semente, linhas)

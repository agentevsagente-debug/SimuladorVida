extends SceneTree
## Regressão do núcleo, sem gráfico. Primeiro, o desempenho com a população máxima: nenhum
## passo acima de 5 ms e nenhuma consulta acima de 2 ms (veja desempenho.gd). Depois, roda
## as sementes 1 a 5 por 100 anos, e a semente 1 com o cenário de intervenções; cada mundo
## roda duas vezes e as crônicas têm de sair iguais. A semente 1 também é salva e carregada
## no meio e tem de terminar igual.
## Grava as crônicas em ferramentas_sim/cronicas/. Sai com código 1 se algo falhar.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/regressao.gd

const Mundo = preload("res://nucleo/mundo.gd")
const Cenario = preload("res://nucleo/cenario.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Desempenho = preload("res://ferramentas_sim/desempenho.gd")
const ANOS := 100

var falhas := 0


func conferir(cond: bool, msg: String) -> void:
	print(("ok      " if cond else "FALHOU  ") + msg)
	if not cond:
		falhas += 1


func rodar(semente: int, cenario: String) -> Array:
	var cmds: Array = [] if cenario.is_empty() else Cenario.ler_arquivo(cenario)
	var m := Mundo.new(semente, cmds, Mundo.HORA_INICIAL, true)
	var t := Time.get_ticks_usec()
	m.avancar_dias(Mundo.DIAS_ANO * ANOS)
	var dt := (Time.get_ticks_usec() - t) / 1e6
	var sub := "%d anos, %s." % [ANOS, "sem intervenção do deus" if cenario.is_empty() else "cenário " + cenario.get_file()]
	return [m.cronica_completa("Crônica do mundo da semente %d" % semente, sub), dt, m]


func _initialize() -> void:
	# Desempenho: cada janela em processos novos; se passar da meta, mede de novo, com mais
	# execuções, antes de dar como falha (esta máquina tem picos de outros processos).
	for janela in Desempenho.JANELAS:
		var r := Desempenho.medir_em_processos(janela, 3)
		if not Desempenho.falhas(r).is_empty():
			r = Desempenho.medir_em_processos(janela, 5)
		var f := Desempenho.falhas(r)
		conferir(f.is_empty(), "desempenho: " + Desempenho.texto(r) + ("" if f.is_empty() else "
        " + "
        ".join(f)))
	var casos := [[1, ""], [2, ""], [3, ""], [4, ""], [5, ""],
		[1, "res://ferramentas_sim/cenarios/semente1-intervencoes.txt"]]
	for caso in casos:
		var a := rodar(caso[0], caso[1])
		var b := rodar(caso[0], caso[1])
		var nome := "semente-%d%s" % [caso[0], "" if caso[1].is_empty() else "-intervencoes"]
		var m = a[2]
		conferir(a[0] == b[0], "%s: determinística (%.2f s por 100 anos, %d pessoas e %d povos no fim)" % [
			nome, a[1], m.populacao(), m.grupos_vivos().size()])
		var f := FileAccess.open("res://ferramentas_sim/cronicas/%s.md" % nome, FileAccess.WRITE)
		f.store_string(a[0] + "\n")
		f.close()
		conferir(a[0].find("{") < 0 and a[0].find("}") < 0, "%s: sem marcas de modelo vazando no texto" % nome)
	# Salvar e carregar no meio não muda nada.
	var inteiro: String = rodar(1, "")[0]
	var m1 := Mundo.new(1, [], Mundo.HORA_INICIAL, true)
	m1.avancar_dias(Mundo.DIAS_ANO * 43 + 17)
	Persistencia.salvar(m1, "user://regressao.txt")
	var m2 = Persistencia.carregar("user://regressao.txt")
	m2.avancar_dias(Mundo.DIAS_ANO * ANOS - (Mundo.DIAS_ANO * 43 + 17))
	conferir(m2.cronica_completa("Crônica do mundo da semente 1", "%d anos, sem intervenção do deus." % ANOS) == inteiro,
		"semente-1: salvar e carregar no ano 44 dá a mesma crônica")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://regressao.txt"))
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)

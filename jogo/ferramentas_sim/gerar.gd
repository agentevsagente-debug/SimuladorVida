extends SceneTree
## Gera a crônica de um mundo. Uso:
##   ferramentas_sim/godot.sh res://ferramentas_sim/gerar.gd -- <semente> <cenario|-> <saida.md> [anos]
## Escreve também <saida>.resumo.txt com os tempos.

const Mundo = preload("res://nucleo/mundo.gd")
const Cenario = preload("res://nucleo/cenario.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var semente := int(args[0])
	var cenario_path: String = args[1]
	var saida: String = args[2]
	var anos := 100 if args.size() < 4 else int(args[3])
	var comandos: Array = []
	var nome_cenario := "sem intervenção do deus"
	if cenario_path != "-":
		comandos = Cenario.ler_arquivo(cenario_path)
		nome_cenario = "cenário %s (%d intervenções)" % [cenario_path.get_file(), comandos.size()]
	var m := Mundo.new(semente, comandos)
	var t0 := Time.get_ticks_usec()
	var t_max := 0.0
	for a in anos:
		var ta := Time.get_ticks_usec()
		m.avancar_dias(Mundo.DIAS_ANO)
		t_max = maxf(t_max, (Time.get_ticks_usec() - ta) / 1e6)
	var t_total := (Time.get_ticks_usec() - t0) / 1e6
	var texto := m.cronica_completa("Crônica do mundo da semente %d" % semente, "%d anos, %s." % [anos, nome_cenario])
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string(texto + "\n")
	f.close()
	var r := "semente=%d cenario=%s anos=%d\n" % [semente, cenario_path, anos]
	r += "tempo_ano_mais_lento=%.3fs tempo_%d_anos=%.3fs\n" % [t_max, anos, t_total]
	r += "eventos=%d populacao_final=%d grupos_vivos=%d\n" % [m.eventos.size(), m.populacao(), m.grupos_vivos().size()]
	var fr := FileAccess.open(saida.get_basename() + ".resumo.txt", FileAccess.WRITE)
	fr.store_string(r)
	fr.close()
	print(r)
	quit()

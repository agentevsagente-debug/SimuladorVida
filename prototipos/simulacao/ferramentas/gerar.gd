extends SceneTree
## Gera a crônica de um mundo. Uso:
##   godot --headless --path . --script res://ferramentas/gerar.gd -- <semente> <cenario|-> <saida.md> [anos]
## Escreve também <saida>.resumo.txt com tempos e a contagem do que foi narrado.

const Mundo = preload("res://nucleo/mundo.gd")
const Cronista = preload("res://nucleo/cronista.gd")
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
	var t_ano1 := 0.0
	var t_max := 0.0
	var ano_max := 1
	for a in anos:
		var ta := Time.get_ticks_usec()
		m.avancar_dias(Mundo.DIAS_ANO)
		var dt := (Time.get_ticks_usec() - ta) / 1e6
		if a == 0:
			t_ano1 = dt
		if dt > t_max:
			t_max = dt
			ano_max = a + 1
	var t_total := (Time.get_ticks_usec() - t0) / 1e6
	var t1 := Time.get_ticks_usec()
	var cr := Cronista.new(m)
	var texto := cr.escrever("Crônica do mundo da semente %d" % semente,
		"%d anos, %s." % [anos, nome_cenario])
	var t_cronica := (Time.get_ticks_usec() - t1) / 1e6
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string(texto + "\n")
	f.close()
	# Resumo: tempos e o que entrou na crônica.
	var narrados := {}
	for id in cr._usados:
		var e = m.eventos[id]
		var chave: String = e.tipo
		if e.tipo == "separacao":
			chave += ":" + e.dados["causa"]
		narrados[chave] = narrados.get(chave, 0) + 1
	var ks: Array = narrados.keys()
	ks.sort()
	var r := "semente=%d cenario=%s anos=%d\n" % [semente, cenario_path, anos]
	r += "tempo_ano_1=%.3fs tempo_ano_mais_lento=%.3fs(ano %d) tempo_%d_anos=%.3fs tempo_cronica=%.3fs\n" % [t_ano1, t_max, ano_max, anos, t_total, t_cronica]
	r += "eventos=%d populacao_final=%d grupos_vivos=%d passos=%d\n" % [m.eventos.size(), m.populacao(), m.grupos_vivos().size(), m.passo]
	r += "narrados:"
	for k in ks:
		r += " %s=%d" % [k, narrados[k]]
	r += "\n"
	var fr := FileAccess.open(saida.get_basename() + ".resumo.txt", FileAccess.WRITE)
	fr.store_string(r)
	fr.close()
	print(r)
	quit()

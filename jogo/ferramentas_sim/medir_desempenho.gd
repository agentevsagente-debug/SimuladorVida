extends SceneTree
## Desempenho com a população máxima, no estágio 6, medido como a apresentação usa o mundo
## (veja desempenho.gd).
## gerar: procura, entre algumas sementes, o mundo de maior população com um povo no
##   estágio 6 e o guarda, comprimido, em ferramentas_sim/mundo_grande.bin (usado pela
##   regressão). Refazer quando o formato do mundo salvo mudar.
## medir (padrão): mede as janelas de desempenho, cada uma em processos novos, e imprime.
## janela <ano> <dia> <hora> <passos>: uso interno; mede uma janela neste processo e
##   imprime o resultado em JSON.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/medir_desempenho.gd -- [gerar|medir]

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")
const Desempenho = preload("res://ferramentas_sim/desempenho.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "medir"
	match modo:
		"gerar":
			_gerar()
		"janela":
			var r := Desempenho.janela_aqui(int(args[1]), int(args[2]), int(args[3]), int(args[4]))
			print(Desempenho.MARCA + JSON.stringify(r))
		_:
			for janela in Desempenho.JANELAS:
				var r := Desempenho.medir_em_processos(janela, 3)
				print(Desempenho.texto(r))
				for falha in Desempenho.falhas(r):
					print("   acima da meta: ", falha)
	quit()


func _gerar() -> void:
	var melhor := 0
	for semente in [1, 2, 3, 4, 7, 9]:
		var m := Mundo.new(semente, [], Mundo.HORA_INICIAL, true)
		for a in 300:
			m.avancar_dias(Mundo.DIAS_ANO)
			var est6 := false
			for g in m.grupos_vivos():
				est6 = est6 or g.estagio >= 6
			if est6 and m.populacao() > melhor:
				Persistencia.salvar(m, Desempenho.TEMPORARIO)
				melhor = m.populacao()
				print("semente %d ano %d: %d pessoas" % [semente, m.ano(), m.populacao()])
	var texto := FileAccess.get_file_as_string(Desempenho.TEMPORARIO)
	var f := FileAccess.open_compressed(Desempenho.MUNDO_GRANDE, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	f.store_string(texto)
	f.close()
	print("guardado em ", Desempenho.MUNDO_GRANDE)

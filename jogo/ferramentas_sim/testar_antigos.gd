extends SceneTree
## O arquivo dos antigos não muda o mundo. Roda a mesma semente três vezes, lado a lado:
## sem arquivar, arquivando sem parar, e arquivando com o mundo salvo e carregado de novo a
## cada 50 anos (o carregado segue no lugar do original), e também no meio da virada, entre as
## duas fatias da escrita do ano que acabou. A cada 50 anos, os três precisam
## ter a mesma crônica inteira, o mesmo estado do sorteio, o mesmo passo, os mesmos eventos e
## a mesma população. Opcional: acabar com todos num ano, para conferir o livro da era
## escrito depois de os eventos antigos saírem.
## Uso: ferramentas_sim/godot.sh res://ferramentas_sim/testar_antigos.gd -- <semente> <anos> [nenhum|caprichoso] [ano_do_fim]

const Mundo = preload("res://nucleo/mundo.gd")
const Persistencia = preload("res://nucleo/persistencia.gd")

var falhas := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var semente := int(args[0])
	var anos := int(args[1])
	var estilo: String = args[2] if args.size() > 2 else "nenhum"
	var ano_fim := int(args[3]) if args.size() > 3 else -1
	# Um caminho por execução: várias podem rodar ao mesmo tempo.
	var caminho := "user://antigos_teste/%s-%d-%d.txt" % [estilo, semente, ano_fim]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(caminho.get_base_dir()))
	var mundos: Array = [Mundo.new(semente, [], Mundo.HORA_INICIAL, true), Mundo.new(semente, [], Mundo.HORA_INICIAL, true), Mundo.new(semente, [], Mundo.HORA_INICIAL, true)]
	mundos[0].arquivar = false
	var deuses: Array = []
	for k in 3:
		var d := RandomNumberGenerator.new()
		d.seed = semente * 7919 + 3
		deuses.append(d)
	var nomes := ["sem arquivar", "arquivando", "salvo e carregado"]
	var t0 := Time.get_ticks_usec()
	for a in anos:
		for k in 3:
			var m = mundos[k]
			if k == 2 and m.ano() % 50 == 0:
				# Salvo e carregado no meio da escrita do ano que acabou (entre as fatias da virada).
				m.avancar_hora()
				m.avancar_hora()
				if not Persistencia.salvar(m, caminho):
					_falhou("ano %d: não salvou na virada" % m.ano())
				var c = Persistencia.carregar(caminho)
				if c == null:
					_falhou("ano %d: não carregou na virada" % m.ano())
				else:
					m = c
					mundos[2] = c
			for d in Mundo.DIAS_ANO:
				if d == 0 and m.hora() != 0:
					while m.hora() != 0:
						m.avancar_hora()
				else:
					m.avancar_dias(1)
				if estilo == "caprichoso" and not m.fim_do_mundo and m.ano() >= 5 and deuses[k].randf() < 0.04:
					var poder: String = m.PODERES[deuses[k].randi_range(0, m.PODERES.size() - 1)]
					m.usar_poder(poder, deuses[k].randf_range(130.0, 470.0), deuses[k].randf_range(0.3, 0.95))
			if m.ano() == ano_fim and not m.fim_do_mundo:
				for id in m.vivos.keys():
					m._morrer(m.pessoas[id], "doenca")
			if m.fim_do_mundo and m.ano() - m.livros[-1]["ano_fim"] >= 10 and m.livros.size() == m.era:
				m.criar_povo(260.0)
		if mundos[0].ano() % 50 == 0:
			if not Persistencia.salvar(mundos[2], caminho):
				_falhou("ano %d: não salvou" % mundos[0].ano())
			var c = Persistencia.carregar(caminho)
			if c != null and c.recuperado_de != "":
				_falhou("ano %d: carregou de uma cópia (%s), não do arquivo que acabou de ser salvo" % [mundos[0].ano(), c.recuperado_de])
			if c == null:
				_falhou("ano %d: não carregou" % mundos[0].ano())
			else:
				mundos[2] = c
			_comparar(mundos, nomes)
	_comparar(mundos, nomes)
	print("arquivados: %d linhas (%d eventos vivos de %d; %d pessoas na memória)" % [mundos[1].arquivo_linhas,
		mundos[1].eventos.filter(func(e): return e != null).size(), mundos[1].eventos.size(), mundos[1].pessoas.size()])
	print("%.0f s; %d falhas" % [(Time.get_ticks_usec() - t0) / 1e6, falhas])
	quit(1 if falhas > 0 else 0)


func _comparar(mundos: Array, nomes: Array) -> void:
	var ref = mundos[0]
	var cr: String = ref.cronica()
	var livros: Array = ref.livros.map(func(l): return l["texto"])
	for k in [1, 2]:
		var m = mundos[k]
		var dif: Array = []
		if m.rng.state != ref.rng.state:
			dif.append("sorteio")
		if m.passo != ref.passo:
			dif.append("passo")
		if m.eventos.size() != ref.eventos.size():
			dif.append("eventos %d x %d" % [m.eventos.size(), ref.eventos.size()])
		if m.populacao() != ref.populacao():
			dif.append("população")
		var cm: String = m.cronica()
		if cm != cr:
			var i := 0
			while i < mini(cm.length(), cr.length()) and cm[i] == cr[i]:
				i += 1
			dif.append("crônica (a partir de: «%s» x «%s»)" % [cr.substr(maxi(0, i - 60), 140), cm.substr(maxi(0, i - 60), 140)])
		if m.livros.map(func(l): return l["texto"]) != livros:
			dif.append("livros")
		if not dif.is_empty():
			_falhou("ano %d, %s: %s" % [ref.ano(), nomes[k], "; ".join(dif)])
	print("ano %d: %d pessoas, %d eventos, %d arquivados, era %d" % [ref.ano(), ref.populacao(), ref.eventos.size(),
		mundos[1].arquivo_linhas, ref.era])


func _falhou(t: String) -> void:
	falhas += 1
	print("FALHOU: ", t)

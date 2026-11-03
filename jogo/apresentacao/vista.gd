extends Node2D
## Vista do mundo (480 × 160), montada com as peças de arte_claude/pecas.
##
## As partes fixas (terreno, vegetação, construções, marcas) viram uma imagem
## só, refeita apenas quando as construções, as zonas ou a estação mudam. O
## horário (dia, entardecer, noite) e a luz das fogueiras saem de
## remap.gdshader, que troca as cores pelas tabelas da arte. Pessoas,
## fogueiras, água, sinais e efeitos são desenhados por cima.
##
## A vista pode aproximar 2x e seguir a pessoa acompanhada; o nó pai recorta
## a área do mundo.
##
## Argumentos (depois de "--"):
##   --cena=layout        monta exatamente arte/camadas/layout.json (teste de fidelidade)
##   --hora=dia|entardecer|noite|N   horário inicial (mundo novo)
##   --congelar           o tempo não anda
##   --semente=N          semente do mundo novo
##   --mundo-novo         ignora o mundo salvo e não grava nada
##   --anos=N, --dias=N   avança N anos e N dias antes de abrir (mundo novo, testes)
##   --cenario-raro=NOME  teste: força um acontecimento raro (veja cenarios_raros.gd)
##   --simular-ausencia=H depois de carregar, avança como se o jogador tivesse saído H horas (testes)
##   --com-povo           o mundo novo já nasce com o primeiro povo (sem ele, --mundo-novo começa vazio,
##                        mesmo com --semente; --semente sozinha, --dias, --anos, --cena e
##                        --cenario-raro já nascem com o povo)
##   --extinguir[=N]      teste: todos morrem (e o mundo vazio anda N anos)
##   --capturar=ARQUIVO   grava a vista (480 × 160) em PNG e fecha
##   --capturar-apos=S    espera S segundos antes de capturar
##   --capturar-tudo      captura a tela inteira (480 × 178), com a alça
##   --quadros=N          em vez de um quadro, grava N quadros (ARQUIVO_00.png ...)
##   --intervalo=S        entre os quadros da sequência (padrão 0,2 s)
##   --efeito=chuva|raio  força chuva (e raios) sobre a aldeia, para testes

signal pessoa_clicada(id: int)

const Arte = preload("res://apresentacao/arte.gd")
const Terreno = preload("res://apresentacao/terreno.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")
const Pessoas = preload("res://apresentacao/pessoas.gd")
const Atmosfera = preload("res://apresentacao/atmosfera.gd")
const Sinais = preload("res://apresentacao/sinais.gd")
const Vida = preload("res://apresentacao/vida.gd")
const Obras = preload("res://apresentacao/obras.gd")
const CenariosRaros = preload("res://apresentacao/cenarios_raros.gd")
const Ceu = preload("res://apresentacao/ceu.gd")
const REMAP = preload("res://apresentacao/remap.gdshader")

const LARGURA := 480
const ALTURA := 160
const ESTADOS := ["dia", "entardecer", "noite"]
const DIA := 0
const ENTARDECER := 1
const NOITE := 2
const FUNDOS := ["ceu", "montanhas_longe", "montanhas_perto", "mata_distante"]
## Quanto cada plano de fundo acompanha a câmera (0 = parado no infinito).
const PARALAXE := [0.05, 0.35, 0.55, 0.8]
const HORAS_NOMEADAS := {"dia": 12, "entardecer": 18, "noite": 22}
## Peças pequenas do cenário que somem quando uma construção cai em cima.
const PECAS_MIUDAS := ["capim", "capim_seco", "arbusto", "arbusto_frutas", "pedra_pequena",
	"pedra_grande", "tronco_deriva", "juncos"]
## Árvores que o fogo do deus deixa carbonizadas, com a coluna do tronco.
const ARVORES := {"arvore_copa_a": 19, "arvore_copa_b": 14, "pinheiro_a": 19, "pinheiro_b": 11, "pinheiro_fundo": 15}
const ZOOM_SEGUIR := 2
## Casa de cada estágio, para as janelas acesas (`_luz`) e as chaminés (LEIA-ME, seção 19).
const CASAS := {2: "estagio2/casa_taipa", 3: "estagio3/casa_pedra", 4: "estagio4/casa_enxaimel",
	5: "estagio5/casa_caiada", 6: "estagio6/casa_tijolo"}
## Folga mínima entre construções vizinhas (auditoria 2, N1).
const LOTE_FOLGA := 3.0
const VAO_ENTRE_POVOS := 10.0
const X_CONVITE := 275.0  # a clareira onde o convite do mundo vazio aparece (o x padrão do criar_povo)
var _convite := false
var som: Node  # o som (a moldura põe): a vida toca a lança e o grito da caçada
const FILEIRA_ATRAS := 4  # px acima que a fileira de trás fica (API: `fileira` 1)
const ALCANCE_PESSOA := 3.0  # px em volta da figura que ainda contam como "sobre a pessoa"

var sim: Simulacao
var modo_discreto := false
var seguindo := false        # a câmera aproxima e segue a pessoa acompanhada
var foco := -1               # a caixa de preces levou a vista até esta pessoa (por FOCO_SEGUNDOS)
var _foco_ate := 0.0
const FOCO_SEGUNDOS := 20.0
var zoom := 1
var camera := Vector2.ZERO   # canto de cima à esquerda da área vista, em pixels do mundo
var figuras: Array = []      # o que foi desenhado neste quadro, para a dica do cursor

var _layout: Dictionary
var _modo_layout := false
var _hora_fixa := -1.0
var _capturar := ""
var _quadros_ate_capturar := 4
var _capturar_apos := 0.0
var _capturar_tudo := false
var _quadros := 1
var _intervalo := 0.2
var _gravados := 0

var _materiais: Array[ShaderMaterial] = []
var _fundos: Array[Sprite2D] = []
var _tex_fundo := {}       # "ceu_dia" -> Texture2D, recortada à área usada
var _canto_fundo := []     # canto do recorte de cada plano de fundo
var _tex_reflexo := []     # por estado
var _mundo: Sprite2D
var _agua: Sprite2D
var _reflexo: Sprite2D
var _frente: Sprite2D
var _fogueiras: Node2D
var _pessoas: Pessoas
var _sinais: Sinais
var _quadros_agua: Array[Image] = []
var _tex_agua: Array[ImageTexture] = []
var _sup := PackedInt32Array()
var _tipos := []           # tipo do terreno por coluna de 8 px
var _fogos: Array = []     # [{canto: Vector2i, centro: float, luz: Vector2}]
var _estado := []
var _relogio := 0.0
var _quadro_agua := -1
var _quadro_fogo := -1
var _refazer := true
# DEPURAR_TEMPO: quanto cada parte do quadro custa (µs por quadro, a cada 10 s)
var _medindo := OS.has_environment("DEPURAR_TEMPO")
var _t0 := 0
var _tempos := {}
var _quadros_medidos := 0
var _medir_desde := 0.0
var _tex_nascendo: Texture2D
var recomeco := {}
var _interface: Node2D  # a interface se apresenta aqui (avisos de eventos, quem sonhou)
## Os eventos dos gestos do deus (a origem de um costume que vem da repetição).
const GESTOS_DO_DEUS := ["chuva_divina", "raio_divino", "fogo_divino", "fogo_brando", "fartura_divina", "terra_erguida",
	"sonho", "seca_divina", "diluvio", "terremoto_divino", "pressagio", "cura"]  # {grupo, ini}: o povo novo chegando e acendendo a primeira fogueira
var _chave_fixo := []
var _vida: Vida
var _estacao_fundos := ""
var _gelo := []            # colunas de água congelada
var _tremor := 0.0
var _ceu: Ceu
var _tex_fogueira: Texture2D
var _atmosfera: Atmosfera
var _minutos := 0.0        # fração de hora fixa (--hora=17.5 com --congelar)
var _ceu_especial := ""    # "seca" ou "eclipse": troca o céu de dia
var _eclipse_ate := -1
var _seca_ate := -1          # a seca do deus amarela o céu logo depois do gesto
var _larguras := {}          # peça -> largura do desenho (para os lotes)
var _brasas := []            # centros dos fogos em brasas agora
var _copas: Array = []       # topo da copa de cada árvore desenhada: Vector2(tronco, linha de cima)
var _baixa: Array = []       # trechos [x0, x1] com vegetação baixa (arbustos, capim, pedras)
var _tex_brasas: Texture2D
var _luzes: Sprite2D         # janelas acesas, por cima das casas e sem a tabela de noite
var _tex_luzes := []         # [todas as casas, só as acordadas de madrugada]
var rodas: Array = []        # [{x, base}] rodas d'água (a vida desenha, animadas)
var chamines: Array = []     # pontos de onde sobe a fumaça das lareiras no inverno
var beira_visivel := 0         # a primeira coluna depois da água desenhada do lago
var telhados: Array = []
var estandartes: Array = []  # [{folha, x, base}] no alto da casa principal de cada povo (a vida anima)     # pontos no alto das casas onde os pássaros pousam: Vector2(x, linha de cima)
var _chamines_json := {}
var _camera_aplicada := [-1, Vector2(-1, -1)]


func _ready() -> void:
	var args := _ler_argumentos()
	_modo_layout = args.get("cena", "") == "layout"
	_capturar = args.get("capturar", "")
	_capturar_apos = float(args.get("capturar-apos", "0"))
	_capturar_tudo = args.has("capturar-tudo")
	_quadros = int(args.get("quadros", "1"))
	_intervalo = float(args.get("intervalo", "0.2"))
	Arte.carregar_paleta()
	_layout = Arte.json("camadas/layout.json")
	_criar_nos()

	var hora: String = args.get("hora", "")
	if _modo_layout:
		_hora_fixa = HORAS_NOMEADAS.get(hora, 12)
	else:
		sim = Simulacao.new()
		add_child(sim)
		sim.construcoes_mudaram.connect(func(): _refazer = true)
		sim.zonas_mudaram.connect(func(): _refazer = true)
		sim.eventos_novos.connect(_ao_receber_eventos)
		sim.mundo_trocado.connect(_ao_trocar_mundo)
		_vida = Vida.new(self, sim)
		var novo := args.has("mundo-novo") or args.has("semente") or args.has("cena") or args.has("dias")
		# --mundo-novo começa vazio, como o jogo, a menos que venha --com-povo (mesmo com --semente);
		# --semente sozinha e os caminhos que precisam de gente (--anos, --dias, --cena,
		# --cenario-raro) nascem com o povo
		var com_povo := args.has("com-povo") or (args.has("semente") and not args.has("mundo-novo")) \
			or args.has("cena") or args.has("dias") \
			or args.has("anos") or args.has("cenario-raro")
		sim.salvar_em_disco = not novo
		var semente := int(args.get("semente", str(randi())))
		var hf := float(HORAS_NOMEADAS.get(hora, hora)) if hora != "" else -1.0
		if args.has("anos") or args.has("dias"):
			sim.iniciar(semente, -1, false, true)
			sim.mundo.avancar_dias(40 * int(args.get("anos", "0")) + int(args.get("dias", "0")))
			if hf >= 0.0:
				while sim.mundo.tempo()["hora"] != int(hf):
					sim.mundo.avancar_hora()
			sim.iniciar_de_mundo()
		else:
			sim.iniciar(semente, int(hf) if hf >= 0.0 else -1, not novo, com_povo)
		if args.has("extinguir"):  # teste: todos morrem; com N > 0, o mundo vazio anda N anos
			_extinguir(int(args["extinguir"]) if args["extinguir"] != "" else 0)
		if args.has("simular-ausencia"):  # teste: como se o jogador tivesse saído N horas
			sim.ausencia = sim.mundo.avancar_ausencia(float(args["simular-ausencia"]) * 3600.0)
			sim.iniciar_de_mundo()
		if args.has("cenario-raro"):  # teste: força um acontecimento raro (cenarios_raros.gd)
			var nome: String = args["cenario-raro"]
			CenariosRaros.preparar(nome, self)
			get_tree().create_timer(1.5).timeout.connect(func(): CenariosRaros.encenar(nome, self, _interface, get_tree()))
		sim.congelado = args.has("congelar")
		if sim.congelado and hf >= 0.0:
			_minutos = hf - floorf(hf)
		print("[vista] semente=%d %s" % [semente, "mundo novo" if novo else "mundo salvo, se houver"])
	var efeito: String = args.get("efeito", "")
	if efeito in ["chuva", "raio"]:
		_atmosfera.forcar_chuva = Vector2i(200, 330)
		_atmosfera.forcar_raio = efeito == "raio"


func avancar(delta: float, desenhar: bool) -> void:
	_t0 = Time.get_ticks_usec()
	if sim:
		sim.avancar(delta)
	_medir("sim")
	if not desenhar:
		return
	_atualizar_convite()
	_relogio += delta
	if sim and _chave_fixo != _chave_do_fixo():
		_refazer = true
	if _refazer:
		_refazer = false
		_chave_fixo = _chave_do_fixo() if sim else []
		_montar_fixo()
	_medir("fixo")
	_atualizar_horario()
	_atualizar_agua()
	_atualizar_fogueiras()
	_medir("horario_agua_fogo")
	var desenho: Array = _figuras_layout() if _modo_layout else _vida.atualizar(delta, _relogio)
	figuras = desenho if _modo_layout else _vida.figuras
	_medir("vida")
	_atualizar_camera(delta)
	_pessoas.definir(desenho)
	_medir("pessoas")
	if sim:
		_sinais.atualizar(sim, self, _relogio, figuras)
	_medir("sinais")
	_atmosfera.avancar(delta, _hora(), _estado[0] if _estado[2] < 0.5 else _estado[1], _fogos,
		{} if _modo_layout else sim.clima, _modo_layout)
	if _ceu:
		var meio: int = _estado[0] if _estado[2] < 0.5 else _estado[1]
		_ceu.mostrar_sol = _estado[3] == ""
		var clima_ceu: String = ESTADOS[meio]
		if _estado[3] in ["tempestade", "diluvio"] and meio != NOITE:
			clima_ceu = "tempestade"
		elif _estado[3] == "seca" and meio == DIA:
			clima_ceu = "seca"
		_ceu.avancar(delta, _hora(), clima_ceu, int(sim.tempo.get("dia", 1)),
			not sim.clima.get("tempestade", {}).is_empty() or _atmosfera.chovendo())
	_medir("atmosfera_ceu")
	_relatar_tempo()
	if _capturar != "" and _relogio >= _capturar_apos + _gravados * _intervalo:
		_quadros_ate_capturar -= 1
		if _quadros_ate_capturar <= 0:
			_quadros_ate_capturar = 1 << 30
			queue_redraw()  # no modo de baixo consumo, sem mudança não há quadro novo
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			if not _capturar_tudo:
				img = img.get_region(Rect2i(Vector2i(get_parent().global_position), Vector2i(LARGURA, ALTURA)))
			var arquivo := _capturar if _quadros == 1 else _capturar.replace(".png", "_%02d.png" % _gravados)
			img.save_png(arquivo)
			_gravados += 1
			_quadros_ate_capturar = 1
			print("[vista] capturada em %s" % arquivo)
			if _gravados >= _quadros:
				if sim:
					sim.encerrar()
				if som:
					som.encerrar()
				get_tree().quit()


## Ponto da tela da vista (0..480, 0..160) para pixels do mundo.
func para_mundo(ponto: Vector2) -> Vector2:
	return ponto / zoom + camera


func para_tela(ponto: Vector2) -> Vector2:
	return (ponto - camera) * zoom


func _medir(parte: String) -> void:
	if not _medindo:
		return
	var agora := Time.get_ticks_usec()
	_tempos[parte] = _tempos.get(parte, 0) + agora - _t0
	_t0 = agora


func _relatar_tempo() -> void:
	if not _medindo:
		return
	_quadros_medidos += 1
	if _relogio - _medir_desde < 10.0:
		return
	var partes := []
	for k in _tempos:
		partes.append("%s=%d" % [k, _tempos[k] / _quadros_medidos])
	print("[tempo] quadros=%d fps=%.1f render_cpu=%.2fms processo=%.2fms %s" % [_quadros_medidos,
		_quadros_medidos / (_relogio - _medir_desde), RenderingServer.get_frame_setup_time_cpu(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, " ".join(partes)])
	_tempos = {}
	_quadros_medidos = 0
	_medir_desde = _relogio


## O que está sob o ponto do mundo: {tipo: "pessoa"|"sinal"|"lugar", ...}.
func objeto_em(p: Vector2) -> Dictionary:
	if sim == null:
		return {}
	var sinal := _sinais.sinal_em(p)
	if not sinal.is_empty():
		return {"tipo": "sinal", "prece": sinal}
	var melhor := {}
	var dist := INF
	for f in figuras:
		# a pessoa a até 3 px do cursor ganha do lugar (auditoria 8, P6)
		var r := Rect2(f.x - ALCANCE_PESSOA, f.base - 12 - ALCANCE_PESSOA, f.largura + 2 * ALCANCE_PESSOA, 13 + 2 * ALCANCE_PESSOA)
		if r.has_point(p) and absf(p.x - f.x - f.largura / 2.0) < dist:
			dist = absf(p.x - f.x - f.largura / 2.0)
			melhor = f
	if not melhor.is_empty():
		for pe in sim.pessoas:
			if pe["id"] == melhor.id:
				return {"tipo": "pessoa", "pessoa": pe, "prece": _sinais.prece_de(pe["id"]), "figura": melhor}
	for z in sim.zonas:
		if p.x >= z["x_ini"] and p.x < z["x_fim"]:
			return {"tipo": "lugar", "zona": z, "vila": _vila_em(p.x)}
	return {}


## O povo cuja vila (fogueira ou construção) está a até 24 px de x: {nome, estagio, id}, ou {}.
func _vila_em(x: float) -> Dictionary:
	var perto := 24.0
	var grupo := -1
	for o in sim.construcoes:
		var d := absf(float(o["x"]) - x)
		if d < perto and int(o.get("grupo", -1)) >= 0:
			perto = d
			grupo = int(o["grupo"])
	for g in sim.grupos:
		if g["id"] == grupo:
			return {"nome": g.get("nome", ""), "estagio": int(g.get("estagio", 1)), "id": grupo}
	return {}


func clicar(ponto_tela: Vector2) -> void:
	print("[vista] clique no mundo %s" % para_mundo(ponto_tela).round())
	foco = -1
	var o := objeto_em(para_mundo(ponto_tela))
	if o.get("tipo", "") == "pessoa":
		pessoa_clicada.emit(o.pessoa["id"])


func alternar_seguir() -> void:
	seguindo = not seguindo
	foco = -1


## A caixa de preces: a vista aproxima e segue quem rezou por um tempo (um clique
## no mundo ou o Esc a devolvem antes).
func focar(id: int) -> void:
	foco = id
	_foco_ate = _relogio + FOCO_SEGUNDOS


## Efeito do resultado de um poder (e de outros eventos com dados de ponto).
## Teste do fim do mundo: todos morrem de doença. Com anos = 0, o mundo segue e
## o fim chega na próxima hora (com o aviso); com anos > 0, o mundo vazio anda.
func _extinguir(anos: int) -> void:
	var m = sim.mundo
	for g in m.grupos_vivos():
		for id in g.membros.duplicate():
			m._morrer(m.pessoas[id], "doenca")
	if anos > 0:
		m.avancar_dias(40 * anos)
		sim.iniciar_de_mundo()
	print("[vista] extinção de teste, %d anos depois" % anos)


## Outro mundo (abandono): a vida em cena e o desenho fixo recomeçam.
## O convite do mundo que nunca teve gente (arte, sinais/convite_povo_4q): o anel de
## luz na clareira, do primeiro segundo até o primeiro povo. Não aparece depois da
## extinção, que é outro clima (o mundo vazio de lá já teve gente).
func _atualizar_convite() -> void:
	var convidar: bool = sim != null and sim.mundo.fim_do_mundo and sim.mundo.pessoas.is_empty()
	if convidar == _convite or _sup.is_empty() or _tipos.is_empty():  # o terreno ainda não foi montado
		return
	_convite = convidar
	if convidar:
		_sinais.marcar("convite_povo_4q", 24, 4, 2.5, INF, -1, X_CONVITE, chao(int(X_CONVITE)))
	else:
		_sinais.marcas = _sinais.marcas.filter(func(m): return m.folha != "convite_povo_4q")


func _ao_trocar_mundo() -> void:
	_vida = Vida.new(self, sim)
	seguindo = false
	_eclipse_ate = -1
	_seca_ate = -1
	_refazer = true


func _ao_receber_eventos(eventos: Array) -> void:
	for ev in eventos:
		match ev["tipo"]:
			"eclipse":
				_eclipse_ate = sim.mundo.passo + 3
			"estranhos":  # chegam de além da borda e vão até o fogo do povo
				var fogo := fogo_mais_perto(float(ev.get("dados", {}).get("x", 240.0)))
				for o in sim.construcoes:
					if o["tipo"] == "fogueira" and int(o.get("grupo", -1)) == int(ev.get("grupo", -2)):
						fogo = float(o["x"])
				_vida.chegada(ev.get("participantes", []), fogo, false)
			"dependencia", "costume":  # a repetição vira hábito: um aviso na alça
				var origem := String(ev.get("dados", {}).get("origem_tipo", ""))
				if _interface and (ev["tipo"] == "dependencia" or origem in GESTOS_DO_DEUS):
					_interface.avisar_evento(String(ev.get("curto", "")))
			"profeta":  # o facho desce sobre ele (2 s) e a estrela fica enquanto ele vive
				var quem: Array = ev.get("participantes", [])
				if not quem.is_empty():
					_sinais.marcar("profeta_chamado_4q", 16, 4, 2.0, 2.0, int(quem[0]))
					_sinais.marcar("profeta_marca_4q", 8, 4, 2.0, INF, int(quem[0]), 0.0, 0, false, 2.0)
			"separacao":  # a luz se parte sobre o fogo de onde saíram; a marca fica sobre o povo novo
				var origem := _fogo_do_grupo(int(ev.get("outro_grupo", -1)))
				var novo := _fogo_do_grupo(int(ev.get("grupo", -1)))
				if origem >= 0.0:
					_sinais.marcar("separacao_4q", 24, 4, 1.6, 2.5, -1, origem, chao(int(origem)) - 16, novo >= 0.0 and novo < origem)
				if novo >= 0.0:
					_sinais.marcar("separacao_marca_2q", 12, 2, 1.7, 72.0 * float(sim.SEGUNDOS.get(sim.ritmo, 112.5)),
						-1, novo, chao(int(novo)) - 16)
			"rito", "rixa", "roubo", "casamento", "nascimento":  # as notas de povo pequeno, se a alça está livre
				if _interface and String(ev.get("camada", "")) == "nota":
					_interface.avisar_evento(String(ev.get("curto", "")), true)
			"prece_atendida", "prece_sem_resposta", "prece_contrariada":
				var quem: Array = ev.get("participantes", [])
				var px: float = sim.mundo.posicao_de(quem[0]) if not quem.is_empty() else -1.0
				if px >= 0.0:
					_atmosfera.desfecho_da_prece(ev["tipo"], px)
			"chuva_divina", "raio_divino", "fogo_divino", "fogo_brando", "fartura_divina", "terra_erguida", "sonho", "seca_divina", "diluvio", "terremoto_divino", "pressagio", "cura":
				var d: Dictionary = ev.get("dados", {})
				var alvo := -1.0
				var ids: Array = ev.get("participantes", [])
				if not ids.is_empty():
					alvo = sim.mundo.posicao_de(ids[0])
				_atmosfera.poder(ev["tipo"], float(d.get("x", 240.0)), String(d.get("grau", "sinal")),
					alvo, modo_discreto, d)
				if ev["tipo"] == "sonho" and not ids.is_empty() and _interface:
					_interface.marcar_sonho(int(ids[0]))
				if ev["tipo"] == "pressagio" and d.get("forma", "") == "eclipse":
					_eclipse_ate = sim.mundo.passo + 3
				if ev["tipo"] == "seca_divina":  # de 4 a 10 horas, conforme o grau
					_seca_ate = sim.mundo.passo + {"sinal": 4, "milagre": 7, "imposicao": 10}.get(String(d.get("grau", "sinal")), 4)


# --- montagem -----------------------------------------------------------

func _criar_nos() -> void:
	var paleta := Arte.paleta_vec3()
	var tabelas := Arte.textura_tabelas()
	for nome in FUNDOS:
		_fundos.append(_sprite(0, paleta, tabelas))
		_canto_fundo.append(Vector2.ZERO)
		if nome == "ceu":
			_fundos[-1].material.set_shader_parameter("frente_ativa", true)
	if not _modo_layout:  # o céu vivo fica entre o degradê e as montanhas
		_ceu = Ceu.new()
		add_child(_ceu)
		move_child(_ceu, _fundos[0].get_index() + 1)
		_ceu.criar(self)
	_agua = _sprite(4, paleta, tabelas)
	_mundo = _sprite(1, paleta, tabelas)
	_luzes = Sprite2D.new()
	_luzes.centered = false
	_luzes.visible = false
	add_child(_luzes)
	_fogueiras = Node2D.new()
	_fogueiras.draw.connect(_desenhar_fogueiras)
	add_child(_fogueiras)
	_pessoas = Pessoas.new()
	_pessoas.material = _material(2, paleta, tabelas)
	var opcoes := Arte.opcoes_troca()
	_pessoas.material.set_shader_parameter("peles", opcoes.peles)
	_pessoas.material.set_shader_parameter("cabelos", opcoes.cabelos)
	_pessoas.material.set_shader_parameter("roupas", PackedInt32Array(opcoes.roupas))
	add_child(_pessoas)
	_reflexo = _sprite(5, paleta, tabelas)
	_frente = _sprite(3, paleta, tabelas)
	_atmosfera = Atmosfera.new()
	add_child(_atmosfera)
	# a neblina fica atrás da vila (auditoria 4, N4): logo antes do mundo
	_atmosfera.criar(self, _material(6, paleta, tabelas), _mundo)
	_sinais = Sinais.new()
	add_child(_sinais)
	var luz := Arte.textura("camadas/luz_fogueira.png")
	var halo := Arte.textura("camadas/luz_fogueira_halo.png")
	for m in _materiais:
		m.set_shader_parameter("luz", luz)
		m.set_shader_parameter("halo", halo)
	var folha := Arte.imagem("terreno/agua_superficie_4q.png")
	for i in 4:
		_quadros_agua.append(Arte.quadro(folha, i, 8))


func _material(plano: int, paleta: PackedVector3Array, tabelas: Texture2D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = REMAP
	m.set_shader_parameter("plano", plano)
	m.set_shader_parameter("paleta", paleta)
	m.set_shader_parameter("tabelas", tabelas)
	_materiais.append(m)
	return m


func _sprite(plano: int, paleta: PackedVector3Array, tabelas: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.material = _material(plano, paleta, tabelas)
	add_child(s)
	return s


## Carrega os planos de fundo da estação corrente (e solta os da anterior). Os
## céus de seca e de eclipse só são carregados quando aparecem.
func _carregar_fundos() -> void:
	if _estacao_fundos == Arte.estacao:
		return
	_estacao_fundos = Arte.estacao
	_tex_fundo.clear()
	for i in FUNDOS.size():
		var imgs := ESTADOS.map(func(e): return Arte.imagem(Arte.da_estacao("camadas/%s_%s" % [FUNDOS[i], e]) + ".png"))
		if i == 0 and _ceu:  # com o céu vivo, o céu é só o degradê; sol, lua, nuvens e estrelas vêm do Ceu
			imgs = ESTADOS.map(func(e): return _faixa_repetida(e))
		var corte := _recortar(imgs)
		for k in ESTADOS.size():
			_tex_fundo["%s_%s" % [FUNDOS[i], ESTADOS[k]]] = corte[1][k]
		_canto_fundo[i] = Vector2(corte[0].position)
	_camera_aplicada = [-1, Vector2(-1, -1)]


## O degradê do céu (faixa de 4 × 160 da arte) repetido na largura.
func _faixa_repetida(estado: String) -> Image:
	var nome := estado + ("_inverno" if Arte.estacao == "inverno" and estado != "noite" else "")
	var faixa := Arte.imagem("ceu/faixa_%s.png" % nome)
	var img := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	for x in range(0, LARGURA, faixa.get_width()):
		img.blit_rect(faixa, Rect2i(Vector2i.ZERO, faixa.get_size()), Vector2i(x, 0))
	return img


func _textura_fundo(nome: String) -> Texture2D:
	if not _tex_fundo.has(nome):  # céu de seca ou de eclipse, do mesmo tamanho do céu
		_tex_fundo[nome] = ImageTexture.create_from_image(Arte.imagem("camadas/%s.png" % nome))
	return _tex_fundo[nome]


## O que, além das construções, muda a imagem fixa: a estação (fase das roças).
func _chave_do_fixo() -> Array:
	return [sim.tempo.get("estacao", ""), sim.clima.get("inverno_rigoroso", false),
		sim.zonas.map(func(z): return z.get("alagada", false))]


## Refaz tudo o que é fixo: terreno, vegetação, construções, marcas, reflexo e frente.
func _montar_fixo() -> void:
	if sim:
		Arte.estacao = sim.tempo.get("estacao", "verão")
	_carregar_fundos()
	var obras := _construcoes()
	_fogos.clear()
	var batido := []
	for o in obras:
		if o.tipo == "fogueira":
			var c := int(o.x) / 8
			for col in range(c - 3, c + 3):
				batido.append(col)
	var queimadas := []
	if sim:
		for z in sim.zonas:
			if z["queimada"]:
				for col in range(int(z["x_ini"]) / 8, int(z["x_fim"]) / 8):
					queimadas.append(col)
	var arvore_queimada := Arte.imagem(Arte.da_estacao("memoria/arvore_queimada") + ".png") if not queimadas.is_empty() else null
	# no inverno, as 5 colunas de água mais perto da praia congelam (40 px); no
	# inverno rigoroso, o lago inteiro (auditoria 3b, E5)
	var gelo := []
	if Arte.estacao == "inverno":
		var agua := []
		for c in _layout["colunas"].size():
			var cl: Array = _layout["colunas"][c]
			if cl[1] == "areia" and int(cl[0]) > Terreno.NIVEL_AGUA:
				agua.append(c)
		var rigoroso: bool = sim != null and sim.clima.get("inverno_rigoroso", false)
		gelo = agua if rigoroso else agua.slice(maxi(0, agua.size() - 5))
	_gelo = gelo

	var terreno := Terreno.new()
	var colunas: Array = _layout["colunas"]
	_tipos = colunas.map(func(cl): return cl[1])
	var r := terreno.montar(colunas, batido, _quadros_agua[0], false, queimadas, gelo)
	var cor: Image = r.cor
	var tag: Image = r.tag
	_sup = r.sup
	if not _modo_layout:  # depois do terreno, que diz onde é água
		_encaixar_lotes(obras)
	var agua_mascara := _mascara_agua(tag)
	beira_visivel = 0  # onde a água desenhada acaba, na linha logo abaixo da superfície
	while beira_visivel < LARGURA and roundi(tag.get_pixel(beira_visivel, Terreno.NIVEL_AGUA + 1).r * 255.0) == Arte.AGUA:
		beira_visivel += 1

	var frente := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var tag_frente := Image.create(LARGURA, ALTURA, false, Image.FORMAT_R8)
	var pecas := {}
	_copas = []
	_baixa = []
	for item in _layout["pecas"]:
		var nome: String = item["peca"]
		if item["plano"] in ["pessoa", "fogo"] or nome == "cabana_galhos":
			continue
		if not _modo_layout and nome in PECAS_MIUDAS and _sob_construcao(item, obras):
			continue
		if not _modo_layout and item["plano"] == "mundo" and _arvore_na_roca(item, obras):
			continue  # a roça abre uma clareira na mata (auditoria 3b, E6)
		if item["plano"] == "mundo" and (int(item["x"]) + 8) / 8 in queimadas:
			if nome in ARVORES:  # tronco carbonizado no lugar da árvore
				var tronco: int = int(item["x"]) + ARVORES[nome]
				var pos_q := Vector2i(tronco - 15, int(item["base"]) - 31)
				terreno.colar(cor, tag, arvore_queimada, pos_q, Arte.MUNDO)
				continue
			if nome in PECAS_MIUDAS:
				continue
		if not pecas.has(nome):
			pecas[nome] = Arte.imagem(Arte.da_estacao("estagio1/" + nome) + ".png")
		var img: Image = pecas[nome]
		if item.get("espelho", false):
			img = img.duplicate()
			img.flip_x()
		var pos := Vector2i(int(item["x"]), int(item["base"]) - img.get_height() + 1)
		if nome.begins_with("arvore_copa"):  # onde a coruja pode pousar
			_copas.append(Vector2(pos.x + ARVORES.get(nome, 12), pos.y + _primeira_linha(img)))
		elif nome in PECAS_MIUDAS or item["plano"] == "frente":
			_baixa.append([pos.x, pos.x + img.get_width()])
		if item["plano"] == "frente":
			terreno.colar(frente, tag_frente, img, pos, Arte.FRENTE)
		else:
			terreno.colar(cor, tag, img, pos, Arte.AGUA if item["plano"] == "agua" else Arte.MUNDO)
			# a peça fica por cima do reflexo, como em montar.py
			agua_mascara.blit_rect_mask(_vazio(img.get_size()), img, Rect2i(Vector2i.ZERO, img.get_size()), pos)

	var imagens := {}
	rodas = []
	chamines = []
	telhados = []
	estandartes = []
	var com_estandarte := {}  # grupos que já têm o estandarte na casa principal
	var luz_todas := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var luz_madrugada := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var roca := Arte.imagem(Arte.da_estacao("estagio2/" + _fase_da_roca()) + ".png")
	# as ruínas ficam atrás das construções vivas
	# e a natureza as retoma: mato pelos anos, uma muda e depois uma árvore jovem ao lado
	for o in (sim.ruinas if sim else []):
		var anos := int(o.get("anos", 0))
		var x := roundi(o["x"])
		var ruina := "natureza/fogueira_antiga" if o["tipo"] == "fogueira" else Obras.peca(o["tipo"], int(o.get("estagio", 1)), true)
		var com_mato := Obras.ruina_com_mato(ruina, anos)
		_colar_obra(terreno, cor, tag, imagens, [com_mato if ResourceLoader.exists(Arte.RAIZ + com_mato + ".png") else ruina], x)
		var planta := Obras.planta_da_ruina(anos, o["x"])
		if planta != "" and o["tipo"] not in ["fogueira", "roca", "barco"]:
			var lado := int(o.get("largura", 16)) / 2 + 3
			var px := x + (lado if posmod(x, 2) == 0 else -lado)
			if not _na_agua(px):
				_colar_obra(terreno, cor, tag, imagens, [planta], px, Arte.MUNDO)
	# as casas da fileira de trás antes, mais altas, para as da frente as cobrirem
	var atras_em_x := obras.filter(func(o): return int(o.get("fileira", 0)) == 1)
	atras_em_x.sort_custom(func(a, b): return float(a.x) < float(b.x))  # elas se cobrem pela metade
	var em_ordem := atras_em_x + \
		obras.filter(func(o): return int(o.get("fileira", 0)) != 1)
	for o in em_ordem:
		var x := roundi(o.x)
		var atras := FILEIRA_ATRAS if int(o.get("fileira", 0)) == 1 else 0
		match o.tipo:
			"roda_dagua":  # animada, desenhada pela vida
				rodas.append({"x": x, "base": _chao(x)})
			"muralha":  # um trecho de muro entre duas torres
				var muro := _imagem_obra(imagens, "estagio6/muralha")
				var meia := int(o.get("largura", 28)) / 2
				for mx in range(x - meia, x + meia, muro.get_width()):
					terreno.colar(cor, tag, muro, Vector2i(mx, _chao(mx + 4) - muro.get_height() + 1), Arte.OBRA)
				for tx in [x - meia, x + meia]:
					_colar_obra(terreno, cor, tag, imagens, ["estagio6/muralha_torre"], tx)
			"roca":  # a roça vai sobre a grama, com a base na superfície
				var irrigada: bool = o.get("irrigada", false)
				if not irrigada and posmod(x, 3) != 0:  # o pomar ao lado de umas roças (tronco na coluna 10)
					var px := x + 13
					if not _na_agua(px):
						var arvore := _imagem_obra(imagens, "estagio2/arvore_fruta")
						terreno.colar(cor, tag, arvore, Vector2i(px - 10, _chao(px) - 23), Arte.MUNDO)
				var peca := roca if not irrigada else _imagem_obra(imagens, "estagio6/roca_irrigada")
				terreno.colar(cor, tag, peca, Vector2i(x - 8, _sup[clampi(x, 0, LARGURA - 1)] - 15), Arte.OBRA)
				if irrigada:  # a roda d'água do canal, ao lado (animada, desenhada pela vida)
					rodas.append({"x": x - 15, "base": _chao(x - 15)})
			"barco":  # na água: a linha 14 do barco fica na linha d'água
				var b := _imagem_obra(imagens, Obras.peca("barco", 6))
				terreno.colar(cor, tag, b, Vector2i(x - b.get_width() / 2, Terreno.NIVEL_AGUA - 14), Arte.OBRA)
			"fogueira":
				var canto := Vector2i(x - 8, _chao(x) - 15)
				_fogos.append({"canto": canto, "centro": float(x), "grupo": int(o.get("grupo", -1)),
					"luz": Vector2(snappedi(canto.x, 4) - 56, snappedi(canto.y, 4) - 32)})
			_:
				# API v10: a construção traz a cultura; antes, vinha só do povo
				var aparencia: Dictionary = o.get("aparencia", {})
				if aparencia.is_empty() and sim:
					aparencia = sim.aparencia(int(o.get("grupo", -1)))
				_colar_obra(terreno, cor, tag, imagens, Obras.camadas(o.tipo, int(o.get("estagio", 1)), aparencia), x,
					Arte.OBRA, atras)
				if o.tipo == "cabana" and atras == 0:
					for dx in [-4, 0, 4]:
						var topo := _topo_da_obra(tag, x + dx)
						if topo > 0:
							telhados.append(Vector2(x + dx, topo))
					# o estandarte do povo na cumeeira da casa principal (auditoria 7, C1)
					var g := int(o.get("grupo", -1))
					if g >= 0 and not com_estandarte.has(g):
						com_estandarte[g] = true
						var folha := "objetos/estandarte_%s_%s_2q" % [aparencia.get("roupa", "lilas"), aparencia.get("simbolo", "sol")]
						if ResourceLoader.exists(Arte.RAIZ + folha + ".png"):
							estandartes.append({"folha": folha, "x": x, "base": _topo_da_obra(tag, x)})
				if o.tipo == "cabana" and int(o.get("estagio", 1)) >= 2:
					_luz_e_chamine(o, aparencia, x, imagens, terreno, cor, tag, luz_todas, luz_madrugada)
	if sim:
		_colar_enchente(terreno, cor, tag)
		var pedra := Arte.imagem(Arte.da_estacao("memoria/pedra_erguida") + ".png")
		for z in sim.zonas:
			if z["pedra_erguida"]:
				var x := roundi(z["pedra_x"])
				terreno.colar(cor, tag, pedra, Vector2i(x - 8, _chao(x) - 31), Arte.MUNDO)

	_mundo.texture = ImageTexture.create_from_image(cor)
	_tex_luzes = [ImageTexture.create_from_image(luz_todas), ImageTexture.create_from_image(luz_madrugada)]
	var corte := _recortar([frente])
	_frente.texture = corte[1][0]
	_frente.position = Vector2(corte[0].position)
	var refs := []
	for e in ESTADOS:
		var ref := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
		var fonte := Arte.imagem("camadas/reflexo_%s.png" % e)
		ref.blit_rect_mask(fonte, agua_mascara, Rect2i(0, 0, LARGURA, ALTURA), Vector2i.ZERO)
		refs.append(ref)
	corte = _recortar(refs)
	_tex_reflexo = corte[1]
	_reflexo.position = Vector2(corte[0].position)
	var sup_img := Image.create(LARGURA, 1, false, Image.FORMAT_R8)
	for x in LARGURA:
		sup_img.set_pixel(x, 0, Color8(_sup[x], 0, 0))
	var tex_tag := ImageTexture.create_from_image(tag)
	var tex_sup := ImageTexture.create_from_image(sup_img)
	var luzes := PackedVector2Array()
	for f in _fogos.slice(0, 4):
		luzes.append(f.luz)
	var n := luzes.size()
	luzes.resize(4)
	for m in _materiais:
		m.set_shader_parameter("etiquetas", tex_tag)
		m.set_shader_parameter("superficie", tex_sup)
		m.set_shader_parameter("fogos", luzes)
		m.set_shader_parameter("n_fogos", n)
	_montar_agua()
	_estado = []
	_fogueiras.queue_redraw()


## Cola uma construção (ou ruína) com a base no chão em x: as camadas, de baixo
## para cima (parede, telhado e símbolo da cultura), no mesmo encaixe.
func _colar_obra(terreno, cor: Image, tag: Image, imagens: Dictionary, camadas: Array, x: int,
		etiqueta := Arte.OBRA, acima := 0) -> void:
	for caminho in camadas:
		if caminho == "":
			continue
		var img := _imagem_obra(imagens, caminho)
		terreno.colar(cor, tag, img, Vector2i(x - img.get_width() / 2, _chao(x) - img.get_height() + 1 - acima), etiqueta)


func _imagem_obra(imagens: Dictionary, caminho: String) -> Image:
	if not imagens.has(caminho):
		imagens[caminho] = Obras.primeiro_quadro(caminho, Arte.imagem(Arte.da_estacao(caminho) + ".png"))
	return imagens[caminho]


func _fase_da_roca() -> String:
	if sim == null:
		return "roca_arada"
	if sim.clima.get("seca", false):
		return "roca_seca"
	match sim.tempo.get("estacao", ""):
		"primavera":
			return "roca_broto"
		"verão":
			return "roca_crescida"
		"outono":
			return "roca_madura"
	return "roca_arada"


## Construções do núcleo, ou as da cena-alvo no modo layout.
## No recomeço, as cabanas do povo novo só aparecem depois que a primeira fogueira acende.
func _cabana_por_erguer(o: Dictionary) -> bool:
	return not recomeco.is_empty() and o.tipo == "cabana" and int(o.grupo) == int(recomeco.grupo) \
		and not recomeco.get("ergueu", false)


## O povo novo criado no mundo vazio (arte, seção 28): chega pela borda com a
## trouxa, um deles acende a primeira fogueira e só então as cabanas aparecem.
func comecar_recomeco(grupo: int) -> void:
	recomeco = {"grupo": grupo, "ini": _relogio}
	_refazer = true
	var ids: Array = sim.pessoas.filter(func(p): return int(p["grupo"]) == grupo).map(func(p): return int(p["id"]))
	var fogo := -1.0
	for o in sim.construcoes:
		if o["tipo"] == "fogueira" and int(o.get("grupo", -1)) == grupo:
			fogo = float(o["x"])
	if fogo >= 0.0:
		_vida.chegada(ids, fogo, true)


## O x da fogueira de um povo, ou -1.
func _fogo_do_grupo(grupo: int) -> float:
	for o in sim.construcoes:
		if o["tipo"] == "fogueira" and int(o.get("grupo", -1)) == grupo:
			return float(o["x"])
	return -1.0


func _construcoes() -> Array:
	if not _modo_layout:
		return sim.construcoes.map(func(o): return {"tipo": o["tipo"], "x": float(o["x"]),
			"estagio": int(o.get("estagio", 1)), "largura": int(o.get("largura", 16)), "irrigada": o.get("irrigada", false),
			"grupo": int(o.get("grupo", -1)), "aparencia": o.get("aparencia", {}), "fileira": int(o.get("fileira", 0))}) \
			.filter(func(o): return not _cabana_por_erguer(o))
	var r := []
	for item in _layout["pecas"]:
		if item["peca"] == "cabana_galhos":
			r.append({"tipo": "cabana", "x": item["x"] + 8.0, "estagio": 1, "largura": 16, "grupo": -1})
	r.append({"tipo": "fogueira", "x": _layout["fogueira"]["x"] + 8.0})
	return r


## Cada construção no seu lote (auditoria 2, N1), pela largura real da peça
## (a arte é mais larga que a `largura` da API), com LOTE_FOLGA px entre
## vizinhas e o menor deslocamento possível em relação ao `x` do núcleo (o
## mesmo empacotamento das pessoas, com larguras diferentes). Se a vila não
## couber entre a margem e a borda direita, a folga encolhe por igual e as
## peças se encostam um pouco, sem amontoar numa ponta. O barco, na água, fica
## de fora; o que o núcleo pôs na praia continua lá.
func _encaixar_lotes(obras: Array) -> void:
	# a fileira de trás (API: `fileira` 1) pode cruzar a da frente em x: fica fora do encaixe
	var fila := obras.filter(func(o): return o.tipo != "barco" and int(o.get("fileira", 0)) == 0)
	if fila.size() < 2:
		return
	fila.sort_custom(func(a, b): return a.x < b.x)
	var n := fila.size()
	var w: Array = fila.map(func(o): return float(_largura_da_peca(o)))
	var terra := 0
	while terra < LARGURA - 1 and _na_agua(terra):
		terra += 1
	var ini: float = minf(terra + w[0] / 2.0, fila[0].x)
	var fim: float = LARGURA - 4.0 - w[n - 1] / 2.0
	var passos := []
	var total := 0.0
	for i in n - 1:
		# entre as vilas de povos diferentes, um vão, para cada uma ler como um lugar (auditoria 7, C1)
		var vao := VAO_ENTRE_POVOS if int(fila[i].get("grupo", -1)) != int(fila[i + 1].get("grupo", -1)) else 0.0
		passos.append((w[i] + w[i + 1]) / 2.0 + LOTE_FOLGA + vao)
		total += passos[i]
	var aperto := 1.0 if total <= fim - ini else (fim - ini) / total
	var desloc := [0.0]
	for i in n - 1:
		desloc.append(desloc[i] + passos[i] * aperto)
	# y = x - deslocamento precisa crescer: junta os vizinhos fora de ordem na média
	var blocos := []  # [quantos, soma de y]
	for i in n:
		blocos.append([1, fila[i].x - desloc[i]])
		while blocos.size() >= 2 and blocos[-2][1] / blocos[-2][0] > blocos[-1][1] / blocos[-1][0]:
			var b: Array = blocos.pop_back()
			blocos[-1] = [blocos[-1][0] + b[0], blocos[-1][1] + b[1]]
	var i := 0
	for bl in blocos:
		var y: float = clampf(bl[1] / bl[0], ini, fim - desloc[n - 1])
		for k in bl[0]:
			fila[i].x = y + desloc[i]
			i += 1


## As janelas acesas da casa (para a camada de luz) e, no inverno, a chaminé
## com a fumaça da lareira. Uma casa em cada três fica acordada de madrugada.
func _luz_e_chamine(o: Dictionary, aparencia: Dictionary, x: int, imagens: Dictionary, terreno, cor: Image,
		tag: Image, luz_todas: Image, luz_madrugada: Image) -> void:
	var casa: String = CASAS[clampi(int(o.get("estagio", 2)), 2, 6)]
	if not ResourceLoader.exists(Arte.RAIZ + casa + "_luz.png"):
		return
	var luz := _imagem_obra(imagens, casa + "_luz")
	var canto := Vector2i(x - luz.get_width() / 2, _chao(x) - luz.get_height() + 1)
	var faixa := Rect2i(Vector2i.ZERO, luz.get_size())
	luz_todas.blend_rect(luz, faixa, canto)
	if posmod(x * 7, 3) == 0:
		luz_madrugada.blend_rect(luz, faixa, canto)
	if Arte.estacao != "inverno":
		return
	if _chamines_json.is_empty():
		_chamines_json = Arte.json("luzes/chamines.json").get("casas", {})
	var chave := "%s_telhado_%s" % [casa.get_file(), aparencia.get("telhado", "palha")]
	if not _chamines_json.has(chave):
		return
	var c: Dictionary = _chamines_json[chave]
	var chamine := _imagem_obra(imagens, "luzes/chamine")
	terreno.colar(cor, tag, chamine, canto + Vector2i(int(c["chamine_x"]), int(c["chamine_y"])), Arte.OBRA)
	chamines.append(Vector2(canto) + Vector2(float(c["fumaca_x"]) + 4.0, float(c["fumaca_base_y"])))


## A primeira linha de construção de cima para baixo na coluna x, ou -1.
func _topo_da_obra(tag: Image, x: int) -> int:
	if x < 0 or x >= LARGURA:
		return -1
	for y in _chao(x):
		if roundi(tag.get_pixel(x, y).r * 255.0) == Arte.OBRA:
			return y
	return -1


func _largura_da_peca(o: Dictionary) -> int:
	match o.tipo:
		"fogueira", "roca":
			return 16
	var camadas := Obras.camadas(o.tipo, int(o.get("estagio", 1)), o.get("aparencia", {}))
	if camadas.is_empty():
		return int(o.get("largura", 16))
	var caminho: String = camadas[0]
	if not _larguras.has(caminho):
		_larguras[caminho] = _imagem_obra({}, caminho).get_width()
	return _larguras[caminho]


## Árvores e pinheiros com o tronco sobre uma roça (ou o pomar dela) saem.
func _arvore_na_roca(item: Dictionary, obras: Array) -> bool:
	var nome: String = item["peca"]
	if not (nome in ARVORES or nome.begins_with("pinheiro") or nome.begins_with("arvore")):
		return false
	var tronco: float = float(item["x"]) + ARVORES.get(nome, 8)
	for o in obras:
		if o.tipo == "roca" and tronco > o.x - 14.0 and tronco < o.x + 26.0:
			return true
	return false


## A água barrenta do dilúvio cobre as zonas alagadas (API: `alagada`), num
## nível só por zona, 4 px acima do chão do meio dela, com os blocos
## `enchente_*` por cima do terreno e da base das construções.
func _colar_enchente(terreno, cor: Image, tag: Image) -> void:
	var superficie := Arte.quadro(Arte.imagem("efeitos/enchente_superficie_4q.png"), 0, 8)
	var agua := Arte.imagem("efeitos/enchente_agua_1q.png")
	for z in sim.zonas:
		if not z.get("alagada", false):
			continue
		var colunas := []
		for c in range(int(z["x_ini"]) / 8, int(z["x_fim"]) / 8):
			if c >= 0 and c < LARGURA / 8 and not _na_agua(c * 8):
				colunas.append(c)
		if colunas.is_empty():
			continue
		var chaos: Array = colunas.map(func(c): return _sup[c * 8 + 4])
		chaos.sort()
		var nivel: int = chaos[chaos.size() / 2] - 4
		for c in colunas:
			var fundo: int = _sup[c * 8 + 4] + 3
			if fundo <= nivel or fundo - nivel > 14:
				continue  # o chão aqui fica acima da água, ou é encosta (sem parede de água)
			terreno.colar(cor, tag, superficie, Vector2i(c * 8, nivel), Arte.MUNDO)
			for y in range(nivel + 8, fundo, 8):
				terreno.colar(cor, tag, agua, Vector2i(c * 8, y), Arte.MUNDO)


func _primeira_linha(img: Image) -> int:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				return y
	return 0


## O poleiro da coruja: o topo da copa da árvore mais perto de `perto_de` (o x
## que a API dá à coruja), ou da vila (o primeiro fogo).
func poleiro_coruja(perto_de := -1.0) -> Vector2:
	if _copas.is_empty():
		return Vector2(-100, -100)
	var vila: float = perto_de if perto_de >= 0.0 else (_fogos[0].centro if not _fogos.is_empty() else 240.0)
	var melhor: Vector2 = _copas[0]
	for c in _copas:
		if absf(c.x - vila) < absf(melhor.x - vila):
			melhor = c
	return melhor


## O x mais perto de x, andando para `lado`, onde o chão está aberto (sem
## arbusto, capim ou pedra atrás), para a caça caída não sumir no mato.
## Com `na_agua`, vale também a água rasa (quem pesca ou se banha).
func chao_aberto(x: float, lado: float, na_agua := false) -> float:
	for passo in 16:
		var cx := x + lado * passo * 2.0
		var livre := true
		for b in _baixa:
			if cx + 6.0 > b[0] and cx - 6.0 < b[1]:
				livre = false
				break
		if livre and (na_agua or not _na_agua(roundi(cx))):
			return cx
	return x


func _sob_construcao(item: Dictionary, obras: Array) -> bool:
	var x0 := float(item["x"])
	for o in obras:
		if abs(x0 + 4.0 - o.x) < o.get("largura", 16) / 2.0 + 6.0:
			return true
	return false


## Onde uma partícula toca: a linha d'água no mar, o chão no resto.
func chao(x: int) -> int:
	return Terreno.NIVEL_AGUA - 1 if _na_agua(x) else _chao(x)


## O terremoto treme a vista por alguns segundos.
func tremer(segundos: float) -> void:
	_tremor = maxf(_tremor, segundos)


func estacao_atual() -> String:
	return sim.tempo.get("estacao", "verão") if sim else "verão"


func textura_efeito(nome: String) -> Texture2D:
	return Arte.textura("efeitos/%s.png" % nome)


func cor_paleta(i: int) -> Color:
	return Arte.paleta[i]


## Onde os pés de uma pessoa ficam em x (na água, na linha d'água: só quem rema).
func chao_pessoa(x: int) -> int:
	return Terreno.NIVEL_AGUA + 2 if _na_agua(x) else _chao(x)


## Há uma roça a menos de 14 px de x? (quem colhe ali usa a enxada)
func perto_de_roca(x: float) -> bool:
	for o in sim.construcoes:
		if o["tipo"] == "roca" and absf(float(o["x"]) - x) < 14.0:
			return true
	return false


## Linha do chão em x: a superfície menos 1, como as peças da cena-alvo.
func _chao(x: int) -> int:
	return _sup[clampi(x, 0, LARGURA - 1)] - 1


## Colunas de 8 px de água, da esquerda para a direita.
func colunas_agua() -> Array:
	var r := []
	for c in _tipos.size():
		if _tipos[c] == "areia" and _sup[c * 8] > Terreno.NIVEL_AGUA:
			r.append(c)
	return r


func _na_agua(x: int) -> bool:
	var c := clampi(x, 0, LARGURA - 1) / 8
	return _tipos[c] == "areia" and _sup[c * 8] > Terreno.NIVEL_AGUA


func _mascara_agua(tag: Image) -> Image:
	var m := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	for y in ALTURA:
		for x in LARGURA:
			if roundi(tag.get_pixel(x, y).r * 255.0) == Arte.AGUA:
				m.set_pixel(x, y, Color.WHITE)
	return m


## Recorta imagens do mesmo plano à área usada por qualquer uma delas, para
## não guardar texturas de tela inteira quase vazias. Devolve [canto, texturas].
static func _recortar(imgs: Array) -> Array:
	var r := Rect2i()
	for img in imgs:
		var usada: Rect2i = img.get_used_rect()
		if usada.has_area():
			r = usada if not r.has_area() else r.merge(usada)
	if not r.has_area():
		r = Rect2i(0, 0, 1, 1)
	return [r, imgs.map(func(img): return ImageTexture.create_from_image(img.get_region(r)))]


func _vazio(tamanho: Vector2i) -> Image:
	return Image.create(tamanho.x, tamanho.y, false, Image.FORMAT_RGBA8)


## A superfície da água é desenhada à parte, em 4 quadros que deslizam.
func _montar_agua() -> void:
	_tex_agua.clear()
	for q in 4:
		var faixa := Image.create(LARGURA, 8, false, Image.FORMAT_RGBA8)
		for c in LARGURA / 8:
			if _tipos[c] == "areia" and _sup[c * 8] > Terreno.NIVEL_AGUA and not c in _gelo:
				faixa.blit_rect_mask(_quadros_agua[q], _quadros_agua[q], Rect2i(0, 0, 8, 8), Vector2i(c * 8, 0))
		_tex_agua.append(ImageTexture.create_from_image(faixa))
	_agua.position = Vector2(0, 120)
	_quadro_agua = -1


# --- a cada quadro ---------------------------------------------------------

func _parado() -> bool:
	return _modo_layout or (sim != null and sim.congelado)


func _atualizar_agua() -> void:
	var q := 0 if _parado() else int(_relogio * 4.0) % 4
	if q != _quadro_agua:
		_quadro_agua = q
		_agua.texture = _tex_agua[q]
		_reflexo.material.set_shader_parameter("onda", q)
		_reflexo.material.set_shader_parameter("ondulacao", 0.0 if _parado() else 1.0)


func _atualizar_fogueiras() -> void:
	var q := 0 if _parado() else int(_relogio * 6.0) % 4
	var brasas := _fogos_em_brasas()
	if q != _quadro_fogo or brasas != _brasas:
		_quadro_fogo = q
		_brasas = brasas
		_fogueiras.queue_redraw()


## Os fogos que, de madrugada, baixaram para brasas (cena `brasas` da API).
func _fogos_em_brasas() -> Array:
	var r := []
	if sim == null:
		return r
	var h: float = sim.hora_continua()
	for c in sim.cenas:
		if c.get("tipo", "") == "brasas" and h >= float(c.get("ini", 0.0)) and h < float(c.get("fim", 24.0)):
			r.append(fogo_mais_perto(float(c.get("x", 0.0))))
	return r


func _desenhar_fogueiras() -> void:
	if _fogos.is_empty():
		return
	if _tex_fogueira == null:
		_tex_fogueira = Arte.textura("estagio1/fogueira_acesa_4q.png")
	if _tex_brasas == null:
		_tex_brasas = textura_efeito("brasas_4q")
	for f in _fogos:
		var nascendo := _fogo_nascendo(f)
		if nascendo != -2:  # o recomeço: nada, a lenha, a brasa e a chama pequena
			if nascendo >= 0:
				if _tex_nascendo == null:
					_tex_nascendo = ImageTexture.create_from_image(Arte.imagem("estagio1/fogueira_nascendo_4q.png"))
				_fogueiras.draw_texture_rect_region(_tex_nascendo,
					Rect2(f.canto, Vector2(16, 16)), Rect2(nascendo * 16, 0, 16, 16))
			continue
		if f.centro in _brasas:  # o fogo baixo: só as brasas pulsando sobre as pedras
			_fogueiras.draw_texture_rect_region(_tex_brasas, Rect2(Vector2(f.canto) + Vector2(4, 8), Vector2(8, 8)),
				Rect2(maxi(_quadro_fogo, 0) * 8, 0, 8, 8))
			continue
		_fogueiras.draw_texture_rect_region(_tex_fogueira, Rect2(f.canto, Vector2(16, 16)),
			Rect2(maxi(_quadro_fogo, 0) * 16, 0, 16, 16))


## O quadro da fogueira que nasce no recomeço (-1: ainda não há nada; -2: já acesa).
func _fogo_nascendo(f: Dictionary) -> int:
	if recomeco.is_empty() or int(f.get("grupo", -1)) != int(recomeco.grupo):
		return -2
	var t := _relogio - float(recomeco.ini)
	if t < Vida.RECOMECO_GIRA:
		return -1 if t < Vida.RECOMECO_GIRA - 2.0 else 0  # a lenha posta pouco antes
	if t < Vida.RECOMECO_SOPRA:
		return int(t * 2.0) % 2  # a lenha com fumaça e a brasa, enquanto ele gira o pau
	if t < Vida.RECOMECO_ACESA:
		return 2 + int(t * 2.0) % 2  # a chama pequena e crescendo, enquanto ele sopra
	if t >= Vida.RECOMECO_CABANAS and not recomeco.get("ergueu", false):
		recomeco["ergueu"] = true
		_refazer = true  # as cabanas aparecem
	return -2


## Mistura de estados do céu pela hora (com minutos), quantizada em 16 passos.
static func estado_da_hora(h: float) -> Array:
	var faixas := [
		# a manhã: a noite vira entardecer até as 6h30, e o dia só fica pleno às 8h
		[0.0, 5.0, NOITE, NOITE], [5.0, 6.5, NOITE, ENTARDECER], [6.5, 8.0, ENTARDECER, DIA],
		[8.0, 17.0, DIA, DIA], [17.0, 18.0, DIA, ENTARDECER], [18.0, 19.0, ENTARDECER, ENTARDECER],
		[19.0, 20.0, ENTARDECER, NOITE], [20.0, 24.0, NOITE, NOITE]]
	for f in faixas:
		if h >= f[0] and h < f[1]:
			var t: float = (h - f[0]) / (f[1] - f[0]) if f[2] != f[3] else 0.0
			return [f[2], f[3], floorf(t * 82.0) / 82.0]  # a frente anda de 2 em 2 linhas
	return [NOITE, NOITE, 0.0]


func _hora() -> float:
	return _hora_fixa if _hora_fixa >= 0.0 else sim.hora_continua() + _minutos


func _atualizar_horario() -> void:
	var e := estado_da_hora(_hora())
	if _atmosfera.em_clarao():
		e = [DIA, DIA, 0.0]
	_atualizar_luzes(_hora(), _atmosfera.em_clarao())
	var especial := ""
	if sim and _eclipse_ate >= sim.mundo.passo:
		especial = "eclipse"
	elif sim and _atmosfera.diluvio():
		especial = "diluvio"
	elif sim and (not sim.clima.get("tempestade", {}).is_empty() or _atmosfera.chovendo()):
		especial = "tempestade"
	elif sim and (sim.clima.get("seca", false) or _seca_ate >= sim.mundo.passo):
		especial = "seca"
	e.append(especial)
	if e == _estado:
		return
	_estado = e
	var a: int = e[0]
	var b: int = e[1]
	for i in FUNDOS.size():
		_fundos[i].texture = _textura_fundo(_nome_fundo(i, a, especial))
		_fundos[i].material.set_shader_parameter("tex_b", _textura_fundo(_nome_fundo(i, b, especial)))
	_reflexo.texture = _tex_reflexo[a]
	_reflexo.material.set_shader_parameter("tex_b", _tex_reflexo[b])
	# a noite desce do alto; a manhã sobe do horizonte
	var descendo := not (a == NOITE or (a == ENTARDECER and b == DIA))
	for m in _materiais:
		m.set_shader_parameter("estado_a", a)
		m.set_shader_parameter("estado_b", b)
		m.set_shader_parameter("t", e[2])
		m.set_shader_parameter("descendo", descendo)


## Janelas acesas do fim da tarde às 23h e de manhãzinha; de madrugada, só
## as casas de quem está acordado. No clarão do raio, tudo apaga.
func _atualizar_luzes(h: float, clarao: bool) -> void:
	if _tex_luzes.is_empty() or _modo_layout:
		return
	var madrugada := h >= 23.0 or h < 4.5
	var acesas := not clarao and (madrugada or h >= 17.5 or h < 6.5)
	_luzes.visible = acesas
	if acesas:
		var tex: Texture2D = _tex_luzes[1 if madrugada else 0]
		if _luzes.texture != tex:
			_luzes.texture = tex


## O céu de dia vira o de seca ou o de eclipse quando é o caso; com chuva, o
## de tempestade (ou o de dilúvio) cobre também o entardecer.
func _nome_fundo(i: int, estado: int, especial: String) -> String:
	if i == 0 and especial != "" and (estado == DIA or (estado == ENTARDECER and especial in ["tempestade", "diluvio"])):
		return "ceu_" + especial
	return "%s_%s" % [FUNDOS[i], ESTADOS[estado]]


## Seguindo, a vista aproxima 2x e centra a pessoa acompanhada.
func _atualizar_camera(delta: float) -> void:
	var alvo_zoom := 1
	var alvo := Vector2.ZERO
	var quem := -1
	if foco >= 0 and (_relogio > _foco_ate or sim == null or sim.mundo.posicao_de(foco) < 0.0):
		foco = -1  # o tempo passou, ou a pessoa morreu: a vista volta
	if foco >= 0:
		quem = foco
	elif seguindo and sim and sim.mundo.acompanhada >= 0:
		quem = sim.mundo.acompanhada
	if quem >= 0:
		for f in figuras:
			if f.id == quem:
				alvo_zoom = ZOOM_SEGUIR
				var meio := Vector2(f.x + f.largura / 2.0, f.base - 20)
				var vista := Vector2(LARGURA, ALTURA) / ZOOM_SEGUIR
				alvo = (meio - vista / 2.0).clamp(Vector2.ZERO, Vector2(LARGURA, ALTURA) - vista)
		if alvo_zoom == 1:  # a pessoa está numa cabana: mira a casa dela
			var x: float = sim.mundo.posicao_de(quem)
			if x >= 0.0:
				alvo_zoom = ZOOM_SEGUIR
				alvo = Vector2(clampf(x - 120.0, 0.0, 240.0), 40.0)
	if alvo_zoom != zoom:
		zoom = alvo_zoom
		camera = alvo
	else:
		camera = camera.move_toward(alvo, maxf(40.0, camera.distance_to(alvo) * 3.0) * delta)
	var c := camera.round()
	if _tremor > 0.0:  # terremoto: a vista sacode 1 px em direções sorteadas (sorteio da apresentação)
		_tremor -= delta
		c += Vector2(randi_range(-1, 1), randi_range(-1, 1))
	if [zoom, c] == _camera_aplicada:
		return
	_camera_aplicada = [zoom, c]
	scale = Vector2(zoom, zoom)
	position = -c * zoom
	# os planos de fundo andam menos que o mundo (paralaxe)
	for i in FUNDOS.size():
		_fundos[i].position = _canto_fundo[i] + (c * (1.0 - PARALAXE[i])).round()
	if _ceu:  # o céu vivo anda como o degradê: quase parado
		_ceu.position = (c * (1.0 - PARALAXE[0])).round()
	var origem: Vector2 = get_parent().global_position + position
	for m in _materiais:
		m.set_shader_parameter("origem", origem)
		m.set_shader_parameter("zoom", float(zoom))
	_atmosfera.definir_camera(origem, float(zoom))


# --- pessoas ---------------------------------------------------------------

func fogo_mais_perto(x: float) -> float:
	var melhor := -10000.0
	for f in _fogos:
		if abs(f.centro - x) < abs(melhor - x):
			melhor = f.centro
	return melhor


func _figuras_layout() -> Array:
	var r := []
	for item in _layout["pecas"]:
		if item["plano"] != "pessoa":
			continue
		r.append({"id": -1, "folha": "habitantes/" + item["peca"], "quadro": int(item["quadro"]), "largura": int(item["larg_quadro"]),
			"x": int(item["x"]), "base": int(item["base"]), "espelho": item.get("espelho", false),
			"codigo": Arte.codigo_de_tabela(item.get("troca", {})),
			"fogo": fogo_mais_perto(item["x"] + item["larg_quadro"] / 2.0)})
	return r


func _ler_argumentos() -> Dictionary:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var partes := a.substr(2).split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	return args

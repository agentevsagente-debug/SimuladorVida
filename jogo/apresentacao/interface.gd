extends Node2D
## Interface na moldura (arte/interface/): a alça com os botões, a dica do
## cursor, o leitor da crônica, o gesto dos poderes e mensagens curtas.
##
## A alça fica na faixa de cima (18 px). Ela é discreta: mostra o poder e o
## ritmo atuais; os poderes só se abrem quando o jogador clica. Os ritmos têm
## um botão cada (pausa, 1x, 10x, 50x e salto), com o atual marcado.
## Os ícones só aparecem sobre fundo escuro (a alça ou uma caixa de dica),
## nunca direto sobre o céu.
##
## O gesto: com um poder escolhido, segurar o botão sobre o mundo carrega a
## intensidade (0 a 1 em 2 s); soltar usa o poder ali. O botão direito cancela.

signal largura_mudou
signal arrastar
signal esconder
signal escala(delta: int)
signal ritmo_mudou
signal dica_feita(feitas: Array)

const Arte = preload("res://apresentacao/arte.gd")
const Simulacao = preload("res://apresentacao/simulacao.gd")
const EstanteTela = preload("res://apresentacao/estante_tela.gd")

const ALTURA_ALCA := 18
const PEGA := 10          # largura da zona de arraste à esquerda
const BOTAO := 16
const PASSO_BOTAO := 17
const PODERES := ["chuva", "raio", "fogo", "fartura", "erguer_terra", "sonho",
	"seca", "diluvio", "terremoto", "pressagio", "cura"]
## Nome do poder no núcleo e na tela.
const PODER_NUCLEO := {"chuva": "chuva", "raio": "raio", "fogo": "fogo", "fartura": "fartura",
	"erguer_terra": "erguer", "sonho": "sonho", "seca": "seca", "diluvio": "diluvio",
	"terremoto": "terremoto", "pressagio": "pressagio", "cura": "cura"}
const NOME_PODER := {"chuva": "Chuva", "raio": "Raio", "fogo": "Fogo", "fartura": "Fartura",
	"erguer_terra": "Erguer a terra", "sonho": "Sonho", "seca": "Seca", "diluvio": "Dilúvio",
	"terremoto": "Terremoto", "pressagio": "Presságio", "cura": "Cura"}
const RITMOS := ["pausa", "normal", "rapido", "rapido2", "salto"]
const NOME_RITMO := {"pausa": "Pausa (0)", "normal": "Ritmo normal, 1x (1)", "rapido": "Ritmo 10x (2)",
	"rapido2": "Ritmo 50x (3)", "salto": "Saltar ao próximo acontecimento (S)"}
## Quanto tempo real dura um dia de jogo em cada ritmo (dica do botão).
const DIA_REAL := {"normal": "um dia dura 45 min", "rapido": "um dia dura 4,5 min", "rapido2": "um dia dura 54 s",
	"pausa": "o tempo parado"}
const RITMO_DE := {"pausa": Simulacao.Ritmo.PAUSA, "normal": Simulacao.Ritmo.NORMAL,
	"rapido": Simulacao.Ritmo.RAPIDO, "rapido2": Simulacao.Ritmo.MUITO_RAPIDO}
const NOME_GRAU := {"sinal": "um sinal", "milagre": "um milagre", "imposicao": "uma imposição"}
## O grau enquanto o gesto carrega (notas dos poderes da A): o nome e a cor da carga.
const NOME_CARGA := {"brando": "brando", "sinal": "sinal", "milagre": "milagre", "dilúvio": "a água mata"}
const COR_GRAU := {"brando": 21, "sinal": 0, "milagre": 22, "dilúvio": 18}
const NOME_TRACO := {"pacifico": "pacífico", "devoto": "devoto", "curioso": "curioso",
	"ambicioso": "ambicioso", "rancoroso": "rancoroso", "desconfiado": "desconfiado",
	"generoso": "generoso", "engenhoso": "engenhoso", "corajoso": "corajoso", "medroso": "medroso"}
const NOME_ZONA := {"lago": "O lago", "praia": "A praia", "floresta": "A floresta", "morro": "O morro"}
const NECESSIDADES := ["seca", "fome", "doenca", "frio", "guerra"]
const CARGA_SEGUNDOS := 2.0
const LARGURA_DICA := 140  # largura máxima do texto da dica, com quebra de linha
const COR_PENSAMENTO := 29  # índice na paleta (A995DB, lilás): a linha do pensamento
## As dicas da primeira abertura, na ordem: cada uma aparece sozinha, discreta
## na alça, e some quando o jogador faz o que ela ensina.
const DICAS := [["poder", "Escolha um poder e segure sobre o mundo"],
	["pessoas", "Passe o cursor sobre as pessoas"], ["cronica", "C abre a crônica do mundo"],
	["ritmo", "0 a 3 mudam a velocidade do tempo"], ["esconder", "H esconde; o ícone fica na bandeja"]]
const ESPERA_DICA := 4.0  # segundos entre uma dica feita e a próxima
const DICA_PULA := 60.0   # uma dica não feita nesse tempo vai para o fim da fila (auditoria 8, P4)
## O tamanho em que as fontes 5x7 saem pixel a pixel (size=11 no .fnt). Sem ele,
## o Godot usa 16 e amplia o texto 1,45 vez, fora da grade de pixels.
const TAM_FONTE := 11
## O relógio do mundo, no canto de cima à direita, numa pastilha escura.
const RELOGIO := Rect2i(438, 1, 42, 15)
const DA_ESTACAO := {"primavera": "da primavera", "verão": "do verão", "outono": "do outono", "inverno": "do inverno"}

var vista: Node2D
var poder := ""            # poder escolhido ("" = nenhum)
var aberto := ""           # "poderes" ou ""
var botoes: Array = []     # [{id, rect, icone, selecionado}]

var _icones := {}
var _alca: Texture2D
var _botao: Texture2D
var _sob_cursor := ""
var _carregando := false
var _carga_inicio := 0.0
var _carga_ponto := Vector2.ZERO
var _cursor := Vector2(-100, -100)
var _dica: NinePatchRect
var _dica_textos: Array[Label] = []
var _dica_icone: TextureRect
## A caixa desenhada na faixa transparente ao lado da alça (dica da primeira
## abertura ou aviso), ou vazia. A moldura a inclui na região da janela: no
## Windows, a passagem do mouse recorta também o desenho.
var caixa_na_faixa := Rect2()
var _dica_bico: TextureRect   # o bico embaixo da dica, apontando para quem ela descreve
var _resumo_aberto := false  # a crônica mostra só o resumo da ausência
var _dica_balao: TextureRect  # o balãozinho de pensamento ao lado da linha do pensamento
var _dica_linhagem: TextureRect  # o ícone da linhagem ao lado do nome de quem é seguido
var _citados: Array = []
var _sonhou := {}  # id -> relógio de quando sonhou (uma estrelinha lilás sobre a cabeça por 60 s)
var _alvos_da_prece: Array = []  # x dos fogos onde o gesto atende a prece da dica aberta      # ids de quem o pensamento da dica aberta cita (ponto dourado na cabeça)
var _dica_ponto := []         # [mundo, tela] da última dica de pessoa, para atualizar com o cursor parado
var _dica_refazer := 0.0
var _cronica_acima: TextureRect
var _cronica_abaixo: TextureRect
var _cronica: NinePatchRect
var _cronica_texto: Label
var _cronica_titulo: Label
var _cronica_rolagem := 0
var _mensagem := ""
var _mensagem_ate := 0.0
var _fontes := {}
var _relogio := 0.0
var _ultimo_desenho := []
var _estante: Node2D
var _dicas_feitas: Array = []
var _dicas_ligadas := false
var _proxima_dica_em := 0.0
var _fila_dicas: Array = []   # os nomes ainda não feitos, na ordem em que aparecem
var _dica_desde := 0.0        # quando a dica da frente apareceu


func criar(p_vista: Node2D) -> void:
	vista = p_vista
	vista._interface = self
	_alca = Arte.textura("interface/alca_9s.png")
	_botao = Arte.textura("interface/botao_3q.png")
	for nome in PODERES + RITMOS + ["cronica", "linhagem", "esconder", "criar_povo", "estante"]:
		_icones[nome] = Arte.textura("interface/icones_12/%s.png" % nome)
		_icones[nome + "_8"] = Arte.textura("interface/icones_8/%s.png" % nome)
	for cor in ["clara", "escura", "dourada", "titulo"]:
		_fontes[cor] = load("res://arte/interface/fonte_5x7_%s.fnt" % cor)
	Arte.carregar_paleta()
	_fontes["pensamento"] = _fonte_na_cor(_fontes["clara"], Arte.paleta[COR_PENSAMENTO])
	_criar_dica()
	_criar_cronica()
	_estante = EstanteTela.new()
	add_child(_estante)
	move_child(_estante, 0)  # a dica fica por cima da estante
	_estante.criar(self, vista)
	_estante.abandonar.connect(_abandonar)
	_estante.fechada.connect(_montar_botoes)
	if vista.sim:
		vista.sim.eventos_novos.connect(_ao_receber_eventos)
	_montar_botoes()


func largura() -> int:
	return PEGA + botoes.size() * PASSO_BOTAO + 4


# --- alça ------------------------------------------------------------------

func _montar_botoes() -> void:
	var ritmo := _ritmo_atual()
	var lista := []
	if _mundo_vazio():  # sem ninguém, o único poder é criar um povo novo
		aberto = "" if aberto == "poderes" else aberto
		lista.append({"id": "criar_povo", "icone": "criar_povo", "selecionado": poder == "criar_povo"})
	elif aberto == "poderes":
		for p in PODERES:
			lista.append({"id": "poder:" + p, "icone": p, "selecionado": p == poder})
	else:
		lista.append({"id": "poderes", "icone": poder if poder != "" else "chuva", "selecionado": poder != ""})
	for r in RITMOS:
		lista.append({"id": "ritmo:" + r, "icone": r, "selecionado": r == ritmo})
	lista.append({"id": "cronica", "icone": "cronica", "selecionado": _cronica.visible})
	lista.append({"id": "estante", "icone": "estante", "selecionado": _estante.visible and _estante.modo != "fim"})
	if not _mundo_vazio():  # sem ninguém vivo, não há linhagem para seguir
		lista.append({"id": "linhagem", "icone": "linhagem", "selecionado": vista.seguindo})
	lista.append({"id": "esconder", "icone": "esconder", "selecionado": false})
	var antes := botoes.size()
	botoes = []
	for i in lista.size():
		var b: Dictionary = lista[i]
		b["rect"] = Rect2i(PEGA + i * PASSO_BOTAO, 1, BOTAO, BOTAO)
		botoes.append(b)
	if botoes.size() != antes:
		largura_mudou.emit()
	queue_redraw()


func _mundo_vazio() -> bool:
	return vista.sim != null and vista.sim.mundo.fim_do_mundo


func _ritmo_atual() -> String:
	if vista.sim == null:
		return "normal"
	return Simulacao.NOME_RITMO[vista.sim.ritmo]


func _botao_em(p: Vector2) -> Dictionary:
	for b in botoes:
		if b.rect.has_point(Vector2i(p)):
			return b
	return {}


func _apertar(id: String) -> void:
	if id == "poderes":
		aberto = "" if aberto == "poderes" else "poderes"
	elif id.begins_with("poder:"):
		var p := id.substr(6)
		poder = "" if p == poder else p
		aberto = ""
		_avisar(NOME_PODER[poder] + ": segure sobre o mundo" if poder != "" else "Nenhum poder escolhido")
	elif id.begins_with("ritmo:"):
		aberto = ""
		marcar_dica("ritmo")
		var r := id.substr(6)
		if r == "salto":
			_saltar()
		else:
			vista.sim.definir_ritmo(RITMO_DE[r])
			ritmo_mudou.emit()
	elif id == "criar_povo":
		poder = "" if poder == "criar_povo" else "criar_povo"
		_avisar("Criar um povo: clique onde ele vai nascer" if poder != "" else "Nenhum poder escolhido")
	elif id == "cronica":
		if _estante.visible:
			_estante.fechar()
		alternar_cronica()
	elif id == "estante":
		alternar_estante()
	elif id == "linhagem":
		vista.alternar_seguir()
		_avisar(_texto_linhagem())
	elif id == "esconder":
		esconder.emit()
	_montar_botoes()


func alternar_estante() -> void:
	if _estante.visible and _estante.modo != "fim":
		_estante.fechar()
	else:
		if _cronica.visible:
			alternar_cronica()
		_dica.visible = false
		_estante.abrir()
	_montar_botoes()


## Pela estante, depois da confirmação: a crônica vai para a estante e começa outro mundo.
func _abandonar() -> void:
	var livro: Dictionary = vista.sim.abandonar()
	poder = ""
	aberto = ""
	_montar_botoes()
	_avisar("%s foi para a estante. Começou outro mundo." % livro.get("titulo", "A crônica"))


func _ao_receber_eventos(eventos: Array) -> void:
	for ev in eventos:
		if ev["tipo"] == "fim_do_mundo":
			poder = ""
			aberto = ""
			if _cronica.visible:
				alternar_cronica()
			var m = vista.sim.mundo
			var livro: Dictionary = m.livros[-1] if not m.livros.is_empty() else {}
			_estante.avisar_fim(livro)
			_montar_botoes()
		elif ev["tipo"] == "livro_fechado" or ev["tipo"] == "os_ultimos":
			_montar_botoes()


func _saltar() -> void:
	var antes: Dictionary = vista.sim.tempo
	var eventos: Array = vista.sim.saltar()
	var depois: Dictionary = vista.sim.tempo
	var dias: int = (depois["ano"] - antes["ano"]) * 40 + depois["dia"] - antes["dia"]
	var nota := ""
	for ev in eventos:
		if ev["camada"] != "ambiente":
			nota = _nome_evento(ev["tipo"])
			break
	_avisar(("Passaram %d dias. " % dias if dias > 0 else "") + (nota if nota != "" else "Nada de notável."))


func _texto_linhagem() -> String:
	var m = vista.sim.mundo
	if m.acompanhada < 0:
		return "A linhagem acabou."
	var pessoa = m.pessoa(m.acompanhada)
	var nome: String = pessoa.nome
	return ("Seguindo %s, %d anos" if vista.seguindo else "Acompanhando %s, %d anos") % [nome, int(pessoa.idade(m.ano()))]


# --- entrada (a moldura repassa; devolve true se usou o evento) --------------

func tratar(event: InputEvent, pos: Vector2, faixa: int) -> bool:
	_cursor = pos
	var na_alca := pos.y < faixa and pos.x < largura()
	var no_relogio := RELOGIO.has_point(Vector2i(pos))
	if event is InputEventMouseMotion and no_relogio:
		_mostrar_dica([_data_do_relogio()], -1, Vector2(RELOGIO.position.x - 70, RELOGIO.end.y + 3), false)
		return true
	if event is InputEventMouseButton and no_relogio:
		return true
	if event is InputEventMouseMotion:
		var b := _botao_em(pos) if na_alca else {}
		var novo: String = b.get("id", "")
		if novo != _sob_cursor:
			_sob_cursor = novo
			queue_redraw()
		if _cronica.visible:
			return true
		if _estante.visible and _estante.modo != "fim" and not na_alca and pos.y >= faixa:
			_estante.tratar(event, pos - Vector2(0, faixa))
			return true
		if not na_alca and pos.y >= faixa:
			_atualizar_dica(vista.para_mundo(pos - Vector2(0, faixa)), pos)
		elif not novo.is_empty():
			_mostrar_dica_botao(novo, Vector2(b.rect.position) + Vector2(0, faixa))
		else:
			_dica.visible = false
		return false
	if event is InputEventMouseButton:
		if OS.has_environment("DEPURAR_ALCA"):
			print("[alca] botao=%d apertado=%s duplo=%s pos=%s botoes=%s" % [event.button_index, event.pressed,
				event.double_click, pos, botoes.map(func(b): return [b.id, b.rect.position.x])])
		# No Windows, um clique rápido depois de outro chega duas vezes: o
		# "apertou" normal e outro marcado como duplo, sem soltar no meio.
		# O segundo apertaria o botão de novo ou reiniciaria a carga do gesto.
		if event.double_click:
			return true
		if event.pressed and na_alca:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var b := _botao_em(pos)
				if b.is_empty():
					arrastar.emit()
				else:
					_apertar(b.id)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				escala.emit(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				escala.emit(-1)
			return true
		if _estante.visible and pos.y >= faixa:
			_estante.tratar(event, pos - Vector2(0, faixa))
			_montar_botoes()
			return true
		if _cronica.visible:
			if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_rolar(-2)
			elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_rolar(2)
			elif event.pressed and not _cronica.get_rect().has_point(pos):
				alternar_cronica()
			return true
		if pos.y < faixa:
			return false
		var mundo_p: Vector2 = vista.para_mundo(pos - Vector2(0, faixa))
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and poder == "criar_povo":
				_criar_povo(mundo_p.x)
			elif event.pressed and poder != "":
				_carregando = true
				_carga_inicio = _relogio
				_carga_ponto = mundo_p
				_dica.visible = false
			elif not event.pressed and _carregando:
				_carregando = false
				_usar_poder()
			elif event.pressed:
				vista.clicar(pos - Vector2(0, faixa))
			queue_redraw()
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _carregando:
				_carregando = false
				_avisar("Cancelado")
			elif poder != "":
				poder = ""
				_montar_botoes()
			queue_redraw()
			return true
	return false


func tecla(keycode: int) -> bool:
	if _estante.visible and keycode in [KEY_LEFT, KEY_RIGHT, KEY_PAGEUP, KEY_PAGEDOWN]:
		return _estante.tecla(keycode)
	match keycode:
		KEY_C:
			if _estante.visible:
				_estante.fechar()
			alternar_cronica()
		KEY_E:
			alternar_estante()
		KEY_L:
			_apertar("linhagem")
		KEY_D:
			vista.modo_discreto = not vista.modo_discreto
			_avisar("Modo discreto ligado" if vista.modo_discreto else "Modo discreto desligado")
		KEY_SPACE:
			_apertar("ritmo:normal" if vista.sim.ritmo == Simulacao.Ritmo.PAUSA else "ritmo:pausa")
		KEY_0, KEY_KP_0:
			_apertar("ritmo:pausa")
		KEY_1, KEY_KP_1:
			_apertar("ritmo:normal")
		KEY_2, KEY_KP_2:
			_apertar("ritmo:rapido")
		KEY_3, KEY_KP_3:
			_apertar("ritmo:rapido2")
		KEY_S:
			_apertar("ritmo:salto")
		KEY_ESCAPE:
			if _estante.visible:
				_estante.voltar()
				_montar_botoes()
			elif _cronica.visible:
				alternar_cronica()
			elif poder != "" or _carregando:
				_carregando = false
				poder = ""
				_montar_botoes()
		_:
			return false
	return true


func _criar_povo(x: float) -> void:
	var r: Dictionary = vista.sim.criar_povo(x)
	print("[interface] criar povo em x=%d -> %s" % [x, r])
	poder = ""
	_montar_botoes()
	if r.get("ok", false):
		_avisar("Nasceu um povo novo: começa %s." % String(vista.sim.mundo.nome_da_era()).to_lower())
		vista.comecar_recomeco(int(r.get("grupo", -1)))
	else:
		_avisar(String(r.get("motivo", "Não deu certo")))


func iniciar_dicas(feitas: Array) -> void:
	_dicas_feitas = feitas.duplicate()
	_dicas_ligadas = true
	_fila_dicas = DICAS.map(func(d): return d[0]).filter(func(n): return not n in _dicas_feitas)
	_proxima_dica_em = _relogio + 2.0
	_dica_desde = _proxima_dica_em


## A dica que aparece agora, ou "" (nenhuma, ou esperando entre uma e outra).
## Uma dica não feita em DICA_PULA segundos (de noite, por exemplo, não há em
## quem passar o cursor) vai para o fim da fila e volta depois das outras.
func _dica_atual() -> String:
	if not _dicas_ligadas or _fila_dicas.is_empty() or _relogio < _proxima_dica_em:
		return ""
	if _relogio - _dica_desde > DICA_PULA and _fila_dicas.size() > 1:
		_fila_dicas.push_back(_fila_dicas.pop_front())
		_proxima_dica_em = _relogio + ESPERA_DICA
		_dica_desde = _proxima_dica_em
		return ""
	for d in DICAS:
		if d[0] == _fila_dicas[0]:
			return d[1]
	return ""


## O jogador fez o que a dica ensina. Feita fora da ordem, ela sai da fila e não volta.
func marcar_dica(nome: String) -> void:
	if nome in _dicas_feitas:
		return
	_dicas_feitas.append(nome)
	if _dicas_ligadas and not _fila_dicas.is_empty():
		var era_a_atual: bool = _fila_dicas[0] == nome and _relogio >= _proxima_dica_em
		_fila_dicas.erase(nome)
		if era_a_atual:
			_proxima_dica_em = _relogio + ESPERA_DICA
			_dica_desde = _proxima_dica_em
	dica_feita.emit(_dicas_feitas)
	queue_redraw()


## A cruzinha da cura, em verde (5 × 5, com contorno escuro); em lilás, a estrelinha do sonho.
func _cruz(c: Vector2, cor := 28) -> void:
	draw_rect(Rect2(c + Vector2(-2, -1), Vector2(5, 3)), Arte.paleta[3])
	draw_rect(Rect2(c + Vector2(-1, -2), Vector2(3, 5)), Arte.paleta[3])
	draw_rect(Rect2(c + Vector2(-1, 0), Vector2(3, 1)), Arte.paleta[cor])
	draw_rect(Rect2(c + Vector2(0, -1), Vector2(1, 3)), Arte.paleta[cor])


## Quem sonhou (evento `sonho`): marcado por 60 s, porque o sonho muda uma pessoa, não o povo.
func marcar_sonho(id: int) -> void:
	_sonhou[id] = _relogio
	for k in _sonhou.keys():
		if _relogio - float(_sonhou[k]) > 60.0:
			_sonhou.erase(k)


## Um aviso na alça de um evento que é consequência longa da repetição (hábito, dependência).
func avisar_evento(texto: String) -> void:
	if texto != "":
		_avisar(texto)
		_mensagem_ate = _relogio + 5.0


## O jogador já escondeu a janela alguma vez (o aviso de como voltar só sai na primeira).
func ja_escondeu() -> bool:
	return "esconder" in _dicas_feitas


## Usa um poder como se o jogador tivesse feito o gesto (testes e capturas).
func demo(p: String, x: float, intensidade_fixa: float) -> void:
	if p == "criar_povo":
		_criar_povo(x)
		return
	poder = p
	_carga_ponto = Vector2(x, 100)
	_carga_inicio = _relogio - intensidade_fixa * CARGA_SEGUNDOS
	_usar_poder()
	_montar_botoes()


## O grau que o gesto teria se fosse solto agora (a imposição, 3º uso em 3 dias, só o núcleo sabe).
func _grau_da_carga(carga: float) -> String:
	if poder == "fogo" and carga < Simulacao.Mundo.FOGO_BRANDO:
		return "brando"
	if poder == "diluvio" and carga >= 0.7:  # o mais forte: pode matar muitos (aviso)
		return "dilúvio"
	return "milagre" if carga >= 0.5 else "sinal"


func intensidade() -> float:
	return clampf((_relogio - _carga_inicio) / CARGA_SEGUNDOS, 0.0, 1.0)


func _usar_poder() -> void:
	var r: Dictionary = vista.sim.usar_poder(PODER_NUCLEO[poder], _carga_ponto.x, intensidade())
	print("[interface] poder %s em x=%d intensidade=%.2f -> %s" % [poder, _carga_ponto.x, intensidade(), r])
	if r.get("ok", false):
		marcar_dica("poder")
		var alvo := ""
		if int(r.get("alvo", -1)) >= 0:
			alvo = " sobre " + String(vista.sim.mundo.pessoa(r["alvo"]).nome)
		_avisar("%s: %s%s" % [NOME_PODER[poder], NOME_GRAU.get(r.get("grau", ""), ""), alvo])
	else:
		_avisar(String(r.get("motivo", "Não deu certo")))


## Onde está, na tela, a cabeça de quem a câmera segue; longe da tela se ninguém.
func _cabeca_seguida() -> Vector2:
	if not vista.seguindo or vista.sim == null:
		return Vector2(-100, -100)
	for f in vista.figuras:
		if f.id == vista.sim.mundo.acompanhada:
			return (vista.para_tela(Vector2(f.x + f.largura / 2.0, f.base - 12)) + Vector2(0, ALTURA_ALCA)).round()
	return Vector2(-100, -100)


func avancar(delta: float) -> void:
	_relogio += delta
	_refazer_dica(delta)
	if not _citados.is_empty() or (_dica.visible and not _alvos_da_prece.is_empty()) or poder == "cura" \
			or not _sonhou.is_empty():
		queue_redraw()  # o ponto dourado acompanha quem anda; a seta do fogo pulsa
	var assinatura := [_cabeca_seguida(), _texto_relogio(), _carregando, int(intensidade() * 8.0) if _carregando else 0,
		_mensagem if _relogio < _mensagem_ate else "", _ritmo_atual(), vista.seguindo, _mundo_vazio(), _dica_atual()]
	if assinatura != _ultimo_desenho:
		if _ultimo_desenho.size() <= 4 or (assinatura[4] != _ultimo_desenho[4] or assinatura[5] != _ultimo_desenho[5]
				or assinatura[6] != _ultimo_desenho[6]):
			_montar_botoes()
		_ultimo_desenho = assinatura
		queue_redraw()


## "14:15": a hora do mundo, com os minutos da fração do passo. No 50x, de 10
## em 10 minutos, para não piscar; na pausa, parado.
func _texto_relogio() -> String:
	if vista.sim == null or vista.sim.tempo.is_empty():
		return ""
	var f: float = vista.sim.fracao()
	var minutos := int(f * 6.0) * 10 if vista.sim.ritmo == Simulacao.Ritmo.MUITO_RAPIDO else int(f * 60.0)
	return "%02d:%02d" % [int(vista.sim.tempo["hora"]), mini(minutos, 59)]


func _data_do_relogio() -> String:
	var t: Dictionary = vista.sim.tempo
	var dia_na_estacao := (int(t["dia"]) - 1) % 10 + 1
	return "Dia %d %s, ano %d" % [dia_na_estacao, DA_ESTACAO.get(t["estacao"], ""), t["ano"]]


func _avisar(texto: String) -> void:
	_mensagem = texto.left(1).to_upper() + texto.substr(1)  # o núcleo às vezes manda em minúscula
	_mensagem_ate = _relogio + 2.5
	queue_redraw()


# --- dica do cursor ----------------------------------------------------------

## A mesma fonte de pixels, com as letras numa cor da paleta.
func _fonte_na_cor(base: FontFile, cor: Color) -> FontFile:
	var f: FontFile = base.duplicate(true)
	var tam := Vector2i(TAM_FONTE, 0)
	var img: Image = f.get_texture_image(0, tam, 0).duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, Color(cor, img.get_pixel(x, y).a))
	f.set_texture_image(0, tam, 0, img)
	return f


func _criar_dica() -> void:
	_dica = NinePatchRect.new()
	_dica.texture = Arte.textura("interface/caixa_dica_9s.png")
	_dica.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	_dica.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_dica.set_patch_margin(lado, 4)
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.visible = false
	add_child(_dica)
	for i in 6:
		var l := Label.new()
		l.add_theme_font_override("font", _fontes["dourada" if i == 0 else "clara"])
		l.add_theme_font_size_override("font_size", TAM_FONTE)
		l.add_theme_constant_override("line_spacing", 0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dica.add_child(l)
		_dica_textos.append(l)
	_dica_icone = TextureRect.new()
	_dica_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_child(_dica_icone)
	_dica_balao = TextureRect.new()
	var balao := AtlasTexture.new()
	balao.atlas = Arte.textura("sinais/balao_5v.png")
	balao.region = Rect2(12, 0, 6, 5)  # a variação 2: pensamento
	_dica_balao.texture = balao
	_dica_balao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_child(_dica_balao)
	_dica_linhagem = TextureRect.new()
	_dica_linhagem.texture = _icones["linhagem_8"]
	_dica_linhagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_child(_dica_linhagem)
	_dica_bico = TextureRect.new()
	_dica_bico.texture = Arte.textura("interface/dica_ponteiro.png")
	_dica_bico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.add_child(_dica_bico)


func _atualizar_dica(p: Vector2, tela: Vector2) -> void:
	if _carregando:
		return
	var o: Dictionary = vista.objeto_em(p)
	var linhas: Array = []
	var icone := -1
	var alvo := tela
	var pensamento := -1  # a linha do pensamento, se houver
	var leve := -1        # uma linha em lilás, sem o balãozinho (a resposta da prece)
	var linhagem := false
	_dica_ponto = []
	_citados = []
	_alvos_da_prece = []
	match o.get("tipo", ""):
		"pessoa":
			marcar_dica("pessoas")
			var fig: Dictionary = o.get("figura", {})
			if not fig.is_empty():  # o bico aponta para a cabeça de quem a dica descreve
				alvo = vista.para_tela(Vector2(fig.x + fig.largura / 2.0, fig.base - 12)) + Vector2(0, ALTURA_ALCA)
			var pe: Dictionary = o.pessoa
			_dica_ponto = [p, tela]
			# API: o que faz, o que pensa e o humor (mundo.dica); sem ela, os traços, como antes
			var d: Dictionary = vista.sim.mundo.dica(pe["id"]) if vista.sim.mundo.has_method("dica") else {}
			var titulo := "%s, %d anos" % [pe["nome"], pe["idade"]]
			if String(d.get("humor", "")) != "":
				titulo += " — " + String(d["humor"])
			linhas.append(titulo)
			var papel := "" if pe["papel"] == "" else \
				("líder" if pe["papel"] == "lider" else "sacerdote" if pe["sexo"] == "m" else "sacerdotisa")
			if d.is_empty():
				var detalhes := ", ".join(pe["tracos"].map(func(t): return NOME_TRACO.get(t, t)))
				linhas.append(papel + ", " + detalhes if papel != "" else detalhes)
			else:
				var fazendo := String(d.get("fazendo", ""))
				if papel != "":
					fazendo = papel + (", " + fazendo if fazendo != "" else "")
				if fazendo != "":
					linhas.append(fazendo.left(1).to_upper() + fazendo.substr(1))
				if String(d.get("sonho", "")) != "":  # dormindo, o sonho como narração, sem aspas
					pensamento = linhas.size()
					linhas.append(String(d["sonho"]))
				elif String(d.get("pensamento", "")) != "":  # quem dorme sem sonhar não pensa nada
					pensamento = linhas.size()
					linhas.append("\"%s\"" % d["pensamento"])
					_citados = _citados_em(String(d["pensamento"]), int(pe["id"]))
			linhagem = pe.get("acompanhada", false)  # o ícone da linhagem ao lado do nome
			if not o.prece.is_empty():
				linhas.append("reza: " + o.prece["texto"])
				icone = NECESSIDADES.find(o.prece["necessidade"])
		"sinal":
			var pr: Dictionary = o.prece
			var autor = vista.sim.mundo.pessoa(pr["autor"])
			linhas.append("Prece de " + String(autor.nome))
			linhas.append(pr["texto"])
			linhas.append("reza desde hoje" if pr["dias"] == 0 else ("espera há %d dias" % pr["dias"] if pr["dias"] != 1 else "espera há 1 dia"))
			icone = NECESSIDADES.find(pr["necessidade"])
			# de leve, em lilás: o que atende e onde o gesto pega (o fogo do povo, marcado em dourado)
			var atendem: Array = pr.get("atendem", [])
			if not atendem.is_empty():
				var nomes: Array = atendem.map(func(a): return String(NOME_PODER.get(a, a)).to_lower())
				var resposta := " ou ".join(nomes)
				if pr.get("fogo_brando", false):
					resposta += " curto"
				leve = linhas.size()
				linhas.append(("Responde: %s, no povo inimigo" if pr["necessidade"] == "guerra" else "Responde: %s, no fogo do povo") % resposta)
			_alvos_da_prece = [float(pr.get("x_povo", -1.0))]
			if pr["necessidade"] == "guerra" and int(pr.get("inimigo", -1)) >= 0:
				for c in vista.sim.construcoes:
					if c["tipo"] == "fogueira" and int(c.get("grupo", -2)) == int(pr["inimigo"]):
						_alvos_da_prece = [float(c["x"])]
						break
		"lugar":
			# à noite, quem dorme está dentro da cabana: a dica vai nela, com o sonho em lilás
			var cab: Dictionary = vista.sim.mundo.dica_cabana(p.x) if vista.sim.mundo.has_method("dica_cabana") else {}
			if not cab.is_empty() and not cab.get("dormem", []).is_empty():
				var dormem: Array = cab["dormem"]
				if dormem.size() <= 5:
					linhas.append(String(cab["texto"]))
				else:  # casa cheia: os 4 primeiros e quantos mais
					var nomes: Array = dormem.slice(0, 4).map(func(id): return String(vista.sim.mundo.pessoa(id).nome))
					linhas.append("Dormem aqui: %s e mais %d" % [", ".join(nomes), dormem.size() - 4])
				if String(cab.get("sonho", "")) != "":
					pensamento = 1
					linhas.append(String(cab["sonho"]))
				alvo = tela - Vector2(0, 4)
				_mostrar_dica(linhas, -1, alvo, true, pensamento)
				return
			var z: Dictionary = o.zona
			var vila: Dictionary = o.get("vila", {})
			if not vila.is_empty():  # sobre o acampamento ou a vila, o nome dela vem antes da zona
				linhas.append(("O acampamento" if vila["estagio"] < 2 else "A vila") + " de " + String(vila["nome"]))
				linhas.append(NOME_ZONA.get(z["chave"], z["nome"]).to_lower())
			else:
				linhas.append(NOME_ZONA.get(z["chave"], z["nome"]))
			alvo = tela - Vector2(0, 4)
			var nomes: Array = []
			for g in z["nomes"]:
				nomes.append(z["nomes"][g])
			if not nomes.is_empty():
				linhas.append("chamado " + ", ".join(nomes.slice(0, 2)))
			var estado := []
			if z["seca"]:
				estado.append("em seca")
			if z["queimada"]:
				estado.append("queimada")
			if z["comida"] > 1.2:
				estado.append("farta")
			if not estado.is_empty():
				linhas.append(", ".join(estado))
	_mostrar_dica(linhas, icone, alvo, true, pensamento, not _dica_ponto.is_empty(), linhagem, leve)


## Quem, entre as pessoas na tela, o pensamento cita pelo nome (menos a própria).
func _citados_em(texto: String, proprio: int) -> Array:
	var r := []
	var palavras := texto.replace(",", " ").replace(".", " ").replace("!", " ").replace("?", " ").split(" ", false)
	for p in vista.sim.pessoas:
		if p["id"] != proprio and String(p["nome"]) in palavras:
			r.append(p["id"])
	return r


## Com o cursor parado sobre alguém, a dica acompanha o que a pessoa passa a fazer.
func _refazer_dica(delta: float) -> void:
	_dica_refazer -= delta
	if _dica_refazer > 0.0 or _dica_ponto.is_empty() or not _dica.visible:
		return
	_dica_refazer = 0.5
	_atualizar_dica(_dica_ponto[0], _dica_ponto[1])


func _mostrar_dica_botao(id: String, canto: Vector2) -> void:
	var nome := ""
	if id.begins_with("poder:"):  # o gesto curto é um sinal; segurando mais, vira milagre (auditoria 8, P9)
		var linhas := [NOME_PODER[id.substr(6)], "Segure mais para um milagre"]
		if id == "poder:fogo":
			linhas.append("Curto, o fogo só acende e aquece")
		_mostrar_dica(linhas, -1, canto + Vector2(4, 22), false)
		return
	elif id.begins_with("ritmo:"):
		var r := id.substr(6)
		if DIA_REAL.has(r):
			_mostrar_dica([NOME_RITMO[r], DIA_REAL[r]], -1, canto + Vector2(4, 22), false)
			return
		nome = NOME_RITMO[r]
	else:
		nome = {"poderes": "Poderes", "ritmo": "Ritmo do tempo", "cronica": "Crônica (C)",
			"criar_povo": "Criar um povo novo", "estante": "Estante de crônicas (E)",
			"linhagem": "Seguir a linhagem (L)", "esconder": "Esconder (H)"}.get(id, "")
	_mostrar_dica([nome], -1, canto + Vector2(4, 22), false)


## `pensamento`: a linha que vai na cor do pensamento, com o balãozinho ao lado.
## `de_pessoa`: sem lugar acima, a dica vai para o lado, sem cobrir quem ela descreve.
func _mostrar_dica(linhas: Array, icone: int, perto: Vector2, acima := true, pensamento := -1,
		de_pessoa := false, linhagem := false, leve := -1) -> void:
	if linhas.is_empty():
		_dica.visible = false
		_citados = []
		_alvos_da_prece = []
		return
	if not de_pessoa:
		_citados = []
	var y := 3
	var w := 0
	_dica_balao.visible = false
	for i in _dica_textos.size():
		var l := _dica_textos[i]
		l.visible = i < linhas.size()
		if not l.visible:
			continue
		l.text = linhas[i]
		var recuo := 8 if i == pensamento else 0
		var largura_max := LARGURA_DICA - recuo
		l.add_theme_font_override("font", _fontes["dourada" if i == 0 else "pensamento" if i in [pensamento, leve] else "clara"])
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		var tamanho := l.get_minimum_size()
		if tamanho.x > largura_max:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(largura_max, 0)
			l.size = Vector2(largura_max, 0)
			tamanho = Vector2(largura_max, l.get_minimum_size().y)
		else:
			l.custom_minimum_size = Vector2.ZERO
			l.size = tamanho
		l.position = Vector2(5 + recuo, y)
		if i == pensamento:
			_dica_balao.visible = true
			_dica_balao.position = Vector2(5, y + 2)
		if i == 0 and linhagem:  # o ícone da linhagem (8 × 8) logo depois do nome
			_dica_linhagem.position = Vector2(5 + tamanho.x + 3, y + 1)
			tamanho.x += 11
		y += int(tamanho.y)
		w = maxi(w, int(tamanho.x) + recuo)
	_dica_linhagem.visible = linhagem
	var extra := 0
	_dica_icone.visible = icone >= 0
	if icone >= 0:
		var at := AtlasTexture.new()
		at.atlas = Arte.textura("sinais/necessidade_5v.png")
		at.region = Rect2(icone * 8, 0, 8, 8)
		_dica_icone.texture = at
		_dica_icone.position = Vector2(w + 8, 4)
		extra = 10
	var tamanho_caixa := Vector2(w + 10 + extra, y + 3)
	_dica.size = tamanho_caixa
	var pos := perto + Vector2(-tamanho_caixa.x / 2.0, -tamanho_caixa.y - 6) if acima else perto
	pos.x = clampf(pos.x, 1, 480 - tamanho_caixa.x - 1)
	var em_cima := acima
	if pos.y < 19 and de_pessoa:  # sem lugar acima da cabeça: ao lado da pessoa, nunca por cima dela
		em_cima = false
		pos.x = perto.x + 8 if perto.x + 8 + tamanho_caixa.x < 479 else perto.x - 8 - tamanho_caixa.x
		pos.y = perto.y - 4
	elif pos.y < 19:
		pos.y = perto.y + 10
		em_cima = false
	pos.y = clampf(pos.y, 19, 178 - tamanho_caixa.y - 1)
	_dica.position = pos.round()
	_dica.visible = true
	# o bico (6 × 3) sai da borda de baixo e aponta para o alvo, logo abaixo
	_dica_bico.visible = em_cima
	if em_cima:
		_dica_bico.position = Vector2(clampf(roundf(perto.x - 3.0 - _dica.position.x), 3.0, tamanho_caixa.x - 9.0),
			tamanho_caixa.y - 1.0)


# --- crônica -----------------------------------------------------------------

func _criar_cronica() -> void:
	_cronica = NinePatchRect.new()
	_cronica.texture = Arte.textura("interface/caixa_cronica_9s.png")
	_cronica.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	_cronica.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_cronica.set_patch_margin(lado, 6)
	_cronica.position = Vector2(24, 22)
	_cronica.size = Vector2(432, 152)
	_cronica.visible = false
	_cronica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cronica)
	_cronica_titulo = Label.new()
	_cronica_titulo.add_theme_font_override("font", _fontes["titulo"])
	_cronica_titulo.add_theme_font_size_override("font_size", TAM_FONTE)
	_cronica_titulo.position = Vector2(10, 6)
	_cronica_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cronica.add_child(_cronica_titulo)
	_cronica_acima = _seta(true)
	_cronica_acima.position = Vector2(416, 8)
	_cronica.add_child(_cronica_acima)
	_cronica_abaixo = _seta(false)
	_cronica_abaixo.position = Vector2(416, 140)
	_cronica.add_child(_cronica_abaixo)
	var recorte := Control.new()
	recorte.clip_contents = true
	recorte.position = Vector2(10, 19)
	recorte.size = Vector2(412, 132)  # ajustado a linhas inteiras em _rolar()
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cronica.add_child(recorte)
	_cronica_texto = Label.new()
	_cronica_texto.add_theme_font_override("font", _fontes["escura"])
	_cronica_texto.add_theme_font_size_override("font_size", TAM_FONTE)
	_cronica_texto.add_theme_constant_override("line_spacing", 0)
	_cronica_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cronica_texto.size = Vector2(412, 0)
	_cronica_texto.custom_minimum_size = Vector2(412, 0)
	recorte.add_child(_cronica_texto)


## Uma setinha de 5 × 3 na tinta escura: há mais texto acima (ou abaixo).
func _seta(para_cima: bool) -> TextureRect:
	var img := Image.create(5, 3, false, Image.FORMAT_RGBA8)
	for y in 3:
		var meia := y if para_cima else 2 - y
		for x in range(2 - meia, 3 + meia):
			img.set_pixel(x, y, Arte.paleta[8])
	var t := TextureRect.new()
	t.texture = ImageTexture.create_from_image(img)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func alternar_cronica() -> void:
	# com o resumo da ausência aberto, o C passa para a crônica inteira, em vez de fechar
	_cronica.visible = not _cronica.visible or _resumo_aberto
	_resumo_aberto = false
	_dica.visible = false
	if _cronica.visible:
		marcar_dica("cronica")
		mostrar_cronica("")
	_montar_botoes()


## Abre a crônica; `antes` vem em cima (o relato da ausência, por exemplo).
## Com `titulo`, mostra só `antes`, com esse título (o resumo da ausência: a
## crônica inteira continua no C).
func mostrar_cronica(antes: String, titulo := "") -> void:
	var m = vista.sim.mundo
	var texto := ""
	if antes != "":
		texto = antes + "\n\n"
	var t: Dictionary = vista.sim.tempo
	if titulo == "":
		texto += _sem_markdown(m.cronica()) + "\n\nAno %d, dia %d: o ano ainda está em curso." % [t["ano"], t["dia"]]
	else:
		texto += "C abre a crônica inteira."
	_cronica_titulo.text = titulo if titulo != "" else "Crônica: " + String(m.nome_da_era())
	_resumo_aberto = titulo != ""
	_cronica_texto.text = texto
	_cronica.visible = true
	_cronica_texto.size.y = 0
	_montar_botoes()
	# começa no fim, onde está o mais recente (as linhas só existem depois do layout)
	await get_tree().process_frame
	_cronica_rolagem = _cronica_texto.get_line_count() if antes == "" else 0
	_rolar(0)


func _rolar(d: int) -> void:
	var altura := _cronica_texto.get_line_height()
	var cabem := int(124 / altura)
	_cronica_texto.get_parent().size.y = cabem * altura
	var linhas := _cronica_texto.get_line_count()
	_cronica_rolagem = clampi(_cronica_rolagem + d, 0, maxi(0, linhas - cabem))
	_cronica_texto.position.y = -_cronica_rolagem * altura
	_cronica_acima.visible = _cronica_rolagem > 0
	_cronica_abaixo.visible = _cronica_rolagem < linhas - cabem


static func _sem_markdown(md: String) -> String:
	var r := []
	var titulo := false
	for linha in md.split("\n"):
		var l := linha.strip_edges()
		if titulo and l == "":
			continue  # o parágrafo vem logo abaixo do título do ano
		titulo = l.begins_with("#")
		while l.begins_with("#"):
			l = l.substr(1)
		l = l.strip_edges().replace("**", "").replace("*", "").replace("_", " ")
		l = l.replace("“", "«").replace("”", "»").replace("’", "'")
		if l.begins_with("> "):
			l = l.substr(2)
		r.append(l)
	var texto := "\n".join(r)
	while texto.contains("\n\n\n"):
		texto = texto.replace("\n\n\n", "\n\n")
	return texto.strip_edges()


static func _nome_evento(tipo: String) -> String:
	return {"prece": "Alguém rezou.", "nascimento": "Nasceu alguém.", "gemeos": "Nasceram gêmeos.",
		"morte": "Alguém morreu.", "casamento": "Houve um casamento.",
		"casamento_entre_grupos": "Dois povos se uniram num casamento.", "fome_inicio": "Começou uma fome.",
		"fome_fim": "A fome passou.", "doenca_inicio": "Começou uma doença.", "doenca_fim": "A doença passou.",
		"ataque": "Houve um ataque.", "rixa": "Houve uma briga.", "roubo": "Houve um roubo.",
		"guerra_inicio": "Começou uma guerra.", "guerra_fim": "Uma guerra acabou.", "tregua": "Houve uma trégua.",
		"conquista": "Um povo conquistou outro.", "fusao": "Dois povos viraram um.",
		"crenca": "Um povo passou a crer.", "nova_crenca": "Nasceu uma nova crença.",
		"deus_renomeado": "O deus ganhou um novo nome.", "sacerdote": "Surgiu um sacerdote.",
		"edito": "Um sacerdote ditou uma regra.", "exigencia": "O povo fez uma exigência ao deus.",
		"reforma": "A fé mudou.", "silencio": "O deus ficou em silêncio.", "desamparo": "Um povo se sentiu desamparado.",
		"culpado": "Culparam alguém.", "dependencia": "Um povo depende do deus.",
		"separacao": "Um povo se dividiu.", "mudanca": "Um povo se mudou.", "expedicao": "Partiu uma expedição.",
		"extincao_grupo": "Um povo acabou.", "novo_lider": "Há um novo líder.", "agricultura": "Nasceu a agricultura.",
		"descoberta": "Alguém descobriu algo.", "conhecimento_perdido": "Um saber se perdeu.",
		"costume": "Nasceu um costume.", "costume_esquecido": "Um costume foi esquecido.",
		"cultura": "A cultura de um povo mudou.", "lugar_nomeado": "Um lugar ganhou nome.",
		"tempestade": "Veio uma tempestade.", "inverno_rigoroso": "Veio um inverno duro.",
		"seca_inicio": "Começou uma seca.", "seca_fim": "A seca acabou.", "eclipse": "Houve um eclipse.",
		"cometa": "Passou um cometa.", "terremoto": "A terra tremeu.", "fartura_natural": "Veio uma fartura.",
		"os_ultimos": "Restam poucos.", "fim_do_mundo": "Não resta ninguém.", "linhagem": "A linhagem passou adiante.",
		"prece_atendida": "Uma prece foi atendida.", "prece_sem_resposta": "Uma prece ficou sem resposta."}.get(
		tipo, "Algo aconteceu.")


# --- desenho -------------------------------------------------------------------

## Caixa em 9 partes: os cantos ficam fixos, as bordas e o miolo repetem.
## `alvo` é onde desenhar (outro nó, como a estante), se não for a própria alça.
func _desenhar_9(tex: Texture2D, r: Rect2, m: int, alvo: CanvasItem = null) -> void:
	if alvo == null:
		alvo = self
	var t := tex.get_size()
	var xs := [0.0, m, t.x - m, t.x]
	var ys := [0.0, m, t.y - m, t.y]
	var dx := [r.position.x, r.position.x + m, r.end.x - m, r.end.x]
	var dy := [r.position.y, r.position.y + m, r.end.y - m, r.end.y]
	for j in 3:
		for i in 3:
			var sw: float = xs[i + 1] - xs[i]
			var sh: float = ys[j + 1] - ys[j]
			var y: float = dy[j]
			while y < dy[j + 1]:
				var h := minf(sh, dy[j + 1] - y)
				var x: float = dx[i]
				while x < dx[i + 1]:
					var w := minf(sw, dx[i + 1] - x)
					alvo.draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(xs[i], ys[j], w, h))
					x += sw
				y += sh


func _draw() -> void:
	var na_faixa := Rect2()
	_desenhar_9(_alca, Rect2(0, 0, largura(), ALTURA_ALCA), 4)
	for y in [5, 8, 11]:  # pega de arraste
		for x in [3, 6]:
			draw_rect(Rect2(x, y, 2, 1), Arte.paleta[12])
	for b in botoes:
		var q := 2 if b.selecionado else (1 if b.id == _sob_cursor else 0)
		draw_texture_rect_region(_botao, Rect2(b.rect), Rect2(q * BOTAO, 0, BOTAO, BOTAO))
		draw_texture(_icones[b.icone], Vector2(b.rect.position) + Vector2(2, 2))
	if _carregando:
		# caixa escura junto ao cursor com o ícone do poder e a carga
		var tela: Vector2 = vista.para_tela(_carga_ponto) + Vector2(0, ALTURA_ALCA)
		var carga := intensidade()
		var grau := _grau_da_carga(carga)
		var fonte_grau: Font = _fontes["dourada" if grau != "sinal" else "clara"]
		var largura := maxf(46.0, fonte_grau.get_string_size(NOME_CARGA[grau], HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x + 7.0)
		var r := Rect2((tela + Vector2(-largura / 2.0, -30)).round(), Vector2(largura, 22))
		r.position.y = maxf(r.position.y, ALTURA_ALCA + 1)
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), r, 4)
		draw_texture(_icones[poder + "_8"], r.position + Vector2(2, 2))
		var n := int(carga * 30.0)
		for i in 30:
			var cor: Color = Arte.paleta[COR_GRAU[grau] if i < n else 3]
			draw_rect(Rect2(r.position.x + 12 + i, r.position.y + 5, 1, 2), cor)
		# as marcas: o milagre na metade; no fogo, o fim do fogo brando
		draw_rect(Rect2(r.position.x + 12 + 15, r.position.y + 3, 1, 6), Arte.paleta[31])
		if poder == "fogo":
			draw_rect(Rect2(r.position.x + 12 + roundi(Simulacao.Mundo.FOGO_BRANDO * 30.0), r.position.y + 4, 1, 4), Arte.paleta[21])
		draw_string(fonte_grau, r.position + Vector2(3, 19), NOME_CARGA[grau],
			HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
	var seguido := _cabeca_seguida()
	if seguido.x > -50:  # o bico sobre quem a câmera segue
		draw_texture(Arte.textura("interface/dica_ponteiro.png"), seguido + Vector2(-3, -5))
	var hora := _texto_relogio()
	if hora != "":
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), Rect2(RELOGIO), 4)
		var fonte_relogio: Font = _fontes["dourada" if vista.sim.tempo.get("noite", false) else "clara"]
		var w := fonte_relogio.get_string_size(hora, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x
		draw_string(fonte_relogio, Vector2(RELOGIO.position.x + roundi((RELOGIO.size.x - w) / 2.0), 12), hora, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
	var dica := _dica_atual()
	if dica != "" and not (_relogio < _mensagem_ate and _mensagem != ""):
		# a dica da primeira abertura: discreta, ao lado da alça, com a letra dourada
		var fd: Font = _fontes["dourada"]
		var wd := int(fd.get_string_size(dica, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		var rd := Rect2(largura() + 2, 2, wd + 10, 14)
		if rd.end.x > RELOGIO.position.x - 2:
			rd.position = Vector2(480 - rd.size.x, ALTURA_ALCA + 1)
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), rd, 4)
		draw_string(fd, rd.position + Vector2(5, 11), dica, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		if rd.position.y < ALTURA_ALCA:
			na_faixa = rd
	if _relogio < _mensagem_ate and _mensagem != "":
		var fonte: Font = _fontes["clara"]
		var w := int(fonte.get_string_size(_mensagem, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE).x)
		var r := Rect2(largura() + 2, 2, w + 10, 14)
		if r.end.x > RELOGIO.position.x - 2:
			r.position = Vector2(480 - r.size.x, ALTURA_ALCA + 1)
		_desenhar_9(Arte.textura("interface/caixa_dica_9s.png"), r, 4)
		draw_string(fonte, r.position + Vector2(5, 11), _mensagem, HORIZONTAL_ALIGNMENT_LEFT, -1, TAM_FONTE)
		if r.position.y < ALTURA_ALCA:
			na_faixa = r
	if poder == "cura" or not _sonhou.is_empty():
		var doentes := {}
		if poder == "cura":
			for p in vista.sim.pessoas:
				if p.get("doente", false):
					doentes[p["id"]] = true
		var em_casa := doentes.duplicate()  # quem está doente quase sempre está em casa: a cruz vai no telhado
		for f in vista.figuras:
			var topo: Vector2 = (vista.para_tela(Vector2(f.x + f.largura / 2.0, f.base - 15)) + Vector2(0, ALTURA_ALCA)).round()
			if doentes.has(f.id):  # a cura sara quem está doente; em quem está são, não faz nada
				_cruz(topo)
				em_casa.erase(f.id)
			elif _sonhou.has(f.id) and _relogio - float(_sonhou[f.id]) < 60.0:  # quem sonhou aprende a ideia
				_cruz(topo + Vector2(0, -float(int(_relogio * 2.0) % 2)), 29)  # uma estrelinha lilás, piscando de leve
		var casas := {}
		for id in em_casa:
			var cx: float = vista.sim.mundo.rotina().casa_de(id)
			if cx >= 0.0:
				casas[roundi(cx)] = casas.get(roundi(cx), 0) + 1
		for cx in casas:  # uma cruz por doente, lado a lado, sobre o telhado
			for k in casas[cx]:
				var topo_c: Vector2 = (vista.para_tela(Vector2(cx - 3.0 * (casas[cx] - 1) + 6.0 * k, vista.chao(cx) - 26))
					+ Vector2(0, ALTURA_ALCA)).round()
				_cruz(topo_c)
	if _dica.visible:  # uma seta dourada pequena sobre o fogo onde o gesto atende a prece
		for ax in _alvos_da_prece:
			if ax < 0.0:
				continue
			var base: Vector2 = (vista.para_tela(Vector2(ax, vista.chao(int(ax)) - 20)) + Vector2(0, ALTURA_ALCA)).round()
			var sobe := float(int(_relogio * 3.0) % 2)
			for k in 3:  # um V de 5 px, com contorno escuro
				draw_rect(Rect2(base + Vector2(-3 + k, k - 1 - sobe), Vector2(1, 2)), Arte.paleta[3])
				draw_rect(Rect2(base + Vector2(3 - k, k - 1 - sobe), Vector2(1, 2)), Arte.paleta[3])
				draw_rect(Rect2(base + Vector2(-2 + k, k - sobe), Vector2(1, 1)), Arte.paleta[22])
				draw_rect(Rect2(base + Vector2(2 - k, k - sobe), Vector2(1, 1)), Arte.paleta[22])
	if _dica.visible:  # um ponto dourado sobre a cabeça de quem o pensamento cita
		for f in vista.figuras:
			if f.id in _citados:
				var c: Vector2 = (vista.para_tela(Vector2(f.x + f.largura / 2.0, f.base - 14)) + Vector2(0, ALTURA_ALCA)).round()
				draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Arte.paleta[3])  # contorno escuro
				draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Arte.paleta[22])  # dourado
	if na_faixa != caixa_na_faixa:
		caixa_na_faixa = na_faixa
		largura_mudou.emit.call_deferred()  # a moldura refaz a região da janela

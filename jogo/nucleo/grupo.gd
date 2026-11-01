extends RefCounted
## Um grupo de pessoas que vive junto: o embrião de uma vila e de uma cultura.

var id: int = 0
var nome: String = ""
var zona: String = ""
var membros: Array = []         # ids de pessoas vivas
var lider: int = -1
var sacerdote: int = -1
var fundador: int = -1
var estoque: float = 0.0
var abrigos: int = 0
var estagio: int = 1            # 1 coleta, 2 agricultura
var extinto: bool = false
var origem: Dictionary = {}     # {"pai", "causa", "ano", "evento"}
var cultura: Dictionary = {}    # sílabas para nomes
# religião
var tem_crenca: bool = false
var nome_deus: String = ""
var genero_deus: String = "m"
var deus_renomeado_ano: int = -100
var misterio: float = 0.0
var crencas: Array = []         # chaves de crença
var preces: Dictionary = {}     # necessidade -> {"evento", "dia", "autor", "alvo"}
var silencios: int = 0
var ceticos: bool = false
# cultura e memória
var costumes: Array = []        # {"tipo", "ano", "evento", "esquecido"}
var violencia: float = 0.3
var hostilidade: Dictionary = {}  # id de grupo -> valor
var tregua_ate: Dictionary = {}   # id de grupo -> dia absoluto
var proibido: Dictionary = {}     # id de grupo -> true (édito do sacerdote)
# estados
var fome_dias: int = 0
var em_fome: bool = false
var fome_evento: int = -1
var fome_mortos: int = 0
var fome_ultima_ano: int = -100
var doenca_evento: int = -1
var doenca_mortos: int = 0
var frio_mortos: int = 0
var amaldicoada: bool = false     # a zona atual foi lida como maldita
var nascimentos: int = 0
var estranhos: float = 0.0       # relação com estranhos: -1 desconfiada, 1 acolhedora
var mortos: String = ""          # o que se faz com os mortos: enterram, queimam, veneram
var atendidas_seguidas: int = 0  # preces atendidas sem nenhum silêncio no meio
var dependente: bool = false     # deixou de se preparar: o deus sempre dá
var exigente: bool = false       # passou a pedir coisas pequenas
var ultimo_ataque_sofrido: int = -1000


func tem_costume(tipo: String) -> bool:
	for c in costumes:
		if c["tipo"] == tipo:
			return true
	return false


func tem_crenca_chave(chave: String) -> bool:
	return crencas.has(chave)

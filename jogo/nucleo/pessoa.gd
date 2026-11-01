extends RefCounted
## Um habitante. Só dados: as regras ficam no mundo.

var id: int = 0
var nome: String = ""
var sexo: String = "m"          # "m" ou "f"
var nasc_ano: int = 0
var pai: int = -1
var mae: int = -1
var conjuge: int = -1
var filhos: Array = []
var grupo: int = -1
var tracos: Array = []          # dois traços
var memoria: Array = []         # ids de eventos vividos
var saude: float = 1.0          # 0 = morte
var fe: float = 0.0             # relação pessoal com o deus, -1..1
var sabe_agricultura: bool = false
var saberes: Array = []          # estágios 3 a 6: "pedra", "metal", "escrita", "engenharia"
var rancores: Dictionary = {}   # id de pessoa -> intensidade
var vivo: bool = true
var morte_ano: int = -1
var causa_morte: String = ""
var gravidez: int = -1          # dias até o parto, -1 se não está grávida
var doente: int = 0             # dias restantes de doença
var ferida_pelo_deus: bool = false   # a família perdeu alguém para o deus
var feitos: int = 0             # quanto a pessoa importa para a crônica
var veio_de: int = -1           # grupo de onde veio ao casar

const MEMORIA_MAX := 40


func tem(traco: String) -> bool:
	return tracos.has(traco)


func lembrar(evento_id: int) -> void:
	memoria.append(evento_id)
	if memoria.size() > MEMORIA_MAX:
		memoria.pop_front()


func idade(ano_atual: int) -> int:
	return ano_atual - nasc_ano


## Preenche a partir de uma linha do mundo salvo, sem set() por nome (rápido com dezenas
## de milhares de linhas): ix[k] é a coluna do campo CAMPOS[k] na linha, ou -1 se o
## arquivo não tem esse campo (fica o valor padrão).
const CAMPOS := ["id", "nome", "sexo", "nasc_ano", "pai", "mae", "conjuge", "filhos", "grupo", "tracos", "memoria", "saude", "fe", "sabe_agricultura", "saberes", "rancores", "vivo", "morte_ano", "causa_morte", "gravidez", "doente", "ferida_pelo_deus", "feitos", "veio_de"]


func de_linha(l: Array, ix: PackedInt32Array) -> void:
	if ix[0] >= 0:
		id = l[ix[0]]
	if ix[1] >= 0:
		nome = l[ix[1]]
	if ix[2] >= 0:
		sexo = l[ix[2]]
	if ix[3] >= 0:
		nasc_ano = l[ix[3]]
	if ix[4] >= 0:
		pai = l[ix[4]]
	if ix[5] >= 0:
		mae = l[ix[5]]
	if ix[6] >= 0:
		conjuge = l[ix[6]]
	if ix[7] >= 0:
		filhos = l[ix[7]]
	if ix[8] >= 0:
		grupo = l[ix[8]]
	if ix[9] >= 0:
		tracos = l[ix[9]]
	if ix[10] >= 0:
		memoria = l[ix[10]]
	if ix[11] >= 0:
		saude = l[ix[11]]
	if ix[12] >= 0:
		fe = l[ix[12]]
	if ix[13] >= 0:
		sabe_agricultura = l[ix[13]]
	if ix[14] >= 0:
		saberes = l[ix[14]]
	if ix[15] >= 0:
		rancores = l[ix[15]]
	if ix[16] >= 0:
		vivo = l[ix[16]]
	if ix[17] >= 0:
		morte_ano = l[ix[17]]
	if ix[18] >= 0:
		causa_morte = l[ix[18]]
	if ix[19] >= 0:
		gravidez = l[ix[19]]
	if ix[20] >= 0:
		doente = l[ix[20]]
	if ix[21] >= 0:
		ferida_pelo_deus = l[ix[21]]
	if ix[22] >= 0:
		feitos = l[ix[22]]
	if ix[23] >= 0:
		veio_de = l[ix[23]]

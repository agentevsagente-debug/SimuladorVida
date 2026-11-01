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

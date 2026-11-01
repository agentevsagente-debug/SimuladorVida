extends RefCounted
## Evento estruturado. Tudo o que é significativo no mundo vira um evento,
## e a crônica, a memória e as preces só leem eventos.

var id: int = 0
var tipo: String = ""
var ano: int = 0
var dia: int = 0          # dia do ano, 0..39
var hora: int = 0
var zona: String = ""
var grupo: int = -1       # grupo principal envolvido
var outro_grupo: int = -1
var participantes: Array = []   # ids de pessoas
var causa: String = "natural"   # natural, social ou divina
var importancia: int = 0        # 0..10
var dados: Dictionary = {}


func para_dict() -> Dictionary:
	return {
		"id": id, "tipo": tipo, "ano": ano, "dia": dia + 1, "hora": hora,
		"zona": zona, "grupo": grupo, "outro_grupo": outro_grupo,
		"participantes": participantes, "causa": causa,
		"importancia": importancia, "dados": dados,
	}


## Preenche a partir de uma linha do mundo salvo, sem set() por nome (rápido com dezenas
## de milhares de linhas): ix[k] é a coluna do campo CAMPOS[k] na linha, ou -1 se o
## arquivo não tem esse campo (fica o valor padrão).
const CAMPOS := ["id", "tipo", "ano", "dia", "hora", "zona", "grupo", "outro_grupo", "participantes", "causa", "importancia", "dados"]


func de_linha(l: Array, ix: PackedInt32Array) -> void:
	if ix[0] >= 0:
		id = l[ix[0]]
	if ix[1] >= 0:
		tipo = l[ix[1]]
	if ix[2] >= 0:
		ano = l[ix[2]]
	if ix[3] >= 0:
		dia = l[ix[3]]
	if ix[4] >= 0:
		hora = l[ix[4]]
	if ix[5] >= 0:
		zona = l[ix[5]]
	if ix[6] >= 0:
		grupo = l[ix[6]]
	if ix[7] >= 0:
		outro_grupo = l[ix[7]]
	if ix[8] >= 0:
		participantes = l[ix[8]]
	if ix[9] >= 0:
		causa = l[ix[9]]
	if ix[10] >= 0:
		importancia = l[ix[10]]
	if ix[11] >= 0:
		dados = l[ix[11]]

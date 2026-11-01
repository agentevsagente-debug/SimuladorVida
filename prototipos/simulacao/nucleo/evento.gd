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

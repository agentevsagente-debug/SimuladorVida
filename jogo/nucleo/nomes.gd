extends RefCounted
## Nomes de pessoas e grupos a partir de sílabas por cultura.
## Uma cultura nova herda as sílabas da cultura mãe e troca algumas,
## então povos aparentados têm sonoridade parecida, mas não igual.

const SILABAS_TODAS := ["ar", "dem", "to", "ril", "ma", "na", "ki", "lo", "be", "su",
	"ta", "ra", "mi", "do", "en", "ul", "ga", "vi", "sa", "or", "te", "bu", "ze", "ko",
	"li", "fa", "nu", "go", "ve", "ha", "ju", "pe", "mo", "da", "ni", "ru", "ka", "sel",
	"tam", "ber", "yo", "wa", "is", "ob", "kur", "lin", "mar", "tor", "es", "ib"]
const FINS_M := ["o", "em", "an", "ur", "ik", "os", "el", "on", "ar", "ut", "im", "or"]
const FINS_F := ["a", "ia", "na", "ra", "e", "il", "is", "ena", "ali", "u", "ya", "ela"]
const FINS_GRUPO := ["em", "il", "an", "or", "ur", "ak", "um", "es", "ar", "on"]


static func cultura_inicial(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"silabas": _amostra(SILABAS_TODAS, 10, rng),
		"fins_m": _amostra(FINS_M, 4, rng),
		"fins_f": _amostra(FINS_F, 4, rng),
	}


## Cultura derivada: mantém a maior parte das sílabas e troca algumas.
static func cultura_derivada(mae: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var sil: Array = mae["silabas"].duplicate()
	for i in 4:
		sil[rng.randi_range(0, sil.size() - 1)] = SILABAS_TODAS[rng.randi_range(0, SILABAS_TODAS.size() - 1)]
	var fm: Array = mae["fins_m"].duplicate()
	fm[rng.randi_range(0, fm.size() - 1)] = FINS_M[rng.randi_range(0, FINS_M.size() - 1)]
	var ff: Array = mae["fins_f"].duplicate()
	ff[rng.randi_range(0, ff.size() - 1)] = FINS_F[rng.randi_range(0, FINS_F.size() - 1)]
	return {"silabas": sil, "fins_m": fm, "fins_f": ff}


static func pessoa(cultura: Dictionary, sexo: String, rng: RandomNumberGenerator) -> String:
	var sil: Array = cultura["silabas"]
	var n := 1 if rng.randf() < 0.6 else 2
	var s := ""
	for i in n:
		s += sil[rng.randi_range(0, sil.size() - 1)]
	var fins: Array = cultura["fins_m"] if sexo == "m" else cultura["fins_f"]
	s = _juntar(s, fins[rng.randi_range(0, fins.size() - 1)])
	return s.substr(0, 1).to_upper() + s.substr(1)


static func grupo(cultura: Dictionary, rng: RandomNumberGenerator) -> String:
	var sil: Array = cultura["silabas"]
	var s: String = sil[rng.randi_range(0, sil.size() - 1)]
	s = _juntar(s, FINS_GRUPO[rng.randi_range(0, FINS_GRUPO.size() - 1)])
	if s.length() < 4:
		s = sil[rng.randi_range(0, sil.size() - 1)] + s
	return s.substr(0, 1).to_upper() + s.substr(1)


## Evita encontros feios de vogais iguais ("aa") e de três consoantes.
static func _juntar(a: String, b: String) -> String:
	if a.is_empty():
		return b
	var ult := a[a.length() - 1]
	var pri := b[0]
	if ult == pri:
		return a + b.substr(1)
	var vogais := "aeiouy"
	if vogais.find(ult) < 0 and vogais.find(pri) < 0:
		return a + b.substr(1) if b.length() > 1 else a
	return a + b


static func _amostra(origem: Array, n: int, rng: RandomNumberGenerator) -> Array:
	var copia: Array = origem.duplicate()
	var r: Array = []
	for i in n:
		var k := rng.randi_range(0, copia.size() - 1)
		r.append(copia[k])
		copia.remove_at(k)
	return r

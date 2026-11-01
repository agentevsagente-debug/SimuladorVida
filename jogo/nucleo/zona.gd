extends RefCounted
## Uma zona da região: praia, lago, floresta ou morro.

var chave: String = ""
var nome: String = ""           # substantivo comum: "praia", "lago"
var genero: String = "f"
var cabeca: String = ""         # início do nome próprio: "Praia", "Lago"
var comida: float = 0.0
var comida_cap: float = 0.0
var agua: float = 1.0           # 0..1
var agua_min_seca: float = 0.1
var madeira: float = 0.0
var madeira_cap: float = 0.0
var terra_cultivavel: int = 0
var risco_raio: float = 1.0
var seca: bool = false
var monte_erguido: bool = false
var pedra_x: float = -1.0      # onde a terra foi erguida
var queimada_ate: int = -1      # dia absoluto até quando a zona mostra o fogo
var nomes: Dictionary = {}      # id do grupo -> {"nome", "evento"}

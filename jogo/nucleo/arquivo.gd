extends RefCounted
## Gravação segura de arquivos, com cópias de segurança: usada pelo mundo salvo e pela estante.

## Quantas versões anteriores de um arquivo ficam guardadas (mundo.1.txt é a mais nova).
const COPIAS := 3


## O caminho da cópia `n` (1 a COPIAS) de um arquivo: user://mundo.txt -> user://mundo.1.txt.
static func copia(caminho: String, n: int) -> String:
	return "%s.%d.%s" % [caminho.get_basename(), n, caminho.get_extension()]


## Grava `texto` em `caminho` com segurança: primeiro num arquivo `.novo`; só se deu certo,
## as versões anteriores rodam (a 3 sai, a 2 vira 3, a 1 vira 2, a atual vira 1) e o novo
## toma o lugar. Um corte no meio não estraga nada.
## `conteudo` é um texto ou os bytes do arquivo.
static func gravar_com_copias(caminho: String, conteudo, copias: int = COPIAS) -> bool:
	var tmp := caminho + ".novo"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Não foi possível gravar " + tmp)
		return false
	var em_bytes: bool = conteudo is PackedByteArray
	if em_bytes:
		f.store_buffer(conteudo)
	else:
		f.store_string(conteudo)
	f.close()
	var confere: bool = FileAccess.get_file_as_bytes(tmp).size() == conteudo.size() if em_bytes \
		else FileAccess.get_file_as_string(tmp).length() == conteudo.length()
	if not confere:
		push_error("O arquivo gravado não confere: " + tmp)
		return false
	# Pelos caminhos absolutos, e não por DirAccess.open da pasta: com mais de 260 caracteres
	# (o limite do Windows), abrir a pasta falha, mas renomear e apagar pelo caminho funcionam.
	if copias > 0:
		if FileAccess.file_exists(copia(caminho, copias)):
			DirAccess.remove_absolute(_global(copia(caminho, copias)))
		for n in range(copias - 1, 0, -1):
			if FileAccess.file_exists(copia(caminho, n)):
				DirAccess.rename_absolute(_global(copia(caminho, n)), _global(copia(caminho, n + 1)))
		if FileAccess.file_exists(caminho):
			DirAccess.rename_absolute(_global(caminho), _global(copia(caminho, 1)))
	elif FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(_global(caminho))
	if DirAccess.rename_absolute(_global(tmp), _global(caminho)) != OK:
		# O mundo gravado ficou no .novo, que carregar() lê antes das cópias: nada se perde.
		push_error("Não foi possível trocar %s pelo arquivo novo" % caminho)
		return false
	return true


static func _global(caminho: String) -> String:
	return ProjectSettings.globalize_path(caminho)

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
	var dir := DirAccess.open(caminho.get_base_dir())
	if dir == null:
		return false
	if copias > 0:
		if FileAccess.file_exists(copia(caminho, copias)):
			dir.remove(copia(caminho, copias).get_file())
		for n in range(copias - 1, 0, -1):
			if FileAccess.file_exists(copia(caminho, n)):
				dir.rename(copia(caminho, n).get_file(), copia(caminho, n + 1).get_file())
		if FileAccess.file_exists(caminho):
			dir.rename(caminho.get_file(), copia(caminho, 1).get_file())
	elif FileAccess.file_exists(caminho):
		dir.remove(caminho.get_file())
	return dir.rename(tmp.get_file(), caminho.get_file()) == OK

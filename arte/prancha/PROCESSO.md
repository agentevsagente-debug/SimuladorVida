# Prancha de direção visual

Arte original rasterizada por código Python/Pillow, em 480 × 160 pixels. Rode `python arte/prancha/compor.py` para recriar as nove imagens; cada PNG também possui seu script homônimo. Requer `arte/gerador.py`, que contém a paleta T001 e o desenho dos habitantes.

As três versões compartilham geografia, câmera, sol/lua, sete habitantes (cinco adultos e duas crianças), duas cabanas, fogueira e floresta. Nenhuma imagem de referência foi copiada ou usada como entrada.

- A: céu pontilhado, colinas sobrepostas, névoa segmentada, pinheiros em silhueta, terreno contido e reflexo quente na água.
- B: copas arredondadas, vegetação clara, acentos amarelos, terra quente e cabanas com cobertura mais viva.
- C: pinheiros segmentados com luz nas bordas, textura mineral, contornos do próprio material e maior contraste entre detalhes.

Todas usam exatamente o conjunto permitido de `arte/paleta/paleta.hex`, sem ajustes. As versões noturnas mantêm a geografia e usam azuis, violetas e verdes escuros, com o núcleo da fogueira em amarelo e quase branco. As ampliações usam vizinho mais próximo, sem suavização. Não há pixels semitransparentes.

A escolha da direção cabe ao usuário e ao orquestrador. As peças T002–T005 foram entregues antes da inclusão desta tarefa na fila; devem ser revistas segundo a direção escolhida em novas tarefas, sem sobrescrever arte aprovada.

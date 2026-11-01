# Guia de estilo — pixel art

## O jogo em uma imagem

Um pequeno mundo visto **de lado**, como um diorama, dentro de uma moldura na área de trabalho. Em cima fica o céu, onde acontecem a chuva, os raios, os cometas e o ciclo de dia e noite. No meio, o chão com as vilas, as pessoas, as árvores e o morro. Embaixo, um pouco de terra, pedra e água. O tom é natural, terroso e acolhedor, mas o mundo pode ficar sombrio: fome, guerra, ruínas.

Referências de leitura: as **criaturas e vilas do WorldBox** (legibilidade em tamanho pequeno), o **clima acolhedor do Terraglass** e a **atmosfera em corte lateral de Kingdom Two Crowns**. Não copie nenhuma delas.

## Referência visual oficial

**A referência do jogo é a cena-alvo pintada pelo Claude:** `arte_claude/alvo/alvo_dia.png`, `alvo_entardecer.png` e `alvo_noite.png` (e as versões `_4x`). O usuário a escolheu numa comparação com a cena do Codex (`arte/alvo/`). **Toda peça nova precisa parecer ter saído dessa cena.** Em caso de dúvida, abra a versão 4x e copie o tratamento: margem orgânica da praia, montanhas com neve e sombras, subsolo com raízes e pedras, floresta densa e variada, e a luz da fogueira iluminando as pessoas à noite.

Toda a arte do jogo agora é feita por sessões do Claude, em `arte_claude/`. As peças modulares (terreno, habitantes, estágio 1) ficam em `arte_claude/pecas/`. O Codex foi desligado.

## Direção escolhida: C, Clássica 16 bits

Escolhida pelo usuário na prancha T001A. A cena-alvo do Claude, acima, já aplica esta direção com as correções abaixo.

**O que manter da direção C:**
- céu em degradê com pontilhado (dithering) e nuvens alongadas com sombra;
- montanhas em dois tons ao fundo, criando profundidade;
- pinheiros segmentados com luz nas bordas;
- textura mineral no terreno (pontos e grãos);
- contornos feitos com a cor mais escura do próprio material, nunca preto;
- reflexo do sol em traços horizontais na água.

**O que corrigir:**
- **Chão baixo:** a superfície fica por volta de 75% da altura da cena. Abaixo dela, camadas visíveis: grama, terra, terra escura com raízes e pedras, rocha. Nada de bloco liso ocupando metade da tela.
- **Pessoas mais definidas** dentro dos 8 × 12 pixels: cabeça com cabelo, rosto com um pixel de sombra, tronco com roupa sombreada, braços que se distinguem do corpo e pernas com dois tons. Elas precisam ser o elemento mais nítido da cena.
- **Mais variedade no estilo da vegetação:** pinheiros, árvores de copa larga, arbustos e capim, todos com o mesmo tratamento de luz nas bordas.
- **Perfil do terreno orgânico:** saliências, pedras afloradas e grama irregular na borda.
- **Luz da fogueira à noite:** ela ilumina o chão e as pessoas próximas com tons quentes. Na cena noturna, isso vale como referência para o efeito que o motor vai fazer.

**Efeitos do motor:** céu em degradê, reflexo na água, brilho do fogo, neblina, partículas e clima são feitos pelo jogo, por código. Não pinte esses efeitos nas peças avulsas (sprites, blocos). Pinte-os apenas nas cenas de teste e na prancha, para mostrar como o jogo vai ficar.

## Regras técnicas

| Regra | Valor |
|---|---|
| Formato | PNG com fundo transparente |
| Paleta | **somente** as 32 cores de `arte/paleta/paleta.hex` (depois que a T001 for aprovada) |
| Suavização | nenhuma: sem anti-aliasing, sem semitransparência (cada pixel é opaco ou totalmente transparente) |
| Bloco de terreno | 8 × 8 pixels |
| Habitante adulto | 8 × 12 pixels |
| Criança | 6 × 8 pixels |
| Construções | múltiplos de 8 (cabana 16 × 16, templo até 32 × 32) |
| Luz | vem de cima. Topos mais claros, bases mais escuras |
| Contorno | sem contorno preto. Use a cor mais escura do próprio material, só onde for necessário para separar do fundo |
| Texto | nenhum texto dentro da arte |

## Animações

- Folha de quadros **horizontal**, quadros do mesmo tamanho, da esquerda para a direita, sem espaço entre eles.
- Personagens olham **para a direita**. O jogo espelha para a esquerda.
- O nome do arquivo indica a quantidade de quadros: `habitante_andar_4q.png`.

## Legibilidade

- Toda peça precisa ser reconhecível em escala 1x. Teste olhando o PNG sem ampliar.
- A silhueta vem antes do detalhe: uma cabana precisa parecer cabana só pela forma.
- Pessoas precisam se destacar do chão e da vegetação. Use as cores de pele e de roupa, que são mais vivas que as do cenário.

## Culturas e variações

O jogo combina peças para criar variações por cultura (cor de roupa, cor de telhado, símbolo do templo). Para isso:
- a **roupa** dos habitantes usa só as cores do grupo "tecidos" da paleta, para que o jogo possa trocá-las;
- o **telhado** e as **paredes** das construções usam grupos de cor separados do resto da peça.

## Paleta (requisitos para a T001)

32 cores, distribuídas assim:

| Grupo | Quantidade | Uso |
|---|---|---|
| Céu de dia | 3 | do azul claro do horizonte ao azul do alto |
| Céu de noite | 3 | azuis profundos e violeta |
| Entardecer | 2 | laranja e rosa do pôr do sol |
| Terra e pedra | 5 | do marrom escuro ao cinza claro |
| Vegetação | 4 | do verde escuro ao verde claro, incluindo um tom seco |
| Água | 3 | escura, média e espuma |
| Fogo | 3 | vermelho, laranja e amarelo |
| Pele | 4 | quatro tons de pele humana diferentes |
| Tecidos | 3 | três cores vivas para roupas e símbolos de cultura |
| Neutros | 2 | quase preto (para sombras profundas) e quase branco (brilhos, raios) |

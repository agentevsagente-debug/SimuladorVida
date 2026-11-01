# Auditoria visual 3c: a interface

*Sessão C (arte), 01/11/2026. Feita sobre a main em `3a1b069`. O foco é o que ainda não tinha sido auditado: a alça e o seletor de poderes, a dica do cursor, a crônica, a estante, o relógio, os botões de velocidade, o mundo vazio, o criar povo e o abandono.*

## Como foi feito

Rodei o jogo com as opções que a B deixou para teste, como `--abrir=cronica` ou `estante`, `--dica=x,y`, `--demo` e `--extinguir`. Os comandos estão em `capturar3c.sh`, e as capturas, em `capturas3c/`.

- **1x:** cada captura é a janela inteira, com a alça, em 480 × 178.
- **2x:** é a mesma imagem ampliada sem suavização, que é o que a janela mostra na escala 2.
- **Mundo vazio:** o `--extinguir` não deixou o mundo vazio de forma estável nas minhas capturas. Para a tela do mundo vazio e para o aviso do fim, usei `fase2-vazio.png` e `fase2-fim.png`, que a B gravou.

Os recortes estão em `recortes3c/`. Para cada parte da interface, respondi a três perguntas:
- **1x / 2x:** dá para ler nas duas escalas?
- **Sem explicação:** quem nunca jogou entende?
- **Direção C:** combina com a direção escolhida?

## Avaliação de jogador

| Parte | 1x | 2x | Sem explicação | Direção C | Comentário |
|---|---|---|---|---|---|
| **Alça** | sim | sim | em parte | sim | A madeira escura e os botões azuis com borda dourada no selecionado ficam bem. Os ícones de velocidade (pausa, 1x, 10x, 50x e salto) se entendem de cara. O livro (crônica), a estante, a árvore de família e o "esconder" pedem a dica, que existe e é clara (`ok_relogio_e_dica.png`). |
| **Seletor dos 11 poderes** | sim | sim | em parte | sim | Aberto, ocupa 352 px. Os ícones são distintos (`ok_seletor_poderes.png`): chuva, raio, fogo, terra erguida, sonho, seca, dilúvio, terremoto, presságio e cura leem bem. O da fartura era um fiapo que sumia (**A3, corrigido**). Fechado, o botão mostra só o ícone do poder escolhido; quem chega não sabe que ali se escolhe o poder, mas a dica "Poderes" ajuda. O gesto de segurar para carregar só é explicado no aviso de primeira vez. |
| **Dica sobre pessoa** | sim | sim | sim | sim | Mostra o nome dourado, a idade e o temperamento, como "Suim, 29 anos / engenhoso, ambicioso" (`ok_dica_pessoa.png`). É a melhor parte da interface. Falta só o bico (B2). |
| **Dica sobre lugar** | sim | sim | em parte | sim | "A praia", "A floresta" e "O morro" leem bem. Mas sobre o acampamento ela diz "A floresta" e cobre o próprio acampamento (B1). |
| **Dica sobre sinal** | — | — | — | — | Não consegui pôr o cursor sobre um sinal de prece numa captura. Fica para a auditoria 4. |
| **Crônica** | sim | sim | em parte | sim | O pergaminho e a fonte escura são legíveis e bonitos. Ela abre já no fim, sem título e sem sinal de que há texto acima (B4). |
| **Estante** | sim | sim | sim | sim | As lombadas em pé e o "Fechar" e "Abandonar este mundo" se entendem. As lombadas de mundos diferentes trazem o mesmo nome (B5). |
| **Livro aberto** | sim | sim | sim | sim | O livro paginado, com números de página e fita, ficou com cara de livro. O título dourado quase some no pergaminho (**A2, corrigido na arte**). O "í" lia como "(" (**A1, corrigido**). |
| **Relógio** | sim | sim | em parte | sim | A hora é nítida. O dia, a estação e o ano só aparecem na dica ("Dia 3 do verão, ano 1"). |
| **Avisos na alça** | sim | sim | sim | sim | Mensagens curtas ao lado da alça, como "Passaram 5 dias. Nasceu alguém." e "Raio: um milagre sobre Suim" (`ok_aviso_salto.png`). Uma começa com minúscula (B8). |
| **Mundo vazio e criar povo** | sim | sim | sim | sim | As ruínas tomadas pelo mato, a alça reduzida e o aviso "Não resta ninguém" contam bem o fim. O título dourado do aviso some (A2). O botão de seguir a linhagem continua lá sem ninguém para seguir (B7). |
| **Abandonar** | sim | sim | sim | sim | A pergunta é clara ("Este povo não volta."). O botão que destrói e o que volta são iguais (B6). Depois de abandonar, o livro novo aparece na estante. |
| **Primeiros passos** | sim | sim | sim | sim | O texto explica o gesto e o esconder. O "í" lia como "(" (A1). |

**Impressão geral:** a interface está coerente com a cena, com madeira, pergaminho, azul-noite e dourado, e tudo lê em 1x. As dicas de pessoa e os avisos curtos são o que mais ajuda quem chega. O que mais atrapalha são duas coisas: dicas que tampam o que descrevem, e telas que não dizem o que são (a crônica sem título e a linhagem sem dizer quem segue).

## Defeitos de arte (sessão C), já corrigidos

### A1. O "í" lia como "(" (alto)
`recortes3c/A1_i_agudo_como_parentese.png` e `A1_A2_depois.png`

- **O que estava errado:** o acento de 3 px encostava na haste de 1 px do "i" sem pingo. O resultado era um gancho que lia como parêntese: "(cone", "fam(lia", "princ(pio". O defeito aparece em todo texto com "í".
- **Correção:** o "í" agora tem um acento de 2 px, uma linha acima, com 1 linha de folga até a haste. A mudança está em `interface/interface.py`. As 4 fontes e o atlas foram regenerados.

### A2. Título dourado no pergaminho (alto)
`recortes3c/A2_titulo_dourado_no_pergaminho.png` e `A2b_titulo_dourado_fim.png`

- **O que estava errado:** a `fonte_5x7_dourada` foi feita para o fundo escuro da dica. No pergaminho claro, "A Primeira Era" e "Não resta ninguém" quase somem.
- **Correção na arte:** fiz uma fonte nova, `fonte_5x7_titulo`, em vinho escuro (23). Tem as mesmas medidas e o mesmo `.fnt` das outras, e já está no atlas `comum` (`atlas/fonte_5x7_titulo.fnt`). A seção 6 do LEIA-ME diz onde usar cada cor.
- **Falta a B:** trocar a dourada pela titulo em todo título sobre o pergaminho. Isso inclui o título do livro aberto, o "Não resta ninguém" e qualquer título da crônica.

### A3. O ícone da fartura sumia em 1x (médio)
`recortes3c/A3_fartura_antes_depois.png`

- **O que estava errado:** era um fiapo de trigo de 1 px, em tons próximos do fundo da alça.
- **Correção:** agora é um feixe cheio de trigo, amarrado no meio, com um brilho, nos 12 × 12 e nos 8 × 8.

## Defeitos para a B

### B1. A dica de lugar no acampamento diz "A floresta" e cobre o que descreve (médio)
`recortes3c/B1_dica_acampamento_floresta.png`

- **O que está errado:** com o cursor sobre a fogueira e as cabanas, a dica diz "A floresta". A caixa aparece por cima do acampamento, escondendo as pessoas e a fogueira.
- **O que deveria ser:**
  - sobre o acampamento ou a vila, o nome do lugar ("O acampamento", ou o nome da vila);
  - a dica acima do cursor, com o bico apontando para baixo, sem cobrir o alvo, como já é na dica de pessoa.

### B2. A dica não usa o bico (baixo)
`recortes3c/B2_dica_sem_bico.png`

- **O que está errado:** a caixa aparece solta, uns 10 px acima de um grupo de pessoas, e não se sabe de qual delas ela fala.
- **O que deveria ser:** `interface/dica_ponteiro.png` (6 × 3) colado na borda de baixo, apontando para a cabeça da pessoa, como na amostra da interface.

### B3. "Seguir a linhagem" não diz quem é seguido (médio)
`recortes3c/B3_linhagem_sem_quem.png`

- **O que está errado:** a câmera se aproxima de alguém, mas nada na tela diz de quem se trata. Quem nunca jogou acha que a tela só deu zoom.
- **O que deveria ser:** um aviso na alça ao começar ("Seguindo Loa, 25 anos") e a dica fixa sobre a pessoa seguida, ou ao menos o bico apontando para ela.

### B4. A crônica abre no fim, sem título (médio)
`recortes3c/B4_cronica_abre_no_fim.png`

- **O que está errado:** a crônica abre com a última linha embaixo e o texto cortado em cima ("primeiro a rezar e o último a duvidar."). Não há título, e nada indica que dá para rolar.
- **O que deveria ser:**
  - um título no alto, como "Crônica do povo de …" ou o nome da era, com a `fonte_5x7_titulo`;
  - uma indicação de que há mais texto acima, como um ▲ pequeno na borda ou a frase cortada com reticências.

### B5. As lombadas da estante trazem o mesmo nome (baixo, a confirmar)
`recortes3c/B5_lombadas_iguais.png`

- **O que está errado:** as 3 lombadas dizem o mesmo ("ERA I"). Na estante, não dá para saber qual livro é qual.
- **O que deveria ser:** o nome de cada era ou de cada mundo na etiqueta, até 7 caracteres, com o motor abreviando, por exemplo "PRIMEIR", "SECA" ou "MUNDO 2". Se forem eras de mundos diferentes, o número do mundo ajuda.

### B6. Abandonar e Voltar são iguais (médio)
`recortes3c/B6_abandonar_botoes_iguais.png`

- **O que está errado:** o botão que destrói o mundo e o que cancela têm a mesma cor e o mesmo peso.
- **O que deveria ser:** "Voltar" como o padrão, com a borda dourada de selecionado. O "Abandonar" fica à direita e mais discreto, ou com o texto em vermelho (20).

### B7. A alça do mundo vazio mostra a linhagem (baixo)
`recortes3c/B7_alca_mundo_vazio.png`

- **O que está errado:** sem ninguém vivo, o botão de seguir a linhagem continua na alça.
- **O que deveria ser:** esconder o botão, como já se esconde o seletor de poderes. O ícone de criar povo, com um adulto e uma criança sob a estrela, ficou bom.

### B8. Uma mensagem começa com minúscula (baixo)
`recortes3c/B8_mensagem_minuscula.png`

- **O que está errado:** "só se cria um povo com o mundo vazio" começa com minúscula, enquanto todas as outras começam com maiúscula.
- **O que deveria ser:** maiúscula no começo. O texto vem do núcleo, então pode ser da A.

### Sugestões (não são defeitos)

- **Relógio:** mostrar a estação junto da hora, com um ícone de 8 × 8 (flor, sol, folha ou floco). Hoje ela só aparece na dica. Se a B quiser, a C desenha os 4 ícones.
- **Seletor fechado:** quando o jogador escolhe um poder, mostrar o nome dele no aviso por 1 s (por exemplo, "Fartura: segure sobre o mundo"). Isso ensinaria o gesto sem o aviso de primeira vez.
- **Carga do poder:** não consegui capturar o indicador de carga enquanto o botão está segurado (o `--demo` pula a carga). Fica para a auditoria 4.

## Resumo por responsável

| Quem | Itens |
|---|---|
| C (arte) | A1, A2 e A3: **corrigidos**, com as 4 fontes e o atlas regenerados (a A2 ainda depende de a B usar a `fonte_5x7_titulo`) |
| B (apresentação) | usar a `fonte_5x7_titulo` nos títulos sobre o pergaminho; B1 a B7; as sugestões, se quiser |
| A (simulação) | B8 (o texto da mensagem), se vier do núcleo; o nome do lugar no B1, se o lugar vier da simulação |

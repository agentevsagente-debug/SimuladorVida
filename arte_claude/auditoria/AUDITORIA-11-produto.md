# Auditoria 11: o jogo como produto (dá para mostrar?)

*Sessão C (arte), 01/11/2026. Feita sobre a main em `6c5f45a` e com o `.exe` gerado de novo (`builds/`, 110 MB).*

## Limites

- **A sessão do Windows continuava bloqueada:**
  - a primeira hora foi jogada com entrada injetada (auditoria 10, de hoje);
  - as partes desta auditoria foram capturadas pelo código-fonte, com as opções de teste (`--demo`, `--abrir`, `--livro-arquivo`, `--cenario-raro`, `--extinguir`, `--discreto`) e a entrada injetada no recomeço;
  - a leveza foi medida no `.exe`, com a tela bloqueada, o que pode baratear o desenho.
- **Ninguém de verdade usou o jogo com a mão nesta fase.** Ficaram sem teste:
  - a janela transparente sobre outros programas;
  - arrastar a janela e mudar a escala;
  - a bandeja e o Ctrl+Alt+H;
  - o cursor real.

Os comandos estão em `capturar11.sh`. Ficaram 33 capturas em `capturas11/` e os recortes em `recortes11/`.

## Notas

| Área | Nota | O que a sustenta | O que pesa |
|---|---|---|---|
| **Primeira hora** | **4** | Abre de manhã, com gente andando. As dicas andam em fila. O gesto do poder tem a carga e o grau. A crônica conta o que o jogador fez (auditoria 10). | A estante não diz o que é. A fartura e o sonho de dia são discretos (a arte nova ainda não está ligada). |
| **Cotidiano** | **4** | A caçada completa, a pesca, as brincadeiras, a madrugada com a coruja, a raposa e a vigia, e as ações de 1x (auditorias 4 a 6). O fim de tarde e a noite são nota 5. | A tarde das 12h às 15h30 ainda é a mais parada. A roda do entardecer vira uma fileira. |
| **Poderes** | **4** | Os 11 se leem de dia (`poderes_de_dia.png`): a chuva escurece o céu, o fogo brando desce sem queimar, o fogo forte queima e deixa as árvores mortas, a fartura brilha, a terra se ergue, a seca amarela o céu, o dilúvio alaga e o terremoto levanta poeira. A mensagem na alça diz o grau e sobre quem. | **O raio dura menos de 0,7 s e não deixa marca.** Depois do clarão, o chão fica igual, e só a alça diz que alguém foi atingido. O sonho e a cura de dia são discretos. |
| **Estágios** | **4** | Os estágios 3 a 6 se distinguem e as vilas têm profundidade: notas 4, 4, 4 e 5 (auditoria 9). | Os povos grandes ainda têm uma casa só no núcleo. O estágio 5 dura pouco em algumas sementes. |
| **Crônica e livros** | **4** | **É o que mais parece produto** (`cronica_estante_livros_e_fim.png`). A crônica viva tem índice e capítulos por estágio ("I. Os coletores"… "VI. Os canais e os moinhos"). Os livros trazem o título com epíteto, "Em resumo", "Quem foi quem", "O mundo no fim" e o epitáfio. O texto é bom. | O índice corta os títulos ("III. As casas de p…", "IV. O tempo do met…"). O livro fica à esquerda, com um quarto da tela vazio à direita. |
| **Fim do mundo** | **4** | O mundo vazio é contemplativo: as ruínas com o mato sem perder a forma (`recomeco.png`). No recomeço, o povo chega pelo morro, se junta, acende a primeira fogueira e só então ergue as cabanas, de manhã. O lugar guarda o nome do mundo anterior ("Floresta da Fome"). | Não vi a morte do último pela simulação: o `--extinguir=0` ainda mostra o povo nos primeiros segundos (o R4 da revisão do mundo vazio). |
| **Interface** | **4** | É coerente: madeira, pergaminho, azul-noite e dourado. Cada botão tem a dica com a tecla. A dica de pessoa traz o humor e o pensamento, e a de lugar, a memória. O modo discreto (D) troca o pior pela consequência (`eventos_raros_discreto_e_noite.png`). | O índice cortado e o espaço vazio do livro. A estante sem explicação. |
| **Leveza** | **4** | Com o mundo de 200 anos: visível em 1x, 15% de um núcleo; em 50x, 11%; **escondida, 0,1%**. Com o mundo novo, 5%. | A memória vai de 200 MB (mundo novo) a 300 MB (200 anos). O `.exe` tem 110 MB. É muito para um jogo de canto de tela, mas não impede. |

**Visão geral:** 4 em todas as áreas, sem nenhuma abaixo. Como peça (arte, crônica, livros, fim do mundo), já se mostra a amigos. O que falta é o que só se vê com gente de verdade usando.

## O que impede uma versão 0.1 para amigos

### Bloqueia

| # | Item | Por quê | Quem |
|---|---|---|---|
| B1 | **Uma passada com a mão, com a tela desbloqueada:** abrir o `.exe`, arrastar a janela, mudar a escala, esconder e trazer de volta pela bandeja e pelo Ctrl+Alt+H, deixar aberto por cima de outros programas por 1 hora, fechar e abrir. | Tudo isso foi testado só por dentro do jogo ou nem foi. Um amigo que esconda a janela e não consiga trazer de volta abandona na hora. | B (com o orquestrador) |
| B2 | **Uma página "como jogar" para quem recebe o `.exe`.** Ela deve dizer: o que é o jogo (um mundo que vive sozinho no canto da tela); o gesto do poder (escolher e segurar); as teclas (C, E, L, D, H e 0 a 3); como trazer a janela de volta; onde fica o mundo salvo e como começar de novo. Deve avisar também que o Windows pode mostrar o SmartScreen, porque o `.exe` não é assinado. | Sem ela, o amigo não sabe nem o que esperar, nem como apagar o mundo ou desinstalar. | B ou o orquestrador |
| B3 | **Um número de versão visível**, na dica do relógio ou na estante, e o caminho do `godot.log` na página do B2. | Para que os relatos dos amigos digam de qual versão falam, e para que um erro possa ser mandado. | B |

### Desejável (não impede)

| # | Item | Quem |
|---|---|---|
| D1 | o raio deixa o impacto por 1 a 2 s (`raio_impacto_4q` já existe) e uma marca queimada no chão por um tempo | B |
| D2 | ligar a arte pronta e não ligada: fartura e sonho de dia (`*_dia_*`), o chapéu de palha do estágio 6, fome e prece num sinal só, o profeta e a separação | B |
| D3 | o índice dos livros e da crônica sem cortar os títulos (mais largo, ou com quebra de linha), e o livro centrado | B |
| D4 | a estante, na primeira vez: "Aqui ficam as crônicas dos mundos que você deixar" | B |
| D5 | a guerra encenada no `--cenario-raro=batalha` (hoje só registrada) | A |
| D6 | as entradas da crônica do mesmo dia num parágrafo (o Q2 da auditoria 10) | A |
| D7 | conferir, pela simulação, a morte do último e a tela de "Não resta ninguém" | A e B |
| D8 | a memória abaixo de 200 MB, se der (por exemplo, os atlas de inverno só no inverno) | B |
| D9 | as casas pelo tamanho do povo no núcleo, e o estágio 5 com pelo menos 20 a 30 anos | A |

## A pasta de dados do usuário

- Fiz a cópia antes das medições do `.exe`. As capturas pelo código-fonte usam `--sem-config` e `--mundo-novo` e não tocam a pasta.
- No fim, o mundo salvo, a estante e os outros arquivos estavam iguais aos da cópia.
- **Um erro meu ao restaurar os registros:** o `godot.log` estava em uso por outro processo do Godot, e a troca da pasta `logs/` parou no meio. Eu apaguei a cópia sem conferir.
  - Perderam-se os 4 registros antigos do Godot (`logs/godot<data>.log`), que o próprio Godot recria e roda a cada execução.
  - O `godot.log` atual ficou.
  - O jogo, o mundo salvo e a configuração não foram afetados.

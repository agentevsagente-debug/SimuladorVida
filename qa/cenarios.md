# Matriz de cenários de QA

*Sessão D (QA), 01/11/2026. A fonte de verdade é `prompt-funcional-simulador-de-vida.md` (FUN), completada por `tecnico-simulador-de-vida.md` (TEC) e `jogo/nucleo/API.md` (API). Cada cenário cita a promessa de onde saiu.*

**Legenda**
- **Prioridade:** **B** = bloqueia a 0.1 (perda de dados, quebra visível ao jogador ou promessa central do documento); **N** = não bloqueia.
- **Como:**
  - **AN** = automático, núcleo sem tela (`jogo/qa/rodar_qa.gd`);
  - **AJ** = automático, com o jogo em janela e as opções de teste (`qa/janela/`), sem mouse nem teclado reais;
  - **M** = manual: precisa de mão humana ou de liberação do orquestrador para usar mouse e teclado.
- O resultado de cada um está em `qa/RELATORIO-QA.md`.

## 1. Começo do mundo

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-001 | **Dado** nenhum mundo salvo, **quando** o mundo é criado, **então** a região já existe com morro, praia, lago e floresta. | FUN Começo | B | AN |
| QA-002 | **Dado** um mundo novo, **quando** ele começa, **então** a região está vazia e o primeiro gesto do jogador é criar o primeiro povo (com o mesmo poder do recomeço). | FUN Começo, Menor conjunto 1 | N | AN |
| QA-003 | **Dado** o primeiro povo, **então** é um grupo de cerca de 12 coletores, uma família estendida, no estágio 1, sem vila nem religião (nenhum `nome_deus`, nenhum altar ou templo). | FUN Começo | B | AN |
| QA-004 | **Dado** a mesma semente e os mesmos gestos, **quando** dois mundos rodam 30 anos, **então** a crônica, os eventos e o estado do sorteio são iguais. | TEC Determinismo | B | AN |
| QA-005 | **Dado** a mesma semente, **quando** um mundo é consultado a cada hora (pessoas, cenas, construções, preces, dica) e o outro nunca, **então** os dois seguem iguais: as consultas não mudam o mundo. | API Determinismo | B | AN |

## 2. Cotidiano

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-010 | **Dado** um mundo em qualquer hora, **então** ninguém fica dentro da água (x < 126), a não ser remando. | API Espaço | B | AN |
| QA-011 | **Dado** um povo, **então** cada pessoa tem exatamente dois traços da lista. | FUN Habitantes | N | AN |
| QA-012 | **Dado** um dia de jogo, **então** há gente acordada à noite e a vida muda de hora em hora (alguém muda de lugar). | FUN Atenção (ambiente) | N | AN (coberto por `testar_vida.gd`; aqui só a amostra) |
| QA-013 | **Dado** 50 anos sem deus, **então** o mundo gera sozinho necessidades e conflitos: alguma fome, doença ou seca, e algum nascimento e morte. | FUN Habitantes | B | AN |
| QA-014 | **Dado** um mundo de 100 anos, **então** algum lugar ganhou nome pelo que aconteceu ali (`nomes` de zona). | FUN Memória do mundo | N | AN |
| QA-015 | **Dado** a dica de uma pessoa acordada, **então** traz o que faz, o que pensa (até 60 caracteres) e o humor, e o pensamento nunca fala de quem joga. | FUN "O que a pessoa pensa" | N | AN |
| QA-016 | **Dado** o tempo, **então** um dia de jogo dura cerca de 45 minutos reais no ritmo normal, com cerca de 30 de dia e 15 de noite. | FUN Tempo, TEC Tempo | N | AN |
| QA-017 | **Dado** um ano, **então** tem 40 dias e 4 estações de 10 dias. | FUN Tempo | B | AN |
| QA-018 | **Dado** o jogo aberto, **quando** o jogador pede o salto, **então** o mundo avança até o próximo acontecimento de camada nota ou chamado. | FUN Tempo | N | AJ |
| QA-019 | **Dado** o jogo, **então** há o ritmo normal, 10x e 50x, e a pausa. | FUN Tempo | N | M |

## 3. Os 11 poderes e as 3 intensidades

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-020 | **Dado** um mundo no primeiro dia, **quando** cada um dos 11 poderes é usado, **então** todos funcionam (`ok`), sem desbloqueio. | FUN Poderes | B | AN |
| QA-021 | **Dado** um poder, **quando** usado com intensidade 0,2 (gesto curto), **então** o grau é "sinal"; com 0,5 ou mais, "milagre". | FUN Graus, API | B | AN |
| QA-022 | **Dado** o mesmo poder usado 3 vezes na mesma zona em até 3 dias, **então** o terceiro é "imposição". | FUN "O grau vem do uso" | N | AN |
| QA-023 | **Dado** o mesmo poder usado em zonas diferentes, ou com mais de 3 dias entre os usos, **então** não vira imposição. | API Grau | N | AN |
| QA-024 | **Dado** um poder com intensidade fora de 0..1 ou x fora do mundo, **então** não quebra: o valor é limitado e o gesto funciona. | robustez | N | AN |
| QA-025 | **Dado** um nome de poder que não existe, **então** `ok` é falso, com motivo. | robustez | N | AN |
| QA-026 | **Dado** cada poder, **quando** usado, **então** gera um evento com `x`, `grau` e `intensidade`, e a camada é nota ou chamado. | API Poderes | N | AN |
| QA-027 | **Dado** o raio de milagre sobre uma pessoa (x dela), **então** ela morre e a reação é lida (castigo, mártir ou azar). | FUN "Atingir uma pessoa" | B | AN |
| QA-028 | **Dado** o raio de sinal sobre uma pessoa, **então** ninguém morre. | API Raio | N | AN |
| QA-029 | **Dado** uma prece de frio, **quando** o fogo vem com intensidade abaixo de 0,35, **então** é fogo brando: aquece, não queima e atende a prece; com 0,35 ou mais, queima. | FUN "O fogo brando atende o frio" | N | AN |
| QA-030 | **Dado** a cura sobre um doente, **então** ele se levanta; a cura imposta cura todos os doentes do povo. | FUN Poderes, API | N | AN |
| QA-031 | **Dado** o presságio com intensidades 0,2, 0,5 e 0,9, **então** a forma é cometa, eclipse e luzes, e todos os povos o leem. | API Presságio | N | AN |
| QA-032 | **Dado** o sonho de milagre sobre alguém do estágio 1, **então** pode dar a ideia da agricultura ou uma visão; a ideia pode ser ignorada. | FUN "O deus pode inspirar" | N | AN |
| QA-033 | **Dado** o dilúvio de imposição, **então** alaga o mundo inteiro (o quase fim). | API Dilúvio | N | AN |
| QA-034 | **Dado** a terra erguida de milagre entre povos em guerra, **então** força trégua e nasce um lugar com nome. | FUN Erguer, API | N | AN |
| QA-035 | **Dado** um gesto bom repetido 4 vezes sobre o mesmo povo em um ano, **então** vira costume; na 6ª, a chuva vira dependência. | API Hábito | N | AN |
| QA-036 | **Dado** o jogo em janela, **quando** um poder é segurado, **então** a caixa mostra a carga e o grau que sairia ("sinal", "milagre", "brando"). | FUN "Gesto tátil" | B | AJ (`--carregar`) |
| QA-037 | **Dado** o modo de cada poder, **então** o efeito visual aparece na moldura para os 11. | FUN Poderes | B | M (coberto pela auditoria 11 da C) |

## 4. Preces e respostas

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-040 | **Dado** um povo que crê e passa fome, **então** surge uma prece de fome, aberta em `preces_abertas`, com texto, frase curta e os poderes que a atendem. | FUN Preces | B | AN |
| QA-041 | **Dado** uma prece aberta, **quando** o poder que a atende cai no povo (`x_povo`), **então** vem `prece_atendida` e a prece some. | FUN Preces, API | B | AN |
| QA-042 | **Dado** uma prece aberta, **quando** o deus não responde por 14 dias e a necessidade continua, **então** vem `prece_sem_resposta`. | FUN Silêncio a uma prece | B | AN |
| QA-043 | **Dado** uma prece de seca, **quando** o deus manda seca sobre o povo, **então** vem `prece_contrariada` e a fé de quem rezou cai. | API Prece contrariada | N | AN |
| QA-044 | **Dado** um povo que não crê ou é cético, **então** ele nunca aparece em `preces_abertas` (o ponto cego). | FUN Ponto cego | B | AN |
| QA-045 | **Dado** uma prece aberta, **então** ela continua visível até ser atendida ou perder importância: o jogo não pausa sozinho. | FUN "Os sinais esperam" | N | AN |
| QA-046 | **Dado** a necessidade que passa sozinha depois de uma prece, **então** vem `prece_atendida` com falso milagre, e a crônica sabe que foi acaso. | FUN Falso milagre | N | AN |
| QA-047 | **Dado** um povo que crê, **quando** o deus fica 50 anos calado, **então** a religião muda (silêncio explicado, fé que esfria, céticos ou secularização). | FUN Silêncio prolongado | N | AN |
| QA-048 | **Dado** uma prece de frio, **então** o fogo está entre os poderes que atendem, e é marcado como brando. | FUN Fogo brando | N | AN |

## 5. Religião, crença e nome do deus

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-050 | **Dado** o primeiro povo sem religião, **quando** o deus faz coisas inexplicáveis (milagres), **então** a crença nasce (`crenca`) e o povo dá um nome ao deus. | FUN Começo, Religião | B | AN |
| QA-051 | **Dado** dois povos vivos que creem, **então** o nome que dão ao deus é diferente, a não ser que um tenha saído do outro levando a fé. | FUN "Cada cultura dá um nome ao deus", API | N | AN |
| QA-052 | **Dado** um mundo longo, **então** os sacerdotes podem falar pelo deus (éditos) e a religião pode morrer (céticos, secularização). | FUN Sacerdotes, "A religião pode morrer" | N | AN |
| QA-053 | **Dado** um povo que deixou de rezar, **quando** vê algo inegável, **então** pode renascer a fé (`renascimento`). | FUN "O retorno do deus" | N | AN (só registra se ocorreu) |
| QA-054 | **Dado** a fé, **então** ela é de cada pessoa (valores diferentes entre pessoas do mesmo povo), sem medidor global. | FUN "A fé é de cada pessoa" | N | AN |

## 6. Culturas

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-060 | **Dado** um povo, **então** tem as 6 dimensões culturais, com valores das listas do documento. | FUN Seis dimensões | N | AN |
| QA-061 | **Dado** um mundo de 100 anos, **então** surgiu mais de um povo a partir do primeiro, e cada povo novo tem `origem` (pai, causa entre migração, briga e cisma, e ano). | FUN "As culturas se separam" | B | AN |
| QA-062 | **Dado** um povo nascido de outro, **então** a crônica registra de onde ele nasceu. | FUN "Árvore genealógica" | N | AN |
| QA-063 | **Dado** um povo com costume, **então** o costume tem origem num acontecimento (evento). | FUN "Cultura é memória que virou hábito" | N | AN |
| QA-064 | **Dado** dois povos, **então** têm aparência (parede, telhado, símbolo, roupa) e nomes de lugar próprios. | FUN "As diferenças aparecem na moldura" | N | AN |
| QA-065 | **Dado** um mundo de 200 anos, **então** as culturas mudam (eventos `cultura` ou `reforma`). | FUN "As culturas mudam" | N | AN |

## 7. Estágios 1 a 6 e regressão

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-070 | **Dado** um mundo sem deus, **então** o primeiro povo chega à agricultura em até 50 anos. | FUN Menor conjunto 2, API | B | AN |
| QA-071 | **Dado** um mundo de 250 anos, **então** o estágio de todo povo fica entre 1 e 6: o teto é a engenharia. | FUN "O teto é o estágio 6" | B | AN |
| QA-072 | **Dado** um povo no estágio 3 ou mais, **quando** morrem todos os que sabem o saber do estágio (sem escrita), **então** o povo regride um estágio (`regressao`). | FUN "O conhecimento vive nas pessoas" | N | AN |
| QA-073 | **Dado** um povo que chega à escrita, **então** tem a própria crônica. | FUN "A escrita gera a crônica do próprio povo" | N | AN |
| QA-074 | **Dado** o estágio de cada povo, **então** as construções seguem o estágio (forja no 4, arquivo no 5, moinho no 6). | FUN Progresso, API | N | AN |

## 8. Linhagem acompanhada

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-080 | **Dado** um mundo novo, **então** há uma pessoa acompanhada, viva. | FUN Vínculo | B | AN |
| QA-081 | **Dado** a pessoa acompanhada com filhos vivos, **quando** ela morre (pelo raio do deus, pela API pública), **então** o acompanhamento passa ao descendente vivo mais velho e vem o evento `linhagem`. | FUN "acompanha uma linhagem" | B | AN |
| QA-082 | **Dado** `acompanhar(id)` com alguém morto ou que não existe, **então** devolve falso e não muda nada. | API Linhagem | N | AN |
| QA-083 | **Dado** um mundo com acontecimentos recentes, **então** `sugestoes()` sugere quem vale acompanhar, com motivo, só gente viva. | FUN "O jogo sugere quem vale acompanhar" | N | AN |
| QA-084 | **Dado** o jogo em janela, **quando** o jogador clica numa pessoa sem poder escolhido, **então** passa a acompanhá-la. | FUN Sem possessão | N | M |

## 9. Ausência e teto de 1 ano

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-090 | **Dado** um mundo salvo, **quando** se volta 16 horas depois, **então** passam 512 passos (cerca de 20 dias). | FUN Ausência ("uma noite ≈ 20 dias") | B | AN |
| QA-091 | **Dado** 30 dias fora, **então** o mundo para no teto: 960 passos e `teto_atingido`. | FUN Ausência | B | AN |
| QA-092 | **Dado** exatamente um ano de jogo fora (960 × 112,5 s), **então** passam 960 passos e o teto conta como atingido. | FUN Ausência | N | AN |
| QA-093 | **Dado** o relógio do computador que voltou (o salvamento está "no futuro"), **quando** o jogo abre, **então** não anda o tempo para trás, não quebra e não avança nada. | robustez | B | AN |
| QA-094 | **Dado** uma ausência, **então** o relato é uma crônica do período, sem linhas vazias de modelo nem "nada aconteceu". | FUN "Ao voltar, o jogador recebe uma crônica" | B | AN |
| QA-095 | **Dado** 5 anos fora, **então** o mundo avança só 1 ano. | FUN Ausência | B | AN |
| QA-096 | **Dado** uma ausência, **então** um ano é avançado em poucos segundos. | TEC Tempo | N | AN |
| QA-097 | **Dado** um povo à beira do fim, **quando** o jogador fica fora, **então** a extinção pode acontecer durante a ausência, e os chamados e o relato contam isso. | FUN Fim do mundo | B | AN |
| QA-098 | **Dado** o jogo em janela, **quando** volta de uma ausência de 10 dias, **então** o resumo "Enquanto você esteve fora" abre sozinho. | FUN Ausência | B | AJ (`--simular-ausencia`) |

## 10. Persistência e saves corrompidos

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-100 | **Dado** um mundo, **quando** é salvo e carregado, **então** o estado é igual e ele segue igual, passo a passo, ao que nunca parou. | TEC Persistência | B | AN |
| QA-101 | **Dado** o arquivo salvo, **então** é texto legível e guarda a hora real do salvamento. | TEC Persistência | N | AN |
| QA-102 | **Dado** o `mundo.txt` cortado, vazio, com lixo, só com o cabeçalho ou binário, e uma cópia boa, **então** `carregar()` volta da cópia e diz de onde (`recuperado_de`), e o relato da ausência avisa. | API Cópias | B | AN |
| QA-103 | **Dado** o `mundo.txt` e as 3 cópias estragados, **então** `carregar()` devolve null sem quebrar. | API Cópias | B | AN |
| QA-104 | **Dado** um mundo salvo por uma versão mais nova do jogo (versão do arquivo desconhecida), **então** o jogo não perde esse mundo: não o sobrescreve sem avisar. | robustez | N | AN |
| QA-105 | **Dado** que nenhum mundo salvo pôde ser lido, **quando** o jogo cria um mundo novo e salva 4 vezes, **então** os arquivos antigos (que talvez uma versão futura leia) não são apagados sem aviso ao jogador. | robustez, perda de dados | N | AN + AJ |
| QA-106 | **Dado** só as cópias (sem `mundo.txt`), **então** `existe()` é verdadeiro e `carregar()` volta da cópia. | API | N | AN |
| QA-107 | **Dado** `salvar_async` em andamento, **quando** o mundo avança, **então** espera a gravação e o arquivo final é válido. | API Salvar sem travar | N | AN |
| QA-108 | **Dado** o índice da estante estragado, **então** a estante se refaz a partir dos livros, sem perder nenhum. | API Estante | B | AN |
| QA-109 | **Dado** um mundo com livro fechado, **quando** ele é salvo em qualquer caminho, **então** o livro vai para a estante que acompanha esse caminho (não para a estante do jogador quando o caminho é de teste). | testabilidade, isolamento | N | AN |
| QA-111 | **Dado** o mesmo arquivo salvo, **quando** é carregado 6 vezes e avançado do mesmo jeito, **então** o sorteio e a crônica são os mesmos nas 6 vezes. | TEC Determinismo, API Persistência | N | AN |
| QA-110 | **Dado** um mundo salvo com o arquivo dos antigos faltando, **então** o carregamento volta de uma cópia ou devolve null, sem quebrar. | API Antigos | N | AN |

## 11. Fim do mundo, mundo vazio, criar povo e ruínas

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-120 | **Dado** um povo, **quando** o deus usa só os poderes (sem truque), **então** é possível acabar com todos: a extinção é real. | FUN "A extinção é real", "liberdade total" | B | AN |
| QA-121 | **Dado** que restam 5 ou menos, **então** vem `os_ultimos`, de camada chamado. | FUN "Os últimos são um chamado" | B | AN |
| QA-122 | **Dado** que morre o último, **então** vem `fim_do_mundo`, e a crônica fecha como livro ("A Primeira Era"). | FUN Fim do mundo | B | AN |
| QA-123 | **Dado** o mundo vazio, **então** o tempo continua, as ruínas ficam e envelhecem, e os poderes devolvem `ok` falso. | FUN "O mundo fica vazio e continua vivo" | B | AN |
| QA-124 | **Dado** o mundo vazio, **quando** o jogador cria um povo, **então** começa a Segunda Era com 12 pessoas; num mundo habitado, criar povo é recusado. | FUN Criar um novo povo | B | AN |
| QA-125 | **Dado** um povo novo criado no lago, **então** ele nasce na praia. | API | N | AN |
| QA-126 | **Dado** o povo novo, **então** encontra as ruínas e as explica (`mito_ruinas`). | FUN "O novo povo encontra as ruínas" | N | AN |
| QA-127 | **Dado** ruínas de pedra em diante, **então** o povo novo pode aprender nelas (`ruinas_saber`). | FUN "Ruínas guardam conhecimento" | N | AN (só registra se ocorreu) |
| QA-128 | **Dado** o fim, **quando** o mundo é salvo e carregado, **então** continua vazio, com o livro e a era. | FUN Fim do mundo | B | AN |
| QA-129 | **Dado** o jogo em janela, **quando** todos morrem, **então** aparece "Não resta ninguém" e o botão vira criar povo. | FUN Fim do mundo | B | AJ (`--extinguir`) |
| QA-130 | **Dado** um dilúvio que poupa alguém, **então** o quase fim é possível. | FUN "Um quase fim" | N | AN |
| QA-131 | **Dado** que o último morre às 10h pelo raio do deus, **quando** passa 1 hora, **então** o mundo já está vazio (`fim_do_mundo`) e criar povo já funciona, sem esperar a meia-noite. | FUN "Criar um novo povo só com o mundo vazio" | B | AN |

## 12. Estante e abandono

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-140 | **Dado** um mundo vivo, **quando** o jogador o abandona, **então** a crônica fecha como livro, vai para a estante e o mundo salvo (com as cópias e os antigos) é apagado. | FUN Mundo abandonado | B | AN |
| QA-141 | **Dado** a estante com livros, **quando** outro mundo começa, **então** os livros continuam lá e podem ser lidos. | FUN "numa estante com as crônicas de todos os mundos" | B | AN |
| QA-142 | **Dado** um livro na estante cujo arquivo sumiu, **então** a cópia vale. | API Estante | N | AN |
| QA-143 | **Dado** o livro de uma extinção, **então** tem título com epíteto, "Em resumo", capítulos e epitáfio. | API Livro | N | AN |
| QA-144 | **Dado** dois abandonos seguidos, **então** a estante tem os dois livros, com ids diferentes. | FUN Estante | N | AN |
| QA-145 | **Dado** o jogo em janela, **quando** a estante abre, **então** os livros aparecem e podem ser lidos. | FUN Estante | N | AJ (`--abrir=estante`) |

## 13. Modo discreto

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-150 | **Dado** o modo discreto, **quando** acontece uma cena pesada, **então** a crônica registra igual: o núcleo não sabe do modo. | FUN "sempre as registra na crônica" | B | AN (o núcleo não tem o modo: a crônica é a mesma por construção) |
| QA-151 | **Dado** `--discreto` e o fogo de milagre, **então** a tela não mostra as chamas sobre as pessoas. | FUN Em público | N | AJ |
| QA-152 | **Dado** a tecla D, **então** o modo liga e desliga, e fica guardado. | FUN Em público | N | M |

## 14. Moldura (esconder, escala, passagem do mouse)

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-160 | **Dado** o jogo aberto, **então** a janela é sem borda, transparente e sempre por cima. | TEC Moldura | B | AJ (só o arranque e o log) + M |
| QA-161 | **Dado** a janela, **então** o mouse atravessa as áreas transparentes. | TEC Moldura | B | M |
| QA-162 | **Dado** a janela, **quando** o jogador muda a escala, **então** é sempre um inteiro (2x, 3x, 4x). | TEC Moldura | N | AJ (`--escala`) + M |
| QA-163 | **Dado** H ou Ctrl+Alt+H, **então** a moldura some na hora e volta pela bandeja ou pelo atalho. | FUN "esconder a moldura na hora" | B | M |
| QA-164 | **Dado** o jogo fechado normalmente, **então** sai sem falha (código de saída 0) e salva. | robustez (falha de segmentação conhecida) | B | AJ (10 aberturas) |
| QA-167 | **Dado** o jogo com o atalho global ligado (como no jogo de verdade), **quando** ele fecha pelo "Sair" ou pela mensagem da janela (Alt+F4), inclusive durante um salvamento em segundo plano, **então** sai com código 0, o log diz "threads encerradas", não há aviso de thread destruída e o PowerShell do atalho não fica órfão. Confirma a correção da B (c06e4d0). | robustez (falha de segmentação ao fechar) | B | AJ (`rodar_janela.ps1 -ComAtalho`) |
| QA-165 | **Dado** a janela arrastada e redimensionada, **quando** o jogo fecha e abre, **então** volta no mesmo lugar e escala. | FUN A moldura | N | M |
| QA-166 | **Dado** o jogo, **então** mostra um número de versão (auditoria 11, B3). | produto | B | AJ (busca no código) |

## 15. Leveza

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-170 | **Dado** o passo da simulação com a população máxima, **então** nenhum passo passa de 5 ms. | API Custo | N | AN (amostra; a regressão de A mede por inteiro) |
| QA-171 | **Dado** o jogo visível em 1x com um mundo novo, **então** a CPU fica abaixo de 8% de um núcleo. | orquestrador | B | AJ |
| QA-172 | **Dado** o jogo visível em 1x com um mundo de 200 anos, **então** a CPU fica abaixo de 8% de um núcleo. | orquestrador | N | AJ |
| QA-173 | **Dado** o jogo escondido, **então** a CPU fica perto de 0. | TEC Leveza | N | M (precisa esconder) |
| QA-174 | **Dado** o jogo, **então** desenha no máximo 30 quadros por segundo. | TEC Leveza | N | AJ (`project.godot`) |
| QA-175 | **Dado** o jogo, **então** a memória fica abaixo de 200 MB (meta do documento; o usuário aceitou passar no conjunto de trabalho). | TEC Leveza | N | AJ |
| QA-176 | **Dado** uma ausência de um ano no mundo grande, **então** leva poucos segundos. | TEC Tempo | N | AN |

## 16. Robustez da API e cenas (achados durante a leitura)

| ID | Dado / Quando / Então | Fonte | Prio | Como |
|---|---|---|---|---|
| QA-180 | **Dado** um ataque registrado às 8h (forçado no meio do dia), **quando** o mundo é consultado a cada hora, **então** a cena `guerra` começa às 10h, com a luta das 11h30 às 13h. | API `cenas_ativas` (guerra) | N | AN (TDD para A) |
| QA-181 | **Dado** o pacote exportado, **então** não leva os testes de QA (`qa/`). | produto | N | AN (lê `export_presets.cfg`) |
| QA-182 | **Dado** as ferramentas de teste do núcleo, **então** nenhuma apaga ou escreve na estante real do jogador. | perda de dados | B | AN (lê o código) |

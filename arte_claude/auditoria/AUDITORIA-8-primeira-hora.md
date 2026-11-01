# Auditoria 8: a primeira hora de quem nunca jogou

*Sessão C (arte), 01/11/2026. Feita sobre a main em `7db7e41`.*

> **Limite desta auditoria:**
> - A sessão do Windows estava bloqueada (o LogonUI estava ativo). Por isso, a captura da tela saiu preta e o mouse e o teclado de verdade não chegavam ao jogo.
> - Joguei injetando a entrada por dentro do Godot (`roteiro8_injetar_entrada.gd`), pelo mesmo caminho da entrada de verdade: passar o cursor, apertar, segurar e soltar, e as teclas C, L, E, Escape e H. Gravei as capturas pelo próprio jogo.
> - "O que confunde" está julgado pelo que a tela oferece: se há um sinal visível do que fazer. Não vi alguém de verdade se perder.
> - **Ficou de fora:**
>   - a janela transparente por cima dos outros programas;
>   - arrastar a janela e mudar a escala;
>   - o atalho Ctrl+Alt+H;
>   - o ícone na bandeja;
>   - o cursor de verdade na área de trabalho.
>
> Com a sessão desbloqueada, vale uma passada com a mão.

## Como foi feito

**A preparação:**
- Gerei o `.exe` com `--export-release "Windows"`. Ele ficou em `builds/` (110 MB, fora do git).
- Abri o `.exe` de verdade sem nenhuma opção, para ver a primeira abertura padrão (`capturas8/exe_primeira_abertura.png`). Ele abre em 3x, no canto de baixo à direita.
- As sessões com entrada injetada rodaram do código-fonte, porque o `.exe` não aceita o script.

**A pasta de dados do usuário:**
- Antes, fiz uma cópia inteira da pasta. A A e a B estavam rodando testes nela ao mesmo tempo, então não dava para movê-la.
- Ela já estava como a de quem nunca jogou: sem mundo salvo, sem `moldura.cfg` e com a estante vazia.
- Depois, apaguei só o que o jogo criou: `mundo.txt`, `mundo.1.txt`, `mundo.2.txt` e `moldura.cfg`.
- Conferi que os arquivos e as pastas ficaram iguais aos da cópia e apaguei a cópia.

**As 4 sessões:**

| Sessão | O que fiz | Duração |
|---|---|---|
| 1. Primeira abertura | Li as dicas. Passei o cursor nos 10 botões e no acampamento. Usei 4 poderes, cada um apertando, segurando e soltando: chuva por 2,2 s, fogo por 0,5 s (fraco), fartura por 1,5 s e sonho por 1,5 s. Segui a linhagem (L), li a crônica (C), passei por 10x, 50x e 1x, abri a estante (E) e fechei (Esc), escondi (H) e passei o cursor no relógio. Fechou e salvou normalmente. | 3 min 40 s |
| 2. Fechar e abrir de novo | Reabri o mesmo mundo, passei o cursor pela vila e li a crônica. | 35 s |
| 3. A dica de pessoa | Passei o cursor ao longo das pessoas, na altura delas. | 20 s |
| 4. Voltar depois de 8 horas | Abri com `--simular-ausencia=8`. | 20 s |

Ficaram 44 capturas em `capturas8/` (com o roteiro da sessão 1), e os recortes estão em `recortes8/` (`recortar8.py`).

## Nota da primeira hora: 3

| O que pesa | |
|---|---|
| **A favor** | A arte, as dicas dos botões, a chuva, o altar que o povo ergue, a dica de pessoa, seguir a linhagem e o dia em 50x. |
| **Contra** | O jogo abre à meia-noite, com todos dormindo. O fogo fraco queima. A crônica não registra o que o jogador fez. A fila de dicas para na segunda. |

Com o começo de manhã, o fogo brando e a crônica contando os milagres, seria 4.

## O que encanta

- **A cena.** Mesmo de noite, a praia, o lago, as montanhas e os vagalumes dão vontade de ficar olhando (`01_primeira_abertura_a_meia_noite.png`).
- **O gesto do poder.** Segurar mostra a caixinha com o ícone e a carga enchendo. Ao soltar, a resposta vem na hora: nuvens, chuva sobre o acampamento e "Chuva: um milagre" na alça (`03_chuva_carga_e_milagre.png`).
- **O mundo responde.** Logo depois dos milagres, o povo ergueu um altar de pedra junto ao fogo (`05_fartura_e_sonho.png`). É o melhor momento da hora: o jogador entende, sem ninguém dizer, que eles perceberam.
- **Seguir a linhagem.** A câmera aproxima em 2x e a alça diz "Seguindo Sali, 50 anos" (`06_seguir_a_linhagem.png`).
- **A dica de pessoa.** Por exemplo, "Obsael, 54 anos — desconfiado / Líder, parado na vila / 'O povo conta comigo'" (`10_reabrir_e_dica_de_pessoa.png`).
- **A dica de lugar.** Ela também guarda a memória: "O acampamento de Daon / a floresta / queimada, farta".
- **As dicas dos botões.** São claras e dizem a tecla: "Crônica (C)", "Seguir a linhagem (L)", "Esconder (H)" e "Ritmo 50x (3) / um dia dura 54 s" (`02_dicas_dos_botoes.png`).
- **Os ritmos.** Em 50x, a noite vira manhã em segundos (`08_ritmos_10x_e_50x.png`).
- **Reabrir.** O mundo volta igual, com as árvores queimadas e o altar no lugar.

## O que confunde

- **Abrir à meia-noite.** Os primeiros minutos são uma cena escura com uma única pessoa visível, a vigia; os outros dormem dentro das cabanas.
  - Em 1x, o dia nasce depois de uns 11 min. Quem abre o jogo pela primeira vez não sabe que há um povo ali.
  - A única pista é "Escolha um poder e segure sobre o mundo", e ainda não há o que olhar.
- **A fila de dicas para.** Depois do primeiro poder, a alça diz "Passe o cursor sobre as pessoas". De noite, não há pessoas desenhadas a não ser a vigia, então a dica fica ali para sempre.
  - As seguintes nunca aparecem: a crônica, o ritmo e "H esconde; o ícone fica na bandeja".
  - Na sessão 1, fiz tudo isso e a alça continuou dizendo "Passe o cursor sobre as pessoas" até o fim.
- **O alvo da pessoa é pequeno.** Passando o cursor ao longo do acampamento, só 1 de 40 posições pegou uma pessoa; nas outras, a dica do acampamento toma a frente.
- **"Fogo: um sinal".** Ninguém sabe o que é um "sinal" e o que é um "milagre". Os graus aparecem na alça, mas nada explica a diferença. Parece só uma palavra mais fraca.
- **A estante na primeira hora.** Ela ocupa a tela inteira com um livro só e mostra "Abandonar este mundo" bem à vista (`09_estante.png`). Para quem acabou de chegar, é um botão perigoso e sem contexto.

## O que não tem retorno visível

- **A crônica não registra o que o jogador fez** (`07_cronica_sem_os_milagres.png`).
  - Depois de 4 milagres no primeiro dia (chuva, fogo, fartura e sonho), a crônica continua com o texto de abertura e "Ano 1, dia 1: o ano ainda está em curso".
  - Ao voltar depois de 8 horas, ela abre sozinha: "Enquanto você esteve fora (10 dias): / Enquanto o deus esteve fora, nada de notável aconteceu", e continua sem os milagres.
  - O jogador procura o efeito do que fez e não acha.
- **A fartura e o sonho de noite.** Os brilhos são pequenos e escuros. Sem a mensagem na alça, não se saberia que algo aconteceu.
- **Esconder.** Com H, a janela some e o H não traz de volta, porque a janela escondida não recebe teclas. A dica da bandeja nunca foi mostrada, porque a fila parou. Não testei a bandeja nem o atalho global.

## Onde a vontade de continuar cai

1. **No primeiro minuto:** escuro, nada se mexe, e há só uma dica.
2. **Logo depois do fogo:** ele devia ser brando, mas queimou as árvores ao lado do acampamento (`04_fogo_fraco_queima.png`). O jogador se sente culpado sem ter querido.
3. **Ao abrir a crônica:** procura o que fez e acha "o ano ainda está em curso".

Do segundo dia em diante, com luz, gente andando, a dica de pessoa e o altar, a vontade volta.

## Defeitos, com o responsável

| # | Defeito | Gravidade | Quem |
|---|---|---|---|
| P1 | **O mundo novo começa à meia-noite.** Em 1x, são uns 11 min de escuro com quase ninguém à vista. O mundo novo deveria começar de manhã, por volta das 7h, com o povo saindo das cabanas. | alto | A (hora inicial do mundo novo) |
| P2 | **O fogo em intensidade baixa queima.** Com 0,18 de carga, "Fogo: um sinal" fez a chama grande da fogueira e deixou árvores queimadas ao lado. A decisão era fogo brando: acende e aquece, sem queimar. A arte já existe: `fogo_brando_descer_4q`, `fogo_brando_acender_4q` e `calor_brando_4q` (LEIA-ME, seção 4). | alto | A (efeito no núcleo) e B (usar a arte do fogo brando) |
| P3 | **A crônica não conta os milagres do ano em curso.** Ela só fecha o ano no fim. Os milagres do jogador deveriam entrar na hora, como uma linha do dia, por exemplo "Dia 1: choveu do céu limpo sobre o acampamento". | alto | A (cronista) |
| P4 | **A fila de dicas trava.** Ela para em "Passe o cursor sobre as pessoas" quando não há ninguém à vista (de noite). Sugestões: pular uma dica que não foi feita em 60 s e voltar a ela depois; ou marcar como feitas as que o jogador já fez fora da ordem. Na sessão 1, a crônica, o ritmo e o esconder foram feitos e nunca contaram. | alto | B |
| P5 | **"Enquanto você esteve fora (10 dias): / Enquanto o deus esteve fora, nada de notável aconteceu".** A frase se repete. Além disso, em 10 dias, o normal (nascimentos, colheita, a roça) poderia aparecer em 1 ou 2 linhas. | médio | A e B |
| P6 | **O alvo da pessoa é pequeno.** A dica do lugar toma a frente. A pessoa a até 3 px do cursor deveria ter prioridade sobre o lugar. | médio | B |
| P7 | **Esconder sem saber como voltar.** Na primeira vez, antes de esconder, a alça poderia avisar por 2 s: "Para voltar: o ícone na bandeja ou Ctrl+Alt+H". O H dentro do jogo não traz a janela de volta. | médio | B |
| P8 | **"Abandonar este mundo" à vista na estante desde a primeira hora.** Ele poderia aparecer só a partir do segundo livro, ou do segundo ano. | baixo | B |
| P9 | **"Sinal" e "milagre" sem explicação.** Uma linha na dica do poder ajudaria, por exemplo: "segure mais para um milagre". | baixo | B |
| P10 | **A fartura e o sonho quase não se veem de noite.** Os brilhos são pequenos, nas cores da noite. Dá para fazer um brilho maior e mais claro para a noite. | baixo | C (a fazer) |
| P11 | **"Líder, parado na vila" quando ainda é um acampamento.** Já visto na auditoria 6. | baixo | A |

## O que melhorou desde as auditorias anteriores

| Item | Situação |
|---|---|
| Dicas dos botões | a tecla e "um dia dura…" ajudam |
| Seguir a linhagem | "Seguindo Sali, 50 anos" (o B3 da 3c está resolvido) |
| Crônica | tem título e setas (B4) |
| Bico das dicas | a dica de lugar já usa "O acampamento de…" (B1 e B2) |

## Resumo por responsável

| Quem | Itens |
|---|---|
| A (simulação) | **P1** (começar de manhã), **P2** (fogo brando sem queimar), **P3** (milagres na crônica do ano em curso), P5, P11 |
| B (apresentação) | **P2** (a arte do fogo brando), **P4** (fila de dicas), P5, P6, P7, P8, P9 |
| C (arte) | P10 (os brilhos de noite da fartura e do sonho), se a A e a B quiserem |

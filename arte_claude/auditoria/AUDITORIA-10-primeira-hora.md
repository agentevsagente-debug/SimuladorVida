# Auditoria 10: a primeira hora, de novo

*Sessão C (arte), 01/11/2026. Feita sobre a main em `7c70435`, com o `.exe` gerado de novo (`builds/`, 18h04). Repete a auditoria 8 com o mesmo roteiro, para comparar. A meta era nota 4.*

> **O mesmo limite da auditoria 8:** a sessão do Windows continuava bloqueada (o LogonUI estava ativo). A entrada foi injetada por dentro do Godot (`roteiro8_injetar_entrada.gd`), pelo mesmo caminho da entrada de verdade. O `.exe` de verdade foi aberto só na primeira abertura (`capturas10/exe_primeira_abertura.png`). Continuam sem teste: a janela por cima de outros programas, arrastar a janela, mudar a escala, a bandeja, o Ctrl+Alt+H com o teclado de verdade e o cursor real.

## Como foi feito

**A pasta de dados do usuário:**
- Fiz uma cópia inteira antes.
- Havia um mundo salvo (`mundo.txt`), e ele estava na cópia. Tirei-o para o jogo abrir como para quem nunca jogou.
- No fim, apaguei o que o jogo criou (`mundo.txt`, `mundo.1.txt` e `moldura.cfg`) e devolvi o `mundo.txt` da cópia.
- Conferi que os arquivos, as pastas, o mundo salvo e a estante ficaram iguais aos da cópia, e apaguei a cópia.

**As sessões:**
1. **A primeira abertura**, com o mesmo roteiro da auditoria 8 (`capturas10/roteiro_sessao1.json`):
   - as dicas;
   - passar o cursor nos 10 botões e no acampamento;
   - 4 poderes: chuva (2,2 s), fogo curto (0,5 s), fartura e sonho;
   - seguir a linhagem, a crônica, 10x, 50x e 1x, a estante, esconder e o relógio.
2. **Reabrir** o mundo, passando o cursor ao longo das pessoas.
3. **Voltar depois de 8 horas** (`--simular-ausencia=8`).

Ficaram 27 capturas em `capturas10/`, e os recortes estão em `recortes10/` (`recortar10.py`).

## Nota da primeira hora: 4 (a auditoria 8 deu 3)

A meta foi atingida. Os 4 defeitos altos da auditoria 8 estão corrigidos, e o que sobra é polimento.

| Defeito da auditoria 8 | Agora |
|---|---|
| **P1** O mundo começava à meia-noite. | **Corrigido:** ele abre às 7h, com o céu do amanhecer, gente andando, o fogo aceso e o estandarte do povo (`01_primeira_abertura_de_manha.png`). O primeiro minuto já tem o que olhar. |
| **P2** O fogo fraco queimava. | **Corrigido:** "Fogo: um sinal" faz a luz morna descer sobre a fogueira e deixa o calor em volta, sem chama nem queimada (`03_fogo_brando_sem_queimar.png`). Na dica, uma pessoa sentada junto ao fogo pensa "Que calor gostoso". O jogador vê o efeito no povo. |
| **P3** A crônica não contava os milagres. | **Corrigido:** "Dia 1: As fogueiras da floresta se acenderam sozinhas, com uma chama que não queimava.", "Os galhos da floresta pesaram de tanto fruto, fora de época.", "Yokana sonhou com sementes enterradas, mas achou que era bobagem e esqueceu." (`04_cronica_com_os_milagres.png`). É o melhor momento da hora: o mundo escreveu o que o jogador fez. |
| **P4** A fila de dicas travava. | **Corrigido:** as dicas andam (o poder, a crônica, o ritmo e o esconder), sem parar em nenhuma (`02_chuva_e_dicas_em_fila.png`). |
| **P5** A ausência repetia a frase. | **Corrigido:** "Enquanto você esteve fora: 10 dias / Nesses dez dias, ninguém nasceu e ninguém morreu. Em Demor, o verão foi de frutas e peixe. / C abre a crônica inteira." |
| **P6** O alvo da pessoa era pequeno. | **Corrigido:** passando ao longo do povo, a dica de pessoa aparece bem mais vezes: "Dempeut, 55 anos — inquieto / Líder, sentado junto ao fogo", "Sagali, 23 anos — contente / Cozinhando no fogo / 'Yokana já anda para todo lado'" (`05_dica_de_pessoa_e_lugar.png`). |
| **P7** Esconder sem saber como voltar. | **Corrigido:** o aviso aparece 2 s antes de a janela sumir. Não deu para capturá-lo, porque a captura para quando a janela some; vi pelo registro. |
| **P8** "Abandonar este mundo" na primeira hora. | **Corrigido:** a estante do primeiro ano só tem "Fechar". |
| **P9** "Sinal" e "milagre" sem explicação. | **Corrigido:** a dica do botão diz "Segure mais para um milagre". |
| **P10** A fartura e o sonho de noite. | **Corrigido** com as versões noturnas. De dia, ver abaixo. |

## O que encanta

- **A manhã de abertura:** a primeira imagem do jogo agora é bonita e viva.
- **A chuva:** escurece o céu inteiro, e a mensagem "Chuva: um milagre" aparece.
- **O fogo brando** e a pessoa que sente o calor.
- **A crônica** contando, em frases de cronista, o que o jogador fez.
- **A volta depois de horas,** com um resumo curto e natural.
- **Seguir a linhagem** ("Seguindo Rae, 49 anos"), os ritmos e a dica de pessoa.

## O que falta para 5

| # | Item | Quem |
|---|---|---|
| Q1 | **A fartura e o sonho de dia ainda são discretos.** Sem a mensagem da alça, quase não se veem sobre o capim e a copa. As versões noturnas ficaram boas; de dia, a fartura poderia usar o brilho de 12 × 12 sobre as árvores frutíferas, e o sonho, uma espiral maior sobre quem sonha. | C (a fazer, se a B quiser) |
| Q2 | **As entradas da crônica do mesmo dia repetem "Dia 1:"** (três seguidas). Poderiam virar um parágrafo só ("No dia 1, as fogueiras… Os galhos… Yokana sonhou…"). E "o ano ainda está em curso" no fim é seco; poderia ser "O ano continua." | A |
| Q3 | **A estante com um livro só** ocupa a tela inteira, e não diz o que é. Na primeira vez, uma linha como "Aqui ficam as crônicas dos mundos que você deixar" ajudaria. | B |
| Q4 | **A roda em volta do fogo ao entardecer** vira uma fileira compacta de gente na frente das cabanas (`05_dica_de_pessoa_e_lugar.png`). É o mesmo V1 dos estágios, em pequeno. | B |

## Resumo por responsável

| Quem | Itens |
|---|---|
| A (simulação) | Q2 |
| B (apresentação) | Q3, Q4 |
| C (arte) | Q1, se for pedido |

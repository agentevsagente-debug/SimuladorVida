# Auditoria 12b: o primeiro minuto na versão 0.1.1

*Sessão C (arte), 01/11/2026. Feita sobre o `.exe` 0.1.1 da B (`3db5a8c`, em `fase0-moldura-e4e762/builds/`, 21h07), com a arte da acolhida ligada: o convite na clareira (V1), o cervo e a garça na beira do lago e os pássaros 3 vezes mais frequentes até o primeiro povo (V2).*

## Como foi feito

Abri o `.exe` de verdade duas vezes, com `--primeira-vez`, `--mundo-novo` e `--sem-config`, sem tocar em nada: 40 s com um quadro por segundo e 20 s com um quadro a cada meio segundo. A sessão do Windows continuava bloqueada, então ninguém clicou. O clique e o que vem depois já estão na auditoria 12. Com `--sem-config` e `--mundo-novo`, a pasta de dados do usuário não foi usada.

As capturas estão em `capturas12b/` e os recortes em `recortes12b/`.

## O que mudou no primeiro minuto

| O que | Auditoria 12 (0.1.0) | **0.1.1** |
|---|---|---|
| Onde clicar | só a dica na alça | **a dica na alça e o convite na clareira desde o primeiro quadro**: o anel de luz e a estrela pulsando no lugar onde o povo vai nascer |
| Primeiro ser vivo | uns 10 s (pássaros longe) | **uns 4 s**: a garça pescando na água rasa e o cervo bebendo na beira, junto dos juncos |
| Movimento até o clique | nuvens e o brilho do lago | os dois bichos em laço, os bandos de pássaros cruzando o céu e o convite respirando |
| Parece quebrado? | sim, nos 10 primeiros segundos | **não**: em nenhum momento a tela fica parada |

`recortes12b/primeiro_minuto_0_1_1.png` mostra os 25 primeiros segundos, e `garca_e_cervo_na_beira.png`, a beira do lago ampliada.

## Ressalvas (pequenas)

- **O cervo aparece pouco.** De manhã cedo, a beira do lago fica na sombra azul das montanhas, e o cervo castanho se confunde com o chão e os juncos. **A garça, branca, é o que pega o olho.** Duas saídas, se quiserem:
  - pôr o cervo um pouco mais à direita, sobre a areia clara da praia (para a B);
  - um contorno mais claro no lombo do cervo da manhã (para a C).

  Não impede.
- **O convite é discreto em 1x:** uma estrela pequena e um anel pontilhado. Ele cumpre o papel junto com a dica da alça. Ficar mais forte faria o mundo vazio parecer menos calmo, então eu deixaria assim.
- **Os quadros 0 e 1 do cervo** (olhar e baixar a cabeça) voltando a cada ciclo ficam bem: parece que ele levanta a cabeça para olhar em volta. Não precisa separar.

## Nota da primeira hora: 5

O que segurava a primeira hora em 4 na auditoria 12 eram os 10 primeiros segundos parados. Na 0.1.1, o mundo vazio tem vida em 4 s e mostra onde clicar sem depender da alça. O resto da hora (o clique, a chegada, a primeira fogueira, os poderes e a crônica) já estava no nível de 5.

| | Aud. 8 | Aud. 10 | Aud. 12 | **12b (0.1.1)** |
|---|---|---|---|---|
| Primeira hora | 3 | 4 | 4 | **5** |

A ressalva é a de sempre: o jogo ainda não foi jogado com a mão, com a tela desbloqueada (o B1 da auditoria 11).

## Conferido de novo na 0.1.1 da raiz (`builds/`, gerada da main `faa2432`)

*Sessão C (arte), 01/11/2026. O usuário estava usando o PC, então rodei em segundo plano:*
- *no segundo monitor, com `--sem-foco`;*
- *com `--primeira-vez`, `--mundo-novo` e `--sem-config`, sem o mouse real.*

*O `.exe` abriu sozinho por 60 s. Depois rodei o código-fonte (a mesma main) com a entrada injetada: passar o cursor sobre o mundo vazio e clicar. Fiz a cópia da pasta de dados antes e, no fim, copiei por cima, sem apagar nada; nenhum arquivo ficou diferente. As capturas estão em `capturas12c/`.*

| O que | Visto |
|---|---|
| A dica na alça | "Clique sobre o mundo para fazer nascer um povo", desde o primeiro quadro |
| O convite no chão | o anel e a estrela na clareira, desde o primeiro quadro, até o clique |
| **A dica junto do cursor (V4)** | **sobre o mundo vazio, a dica de lugar ganha "Clique para fazer nascer um povo aqui"** ("A floresta", "O morro"…). É o que faltava: o jogador lê a instrução onde está olhando (`recortes12b/dica_junto_do_cursor_e_clique.png`). |
| Os bichos | a garça e o cervo na beira do lago a partir de uns 4 s, e os bandos de pássaros cruzando |
| O clique | "Nasceu um povo novo: começa a primeira era."; o povo entra pelo morro, e a fogueira acende uns 10 s depois do clique |

**Nota da primeira hora: 5.** A meta foi confirmada na 0.1.1 que vai para os amigos. O primeiro minuto convida, tem vida e ensina o gesto dentro do mundo. A ressalva do cervo pouco visível na sombra da manhã continua, mas não pesa, porque a garça e a dica junto do cursor fazem o trabalho.

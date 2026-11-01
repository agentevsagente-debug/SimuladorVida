# Auditoria 12: a primeira hora com o mundo começando vazio

*Sessão C (arte), 01/11/2026. Feita sobre a main em `5f6e018`, com o `.exe` gerado de novo (20h42). O roteiro está em `AUDITORIA-12-roteiro.md`, e a comparação é com as auditorias 8 (nota 3) e 10 (nota 4).*

> **Limite:** a sessão do Windows continuava bloqueada.
> - A primeira abertura foi vista no `.exe` de verdade, com `--primeira-vez`, `--mundo-novo` e `--sem-config`.
> - A sessão 1 rodou pelo código-fonte, com a entrada injetada (`roteiro8_injetar_entrada.gd`), para comparar com a auditoria 10.
>
> **A pasta de dados do usuário:** fiz a cópia antes e, no fim, copiei por cima, sem apagar nada. Ela tem só arquivos a mais, das outras sessões e dos registros. Os testes não a usaram, por causa de `--sem-config` e `--mundo-novo`.

## Como foi feito

| Sessão | O que fiz |
|---|---|
| **Primeira abertura (`.exe`)** | Abri e deixei 40 s sem tocar em nada. |
| **Sessão 1** | 30 s só olhando. Depois, um clique no mundo para fazer nascer o povo. A partir daí, o roteiro da auditoria 10: as dicas dos botões, 4 poderes (chuva, fogo brando, fartura e sonho), seguir a linhagem, a crônica, os ritmos, a estante e esconder. |
| **Sessão 2 (semente 11)** | Com `--semente`, o mundo **abriu já com gente**, como antes. Isso deu, sem querer, a comparação lado a lado, na mesma hora. |

Ficaram 20 capturas em `capturas12/` e os recortes em `recortes12/`.

## Medidas

| O que | Tempo |
|---|---|
| A dica "Clique sobre o mundo para fazer nascer um povo" na alça | **desde o primeiro quadro** |
| Primeiro movimento de vida na tela, antes do clique | **uns 10 s** (um bando de pássaros); antes disso, só as nuvens e o brilho do lago |
| O povo à vista depois do clique | **1 a 3 s**: ele entra pelo morro, à direita |
| A primeira fogueira acesa | **uns 19 s** depois do clique |
| As cabanas de pé | **uns 27 s** depois do clique |
| O aviso | "Nasceu um povo novo: começa a **primeira** era." (correto) |

## Começar vazio é melhor ou pior que começar com gente?

**Melhor, mas só por pouco e com uma condição.** Pelo que se vê hoje, ainda há um risco nos primeiros 30 s.

**Por que é melhor:**
- **O primeiro gesto do jogador é um gesto de deus,** e não um teste de botão. Ele clica, e o povo nasce dele (`02_espera_e_clique.png`).
- **O jogador vê o povo nascer:** a chegada pelo morro, a roda, a primeira fogueira acesa e só depois as cabanas (`03_chegada_fogueira_cabanas.png`). Era o melhor momento do recomeço, e agora é o começo de todo mundo.
- **A manhã vazia é a imagem mais bonita do jogo:** o céu do amanhecer, as montanhas rosadas e o lago com o brilho do sol.
- **A crônica começa com o povo que o jogador fez,** e a do primeiro dia já conta os milagres num parágrafo só: "No dia 1, choveu sobre a floresta num dia sem nuvens. Um fogo manso desceu do céu e acendeu as fogueiras da floresta, sem queimar nada…" (`04_poderes_e_cronica.png`).

**Por que ainda é arriscado:**
- **Os 10 primeiros segundos estão parados.** Antes do clique, a tela não tem nenhum ser vivo e só a dica na alça diz o que fazer.
  - O convite dentro do mundo (`convite_povo_4q`, V1) ainda não foi ligado.
  - Os bichos da manhã (V2) não são garantidos: nos 30 s, só passaram uns pássaros.
  - Quem não lê a alça vê uma paisagem bonita e parada, e pode achar que o jogo não carregou.
- **Começar com gente** (`05_comparacao_comecando_com_gente.png`) tem vida desde o primeiro quadro: a vigia, o fogo e as crianças. Mas o jogador não sabe o que ele é ali, e o primeiro gesto (um poder) não tem o peso de criar.

**O veredito:**
- **Com o convite no chão e um bicho nos primeiros segundos, começar vazio é claramente melhor:** o mundo convida, o jogador age e o povo nasce dele.
- **Sem isso, é igual ou um pouco pior nos primeiros 10 s,** porque o jogo parece parado, e melhor depois do clique.

## Nota da primeira hora: 4

A mesma da auditoria 10, com outra forma.
- **O que subiu:** o gesto de criar, a chegada, a crônica em parágrafo e o aviso correto.
- **O que segura em 4:** os 10 s parados antes do clique.

**Para 5:**
- **V1 (B):** ligar o convite no chão da clareira.
- **V2 (B):** um cervo, uma garça ou um coelho nos primeiros 5 a 10 s, e os bandos de pássaros mais frequentes até o clique.
- **V4 (B):** a dica de criar povo também junto do cursor sobre o mundo.

O V3 (o aviso da primeira era) está corrigido.

## Comparação com as auditorias anteriores

| | Aud. 8 | Aud. 10 | **Aud. 12** |
|---|---|---|---|
| Abertura | meia-noite, quase ninguém | 7h, com gente | **7h, vazio, a dica desde o primeiro quadro** |
| Primeiro gesto | poder, com a dica travando | poder, com a dica em fila | **criar o povo**, e depois os poderes em fila |
| Momento mais forte | a chuva | a crônica contando os milagres | **o povo chegando e acendendo a primeira fogueira** |
| Crônica | sem os milagres | os milagres, um por linha | **os milagres num parágrafo do dia** |
| Nota | 3 | 4 | **4** (5 com o V1 e o V2) |

## Outros detalhes vistos

- **A crônica viva com um ano só:** o índice "Até agora" fica com uma linha e um pergaminho vazio ao lado do livro. Quando há só um capítulo, o índice pode sumir, ou o livro pode ficar centrado. Quem corrige: **B**.
- **`--semente` com `--mundo-novo` ainda abre com gente.** Pode ser de propósito, para os testes, mas vale saber que as capturas antigas e as novas com semente não mostram o começo vazio. Quem decide: **A** ou o orquestrador.
- **A bandeja** já escolhe o ícone de 24 px em 144 dpi (pelo registro). O item 2 da revisão dos 5 minutos está resolvido.

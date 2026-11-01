# Revisão do fim do mundo e do mundo vazio

*Sessão C (arte), 01/11/2026. Feita sobre a main em `136fbb2`. Um mundo da semente 3 no ano 140 (estágio 4), com todos mortos (`--extinguir`), visto logo depois e 5, 20 e 60 anos depois, de dia, ao entardecer, de noite e no inverno. Depois, o povo novo criado pelo botão, com a entrada injetada como na auditoria 8. Os comandos estão em `capturar_vazio.sh`, e os recortes, em `recortes_vazio/`.*

## A sensação

**É contemplativa, não de tela de erro** (`o_fim_e_os_anos.png`). Sem gente, sobram:
- o lago, as montanhas e o céu, que mudam com a hora;
- os vagalumes, os pássaros e a coruja;
- as ruínas com o mato subindo.

A alça fica só com o botão de criar povo, os ritmos, a crônica e a estante, e nada pisca nem cobra o jogador. De noite, sem uma única luz, é o momento mais silencioso do jogo, como deve ser.

O povo novo nasce com um aviso bonito ("Nasceu um povo novo: começa a segunda era."). A dica do lugar guarda a memória do mundo anterior ("A floresta / chamado Floresta do Raio").

## O que corrigi na arte

### R1. No grau 3, o mato virava moita e a ruína sumia (alto)
`mato_antes_depois_20_e_60_anos.png`, `mato_graus_antes.png` e `mato_graus_1_a_3_depois.png`

- **O que estava errado:**
  - Aos 20 anos, as ruínas da vila do estágio 4 viravam montes de folhagem. As trepadeiras subiam por 95% da altura, e o musgo cobria 70% dos topos.
  - Sem a silhueta das paredes, da cumeeira e das colunas, o jogador perdia o "aqui morou alguém", que é a melhor parte do mundo vazio.
- **Correção** (`natureza/natureza.py`):
  - as trepadeiras sobem até uns 3/4 da altura, e há menos delas;
  - as moitas da base são menores e mais raras;
  - o musgo cobre 40% dos topos.

  O alto das paredes, a cumeeira e as pedras continuam à mostra em todos os graus. As 18 ruínas foram regeneradas nos 3 graus.

### R2. O povo novo nasce com a fogueira já acesa (médio) — arte nova; falta a B
`o_povo_novo_chegando.png` e `pecas/acoes/amostra_recomeco_4x.png`

- **O que está errado:** o clique cria o povo, e no quadro seguinte o acampamento já está pronto, com as cabanas e o fogo aceso. Falta o momento do recomeço: a chegada e a primeira fogueira.
- **Arte nova** (`acoes/recomeco.py`, LEIA-ME seção 28):
  - `acoes/acender_fogo_4q`: alguém ajoelhado gira o pau sobre a tábua, sai a fumaça e ele sopra a brasa;
  - `estagio1/fogueira_nascendo_4q`: a lenha com a palha, a fumaça, a brasa, a chama pequena e a chama crescendo. Depois, a `fogueira_acesa_4q`.
- **Sugestão para a B:**
  1. o povo entra pela borda com `andar_trouxa_4q`, que já existe;
  2. alguém acende o fogo (uns 6 a 8 s em 1x), com os outros em volta;
  3. só então aparecem as cabanas.

## O que fica para a B e a A

| # | Item | Quem |
|---|---|---|
| R2 | a chegada e a primeira fogueira, com a arte nova | B |
| R3 | o botão de criar povo poderia pulsar devagar (2 quadros, a cada 3 s) no mundo vazio, para o jogador saber que é ali que recomeça, sem texto | B |
| R4 | com `--extinguir=0`, a tela ainda mostra o povo e a alça antiga no primeiro quadro; pode ser só o teste, mas vale conferir que, no jogo, a morte do último leva direto ao "Não resta ninguém" | B |

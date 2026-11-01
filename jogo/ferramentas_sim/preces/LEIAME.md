# Preces e chamados, vistos como jogador

*Sessão A (simulação), 01/11/2026.* Gerado por `ferramentas_sim/preces.gd`: 3 mundos (sementes 1, 2 e 3) de 50 anos, cada um em três modos.

- `calado`: o deus não faz nada.
- `atende`: dois dias depois de cada prece, o deus usa o poder que faz sentido, no povo que reza:
  - chuva na seca;
  - fartura na fome;
  - cura no doente;
  - terremoto no povo inimigo, na guerra.
- `contraria`: o deus faz o contrário, no povo que reza:
  - seca na seca e na fome;
  - raio na doença;
  - dilúvio no frio;
  - terremoto na guerra.

Para cada mundo, há dois arquivos aqui:
- `<modo>-semente-<n>.md`: as preces por década, os chamados por tipo, as respostas do deus e a reação de quem rezou no dia seguinte (memória, humor e pensamento da dica);
- `<modo>-semente-<n>-cronica.md`: a crônica dos 50 anos.

## 1. As preces

| Deus | Preces em 3 × 50 anos | Textos diferentes | Necessidades |
|---|---|---|---|
| calado | 71 | 31 | fome 21, seca 19, filho doente 16, guerra 10, frio 3, doença 2 |
| atende | 225 | 31 | banais 93, filho doente 55, fome 45, seca 16, doença 10, frio 6 |
| contraria | 49 | 8 | fome 23, seca 23, frio 1, doença 2 |

**São variadas?** Sim, e cada uma se liga a uma necessidade real do povo:
- seca na zona, fome, doença (com o nome do filho doente, quando há), inverno rigoroso sem abrigo para todos, um ataque recente;
- os pedidos pequenos ("que a caça seja gorda") só aparecem num povo que se acostumou a ser atendido.

O texto muda com o deus de cada povo e com o pedido:
- «Que Nega, não deixes nossos filhos morrerem de fome.»
- «Cura Beya, Que Nega. Ela é tão pequena.»
- «Que Nega, que Sagak caia da próxima vez.» (de quem atacou e perdeu)

Com o deus que atende, o povo fica dependente e depois exigente, e os pedidos pequenos dominam. O desenho já previa isso.

**Dá para atender ou recusar com um poder que faça sentido?** Agora, sim, em quase todas:

| Prece | Atendem (`atendem`) | Contrariam (`contrariam`) |
|---|---|---|
| seca | chuva | seca, fogo, dilúvio, terremoto |
| fome | fartura | seca, fogo, dilúvio, terremoto |
| doença | cura (no doente; sem alvo, só a cura repetida, que cura todos) | raio que mata alguém do povo, fogo, dilúvio, terremoto |
| guerra | raio ou terremoto **no povo inimigo** | os mesmos, no próprio povo |
| frio | nenhum | dilúvio, terremoto, fogo, raio |
| banal | nenhum | seca, fogo, dilúvio, terremoto, raio |

Nenhum poder atende o frio. Responder com o fogo seria contrariar a prece, porque o fogo queima comida e abrigos. Ver "Para decidir", no fim.

## 2. A reação do povo

| Deus | Desfechos olhados | Na memória de quem rezou | Pensa no desfecho no dia seguinte |
|---|---|---|---|
| calado | 53 atendidas pelo acaso, 16 sem resposta | 69 de 69 | 61 de 69 |
| atende | 96 atendidas pelo deus, 35 pelo acaso | 131 de 131 | 109 de 131 |
| contraria | 44 contrariadas, 2 atendidas pelo acaso | 46 de 46 | 25 de 46 |

Quando quem rezou não pensa na prece, está pensando numa necessidade urgente da mesma força: "Faz dias que ninguém come direito", depois de pedir comida e receber seca.

Exemplos de pensamento:
- **Atendida:**
  - Rabea, grata: "O Que Nega ouviu a nossa prece".
  - Loenu, grata: "Vou agradecer ao Que Nega hoje".
- **Sem resposta:**
  - Viu, aflita: "O Que Nega nos esqueceu".
  - Satora: "Por que o Que Nega não responde?".
- **Contrariada:**
  - Rabea, aflita: "Pedi comida, e veio o castigo".
  - Enim, revoltado: "O Olho Escuro fez o contrário do que pedimos".

Na crônica:
- «Makon tinha pedido chuva. Veio a seca, e em Koil perguntaram o que tinham feito de errado.»
- «Demya pediu a cura de Gaut, e veio o raio. Em Esar, ninguém mais rezou por doente.»
- «Pevik morreu mesmo assim, e Mavion nunca mais rezou.»

**O que estava errado e foi corrigido no núcleo:**
1. **Prece contrariada.** Antes, se o deus mandava seca a um povo que pedia comida, a fome depois passava sozinha e o povo agradecia: "O Que Nega ouviu a nossa prece". Agora:
   - o gesto que fere o povo que reza fecha as preces abertas com `prece_contrariada`, um evento por gesto e por povo;
   - a fé cai, o silêncio conta em dobro, e quem rezou fica ferido pelo deus;
   - aparece na crônica, na memória de quem rezou e na dica.
2. **Prece de guerra.**
   - O inimigo agora é o outro povo; antes, Zeor rezava «que Zeor não volte».
   - Quem atacou e perdeu pede vitória, não proteção.
   - Uma prece de guerra que reabre sem ataque novo também diz o nome do inimigo.
   - Um raio ou terremoto no inimigo atende a prece.
3. **Onde o gesto pega.** `preces_abertas()` agora traz `x_povo`, a fogueira do povo, dentro da zona dele. O `x` é onde está quem reza, e essa pessoa pode estar trabalhando em outra zona: um gesto ali não atinge o povo.
4. **Espera para rezar de novo.** Depois de uma prece sem resposta ou contrariada, o povo espera 10 dias para pedir a mesma coisa. Antes reabria no dia seguinte.
5. **Prece repetida.** A mesma necessidade, pelo mesmo povo, em menos de um ano, vira "nota", não "chamado". Numa década de guerra, as preces-chamado caíram de 25 para 12.
6. **O pensamento de quem rezou.** Nos 2 dias seguintes, o desfecho da própria prece passa à frente de tudo, inclusive da fome.

## 3. Os chamados

Em 3 mundos × 50 anos, com o deus calado:

| Chamado | Quantos | Um a cada, por mundo |
|---|---|---|
| prece (não repetida) | 57 | 2,6 anos |
| fome_inicio | 30 | 5 anos |
| doenca_inicio | 19 | 8 anos |
| morte (importância ≥ 8: líderes, fundadores, mortes marcantes) | 13 | 11,5 anos |
| ataque | 5 | 30 anos |
| profeta | 2 | 75 anos |
| crenca, agricultura, separacao, linhagem | 3 cada | um por mundo |

Em 1x, um ano de jogo dura uns 30 min, então são uns 2 a 4 chamados por hora de tela. Não cansam. O risco é o contrário: passarem batidos, ou se misturarem.

- **Fome e prece andam juntas.** Quase toda prece de fome vem colada a um `fome_inicio`, e as duas puxam o olho para o mesmo povo no mesmo dia.
- **Nascimento nunca é chamado**, nem a morte comum (importância < 8). Só os nascimentos com motivo (gêmeos, o primeiro de um povo) entram como nota.
- **A extinção iminente (`os_ultimos`) é rara** (1 em 150 anos, no mundo 2) e deve ser o chamado mais forte.
- **A prece contrariada é chamado.** É a consequência direta do gesto do jogador.

## Para a B (na tela)

1. **Mirar o gesto em `x_povo`.** O sinal da prece fica sobre quem reza (`x`), mas o gesto que responde precisa cair em `x_povo`. Sugestão:
   - ao passar o cursor no sinal, destacar a fogueira do povo;
   - na prece de guerra, destacar também o povo `inimigo`, onde o raio ou o terremoto atende.
2. **Mostrar os poderes que servem.** `atendem` e `contrariam` trazem os poderes de cada prece. Na dica do sinal, uma linha "pede chuva" com o ícone da chuva ajuda o jogador a responder. Se a lista `atendem` estiver vazia (frio e pedidos pequenos), não sugerir nada.
3. **A resposta precisa aparecer.**
   - `prece_atendida`, `prece_sem_resposta` e `prece_contrariada` deviam fechar o sinal com um efeito: luz quente, apagar devagar e um traço vermelho, respectivamente. A contrariada é chamado.
   - Na dica, quem rezou passa 2 dias pensando no desfecho.
4. **Juntar fome e prece.** Quando `fome_inicio` e `prece` de fome do mesmo povo chegam no mesmo dia, um sinal só ("Fome em Koil — Kurpeya pede comida") cansa menos e lê melhor que dois.
5. **Chamados que hoje passam batidos:**
   - `os_ultimos` merece o maior destaque da tela;
   - `profeta` e `separacao` mudam o povo e merecem um sinal que dure;
   - as preces repetidas agora são nota, e podem ser um sinal menor.

## Para decidir

- **O frio não tem poder que o atenda.** O fogo queima. Saídas possíveis:
  - um "fogo" fraco (sinal) que só acende a fogueira e aquece, sem queimar;
  - deixar o frio como a prece que o deus não sabe atender.

  Hoje, a prece de frio só passa com o inverno, e o povo agradece ao acaso.

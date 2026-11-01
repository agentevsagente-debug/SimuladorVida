# Auditoria visual 5: o cotidiano depois da auditoria 4

*Sessão C (arte), 01/11/2026. Feita sobre a main em `d87b0cd`. A A e a B entregaram os itens da auditoria 4: a caçada perto da vila, o abate em chão aberto, a coruja fixa na copa, a raposa e o morcego, a troca de lugar dos parados, as conversas e os balões da tarde e a neblina. O roteiro é o mesmo das auditorias 3 e 4.*

## Como foi feito

Os comandos estão em `capturar5.sh`, com a semente 7 no verão:
- **1x:** 11 horas, com 8 quadros cada, de 1,5 em 1,5 s;
- **duas sessões longas em 1x,** de 2 min cada: a tarde (a partir das 14h) e a madrugada (a partir das 2h);
- **duas caçadas em 1x:** das 13h (2 min) e das 15h (90 s);
- **um dia em 50x** (`recortes5/dia_em_50x.png`);
- **o mundo de 40 anos:** 10h e 16h, mais tarde e madrugada.

São 468 capturas, nenhuma com cor fora da paleta. Das sessões longas, só os quadros pares ficaram em `capturas5/`; o script recria todos. Os recortes estão em `recortes5/`.

**Medidas automáticas:**

| Hora | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 22 | 1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Movimento, auditoria 3 | 229 | 306 | 235 | 234 | 329 | 352 | 222 | 248 | 130 | 70 |
| Movimento, auditoria 4 | 264 | 352 | 376 | 265 | 390 | 382 | 189 | 226 | 80 | 53 |
| Movimento, auditoria 5 | 259 | 254 | 371 | 321 | 389 | 341 | 207 | 249 | 128 | 78 |

*O movimento é a quantidade de pixels da faixa da vila que mudam em 1,5 s. Às 8h ele caiu porque a neblina em pontinhos, que mudava a cada quadro, saiu.*

| Sessão de 1x | Quadros com balão, auditoria 4 | Auditoria 5 | Quadros com a coruja, auditoria 5 |
|---|---|---|---|
| tarde, 2 min | 1 de 60 | **10 de 60** | — |
| caçada das 15h | — | **24 de 60** | — |
| madrugada, 2 min | 8 de 60 | **12 de 60** | **56 de 60** |
| madrugada do mundo de 40 anos | 11 de 40 | **16 de 40** | **35 de 40** |

## Impressão de jogador

| Período | Aud. 3 | Aud. 4 | **Aud. 5** | Por quê |
|---|---|---|---|---|
| **Manhã** (6h às 11h) | 3 | 4 | **4** | Igual à 4, e mais limpa: a neblina da manhã agora fica atrás da vila, sem os pontinhos (`ok_neblina_sem_pontinhos.png`). Há o feixe de lenha, o pote, crianças e gente indo à praia. |
| **Tarde** (12h às 16h) | 2 | 3 | **4** | A tarde mudou de cara (`ok_tarde_baloes_e_criancas.png`). Dois porcos fuçam em chão aberto, junto da vila (`ok_porcos_perto_da_vila.png`). Os balões aparecem 10 vezes mais. As crianças brincam em grupo. Passa gente com o cesto na cabeça. A caçada acontece à vista: a lança crava no lombo do porco, ele foge e a lança fica cravada no chão (`ok_arremesso_e_fuga.png`). Ainda não é 5 (veja abaixo). |
| **Fim de tarde** (17h às 19h) | 4 | 5 | **5** | A roda em volta do fogo continua, com balões. |
| **Noite** (20h às 5h) | 3 | 4 | **5** | A madrugada ficou completa (`ok_madrugada.png`): a coruja fica na copa a noite toda, com os olhos acesos (`ok_coruja_na_copa.png`), e a raposa trota pela beira (`ok_raposa.png`). A vigia cochila com o balão de pensamento, alguém atiça as brasas e há vagalumes. Algo acontece a cada 20 a 30 s. |

**A meta foi atingida:** nenhum período ficou abaixo de 4. A soma das notas foi de 12 (auditoria 3) para 16 (auditoria 4) e agora 18.

**Dá vontade de continuar olhando?** Sim, em 1x, o dia inteiro. A tarde deixou de ser o buraco do dia, e a madrugada virou um bom motivo para deixar o jogo aberto à noite.

## O que falta para a tarde ir a 5

### T1. Os caçadores parecem gente sentada (alto) — arte corrigida, falta a B
`recortes5/T1_cacadores_parecem_sentados.png` e `T1_depois_espreita_e_arremesso_fortes.png`

- **O que está errado:** na espreita, os caçadores ficam agachados a uns 10 px do porco. A lança de 1 px, marrom sobre o verde e o marrom, some. De longe, eles parecem duas pessoas sentadas conversando, e o arremesso, que dura uns 7 s em 1x, passa sem que se perceba.
- **Correção na arte:** fiz três peças novas (seção 22 do LEIA-ME):
  - **`acoes/cacar_espreitar_forte_4q`:** agachado, com a lança de 2 px à frente, passando do corpo, e a ponta clara;
  - **`acoes/cacar_arremessar_forte_4q`:** recolhe a lança atrás da cabeça, ergue, arremessa e acompanha;
  - **`objetos/lanca_voando_forte`** (14 × 3): a lança solta, com a ponta clara e um rastro.

  As três têm a roupa dos estágios 3 a 6 e a de inverno, como as outras ações de 1x.
- **Falta a B:** usar essas peças no lugar das de sempre na caçada.

### T2. A espreita é longa e parada, e o arremesso é curto (médio) — A
- **O que está errado:** os caçadores ficam agachados no mesmo lugar por mais de 1 h de jogo (uns 2 min em 1x), e depois o arremesso dura 4 min de jogo (uns 7 s).
- **O que deveria ser:** a espreita andando aos poucos, de 2 a 4 px a cada 10 a 15 s, com o porco se mexendo também. O arremesso pode durar mais, com uma pausa de 1 a 2 s no quadro 1 (lança erguida) antes de soltar, e quem fica para trás pode fazer `cacar_apontar_2q`.

### T3. A volta e a repartição podem passar pelo meio da vila (baixo) — A e B
Na janela das minhas capturas, a caçada da semente 7 errou (o porco fugiu), então não vi a volta com o porco no pau. Quando acerta, vale a volta atravessar a vila até o fogo, e a caça ser repartida no fogo, com o `espeto` e quem cozinha, de modo que o fim da caçada se encontre com o fim de tarde.

### T4. Mais bichos de dia perto da vila (baixo) — B
- **Hoje:** o porco e a ave grande já aparecem.
- **Sugestão:** uns pássaros pousando no telhado ou no chão (`passaro_pousado_2q`) e um coelho atravessando a borda da roça (`coelho_4q`), a cada poucos minutos de 1x. É o mesmo princípio que fez a madrugada dar certo: um bicho visível o tempo todo e outros passando.

## O que melhorou desde a auditoria 4

| # | Defeito da auditoria 4 | Situação |
|---|---|---|
| N1 | o abate atrás do arbusto | **corrigido:** o porco fica em chão aberto, junto da vila. A lança cravada e a fuga leem bem. Falta a legibilidade dos caçadores (T1). |
| N2 | bichos da madrugada raros | **corrigido:** a coruja aparece em 56 de 60 quadros da madrugada, e a raposa passa pela beira |
| N3 | poucos balões de dia | **corrigido:** balão em 10 de 60 quadros da tarde, e em 24 de 60 durante a caçada |
| N4 | pontinhos claros às 8h | **corrigido:** a neblina agora é em fiapos, atrás da vila |
| N5 | parados por minutos | **melhorou:** quem conversa ou trabalha agora troca de lugar. Os únicos parados por 2 min são os caçadores na espreita (T2). |

## Arte nesta entrega

- `acoes/cacar_espreitar_forte_4q`, `acoes/cacar_arremessar_forte_4q` e `objetos/lanca_voando_forte`, com as variações dos estágios 3 a 6 e de inverno, documentados na seção 22 do LEIA-ME.
- Os atlas foram regenerados. O total foi de 3,94 para 4,19 MB; o `comum` continua em 512 × 512, com 241 peças.

## Resumo por responsável

| Quem | Itens |
|---|---|
| B (apresentação) | T1 (usar as peças fortes da caçada), T4 (bichos de dia), parte do T3 |
| A (simulação) | T2 (espreita andando e arremesso mais longo), T3 (a volta pela vila e a repartição no fogo) |
| C (arte) | T1: peças entregues |

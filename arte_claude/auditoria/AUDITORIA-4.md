# Auditoria visual 4: o cotidiano com as encenações

*Sessão C (arte), 01/11/2026. Feita sobre a main em `87b7fed`, com as encenações da B:
- as ações de 1x;
- as brincadeiras;
- a caçada por etapas;
- a madrugada com brasas, vigia e bichos;
- os balões.

Segue o mesmo roteiro da auditoria 3, para comparar as notas.*

## Como foi feito

Joguei a semente 7, no verão, com capturas reais do jogo, e também olhei os GIFs `tarde-1x.gif` e `madrugada-1x.gif` da B. Os comandos estão em `capturar4.sh`.

**O que foi capturado:**
- **No ritmo 1x, como na auditoria 3:** 11 horas do dia (6, 8, 10, 12, 14, 16, 18, 20, 22, 1 e 3h), com 8 quadros cada, de 1,5 em 1,5 s.
- **Duas sessões longas em 1x, de 2 min de jogo de verdade cada:** a tarde, a partir das 14h, e a madrugada, a partir das 2h, com um quadro a cada 2 s.
- **A caçada em 1x:** das 15h, por 90 s.
- **Um dia inteiro em 50x:** 48 quadros (resumo em `recortes4/dia_em_50x.png`).
- **Um mundo de 40 anos:** 10h e 16h, mais 80 s de tarde e 80 s de madrugada, em 1x.

**Os arquivos:** são 408 capturas, nenhuma com cor fora da paleta. Para o repositório ficar leve, das sessões longas só ficaram os quadros pares em `capturas4/`; o script recria todos. Os recortes estão em `recortes4/`.

**Uma medida simples de vida:** contei quantos pixels da faixa da vila (x 100 a 480, y 85 a 135) mudam de um quadro para o outro, em 1,5 s. A conta inclui o fogo e a água, então serve para comparar, não como valor absoluto.

| Hora | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 22 | 1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Auditoria 3 | 229 | 306 | 235 | 234 | 329 | 352 | 222 | 248 | 130 | 70 |
| Auditoria 4 | 264 | 352 | 376 | 265 | 390 | 382 | 189 | 226 | 80 | 53 |

O dia ficou de 10% a 60% mais mexido. A noite tem menos pixels mudando, porque o fogo agora baixa para brasas, mas ela tem mais acontecimentos (veja a madrugada abaixo).

## Impressão de jogador

| Período | Auditoria 3 | **Auditoria 4** | Por quê |
|---|---|---|---|
| **Manhã** (6h às 11h) | 3 | **4** | O povo se espalha e agora faz coisas que se leem de longe: o feixe de lenha atravessado no peito e no ombro (`ok_feixe_de_lenha_1x.png`), crianças correndo, gente indo à praia. Às 10h, o movimento é 60% maior que na auditoria 3. |
| **Tarde** (12h às 16h) | 2 | **3** | Melhorou: há pares conversando com balão, crianças brincando, a ave grande andando entre as cabanas e a caçada voltando com o porco no pau. Mas os balões são raros, 1 em 60 quadros nos 2 min da tarde longa. Os grupos ainda ficam muito tempo nos mesmos lugares. E a parte da caçada que cai na tarde (o abate) é um borrão atrás de um arbusto (N1). É o único período abaixo da meta. |
| **Fim de tarde** (17h às 19h) | 4 | **5** | O D1 está resolvido: a roda fica em volta do fogo, a 9 px ou mais, e quem está à direita olha para o fogo (`ok_roda_em_volta_do_fogo.png`). Com o céu do entardecer, é o melhor momento do jogo. |
| **Noite** (20h às 5h) | 3 | **4** | Até as 22h, a roda continua, com balões. A madrugada deixou de ser vazia (`ok_madrugada_vigia_e_atico.png`): o fogo baixa para brasas, a vigia cochila com o balão de pensamento, alguém levanta, boceja e atiça o fogo, e há vagalumes. Em 2 min de madrugada, algo acontece a cada 30 a 40 s. Só não fica 5 porque, em 3 min e 20 s de madrugada capturada, não apareceu nenhum bicho, nem a coruja (N2). |

**Comparação:** a soma das notas foi de 12 para 16. Três períodos estão na meta (4 ou mais); falta a tarde.

**Dá vontade de continuar olhando?**
- **Em 1x, sim,** da manhã até a madrugada, com a ressalva da tarde. Quem olha de canto de olho agora vê gente carregando coisas, crianças correndo e balões aparecendo.
- **Em 50x, continua agradável.** O ciclo de espalhar, reunir e esvaziar ficou mais rico, com a caça chegando à fogueira no fim da tarde.

## Respostas às perguntas

- **A tarde em 1x:** está mais viva, mas ainda é o período mais fraco (3). Há poucos balões, o abate ilegível (N1) e grupos parados por minutos.
- **A madrugada:** ganhou ritmo. Brasas, vigia cochilando com balão, gente atiçando o fogo e vagalumes dão um acontecimento a cada meio minuto. Falta o bicho (N2).
- **A caçada lê como caçada?**
  - **A volta, sim:** dois carregadores com o porco no pau grosso atravessando até o fogo (`ok_volta_com_a_caca_gif_da_B.png`, do GIF da B).
  - **O abate, não:** o porco escuro cai sobre um arbusto, e quem amarra fica ajoelhado em cima dele. De longe, é um borrão marrom (N1).
  - **Espreitar e arremessar:** não peguei nas minhas capturas. No GIF da B, os caçadores ficam de pé na borda, sem a lança visível em voo.
- **As brincadeiras, os balões e as ações de 1x são visíveis?**
  - **Ações de 1x, sim:** o feixe de lenha e o pote são o que mais se lê.
  - **Brincadeiras, em parte:** as crianças correm, mas não vi a ciranda em nenhuma captura.
  - **Balões, sim, quando aparecem:** à noite e no pensamento da vigia lêem muito bem (creme sobre o escuro). De dia, aparecem pouco (N3).
- **A coruja aparece?** Não, em nenhuma das minhas capturas nem no GIF da madrugada (N2).

## Defeitos, do mais grave ao mais leve

### N1. O abate da caçada é um borrão atrás do arbusto (alto)
`recortes4/N1_abate_atras_do_arbusto.png` (caçada, 15h)

- **O que está errado:** o porco abatido e o pau no chão ficam em cima de um arbusto da borda. O caçador que amarra fica ajoelhado sobre o bicho. Tudo é marrom-escuro sobre verde-escuro, e não se vê o bicho nem a corda.
- **O que deveria ser:**
  - o bicho caído em chão aberto, desenhado na frente da vegetação baixa;
  - quem amarra ao lado dele, a uns 8 px, com a mão sobre ele (`cacar_amarrar_4q`, seção 24 do LEIA-ME);
  - o `pau_no_chao` do outro lado;
  - quem comemora a uns 10 a 16 px, de pé e com a lança erguida, para dar silhueta.
- **Na espreita e no arremesso:** os caçadores agachados (`cacar_espreitar_4q`), e a `lanca_voando` desenhada no arco até o bicho.
- **Quem corrige:** **B** (ordem de desenho e encaixe). Se a A puser o bicho a uns 20 px da borda, em chão aberto, a cena fica livre dos arbustos.

### N2. A coruja e os outros bichos da madrugada quase nunca aparecem (médio)
`recortes4/N2_madrugada_sem_bicho.png`

- **O que está errado:**
  - A cena `bicho_noturno` sorteia 1 ou 2 bichos por noite, entre coruja, morcego, raposa e sapo.
  - Cada um fica de 25 a 45 min de jogo, ou seja, de 50 s a 1 min e meio em 1x, numa hora sorteada.
  - Somando, isso cobre de 10% a 25% da noite, e a coruja tem 1 chance em 4.
  - Em 3 min e 20 s de madrugada capturada (2 mundos), não apareceu nenhum bicho. O GIF da madrugada da B também não pegou a coruja.
- **O que deveria ser:**
  - a coruja como presença fixa da madrugada, pousada a noite toda numa árvore perto da vila, piscando e virando a cabeça;
  - os outros bichos passando a cada 15 a 30 min de jogo: a raposa trotando pela borda (a arte já existe: `raposa_noite_4q` e `raposa_parada_4q`), o morcego sobre o lago, o sapo na margem.
- **A conferir:** a coruja vai em `chão − 18`, no x da mata. Se não houver copa ali, ela flutua. O ideal é pôr a base dela no topo da copa da árvore mais próxima.
- **Quem corrige:** **A** (frequência e duração das cenas) e **B** (a coruja fixa e a raposa, que ainda não tem encenação).

### N3. Poucos balões de dia (médio)
`recortes4/N3_tarde_poucos_baloes.png` e `ok_baloes.png`

- **O que está errado:** nos 2 min da tarde longa, só 1 quadro em 60 tem balão. Às 12h e às 15h há conversas com balão, mas curtas. À noite, os balões aparecem bem mais.
- **O que deveria ser:** na tarde, um balão a cada 10 a 20 s em algum lugar da tela. Por exemplo, os pares parados conversando alternam `fala`, e quem trabalha junto solta um balão de vez em quando. O limite de 3 de cada vez continua bom.
- **Quem corrige:** **B** (e a A, se a conversa vier das cenas).

### N4. Pontinhos claros em arco sobre o acampamento às 8h (baixo, a confirmar)
`recortes4/N4_pontinhos_brancos_8h.png`

- **O que está errado:** às 8h, pontinhos azul-claros e brancos ficam espalhados em arco sobre as cabanas e a fogueira, por todos os 8 quadros. Não consegui identificar a peça. Pode ser algum efeito (orvalho, garoa ou fagulha) fora do lugar.
- **Quem corrige:** **B**, ao identificar a origem.

### N5. A tarde ainda tem grupos parados por minutos (baixo)
`recortes4/N3_tarde_poucos_baloes.png`

- **O que está errado:** os mesmos pares ficam de pé no mesmo lugar do início ao fim dos 2 min. Eles se mexem no lugar, mas não trocam de posição.
- **O que deveria ser:** quem está parado há mais de 30 a 40 s de 1x troca de lugar ou de atividade, como ir até o fogo, sentar ou ir buscar água com o pote.
- **Quem corrige:** **A** e **B**.

## O que melhorou desde a auditoria 3

| # | Defeito da auditoria 3 | Situação |
|---|---|---|
| D1 | pessoas dentro da fogueira | **corrigido** |
| D2 | falta acontecimento em 1x | **melhorou muito**: ações de 1x, brincadeiras e balões. Falta só a tarde (N3 e N5). |
| D3 | a caçada não lê | **em parte**: a volta com o porco no pau lê bem; o abate não (N1). |
| D4 | madrugada vazia | **corrigido** nos acontecimentos (brasas, vigia, atiçar, vagalumes); falta o bicho (N2) |
| D5 | fumaça parada no céu | **corrigido**: a baforada sobe e some perto do fogo |
| D6 | samambaia tracejada | **corrigido** (arte) |
| D7 | ruínas no meio da vila | **corrigido**: no mundo de 40 anos, a vila não tem mais ruínas no meio. Pelo relatório da B, as casas vazias agora ficam nas pontas e o mato cresce mais cedo sobre elas; não vi nenhuma casa vazia nas capturas para conferir o mato. |

## Arte nesta entrega

- **Raposa da madrugada** (`criaturas/raposa_noite_4q` e `raposa_parada_4q`, 12 × 7), já em tons de noite:
  - ferrugem apagada, com peito e ponta do rabo claros, olho que brilha e patas em ferrugem escura, para não flutuar no chão escuro;
  - trota, para, cheira o chão e olha para trás;
  - está na seção 17 do LEIA-ME e no atlas `comum`.

## Resumo por responsável

| Quem | Itens |
|---|---|
| B (apresentação) | N1 (o abate em chão aberto, com a lança no ar), N2 (a coruja fixa e a encenação da raposa), N3, N4 |
| A (simulação) | N2 (frequência dos bichos da noite), N5, e o lugar do bicho na caçada (N1) |
| C (arte) | a raposa, entregue. Nenhum defeito novo de arte. |

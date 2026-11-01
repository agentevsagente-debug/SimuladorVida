# Auditoria visual 6: a caçada completa, os bichos de dia e a dica da pessoa

*Sessão C (arte), 01/11/2026. Feita sobre a main em `baf4e90`.*

**O que a A e a B entregaram desde a auditoria 5:**
- a caçada completa: a espreita em avanços, a mira, o arremesso forte, a volta pela vila e a repartição no fogo;
- pássaros pousados e o coelho de dia;
- a dica nova da pessoa, com o que ela faz, o que pensa e o humor.

O roteiro é o mesmo das auditorias 4 e 5, com duas caçadas inteiras a mais e as capturas da dica.

## Como foi feito

Os comandos estão em `capturar6.sh`, com a semente 7 no verão:
- **1x:** 11 horas, com 8 quadros cada, de 1,5 em 1,5 s;
- **duas sessões longas em 1x,** de 2 min cada: a tarde (a partir das 14h) e a madrugada (a partir das 2h);
- **um dia em 50x** (`recortes6/dia_em_50x.png`);
- **o mundo de 40 anos:** 10h e 16h, mais a tarde e a madrugada.

**As duas caçadas inteiras em 1x,** das 12h às 17h45, com um quadro a cada 3 s (1,5 min de jogo):
- a de 12 dias, em que o arremesso erra;
- a de 13 dias, em que acerta, como a B indica no RELATORIO.

**A dica:**
- 4 pessoas às 9h, 15h, 19h e 23h, com `--dica-pessoa`;
- uma criança acompanhada por 1 min;
- as frases do `testar_dica`, em 8 mundos.

**O horário da caçada** foi lido do próprio núcleo:

| Etapa | 12 dias | 13 dias |
|---|---|---|
| Saída do fogo | 15h37 | 15h38 |
| 9 avanços de espreita | 15h51 a 16h53 | 15h52 a 16h55 |
| Mira | 16h53 | 16h55 |
| Arremesso | 16h54 a 17h00 | 16h56 a 17h02 |
| Depois do arremesso | fuga até 17h16 | abate até 17h18, depois a volta e a repartição até ~17h30 |

São 848 capturas, nenhuma com cor fora da paleta. Ficaram 420 em `capturas6/`:
- das sessões longas, os quadros pares;
- das caçadas, um quadro em cada 4, mais todos os quadros da caçada de 13 dias do 180 ao 206 (16h30 a 17h10).

O script recria todas. Os recortes estão em `recortes6/` (`recortar6.py`), e as medidas, em `medir6.py`.

**Cuidado com duas capturas.** Na madrugada longa (do quadro 19 em diante) e na caçada de 12 dias, aparece a dica "O morro" no canto de baixo. Ela vem do meu cursor de verdade, parado sobre a janela, e não é defeito do jogo. Ela não aparece nas capturas por hora, que são as do movimento, e os recortes evitam esse canto.

## Medidas automáticas

| Hora | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 22 | 1 |
|---|---|---|---|---|---|---|---|---|---|---|
| Movimento, auditoria 4 | 264 | 352 | 376 | 265 | 390 | 382 | 189 | 226 | 80 | 53 |
| Movimento, auditoria 5 | 259 | 254 | 371 | 321 | 389 | 341 | 207 | 249 | 128 | 78 |
| Movimento, auditoria 6 | 260 | 250 | 334 | 287 | 393 | 324 | 273 | 242 | 138 | 86 |

O movimento é a quantidade de pixels da faixa da vila que mudam em 1,5 s. Às 18h ele subiu 30%, com a repartição e o espeto no fogo.

**Balões.** O detector de balões agora é um script (`medir6.py`). Ele conta menos que a contagem da auditoria 5, que foi feita à mão, então recontei as capturas da 5 com ele:

| Sessão em 1x | Auditoria 5 (no texto da 5) | Auditoria 5 (recontada) | **Auditoria 6** |
|---|---|---|---|
| Tarde, 2 min (14h) | 10 de 60 | 7 de 60 | **7 de 60** |
| Madrugada, 2 min | 12 de 60 | 6 de 60 | **6 de 60** |
| Tarde do mundo de 40 anos | — | 3 de 40 | **5 de 40** |
| Madrugada do mundo de 40 anos | 16 de 40 | 2 de 40 | **3 de 40** |
| Caçada de 12 dias, das 12h às 15h30 | — | — | **22 de 140** |
| Caçada de 12 dias, das 15h30 às 17h | — | — | **10 de 60** |
| Caçada de 13 dias, das 12h às 15h30 | — | — | **20 de 140** |
| Caçada de 13 dias, das 15h30 às 17h | — | — | **12 de 60** |

Os balões estão iguais aos da auditoria 5: de 12% a 20% dos quadros de dia. A coruja e a raposa eu conferi a olho, nos quadros da madrugada: a coruja está na copa em todos que olhei, e a raposa passa.

## Impressão de jogador

| Período | Aud. 4 | Aud. 5 | **Aud. 6** | Por quê |
|---|---|---|---|---|
| **Manhã** (6h às 11h) | 4 | 4 | **4** | Igual à 5. Os bandos de pássaros cruzando o céu se veem bem. |
| **Tarde** (12h às 16h59) | 3 | 4 | **4** | Das 15h37 às 17h, a tarde tem agora o melhor trecho do dia depois do fogo: a caçada sai, avança aos poucos, mira e arremessa, e tudo se lê (`ok_espreita_mira_arremesso_12dias.png`). Mas das 12h às 15h30, que são uns 7 min em 1x, a tarde está como na auditoria 5: porcos fuçando, crianças, balões em 15% dos quadros, gente indo e vindo, e nenhum acontecimento maior. Antes a caçada saía às 12h40; agora sai às 15h37. Veja abaixo o que falta. |
| **Fim de tarde** (17h às 19h) | 5 | 5 | **5** | Ficou mais forte: o abate, a volta com o porco no pau e o espeto no fogo caem no começo do entardecer (`ok_lanca_no_ar_abate_volta_espeto_13dias.png`). |
| **Noite** (20h às 5h) | 4 | 5 | **5** | Igual à 5: a coruja na copa, a raposa, a vigia cochilando e as brasas. |

**A meta da tarde não foi atingida: ela ficou em 4.** A nota está assim:
- **A caçada em si já é nota 5.** Os pontos T1 e T2 da auditoria 5 estão resolvidos.
- **A tarde é 4.** A caçada cobre só 1h20 de jogo das 5h da tarde, uns 3 min em 1x.
- **A 4 vem das 12h às 15h30,** que ficaram iguais às da auditoria 5. Ao levar o fim da caçada para o fogo (T3), a A empurrou a saída das 12h40 para as 15h37. O começo da tarde ficou sem o seu acontecimento.

A soma das notas fica em 18, como na auditoria 5.

**Dá vontade de continuar olhando?** Sim. Quem deixa o jogo aberto das 15h30 em diante vê uma história inteira em uns 4 min: os caçadores saem, rastejam, um ergue a lança, ela voa, o porco cai, a caça volta no pau e vai para o espeto no fogo, já com o céu laranja. É o melhor encadeamento do jogo até agora.

## A caçada, etapa por etapa

| Etapa | Lê? | Comentário |
|---|---|---|
| Saída e espreita em avanços | **sim** | Os caçadores agachados, com a lança de 2 px apontada para o porco, avançam aos poucos. Já não parecem gente sentada (o T1 da auditoria 5 está resolvido). |
| Mira | **sim** | A lança erguida atrás da cabeça, por 1 s, se vê. |
| Arremesso e lança no ar | **sim** | A `lanca_voando_forte` aparece no alto, sobre o porco. |
| Erro | **sim** | A lança fica cravada inclinada no chão, e o porco foge. |
| Abate | **sim** | O porco cai de lado, com a lança cravada. |
| Volta | **em parte** | Os dois carregadores com o porco no pau se leem, mas só por uns 12 s. O porco estava a uns 30 px do fogo, então a volta é curta e some entre a cabana e a roda. Enquanto esperam, aparece o defeito H1. |
| Repartição e espeto | **sim** | A caça no chão do fogo e depois no espeto, com quem cozinha, ficam bem no entardecer, apesar da roda cheia. |

### H1. O pau vazio na cabeça (médio) — B
`recortes6/H1_pau_vazio_na_cabeca.png` (13 dias, quadros 191 a 197, por volta das 17h05)

- **O que está errado:** depois do abate, o porco fica no chão com o `pau_no_chao` ao lado. Enquanto isso, um dos carregadores fica de pé com um pau longo apoiado na cabeça, sem o porco, como se carregasse uma tábua. Isso dura uns 30 s em 1x.
- **Pelo RELATORIO, deveria ser:** a caça já pendurada no pau entre os dois carregadores, também enquanto esperam.
- **O que fazer:** ou o porco vai para o pau (`caca_no_pau_porco_forte`) assim que os dois estão no lugar, ou, até lá, os dois ficam agachados amarrando (`cacar_amarrar_4q`), sem o pau na cabeça.

### H2. Os caçadores se amontoam, e há alguém parado ao lado do porco (médio) — A e B
`recortes6/H2_cacadores_amontoados.png` (12 dias, das 16h20 às 16h50)

- **O que está errado:**
  - Os três caçadores avançam colados, a 2 ou 3 px um do outro. Lê como uma mancha com uma lança, e não se conta quantos são.
  - Uma pessoa da vila fica de pé a 4 px do porco durante a espreita toda. O porco não foge dela, o que tira a tensão da cena.
  - A espreita acontece entre as cabanas, a 10 ou 50 px do fogo, no meio de quem está no acampamento. Ainda lê como caçada graças às lanças apontadas, mas por pouco.
- **O que deveria ser:**
  - os caçadores escalonados, a uns 6 a 8 px um do outro, o último mais atrás (já faz `apontar` na mira);
  - ninguém da vila a menos de 20 px do porco durante a caçada: quem estiver ali sai, ou o porco foge dela;
  - de preferência, o porco mais longe do acampamento. Isso também alonga a volta (veja T6).

## O que falta para a tarde ir a 5

### T5. Um acontecimento no começo da tarde (alto) — A e B
`recortes6/tarde_antes_da_cacada.png`

As 12h às 15h30 são o maior trecho do dia sem nenhum acontecimento que se acompanhe do começo ao fim. São 7 min em 1x, logo depois do almoço. Há dois caminhos, e o primeiro me parece o melhor:

1. **Levar a caçada de volta para o começo da tarde.** A saída voltaria para perto das 13h30 a 14h, e as 9 espreitas teriam pausas mais longas entre elas: o porco fuça, os caçadores esperam abaixados. Assim a espreita cobriria das 14h às 16h30, e o resto cairia no entardecer, como hoje. A repartição no fogo continua no fim da tarde.
2. **Outra cena do começo da tarde,** com começo, meio e fim que se veem de longe. Por exemplo:
   - a pesca: alguém na água rasa com a lança de pesca, e o peixe pulando e saindo na ponta;
   - a volta da coleta do morro: 3 ou 4 pessoas em fila, com cesto na cabeça, descendo até o fogo e despejando os cestos;
   - a lavagem no lago, com as crianças na água.

   A arte do cesto na cabeça e da água já existe. A pesca precisaria de 2 folhas novas, que eu posso fazer.

### T6. A volta é curta demais para atravessar a vila (baixo) — A
O porco fica a uns 30 px do fogo, então a volta dura uns 12 s e passa entre a cabana e a roda. Com o porco mais longe (H2), na borda da mata ou do morro, a volta atravessaria a vila de verdade. Ela passaria por quem está trabalhando, e as crianças poderiam correr atrás: o pensamento "Lá vêm eles com a caça!" já existe.

### T7. Os pássaros pousados quase não se veem (baixo) — C
`recortes6/T4_passaro_pousado_e_coelho.png`

- **Os pássaros pousados:** o `passaro_pousado_2q` tem 4 × 2 px, em marrom e ocre. Na ponta das cabanas do estágio 1, que também é marrom, vira um pontinho. Nem a 3x dá para dizer que é um pássaro.
- **Os bandos voando e o coelho:** se leem bem. O coelho aparece na borda, em chão aberto, nas duas tardes de caçada e na tarde longa.
- **Correção na arte (posso fazer na próxima ordem):** um pássaro pousado de 5 × 3, com o peito claro e o bico escuro, que destaque sobre a palha, sobre o telhado e sobre o céu.

## A dica da pessoa, como jogador

`recortes6/ok_dica_em_1x.png`, `dica_tres_horas.png` e `D1_pensamento_contradiz_o_que_faz.png`

| Pergunta | Resposta |
|---|---|
| **Dá vontade de passar o cursor?** | **Sim.** É a primeira coisa no jogo que mostra cada pessoa como alguém, e não como um boneco. O humor na primeira linha e o pensamento com o nome dos outros ("Gosto de ver Rilorim rir", "À noite, Rilorim me espera no fogo") puxam a mão para procurar o Rilorim. Duas coisas cortam essa vontade: a repetição (D2) e a noite vazia (D4). |
| **As frases soam naturais?** | **Quase sempre.** São curtas, faladas e com a voz certa da idade: "Quando crescer, vou mandar em todos", "Tem bicho no escuro?", "As pernas já não aguentam como antes", "Brigar não enche a barriga de ninguém". O nome do deus ("Hoje vou agradecer ao Que Sacode") e o espreitador ("Devagar... ele ainda não me viu") são ótimos. Os tropeços estão em D1 a D3. |
| **É legível em 1x?** | **Sim.** Na captura crua de 480 × 160, a fonte 5 × 7 lê nas três cores sobre o azul-noite. O creme tem contraste de 12:1 e o lilás do pensamento, de 5,7:1, o que basta. A caixa tem até uns 150 × 50 px, cerca de 10% da tela. Ela fica acima da cabeça e cobre o céu e o morro, não as pessoas. |
| **Combina com a direção C?** | **Sim.** É o mesmo azul-noite com dourado da alça, com o bico da dica e o balãozinho de pensamento do `balao_5v`. É tudo opaco e da paleta. O travessão no lugar do ponto do meio fica bem. |

### D1. O pensamento contradiz o que a pessoa faz (médio) — A
Suan, 7 anos, está "Brincando na praia" e pensa "Amanhã vou na praia de novo". O mesmo pensamento continua pelo minuto inteiro em que a acompanhei. Pensamentos sobre um lugar ou uma ação não deveriam sair enquanto a pessoa já está nesse lugar ou fazendo essa ação. Por exemplo, na praia, "Achei uma concha!" ou "A água está fria!".

### D2. Os mesmos pensamentos voltam cedo, e passam de uma pessoa para outra (médio) — A
- **A mesma pessoa repete:**
  - Oran, 4 anos, pensa "Quando crescer, vou mandar em todos" às 9h e às 15h;
  - Totoim, 5 anos, pensa "Vou dar minha fruta ao pequeno" às 9h e às 15h.
- **O pensamento passa de uma pessoa para outra:** "Amanhã vou na praia de novo" é de Suan às 15h e de Oran às 19h.
- **"Gosto de ver X rir"** aparece em 3 dos 8 mundos do `testar_dica` e duas vezes nas minhas capturas.

O pensamento muda a cada 2 horas, mas volta para a mesma frase. Sugestões:
- não repetir a mesma frase para a mesma pessoa no mesmo dia;
- evitar duas pessoas com a mesma frase ao mesmo tempo, que é quando o jogador compara dicas;
- dar 2 ou 3 variações aos modelos mais frequentes, como "Gosto de ver X rir", "X me faz rir" e "Com X por perto o dia passa rápido".

### D3. "a linhagem que você segue" começa com minúscula e fala com o jogador (baixo) — B
Na dica de quem é seguido, a última linha é "a linhagem que você segue", em minúscula e na mesma cor do resto. As outras linhas começam com maiúscula. A linha também fala com o jogador, o que o núcleo evita nas frases.

Sugestão: trocar por uma marca, em vez de frase. Por exemplo, um pequeno ícone da linhagem (o da alça, 8 × 8) ao lado do nome. Ou a linha "Da linhagem seguida", com maiúscula e na cor dourada.

### D4. De noite não há em quem passar o cursor (médio) — B
Às 23h, nenhuma das 4 pessoas gerou dica, porque quem dorme não é desenhado: fica dentro das cabanas. Assim, os sonhos que a A escreveu ("Sonha com Vepeik") nunca chegam à tela. Sugestões:
- uma dica sobre a cabana à noite, como "Dormem aqui: Tamu e Peos", com o sonho de um deles na linha lilás;
- quando o sonho aparecer, sem as aspas e sem o "Sonha com". Por exemplo, a linha lilás "sonhando com Vepeik" com o balãozinho. As aspas pedem uma frase que a pessoa pensa, e "Sonha com Vepeik" é narração.

### Sugestão (não é defeito)
Quando o pensamento cita alguém ("Saudade de Loa", "Gosto de ver Rilorim rir"), um sinal sobre a cabeça dessa pessoa, enquanto a dica está aberta, ligaria as duas. Pode ser o bico pequeno ou um ponto dourado. Isso transforma a dica num jeito de descobrir quem gosta de quem, e dá mais vontade de passar o cursor.

## O que melhorou desde a auditoria 5

| # | Item da auditoria 5 | Situação |
|---|---|---|
| T1 | os caçadores parecem gente sentada | **corrigido:** com a lança de 2 px apontada, leem como caçadores |
| T2 | a espreita parada e o arremesso curto | **corrigido:** 9 avanços, a mira com a lança erguida, a lança no ar |
| T3 | a volta e a repartição | **em parte:** a repartição e o espeto no fogo leem bem; a volta é curta (T6) e tem o H1 |
| T4 | bichos de dia | **em parte:** os bandos e o coelho se veem; o pássaro pousado não (T7) |

## Resumo por responsável

| Quem | Itens |
|---|---|
| A (simulação) | **T5** (a caçada de volta ao começo da tarde, ou outra cena das 12h às 15h30), H2 (o porco mais longe, ninguém da vila perto dele), T6, D1, D2 |
| B (apresentação) | **H1** (o pau vazio na cabeça), H2 (caçadores escalonados), D3, D4, a sugestão de marcar quem o pensamento cita |
| C (arte) | T7 (o pássaro pousado maior), e as folhas da pesca se o T5 for por esse caminho |

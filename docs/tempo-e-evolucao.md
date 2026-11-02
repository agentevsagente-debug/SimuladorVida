# Tempo e evolução

*Simulador de vida 0.1.1. [Voltar ao início](../README.md)*

O jogo foi pensado para ficar aberto o dia todo, num ritmo lento. Esta página mostra quanto dura cada pedaço do tempo de jogo e quanto tempo um povo leva para passar pelos 6 estágios.

## O relógio do mundo

| Grandeza | Valor |
|---|---|
| 1 hora de jogo | 112,5 segundos reais, em 1x |
| 1 dia de jogo | 24 horas de jogo = **45 minutos reais**, em 1x: cerca de 26 min de dia e 19 min de noite (a noite vai das 20h às 6h) |
| 1 estação | 10 dias de jogo |
| 1 ano | **40 dias de jogo**, em 4 estações de 10 (primavera, verão, outono e inverno) |

A simulação anda de hora em hora. As velocidades maiores só fazem as horas passarem mais depressa; o mundo é o mesmo.

## Quanto dura, por velocidade

| Tempo de jogo | 1x (normal) | 10x | 50x |
|---|---|---|---|
| 1 hora | 112,5 s | 11,25 s | 2,25 s |
| 1 dia | 45 min | 4,5 min | 54 s |
| 1 estação (10 dias) | 7,5 h | 45 min | 9 min |
| 1 ano (40 dias) | 30 h | 3 h | 36 min |
| 10 anos | 300 h (12,5 dias corridos) | 30 h | 6 h |
| 1 geração (cerca de 20 anos) | 600 h (25 dias corridos) | 60 h | 12 h |

As teclas 1, 2 e 3 escolhem 1x, 10x e 50x; 0 e Espaço pausam. A tecla **S** salta até o próximo acontecimento, até no máximo 1 ano de jogo por salto.

## Enquanto o jogo está fechado (a ausência)

O mundo não para quando você fecha o jogo. Ao abrir de novo, o jogo conta o tempo real que passou desde o último salvamento e simula as horas que faltam, **no ritmo de 1x e até o teto de 1 ano de jogo** (960 horas de jogo, ou 30 horas reais). Passado o teto, o mundo espera por você.

| Tempo fechado | Quanto o mundo anda |
|---|---|
| uma noite (16 h) | cerca de 21 dias de jogo |
| um dia inteiro (24 h) | 32 dias de jogo |
| 30 h ou mais (um fim de semana, as férias) | o teto: 1 ano de jogo |

- **É rápido.** O ano de ausência é simulado sem gráfico. Na medição do QA, carregar um mundo de 250 anos e avançar 1 ano levou 0,4 s.
- **Você fica sabendo do que aconteceu.** Um resumo abre sozinho, contando o período ("Enquanto você esteve fora: 10 dias"), e a crônica (tecla C) traz os anos inteiros.
- **Tudo pode acontecer, inclusive a extinção.** É raro: num teste da simulação com 20 mundos, partindo dos anos 3, 25, 60 e 120, foram 79 anos de ausência sem nenhum fim do mundo. A população mudou de −24% a +17% no ano fora (mediana de +3%).
- **O relógio do Windows conta.** Se o relógio voltar no tempo, a ausência é zero; se pular para a frente, vale o salto, até o teto.

**Na prática:** quem abre o jogo pelo menos uma vez a cada 30 horas tem o mundo andando em 1x o tempo todo, aberto ou fechado. Só as ausências mais longas que isso perdem tempo de jogo.

## Os 6 estágios

O mundo começa no estágio 1. Não existe árvore de pesquisa: cada povo descobre o próximo saber sozinho, pela necessidade, por gente engenhosa ou curiosa e pela troca com outros povos. O saber vive nas pessoas e se ensina devagar. **Quando morre o último que sabia, o povo volta um estágio**, a não ser que a escrita o salve.

| Estágio | O que aparece na tela | O que muda no povo e na relação com o deus |
|---|---|---|
| **1. Coleta** | cabanas de galhos e a fogueira | um grupo de coletores que caça, pesca e cata; depende de tudo, e o deus é tudo |
| **2. Agricultura** | roças, o celeiro (se o povo guarda comida) e o primeiro templo (se o povo crê) | o povo passa a plantar; nos últimos 4 dias do outono, todos os adultos vão à colheita |
| **3. Pedra** | casas de pedra e o templo em degraus | os sacerdotes ganham força: o dobro de éditos, e o poder pode passar ao templo. Mais depressa depois de terremoto, tempestade ou dilúvio |
| **4. Metal** | casas de enxaimel, a forja e o templo de colunas | as guerras matam mais. Mais depressa em tempo de guerra |
| **5. Escrita** | casas caiadas, o arquivo e a estela | os costumes não se esquecem; o saber se ensina 3 vezes mais rápido; o povo escreve a própria crônica (que às vezes contradiz a do deus); o estudo do céu enfraquece os presságios; um povo pode deixar de rezar |
| **6. Engenharia** | casas de tijolo, canais, roda d'água, moinho, muralhas e barcos | a irrigação faz a seca pesar pouco, e o povo não reza mais por chuva; tudo o que o deus faz impressiona 40% menos. É o teto: daí em diante, a evolução é só social e cultural |

O deus pode inspirar: o **sonho** dá a alguém o saber do próximo estágio, que pode servir à paz ou à guerra. Os números abaixo são de mundos **sem nenhum gesto do deus**.

### Em quantos anos de jogo

Ano em que o primeiro povo do mundo chega a cada estágio:

| Estágio | Mundos medidos | Mínimo | Mediana | Máximo |
|---|---|---|---|---|
| 2. Agricultura | 60 | 4 | 25 | 50 |
| 3. Pedra | 20 | 14 | 61 | 124 |
| 4. Metal | 19 | 33 | 103 | 213 |
| 5. Escrita | 19 | 73 | 145 | 225 |
| 6. Engenharia | 19 | 100 | 172 | 249 |

- Na agricultura, 90% dos mundos chegaram até o ano 38.
- Os 20 mundos chegaram ao estágio 6 antes de 300 anos (um deles depois de um fim do mundo e de um povo novo).
- A variação é grande porque cada mundo tem a sua história: uma peste, uma fome ou uma guerra no momento errado podem levar embora quem sabia, e o povo precisa reaprender.

### Em tempo real (mediana)

| Estágio | 1x, sem parar | 10x, sem parar | 50x, sem parar | Uso típico |
|---|---|---|---|---|
| 2. Agricultura (25 anos) | 31 dias | 3 dias | 15 h | cerca de 1,3 mês |
| 3. Pedra (61 anos) | 76 dias | 7,6 dias | 1,5 dia | cerca de 3 meses |
| 4. Metal (103 anos) | 4,2 meses | 13 dias | 2,6 dias | cerca de 5 meses |
| 5. Escrita (145 anos) | 6 meses | 18 dias | 3,6 dias | cerca de 7,5 meses |
| 6. Engenharia (172 anos) | 7 meses | 21,5 dias | 4,3 dias | cerca de 9 meses |

### Em tempo real (do mais rápido ao mais lento)

| Estágio | 1x, sem parar | 10x, sem parar | 50x, sem parar | Uso típico |
|---|---|---|---|---|
| 2. Agricultura | 5 a 62 dias | 12 h a 6 dias | 2,4 a 30 h | 1 a 11 semanas |
| 3. Pedra | 17,5 a 155 dias | 1,8 a 15,5 dias | 8 a 74 h | 3 a 28 semanas |
| 4. Metal | 41 a 266 dias | 4 a 27 dias | 20 a 128 h | 7 a 48 semanas |
| 5. Escrita | 91 a 281 dias | 9 a 28 dias | 44 a 135 h | 16 a 50 semanas |
| 6. Engenharia | 125 a 311 dias | 12,5 a 31 dias | 60 a 149 h | 22 a 56 semanas |

**Como ler as colunas:**
- **1x, 10x e 50x, sem parar:** o jogo rodando nessa velocidade dia e noite. Em 1x, isso vale também para quem fecha o jogo, desde que o abra pelo menos uma vez a cada 30 horas (veja a ausência, acima). Um ano de jogo dura 30 h em 1x, 3 h em 10x e 36 min em 50x.
- **Uso típico (estimativa):** o jogador simulado pela sessão de simulação em `jogo/ferramentas_sim/uso_real/`.
  - De segunda a sexta, o jogo fica aberto 8 h em 1x: 256 horas de jogo, uns 11 dias.
  - De segunda a quinta, a noite fechada (16 h) avança 512 horas de jogo, uns 21 dias.
  - O fim de semana fechado (64 h) para no teto: 1 ano de jogo.
  - Somando, uma semana real dá 4.288 horas de jogo, ou **cerca de 4,5 anos de jogo**. Os meses da tabela contam 4,35 semanas por mês.

## De onde vêm os números

- **O relógio:** as constantes do núcleo (`Mundo.SEGUNDOS_POR_PASSO = 112,5`, `TETO_AUSENCIA = 960`) e a velocidade da apresentação (10x e 50x dividem o passo por 10 e por 50).
- **A agricultura:** a medição de equilíbrio da sessão de simulação, em 60 mundos (sementes 1 a 60), depois do ajuste que apressa a descoberta quando o povo passa de 25 anos na coleta (`jogo/ferramentas_sim/equilibrio/LEIAME.md`).
- **Os estágios 3 a 6:** uma rodada nova da sondagem da sessão de simulação (`jogo/ferramentas_sim/sondagem_longa.gd`), feita para esta página em 01/11/2026 sobre o código da versão 0.1.1 (commit `277375f`): 20 mundos (sementes 1 a 20), 300 anos cada, sem gestos do deus, numa cópia do núcleo fora do repositório. O ano conta quando o povo chega ao estágio, como na medição da agricultura (a sondagem confere no fim de cada ano, então os valores dela foram descontados de 1). Na mesma rodada, a agricultura deu mínimo de 4, mediana de 21 e máximo de 50, em linha com os 60 mundos.
  - Na semente 16, o povo se extinguiu, e um povo novo, criado 10 anos depois (como faria um jogador), chegou aos estágios 4 a 6. Ela fica fora das linhas de 4 a 6, que por isso têm 19 mundos.
- **A tabela antiga** em `jogo/ferramentas_sim/sondagem/estagios.txt` (10 mundos, com a agricultura em até 87 anos) é de antes desse ajuste e não vale mais para a agricultura.
- **A ausência:** `jogo/ferramentas_sim/equilibrio/LEIAME.md` (20 mundos, um ano fora a partir de 4 momentos) e o cenário QA-176 do QA.

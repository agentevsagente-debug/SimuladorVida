# O equilíbrio de longo prazo, visto como jogador

*Sessão A (simulação), 01/11/2026.* Gerado por `ferramentas_sim/equilibrio.gd`, sem o deus:
- `estagio2-*.txt`: o estágio 2 em 60 mundos;
- `ausencia-*.txt`: um ano de ausência em 20 mundos, partindo de 4 momentos;
- `monotonia-*.txt`: as décadas de 3 mundos de 300 anos.

Cada arquivo tem uma linha por mundo ou por década; as colunas estão no começo de cada função do script.

## 1. O estágio 2 (a agricultura)

**Antes**, em 60 mundos (sementes 1 a 60, até 150 anos):
- a mediana já era de 21 anos;
- 5 mundos passavam de 60 anos: 65, 71, 72, 74 e 87;
- 3 mundos morriam antes de plantar.

Nos mundos lentos, alguém descobria a agricultura cedo (do ano 4 ao 17), e o saber não se espalhava:
- o único que sabia era desconfiado ou ambicioso e quase não ensinava;
- ou morria, e o povo esquecia;
- ou o povo era pequeno demais para a regra de "4 que sabem".

Exemplo, semente 30:
- uma pessoa sabia plantar dos anos 5 a 20 e não ensinou ninguém;
- uma fome levou o povo de 20 para 2 pessoas;
- a redescoberta só veio no ano 70.

**Mudanças:**
- **Pressa depois de 25 anos.** Depois de 25 anos no estágio 1 (`Mundo.ENSINO_DEMORA`), descobrir e ensinar ficam mais rápidos. A cada década a mais, a chance de antes é somada de novo: aos 35 anos, dobra; aos 45, triplica. Os mundos que chegam antes dos 25 anos, quase a metade, não mudam.
- **Redescoberta.** Quem já soube e esqueceu redescobre mais depressa: os velhos lembravam que se plantava.
- **Povo pequeno.** Basta que todos os adultos saibam quando são menos de 4.

**Depois**, nas mesmas 60 sementes (com os estranhos, item 3):

| Anos até a agricultura | Mundos |
|---|---|
| 1 a 10 | 3 |
| 11 a 20 | 21 |
| 21 a 30 | 16 |
| 31 a 40 | 16 |
| 41 a 50 | 4 |
| mais de 50 | 0 |
| não chegou em 150 anos | 0 |

- **Mediana:** 25 anos (meta: de 20 a 35).
- **90%:** até 38 anos.
- **Máximo:** 50 anos (meta: até 60).
- **Regredir continua possível:** 15 dos 60 mundos perderam o saber pelo caminho, quando morreram os que sabiam, e o reaprenderam.
- **Morrer:** nenhum dos 60 morreu antes de plantar. A extinção continua possível depois; ver o item 2.

## 2. A extinção por ausência

20 mundos (sementes 1 a 20), cada um parado nos anos 3, 25, 60 e 120. A partir de cada um desses pontos, um ano inteiro de ausência, que é o teto: uma semana real ou mais.

| Partida | Estágio mais alto, em geral | Voltam vivos depois de 1 ano fora |
|---|---|---|
| ano 3 | 1 | 20 de 20 |
| ano 25 | 1 ou 2 | 20 de 20 |
| ano 60 | 2 | 20 de 20 |
| ano 120 | 2 ou 3 | 19 de 19 (a semente 16 tinha morrido sozinha antes do ano 120) |

- **A população no ano de ausência:** varia de −24% a +17%, com mediana de +3%.
- **Quedas maiores:** as piores perdas foram de um povo de 10 que ficou com 8, e de um de 153 que ficou com 134.

**Resposta:** quem fica fora uma semana encontra o mundo vivo quase sempre.
- Em 79 anos de ausência, o mundo não morreu nenhuma vez.
- A extinção continua possível sem o jogador: a semente 16 morreu entre os anos 60 e 120. Na medida anterior, sem os estranhos, foram 2 de 20.
- Nos testes de resistência de 1000 anos, os fins do mundo vêm de guerra, fome e peste em sequência. É rara, mas tem motivo.

## 3. A monotonia nos séculos médios

Três mundos de 300 anos. Uma década conta como notável quando tem um marco ou uma crise que o jogador nota:
- separação, migração, peste, profeta, guerra, conquista;
- estágio ou regressão, descoberta, novo líder, costume, crença, secularização;
- expedição, édito, reforma, silêncio do deus, ruínas, estranhos.

Não contam as preces, as fomes de rotina nem as mortes comuns.

**Antes:**

| Semente | Décadas | Décadas vazias | Maior sequência com até 1 marco |
|---|---|---|---|
| 1 | 30 | 0 | 1 |
| 2 | 14 (o mundo acabou no ano 140) | 7 (anos 31 a 81, e 101) | 11 |
| 3 | 30 | 2 (anos 61 e 71) | 2 |

Na semente 2, uma peste no ano 20 deixou um resto de 7 pessoas. No ano 70, eram 2 homens e 5 mulheres, todos irmãos: ninguém podia casar. O povo definhou em silêncio por 110 anos e acabou.

**O motivo interno novo: estranhos de além da borda.**
- **Quando:** um povo com menos de 20 pessoas, sem nenhum casal fértil e sem nenhum par que possa casar.
- **O que acontece:**
  - a cada ano, há 22% de chance de chegarem 2 ou 3 jovens de além da borda do mundo, que ficam e trazem o sexo que falta (8% num povo desconfiado de estranhos);
  - evento `estranhos`, nota, com a crônica: «Vieram de além da borda três estranhos, magros e calados: Kaut, Mia e Dou. Esar os recebeu, e eles ficaram.»;
  - a lenda da borda passa a ter volta.

**Depois:**

| Semente | Décadas | Décadas vazias | Maior sequência com até 1 marco | Chegadas de estranhos | População no ano 300 |
|---|---|---|---|---|---|
| 1 | 30 | 0 | 1 | 2 | 250 |
| 2 | 30 | 3 (anos 31, 81 e 101) | 3 | 5 | 226 |
| 3 | 30 | 0 | 1 | 5 | 261 |

Os outros motivos pedidos já existiam e aparecem nas décadas dos três mundos:
- sucessão disputada ("Fulano queria o lugar e nunca perdoou");
- cisma do profeta;
- migração e separação;
- peste;
- descoberta técnica.

Fora o resto de um povo quase extinto, que agora é resgatado, os séculos médios não têm sequências longas sem nada.

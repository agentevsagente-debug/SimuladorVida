# Auditoria visual 7: os estágios 3 a 6 dentro do jogo

*Sessão C (arte), 01/11/2026. Feita sobre a main em `de7a3c1`. É a primeira vez que os estágios avançados são vistos dentro do jogo, como jogador. Até aqui, só as amostras da arte e as cenas montadas tinham sido vistas.*

## Como foi feito

**Os mundos.** Sondei 6 sementes até o ano 700, para saber quando cada uma chega a cada estágio. Só a semente 2 se extingue (no ano 138). Escolhi as sementes 3 e 7:

| Semente | Estágio 3 | Estágio 4 | Estágio 5 | Estágio 6 | Povos |
|---|---|---|---|---|---|
| 3 | ano 42 | 125 | 158 | 164 | 4 |
| 7 | 75 | 101 | 119 | 127 | 3 a 4 |

**As capturas** (`capturar7.sh`) foram feitas em 1x, nos anos em que cada estágio já se firmou:
- semente 3: anos 60, 140, 161, 250 e 500;
- semente 7: anos 90, 110, 122, 200 e 400.

Em cada ano, capturei 3 quadros às 10h, às 19h e às 22h, e 2 quadros no inverno.

**O que há em cada mundo** (povos, estágio, aparência, construções e ruínas) li do próprio núcleo, com um script de sondagem que não ficou no repositório.

**Antes e depois.** Para mostrar a arte nova desta entrega (veja "Arte corrigida"), liguei-a no jogo só para o teste, sem commit em `jogo/`, e capturei de novo três mundos (`depois_*`). Depois desfiz a ligação.

Ficaram 43 capturas em `capturas7/` (o primeiro quadro de cada uma), e os recortes estão em `recortes7/` (`recortar7.py`).

**O que há na tela, segundo o núcleo:**

| Mundo | Povos (estágio, pessoas) | Construções |
|---|---|---|
| S3, ano 140 | Viur (4, 77), Gaes (4, 26), Viem (3, 29), Loak (3, 7) | 3 casas, 2 templos de pedra (estágio 3), 2 roças, 1 celeiro, 4 fogueiras; 13 ruínas |
| S3, ano 161 | Viur (**5**, 82), Gaes (4), Viem (3), Loak (3) | Viur tem **só 1 casa e 1 fogueira**: nenhum arquivo, estela ou templo |
| S3, ano 250 | Viur (6, 88), Gaes (6), Viem (4), Loak (4) | 3 casas, 2 barcos, 2 templos de colunas (estágio 4), 1 forja |
| S3, ano 500 | 3 povos no estágio 6 (214 pessoas) e 1 no 2 | 3 casas, 2 moinhos, 2 muralhas, 1 barco, 2 roças; **nenhum templo** |
| S7, ano 122 | Toan (**5**, 88), Raon (4), Kail (3), Doum (3) | Toan tem só 1 casa e 1 fogueira |
| S7, ano 400 | 4 povos no estágio 6 (261 pessoas) | 3 casas, 2 moinhos, 2 muralhas, 2 barcos, 2 roças; **nenhum templo** |

## Notas por estágio

| Estágio | Nota | Por quê |
|---|---|---|
| **3, pedra** | **3** | Se distingue: a casa de pedra com telhado de telha e o templo em degraus, de pedra, leem de longe. A ruína do templo antigo, tomada pelo mato, conta a história (`ok_ruina_com_mato.png`). Mas cada povo tem 1 casa, e o povo andava com a roupa do estágio 1 (A1, corrigido). |
| **4, metal** | **3** | A casa de enxaimel (madeira aparente) se distingue bem da de pedra. A forja quase não aparece: só 1 em 4 mundos. Os templos da tela são os dos povos do estágio 3. A multidão na frente das casas (V1) é o que mais pesa. |
| **5, escrita** | **2** (com a arte nova: 3) | Não se distinguia do 4: o povo do estágio 5 usava a casa de enxaimel, e não ergue arquivo, estela nem templo de escrita, cuja arte existe e nunca aparece (E1). Agora tem a casa caiada própria (A2), mas sem o arquivo e o templo continua fraco. |
| **6, engenharia** | **3** | O mais rico de longe: moinhos girando, torres de muralha, barcos a vela no lago, casas de tijolo e, à noite, muitas fogueiras e janelas acesas (`estagio6_noite_e_inverno.png`). Mas não há templo (nem a cúpula) em nenhum dos dois mundos. As torres ficam soltas, sem muralha entre elas, e não há canal nem roda d'água. A multidão é a maior: 214 a 261 pessoas para 3 casas. |

**Resumo:** os estágios 3, 4 e 6 se distinguem de longe pelas construções. O 5 não se distinguia (agora tem a casa própria). As roupas quase não ajudavam, porque só as ações de 1x tinham a roupa do estágio (corrigido na arte).

O que mais tira a vida da vila nos estágios avançados não é a arte, é a escala: 80 a 100 pessoas por povo, 1 casa cada, e todos de pé numa fileira na frente das casas.

## Perguntas da ordem

| Pergunta | Resposta |
|---|---|
| **Cada estágio se distingue de longe?** | **Nas construções, sim**, menos o 5 (agora com a casa caiada). **Nas roupas, não:** só as ações de 1x tinham a roupa do estágio, então quem andava ou estava parado usava a do estágio 1 (A1, corrigido na arte; falta a B ligar). **Ferramentas:** a lança e as ações de 1x aparecem, a forja quase nunca. **Templo:** o do 3 e o do 4 aparecem; o do 5 (escrita) e o do 6 (cúpula), nunca (E1, E2). |
| **A vila parece viva ou um amontoado?** | **Um amontoado.** Com 4 povos e 140 a 260 pessoas para 3 ou 4 casas, a frente da vila vira uma faixa contínua de gente sobreposta, cobrindo as portas e as fogueiras (`V1_amontoado.png`). De noite e no inverno fica melhor, porque a cena é mais escura e as janelas acesas aparecem. |
| **As culturas diferentes se distinguem?** | **Pouco.** A partir do estágio 3, a parede é a do estágio, e a cultura só aparece no telhado e no símbolo do templo. Na semente 3, os 4 povos têm telhado de palha (só Gaes tem tábuas), e na 7, um povo tem telha vermelha e os outros palha. A roupa é a mesma cor em todos os povos de uma semente: turquesa na 3, lilás na 7. De longe, 4 povos parecem uma vila só (C1). |
| **As ruínas e a memória aparecem?** | **Sim, e bem.** A ruína do templo de pedra e da casa, com as trepadeiras crescendo, lê de longe e é o que mais dá a sensação de tempo (`ok_ruina_com_mato.png`). Em mundos mais velhos (S3, ano 500), as ruínas do arquivo e da forja existem no núcleo, mas não as vi na tela, cobertas pela multidão ou fora da faixa capturada. |

## Arte corrigida nesta entrega

### A1. As folhas de sempre dos habitantes sem a roupa do estágio (alto) — C, corrigido; falta a B ligar
`recortes7/antes_depois_roupas_estagio6.png`

- **O que estava errado:** a roupa do estágio só existia nas ações de 1x, nas brincadeiras, na caçada e na pesca. As folhas que ficam mais tempo na tela tinham só a versão do estágio 1, com outro nome (`adulto_eN_*`):
  - `adulto_a/b_andar`;
  - `adulto_a/b_parado`;
  - `rezar`, `colher` e `sentado`;
  - a criança e o idoso.

  Num povo do estágio 6, só quem cata lenha ou caça tinha chapéu.
- **Correção:** as 9 folhas de sempre agora saem com a roupa dos estágios 3 a 6 e com a de inverno, com o mesmo nome em `estagioN/` (`acoes/vestir_estagios.py`, LEIA-ME seção 25).
- **Falta a B:** acrescentar os 9 nomes à lista `COM_ROUPA_DO_ESTAGIO` de `vida.gd`, e os 5 da pesca (`pescar_espreitar_forte_2q`, `pescar_arpoar_forte_4q`, `carregar_peixe_forte_4q`, `lavar_margem_forte_4q` e `crianca_banho_4q`). Testei com a lista ampliada: o chapéu e as calças aparecem em todos.

### A2. O estágio 5 sem casa própria (alto) — C, corrigido; falta a B ligar
`recortes7/casas_dos_estagios.png` e `antes_depois_casa_caiada_e_roupas.png`

- **O que estava errado:** o estágio 5 usava a `casa_enxaimel` do 4 (`CASAS` em `vista.gd` e `PECAS` em `obras.gd`). Como o povo do estágio 5 não ergue mais nada além da casa (E1), ele ficava igual ao 4.
- **Correção:** a `estagio5/casa_caiada` tem:
  - paredes caiadas, brancas;
  - cunhais de pedra nos cantos e rodapé ocre;
  - o friso escrito da biblioteca sob o telhado;
  - porta em arco e janelas com postigos.

  Ela vem com os 3 telhados de cultura, a camada de luz, a chaminé (`chamines.json`), a ruína, o mato sobre a ruína e o inverno. O tamanho e o encaixe são os da casa de enxaimel (LEIA-ME seção 11).
- **Falta a B:**
  - `vista.gd`: `CASAS[5] = "estagio5/casa_caiada"`;
  - `obras.gd`: `PECAS["cabana"][5]`, `CAMADAS_CULTURA["cabana"][5]` (com `casa_caiada_parede` e `casa_caiada_telhado_{t}`) e a ruína em `RUINAS`.

  Testei assim: as casas do estágio 5 ficam brancas e se separam das de enxaimel à primeira vista.

## Defeitos para a A e a B

### V1. A vila é um amontoado (alto) — A e B
`recortes7/V1_amontoado.png`

- **O que está errado:**
  - Cada povo tem 1 casa (`cabana`), seja com 7 pessoas, seja com 100.
  - Com 3 ou 4 povos na mesma faixa de 480 px, ficam de 140 a 260 pessoas para 3 ou 4 casas.
  - De dia, todos ficam de pé numa fileira contínua na frente das casas, sobrepostos, cobrindo as portas, as fogueiras e as roças.
- **O que deveria ser:**
  - **A:** o número de casas acompanha o povo, por exemplo 1 casa para cada 8 a 12 pessoas, até onde a faixa couber.
  - **B:**
    - não desenhar todo mundo de uma vez: parte do povo está dentro de casa, na roça, no lago ou no morro;
    - limitar quem fica parado na frente da vila, por exemplo a umas 2 ou 3 pessoas por casa;
    - espalhar o resto pelas zonas.

  Com 30 a 50 pessoas visíveis, a vila do estágio 6 seria a mais bonita do jogo.

### E1. O estágio 5 não ergue nada próprio (alto) — A
- **O que está errado:** os povos que chegam ao 5 (Viur, na semente 3, e Toan, na 7) têm só 1 casa e 1 fogueira. Não erguem:
  - o arquivo (`biblioteca`);
  - o templo de escrita;
  - a estela.

  A ruína de um arquivo aparece no ano 500, então o tipo existe, mas é raro. A arte do estágio 5 (biblioteca, templo de escrita, estela, tabuletas e escriba) quase nunca chega à tela.
- **O que deveria ser:** ao chegar ao estágio 5, o povo ergue o arquivo nos primeiros anos, e o templo do povo passa a ser o de escrita. A estela pode marcar um acontecimento, como um líder morto ou uma lei.

### E2. Nenhum templo nos estágios 5 e 6, e o 6 sem a sua arte maior (médio) — A
- **O que está errado:**
  - Nos mundos de 400 e 500 anos, todos no estágio 6, não há templo nenhum.
  - Os templos de colunas do ano 250 são dos povos do estágio 4.
  - A `templo_cupula`, o `canal`, a `roca_irrigada` e a `roda_dagua` nunca aparecem.
  - A muralha aparece só como torres soltas.
- **O que deveria ser:**
  - o templo acompanha o estágio do povo: ao subir, o povo reconstrói o templo no estilo novo;
  - no 6, pelo menos 1 canal ou roda d'água na roça perto do lago;
  - a muralha com o trecho de muro entre 2 torres.

### C1. As culturas quase não se distinguem (médio) — A, com a C se for preciso
- **O que está errado:** do estágio 3 em diante, a parede é a do estágio, e a cultura fica só no telhado e no símbolo.
  - A derivação de povos muda uma coisa de cada vez. Por isso, numa semente, quase todos têm o mesmo telhado (palha) e a mesma roupa (turquesa ou lilás).
  - Sem templo nos estágios altos (E2), o símbolo também some.
  - De longe, 4 povos parecem uma vila só.
- **O que deveria ser:**
  - **A:** a aparência do povo novo mudar 2 coisas, e a roupa entrar mais vezes no sorteio;
  - **B:** um vão de alguns pixels entre as vilas de povos diferentes, para cada uma ler como um lugar.
- **A C pode fazer**, se a A e a B quiserem: um estandarte de 4 × 8 por povo, no alto da casa principal, na cor da roupa e com o símbolo do templo. Ele marcaria cada vila mesmo sem templo.

### E4. As baforadas de fumaça continuam altas no céu (baixo) — B
É o E4 da auditoria 3b, ainda aberto. Em todos os estágios, de dia, de 3 a 6 baforadas cinzas ficam inteiras uns 15 a 25 px acima da vila e leem como pássaros parados no céu (`estagios_semente3.png`).

## Resumo por responsável

| Quem | Itens |
|---|---|
| C (arte) | **A1** e **A2** corrigidos: as roupas dos estágios nas 9 folhas de sempre e a casa caiada do estágio 5, com o inverno, a luz, a chaminé, a ruína e o mato. A2 e A1 estão no LEIA-ME (seções 11, 19 e 25), com os atlas regenerados. Se quiserem, o estandarte por povo (C1). |
| B (apresentação) | **ligar A1 e A2** (listas em `vida.gd`, `vista.gd` e `obras.gd`), **V1** (quantos aparecem e onde), o vão entre as vilas (C1), E4 |
| A (simulação) | **V1** (casas pelo tamanho do povo), **E1** (o arquivo e o templo de escrita no estágio 5), **E2** (templo acompanha o estágio, canal ou roda d'água e muro da muralha no 6), C1 (aparência mais variada) |

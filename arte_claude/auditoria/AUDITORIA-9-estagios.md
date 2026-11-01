# Auditoria 9: os estágios 3 a 6 com tudo ligado

*Sessão C (arte), 01/11/2026. Feita sobre a main em `7c70435`. Ela refaz as notas da auditoria 7 com as peças ligadas pela B (as roupas, a casa caiada, a fileira de trás, o arquivo, a estela, a roda d'água, a muralha e o estandarte) e com o equilíbrio novo da A. O roteiro está em `AUDITORIA-9-roteiro.md`. A meta era nenhum estágio abaixo de 4.*

## Como foi feito

**Os mundos.** O equilíbrio novo mudou os anos dos estágios, então sondei de novo:

| Semente | Estágio 3 | Estágio 4 | Estágio 5 | Estágio 6 |
|---|---|---|---|---|
| 3 | ano 42 | 68 | 112 | 128 |
| 7 | 75 | 109 | 165 | 166 |
| 1 | — | — | 102 | 130 |

Na semente 7, o estágio 5 dura um ano só, por isso entrou a semente 1.

**Os anos capturados** (`capturar9.sh`):
- semente 3: 55, 90, 120, 200 e 400;
- semente 7: 90, 130 e 250;
- semente 1: 115 e 300.

Em cada ano, capturei 10h, 19h, 22h e o inverno, mais 1 min de tarde em 1x por estágio.

**O núcleo.** A sondagem (`sondar_estagios9.gd`) está em `capturas9/sondagem_nucleo.txt`. Ficaram 51 capturas em `capturas9/` e os recortes em `recortes9/` (`recortar9.py`). Os de "antes e depois" comparam com `capturas7/`.

## Notas por estágio

| Estágio | Aud. 7 | **Aud. 9** | Por quê |
|---|---|---|---|
| **3, pedra** | 3 | **4** | As casas de pedra em fileira, com o telhado da cultura, o templo em degraus, as roças e o estandarte na cumeeira de cada povo. Já lê como vila, não como uma casa só (`estagios_semente3.png`, linha 1). |
| **4, metal** | 3 | **4** | O enxaimel, o templo de colunas e a forja aparecem (o Peak, ano 120). Os estandartes separam os povos. Há o capacete de quem trabalha. |
| **5, escrita** | 2 | **4** | Era o estágio que não existia; agora é o que mais mudou (`antes_e_depois_estagio5.png`). As casas caiadas com o friso escrito, o templo de escrita, o arquivo com as estantes e a estela, e o estandarte lilás. Na semente 1 (Sagak, ano 115) estão as quatro peças juntas. |
| **6, engenharia** | 3 | **5** | O mais bonito do jogo (`antes_e_depois_estagio6.png` e `ok_estagio6_cupula_moinho_muralha.png`): casas de tijolo, o templo de cúpula, moinhos girando, torres com o muro entre elas, a roda d'água, barcos no lago, e o povo de chapéu. De noite, as janelas acesas e as fogueiras; no inverno, a neve nos telhados (`noite_e_inverno.png`). |

**A meta foi atingida:** nenhum estágio ficou abaixo de 4. A soma foi de 11 para 17.

## O que mudou desde a auditoria 7

| # | Item da auditoria 7 | Situação |
|---|---|---|
| A1 | roupas dos estágios nas folhas de sempre | **corrigido**: o povo todo com a roupa do estágio. No 6, ajustei o chapéu (A9, abaixo). |
| A2 | a casa caiada do estágio 5 | **corrigido** e ligado |
| V1 | a vila amontoada | **melhorou muito**: a fileira de trás e as casas em fila tiram a multidão da frente. Sobra uma faixa de gente na frente das casas da esquerda, mas as portas e as fogueiras aparecem. No núcleo, os povos maiores ainda têm uma `cabana` só (Koil com 84 pessoas, Raon com 102, Zeor com 104). A tela compensa, mas a conta da A continua lá. |
| E1 | o estágio 5 sem obra própria | **corrigido**: o templo de escrita, a estela e o arquivo aparecem (o arquivo ainda é raro: só o Sagak tinha) |
| E2 | o estágio 6 sem templo, canal ou muro | **corrigido**: a cúpula, a roda d'água, o moinho e o muro entre as torres |
| C1 | as culturas iguais | **melhorou**: o estandarte de cada povo, na cor da roupa e com o símbolo, separa as vilas à primeira vista. Os telhados ainda são quase todos de telha nas sementes 3 e 7. |
| E4 | as baforadas no céu | **melhorou**: menores e mais baixas. De vez em quando, uma fica parada perto do moinho. |

## Arte corrigida nesta auditoria

### A9. O povo do estágio 6 virava uma faixa marrom (médio) — C, corrigido
`recortes9/A9_chapeu_de_palha_antes_depois.png`

- **O que estava errado:** o chapéu marrom, de aba larga, e as calças marrons se juntavam com os vizinhos e com o chão de terra. Numa roda de gente sentada perto do fogo, o povo virava uma faixa marrom.
- **Correção:**
  - o chapéu passou a ser de palha (16), com a aba clara (12) de 1 px de cada lado;
  - as calças passaram a azul-escuro (17 e 4).

  As 30 folhas foram regeneradas com a roupa do estágio 6 e a de inverno (`acoes/vestir_estagios.py`). Conferi no jogo, com as peças ligadas só para o teste: os chapéus de palha se separam um do outro e do chão.
- **Falta a B:** copiar as folhas novas de `estagio6/` e de `estacoes/inverno/estagio6/`.

## O que fica

| # | Item | Quem |
|---|---|---|
| V1 | a conta de casas no núcleo: os povos de 80 a 100 pessoas com uma `cabana` só | A |
| E5 | o estágio 5 dura um ano na semente 7 (165 para 166): o jogador quase não o vê. Um mínimo de uns 20 a 30 anos em cada estágio daria tempo para o arquivo e o templo de escrita aparecerem. | A |
| C1 | os telhados quase todos de telha numa semente; o estandarte já resolve a leitura das vilas | A, se quiser |
| E4 | uma baforada parada de vez em quando | B |
| A9 | copiar as folhas novas do estágio 6 | B |

**O que falta para os estágios 3, 4 e 5 irem a 5:**
- **3:** um pouco mais de vida perto do templo em degraus (oferendas, gente rezando), que hoje fica quieto.
- **4:** a forja trabalhando com faíscas e o ferreiro, mais vezes na tela.
- **5:** o arquivo em todo povo do estágio 5, com alguém escrevendo à porta (`escriba_sentado_2q` já existe), e o estágio durando mais (E5).

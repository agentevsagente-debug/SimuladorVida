# API do núcleo da simulação

*Versão 10, de 01/11/2026 (sem picos: a rotina do dia é montada numa thread; nenhum passo acima de 5 ms e nenhuma consulta acima de 2 ms com a população máxima; `adiantar_rotina()` não é mais preciso; lugares de descanso sem fila; construções e ruínas com a cultura; cópias de segurança do mundo salvo e da estante). Antes: versão 9 (desempenho da rotina: respostas guardadas por hora e `adiantar_rotina()`). Antes: versão 8 (rotina rica e cenas: o plano do dia de cada pessoa, 11 ações novas, `agenda`, `virado`, `cena` e `cenas_ativas()`). Antes: versão 7 (qualidade de longo prazo: textos curtos para a moldura, peste, profetas, secularização, revoltas). Antes: versão 6 (fase 2: os 11 poderes, estágios 3 a 6, ruínas, fim do mundo e eras, estante, 6 dimensões culturais). Desde a versão 1, só houve acréscimos. A única mudança de comportamento: `cronica()` agora começa, por padrão, no início da era atual, o que dá o mesmo resultado na primeira era. Dona: sessão A. Mudanças que quebrem esta API serão avisadas ao orquestrador antes.*

O núcleo é GDScript puro. Não tem nós nem cenas, e não desenha nada. A apresentação faz duas coisas:
- **lê** o estado e os eventos pelas funções abaixo;
- **age** só por `avancar_hora()`, `usar_poder()` e `acompanhar()`.

Para salvar, carregar e avançar a ausência, use `nucleo/persistencia.gd` (seção "Salvar, carregar e ausência").

## Começar

```gdscript
const Mundo = preload("res://nucleo/mundo.gd")

var mundo := Mundo.new(semente)          # semente: int; mesma semente, mesmo mundo
```

O mundo nasce com o primeiro povo: 12 coletores na floresta, no ano 1, dia 1, hora 0. A pessoa acompanhada começa sendo a matriarca.

## Tempo

| Chamada | Retorno |
|---|---|
| `avancar_hora()` | Avança um passo (1 hora de jogo). É a única forma de o tempo andar. No ritmo normal (um dia de jogo em 45 minutos reais), um passo a cada 112,5 s (`Mundo.SEGUNDOS_POR_PASSO`). |
| `avancar_dias(n)` | Avança `n × 24` passos de uma vez (para saltos). |
| `tempo()` | `{passo, hora (0..23), dia (1..40), ano (1..), estacao ("primavera", "verão", "outono", "inverno"), noite (bool: hora ≥ 20 ou < 6)}` |
| `clima()` | `{seca: bool, inverno_rigoroso: bool, tempestade: {} ou {zona, x_ini, x_fim}}`. A tempestade só aparece nas horas em que está caindo. |

A apresentação interpola os movimentos entre dois passos. Cada pessoa traz a posição do passo atual (`x`) e a do anterior (`x_anterior`). Basta ir de uma à outra durante o intervalo entre passos.

## Espaço

O mundo tem **480 pixels de largura**, e todo `x` está nessa escala (0 a 479). As zonas ocupam faixas fixas, casadas com a arte da cena-alvo, da esquerda para a direita:

| Zona | x_ini | x_fim | O que é |
|---|---|---|---|
| lago | 0 | 136 | a água |
| praia | 136 | 200 | areia e capim seco |
| floresta | 200 | 330 | clareira e mata |
| morro | 330 | 480 | |

**Ninguém fica dentro da água.** Toda pessoa está sempre em `x ≥ 126`.
- O povo que vive no lago acampa na margem e na areia próxima (126 a 168).
- Esse povo trabalha na margem (126 a 136): a ação `colher`, ali, é pescar ou buscar água.
- Se dois povos dividem uma zona, o acampamento dela é repartido entre eles (veja `grupos_visiveis()`).

As faixas estão em `nucleo/cotidiano.gd` (`FAIXAS`, `ACAMPAMENTO`, `TRABALHO`, `MARGEM`). A simulação não depende delas.

A altura (y) é da apresentação. O núcleo não sabe de chão nem de céu.

## Estado legível

Todas as consultas abaixo são **puras**: não mudam o mundo, não consomem sorteio e podem ser chamadas quantas vezes for preciso. As posições não são sorteadas a cada hora. Saem de uma rotina fixa por pessoa, então uma consulta repetida dá sempre a mesma resposta. Uma consulta completa (pessoas, construções e preces) custa cerca de 0,2 ms com 14 pessoas, crescendo em linha reta com a população. O ideal é chamá-la uma vez por passo e guardar o resultado.

### `zonas_visiveis() -> Array[Dictionary]`

| Campo | Tipo | O que é |
|---|---|---|
| `chave` | String | "praia", "lago", "floresta" ou "morro" |
| `nome` | String | nome comum ("praia") |
| `x_ini`, `x_fim` | int | faixa da zona |
| `agua` | float 0..1 | baixa na seca (o lago nunca seca de todo) |
| `comida` | float 0..2 | fartura em relação ao normal (1 = cheia; acima de 1 = fartura) |
| `seca` | bool | a zona está em seca |
| `queimada` | bool | o fogo do deus passou por ali há pouco (para desenhar cinzas) |
| `alagada` | bool | o dilúvio ainda cobre a zona (de 4 a 14 dias, conforme a intensidade) |
| `pedra_erguida`, `pedra_x` | bool, float | a terra foi erguida ali, e onde |
| `nomes` | Dictionary | id do grupo → nome que esse povo deu ao lugar ("Lago do Raio") |

### `grupos_visiveis() -> Array[Dictionary]` (só os vivos)

| Campo | O que é |
|---|---|
| `id`, `nome` | identificador e nome do povo ("Zeor") |
| `zona`, `x_ini`, `x_fim` | onde vive; `x_ini` e `x_fim` são a faixa do acampamento. Se dois povos dividem uma zona, cada um fica com uma parte. |
| `membros`, `estagio` | quantas pessoas; estágio 1 = coleta, 2 = agricultura, 3 = pedra, 4 = metal, 5 = escrita, 6 = engenharia |
| `lider`, `sacerdote` | id da pessoa, ou -1 |
| `nome_deus` | como o povo chama o deus («o Que Rega»); vazio se ainda não crê ou se é cético. Um nome novo (crença, rebatismo, profeta, cisma) nunca é o de outro povo vivo; só os povos que se separaram de um mesmo povo e levaram a fé junto chamam o deus do mesmo jeito. |
| `ceticos` | o povo deixou de rezar |
| `em_fome`, `doenca` | estados atuais |
| `costumes` | lista de chaves: "estocar", "agua", "festa_chuva", "tabu_tempestade", "queimar_mortos", "lancas", "oferendas" |
| `cultura` | as 6 dimensões culturais, como palavras: `deus` ("devota", "temerosa", "cetica" ou "" se ainda não crê), `estranhos` ("acolhedora", "desconfiada"), `poder` ("lider", "conselho", "sacerdotes"), `recursos` ("partilha", "acumula"), `violencia` ("pacifica", "guerreira"), `mortos` ("enterram", "queimam", "veneram" ou "") |
| `aparencia` | `{parede, telhado, simbolo, roupa}`, para escolher as peças de `arte_claude/pecas/culturas/` e dos estágios: parede "taipa", "pedra" ou "madeira"; telhado "palha", "telha" ou "tabuas"; símbolo "sol", "lua" ou "arvore"; roupa "turquesa", "lilas" ou "rosa". Sai do nome do povo (não sorteia nada); um povo novo herda a do povo de onde saiu e muda duas coisas (a roupa, que se vê de longe, tem o dobro da chance de mudar). |
| `escreve` | o povo chegou à escrita e tem a própria crônica (`cronica_do_povo`) |
| `origem` | `{}` para o povo original, ou `{pai, causa ("migracao", "briga", "cisma"), ano, evento}` |
| `estranhos` | float de -1 (desconfia de quem vem de fora) a 1 (acolhe). Muda com casamentos entre povos e com ataques. |
| `mortos` | o que o povo faz com os mortos: "enterram", "queimam", "veneram", ou "" se ainda não decidiu |
| `dependente` | o povo deixou de se preparar porque o deus sempre respondeu (para mostrar celeiros vazios) |

### `guerras_ativas() -> Array[Dictionary]`

Guerras em andamento que já têm nome. Uma briga só vira guerra na segunda batalha.

| Campo | O que é |
|---|---|
| `id`, `nome` | "Guerra da Fome", "Guerra Santa", "Guerra dos Irmãos", "Guerra do Lago", "Segunda Guerra Santa"... |
| `a`, `b` | ids dos povos, com `a` o que atacou primeiro |
| `motivo` | "fome", "santa" (sacerdote proibiu o trato), "terra" (mesma zona), "irmaos" (um povo nasceu do outro), "rancor" |
| `inicio`, `batalhas`, `mortos` | ano em que começou, e o saldo até agora |

### `construcoes() -> Array[Dictionary]`

`{tipo, x, largura, grupo, estagio, aparencia, ruina, fileira}`, com `x` no centro da peça. `fileira` é 0 (a fileira da frente) ou 1 (a fileira de trás: casas que não couberam na frente; ficam atrás das peças da frente, podendo cruzar com elas em x, e a apresentação as desenha mais altas e por trás). `estagio` é o estágio do povo e diz qual arte usar (a casa do estágio 3 é `casa_pedra`, a do 4 é `casa_enxaimel`, e assim por diante). `aparencia` é a cultura do povo, a mesma de `grupos_visiveis()`: `{parede, telhado, simbolo, roupa}`, para escolher as variações de `arte_claude/pecas/culturas/`. `ruina` é sempre false aqui. Tipos:

| Tipo | Largura | Quando existe |
|---|---|---|
| `fogueira` | 8 | sempre, no centro do acampamento |
| `altar` | 8 | o povo crê (e não é cético) |
| `templo` | 32 | o povo está no estágio 2 ou mais e crê, ou já creu (o templo acompanha o estágio: degraus no 3, colunas no 4, escrita no 5, cúpula no 6; quando o povo sobe, o templo é o do estágio novo). `abandonado: true` quando o povo deixou de rezar: o templo fica de pé, vazio |
| `cabana` | 16, 24 ou 32 | as moradias: cabana no estágio 1 (16), casa de taipa no 2 (24), casas maiores do 3 em diante (32). Do estágio 3 em diante, uma casa para cada 10 pessoas (até as que o povo ergueu); as que não cabem na frente vão para a fileira de trás (`fileira`: 1), se couberem |
| `estela` | 6 | estágio 5 ou mais: uma pedra que marca um acontecimento do povo, o último entre a chegada ao estágio, um édito, o fim de uma guerra, uma conquista, um novo líder, uma reforma, um costume, um lugar com nome ou o arquivo que salvou um saber. `evento`: o id; `texto`: a frase curta dele ("Acaba a Terceira Guerra da Fome", "Ulyora guia Raon") |
| `roda_dagua` | 16 | estágio 6: a roda d'água na ponta da faixa do lado do lago |
| `celeiro` | 24 | estágio 2 ou mais, se o povo tem o costume de estocar |
| `roca` | 16 | estágio 2 ou mais, uma para cada ~6 adultos, até 4; `irrigada: true` no estágio 6 (canal ao lado) |
| `forja` | 24 | estágio 4 ou mais |
| `arquivo` | 32 | estágio 5 ou mais (a biblioteca da arte) |
| `moinho` | 32 | estágio 6 |
| `muralha` | 28 | estágio 6, povo guerreiro: em cada ponta do acampamento, um trecho de muro entre duas torres (`torres`: 2) |
| `barco` | 24 | estágio 6, povo do lago ou da praia: na água, em x = 112 − 28·k (um barco por povo da margem) |

**Os lotes.** Cada povo tem uma faixa de terra própria, e as peças vão para o primeiro lugar livre perto da fogueira, numa ordem fixa. Só mudam de lugar quando o número de peças muda, quando a faixa muda ou quando o povo se muda.
- **A faixa.** Os povos de uma zona dividem a terra dela conforme o porte: 1 parte até 39 pessoas, 2 de 40 a 99 e 3 de 100 em diante (em degraus, para que a vila não escorregue a cada nascimento). O lago e a praia dividem juntos a terra de 126 a 200, com o povo do lago à esquerda. Numa faixa com menos de 110 px, a fogueira vai para a ponta do lado da água (8 px da beira), para sobrar terra inteira do outro lado.
- **A ordem.** Fogueira; nos estágios 1 e 2, a primeira casa; o templo de quem crê (ou o altar, se não há templo); a obra do estágio (roda d'água e moinho no 6, arquivo no 5, forja no 4); o templo abandonado; a estela; do estágio 3 em diante, a primeira casa; a segunda casa; o altar; o arquivo (no 6); a forja (no 5 e no 6); o celeiro; as roças; e as outras casas. As casas que não cabem na frente vão para trás.
- **Nenhuma peça encosta em outra** (ficam a 2 px no mínimo) nem sai da faixa: o que não cabe fica de fora, a começar pelo fim da ordem. **Isto muda uma regra anterior**: o altar, o templo, o arquivo e a forja não aparecem mais "mesmo encostados"; com pouca terra, podem faltar.
- **As muralhas** só ocupam as pontas quando a faixa tem 140 px ou mais.
- **O limite da terra.** Com a fogueira no meio, uma faixa de 130 px (a floresta) tem lugar na frente para duas peças grandes, uma de cada lado. Nos mundos de 200 a 400 anos (sementes 3 e 7): o povo da floresta no estágio 6 fica com a roda d'água, o moinho, o templo abandonado e a estela na frente, e 3 casas atrás; o do morro no 5, com o templo, o arquivo, a estela, o altar e 2 roças na frente, e 3 casas atrás; o do lago (50 a 56 px), com a roda d'água, a estela e 1 casa na frente, e 1 atrás, com o barco na água; o da praia (18 a 25 px), só com a fogueira e a estela (ou o altar).

### `ruinas_visiveis() -> Array[Dictionary]`

Construções abandonadas, de povos que acabaram, se mudaram ou foram conquistados, inclusive de eras anteriores: `{tipo, x, largura, estagio, povo, era, ano, anos, aparencia, ruina: true}`. `anos` é a idade da ruína, para cobrir de mato.
- **Casas vazias de um povo vivo.** Quando um povo perde gente e, com isso, casas (e não quando a faixa encolhe porque um vizinho cresceu), as que ficaram vazias aparecem aqui também, com `abandonada: true` e `anos` (há quantos anos estão vazias, para o mato crescer). São as casas das pontas da vila, nunca as do meio. Somem como as outras ruínas (30 anos nos estágios 1 e 2, 200 da pedra em diante), ou quando uma peça viva passa a ocupar o lugar.
- Uma ruína que fica embaixo de uma peça viva (de um povo que se mudou para cima dela) não aparece: só a peça viva.
- A natureza retoma o espaço: ruínas dos estágios 1 e 2 somem em 30 anos; as de pedra em diante, em 200.
- Ruínas guardam conhecimento: um povo que vive perto pode aprender nelas o saber seguinte (evento `ruinas_saber`).

### `pessoas_visiveis() -> Array[Dictionary]` (só as vivas)

| Campo | O que é |
|---|---|
| `id`, `nome`, `sexo` ("m"/"f"), `idade`, `crianca` (idade < 12) | quem é |
| `grupo` | id do povo |
| `x_anterior`, `x` | posição no **começo** e no **fim** desta hora |
| `acao` | a ação no meio da hora (lista abaixo) |
| `virado` | para onde olha no meio da hora: -1 (esquerda), 1 (direita) ou 0 (tanto faz). Andando, é o sentido da caminhada; conversando, lutando ou dançando, é para o outro. |
| `cena` | `{tipo, id}` se a pessoa está numa cena no meio da hora; `{}` se não |
| `detalhe` | o que a pessoa faz, em detalhe, no meio da hora, dentro da `acao` (lista abaixo); "" quando não há |
| `agenda` | os trechos da hora, em detalhe (abaixo). É o que dá vida ao cotidiano. |
| `papel` | "lider", "sacerdote" ou "" |
| `tracos` | dois de: ambicioso, pacifico, rancoroso, curioso, devoto, desconfiado, generoso, engenhoso, corajoso, medroso |
| `doente`, `gravida` | estados atuais |
| `acompanhada` | é a pessoa acompanhada pelo jogador |
| `pai`, `mae`, `conjuge` | ids, ou -1 |

**A agenda da hora.** Uma hora de jogo dura 112,5 s no ritmo normal, e ninguém fica a hora toda parado num ponto: a pessoa anda entre arbustos, vai pescar, traz lenha, conversa. `agenda` é a lista dos trechos da hora, em ordem:

```
{de, ate, x0, x1, acao, virado, cena, detalhe}
```

- `de` e `ate` vão de 0 a 1, a fração da hora;
- se `x0 != x1`, a pessoa anda de `x0` a `x1` nesse trecho, com a ação de caminhada (`andar`, `lenha`, `carregar_morto`, `carregar_caca`, `brincar` correndo, ou `remar` indo para o barco);
- se `x0 == x1`, ela fica ali fazendo a `acao`;
- `detalhe` diz o que exatamente ela faz (ou leva, andando); "" quando não há. A `acao` continua sendo a genérica: quem não usar o `detalhe` vê o mesmo de antes.

Para animar: guarde a agenda ao começar a hora e, a cada quadro, ache o trecho da fração corrente e interpole `x` entre `x0` e `x1`. Os trechos vêm colados (o `ate` de um é o `de` do seguinte), e o último termina em 1. O primeiro trecho começa no `x_anterior`, e o último termina no `x`. Das 7h às 16h, há em média de 4 a 5 trechos por pessoa por hora.

**Ações** (todas casam com `arte_claude/pecas/acoes/` ou com os habitantes):

| Ação | Quando |
|---|---|
| `dormir` | à noite, em casa; doentes, de dia também |
| `andar` | caminhando entre dois pontos |
| `parado` | pausa curta, espera, olhar a borda do mundo; em casa durante tempestade |
| `colher` | coletar em arbustos, trabalhar na roça, cortar lenha na mata, colher na colheita |
| `pescar` | na margem do lago, olhando para a água (à esquerda) |
| `lenha` | caminhando com carga: lenha da mata, colheita para o celeiro, mudança na migração |
| `construir` | martelando numa casa ou na obra nova (os engenhosos mais que os outros) |
| `forjar` | na forja, estágio 4 em diante, quem sabe o metal |
| `escrever` | no arquivo, estágio 5 em diante, escribas, curiosos e sacerdotes |
| `remar` | no barco, estágio 6, povos do lago e da praia. Única ação permitida na água (x < 126). |
| `rezar` | no altar: o sacerdote de manhã e ao entardecer, quem tem prece aberta, os devotos, a prece coletiva e o funeral |
| `fogueira` | sentado em volta do fogo à noite, olhando para ele (`virado`); os velhos passam boa parte do dia ali |
| `conversar` | em pares, um de frente para o outro (`virado` oposto), no almoço e à noite; o líder visitando quem trabalha; visitas ao recém-nascido |
| `cuidar` | mãe com bebê, perto de casa |
| `dancar` | casamentos e festas, em volta do fogo |
| `lutar` | guerra: as duas linhas frente a frente |
| `carregar_morto` | os dois primeiros do cortejo do funeral |
| `cacar` | na caçada, longe do acampamento, de ponto em ponto |
| `carregar_caca` | andando de volta da caçada com a caça |
| `brincar` | crianças brincando, na praia ou perto do fogo; também andando (correndo uma atrás da outra) |
| `deitar` | descansando deitado à sombra: uma pausa no trabalho, ou o fim de tarde em casa |
| `tecer` | tecendo cesto, em casa (adultos no fim de tarde, os velhos de dia) |
| `consertar` | consertando uma ferramenta, em casa |
| `cozinhar` | preparando o jantar perto do fogo, das 17h30 às 19h |
| `comer` | jantando perto do fogo (as crianças comem depois dos grandes) |

**Detalhes** (campo `detalhe`, nos trechos da agenda e na ficha):

| Detalhe | Dentro de | O que é |
|---|---|---|
| `colher_arbusto`, `cavar_raiz` | `colher` | coleta: frutas e folhas nos arbustos, ou raízes cavadas no chão |
| `catar_lenha` | `colher` | lenha na mata |
| `colher_roca` | `colher` | trabalho na roça |
| `carregar_cesto`, `carregar_agua` | `lenha` (andando) | a volta com a carga: cesto cheio, ou água do lago |
| `levar_cesto`, `levar_vara`, `levar_machado`, `levar_pote`, `levar_lanca` | `andar` | a ida ao trabalho com a ferramenta: cesto (coleta), vara (pesca), machado (lenha, obra, forja), pote (água), lança (caçada) |
| `buscar_agua`, `banho` | `parado` | na margem do lago |
| `guardar` | `parado` | guardando a carga em casa ou no celeiro |
| `descansar` | `deitar` | a pausa à sombra no meio do trabalho |
| `cozinhar`, `comer` | `cozinhar`, `comer` | o jantar, das 17h30 às 19h |
| `brincar` | `brincar` | crianças brincando, na praia ou perto do fogo |
| `ninar` | `cuidar` | depois do jantar, quem tem filho pequeno nina em casa |
| `vigia` | `fogueira`, `parado` | o vigia da noite: sentado no fogo, ou de pé na beira do acampamento |
| `olhar_ceu` | `conversar` | um casal olhando o céu à noite |
| `reza_noturna` | `rezar` | quem reza tarde da noite |
| `historias` | `conversar` | a roda de histórias à noite |
| `doente` | `parado` | o doente acordado em casa |
| `repartir`, `maos_vazias` | `parado` | a volta da caçada: repartindo a caça, ou sem nada |
| `brigar`, `separar`, `machucado`, `espantar`, `perdido`, `buscar`, `discutir` | `parado`, `conversar` | os pequenos incidentes (veja as cenas) |
| `carregar_feixe` | `lenha` (andando) | a volta da mata com um feixe grande de lenha nas costas |
| `carregar_cesto_cabeca` | `lenha` (andando) | a volta com um cesto grande na cabeça (da praia ou de longe) |
| `espreitar` | `cacar` | a caçada: agachado, chegando aos poucos perto do porco, com a lança |
| `mirar` | `cacar` | a caçada: quem vai arremessar, parado um instante com a lança erguida (o quadro 1 de `cacar_arremessar`), antes de soltar |
| `arremessar` | `cacar` | a caçada: o arremesso da lança |
| `apontar` | `cacar` | a caçada: os que ficam para trás apontam o porco enquanto o da frente mira e arremessa (`cacar_apontar_2q`) |
| `espeto` | `cozinhar` | no fogo, quem espera a caça com o espeto (no lugar de mexer a panela) |
| `pescar_lanca` | `pescar` | a cena `pesca_lanca`: na água rasa, parado com a lança de pesca erguida, esperando o peixe |
| `golpear` | `pescar` | a cena `pesca_lanca`: o golpe da lança na água (1 min) |
| `peixe_na_lanca` | `parado`; e andando (`ida_det`) | a cena `pesca_lanca`: o peixe na ponta da lança, erguido e levado ao fogo |
| `despejar` | `parado` | a cena `coleta_morro`: despejando o cesto perto do fogo |
| `lavar` | `parado` | a cena `lavagem`: lavando na beira do lago |
| `recolher_caca` | `parado` | a caçada: abaixado junto do bicho caído |
| `caca_no_pau` | `carregar_caca` (andando) | a volta da caçada com o porco amarrado num pau, nos ombros |
| `bocejar` | `parado` | de madrugada, alguém acorda em casa e se espreguiça |
| `aticar` | `fogueira` | de madrugada, quem acordou atiça o fogo |
| `cochilar` | `fogueira` | o vigia cochilando sentado no fogo (no lugar de `vigia`) |

Precisam de arte (B ou C): `mirar` (o quadro 1 do arremesso, parado), `apontar` (`cacar_apontar_2q`), `espeto` (`cozinhar_espeto_4q`), `pescar_lanca`, `golpear` e `peixe_na_lanca` (a pesca com lança na água rasa: duas folhas novas, da C), `despejar` (o cesto virado no chão), `lavar`, `carregar_feixe`, `carregar_cesto_cabeca`, `espreitar`, `arremessar`, `recolher_caca`, `caca_no_pau`, `bocejar`, `aticar`, `cochilar`; as cenas `brasas` e `bicho_noturno` (coruja, morcego, raposa, sapo); o porco da caçada.

**O dia usa o mundo inteiro.** Quase todo dia, de 2 a 4 adultos saem juntos à tarde para a caçada na borda da floresta (veja a cena `cacada`). Cada povo tem um pescador no dia, que pesca até 17h30, alguém que vai e vem do lago com água e um ou dois que colhem longe do acampamento. As crianças brincam na praia de manhã (9h às 11h30) e à tarde (14h às 17h40). De dia, as pessoas ocupam pelo menos 3 das 4 zonas e nunca mais de 40% delas fazem a mesma coisa (veja `testar_vida.gd`).

**Ninguém parado muito tempo.** De dia (6h às 17h), ninguém fica de pé, deitado, sentado no fogo ou conversando no mesmo ponto por mais de 20 min de jogo (uns 37 s em 1x), fora das cenas: a cada 15 a 20 min a pessoa dá uns passos para o lado (6 a 10 px) e continua dali, ou volta ao ponto de antes. Quem chega antes da hora marcada espera ao lado e chega na hora. Os dois de um par que conversa mudam juntos.

**Conversas à tarde.** Das 12h45 às 16h45, a cada 12 a 15 min, dois do mesmo povo que estão trabalhando ou à toa perto um do outro (até 24 px) param uns 6 min e conversam ali mesmo, um de frente para o outro (`conversar`). Se em meia hora ninguém conversou, um par mais longe (até 60 px) se encontra: um vai até o outro e depois volta. O pescador e quem busca água continuam no que fazem. No povo inicial (12 pessoas), é uma conversa a cada 17 min de jogo, em média; com três ou quatro povos na tela, um balão a cada poucos segundos em 1x. No almoço, cada par termina numa hora (de 12h15 a 12h45). O pescador passa o dia todo na margem.

**Um acontecimento por hora.** Das 6h às 20h, a cada hora, alguém de cada povo atravessa a tela: sai de casa (às vezes com a ferramenta, `levar_pote` ou `levar_machado`), vai ao lago, à mata, à praia ou longe, trabalha uns minutos e volta para casa com uma carga grande (`carregar_agua`, `carregar_feixe` ou `carregar_cesto_cabeca`). A ida e a volta somam pelo menos 40 px. Quem atravessa é um adulto de 10 a 70 anos sem papel no dia (nem o pescador, nem os caçadores). Junto com as crianças correndo, os incidentes e a caçada, isso dá em 1x (≈1 a 2 min por hora de jogo) sempre alguma coisa legível acontecendo.

**Fim de tarde e noite.** Das 16h15 às 17h15, cada um volta com a carga. Depois, uns vão ao lago (banho ou água), outros à lenha, outros descansam em casa. Das 17h30 às 19h, uns cozinham (`cozinhar`) e os outros conversam e comem (`comer`); as crianças brincam na praia até 17h50 e comem depois dos grandes. Depois do jantar, uns ninam os pequenos, tecem ou consertam em casa, e o resto fica na fogueira, com conversas e crianças correndo. Dorme-se das 21h às 22h30 até as 5h ou 6h30, mas a noite tem sempre alguém acordado: o vigia faz a ronda em três turnos (22h à meia-noite, meia-noite às 2h50, 2h30 às 5h). Às vezes um casal fica olhando o céu, alguém reza tarde ou vai ao lago de madrugada, e em noites sem tempestade há uma roda de histórias até as 23h. O doente passa o dia em casa, acordando de vez em quando.

**A madrugada (0h às 5h).** Nos dois primeiros turnos, o vigia às vezes cochila sentado no fogo (`cochilar`, em cerca de um terço das paradas no fogo) e depois volta à ronda. Uma ou duas vezes por noite, alguém acorda em casa (`bocejar`), vai ao seu lugar no fogo e o atiça (`aticar`); a pessoa tem `cena: {tipo: "acordou", id}` nesses trechos. Enquanto ninguém atiça, o fogo baixa para brasas: a cena `brasas` vai de 0h40 até quem atiçar chegar, e volta 50 min depois, até as 5h. A coruja fica a noite toda na árvore mais perto da vila, e a cada 15 a 30 min um bicho passa: a raposa, o morcego ou o sapo (cena `bicho_noturno`).

**Ninguém em cima do fogo.** Depois de montado o plano, quem ficaria parado a menos de 6 px do centro da fogueira (`FOGO_LIVRE`) é afastado para 6 px, do lado em que já estava. Vale para a fogueira, o jantar, o vigia e todas as cenas.

**Lugares sem fila.** Cada pessoa tem um lugar de descanso próprio perto do fogo, fixo enquanto o povo não muda: os lugares ficam a 7 px uns dos outros, alternando os lados da fogueira e a pelo menos 6 px do centro dela, por ordem de chegada ao mundo. É ali que ela fica na `fogueira` da noite e nas conversas em volta do fogo. Quem não cabe na faixa do povo vai direto para casa à noite (`dormir`). Em casa, cada um dorme num ponto próprio ao longo da largura da moradia. Em povos grandes, a coleta se espalha pela faixa de trabalho inteira. Ninguém fica na água (x < 126), a não ser remando; quem pesca fica na margem, de 126 a 136.

As crianças correm umas atrás das outras perto do fogo (trechos curtos de `andar` e `parado`). Cada pessoa faz de 2 a 4 atividades por dia, conforme o estágio, o papel, a zona e os traços, e as repete em ciclos até o fim da tarde. Os horários de acordar e dormir variam, e dois dias nunca são iguais (às 10h, só 4% a 6% das pessoas estão no mesmo lugar que no dia anterior). Tudo sai da semente.

**Custo e cache:**
- A rotina do dia (lugares, cenas, vida social, o plano de cada pessoa e as agendas das 24 horas) é montada **numa thread de trabalho**, sem custo para a linha principal. Ao fim da montagem, os planos são soltos (só as linhas e as agendas ficam); as agendas das horas que já passaram também são soltas, e a rotina de amanhã montada às 23h corta só as primeiras horas (ela é refeita na 1h). Com 250 pessoas, uma rotina ocupa de 20 a 30 MB. Custa de 60 a 220 ms de thread com a população máxima.
  - A rotina de amanhã começa a ser montada às 23h, para a madrugada já entrar pronta (vigia, brasas, quem acorda). Depois do passo da 0h à 1h, em que acontecem os eventos do dia, ela é montada de novo, com os eventos, e entra assim que fica pronta, em décimos de segundo. No mais tardar às 4h, o passo espera por ela; no jogo, ela fica pronta muito antes.
  - Se a rotina das 23h não ficou pronta (um salto, um mundo recém-carregado), até a nova entrar todos aparecem dormindo em casa, como na última hora do dia anterior.
  - O alvo de um poder sai sempre da rotina de hoje (se o deus age no instante em que ela ainda está sendo montada, espera por ela): a simulação não depende de a apresentação estar olhando.
- No meio do dia, um evento que vira cena (nascimento, casamento, ataque, separação, tempestade...) manda montar a rotina de novo, também na thread, no passo seguinte ao evento. Até a nova ficar pronta, vale a anterior: a cena aparece uma ou duas horas de jogo depois do evento.
- A tempestade não entra no plano: é posta por cima. Da hora em que ela começa até o fim do dia, quem é da zona vai para casa e fica `parado` lá.
- Enquanto a thread monta, ela só lê o mundo. Por isso `avancar_hora()`, `usar_poder()`, `criar_povo()` e `abandonar()` esperam por ela antes de mudar o mundo. No jogo, isso não acontece: entre dois passos há pelo menos 1,9 s.
- A rotina só é montada se a apresentação consultou o mundo desde o passo anterior. Avançar muitas horas sem consultar (salto, ausência, testes) não monta nada. A primeira consulta depois de criar ou carregar um mundo, ou de saltar mais de um dia, monta a rotina inteira ali mesmo (~100 ms com a população máxima): é um momento de carregamento.
- Quem passou a existir no meio do dia antes de a rotina ser refeita (raro) aparece `parado` em casa até a rotina seguinte.
- Quando sobra tempo no passo, ele mesmo já prepara as pessoas visíveis e as cenas da hora nova. A consulta logo depois só devolve o que está pronto.
- Idade, papel, doença, gravidez e cônjuge das fichas mudam com o dia e com os eventos. De madrugada (antes das 5h), o que muda por evento pode entrar na ficha só no passo seguinte.
- `pessoas_visiveis()`, `cenas_ativas()`, `construcoes()` e `preces_abertas()` guardam a resposta da hora: **chamar de novo na mesma hora devolve o mesmo array, sem custo**. Não altere esses arrays. Se precisar guardar algo além da hora, copie, porque as fichas das pessoas são reaproveitadas na hora seguinte.

Medido com o mundo grande da regressão (287 pessoas, estágio 6), como a apresentação usa o mundo (um passo e, depois, tudo o que `simulacao.gd` lê), em processos novos, menor tempo de 3 execuções:

| Momento | Custo |
|---|---|
| Passo (`avancar_hora`), pior caso: a virada do ano | 3,4 a 3,6 ms |
| Passo, média | ~1,3 ms (inclui preparar as pessoas visíveis da hora) |
| Consulta completa depois do passo, pior caso | 0,4 a 0,9 ms |
| Consulta completa, média | ~0,1 ms |
| Repetida na mesma hora | ~0,1 ms |

A regressão confere isso a cada rodada: nenhum passo acima de 5 ms, nenhuma consulta acima de 2 ms, nenhuma montagem dentro de uma consulta, nenhuma espera pela thread e ninguém acordado sem plano.

**`adiantar_rotina(n = 4) -> int`** ficou só por compatibilidade: a rotina é montada na thread e não precisa mais ser adiantada. Devolve quantas pessoas vivas estão sem plano na rotina em uso (normalmente 0).

### `cenas_ativas() -> Array[Dictionary]`

As cenas que acontecem em algum momento desta hora: `{id, tipo, grupo, evento, ini, fim, participantes, x, ...}`. `ini` e `fim` são em horas do dia (por exemplo, 8.0 e 11.3). `x` é o lugar principal da cena. Quem participa tem `cena: {tipo, id}` em `pessoas_visiveis()`, e a própria agenda já traz o que a pessoa faz na cena.

| Tipo | Quando | O que se vê | Campos extras |
|---|---|---|---|
| `funeral` | no dia seguinte a uma morte (de quem tinha 12 anos ou mais), das 8h às 11h | cortejo do fogo ao lugar dos mortos, dois à frente com `carregar_morto`; reza ali | `morto`, `rito` ("enterram", "queimam", "veneram"), `x_tumulo` |
| `nascimento` | no dia do nascimento, das 8h às 12h | a mãe `cuidar` em casa, visitas conversando em volta | `mae`, `crianca` |
| `casamento`, `festa` | à noite, das 19h às 21h; a festa é no aniversário da chuva, em povos com esse costume | dança em volta do fogo | |
| `migracao` | no dia de uma separação ou mudança, a partir das 6h30 | fila de gente com carga, da aldeia antiga até a nova | `de`, `para` |
| `guerra` | no dia de um ataque, das 7h30 às 12h | marcha, as duas linhas frente a frente com `lutar` das 9h às 10h30, e a volta | `outro_grupo`, `x_combate`, `mortos` |
| `corvos` | o dia seguinte a um ataque com mortos | sem participantes: corvos sobre o campo de luta | `mortos` |
| `prece` | toda tarde (18h às 18h50) enquanto o povo tem uma prece aberta há 3 dias ou mais | os que creem ajoelhados no altar | |
| `colheita` | os últimos 4 dias do outono, estágio 2 em diante | todo adulto na roça, trabalhando ao longo dela | |
| `cacada` | em cerca de 2 de cada 3 dias, à tarde: saem do fogo entre 13h30 e 14h, espreitam das 14h às 16h30 (com pausas longas), arremessam entre 16h30 e 16h40 e chegam ao fogo com a caça entre 17h15 e 17h23; a cena acaba entre 17h37 e 17h45 | 2 a 4 adultos, longe do acampamento: o porco aparece 35 px além da última cabana, um dia na borda da mata (do lado da praia) e outro na do morro (na vila inicial, x 200 a 206 ou 344 a 350, a 60 a 85 px do fogo), em chão aberto. Os caçadores vão escalonados, a 7 px uns dos outros; enquanto dura a caçada (da saída ao fim do abate), ninguém de fora dela fica parado a menos de 27 px do porco. A volta atravessa a vila até a fogueira, e até 3 crianças (de 3 a 8 anos; uma, pelo menos, fica na praia) esperam na beira da vila e correm atrás dos caçadores (`x` é onde o porco está) | `vazia`: erraram e voltaram sem nada; `bicho`: "porco"; `etapas` (abaixo); `cozinha`: o id de quem espera a caça no fogo com o espeto (-1 se ninguém, e sempre -1 quando `vazia`); `criancas`: os ids das crianças que correm atrás da volta (ação `brincar`, com a cena `cacada`) |
| `pesca_lanca` | nos dias sem caçada (cerca de 1 em cada 3 dias), uma das três cenas do começo da tarde, alternando: das 13h30 às 15h20, mais ou menos | um adulto na beira do lago (na água rasa, para a apresentação), com a lança de pesca: espera parado com a lança erguida (`pescar_lanca`), golpeia (`golpear`), erra de 2 a 4 vezes, acerta, ergue o peixe na ponta (`peixe_na_lanca`) e leva ao fogo | `etapas`: `ida`, `espera`, `golpe` (com `acerto`: true só no último), `peixe`, `volta`, `entrega` |
| `coleta_morro` | nos dias sem caçada, alternando com as outras duas, das 13h30 às 16h15 | 3 ou 4 adultos sobem ao morro, colhem até 15h35 e descem em fila, a 8 px uns dos outros, com o cesto na cabeça (`carregar_cesto_cabeca`); no fogo, despejam os cestos (`despejar`) | `etapas`: `subida`, `coleta`, `descida`, `despejar` |
| `lavagem` | nos dias sem caçada, alternando com as outras duas, das 13h30 às 15h | 2 adultos lavam na beira do lago (`lavar`), e até 4 crianças (de 3 a 10 anos) brincam na água rasa (`brincar`, detalhe `banho`) | `etapas`: `ida`, `lavar`, `volta`; `criancas` |
| `caca_vazia` | na volta de uma caçada sem caça | os caçadores, de mãos vazias perto do fogo | |
| `vigia` | toda noite, em três turnos | o vigia, que vai e volta entre o fogo e a beira do acampamento; às vezes cochila no fogo | |
| `brasas` | de madrugada, de 0h40 até alguém atiçar, e de novo 50 min depois, até as 5h | sem participantes: a fogueira baixa, em brasas (`x` é a fogueira) | |
| `bicho_noturno` | toda noite. A coruja (`fixo: true`) fica das 21h às 5h na árvore da mata mais perto da vila (`x`; a base dela vai no topo da copa mais próxima). Os outros passam a cada 15 a 30 min, de 6 a 10 min cada: a raposa trotando pela beira do acampamento, o morcego sobre o lago, o sapo na margem | sem participantes | `bicho`: "coruja", "raposa", "morcego" ou "sapo"; `fixo`; `x_fim`: onde o bicho termina a passagem (os que não são fixos) |
| `historias` | algumas noites sem tempestade, 21h15 às 23h | até 6 pessoas conversando em volta do fogo | |
| `briga_criancas` | incidente: 2 ou 3 por povo por dia, entre 9h20 e 16h20 | duas crianças brigando; um adulto separa | |
| `tombo` | incidente | alguém se machuca de leve; outro cuida | |
| `animal` | incidente | um animal aparece na beira do acampamento; dois adultos espantam (`x` é onde ele está) | |
| `perdido` | incidente | uma criança se perde longe do acampamento; um adulto vai buscar | |
| `discussao` | incidente | dois adultos (de preferência rancorosos ou ambiciosos) discutem | |
| `construcao` | no dia e no seguinte a uma conquista de estágio, à agricultura, ou a cabanas derrubadas por tempestade, terremoto ou dilúvio | até 6 pessoas `construir` na obra nova (templo, forja, arquivo, moinho ou casas) | `obra` |

**As etapas da caçada.** A cena `cacada` traz `etapas`, em ordem, para a apresentação encenar o bicho e a lança: `{etapa, ini, fim, x, x_bicho}`, com `ini` e `fim` em horas do dia, `x` onde estão os caçadores (na espreita, o da frente) e `x_bicho` onde está o porco (-1 quando ele não está mais no chão).

A espreita vem em várias etapas `espreita` seguidas (9 a 11; 6 a 8 quando o fogo está perto do porco e não há espaço para mais), uma por avanço, das 14h às 16h30: entre um avanço e outro, uma pausa de 12 a 17 min de jogo (uns 25 a 30 s em 1x) em que o porco fuça e os caçadores esperam abaixados; depois, dão 2 a 4 px na direção do porco e agacham de novo. O porco muda de lugar 0 a 3 px de uma etapa para a outra (`x_bicho`; a apresentação pode deslizar entre as duas). Os de trás vão escalonados, a 7 px uns dos outros (`Rotina.ESCALONADO`). A última `espreita` traz `mira: true`: 0,8 min (uns 1,5 s em 1x) em que o da frente fica parado com a lança erguida (`mirar`) e os outros apontam (`apontar`). O arremesso dura 6 min (uns 11 s), e os de trás continuam apontando. Constantes: `Rotina.MIRA`, `ARREMESSO`, `ABATE` e `REPARTIR`.

| Etapa | O que se vê | Detalhe dos caçadores |
|---|---|---|
| `saida` | juntos no fogo, prontos para sair, e a caminhada até a borda (até o começo da espreita); o porco já aparece na borda (`x_bicho`) | `parado` |
| `espreita` | agachados, chegando aos poucos, 2 a 4 px a cada 6 a 8 min; o porco fuça e se mexe também | `espreitar` (andando, `levar_lanca`); na `mira`, `mirar` (o da frente) e `apontar` (os outros) |
| `arremesso` | a lança voa até o porco | `arremessar` (o da frente) e `apontar` (os outros) |
| `abatido` | o porco caído; os caçadores abaixados junto dele | `recolher_caca` |
| `fuga` | (no lugar de `abatido`, quando `vazia`) o porco foge 40 px para dentro da mata | — |
| `volta` | a volta até o fogo, com o porco amarrado no pau (ou de mãos vazias) | `caca_no_pau` (andando) |
| `repartir` | no fogo, no fim de tarde, repartindo a caça, com quem espera no espeto (`cozinha`, ação `cozinhar`, detalhe `espeto`, do lado de quem chega, desde 3 min antes); ou `maos_vazias`, com a cena `caca_vazia` | `repartir` |

A lista de nomes está em `Rotina.ETAPAS_CACADA`.

`posicao_de(pessoa_id) -> float` devolve o x de uma pessoa no meio da hora corrente (-1 se ela morreu).

**O mundo novo começa de manhã.** `Mundo.new(semente)` devolve o mundo às 7h do dia 1 (`Mundo.HORA_INICIAL`), com o povo saindo das cabanas: as horas da noite passam na criação, como passos normais. `criar_povo()` no mundo vazio também deixa o tempo correr até as 7h antes de criar o povo. Ao carregar um mundo salvo, nada disso muda (a persistência cria o mundo com `Mundo.new(semente, [], 0)`).

### `dica(pessoa_id) -> Dictionary` (a dica sobre a pessoa)

Para a dica que aparece ao passar o mouse sobre alguém: `{fazendo, pensamento, humor, sonho}` (vazio `{}` se a pessoa morreu). É calculada na consulta, a partir da ficha da hora de `pessoas_visiveis()` e do estado do mundo, e guardada até o próximo passo; nada nos quadros, e não usa o sorteio do mundo.

**Duas pessoas não pensam a mesma frase na mesma hora, e ninguém repete a frase no mesmo dia.** Na primeira consulta da hora, o pensamento é escolhido para o povo inteiro da pessoa, em ordem de id: cada um tem a sua ordem de preferência (que sai da semente da pessoa) e passa para a próxima frase quando a primeira já está com outra pessoa nesta hora, do mesmo povo ou de outro já consultado, ou quando ela mesma já a pensou hoje, em outro bloco de 2 horas. Entre povos, depende de qual foi consultado antes (isso não mexe no mundo). Num mundo cheio, quando as frases livres de alguém acabam, vale a de alguém de outro povo, nunca a de alguém do mesmo; sem nenhuma, fica sem pensamento. As fontes do pensamento que só mudam com o dia (necessidades, memória, relações, o deus, o povo, os traços) ficam guardadas por um dia: um acontecimento entra no pensamento no dia seguinte. Custo: num povo de 12 a 30 pessoas, menos de 2 ms na primeira consulta do dia e menos de 1 ms na primeira de cada hora; no mundo de 244 pessoas (ano 286), 8 ms e 3 ms.

| Campo | O que é |
|---|---|
| `fazendo` | o que a pessoa faz agora, numa frase curta, com concordância (no estágio 1, "no acampamento", não "na vila"): "catando lenha na borda da mata", "espreitando um porco", "mirando o porco com a lança", "cozinhando a caça", "vigiando o fogo", "sentada junto ao fogo", "conversando com Aru", "dormindo". Sai do `detalhe`, da `acao` e da cena (enterro, casamento, festa, prece, guerra, colheita, obra), com o lugar dito como se fala: "perto do fogo", "na vila", "na praia", "na beira do lago", "na mata", "no morro". |
| `pensamento` | uma frase de até 60 caracteres, com a primeira letra maiúscula, tirada do estado real da pessoa (abaixo). Dormindo, é o sonho ou vazio (a linha pode ser escondida): um sonho da fonte mais forte que tem sonho (um morto ou o cônjuge, a fome, a doença, o deus, o frio, a seca, um susto, o medo do escuro), sempre quando ela pesa e, quando é fraca, só em um bloco de 2 horas em cada 3. Exemplos: "Sonha com Kidema", "Sonha com comida", "Sonha com a voz do Que Sacode", "Sonha que um bicho a persegue na mata". Para mostrar o sonho como narração, use `sonho`. |
| `sonho` | dormindo, o sonho como narração, sem aspas e em minúscula: "sonhando com Vepeik", "sonhando que um bicho a persegue na mata" ("" acordado ou sem sonho). O `pensamento` de quem dorme continua com a frase ("Sonha com Vepeik"), para quem ainda a mostra; a apresentação pode trocar por `sonho`. |
| `humor` | uma palavra ou duas, com concordância: "contente", "aflita", "de luto", "faminto", "assustada", "grato", "amargurada", "orgulhoso", "tranquila", "alegre" (criança)... Dormindo: "dormindo"; "inquieto no sono" (doença, fome, luto, aflição) ou "sono leve" (frio, susto, medo) quando há motivo. |

De onde vem o pensamento, da fonte mais forte para a mais fraca:
1. **Necessidade urgente:** doença da própria pessoa, fome do povo, seca na zona, doença no povo, gravidez, velhice, o frio do inverno.
2. **Um acontecimento dos últimos 8 dias** que a pessoa viveu ou que tocou o povo (a memória dela): morte de parente ("Sinto falta de Marsaim", humor "de luto"), nascimento de filho ou irmão, raio ou fogo do céu, fartura, prece atendida ou sem resposta ("O Que Rega nos esqueceu"), ataque, tempestade, terremoto, eclipse, cometa, o fim da fome ou da seca, casamento, novo líder, costume novo.
3. **Relação forte:** o maior rancor ("Não perdoo Oro"), o cônjuge vivo, a saudade de pai, mãe, filho ou cônjuge mortos, os filhos pequenos.
4. **O deus**, pelo nome que o povo dá a ele e pela fé da pessoa: "O Que Sacode cuida de nós", "Rezar ao Que Sacode para quê?", "Por que a Mãe da Chuva se cala?". Sem crença, só os curiosos se perguntam quem manda a chuva. A pessoa fala do que viu, nunca de quem joga.
5. **O povo:** os costumes, o líder (os ambiciosos e os rancorosos criticam, menos o cônjuge dele), o celeiro cheio, repartir pouco.
6. **Os traços** (dois por pessoa, com frases próprias).

O que a pessoa está fazendo também pesa: na espreita, no arremesso, apontando, com a caça no pau, no espeto, na vigia, na roda de histórias, na pesca com lança, correndo atrás dos caçadores. E o momento, pelo lugar e pela atividade: na praia, "Achei uma concha!"; no lago, "Vi um peixe!"; pescando, "Esse lago tem peixe grande"; catando lenha, "Esse galho seco serve"; tecendo, "Mais umas voltas e o cesto fica pronto".

**O pensamento não contradiz o que a pessoa faz.** Um pensamento do dia sobre um lugar ou uma ação não sai enquanto a pessoa já está ali ou fazendo aquilo: quem brinca na praia não pensa "Amanhã vou na praia de novo", quem pesca não pensa "Quando eu crescer vou pescar" (as palavras do lugar e da ação: praia, lago, morro, brincar, pescar, lenha, porco, fogo, rezar, cesto). Os pensamentos do momento, sim.

Uma necessidade urgente (doença, fome) fica sozinha. Senão, a cada 2 horas de jogo, a frase vem de uma das três fontes mais fortes, e muda entre as variantes de cada uma (os modelos mais frequentes têm de 3 a 5: "Gosto de ver Aru rir", "Aru me faz rir", "Com Aru por perto, o dia passa rápido"...): ninguém fica com a mesma frase por horas, e pessoas parecidas (cinco crianças do mesmo povo) não pensam a mesma coisa ao mesmo tempo. As crianças (até 11 anos) pensam como crianças: "Mãe, tem comida?", "Cadê a mamãe?", "Por que o fogo dança?", "Quero brincar mais um pouco".

### `dica_cabana(x) -> Dictionary` (a dica da cabana, à noite)

À noite, quem dorme fica dentro da cabana e não é desenhado: a dica vai na cabana. `{x, grupo, moram, dormem, texto, quem_sonha, sonho}` da cabana em `x` (`{}` se não há cabana ali): `moram` e `dormem` são ids; `texto` é "Dormem aqui: Tamu e Peos" ("Dorme aqui: ..." com uma pessoa; "Moram aqui: ..." quando ninguém dorme, de dia); `sonho` é o sonho de um deles, como narração: "Tamu, sonhando com Vepeik" ("" se ninguém sonha), e `quem_sonha` o id de quem sonha (-1). Usa a mesma escolha de `dica()`.

## Eventos, preces e chamados

Tudo o que acontece vira um **evento**, guardado em ordem em `mundo.eventos` (ids crescentes, a partir de 0). Para saber o que há de novo:

```gdscript
var vistos := 0
# a cada passo:
for ev in mundo.eventos_desde(vistos):
    ...
vistos = mundo.eventos.size()
```

`eventos_desde(id) -> Array[Dictionary]` traz os seguintes campos de cada evento:
- `id` e `tipo`;
- `ano`, `dia` (1..40) e `hora`;
- `zona`, `grupo`, `outro_grupo` e `participantes` (ids de pessoas);
- `causa`: "natural", "social" ou "divina";
- `importancia`: de 0 a 10;
- `dados`: depende do tipo. Os atos do deus trazem `x`, `grau` e `intensidade`;
- `camada`: "ambiente", "nota" ou "chamado", as três camadas de atenção do documento funcional;
- `curto`: uma frase de até 40 caracteres para a dica do cursor, nos eventos de camada "nota" ou "chamado" ("Fome em Koil", "Começa a Guerra Santa", "Restam só quatro no mundo"). É vazia na camada "ambiente" e nos poucos tipos que não têm frase.

`texto_curto(evento_id) -> String` devolve a mesma frase curta para qualquer evento, a qualquer momento. Ela sai da gramática, não sorteia nada do mundo e é sempre a mesma para o mesmo evento.

Uma lista completa de tipos e dados de cada um fica para a próxima versão deste documento. Por enquanto, a referência é a função `registrar(...)` em `mundo.gd`. Os tipos que mais interessam à moldura:

| Tipo | Quando | Camada |
|---|---|---|
| `prece` | alguém pede ao deus (seca, fome, doença, frio, guerra). `dados.repetida`: a mesma necessidade, pelo mesmo povo, em menos de um ano (camada "nota", não "chamado"); `dados.inimigo` (guerra): o outro povo do último ataque; `dados.atacou`: quem reza atacou e perdeu (pede vitória, não proteção) | chamado (nota, se repetida ou banal) |
| `prece_atendida`, `prece_sem_resposta` | a necessidade passou, ou não passou (ou quem foi pedido morreu) | nota |
| `prece_contrariada` | o deus fez o contrário do que o povo pedia: um gesto que fere o povo que reza (seca, fogo, dilúvio ou terremoto na zona dele, ou um raio que mata alguém dele). Um evento por gesto e por povo, com todas as preces que ele contrariou (`dados.necessidades`), `dados.poder` e `dados.resposta` (o evento do gesto). A fé de quem rezou cai 0,4, a do povo 0,1 (os devotos, 0,02), o silêncio conta em dobro, e quem rezou fica ferido pelo deus | chamado |
| `fome_inicio`, `doenca_inicio`, `ataque` | começa uma fome, uma doença ou uma luta | chamado |
| `os_ultimos` | restam 5 pessoas ou menos no mundo | chamado (o mais intenso) |
| `fim_do_mundo` | não resta ninguém | chamado |
| `crenca`, `separacao`, `conquista`, `agricultura` | marcos do mundo | chamado (importância ≥ 8) |
| `nascimento`, `morte`, `casamento` | ciclo de vida | conforme a importância |
| `tempestade`, `seca_inicio`, `seca_fim`, `eclipse` | clima e céu; `seca_fim` traz `dados.irrigados`, os povos com canais (estágio 6), que quase não sentiram a seca | nota |
| `fogo_brando` | o fogo em intensidade baixa (abaixo de 0,35, o gesto curto): desce manso, acende as fogueiras da zona e aquece o povo por 6 dias, sem queimar (ninguém sofre o frio, e a prece de frio é atendida). O povo pode ver nisso o deus mandando o calor | nota |
| `chuva_divina`, `raio_divino`, `fartura_divina`, `fogo_divino`, `terra_erguida`, `sonho`, `seca_divina`, `diluvio`, `terremoto_divino`, `pressagio`, `cura` | resultado de `usar_poder` | nota ou chamado |
| `linhagem` | a pessoa acompanhada morreu, e o acompanhamento passou adiante | nota |
| `guerra_inicio`, `guerra_fim` | uma briga vira guerra com nome (na segunda batalha) e termina: trégua, imposição do deus, conquista, extinção ou esfriou | chamado |
| `cometa`, `terremoto`, `gemeos` | presságios naturais, além do `eclipse`. O terremoto derruba cabanas e pode matar. | nota |
| `cultura` | um povo muda uma dimensão da cultura (`dados.dimensao`: "estranhos", "mortos", "poder", "recursos"). Para o poder, `dados.como` diz como: "revolta" (contra o templo), "golpe" (um ambicioso acaba com o conselho), "tirania" (o povo cansa de um líder só) ou "templo" (os sacerdotes passam a mandar) | nota |
| `reforma` | uma geração abandona um costume herdado ou de origem esquecida | nota |
| `dependencia`, `exigencia`, `desamparo` | o povo deixa de se preparar porque o deus sempre responde (`dados.por`: "" pelas preces atendidas, ou o poder repetido: "chuva", "fartura" ou "cura"); passa a pedir coisas pequenas; e, no primeiro silêncio, paga caro | nota |
| `expedicao` | uma família parte além da borda do mundo e nunca volta | nota |
| `estranhos` | chegam de além da borda 2 ou 3 jovens sem parentes ali e ficam no povo (participantes: os que chegaram; `dados.n`; `dados.acolhida`: a relação do povo com estranhos). Só num povo com menos de 20 pessoas em que ninguém mais pode casar (sem casal fértil e sem par que não seja de irmãos ou de pais e filhos): 22% por ano (8% num povo desconfiado) | nota |
| `descoberta_tecnica` | alguém descobre o saber do próximo estágio (`dados.saber`: "pedra", "metal", "escrita", "engenharia") | nota |
| `estagio` | o povo chega a um estágio novo (`dados.estagio`, de 3 a 6) | chamado |
| `regressao` | morreu o último que sabia, e o povo volta um estágio (`dados.de`, `dados.para`) | chamado |
| `arquivo_salvou` | com a escrita, alguém reaprende nas tabuletas o saber que ia se perder | nota |
| `estudo_do_ceu` | o povo passa a prever eclipses: sinais no céu impressionam menos (metade no estágio 5, um quarto no 6) | nota |
| `ruinas_saber`, `mito_ruinas` | alguém aprende nas ruínas (só o que ninguém do povo sabe ainda); um povo explica ruínas de quem não existe mais ("gigantes", "castigo" ou "gente"), pelo que viu lá (`dados.obra`: templo, muralha, moinho, arquivo, forja, celeiro, cabana ou fogueira; `dados.antiga`: de uma era anterior) | nota |
| `livro_fechado` | a crônica de uma era se fechou como livro | nota |
| `peste` | uma doença vem de longe e entra em todos os povos; mata muito por cerca de 20 dias (uma vez a cada ~150 anos) | chamado |
| `estagio` (e os marcos da estela) | do estágio 5 em diante, o último marco do povo vai para a estela (`Grupo.estela`, veja `construcoes()`) | |
| `profeta` | alguém prega outro nome para o deus. `dados.aceito`: o povo aceitou (o deus muda de nome), ou o templo chamou de heresia e os seguidores fundaram outro povo (vem em seguida uma `separacao` por cisma) | chamado |
| `secularizacao` | um povo que escreve deixa de rezar: os sábios explicam a chuva e o raio | chamado |
| `renascimento` | um povo que tinha deixado de rezar volta a crer, diante de algo inegável | chamado |

`camada(evento)` aplica a regra: importância ≥ 8 ou tipo de chamado → "chamado"; importância ≥ 4 → "nota"; o resto → "ambiente".

### `preces_abertas() -> Array[Dictionary]`

As preces que ainda esperam resposta. São os sinais na moldura e continuam aqui até serem atendidas ou ficarem sem resposta.

| Campo | O que é |
|---|---|
| `evento` | id do evento `prece` |
| `grupo`, `autor` | quem reza |
| `alvo` | por quem reza (o filho doente), ou -1 |
| `necessidade` | "seca", "fome", "doenca", "frio", "guerra" ou "banal". Uma prece banal ("que amanhã faça sol para a pesca") é de um povo que se acostumou a ser atendido. Ela some sozinha em alguns dias, sem contar como silêncio, e tem camada "nota", não "chamado". |
| `desde`, `dias` | dia absoluto em que começou e há quantos dias espera |
| `x` | onde está quem reza agora (pode estar trabalhando longe, até em outra zona) |
| `x_povo` | onde um gesto do deus atinge o povo que reza: a fogueira, dentro da zona do povo. É aqui que um poder atende ou contraria a prece (não em `x`) |
| `inimigo` | na prece de guerra, o id do povo inimigo (-1 se não se sabe) |
| `atendem` | os poderes que atendem a prece: seca, `["chuva"]`; fome, `["fartura"]`; doença, `["cura"]` (no doente que é `alvo`; sem alvo, só a cura imposta, repetida, cura todos); guerra, `["raio", "terremoto"]`, **no povo inimigo**; frio, `["fogo"]`, **em intensidade baixa** (o gesto curto, abaixo de 0,35: veja `fogo_brando`); banal, `[]` |
| `fogo_brando` | true na prece de frio: o fogo que atende é o brando (intensidade abaixo de `Mundo.FOGO_BRANDO`, 0,35); o fogo médio ou forte queima e contraria a prece |
| `contrariam` | os poderes que contrariam a prece quando caem no povo que reza: seca e fome, `["seca", "fogo", "diluvio", "terremoto"]`; doença, frio e guerra, também o raio que mata alguém do povo. Na guerra, raio e terremoto atendem no inimigo e contrariam no próprio povo |
| `texto` | a prece em português, sempre a mesma para o mesmo evento: «Que Rega, que a chuva volte.» |
| `curto` | uma frase de até 40 caracteres para a dica do cursor: "Kurpeya pede comida", "Viem pede a cura de Lou" |

Um povo sem crença, ou cético, não reza e por isso não aparece aqui. É o ponto cego do documento funcional.

**O que acontece com a prece.** Atendida por um poder (a chuva na seca, a fartura na fome, a cura no doente, o raio ou o terremoto no inimigo, o fogo brando no frio): `prece_atendida`, a fé sobe, e o povo agradece. Atendida pelo acaso (a necessidade passou sozinha): `prece_atendida` com `falso_milagre`, e o povo agradece do mesmo jeito. Sem resposta em 14 dias: `prece_sem_resposta`, a fé cai, e três silêncios viram uma explicação (`silencio`). Contrariada: `prece_contrariada` (acima). Depois de uma prece sem resposta ou contrariada, o povo espera 10 dias para pedir de novo a mesma coisa (`Mundo.ESPERA_PARA_REZAR`). Quem rezou pensa no desfecho por 2 dias (veja a dica: "O Que Nega ouviu a nossa prece", "Pedi chuva, e veio o castigo", "O Que Nega nos esqueceu").

## Poderes

```gdscript
var r := mundo.usar_poder(poder, x, intensidade)
# r = {ok: bool, grau: "sinal"|"milagre"|"imposicao", evento: id, zona: String, alvo: id da pessoa ou -1}
# se ok == false: {ok: false, motivo: String}
```

- `poder` é um de: `"chuva"`, `"raio"`, `"fartura"`, `"fogo"`, `"erguer"`, `"sonho"`, `"seca"`, `"diluvio"`, `"terremoto"`, `"pressagio"`, `"cura"`. A lista está em `Mundo.PODERES`.
- `x` é o ponto do gesto, em pixels do mundo. A zona vem de x.
- `intensidade` vai de 0 a 1 e vem do gesto: quanto mais tempo segurando, mais forte.

**Grau.** Sai da intensidade e da repetição, como manda o documento funcional:
- **imposição:** é o terceiro uso do mesmo poder na mesma zona em até 3 dias;
- **milagre:** intensidade ≥ 0,5;
- **sinal:** o resto.

A precisão conta para o raio e o sonho, que acertam a pessoa mais perto de x, se ela estiver a até 6 pixels. A força da reação do povo cresce com o grau. Na chuva, na fartura, na seca, no fogo, no dilúvio e no terremoto, a intensidade conta também dentro do grau (proporcional); no raio, no sonho, na cura, no presságio e na terra erguida, só o grau conta (veja `ferramentas_sim/poderes/LEIAME.md`).

**O gesto repetido vira hábito.** O mesmo gesto bom sobre o mesmo povo, na 4ª vez em um ano, vira costume: a chuva, a festa da chuva; a fartura e a cura (só a de quem estava doente), as oferendas; o sonho, o presságio e a terra erguida, a crença de que o deus ouve. Na 6ª, a chuva, a fartura e a cura viram dependência (`dependencia`, com `por`): o povo larga o costume de guardar. Os gestos que ferem criam o medo (a crença de que o deus castiga, oferendas, o deus renomeado) por conta própria.

| Poder | Sinal | Milagre | Imposição |
|---|---|---|---|
| `chuva` | garoa: sobe a água, não acaba a seca | acaba a seca naquela zona; os vizinhos ainda secos sentem inveja | idem, e força trégua entre os povos da zona e seus inimigos |
| `raio` | cai perto, não mata ninguém | mata quem está sob x, lido como castigo, martírio ou azar; ou cai no chão, se não houver ninguém | idem, mais trégua forçada; o lugar fica amaldiçoado e o povo tende a partir |
| `fartura` | comida a mais, parece natural | fartura que acaba a fome; os povos com fome em outras zonas sentem inveja | (mesmo efeito do milagre) |
| `fogo` | abaixo de 0,35 (o gesto curto), **fogo brando**: acende as fogueiras e aquece o povo da zona por 6 dias, sem queimar, e atende a prece de frio (evento `fogo_brando`); de 0,35 a 0,5, queima pouco | queima a zona, cabanas e estoque, e pode matar; lido como purificação ou maldição | (mesmo efeito do milagre) |
| `erguer` | uma pedra estranha | pedra alta, lugar sagrado com nome, e trégua entre povos em guerra | (mesmo efeito do milagre) |
| `sonho` | sonho vago, que muitos ignoram | ideia da agricultura, ou uma visão que pode fazer um sacerdote | sonho aceito com certeza, e paz entre o povo do sonhador e seus inimigos |
| `seca` | a zona seca um pouco | só aquela zona seca, por 6 a 28 dias, conforme a intensidade. É lida como castigo ("o que fizemos?"), e pode trazer oferendas. | seca dobrada, e oferendas |
| `diluvio` | a água sobe e cobre a zona | com intensidade ≥ 0,7, a água chega às zonas vizinhas: cabanas, estoque e vidas se perdem. Vira mito ("o deus lavou o mundo"), e o lugar ganha nome. | o mundo inteiro alaga: o quase fim do documento funcional |
| `terremoto` | tremor fraco na zona | a zona treme forte (e as outras, de leve): cabanas caem, pode matar, e é lido como castigo | (mesmo efeito do milagre) |
| `pressagio` | um sinal no céu, visto por todos os povos | idem, mais forte. Pela intensidade, a forma é cometa (< 0,34), eclipse (< 0,67) ou luzes. Cada povo lê como bom agouro (a fé sobe), mau agouro (hostilidade com inimigos) ou aviso (passam a estocar). | (mesmo efeito do milagre) |
| `cura` | em alguém são: só bem-estar | em quem está doente ou fraco, a 6 pixels de x: a pessoa se levanta. Nasce um devoto, às vezes um sacerdote, e a prece por ela é atendida de verdade. | cura todos os doentes do povo |

O evento gerado traz em `dados` o `x`, o `grau` e a `intensidade` (para o efeito visual), além do que aconteceu: vítima, mortos, se acabou a seca, como o povo leu o fato. Campos próprios dos poderes novos:
- `seca_divina`: `dias`;
- `diluvio`: `zonas` (as zonas alagadas), `mortos` e `cabanas`;
- `terremoto_divino`: `mortos` e `cabanas`;
- `pressagio`: `forma` ("cometa", "eclipse" ou "luzes") e `leituras` (id do povo → "bom", "mau" ou "aviso");
- `cura`: `curado`, `condenado` (se a pessoa estava mesmo para morrer) e `n` (quantos se curaram).

## Linhagem acompanhada

| Chamada | O que faz |
|---|---|
| `acompanhada` | id da pessoa acompanhada, ou -1 (a linhagem acabou) |
| `acompanhar(pessoa_id) -> bool` | troca a pessoa acompanhada; false se ela não existe ou morreu |
| `sugestoes(n = 5) -> Array[Dictionary]` | `{id, nome, grupo, motivo}`: pessoas que viveram algo marcante nos últimos 2 anos, por exemplo "acabou de ter uma visão", "está rezando", "fundou um povo" ou "perdeu alguém depois de rezar" |

Quando a pessoa acompanhada morre (ou parte além da borda), o acompanhamento passa sozinho ao descendente vivo mais velho: filhos, depois netos, e assim por diante. Isso gera um evento `linhagem` com `dados.de` e `dados.para`. Se não houver descendente vivo, `acompanhada` vira -1.

## Crônica

A crônica é escrita **ano a ano**, quando cada ano termina. Um ano escrito não muda mais.

| Chamada | Retorno |
|---|---|
| `cronica(ano_ini = 1, ano_fim = -1, com_prologo = true, com_epilogo = false) -> String` | Markdown dos anos completos no intervalo (-1 = até o último escrito), com os anos quietos resumidos numa linha |
| `cronica_ano(ano) -> String` | Markdown de um ano (`### Ano N` e o parágrafo), ou "" se o ano foi quieto ou ainda não terminou. O ano que acabou é escrito no dia 0 do ano seguinte, em duas fatias, para não pesar na virada: na hora 1, as frases dos eventos; na hora 2, o resumo da década e o censo (nos anos redondos) e a crônica dos povos, e só então o ano entra na crônica. |
| `ultimo_ano_na_cronica() -> int` | o último ano escrito: o ano anterior ao atual, a partir da hora 2 do dia 0 (das 0h às 2h do dia 0, ainda o de antes) |

O ano em andamento ainda não está na crônica. Para mostrar o que acabou de acontecer, a apresentação usa os eventos de camada "nota" e "chamado".

**Repetição.** Quando um evento tem mais de uma frase possível, a crônica evita a que já usou nos últimos 25 anos (se todas foram usadas, fica a mais antiga). Essa memória é gravada com o mundo. Só a escrita oficial de cada ano a usa e muda: as notas ao vivo (`curto`) e o relato da ausência não mexem nela.

## Determinismo

Todo sorteio da simulação vem de `mundo.rng`, com a semente dada. As consultas desta API não sorteiam nada. A mesma semente, com os mesmos poderes usados nos mesmos passos, dá o mesmo mundo e a mesma crônica.

## Salvar, carregar e ausência

```gdscript
const Persistencia = preload("res://nucleo/persistencia.gd")

Persistencia.salvar_async(mundo)                 # grava numa thread, sem travar o jogo (use durante o jogo)
Persistencia.salvamento_terminou(mundo)          # -> bool
Persistencia.terminar_salvamento(mundo)          # -> bool; espera a gravação e diz se deu certo
Persistencia.salvar(mundo)                       # -> bool; grava agora, na linha principal (use ao fechar)
Persistencia.existe()                            # -> bool
var mundo = Persistencia.carregar()              # -> mundo, ou null se não há arquivo válido
var r = Persistencia.carregar_e_avancar()        # -> {mundo, ausencia}, ou null
```

Todas aceitam um caminho como primeiro argumento (padrão: `user://mundo.txt`), depois do mundo nas que recebem o mundo.

**Salvar sem travar:** `salvar_async` tira, na linha principal, só um retrato do que pode mudar fora de um passo (os campos do mundo e a crônica): menos de 1 ms com o mundo grande. Pessoas, povos, zonas e eventos são lidos e gravados numa thread (cerca de 370 ms com o mundo grande).
- Enquanto a thread grava, o mundo não pode mudar. Por isso `avancar_hora()`, `usar_poder()`, `criar_povo()` e `abandonar()` esperam por ela. No jogo, a gravação acaba muito antes do passo seguinte.
- As consultas continuam valendo durante a gravação.
- O resultado fica em `mundo.ultimo_salvamento_ok` quando a gravação termina; `terminar_salvamento()` espera e devolve esse resultado.
- Chamar `salvar_async` ou `salvar` com outra gravação em andamento espera a anterior.
- Para o fechamento do jogo, `salvar()` continua síncrono: grava tudo antes de voltar (cerca de 360 ms com o mundo grande).
- Uma gravação interrompida no meio (o processo morto, falta de luz) nunca deixa o mundo ilegível: o arquivo novo só toma o lugar do antigo depois de gravado e conferido, e as cópias de segurança (abaixo) cobrem o resto. O teste mata o processo no meio de gravações e carrega de novo.

**O arquivo** é texto: o formato de Variant do Godot (`var_to_str`), com uma linha de cabeçalho. Ele guarda o mundo inteiro, incluindo o estado do sorteio e o estado do cronista, e também a hora real do salvamento (`mundo.salvo_em`, em segundos Unix). Os números reais são gravados pelos seus 64 bits ("@f:" seguido de um inteiro), porque a leitura de reais em texto do Godot perde o último dígito. O resultado é exato: um mundo salvo e carregado segue igual, passo a passo, ao que nunca parou. Desde a versão 2 do arquivo, pessoas, povos, zonas e eventos vão em colunas (os nomes dos campos uma vez, e os valores de cada um em ordem), o que deixa o arquivo com pouco mais da metade do tamanho. Arquivos das versões 1 e 2 continuam sendo lidos.

**Os antigos (versão 3).** Os eventos de mais de 300 anos e os mortos de mais de 300 anos saem da memória viva e vão para um arquivo à parte, ao lado do mundo salvo: `mundo.antigos.txt`, com as mesmas 3 cópias de segurança (`mundo.antigos.1.txt` a `.3.txt`).
- **Fica na memória viva o que o mundo ainda usa:** os eventos para onde o estado aponta (a origem de cada costume, dos nomes de lugares e de cada povo, as preces abertas, a fome, a doença e a seca em curso), os que outros eventos citam, o começo de cada era e o fim do mundo; e os mortos que esses eventos citam, os líderes, sacerdotes e fundadores, e a pessoa acompanhada.
- **Nada do histórico se perde:** `evento(id)` e `pessoa(id)` devolvem também os arquivados, decodificados, iguais ao que eram (um objeto novo a cada chamada). `eventos_desde()` e `texto_curto()` funcionam com qualquer id. A lista `mundo.eventos` continua do mesmo tamanho, com o id de cada evento na sua posição: os arquivados ficam como `null`. Não percorra essa lista direto; use as chamadas acima.
- **O mundo não muda:** o arquivamento é parte da simulação, e não do salvamento. Roda todo dia, no passo das 3h, com os eventos do mesmo dia de 300 anos atrás. O que percorria a história inteira (o primeiro ataque entre dois povos, os mortos entre eles, a pior fome, a seca anterior, a contagem de nascimentos e mortes do epílogo) lê um resumo do que saiu, salvo com o mundo. Um mundo sem arquivar, um arquivando e um salvo e carregado a cada 50 anos (inclusive no meio da virada) dão a mesma crônica, o mesmo sorteio, os mesmos eventos e o mesmo livro (`ferramentas_sim/testar_antigos.gd`).
- **O que só vale para os vivos sai com a morte:** o que a pessoa viveu (`memoria`) e os rancores. Nada lia isso de um morto.
- **A gravação:** o arquivo dos antigos é gravado antes do mundo, e só quando mudou. Ele só cresce: uma versão mais nova serve a um mundo salvo mais velho, que usa só as primeiras linhas. Se ele está estragado ou falta, `carregar()` tenta as cópias dele; se nenhuma tem as linhas de que o mundo precisa, o mundo vem de uma cópia anterior do `mundo.txt` (com `recuperado_de`), ou não carrega. `abandonar()` apaga os dois, com as cópias. A estante não muda: os livros já são texto.
- **Um mundo salvo antes da versão 3** abre normalmente. No primeiro passo das 3h depois de carregar, ele arquiva de uma vez tudo o que já passou de 300 anos: um passo de ~0,6 s com 1000 anos de história, uma vez só.

**A gravação é segura:** o núcleo grava num arquivo `.novo`, confere o que gravou e só depois troca pelo antigo. Uma queda no meio não estraga o mundo salvo.

**Cópias de segurança:** a cada salvamento bem-sucedido, as 3 versões anteriores ficam guardadas, rodando: `mundo.1.txt` é a anterior, `mundo.2.txt` a de antes, `mundo.3.txt` a mais velha.
- Se o `mundo.txt` estiver estragado ou ilegível (cortado, vazio, com lixo, sem alguma parte), `carregar()` tenta as cópias, da mais nova para a mais velha. O mundo que voltou de uma cópia traz `mundo.recuperado_de` com o caminho dela (vazio quando veio do arquivo certo). Se nenhuma serve, devolve null.
- `carregar_e_avancar()` conta isso no retorno: `ausencia.recuperado_de`, e o `relato` começa com "*O mundo salvo estava estragado. Ele voltou da cópia de segurança de <data>, e o que aconteceu depois dela se perdeu.*"
- `existe()` também vale quando só há cópias.
- `abandonar()` apaga o mundo e as cópias dele, e o arquivo dos antigos com as cópias dele.

**Custo:** com 38 anos de mundo, o arquivo tem 184 KB e cada operação leva cerca de 25 ms. O tamanho cresce com o número de eventos, que são uns 25 por ano. Com 284 anos (o mundo grande da regressão, 10 mil eventos), o arquivo tem 3 MB; `salvar_async` custa menos de 1 ms na linha principal (e ~370 ms na thread), `salvar` ~360 ms e `carregar` ~420 ms. Com 1000 anos, graças ao arquivo dos antigos, o `mundo.txt` tem 4,5 a 5,3 MB (e o arquivo dos antigos, uns 6 MB), `carregar` leva 360 a 390 ms, `salvar_async` 1 a 3 ms na linha principal (e ~0,6 s na thread), e o mundo carregado ocupa 82 a 88 MB (veja `ferramentas_sim/resistencia/LEIAME.md`). O documento técnico pede salvar a cada dia de jogo e ao fechar: durante o jogo, use `salvar_async`. Isso é decisão da apresentação; o núcleo só salva quando chamado.

### Ausência

```gdscript
var aus := mundo.avancar_ausencia(segundos_reais)   # segundos desde mundo.salvo_em
```

O mundo avança sem gráfico, à razão de um passo a cada 112,5 s reais, até o teto de 1 ano de jogo (960 passos). Em tempo de computador, um ano leva cerca de 0,02 s. `carregar_e_avancar()` já faz isso com o relógio do sistema.

O retorno:

| Campo | O que é |
|---|---|
| `passos` | quantas horas de jogo passaram |
| `teto_atingido` | bool: a ausência passou de um ano, e o mundo esperou no teto |
| `de`, `ate` | `tempo()` antes e depois |
| `relato` | a crônica do período, em markdown (veja abaixo) |
| `chamados` | os eventos de camada "chamado" que aconteceram no período, no formato de `eventos_desde()`. Inclui `os_ultimos` e `fim_do_mundo`, se a extinção aconteceu durante a ausência. |

**O `relato`:**
- os anos que terminaram durante a ausência vêm da crônica oficial (`### Ano N`), inteiros, inclusive o que aconteceu antes de o deus sair;
- o ano em andamento vem como `### Ano N (até agora)`. É escrito à parte, sem consumir nada da crônica oficial, que sai completa quando o ano terminar;
- no fim, sempre, o de sempre em uma ou duas linhas: quem nasceu, morreu e casou no período, e o trabalho da estação no povo maior ("Nesses dez dias, nasceram duas crianças em Zeor. Em Zeor, colheram as roças e guardaram o grão."). Não há mais a linha "Enquanto o deus esteve fora, nada de notável aconteceu".

Exemplo de 30 dias fechado (teto de um ano):

> ### Ano 39 (até agora)
>
> Em Zeor, Rabea pediu: «Que Apaga o Sol, não deixes nossos filhos morrerem de fome.» A fome passou, e Zeor viu nisso a mão do Que Apaga o Sol. A crônica sabe que foi acaso. Linmiut morreu de frio.

## Cenários para testes (ferramentas)

Um cenário é um arquivo de texto com o que o deus faz, usado pelas ferramentas de teste em `jogo/ferramentas_sim/`. O jogo não usa cenários: o jogador age por `usar_poder`. O formato completo está em `nucleo/cenario.gd`.

```
ano 28, dia 15: raio sobre o líder do lago        # em data marcada
na próxima seca: chuva onde houver seca           # condicional: dispara uma vez, quando acontece
na próxima fome, a partir do ano 55: fartura onde houver fome
sempre que houver seca: chuva onde houver seca     # repete, no máximo uma vez por ano
quando houver guerra: erguer terra onde houver guerra
ano 85, dia 18: fogo forte na floresta             # "fraco"/"forte" mudam a intensidade
```

Condições: seca, fome, guerra, doença e prece.

## Ferramentas de teste (`jogo/ferramentas_sim/`)

Todas rodam sem gráfico: `ferramentas_sim/godot.sh res://ferramentas_sim/<script>.gd`.

| Script | O que faz |
|---|---|
| `regressao.gd` | Primeiro, mede o desempenho com a população máxima (veja `desempenho.gd`): nenhum passo acima de 5 ms e nenhuma consulta acima de 2 ms. Depois, roda as sementes 1 a 5 e o cenário de intervenções por 100 anos. Cada uma roda duas vezes e precisa dar a mesma crônica. Também salva e carrega a semente 1 no meio. Grava as crônicas em `cronicas/` e sai com código 1 se algo falhar. |
| `testar_api.gd` | Testa esta API: posições, ninguém na água, poderes e graus, linhagem, crônica. |
| `testar_persistencia.gd` | Testa salvar, carregar e a ausência; e as cópias de segurança, estragando de propósito o mundo salvo (cortado, vazio, com lixo, mexido), a estante (índice e livros) e o arquivo dos antigos (cortado, ausente; abandonar apaga ele também). |
| `testar_antigos.gd` | O arquivo dos antigos não muda o mundo: a mesma semente sem arquivar, arquivando, e salva e carregada a cada 50 anos (também entre as fatias da virada), comparando crônica, sorteio, passo, eventos, população e livros (`-- <semente> <anos> [nenhum\|caprichoso] [ano_do_fim]`). |
| `testar_gramatica.gd` | Testa casos difíceis de concordância. |
| `equilibrio.gd` | O equilíbrio de longo prazo: em quantos anos o primeiro povo chega à agricultura (`estagio2 <de> <ate>`), quantos mundos voltam vivos de um ano de ausência a partir de vários anos (`ausencia <de> <ate>`), e as décadas de um mundo com o que houve de notável em cada uma (`monotonia <semente> <anos>`). Grava em `ferramentas_sim/equilibrio/`, com um LEIAME. |
| `poderes.gd` | Os 11 poderes vistos como jogador: um gesto em 3 intensidades e 3 mundos (estágio 1, agricultura, estágios altos), com o que mudou um dia depois (mortos, abrigos, estoque, comida, água, fé, nome do deus, crenças, costumes, eventos, crônica, pensamento), e o mesmo poder 10 vezes seguidas. Grava uma tabela por poder em `ferramentas_sim/poderes/`, com um LEIAME (`-- <poder> ...`). |
| `preces.gd` | As preces e os chamados vistos como jogador: 3 mundos de 50 anos em três modos (o deus calado; o que atende cada prece com o poder que faz sentido; e o que faz o contrário), com as preces por década, os chamados por tipo e a reação a cada desfecho (crônica, memória e dica de quem rezou, no dia seguinte). Grava em `ferramentas_sim/preces/`, com um LEIAME para a apresentação (`-- <semente> <modo>`). |
| `cronica_estagios.gd` | Roda um mundo até algum povo chegar ao estágio 6 e grava a crônica do primeiro estágio 3 até 60 anos depois, mais a crônica do povo que chegou lá, para ler (`-- <semente> [ano_limite] [saida.md]`). Nas sementes 1, 3, 4, 5 e 6, o estágio 6 chega entre os anos 114 e 204. |
| `testar_dica.gd` | Imprime as dicas (`fazendo`, `pensamento`, `humor`) de pessoas em 10 mundos, anos e horas diferentes (até um de 244 pessoas no ano 286), e a dica das cabanas às 23h, e confere: nada vazio, pensamento até 60 caracteres e sem modelo por preencher, nada sobre quem joga, quem dorme com humor de sono, duas pessoas nunca com a mesma frase na mesma hora (nos mundos de até 60 pessoas; nos maiores, só entre povos, quando as frases acabam), a mesma pessoa nunca voltando a uma frase de outro bloco de 2 horas do mesmo dia, ninguém pensando na praia, em pescar ou em brincar enquanto já está ali ou fazendo aquilo, ninguém com a mesma frase 8 horas seguidas (em povos de até 40), o sonho da cabana como narração, o sorteio do mundo intocado; e mede o custo da primeira consulta do dia e da hora. |
| `testar_vida.gd` | Testa se a cena tem vida, hora a hora, em 5 sementes e nas 4 estações: de dia, nunca mais de 40% na mesma ação (como a tela mostra: a `acao`, e o `detalhe` só em `colher` e nas caminhadas) e gente em 3 das 4 zonas; das 17h às 21h, nunca mais de 75% na mesma ação; à noite, alguém acordado; a cada hora, alguém mudando de lugar; das 6h às 20h, a cada hora, um acontecimento legível (alguém atravessando 40 px ou mais com carga ou ferramenta, crianças correndo, um incidente ou a caçada); de 0h às 4h, algo além do vigia (alguém que acorda, as brasas, um bicho da noite); ninguém parado a menos de 6 px do centro da fogueira do seu povo; durante a caçada, ninguém de fora dela parado a menos de 20 px do porco; de dia (6h às 17h), ninguém de pé, deitado, sentado no fogo ou conversando no mesmo ponto por mais de 21 min, fora das cenas; à tarde, em média uma conversa a cada 20 min ou menos num povo de 12 pessoas (a média é impressa). Os 40% contam gente inteira, arredondando para cima: de 12 pessoas, até 5 (41,7%) na mesma ação passam. Mostra a tabela hora a hora da semente 1, dia 4. |
| `estilos.gd` | Simula 4 deuses (benevolente, cruel, ausente, caprichoso) por 100 anos, em 3 sementes, e compara fé, nomes do deus, costumes, dependência, guerras santas, secularizações e população. Tabela, trechos de crônica e leitura em `estilos/`. |
| `testar_fase2.gd` | Testa estágios, construções, ruínas, cultura, crônica do povo, fim do mundo, povo novo, eras, estante e abandono. |
| `gerar.gd` | Gera a crônica de uma semente, com ou sem cenário. |
| `sondar.gd` | Mostra a população por década e a contagem de eventos de várias sementes. |
| `sondagem_longa.gd` | Roda mundos por centenas de anos e mede população, povos, estágio máximo, extinções, eras, intervalo entre marcos e entre viradas, anos quietos, repetição, fomes, guerras, profetas, secularizações e mudanças de poder, e o ano em que o primeiro povo chega a cada estágio (tabela de mínimo, mediana e máximo em `sondagem/<rotulo>-estagios.txt`; a de 10 sementes por 300 anos está em `sondagem/estagios.txt`). Quando o mundo fica vazio, cria um povo novo depois de 10 anos, como faria um jogador. As crônicas e as métricas ficam em `sondagem/`. |
| `resistencia.gd` | Teste de resistência: um mundo por muitos anos (`-- <semente> <nenhum\|caprichoso> [anos]`), medindo a cada 50 anos o tamanho do mundo salvo, salvar, carregar (e se o mundo carregado é igual), memória, objetos vivos, a ausência de 1 ano e o pior dia e ano. Resultados de 5 sementes por 1000 anos, com e sem deus, em `resistencia/LEIAME.md`. |
| `resistencia_passos.gd` | Carrega um mundo velho salvo por `resistencia.gd` e mede passo a passo, como a apresentação usa o mundo: piores passos e consultas, `salvar_async` e a montagem da rotina. |
| `resistencia_ciclo.gd` | O ciclo completo: fim do mundo, livro na estante, povo novo nas ruínas, salvar e carregar depois do fim. |
| `medir_desempenho.gd` | `medir` (padrão) mede as janelas de desempenho e mostra os piores passos e consultas. `gerar` procura o maior mundo no estágio 6 e o guarda, comprimido, em `mundo_grande.bin` (refazer se o formato do mundo salvo mudar). |
| `desempenho.gd` | Mede como a apresentação usa o mundo: a cada passo, avança uma hora e consulta tudo o que `simulacao.gd` lê. Cada janela (uma virada de ano com 287 pessoas e uma virada de década) roda em 3 processos novos, e vale o menor tempo de cada passo, porque esta máquina tem picos de outros processos. |

## Estágios e a relação com o deus

| Estágio | Saber | Como surge | O que muda |
|---|---|---|---|
| 3, pedra | cortar pedra | povo com 18 pessoas ou mais e gente engenhosa; mais depressa depois de terremoto, tempestade ou dilúvio | casas de pedra e templo; os sacerdotes ganham força (o dobro de éditos, e o poder pode passar ao templo) |
| 4, metal | trabalhar o metal | gente engenhosa; mais depressa em tempo de guerra | as guerras matam mais (um morto a mais do lado vencido) e os povos ficam mais fortes |
| 5, escrita | escrever | gente engenhosa ou curiosa; mais depressa com sacerdote | os costumes não se esquecem mais; o saber se ensina 3 vezes mais rápido; o arquivo pode salvar um saber perdido; o povo escreve a própria crônica; o estudo do céu enfraquece o presságio |
| 6, engenharia | canais e moinhos | povo com 30 pessoas ou mais; mais depressa depois de fome | irrigação: a seca pesa pouco e não gera prece por chuva; tudo impressiona 40% menos, porque o povo precisa menos do deus. É o teto. |

**A agricultura (estágio 2):** em 60 mundos, mediana de 25 anos, 90% até 38 e no máximo 50 (veja `ferramentas_sim/equilibrio/LEIAME.md`). Depois de 25 anos no estágio 1 (`Mundo.ENSINO_DEMORA`), descobrir e ensinar a plantar apressam (a cada década a mais, a chance de antes outra vez); quem já soube e esqueceu redescobre mais depressa; e num povo com menos de 4 adultos basta que todos saibam. O saber ainda se perde quando morrem os que sabiam. Quanto tempo leva: veja `jogo/ferramentas_sim/sondagem/estagios.txt` (10 mundos de 300 anos). Depois de 40 anos no mesmo estágio, a necessidade ensina: a chance de descobrir o próximo saber cresce a cada década a mais, e qualquer adulto pode descobrir, não só os engenhosos e curiosos. Isso encurta os platôs longos (que chegavam a 158 anos, ou dois meses reais sem mudar de estágio) sem mexer no tempo típico. Na tabela atual (`estagios.txt`, refeita depois do limite da terra e do esquecimento do deus ausente), nenhum povo fica mais de 101 anos na agricultura. O mundo da semente 2 aparece com 214 anos no estágio 2 porque ficou vazio e recomeçou no ano 146 com um povo novo, que levou ~60 anos para chegar à pedra.

O saber de cada estágio vive nas pessoas, que o ensinam devagar. Quando morre o último que sabia, o povo regride um estágio, a não ser que a escrita o salve. O sonho do deus dá a alguém o saber do próximo estágio, que pode servir à paz ou à guerra.

## A crônica do próprio povo

```gdscript
mundo.cronica_do_povo(grupo_id) -> String    # markdown; vazio se o povo nunca escreveu
```

Um povo que chega à escrita passa a contar a própria história, ano a ano, do seu jeito.
- Começa por um mito de origem: "No começo, o Olho Escuro escolheu nossos pais...".
- Registra as vitórias que o deus deu, os castigos merecidos e as preces atendidas.
- Muitas vezes, contradiz a crônica do deus: o povo escreve que a chuva veio porque rezou, e a crônica do deus diz que foi acaso. A crônica do deus aponta a contradição e cita a voz do povo: "Nas tabuletas de Sagak, a história é outra: «A seca acabou porque rezamos.»"

## Fim do mundo, eras e estante

- **Extinção:** quando não resta ninguém, o mundo emite `fim_do_mundo` e fecha a crônica da era como livro, em `mundo.livros`.
  - O mundo vazio continua: o clima segue, a natureza retoma o espaço e as ruínas envelhecem.
  - `usar_poder` devolve `ok: false`.
- **Povo novo:** `mundo.criar_povo(x) -> {ok, grupo, era}` só funciona com o mundo vazio.
  - Cria uma família de 12 pessoas, de cultura nova, na zona de x. Se x cair no lago, o povo nasce na praia.
  - `mundo.era` passa a 2, 3 e assim por diante, e `mundo.era_inicio_ano` marca o começo da era.
  - O povo novo encontra as ruínas: explica-as (`mito_ruinas`) e pode aprender nelas.
  - A crônica da nova era começa com outro prólogo.
- **`mundo.nome_da_era(n)`** devolve "A Primeira Era", "A Segunda Era" etc.
- **Estante** (`preload("res://nucleo/estante.gd")`): guardada em `user://estante/`, fora do mundo salvo, e sobrevive ao abandono do mundo.
  - `Estante.livros() -> Array[{id, titulo, era, semente, ano_ini, ano_fim, guardado_em}]`
  - `Estante.ler(id) -> String` devolve o markdown do livro.
  - Tudo tem cópia, porque a estante é insubstituível. Cada livro é gravado também como `<id>.1.md`, e `ler` usa a cópia se o arquivo sumiu ou está vazio. O índice guarda as 3 versões anteriores (`indice.1.txt` a `indice.3.txt`); se ele estiver estragado, valem as cópias, e se todas estiverem, o índice é refeito a partir dos livros (com o título da primeira linha).
  - `Persistencia.salvar(mundo)` leva para a estante os livros que ainda não estão lá.
- **Abandonar o mundo:** `Persistencia.abandonar(mundo) -> livro` fecha a crônica da era atual como livro (mesmo com o povo vivo), guarda o livro na estante e apaga o mundo salvo. Depois, a apresentação começa outro mundo com `Mundo.new(semente)`, e a estante continua lá.

## Como o povo reage ao estilo do deus

O custo de intervir é a interpretação: o mesmo povo sai diferente conforme o deus que tem. Veja `ferramentas_sim/estilos/`.
- **O acaso convence menos que o deus:** uma prece que se cumpre sozinha sobe a fé em 0,08, contra 0,15 de um milagre de verdade. Ela também alivia menos o silêncio e não conta para a dependência: só um deus que responde de verdade cria povos dependentes e, depois, exigentes.
- **Um deus que nunca aparece é esquecido:** depois de 15 anos sem nenhum gesto do deus (qualquer poder que o povo sinta), a fé de quem não é devoto esfria 3% ao ano. O povo pode se secularizar a partir do estágio 3.
- **Um deus que mata é aplacado:** um raio do deus que mata alguém, lido como castigo, cria o costume das oferendas.
- **A terra tem limite:** acima de 320 pessoas no mundo, nascem cada vez menos crianças (`Mundo.LOTACAO`).
- `grupo.ultimo_divino`: o dia do último gesto do deus que o povo sentiu (-1: nunca).

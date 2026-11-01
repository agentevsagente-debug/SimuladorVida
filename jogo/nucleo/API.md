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
| `nome_deus` | como o povo chama o deus («o Que Rega»); vazio se ainda não crê ou se é cético |
| `ceticos` | o povo deixou de rezar |
| `em_fome`, `doenca` | estados atuais |
| `costumes` | lista de chaves: "estocar", "agua", "festa_chuva", "tabu_tempestade", "queimar_mortos", "lancas", "oferendas" |
| `cultura` | as 6 dimensões culturais, como palavras: `deus` ("devota", "temerosa", "cetica" ou "" se ainda não crê), `estranhos` ("acolhedora", "desconfiada"), `poder` ("lider", "conselho", "sacerdotes"), `recursos` ("partilha", "acumula"), `violencia` ("pacifica", "guerreira"), `mortos` ("enterram", "queimam", "veneram" ou "") |
| `aparencia` | `{parede, telhado, simbolo, roupa}`, para escolher as peças de `arte_claude/pecas/culturas/` e dos estágios: parede "taipa", "pedra" ou "madeira"; telhado "palha", "telha" ou "tabuas"; símbolo "sol", "lua" ou "arvore"; roupa "turquesa", "lilas" ou "rosa". Sai do nome do povo (não sorteia nada); um povo novo herda a do povo de onde saiu e muda uma coisa. |
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

`{tipo, x, largura, grupo, estagio, aparencia, ruina}`, com `x` no centro da peça. `estagio` é o estágio do povo e diz qual arte usar (a casa do estágio 3 é `casa_pedra`, a do 4 é `casa_enxaimel`, e assim por diante). `aparencia` é a cultura do povo, a mesma de `grupos_visiveis()`: `{parede, telhado, simbolo, roupa}`, para escolher as variações de `arte_claude/pecas/culturas/`. `ruina` é sempre false aqui. Tipos:

| Tipo | Largura | Quando existe |
|---|---|---|
| `fogueira` | 8 | sempre, no centro do acampamento |
| `altar` | 8 | o povo crê (e não é cético) |
| `templo` | 32 | o povo crê e está no estágio 2 ou mais (o templo do estágio: degraus no 3, colunas no 4, escrita no 5, cúpula no 6) |
| `cabana` | 16, 24 ou 32 | as moradias: cabana no estágio 1 (16), casa de taipa no 2 (24), casas maiores do 3 em diante (32). Do estágio 3 em diante, há uma casa para cada 8 pessoas. |
| `celeiro` | 24 | estágio 2 ou mais, se o povo tem o costume de estocar |
| `roca` | 16 | estágio 2 ou mais, uma para cada ~6 adultos, até 4; `irrigada: true` no estágio 6 (canal ao lado) |
| `forja` | 24 | estágio 4 ou mais |
| `arquivo` | 32 | estágio 5 ou mais (a biblioteca da arte) |
| `moinho` | 32 | estágio 6 |
| `muralha` | 16 | estágio 6, povo guerreiro: uma torre em cada ponta do acampamento |
| `barco` | 24 | estágio 6, povo do lago ou da praia: na água, em x = 112 |

As peças vão para o primeiro lugar livre perto da fogueira, numa ordem fixa. As duas primeiras moradias vêm logo depois da fogueira, antes do altar e das obras grandes, para que uma vila nunca fique sem casa. Só mudam de lugar quando o número de peças muda ou quando o povo se muda. Moradias, celeiro, moinho e roças que não cabem na faixa do povo ficam de fora. As peças únicas (altar, templo, arquivo, forja) sempre aparecem, mesmo encostadas.

### `ruinas_visiveis() -> Array[Dictionary]`

Construções abandonadas, de povos que acabaram, se mudaram ou foram conquistados, inclusive de eras anteriores: `{tipo, x, largura, estagio, povo, era, ano, anos, aparencia, ruina: true}`. `anos` é a idade da ruína, para cobrir de mato.
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

**O dia usa o mundo inteiro.** Quase todo dia, de 2 a 4 adultos saem juntos de manhã para a caçada no morro (ou na mata alta, para quem mora no morro) e voltam entre 16h e 17h. Cada povo tem um pescador no dia, que pesca até 17h30, alguém que vai e vem do lago com água e um ou dois que colhem longe do acampamento. As crianças brincam na praia de manhã (9h às 11h30) e à tarde (14h às 17h40). De dia, as pessoas ocupam pelo menos 3 das 4 zonas e nunca mais de 40% delas fazem a mesma coisa (veja `testar_vida.gd`).

**Fim de tarde e noite.** Das 16h15 às 17h15, cada um volta com a carga. Depois, uns vão ao lago (banho ou água), outros à lenha, outros descansam em casa. Das 17h30 às 19h, uns cozinham (`cozinhar`) e os outros conversam e comem (`comer`); as crianças brincam na praia até 17h50 e comem depois dos grandes. Depois do jantar, uns ninam os pequenos, tecem ou consertam em casa, e o resto fica na fogueira, com conversas e crianças correndo. Dorme-se das 21h às 22h30 até as 5h ou 6h30, mas a noite tem sempre alguém acordado: o vigia faz a ronda em três turnos (22h à meia-noite, meia-noite às 2h50, 2h30 às 5h). Às vezes um casal fica olhando o céu, alguém reza tarde ou vai ao lago de madrugada, e em noites sem tempestade há uma roda de histórias até as 23h. O doente passa o dia em casa, acordando de vez em quando.

**Lugares sem fila.** Cada pessoa tem um lugar de descanso próprio perto do fogo, fixo enquanto o povo não muda: os lugares ficam a 7 px uns dos outros, alternando os lados da fogueira e a pelo menos 6 px do centro dela, por ordem de chegada ao mundo. É ali que ela fica na `fogueira` da noite e nas conversas em volta do fogo. Quem não cabe na faixa do povo vai direto para casa à noite (`dormir`). Em casa, cada um dorme num ponto próprio ao longo da largura da moradia. Em povos grandes, a coleta se espalha pela faixa de trabalho inteira. Ninguém fica na água (x < 126), a não ser remando; quem pesca fica na margem, de 126 a 136.

As crianças correm umas atrás das outras perto do fogo (trechos curtos de `andar` e `parado`). Cada pessoa faz de 2 a 4 atividades por dia, conforme o estágio, o papel, a zona e os traços, e as repete em ciclos até o fim da tarde. Os horários de acordar e dormir variam, e dois dias nunca são iguais (às 10h, só 4% a 6% das pessoas estão no mesmo lugar que no dia anterior). Tudo sai da semente.

**Custo e cache:**
- A rotina do dia (lugares, cenas, vida social, o plano de cada pessoa e as agendas das 24 horas) é montada **numa thread de trabalho**, sem custo para a linha principal. Custa de 60 a 120 ms de thread com a população máxima.
  - Ela começa logo depois do passo da 0h à 1h (em que acontecem os eventos do dia) e entra assim que fica pronta, em décimos de segundo. No mais tardar às 4h, antes de alguém acordar, o passo espera por ela; no jogo, ela fica pronta muito antes.
  - Até ela entrar, todos aparecem dormindo em casa, como na última hora do dia anterior.
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
| `cacada` | quase todo dia, das 6h20 até a volta, entre 16h e 17h | 2 a 4 adultos caçando longe (`x` é o lugar da caça) | `vazia`: voltaram sem nada |
| `caca_vazia` | na volta de uma caçada sem caça | os caçadores, de mãos vazias perto do fogo | |
| `vigia` | toda noite, em três turnos | o vigia, que vai e volta entre o fogo e a beira do acampamento | |
| `historias` | algumas noites sem tempestade, 21h15 às 23h | até 6 pessoas conversando em volta do fogo | |
| `briga_criancas` | incidente: 2 ou 3 por povo por dia, entre 9h20 e 16h20 | duas crianças brigando; um adulto separa | |
| `tombo` | incidente | alguém se machuca de leve; outro cuida | |
| `animal` | incidente | um animal aparece na beira do acampamento; dois adultos espantam (`x` é onde ele está) | |
| `perdido` | incidente | uma criança se perde longe do acampamento; um adulto vai buscar | |
| `discussao` | incidente | dois adultos (de preferência rancorosos ou ambiciosos) discutem | |
| `construcao` | no dia e no seguinte a uma conquista de estágio, à agricultura, ou a cabanas derrubadas por tempestade, terremoto ou dilúvio | até 6 pessoas `construir` na obra nova (templo, forja, arquivo, moinho ou casas) | `obra` |

`posicao_de(pessoa_id) -> float` devolve o x de uma pessoa no meio da hora corrente (-1 se ela morreu).

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
| `prece` | alguém pede ao deus (seca, fome, doença, frio, guerra) | chamado |
| `prece_atendida`, `prece_sem_resposta` | a necessidade passou, ou não passou (ou quem foi pedido morreu) | nota |
| `fome_inicio`, `doenca_inicio`, `ataque` | começa uma fome, uma doença ou uma luta | chamado |
| `os_ultimos` | restam 5 pessoas ou menos no mundo | chamado (o mais intenso) |
| `fim_do_mundo` | não resta ninguém | chamado |
| `crenca`, `separacao`, `conquista`, `agricultura` | marcos do mundo | chamado (importância ≥ 8) |
| `nascimento`, `morte`, `casamento` | ciclo de vida | conforme a importância |
| `tempestade`, `seca_inicio`, `seca_fim`, `eclipse` | clima e céu; `seca_fim` traz `dados.irrigados`, os povos com canais (estágio 6), que quase não sentiram a seca | nota |
| `chuva_divina`, `raio_divino`, `fartura_divina`, `fogo_divino`, `terra_erguida`, `sonho`, `seca_divina`, `diluvio`, `terremoto_divino`, `pressagio`, `cura` | resultado de `usar_poder` | nota ou chamado |
| `linhagem` | a pessoa acompanhada morreu, e o acompanhamento passou adiante | nota |
| `guerra_inicio`, `guerra_fim` | uma briga vira guerra com nome (na segunda batalha) e termina: trégua, imposição do deus, conquista, extinção ou esfriou | chamado |
| `cometa`, `terremoto`, `gemeos` | presságios naturais, além do `eclipse`. O terremoto derruba cabanas e pode matar. | nota |
| `cultura` | um povo muda uma dimensão da cultura (`dados.dimensao`: "estranhos", "mortos", "poder", "recursos"). Para o poder, `dados.como` diz como: "revolta" (contra o templo), "golpe" (um ambicioso acaba com o conselho), "tirania" (o povo cansa de um líder só) ou "templo" (os sacerdotes passam a mandar) | nota |
| `reforma` | uma geração abandona um costume herdado ou de origem esquecida | nota |
| `dependencia`, `exigencia`, `desamparo` | o povo deixa de se preparar porque o deus sempre responde; passa a pedir coisas pequenas; e, no primeiro silêncio, paga caro | nota |
| `expedicao` | uma família parte além da borda do mundo e nunca volta | nota |
| `descoberta_tecnica` | alguém descobre o saber do próximo estágio (`dados.saber`: "pedra", "metal", "escrita", "engenharia") | nota |
| `estagio` | o povo chega a um estágio novo (`dados.estagio`, de 3 a 6) | chamado |
| `regressao` | morreu o último que sabia, e o povo volta um estágio (`dados.de`, `dados.para`) | chamado |
| `arquivo_salvou` | com a escrita, alguém reaprende nas tabuletas o saber que ia se perder | nota |
| `estudo_do_ceu` | o povo passa a prever eclipses: sinais no céu impressionam menos (metade no estágio 5, um quarto no 6) | nota |
| `ruinas_saber`, `mito_ruinas` | alguém aprende nas ruínas (só o que ninguém do povo sabe ainda); um povo explica ruínas de quem não existe mais ("gigantes", "castigo" ou "gente"), pelo que viu lá (`dados.obra`: templo, muralha, moinho, arquivo, forja, celeiro, cabana ou fogueira; `dados.antiga`: de uma era anterior) | nota |
| `livro_fechado` | a crônica de uma era se fechou como livro | nota |
| `peste` | uma doença vem de longe e entra em todos os povos; mata muito por cerca de 20 dias (uma vez a cada ~150 anos) | chamado |
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
| `x` | onde está quem reza agora |
| `texto` | a prece em português, sempre a mesma para o mesmo evento: «Que Rega, que a chuva volte.» |
| `curto` | uma frase de até 40 caracteres para a dica do cursor: "Kurpeya pede comida", "Viem pede a cura de Lou" |

Um povo sem crença, ou cético, não reza e por isso não aparece aqui. É o ponto cego do documento funcional.

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

A precisão conta para o raio e o sonho, que acertam a pessoa mais perto de x, se ela estiver a até 6 pixels. A força da reação do povo cresce com o grau.

| Poder | Sinal | Milagre | Imposição |
|---|---|---|---|
| `chuva` | garoa: sobe a água, não acaba a seca | acaba a seca naquela zona; os vizinhos ainda secos sentem inveja | idem, e força trégua entre os povos da zona e seus inimigos |
| `raio` | cai perto, não mata ninguém | mata quem está sob x, lido como castigo, martírio ou azar; ou cai no chão, se não houver ninguém | idem, mais trégua forçada; o lugar fica amaldiçoado e o povo tende a partir |
| `fartura` | comida a mais, parece natural | fartura que acaba a fome; os povos com fome em outras zonas sentem inveja | (mesmo efeito do milagre) |
| `fogo` | queima pouco | queima a zona, cabanas e estoque, e pode matar; lido como purificação ou maldição | (mesmo efeito do milagre) |
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
| `cronica_ano(ano) -> String` | Markdown de um ano (`### Ano N` e o parágrafo), ou "" se o ano foi quieto ou ainda não terminou. O ano que acabou é escrito na hora 1 do dia 0 do ano seguinte (assim o custo não se soma ao da virada). |
| `ultimo_ano_na_cronica() -> int` | o último ano escrito (é sempre o ano anterior ao atual) |

O ano em andamento ainda não está na crônica. Para mostrar o que acabou de acontecer, a apresentação usa os eventos de camada "nota" e "chamado".

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

**O arquivo** é texto: o formato de Variant do Godot (`var_to_str`), com uma linha de cabeçalho. Ele guarda o mundo inteiro, incluindo o estado do sorteio e o estado do cronista, e também a hora real do salvamento (`mundo.salvo_em`, em segundos Unix). Os números reais são gravados pelos seus 64 bits ("@f:" seguido de um inteiro), porque a leitura de reais em texto do Godot perde o último dígito. O resultado é exato: um mundo salvo e carregado segue igual, passo a passo, ao que nunca parou. Desde a versão 2 do arquivo, pessoas, povos, zonas e eventos vão em colunas (os nomes dos campos uma vez, e os valores de cada um em ordem), o que deixa o arquivo com pouco mais da metade do tamanho. Arquivos da versão 1 continuam sendo lidos. Nada do histórico é descartado: a crônica e a memória do mundo leem eventos antigos (os mortos de cada ataque, a pior fome, a seca anterior, a origem dos costumes e dos nomes de lugares, os feitos de cada pessoa), e cortar o histórico mudaria o texto.

**A gravação é segura:** o núcleo grava num arquivo `.novo`, confere o que gravou e só depois troca pelo antigo. Uma queda no meio não estraga o mundo salvo.

**Cópias de segurança:** a cada salvamento bem-sucedido, as 3 versões anteriores ficam guardadas, rodando: `mundo.1.txt` é a anterior, `mundo.2.txt` a de antes, `mundo.3.txt` a mais velha.
- Se o `mundo.txt` estiver estragado ou ilegível (cortado, vazio, com lixo, sem alguma parte), `carregar()` tenta as cópias, da mais nova para a mais velha. O mundo que voltou de uma cópia traz `mundo.recuperado_de` com o caminho dela (vazio quando veio do arquivo certo). Se nenhuma serve, devolve null.
- `carregar_e_avancar()` conta isso no retorno: `ausencia.recuperado_de`, e o `relato` começa com "*O mundo salvo estava estragado. Ele voltou da cópia de segurança de <data>, e o que aconteceu depois dela se perdeu.*"
- `existe()` também vale quando só há cópias.
- `abandonar()` apaga o mundo e as cópias dele.

**Custo:** com 38 anos de mundo, o arquivo tem 184 KB e cada operação leva cerca de 25 ms. O tamanho cresce com o número de eventos, que são uns 25 por ano. Com 284 anos (o mundo grande da regressão, 10 mil eventos), o arquivo tem 3 MB; `salvar_async` custa menos de 1 ms na linha principal (e ~370 ms na thread), `salvar` ~360 ms e `carregar` ~420 ms. O documento técnico pede salvar a cada dia de jogo e ao fechar: durante o jogo, use `salvar_async`. Isso é decisão da apresentação; o núcleo só salva quando chamado.

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
- se nada de notável aconteceu, vem uma linha dizendo isso.

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
| `testar_persistencia.gd` | Testa salvar, carregar e a ausência; e as cópias de segurança, estragando de propósito o mundo salvo (cortado, vazio, com lixo, mexido) e a estante (índice e livros). |
| `testar_gramatica.gd` | Testa casos difíceis de concordância. |
| `testar_vida.gd` | Testa se a cena tem vida, hora a hora, em 5 sementes e nas 4 estações: de dia, nunca mais de 40% na mesma ação (como a tela mostra: a `acao`, e o `detalhe` só em `colher` e nas caminhadas) e gente em 3 das 4 zonas; das 17h às 21h, nunca mais de 75% na mesma ação; à noite, alguém acordado; a cada hora, alguém mudando de lugar. Mostra a tabela hora a hora da semente 1, dia 4. |
| `estilos.gd` | Simula 4 deuses (benevolente, cruel, ausente, caprichoso) por 100 anos, em 3 sementes, e compara fé, nomes do deus, costumes, dependência, guerras santas, secularizações e população. Tabela, trechos de crônica e leitura em `estilos/`. |
| `testar_fase2.gd` | Testa estágios, construções, ruínas, cultura, crônica do povo, fim do mundo, povo novo, eras, estante e abandono. |
| `gerar.gd` | Gera a crônica de uma semente, com ou sem cenário. |
| `sondar.gd` | Mostra a população por década e a contagem de eventos de várias sementes. |
| `sondagem_longa.gd` | Roda mundos por centenas de anos e mede população, povos, estágio máximo, extinções, eras, intervalo entre marcos e entre viradas, anos quietos, repetição, fomes, guerras, profetas, secularizações e mudanças de poder, e o ano em que o primeiro povo chega a cada estágio (tabela de mínimo, mediana e máximo em `sondagem/<rotulo>-estagios.txt`; a de 10 sementes por 300 anos está em `sondagem/estagios.txt`). Quando o mundo fica vazio, cria um povo novo depois de 10 anos, como faria um jogador. As crônicas e as métricas ficam em `sondagem/`. |
| `medir_desempenho.gd` | `medir` (padrão) mede as janelas de desempenho e mostra os piores passos e consultas. `gerar` procura o maior mundo no estágio 6 e o guarda, comprimido, em `mundo_grande.bin` (refazer se o formato do mundo salvo mudar). |
| `desempenho.gd` | Mede como a apresentação usa o mundo: a cada passo, avança uma hora e consulta tudo o que `simulacao.gd` lê. Cada janela (uma virada de ano com 287 pessoas e uma virada de década) roda em 3 processos novos, e vale o menor tempo de cada passo, porque esta máquina tem picos de outros processos. |

## Estágios e a relação com o deus

| Estágio | Saber | Como surge | O que muda |
|---|---|---|---|
| 3, pedra | cortar pedra | povo com 18 pessoas ou mais e gente engenhosa; mais depressa depois de terremoto, tempestade ou dilúvio | casas de pedra e templo; os sacerdotes ganham força (o dobro de éditos, e o poder pode passar ao templo) |
| 4, metal | trabalhar o metal | gente engenhosa; mais depressa em tempo de guerra | as guerras matam mais (um morto a mais do lado vencido) e os povos ficam mais fortes |
| 5, escrita | escrever | gente engenhosa ou curiosa; mais depressa com sacerdote | os costumes não se esquecem mais; o saber se ensina 3 vezes mais rápido; o arquivo pode salvar um saber perdido; o povo escreve a própria crônica; o estudo do céu enfraquece o presságio |
| 6, engenharia | canais e moinhos | povo com 30 pessoas ou mais; mais depressa depois de fome | irrigação: a seca pesa pouco e não gera prece por chuva; tudo impressiona 40% menos, porque o povo precisa menos do deus. É o teto. |

Quanto tempo leva: veja `jogo/ferramentas_sim/sondagem/estagios.txt` (10 mundos de 300 anos). Depois de 40 anos no mesmo estágio, a necessidade ensina: a chance de descobrir o próximo saber cresce a cada década a mais, e qualquer adulto pode descobrir, não só os engenhosos e curiosos. Isso encurta os platôs longos (que chegavam a 158 anos, ou dois meses reais sem mudar de estágio) sem mexer no tempo típico.

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

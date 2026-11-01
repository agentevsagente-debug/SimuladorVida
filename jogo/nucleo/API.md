# API do núcleo da simulação

*Versão 6, de 01/11/2026 (fase 2: os 11 poderes, estágios 3 a 6, ruínas, fim do mundo e eras, estante, 6 dimensões culturais). Desde a versão 1, só houve acréscimos. A única mudança de comportamento: `cronica()` agora começa, por padrão, no início da era atual, o que dá o mesmo resultado na primeira era. Dona: sessão A. Mudanças que quebrem esta API serão avisadas ao orquestrador antes.*

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

`{tipo, x, largura, grupo, estagio, ruina}`, com `x` no centro da peça. `estagio` é o estágio do povo e diz qual arte usar (a casa do estágio 3 é `casa_pedra`, a do 4 é `casa_enxaimel`, e assim por diante). `ruina` é sempre false aqui. Tipos:

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

As peças vão para o primeiro lugar livre perto da fogueira, numa ordem fixa. Só mudam de lugar quando o número de peças muda ou quando o povo se muda. Moradias, celeiro, moinho e roças que não cabem na faixa do povo ficam de fora. As peças únicas (altar, templo, arquivo, forja) sempre aparecem, mesmo encostadas.

### `ruinas_visiveis() -> Array[Dictionary]`

Construções abandonadas, de povos que acabaram, se mudaram ou foram conquistados, inclusive de eras anteriores: `{tipo, x, largura, estagio, povo, era, ano, anos, ruina: true}`. `anos` é a idade da ruína, para cobrir de mato.
- A natureza retoma o espaço: ruínas dos estágios 1 e 2 somem em 30 anos; as de pedra em diante, em 200.
- Ruínas guardam conhecimento: um povo que vive perto pode aprender nelas o saber seguinte (evento `ruinas_saber`).

### `pessoas_visiveis() -> Array[Dictionary]` (só as vivas)

| Campo | O que é |
|---|---|
| `id`, `nome`, `sexo` ("m"/"f"), `idade`, `crianca` (idade < 12) | quem é |
| `grupo` | id do povo |
| `x`, `x_anterior` | posição neste passo e no anterior |
| `acao` | uma de: `dormir`, `andar`, `parado`, `colher`, `rezar`, `fogueira` (sentado em volta do fogo) |
| `papel` | "lider", "sacerdote" ou "" |
| `tracos` | dois de: ambicioso, pacifico, rancoroso, curioso, devoto, desconfiado, generoso, engenhoso, corajoso, medroso |
| `doente`, `gravida` | estados atuais |
| `acompanhada` | é a pessoa acompanhada pelo jogador |
| `pai`, `mae`, `conjuge` | ids, ou -1 |

A rotina de um dia comum:

| Hora | Ação |
|---|---|
| 21h às 5h | `dormir` na cabana |
| 6h | `andar` até o trabalho |
| 7h às 16h | `colher` na zona ou na roça |
| 17h | `andar` de volta ao fogo |
| 18h às 20h | `fogueira` |

Exceções:
- as crianças brincam perto do fogo (`andar`/`parado`);
- os velhos ficam na `fogueira`;
- os doentes ficam deitados (`dormir`);
- durante uma tempestade na zona, todos ficam `parado` na cabana;
- quem tem uma prece aberta vai `rezar` no altar às 6h e às 18h; o sacerdote reza às 7h e às 18h.

`posicao_de(pessoa_id) -> float` devolve o x atual de uma pessoa (-1 se ela morreu).

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
- `camada`: "ambiente", "nota" ou "chamado", as três camadas de atenção do documento funcional.

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
| `tempestade`, `seca_inicio`, `seca_fim`, `eclipse` | clima e céu | nota |
| `chuva_divina`, `raio_divino`, `fartura_divina`, `fogo_divino`, `terra_erguida`, `sonho`, `seca_divina`, `diluvio`, `terremoto_divino`, `pressagio`, `cura` | resultado de `usar_poder` | nota ou chamado |
| `linhagem` | a pessoa acompanhada morreu, e o acompanhamento passou adiante | nota |
| `guerra_inicio`, `guerra_fim` | uma briga vira guerra com nome (na segunda batalha) e termina: trégua, imposição do deus, conquista, extinção ou esfriou | chamado |
| `cometa`, `terremoto`, `gemeos` | presságios naturais, além do `eclipse`. O terremoto derruba cabanas e pode matar. | nota |
| `cultura` | um povo muda a relação com estranhos (`dados.dimensao = "estranhos"`) ou decide o que faz com os mortos (`"mortos"`) | nota |
| `reforma` | uma geração abandona um costume herdado ou de origem esquecida | nota |
| `dependencia`, `exigencia`, `desamparo` | o povo deixa de se preparar porque o deus sempre responde; passa a pedir coisas pequenas; e, no primeiro silêncio, paga caro | nota |
| `expedicao` | uma família parte além da borda do mundo e nunca volta | nota |
| `descoberta_tecnica` | alguém descobre o saber do próximo estágio (`dados.saber`: "pedra", "metal", "escrita", "engenharia") | nota |
| `estagio` | o povo chega a um estágio novo (`dados.estagio`, de 3 a 6) | chamado |
| `regressao` | morreu o último que sabia, e o povo volta um estágio (`dados.de`, `dados.para`) | chamado |
| `arquivo_salvou` | com a escrita, alguém reaprende nas tabuletas o saber que ia se perder | nota |
| `estudo_do_ceu` | o povo passa a prever eclipses: sinais no céu impressionam menos (metade no estágio 5, um quarto no 6) | nota |
| `ruinas_saber`, `mito_ruinas` | alguém aprende nas ruínas; um povo explica ruínas de quem não existe mais ("gigantes", "castigo" ou "gente") | nota |
| `livro_fechado` | a crônica de uma era se fechou como livro | nota |

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
| `cronica_ano(ano) -> String` | Markdown de um ano (`### Ano N` e o parágrafo), ou "" se o ano foi quieto ou ainda não terminou |
| `ultimo_ano_na_cronica() -> int` | o último ano escrito (é sempre o ano anterior ao atual) |

O ano em andamento ainda não está na crônica. Para mostrar o que acabou de acontecer, a apresentação usa os eventos de camada "nota" e "chamado".

## Determinismo

Todo sorteio da simulação vem de `mundo.rng`, com a semente dada. As consultas desta API não sorteiam nada. A mesma semente, com os mesmos poderes usados nos mesmos passos, dá o mesmo mundo e a mesma crônica.

## Salvar, carregar e ausência

```gdscript
const Persistencia = preload("res://nucleo/persistencia.gd")

Persistencia.salvar(mundo)                       # -> bool; grava em user://mundo.txt
Persistencia.existe()                            # -> bool
var mundo = Persistencia.carregar()              # -> mundo, ou null se não há arquivo válido
var r = Persistencia.carregar_e_avancar()        # -> {mundo, ausencia}, ou null
```

Todas aceitam um caminho como primeiro argumento (padrão: `user://mundo.txt`).

**O arquivo** é texto: o formato de Variant do Godot (`var_to_str`), com uma linha de cabeçalho. Ele guarda o mundo inteiro, incluindo o estado do sorteio e o estado do cronista, e também a hora real do salvamento (`mundo.salvo_em`, em segundos Unix). Os números reais são gravados pelos seus 64 bits ("@f:" seguido de um inteiro), porque a leitura de reais em texto do Godot perde o último dígito. O resultado é exato: um mundo salvo e carregado segue igual, passo a passo, ao que nunca parou.

**A gravação é segura:** o núcleo grava num arquivo `.novo` e só depois troca pelo antigo. Uma queda no meio não estraga o mundo salvo.

**Custo:** com 38 anos de mundo, o arquivo tem 184 KB e cada operação leva cerca de 25 ms. O tamanho cresce com o número de eventos, que são uns 25 por ano. O documento técnico pede salvar a cada dia de jogo e ao fechar. Isso é decisão da apresentação; o núcleo só salva quando chamado.

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
quando houver guerra: erguer terra onde houver guerra
ano 85, dia 18: fogo forte na floresta             # "fraco"/"forte" mudam a intensidade
```

Condições: seca, fome, guerra, doença e prece.

## Ferramentas de teste (`jogo/ferramentas_sim/`)

Todas rodam sem gráfico: `ferramentas_sim/godot.sh res://ferramentas_sim/<script>.gd`.

| Script | O que faz |
|---|---|
| `regressao.gd` | Roda as sementes 1 a 5 e o cenário de intervenções por 100 anos. Cada uma roda duas vezes e precisa dar a mesma crônica. Também salva e carrega a semente 1 no meio. Grava as crônicas em `cronicas/` e sai com código 1 se algo falhar. |
| `testar_api.gd` | Testa esta API: posições, ninguém na água, poderes e graus, linhagem, crônica. |
| `testar_persistencia.gd` | Testa salvar, carregar e a ausência. |
| `testar_gramatica.gd` | Testa casos difíceis de concordância. |
| `testar_fase2.gd` | Testa estágios, construções, ruínas, cultura, crônica do povo, fim do mundo, povo novo, eras, estante e abandono. |
| `gerar.gd` | Gera a crônica de uma semente, com ou sem cenário. |
| `sondar.gd` | Mostra a população por década e a contagem de eventos de várias sementes. |

## Estágios e a relação com o deus

| Estágio | Saber | Como surge | O que muda |
|---|---|---|---|
| 3, pedra | cortar pedra | povo com 18 pessoas ou mais e gente engenhosa; mais depressa depois de terremoto, tempestade ou dilúvio | casas de pedra e templo; os sacerdotes ganham força (o dobro de éditos, e o poder pode passar ao templo) |
| 4, metal | trabalhar o metal | gente engenhosa; mais depressa em tempo de guerra | as guerras matam mais (um morto a mais do lado vencido) e os povos ficam mais fortes |
| 5, escrita | escrever | gente engenhosa ou curiosa; mais depressa com sacerdote | os costumes não se esquecem mais; o saber se ensina 3 vezes mais rápido; o arquivo pode salvar um saber perdido; o povo escreve a própria crônica; o estudo do céu enfraquece o presságio |
| 6, engenharia | canais e moinhos | povo com 30 pessoas ou mais; mais depressa depois de fome | irrigação: a seca pesa pouco e não gera prece por chuva; tudo impressiona 40% menos, porque o povo precisa menos do deus. É o teto. |

O saber de cada estágio vive nas pessoas, que o ensinam devagar. Quando morre o último que sabia, o povo regride um estágio, a não ser que a escrita o salve. O sonho do deus dá a alguém o saber do próximo estágio, que pode servir à paz ou à guerra.

## A crônica do próprio povo

```gdscript
mundo.cronica_do_povo(grupo_id) -> String    # markdown; vazio se o povo nunca escreveu
```

Um povo que chega à escrita passa a contar a própria história, ano a ano, do seu jeito.
- Começa por um mito de origem: "No começo, o Olho Escuro escolheu nossos pais...".
- Registra as vitórias que o deus deu, os castigos merecidos e as preces atendidas.
- Muitas vezes, contradiz a crônica do deus: o povo escreve que a chuva veio porque rezou, e a crônica do deus diz que foi acaso. A crônica do deus aponta a contradição: "Nas tabuletas de Nail, ficou escrito que foi o Olho Escuro."

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
  - `Persistencia.salvar(mundo)` leva para a estante os livros que ainda não estão lá.
- **Abandonar o mundo:** `Persistencia.abandonar(mundo) -> livro` fecha a crônica da era atual como livro (mesmo com o povo vivo), guarda o livro na estante e apaga o mundo salvo. Depois, a apresentação começa outro mundo com `Mundo.new(semente)`, e a estante continua lá.

# Peças modulares do estágio 1

Estas são as peças que o jogo monta. Todas saem do tratamento visual da cena-alvo, `arte_claude/alvo/`. As plantas, as pedras, a cabana e a fogueira são desenhadas pelas mesmas funções de `alvo/cena.py`, e as camadas do motor usam as mesmas sementes da cena. Por isso o céu, as montanhas e o reflexo batem pixel a pixel com ela.

**Para recriar tudo:** `python gerar_tudo.py`. **Para conferir:** `python validar.py`, que verifica a paleta, a transparência e os tamanhos.

**Atlas para o jogo:** `arte_claude/atlas/` empacota estas peças em 17 atlas (comum, um por estação e um por estágio, de verão e de inverno), com JSON de regiões, e reduz as camadas grandes. As instruções estão em `arte_claude/atlas/LEIA-ME.md`.

Todas as peças:
- usam só as 32 cores de `arte/paleta/paleta.hex`;
- não têm semitransparência (cada pixel é opaco ou totalmente transparente);
- têm fundo transparente;
- são geradas por código, com o script ao lado.

A pasta `_4x/` de cada seção tem as versões ampliadas, só para olhar.

## Prova de montagem

`montagem/comparacao_dia.png` e `montagem/comparacao_noite.png` mostram a cena-alvo em cima e, embaixo, a mesma cena remontada pelo `montagem/montar.py`. Esse script:
- **lê os PNGs entregues**, sem chamar o código de desenho;
- lê a disposição da cena em `montagem/layout.json`: a altura e o tipo de cada coluna de 8 px, o canto da fogueira e cada peça com quadro, posição, base, espelhamento, troca de cores e plano, na ordem de desenho;
- monta o terreno em blocos;
- coloca as peças nas posições do `layout.json`;
- troca as cores das pessoas;
- faz a noite só com `tabelas_luz.json` e os mapas de luz.

Ou seja, faz o que o motor terá de fazer.

## 1. Terreno (`terreno/`): blocos de 8 × 8

| Bloco | Uso |
|---|---|
| `grama_a`, `grama_b` | Superfície com borda irregular. A linha da grama é a linha 2, e as linhas 0 e 1 têm só os tufos. |
| `grama_seca` | Transição da praia para a grama, com areia embaixo. |
| `chao_batido` | Terra batida da clareira da fogueira. A superfície também fica na linha 2. |
| `terra_a`, `terra_b` | Terra. |
| `terra_raiz`, `terra_raiz_b` | Terra com raiz. A raiz entra e sai na coluna 4, então os blocos empilhados formam uma raiz longa. |
| `terra_escura_topo`, `_b`, `_c` | Fronteira entre a terra e a terra escura, em três alturas. A variante `_b` tem uma pedra. |
| `terra_escura_a`, `terra_escura_b` | Terra escura. |
| `terra_escura_raiz` | Terra escura com raiz. |
| `pedra_solo` | Terra escura com pedra. |
| `rocha_borda`, `_b`, `_c` | Fim da terra escura. Os dentes ficam em cima, e a parte de baixo é **transparente**. A variante `_c` tem uma pedra. |
| `rocha_1` a `rocha_16` | Rocha. São um padrão de 64 × 16 cortado em 16 blocos. |
| `areia_superficie`, `areia_a`, `areia_b`, `areia_base` | Praia e fundo do mar. A `areia_base` faz a fronteira da areia com a terra escura. |
| `agua`, `agua_funda` | Água. A `agua` faz a transição pontilhada para a água funda. |
| `agua_superficie_4q` | Superfície da água em 4 quadros de 8 × 8. As ondas deslizam 2 px por quadro. |

`blocos_prancha.png` mostra todos os blocos juntos. `terreno_teste.png` é o terreno da cena montado só com blocos.

**Regra de montagem, que o motor deve seguir** (está implementada em `terreno.py`, na função `montar_terreno`):

1. **Rocha em grade fixa.** A partir de y = 128, toda a área recebe `rocha_k` em posições múltiplas de 8. O bloco é escolhido assim: `k = (x/8 mod 8) + 8·(y/8 mod 2) + 1`.
2. **Colunas de 8 px com altura livre.** Cada coluna tem uma altura de superfície `s` (qualquer y) e uma pilha de blocos que começa nela. A grama ou a terra batida fica em `s − 2`, e a areia em `s`. Abaixo vêm, nesta ordem:
   - terra, até o centro do bloco passar de y = 130;
   - `terra_escura_topo`;
   - terra escura, até o centro passar de y = 139;
   - `rocha_borda`.

   A pilha acaba na `rocha_borda`, e a rocha da grade aparece por baixo dela. Como cada coluna tem um deslocamento diferente, as fronteiras entre as camadas ficam irregulares, como na cena.
3. **Água.** Nas colunas de mar, a água é desenhada antes da areia: a superfície em y = 120, `agua` em 128 e `agua_funda` daí para baixo, só acima do fundo.
4. **Raízes** vão nas colunas embaixo das árvores. São 2 blocos de terra com raiz e 1 de terra escura com raiz.

## 2. Habitantes (`habitantes/`)

Os personagens olham para a direita. Cada folha é horizontal, sem espaço entre os quadros, e o nome indica quantos quadros ela tem.

| Folha | Quadro | Quadros |
|---|---|---|
| `adulto_a_parado_2q` | 8 × 12 | 2 (respiração: o corpo desce 1 px) |
| `adulto_a_andar_4q` | 8 × 12 | 4 (passo, meio, passo, meio, com os braços balançando) |
| `adulto_b_parado_2q` | 8 × 12 | 2 (cabelo longo e vestido) |
| `adulto_b_andar_4q` | 8 × 12 | 4 |
| `crianca_andar_4q` | 6 × 8 | 4 |
| `idoso_andar_4q` | 8 × 12 | 4 (curvado, com bengala e cabelo grisalho) |
| `adulto_a_rezar_2q` | 8 × 12 | 2 (ajoelhado com os braços erguidos, depois curvado) |
| `adulto_a_colher_4q` | 8 × 12 | 4 (em pé, abaixa, pega e levanta com o fruto) |
| `adulto_a_sentado_1q` | 8 × 12 | 1 (extra: sentado num tronco, como na cena) |

**Cores-base e trocas.** Os personagens vêm com cores-base que o motor troca. As tabelas estão em `trocas.json`, e `variacoes_pele_roupa.png` mostra 4 peles × 3 roupas × (adulto A, adulto B, criança), mais os 5 cabelos.

| Elemento | Cor-base | Como troca |
|---|---|---|
| Pele | 26, com sombra 25 | troca em par |
| Cabelo | 30, com brilho 8 | troca em par |
| Roupa | 28 | só pelas 3 cores do grupo **tecidos** (27, 28, 29) |
| Cabelo do idoso | 12, com brilho 31 | não troca |
| Olho (3), pés (10 e 9), cinto e tira de couro (9) | | nunca trocam |

## 3. Estágio 1 (`estagio1/`)

A base de cada peça, o ponto que toca o chão, fica na última linha.

| Peça | Tamanho | Observação |
|---|---|---|
| `cabana_galhos` | 16 × 16 | corpo com 14 linhas, mais as pontas dos galhos cruzados |
| `fogueira_acesa_4q` | 4 quadros de 16 × 16 | chama tremulando; lenha e anel de pedras fixos |
| `fogueira_apagada` | 16 × 16 | lenha queimada, cinza e uma brasa |
| `arvore_copa_a` | 40 × 32 | tronco na coluna 19 |
| `arvore_copa_b` | 32 × 32 | tronco na coluna 14 |
| `pinheiro_a` | 40 × 40 | tronco na coluna 19 |
| `pinheiro_b` | 24 × 32 | tronco na coluna 11 |
| `pinheiro_fundo` | 32 × 32 | extra: o pinheiro escuro do fundo da floresta |
| `arbusto`, `arbusto_frutas` | 16 × 8 | |
| `capim`, `capim_seco` | 8 × 8 | |
| `pedra_pequena` | 8 × 8 | |
| `pedra_grande` | 16 × 16 | com musgo |
| `juncos` | 8 × 16 | juncos da margem |
| `tronco_deriva`, `alga`, `samambaia_frente` | 16 × 8, 8 × 8, 16 × 16 | extras usados na montagem; a samambaia é do primeiro plano |

Fumaça e fagulhas da fogueira são partículas do motor.

## 4. Efeitos dos poderes e do clima (`efeitos/`)

Os nomes seguem duas regras. O sufixo `_Nq` indica N quadros de animação, lidos da esquerda para a direita. O sufixo `_Nv` indica N variações do mesmo tamanho, e o motor sorteia uma para cada partícula.

Nenhum efeito usa semitransparência. Quando algo some aos poucos, como a fumaça e a poeira, o pontilhado fica cada vez mais ralo de um quadro para o outro.

`amostra_efeitos_4x.png` mostra todos os efeitos sobre o céu de dia e sobre a noite.

| Folha | Quadro | Quadros | Uso |
|---|---|---|---|
| `gotas_3v` | 4 × 8 | 3 variações | partícula de chuva (curta, longa inclinada, pingo) |
| `respingo_4q` | 8 × 8 | 4 | gota batendo no chão ou na água |
| `nuvem_chuva_2q` | 48 × 24 | 2 | a nuvem carregada que o jogador arrasta, com fiapos de chuva na base |
| `raio_a_2q`, `raio_b_2q`, `raio_c_2q` | 32 × 120 | 2 | raio sem galhos, com 2 galhos e com 4 galhos. O quadro 1 é a descarga, e o quadro 2 é o canal esfriando. A ponta de baixo toca o chão. |
| `raio_impacto_4q` | 16 × 16 | 4 | clarão, faíscas e fumaça no ponto atingido (base na linha 14) |
| `chamas_4q` | 16 × 16 | 4 | o poder do fogo no chão ou no capim |
| `chamas_grandes_4q` | 24 × 32 | 4 | fogo em cabana, casa ou árvore |
| `brasas_4q` | 8 × 8 | 4 | brasas pulsando depois do fogo |
| `fumaca_6q` | 16 × 16 | 6 | baforada que sobe pouco (cerca de 6 px), cresce e se desfaz pelas bordas em pedaços irregulares. Deixe-a sumir depois do quadro 6, sem subir mais que as copas. |
| `terra_subindo_4q` | 32 × 24 | 4 | morro brotando, com torrões caindo e poeira; o motor depois troca pelos blocos de terreno |
| `poeira_4q` | 16 × 8 | 4 | poeira no pé da terra que sobe ou do impacto |
| `rachadura_3q` | 16 × 8 | 3 | o chão abrindo, desenhado por cima dos blocos |
| `fartura_brilho_4q` | 8 × 8 | 4 | cintilar dourado sobre a colheita ou a caça |
| `fartura_aura_4q` | 16 × 16 | 4 | partículas verdes e douradas subindo da roça (repete em laço) |
| `sonho_4q` | 16 × 16 | 4 | espiral lilás que desce sobre quem recebe o sonho |
| `sonho_brilho_4q` | 8 × 8 | 4 | brilho lilás solto |
| `folha_verde_4q`, `folha_seca_4q` | 8 × 8 | 4 | folha girando ao vento |
| `vagalume_4q` | 8 × 8 | 4 | vagalume piscando (só à noite) |

### Efeitos da fase 2 (`efeitos_fase2.py`)

São os efeitos dos 5 poderes restantes. `amostra_efeitos_fase2_4x.png` mostra todos sobre o dia e sobre a noite.

| Folha | Quadro | Quadros | Uso |
|---|---|---|---|
| `seca_rachaduras_4q` | 32 × 8 | 4 | **seca**: vai sobre a superfície do chão (linha 2, como a grama). O capim amarela, e as rachaduras crescem em 4 etapas. |
| `calor_4q` | 16 × 16 | 4 | **seca**: tremor de calor subindo do chão |
| `../montagem/ceu_seca.png` | 480 × 160 | | **seca**: céu amarelado do dia, com sol grande e branco (camada de céu) |
| `chuva_forte_3v` | 4 × 12 | 3 variações | **dilúvio**: gota longa da chuva pesada |
| `cortina_chuva_4q` | 32 × 32 | 4 | **dilúvio**: cortina de chuva que repete nas duas direções; o motor a rola para baixo sobre o mundo |
| `enchente_superficie_4q`, `enchente_agua_1q` | 8 × 8 | 4 e 1 | **dilúvio**: superfície e corpo da água barrenta que sobe. São blocos como `agua_superficie_4q` e `agua`, colocados acima do terreno. |
| `destrocos_3v` | 8 × 8 | 3 variações | **dilúvio**: tábua, folhagem e galhos boiando |
| `fenda_4q` | 16 × 16 | 4 | **terremoto**: fenda que se abre no chão. A linha 0 é a superfície. |
| `poeira_terremoto_4q` | 32 × 16 | 4 | **terremoto**: poeira larga subindo e se desfazendo |
| `pedras_caindo_3v` | 4 × 4 | 3 variações | **terremoto**: partícula de pedra caindo |
| `cometa_4q` | 32 × 16 | 4 | **presságio**: cometa com cauda que tremula. Atravessa o céu da direita para a esquerda; a cabeça fica em (4, 4). |
| `eclipse_4q` | 16 × 16 | 4 | **presságio**: o disco escuro cobre o sol até sobrar a coroa |
| `../montagem/ceu_eclipse.png` | 480 × 160 | | **presságio**: céu do eclipse total, de dia, com a coroa e um anel de entardecer no horizonte |
| `cura_luz_4q` | 16 × 24 | 4 | **cura**: luz suave que desce sobre quem é curado. A base fica na linha 23, nos pés da pessoa. |
| `cura_brilho_4q` | 8 × 8 | 4 | **cura**: brilho verde-claro solto |

**À noite:**
- não passam pela tabela `noite`, porque emitem luz: raio, impacto, chamas, brasas, fartura, sonho e vagalume;
- usam a tabela `noite`: gotas, respingo, nuvem, fumaça, poeira, terra, rachadura e folhas;
- da fase 2, emitem luz cometa, eclipse e cura; seca, calor, chuva forte, cortina, enchente, destroços, fenda, poeira do terremoto e pedras usam a tabela `noite`.

## 5. Sinais de prece (`sinais/`)

A base de cada quadro é a última linha, o ponto de onde a luz nasce. Ela vai 1 px acima da cabeça de quem reza ou, para a vila, acima do telhado mais alto. Os sinais emitem luz, então não passam pela tabela da noite. `amostra_sinais_4x.png` mostra todos sobre o dia e sobre a noite.

| Folha | Quadro | Quadros | Quando usar |
|---|---|---|---|
| `prece_comum_4q` | 8 × 12 | 4 | pedido comum: luz pequena e mansa que sobe e desce 1 px |
| `prece_urgente_4q` | 12 × 16 | 4 | urgente: luz maior, com halo e 4 raios pulsando |
| `prece_desesperada_4q` | 16 × 24 | 4 | desesperado: chama de luz quente e trêmula, com 8 raios e faíscas |
| `os_ultimos_4q` | 24 × 48 | 4 | o evento `os_ultimos`: facho de luz fria sobre a vila, com 5 pontos de luz em volta |
| `necessidade_5v` | 8 × 8 | 5 variações | símbolo da `necessidade` da prece, nesta ordem: `seca` (sol), `fome` (espiga), `doenca` (coração rachado), `frio` (floco), `guerra` (lanças cruzadas). Vai ao lado do sinal ou na dica do cursor. |

A escolha da intensidade fica com a apresentação. Uma sugestão: comum até 10 dias de espera, urgente até 30 dias e desesperado a partir daí, ou quando a importância do evento for 8 ou mais.

## 6. Interface da alça (`interface/`)

Todos os elementos são legíveis em 1x. `amostra_interface_4x.png` mostra a alça montada, a crônica, a dica do cursor e o alfabeto completo.

**Ícones**, em `icones_12/` (12 × 12) e `icones_8/` (8 × 8), com os mesmos nomes nas duas pastas:

| Grupo | Ícones |
|---|---|
| Poderes | `chuva`, `raio`, `fogo`, `fartura`, `erguer_terra`, `sonho`; e os da fase 2: `seca` (sol e chão rachado), `diluvio` (chuva pesada e ondas), `terremoto` (fenda no chão), `pressagio` (cometa), `cura` (coração com brilhos verdes) |
| Tempo | `pausa`, `normal`, `rapido`, `rapido2` (três setas, para o ritmo de 50x), `salto` |
| Outros | `cronica` (livro aberto), `linhagem` (árvore de família), `esconder` (minimizar) |

Os ícones foram desenhados para o fundo escuro da alça.

**Caixas em 9 partes** (os cantos ficam fixos, as bordas e o miolo repetem):

| Arquivo | Tamanho | Fatia | Uso |
|---|---|---|---|
| `caixa_cronica_9s.png` | 24 × 24 | 6 px | pergaminho da crônica; texto com `fonte_5x7_escura` |
| `caixa_dica_9s.png` | 12 × 12 | 4 px | dica do cursor, escura; texto com `fonte_5x7_clara` e o nome com `fonte_5x7_dourada` |
| `dica_ponteiro.png` | 6 × 3 | | bico da dica, apontando para baixo; vai colado na borda de baixo |
| `alca_9s.png` | 12 × 12 | 4 px | fundo da alça, madeira escura |
| `botao_3q.png` | 3 quadros de 16 × 16 | | botão normal, com o cursor por cima e selecionado (borda dourada). O ícone de 12 × 12 vai em (2, 2). |

**Ícone do jogo**, para a bandeja e a barra de tarefas: `icone_jogo_16.png`, `icone_jogo_32.png`, `icone_jogo_256.png` e `icone_jogo.ico`.
- O 16 e o 32 foram desenhados à mão, cada um com o seu desenho, para ler bem em 1x. O 256 é o 32 ampliado 8 vezes, sem suavização.
- O `.ico` leva os tamanhos 16, 32, 48, 64, 128 e 256, todos com pixels nítidos.
- O desenho é o pequeno mundo numa moldura de madeira: céu, sol, morro, a cabana de galhos e uma pessoa junto ao fogo.

**Fonte em pixel:** `fonte_5x7_clara`, `fonte_5x7_escura` e `fonte_5x7_dourada`, cada uma com um `.png` e um `.fnt`.
- **Formato:** BMFont em texto, que o Godot 4 importa direto como fonte. As três têm as mesmas medidas e mudam só a cor, porque a fonte não pode ser tingida pelo motor: multiplicar a cor sairia da paleta.
- **Medidas:** maiúsculas de 5 × 7, proporcional, altura de linha 12, linha de base 9, 1 px entre letras e espaço de 3 px.
- **Caracteres:** 110 ao todo:
  - letras de A a Z, maiúsculas e minúsculas, e algarismos de 0 a 9;
  - todos os acentos do português: á à â ã é ê í ó ô õ ú ü, as maiúsculas acentuadas correspondentes, ç e Ç;
  - pontuação: `. , : ; ! ? - — ' " ( ) « » / % + = … º ª`.

## 7. Estágio 2, agricultura (`estagio2/`)

A base de cada peça, o ponto que toca o chão, fica na última linha, como no estágio 1. `amostra_estagio2_4x.png` mostra as peças sobre o chão da cena.

| Peça | Tamanho | Observação |
|---|---|---|
| `roca_arada`, `roca_broto`, `roca_crescida`, `roca_madura` | 16 × 16 | as 4 fases da roça. Os sulcos ficam nas 4 últimas linhas, e as plantas se repetem a cada 4 px, então uma roça larga é a mesma peça repetida lado a lado. A peça vai sobre a grama, com a base na superfície. |
| `roca_seca` | 16 × 16 | talos secos tombados e solo rachado |
| `casa_taipa` | 24 × 24 | casa de taipa com telhado de palha (peça montada) |
| `casa_taipa_parede`, `casa_taipa_telhado` | 24 × 24 | a mesma casa em duas camadas, para as culturas trocarem parede e telhado. Desenhe a parede primeiro e o telhado por cima. |
| `celeiro` | 24 × 24 | celeiro sobre esteios, com escada |
| `cerca` | 8 × 8 | trecho que se repete na horizontal: um poste e dois trilhos |
| `cerca_poste` | 8 × 8 | poste solto, para fechar a ponta direita da cerca |
| `altar` | 16 × 16 | laje de pedra com oferendas e duas chamas |
| `templo` | 32 × 32 | primeiro templo pequeno: pedra, colunas de madeira, palha e o símbolo no alto (peça montada) |
| `templo_parede`, `templo_telhado`, `templo_simbolo` | 32 × 32 | o templo em 3 camadas, desenhadas nesta ordem. O símbolo (o sol) é a parte que cada cultura troca. |
| `adulto_enxada_andar_4q` | quadro de 12 × 12 | 4 quadros, andando com a enxada no ombro |
| `adulto_enxada_trabalhar_4q` | quadro de 12 × 12 | 4 quadros: ergue, golpeia, crava e puxa a terra |

**As folhas com enxada têm quadros de 12 × 12.** O corpo ocupa as colunas 0 a 7, igual aos outros habitantes, e a enxada usa as colunas 8 a 11. O motor alinha pelo canto esquerdo e pela base, como faz com o habitante de 8 × 12. As cores-base e as trocas de pele, cabelo e roupa são as mesmas de `habitantes/trocas.json`.

## 8. Ruínas e marcas da memória (`memoria/`)

A base de cada peça fica na última linha. `amostra_memoria_4x.png` mostra todas sobre o chão da cena.

| Peça | Tamanho | Observação |
|---|---|---|
| `tumulo` | 16 × 16 | monte de terra com pedra fincada riscada e flores |
| `cabana_abandonada` | 16 × 16 | a `cabana_galhos` sem folhas, com o topo cedido, galhos no chão e mato |
| `casa_ruina` | 24 × 24 | a casa de taipa sem telhado: sobram caibros, a parede está quebrada e furada, há entulho e mato |
| `pedra_erguida` | 16 × 32 | menir de lugar sagrado, com espiral entalhada e musgo |
| `terra_queimada_a`, `terra_queimada_b` | 8 × 8 | **blocos de terreno** que substituem a grama, com a superfície na linha 2 (como `grama_a`): tocos queimados, cinza e brasas |
| `arvore_queimada` | 32 × 32 | tronco carbonizado com galhos nus e brasas; o tronco fica na coluna 15 |

## 9. Variações de cultura (`culturas/`)

As peças de cultura têm o mesmo tamanho e o mesmo encaixe da casa (24 × 24) e do templo (32 × 32) do estágio 2. A porta e a janela ficam sempre no mesmo lugar, então qualquer parede combina com qualquer telhado.

Ordem de desenho:
- casa: parede e depois telhado;
- templo: parede, depois telhado e por último o símbolo.

`amostra_culturas_4x.png` mostra, em cima, três povos de exemplo e, embaixo, as 9 casas possíveis. Os três povos são:
- taipa com palha, símbolo do sol e roupa turquesa;
- pedra com telha, símbolo da lua e roupa lilás;
- madeira com tábuas, símbolo da árvore e roupa rosa.

| Grupo | Variações | Arquivos | Cores |
|---|---|---|---|
| Paredes | `taipa`, `pedra`, `madeira` | `casa_parede_<v>`, `templo_parede_<v>` | barro 10/9, pedra 12/11/8, tábuas 10/9/8 |
| Telhados | `palha`, `telha`, `tabuas` | `casa_telhado_<v>`, `templo_telhado_<v>` | palha 16/10/9, telha de barro 20/24/23, tábuas 10/9/8 |
| Símbolos | `sol`, `lua`, `arvore` | `templo_simbolo_<v>` | sol 22/21/31, lua 31/0/19, árvore 15/14/13 |

As três variações também mudam de forma, além da cor:
- **Telhados:** palha média, telha baixa com cumeeira, tábuas alta e íngreme com as pontas cruzadas.
- **Paredes:** reboco de barro, fiadas de pedra, tábuas na horizontal.

A combinação taipa com palha e sol é exatamente a `casa_taipa` e o `templo` do estágio 2.

## 10. Camadas do motor (`montagem/`)

| Arquivo | O que é |
|---|---|
| `ceu_<hora>.png` | 480 × 160, opaco: degradê pontilhado, sol ou lua, estrelas e nuvens, para `entardecer`, `dia` e `noite`. |
| `montanhas_longe_<hora>.png`, `montanhas_perto_<hora>.png` | os 2 planos de montanha |
| `mata_distante_<hora>.png` | a linha de copas logo atrás do mundo |
| `reflexo_<hora>.png` | traços do reflexo do sol ou da lua, brilhos e raios de luz. Vai só sobre os pixels de água. |
| `luz_fogueira.png` | mapa de luz de 128 × 80, **em tons de cinza: são dados, não arte**. Os valores são 0 (noite), 127 (luz média) e 255 (luz perto), já pontilhados. |
| `luz_fogueira_halo.png` | o mesmo, só para o halo no céu: 0 ou 255 |
| `tabelas_luz.json` | as trocas de cor: `noite`, `noite_agua`, `fogo_perto`, `fogo_medio`, `halo_ceu`, `entardecer` e `entardecer_contorno_pessoas` |

**A noite, passo a passo** (está implementada em `montar.py`, na função `noite`):

1. O céu, as montanhas e a mata usam as camadas de noite, sem remapear.
2. **Água:** a tabela `noite_agua`. O reflexo de noite é a sua própria camada.
3. **Primeiro plano:** fica em silhueta.
4. **Mundo:**
   - abaixo de `superfície + 3`, usa a tabela `noite` (a luz do fogo não entra no corte do solo);
   - acima, usa o mapa de luz. O nível 2 usa `fogo_perto`, o nível 1 usa `fogo_medio` e o nível 0 usa `noite`.
5. **Mapa de luz:** o canto do mapa fica no canto da peça da fogueira, deslocado por (−56, −32). Ponha a fogueira em coordenadas múltiplas de 4, para o pontilhado ficar alinhado.
6. **Pessoas:** os pixels da metade do corpo virada para longe do fogo descem um nível de luz. É isso que dá volume.
7. **Céu:** onde o halo vale 255, o céu usa a tabela `halo_ceu`.

## 11. Estágios 3 a 6 (`estagio3/` a `estagio6/`)

As regras são as de sempre:
- a base de cada peça fica na última linha;
- as construções têm tamanhos múltiplos de 8;
- os habitantes têm quadros de 8 × 12, ou de 12 × 12 quando carregam arma ou ferramenta (o corpo fica nas colunas 0 a 7);
- as cores-base e as trocas de pele, cabelo e roupa são as de `habitantes/trocas.json`.

**Culturas.** Cada estágio mantém as 3 culturas da seção 9. A casa sai em parede mais 3 telhados (`_telhado_palha`, `_telhado_telha`, `_telhado_tabuas`), e o templo sai em base mais 3 símbolos (`_simbolo_sol`, `_simbolo_lua`, `_simbolo_arvore`). As peças montadas, sem sufixo, são só exemplos.

**Ruínas.** Cada construção tem a sua `_ruina`, gerada por código a partir da peça inteira, com o mesmo tamanho: o telhado cai e sobram caibros, o topo quebra, aparecem buracos, entulho e mato, e janelas e fogos se apagam.

Cada pasta tem uma `amostra_estagioN_4x.png`.

### Estágio 3, pedra

| Peça | Tamanho | Observação |
|---|---|---|
| `casa_pedra` (`_parede`, `_telhado_<cultura>`) | 32 × 24 | casa de pedra com porta e duas janelas |
| `templo_pedra` (`_base`, `_simbolo_<cultura>`) | 32 × 32 | templo em 3 degraus de pedra lavrada, com escada, santuário e braseiros |
| `casa_pedra_ruina`, `templo_pedra_ruina` | 32 × 24, 32 × 32 | |
| `adulto_e3_parado_2q`, `adulto_e3_andar_4q` | 8 × 12 | capa de pele nos ombros e colar de pedra |

### Estágio 4, metal

| Peça | Tamanho | Observação |
|---|---|---|
| `forja` e `forja_2q` | 24 × 24 | forno de pedra com chaminé, boca acesa (2 quadros de brasa) e bigorna. A boca emite luz à noite. |
| `casa_enxaimel` (`_parede`, `_telhado_<cultura>`) | 32 × 32 | casa de dois andares com madeira aparente |
| `templo_colunas` (`_parede`, `_telhado_<cultura>`, `_simbolo_<cultura>`) | 32 × 32 | templo de colunas e arquitrave; o telhado de cultura forma o frontão |
| `forja_ruina`, `casa_enxaimel_ruina`, `templo_colunas_ruina` | | |
| `adulto_e4_parado_2q`, `adulto_e4_andar_4q` | 8 × 12 | capacete de ferro e fivela de metal |
| `guerreiro_andar_4q` | 12 × 12 | lança e escudo redondo de bronze |
| `ferreiro_trabalhar_4q` | 12 × 12 | avental de couro e martelo: ergue, desce e bate (com faísca) |

### Estágio 5, escrita

| Peça | Tamanho | Observação |
|---|---|---|
| `tabuletas_4v` | 8 × 8 | 4 variações: tabuleta de barro, rolo, estela pequena e pilha de tabuletas |
| `estela` | 8 × 16 | pedra escrita |
| `biblioteca` (`_parede`, `_telhado_<cultura>`) | 32 × 32 | o arquivo: pórtico de colunas, friso escrito e estantes com tabuletas e rolos |
| `templo_escrita` (`_parede`) | 32 × 32 | o templo de colunas com friso escrito; usa os telhados e símbolos de `estagio4/templo_colunas_*` |
| `biblioteca_ruina`, `templo_escrita_ruina` | | a ruína do arquivo tem tabuletas espalhadas |
| `adulto_e5_parado_2q`, `adulto_e5_andar_4q` | 8 × 12 | túnica longa até os pés; parado, segura uma tabuleta |
| `escriba_sentado_2q` | 8 × 12 | sentado, escrevendo na tabuleta |

### Estágio 6, engenharia

| Peça | Tamanho | Observação |
|---|---|---|
| `canal`, `canal_comporta` | 8 × 8 | **blocos de superfície** (linha 2, como a grama) da irrigação: canal com borda de pedra, que repete na horizontal, e comporta |
| `roca_irrigada` | 16 × 16 | a roça madura com rego d'água entre os sulcos |
| `moinho_4q` | 32 × 40 | moinho de vento: as pás giram 22,5° por quadro, e os 4 quadros fecham o ciclo |
| `muralha` | 8 × 16 | trecho com ameias que repete na horizontal |
| `muralha_torre` | 16 × 32 | torre da muralha |
| `barco_2q` | 24 × 16 | barco a vela balançando; a linha 14 fica na linha d'água |
| `casa_tijolo` (`_parede`, `_telhado_<cultura>`) | 32 × 32 | casa de tijolo de dois andares |
| `templo_cupula` (`_base`, `_simbolo_<cultura>`) | 32 × 32 | templo de cúpula com colunata |
| ruínas | | `moinho_ruina`, `muralha_ruina`, `muralha_torre_ruina`, `casa_tijolo_ruina`, `templo_cupula_ruina`, `barco_naufragado` |
| `adulto_e6_parado_2q`, `adulto_e6_andar_4q` | 8 × 12 | chapéu de aba larga e calças |

**Construção comum.** As paredes, portas, janelas, telhados, a ruína e a roupa de cada estágio saem de `construcao.py`. Os materiais de parede disponíveis são taipa, pedra, madeira, pedra lavrada, tijolo e enxaimel.

## 12. Cenas de amostra (`cenas/`)

`cena_estagio2.png` a `cena_estagio6.png` (480 × 160) mostram uma vila em cada estágio, de dia, no estilo da cena-alvo. `amostra_cenas_2x.png` junta as cinco.

As cenas são montadas como a prova de montagem: só com as camadas do motor, o terreno em blocos e as peças lidas dos PNGs. O morro e a praia guardam a vegetação da cena-alvo, vinda de `montagem/layout.json`.

| Estágio | O que a vila mostra |
|---|---|
| 2 | roça cercada, casas de taipa, celeiro, altar, templo no morro e gente com enxada |
| 3 | casas de pedra, templo em degraus, roça e uma casa em ruína no morro |
| 4 | forja acesa, casas de enxaimel, templo de colunas, ferreiro e guerreiros |
| 5 | biblioteca, estelas, templo com friso escrito e o escriba |
| 6 | muralha com torre e sentinela, casas de tijolo, templo de cúpula, roça irrigada, moinho no morro e barco na água |

## 13. Estações (`estacoes/`)

O verão é a arte de sempre. As outras três estações ficam em `estacoes/<estacao>/<pasta>/<nome>.png`, com o mesmo nome, tamanho e encaixe da peça original. **O motor procura primeiro na pasta da estação, que vem do campo `tempo().estacao` da API. Se a peça não estiver lá, usa a de verão.** A `montagem/montar.py` faz exatamente isso, na função `ler_pasta`.

| Estação | O que muda |
|---|---|
| `primavera` | flores brancas e rosas nas copas e nos arbustos, flores no capim e na borda da grama, verde mais vivo |
| `outono` | copas largas e arbustos laranja e ferrugem, capim seco, grama amarelando com folhas caídas, mata distante enferrujada (de dia). Os pinheiros não mudam. |
| `inverno` | árvores de copa sem folhas (mesmo encaixe), neve assentada em cima de tudo (pinheiros, arbustos, telhados de todos os estágios, ruínas, pedras, cercas e roças), grama coberta de neve, montanhas com calotas maiores e mata distante com neve, nos 3 horários |

**Roupa de inverno dos habitantes.** Todas as folhas de pessoas (`habitantes/`, `acoes/` e os habitantes dos estágios 2 a 6) têm uma versão em `estacoes/inverno/<pasta>/`, com o mesmo nome. A roupa de frio tem capuz de lã sobre o cabelo (9 e 10), manto nas costas (8), mangas de lã (9 e 10, com as mãos de fora), polainas nas pernas (8 e 9) e gola de pele (12) nos ombros. Pele e roupa continuam trocáveis pelas tabelas de sempre; com o capuz, o cabelo não aparece. A montagem (`montar.py`) já usa as pessoas da estação. A única folha sem versão de inverno é o `dormir_2q`, porque a pessoa já está coberta.

Peças e efeitos novos:
- `estacoes/inverno/terreno/gelo_superficie.png` (8 × 8): o lago congelado. Na montagem, as 3 colunas de água mais perto da praia usam o gelo no lugar da superfície da água.
- `efeitos/neve_4q.png` (64 × 64, 4 quadros): neve caindo, que repete nas duas direções. Os flocos descem 2 px por quadro.
- `efeitos/floco_3v.png` (4 × 4, 3 variações).
- No outono, as folhas caindo são o `efeitos/folha_seca_4q` de sempre.

Amostras e geração:
- `estacoes/amostra_estacoes_4x.png`: o mesmo lugar (a cena-alvo de dia) nas 4 estações, de cima para baixo: primavera, verão, outono e inverno. Cada cena também está em `cena_<estacao>.png`, com 480 × 160.
- `estacoes/amostra_estacoes_pecas_4x.png`: as principais peças nas 4 estações.
- As variações são geradas por `estacoes.py` a partir das peças de verão. Peça nova entra automaticamente quando o script roda de novo.

## 14. Ações dos habitantes (`acoes/`)

Os quadros têm 8 × 12, olhando para a direita, com a base na última linha. São 4 quadros cada, com as mesmas cores-base e trocas de `habitantes/trocas.json`. `amostra_acoes_4x.png` mostra cada ação com 3 combinações de pele, cabelo e roupa.

| Folha | O que faz |
|---|---|
| `pescar_4q` | espera com a vara erguida, a vara dá um puxão, a pessoa puxa e mostra o peixe. A linha até a água fica com o motor. |
| `carregar_lenha_4q` | anda com o feixe de lenha nos braços |
| `construir_4q` | martela: ergue, prepara, bate embaixo, volta |
| `forjar_4q` | o mesmo golpe, de avental de couro e com faísca no impacto (vai junto da `forja` do estágio 4) |
| `escrever_4q` | de cabeça baixa, escreve com o estilete na tabuleta |
| `remar_4q` | sentado: só o tronco aparece, e o remo entra na água. O corpo começa 2 px abaixo; ponha a folha sobre o barco. |
| `lutar_4q` | lança e escudo: guarda, recua, estocada e volta |
| `carregar_morto_4q` | anda devagar, de cabeça baixa, com o corpo na mortalha sobre os ombros |
| `dancar_4q` | dança de festa: braços para cima, pulo e troca de lado |

## 15. Mundo vazio e natureza retomando (`natureza/`)

**Ruínas cobertas pelo mato.** Toda ruína ganhou 3 graus, `<ruina>_mato_1`, `_mato_2` e `_mato_3`, com o mesmo tamanho e encaixe da ruína.
- **Grau 1:** capim na base e as primeiras trepadeiras.
- **Grau 2:** trepadeiras até o meio, moitas encostadas e musgo nos topos.
- **Grau 3:** trepadeiras por quase tudo, mais moitas e uma muda brotando em cima.

São 17 ruínas: `cabana_abandonada`, `casa_ruina`, `tumulo`, `pedra_erguida` e todas as `_ruina` dos estágios 3 a 6, mais o `barco_naufragado`.

**Peças avulsas:**

| Peça | Tamanho | O que é |
|---|---|---|
| `muda` | 8 × 8 | muda nascendo onde havia casa |
| `arvore_jovem` | 16 × 16 | árvore de copa jovem; tronco na coluna 6 |
| `pinheiro_jovem` | 16 × 16 | pinheiro jovem; tronco na coluna 7 |
| `fogueira_antiga` | 16 × 16 | fogueira apagada há muito tempo: pedras meio enterradas, carvão velho e capim por dentro |

As amostras são `amostra_natureza_4x.png` (4 ruínas nos 3 graus) e `amostra_natureza_jovens_4x.png`.

## 16. Tela da estante de crônicas (`estante/`)

| Peça | Tamanho | Uso |
|---|---|---|
| `estante_fundo` | 16 × 16 | fundo de tábuas escuras; repete nas duas direções |
| `prateleira` | 16 × 6 | tábua que repete na horizontal; os livros ficam em pé sobre a linha 0 |
| `livro_lombada_6v` | 12 × 64, 6 variações | uma lombada para cada era ou mundo, em 6 cores de couro com faixas douradas |
| `livro_aberto` | 256 × 144 | o livro aberto, no estilo do pergaminho: capa de couro, duas páginas, sombra na lombada, bordas das folhas e fita marcadora |

**O nome da era na lombada:**
- vai na etiqueta clara (linhas 8 a 55, colunas 2 a 9);
- é escrito com `fonte_5x7_escura`, em maiúsculas, girado 90° (lido de baixo para cima) e centrado;
- cabem 7 caracteres; nomes maiores, o motor abrevia.

**O texto do livro aberto:**
- página da esquerda: x de 14 a 118; página da direita: x de 138 a 242; as duas de y = 12 a 130;
- cabem 17 caracteres por linha e 10 linhas por página, com `fonte_5x7_escura`;
- o título vai em `fonte_5x7_dourada`.

As amostras são `amostra_tela_estante_4x.png` (duas prateleiras com 12 eras) e `amostra_tela_livro_4x.png`. As duas telas têm 480 × 160.

## 17. Vida ambiente (`criaturas/`)

São criaturas que não fazem parte da simulação: só dão vida ao cotidiano. São pequenas, animadas e olham para a direita; para o outro lado, o motor espelha. A base é a última linha: os pés de quem está no chão, ou o centro de quem voa. Elas usam a tabela `noite`, menos os morcegos, que já são escuros. `amostra_criaturas_4x.png` mostra todas sobre o dia, o entardecer e a noite.

| Folha | Quadro | Quadros | Estação | Horário | Onde e como |
|---|---|---|---|---|---|
| `passaro_voar_4q` | 6 × 4 | 4 | primavera, verão, outono | dia | bando de 3 a 5 que voa e pousa |
| `passaro_pousado_2q` | 4 × 4 | 2 | primavera, verão, outono | dia | no chão, nas cercas e nos telhados |
| `peixe_saltar_4q` | 8 × 8 | 4 | primavera, verão, outono | dia e entardecer | salta do lago e volta; não no gelo |
| `sapo_2q` | 6 × 4 | 2 | primavera, verão | entardecer e noite | na margem e no junco |
| `garca_2q` | 8 × 8 | 2 | primavera, verão, outono | manhã e dia | parada na água rasa da margem |
| `coelho_4q` | 6 × 4 | 4 | todas | manhã e entardecer | no mato e na borda das roças; foge de gente |
| `cervo_4q` | 10 × 8 | 4 | todas menos inverno fundo | manhã (até 9h) | na borda da floresta do morro |
| `corvo_voar_4q` | 6 × 4 | 4 | todas | dia | sobre campos de batalha e onde há mortos |
| `corvo_pousado_2q` | 5 × 4 | 2 | todas | dia | pousado perto dos mortos e das ruínas |
| `morcego_4q` | 6 × 4 | 4 | primavera, verão, outono | entardecer e começo da noite | sai da floresta e das ruínas |
| `bando_migrando_4q` | 24 × 8 | 4 | inverno (e fim do outono) | dia | atravessa o céu alto de um lado a outro |

O `bando_migrando_4q` é uma formação de 5 pássaros em V, por isso passa do limite de 12 × 8. Cada pássaro tem 3 × 2. Os bandos pequenos de verão saem de vários `passaro_voar_4q`, com os quadros defasados.

**Ajustes na mata distante e no céu de inverno:**
- **Outono:** a mata distante tem copas laranja e ferrugem separadas, com textura, e a ponta esquerda termina em copas soltas, sem corte reto.
- **Inverno:** a mata distante tem neve nas copas e verde escuro salpicado de neve, nos 3 horários.
- **Céu de inverno:** os céus de dia e de entardecer ficaram mais frios e pálidos (`estacoes/inverno/montagem/ceu_<hora>.png`). A montagem agora também procura o céu na pasta da estação.

## 18. Vida dos habitantes e objetos de cena (`acoes/vida.py`, `objetos/`)

As folhas abaixo ficam em `acoes/` e seguem o padrão de sempre:
- olhando para a direita, com a base na última linha;
- cores-base e trocas de `habitantes/trocas.json`;
- quadros de 8 × 12; criança em 6 × 8; deitado e estandarte em 12 × 12, com o corpo nas colunas 0 a 7.

`acoes/amostra_vida_4x.png` mostra todas as folhas, e `objetos/amostra_objetos_4x.png`, os objetos.

**Objetos soltos** (`objetos/`), que o motor desenha junto da pessoa ou da cena:

| Objeto | Tamanho | Uso |
|---|---|---|
| `corpo_mortalha` | 16 × 4 | funeral: vai sobre 2 carregadores (`funeral_carregar_4q`) postos a 10 px um do outro. A linha 3 da mortalha fica na linha 3 dos carregadores. |
| `bebe_enrolado` | 6 × 4 | nascimento: o bebê deitado (no colo, use `mae_bebe_*`) |
| `bandeirolas` | 16 × 8 | festa: trecho de varal que repete na horizontal |
| `tambor` | 8 × 8 | festa: tambor no chão (tocado, use `tocar_tambor_4q`) |
| `coroa_flores`, `coroa_flores_cabeca` | 8 × 8, 6 × 2 | festa: coroa no chão ou na cabeça (a de cabeça vai nas colunas 1 a 6, linha 0 do habitante) |
| `trouxa`, `cesto_costas` | 8 × 8 | migração: no chão ou no acampamento (nas costas, use `andar_trouxa_4q` e `andar_cesto_4q`) |
| `estandarte_sol`, `estandarte_lua`, `estandarte_arvore` | 8 × 24 | guerra: estandarte fincado, nas 3 culturas |
| `escudo_sol`, `escudo_lua`, `escudo_arvore` | 8 × 8 | guerra: escudo caído ou pendurado |
| `cesto_cheio` | 8 × 8 | trabalho: cesto de colheita no chão |
| `peixe_mao` | 4 × 2 | trabalho: peixe solto (na mão, use `segurar_peixe_2q`) |
| `feixe_lenha` | 8 × 8 | trabalho: lenha empilhada (nos braços, use `carregar_lenha_4q`) |

### Mapa ação → folha

**Microanimações de quem está parado.** Para a ação `parado`, o motor pode sortear uma microanimação a cada tanto e depois voltar ao `adulto_*_parado_2q`.

| Situação | Folha | Quadros | Nota |
|---|---|---|---|
| `parado` (base) | `habitantes/adulto_a_parado_2q`, `adulto_b_parado_2q` (estágio 1); `estagioN/adulto_eN_parado_2q` | 2 | respiração |
| olhar para os lados | `acoes/olhar_lados_4q` | 4 | direita, frente, esquerda, frente |
| esticar os braços | `acoes/esticar_4q` | 4 | |
| sentar no chão | `acoes/sentar_chao_4q` | 4 | quadros 0 e 1: sentando; 2 e 3: sentado (repita em laço) |
| agachar | `acoes/agachar_2q` | 2 | |
| coçar a cabeça | `acoes/cocar_cabeca_4q` | 4 | |
| bocejar | `acoes/bocejar_4q` | 4 | |
| velho parado | `acoes/idoso_parado_2q` | 2 | apoiado na bengala |

**Ações da API e da rotina:**

| Ação | Folha | Quadros | Nota |
|---|---|---|---|
| `andar` | `habitantes/adulto_a_andar_4q`, `adulto_b_andar_4q`, `crianca_andar_4q`, `idoso_andar_4q`; `estagioN/adulto_eN_andar_4q` | 4 | |
| `dormir` | `acoes/dormir_2q` | 2 | 12 × 12, deitado nas linhas 8 a 11 |
| `fogueira` (sentado em volta do fogo) | `habitantes/adulto_a_sentado_1q` ou `acoes/sentar_chao_4q` (quadros 2 e 3) | | |
| `rezar` | `habitantes/adulto_a_rezar_2q` | 2 | |
| `colher` | `habitantes/adulto_a_colher_4q`; com roça, `estagio2/adulto_enxada_trabalhar_4q` | 4 | |
| `colher` na margem | `acoes/pescar_4q`, e depois `acoes/segurar_peixe_2q` | 4 e 2 | |
| buscar ou carregar lenha | `acoes/carregar_lenha_4q` | 4 | |
| carregar colheita | `acoes/carregar_cesto_4q` | 4 | cesto na cintura |
| construir | `acoes/construir_4q` | 4 | |
| forjar | `acoes/forjar_4q` (ou `estagio4/ferreiro_trabalhar_4q`, 12 × 12) | 4 | ao lado da `forja` |
| escrever | `acoes/escrever_4q`; sentado, `estagio5/escriba_sentado_2q` | 4 e 2 | |
| remar | `acoes/remar_4q` | 4 | sobre o `barco_2q` |
| lutar | `acoes/lutar_4q`; marchando, `estagio4/guerreiro_andar_4q` (12 × 12) | 4 | |

**Vida social e cenas de eventos:**

| Situação | Folha | Quadros | Nota |
|---|---|---|---|
| conversar | `acoes/conversar_falar_4q` + `acoes/conversar_ouvir_4q` | 4 | o par fica de frente: um normal e o outro espelhado, a 9 px; os papéis se alternam |
| mãe com bebê | `acoes/mae_bebe_parado_2q`, `acoes/mae_bebe_andar_4q` | 2 e 4 | adulto B com o bebê no colo |
| crianças correndo | `acoes/crianca_correr_4q` | 4 | 6 × 8 |
| crianças pulando | `acoes/crianca_pular_4q` | 4 | 6 × 8; o motor sobe o sprite 2 a 4 px nos quadros 1 e 2 |
| casal de mãos dadas | `acoes/casal_esquerda_andar_4q` + `acoes/casal_direita_andar_4q` | 4 | a da direita fica a 8 px da da esquerda, e as mãos se encontram |
| velho de bengala | `habitantes/idoso_andar_4q`, `acoes/idoso_parado_2q` | 4 e 2 | |
| funeral | 2 × `acoes/funeral_carregar_4q` + `objetos/corpo_mortalha` | 4 | o de trás vai com o quadro defasado em 2; quem carrega um morto sozinho usa `acoes/carregar_morto_4q` |
| festa | `acoes/dancar_4q`, `acoes/tocar_tambor_4q` + `objetos/bandeirolas`, `tambor`, `coroa_flores*` | 4 | |
| nascimento | `acoes/mae_bebe_*` + `objetos/bebe_enrolado` | | |
| migração | `acoes/andar_trouxa_4q`, `acoes/andar_cesto_4q` + `objetos/trouxa`, `cesto_costas` | 4 | |
| guerra | `acoes/carregar_estandarte_<cultura>_4q` (sol, lua ou arvore) (12 × 12), `acoes/lutar_4q` + `objetos/estandarte_*`, `escudo_*` | 4 | o pano do estandarte usa a cor da roupa (28), e por isso troca junto com a roupa do povo |

## 19. Estações na agricultura e noite nas construções

**Construções no inverno.** Todas as construções dos estágios 2 a 6 têm versão de inverno em `estacoes/inverno/<pasta>/`, com o mesmo nome:
- casas, celeiro, templos, forja, biblioteca, muralha e torre, moinho, barco;
- as partes de cultura (paredes, telhados e símbolos);
- todas as ruínas, inclusive as cobertas de mato (`natureza/`).

O `estacoes/amostra_construcoes_inverno_4x.png` mostra as construções nevadas.

**Agricultura nas 4 estações.** As roças (`estagio2/roca_*` e `estagio6/roca_irrigada`) e o pomar mudam nas 4 estações; a roda d'água só congela no inverno. As variações ficam em `estacoes/<estacao>/<pasta>/`, e a amostra é `estacoes/amostra_agricultura_4x.png`.

| Peça | Primavera | Outono | Inverno |
|---|---|---|---|
| roças | verde mais vivo e florzinhas entre os sulcos | o verde amarela, a espiga fica cor de cobre, folhas caídas no solo | coberta de neve: sulcos brancos e só pontas de palha seca; na irrigada, o rego congelado |
| `estagio2/arvore_fruta` (pomar, 24 × 24, tronco na coluna 10; no verão, frutas verdes amarelando) | em flor (branco e rosa) | frutas maduras e folhas alaranjadas | galhos nus com neve |
| `estagio6/roda_dagua_4q` (16 × 16, gira 11,25° por quadro e respinga) | igual ao verão | igual ao verão | parada e congelada: os 4 quadros são iguais, com gelo e pingentes |

**Noite nas construções** (`luzes/luzes.py`):
- `<estagio>/<casa>_luz.png`: só as janelas acesas, do mesmo tamanho e encaixe da casa. Valem para `estagio2/casa_taipa`, `estagio3/casa_pedra`, `estagio4/casa_enxaimel` e `estagio6/casa_tijolo`. O motor desenha por cima da casa à noite e ao entardecer, sem a tabela `noite`, porque é luz. Também pode acender e apagar cada casa.
- `luzes/chamine.png` (4 × 8): a chaminé de pedra.
- `luzes/chamines.json`: para cada casa e cada um dos 3 telhados, onde vai a chaminé e de onde sai a fumaça, em coordenadas relativas ao canto da casa.
- `luzes/fumaca_chamine_4q.png` (8 × 16): um fiapo fino de fumaça, irregular e sem grade, que sobe e se desfaz. Use só no inverno, nas casas com lareira.

O `luzes/amostra_luzes_4x.png` mostra as casas à noite no inverno, com as janelas acesas e a fumaça.

## 20. Cotidiano: subações, incidentes e caça (`acoes/cotidiano.py`)

As folhas abaixo ficam em `acoes/` e seguem o mesmo padrão das outras ações (veja a seção 18), com as cores-base de `habitantes/trocas.json`. `acoes/amostra_cotidiano_4x.png` mostra todas, junto com os animais e os objetos novos.

### Mapa subação → folha

| Subação | Folha | Quadros | Como montar |
|---|---|---|---|
| `colher_arbusto` | `acoes/colher_arbusto_4q` | 4 | alcança no alto, pega a fruta e põe no cesto do quadril; de frente para o arbusto |
| `cavar_raiz` | `acoes/cavar_raiz_4q` | 4 | ajoelhado; a vara crava, revolve a terra e a raiz sai na mão |
| `catar_lenha` | `acoes/catar_lenha_4q` | 4 | abaixa, pega os galhos e levanta com eles no braço; depois, `carregar_lenha_4q` |
| `carregar_cesto` | `acoes/carregar_cesto_cabeca_4q` (na cabeça), `acoes/andar_cesto_4q` (nas costas), `acoes/carregar_cesto_4q` (no quadril) | 4 | |
| `cacar` | `acoes/cacar_espreitar_4q`, e depois `acoes/cacar_arremessar_4q` | 4 + 4 | anda agachado com a lança na horizontal e arremessa. A lança solta é `objetos/lanca_voando` (12 × 3), lançada a partir do quadro 2. |
| `carregar_caca` | 2 × `acoes/carregar_caca_4q` + `objetos/caca_no_pau_porco` ou `caca_no_pau_ave` | 4 | os dois carregadores ficam a 12 px um do outro, com o quadro defasado em 2. A linha 0 do objeto (o pau) vai na linha 3 dos carregadores, entre eles. |
| `cozinhar` | `acoes/cozinhar_mexer_4q` + `objetos/panela`; `acoes/cozinhar_espeto_4q` + `objetos/espeto` | 4 | agachado diante da panela, mexendo; ou sentado girando o espeto. O fogo é a fogueira. |
| `buscar_agua` | `acoes/buscar_agua_4q` | 4 | na margem: abaixa, enche a cuia e levanta. Depois, a cuia cheia é `objetos/cuia_cheia`. |
| `banhar` | `acoes/banhar_4q` | 4 | na margem: joga água da cuia na cabeça |
| `vigia` | `acoes/vigia_2q` | 2 | sentado com a lança em pé; no quadro 1 a cabeça pesa de sono (use à noite) |
| `contar_historia` | `acoes/contar_historia_4q` + ouvintes `acoes/ouvir_sentado_2q` | 4 e 2 | quem conta fica de pé, gesticulando; os ouvintes ficam sentados em volta, virados para ele |

### Pequenos incidentes

| Incidente | Folha | Quadros | Como montar |
|---|---|---|---|
| crianças brigando | `acoes/criancas_brigar_4q` (6 × 8) | 4 | duas crianças de frente, uma espelhada, a 5 px, com quadros defasados |
| tropeçar e cair | `acoes/tropecar_cair_4q` (12 × 12) | 4 | tropeça, se desequilibra, cai e fica de bruços até a coluna 11. Depois, `agachar_2q` para levantar. |
| espantar um animal | `acoes/espantar_4q` | 4 | abana os braços dando pulinhos, virado para o bicho |
| discussão | `acoes/discutir_4q` | 4 | duas pessoas de frente, uma espelhada, a 9 px, com quadros defasados |
| abraço de reencontro | `acoes/abraco_4q` | 4 | duas pessoas de frente, uma espelhada, a 5 px; as duas correm um passo e fecham o abraço |

### Animais de caça (`criaturas/`)

| Folha | Quadro | Quadros | Onde e quando |
|---|---|---|---|
| `porco_do_mato_4q` | 10 × 6 | 4 | anda e fuça na borda da floresta e no mato, de dia; foge de gente |
| `ave_grande_4q` | 8 × 8 | 4 | anda e bica o chão nos campos e na margem, de dia |
| `porco_abatido`, `ave_abatida` | 10 × 6, 8 × 8 | 1 | o animal caído, depois da caça |

## Critérios

| Critério | Situação |
|---|---|
| Terreno: grama (2 variações, borda irregular), terra, terra escura com raízes, pedras, rocha, areia, água funda, grama seca e água animada em 4 quadros | **Atendido**, com blocos extras de transição, terra batida e uma rocha de 16 blocos |
| Montagem do terreno em 480 × 160 só com blocos | **Atendido**: `terreno/terreno_teste.png` |
| Habitantes A e B parados (2q) e andando (4q); criança, idoso, rezar e colher | **Atendido**, mais um quadro sentado |
| Roupa só com cores do grupo tecidos | **Atendido.** A roupa é de uma cor só, sem tom de sombra. A forma vem do couro, dos braços e da silhueta. |
| Folha de variações de pele e roupa | **Atendido**: `variacoes_pele_roupa.png` e `trocas.json` |
| Estágio 1: cabana, fogueira acesa (4q) e apagada, 2 árvores de copa, 2 pinheiros, arbusto, capim, pedras e juncos, em múltiplos de 8 | **Atendido** |
| Montagem de dia e de noite só com peças e camadas, e as camadas entregues como arquivos | **Atendido** |
| **A montagem parece a cena-alvo lado a lado** | **Atendido na minha avaliação.** Céu, montanhas, mata e reflexo são idênticos. Cerca de 16% dos pixels diferem de dia e 14% de noite, quase todos no solo e na vegetação. As diferenças estão listadas abaixo. |

## Diferenças que ainda se veem entre a montagem e a cena

- **Morro e praia.** A cena tem um perfil contínuo. Na montagem, cada coluna de 8 px tem uma altura só, e aparecem degraus de 1 a 3 px.
- **Roupas.** Na cena, a roupa tem um tom de sombra fora do grupo de tecidos. Nas peças, a roupa é chapada, então as pessoas ficam um pouco mais lisas.
- **Pinheiros.** A cena tem pinheiros de 7 alturas. As peças têm 2 tamanhos e o do fundo, então a floresta fica mais regular.
- **Solo.** A rocha se repete a cada 64 px, e as fronteiras entre as camadas variam menos que na cena.
- **Poses.** O pescador com lança e o adulto apontando não viraram peças. Na montagem, eles usam as poses de parado.

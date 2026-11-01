# Peças modulares do estágio 1

Estas são as peças que o jogo monta. Todas saem do tratamento visual da cena-alvo, `arte_claude/alvo/`. As plantas, as pedras, a cabana e a fogueira são desenhadas pelas mesmas funções de `alvo/cena.py`, e as camadas do motor usam as mesmas sementes da cena. Por isso o céu, as montanhas e o reflexo batem pixel a pixel com ela.

**Para recriar tudo:** `python gerar_tudo.py`. **Para conferir:** `python validar.py`, que verifica a paleta, a transparência e os tamanhos.

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
| `fumaca_6q` | 16 × 16 | 6 | baforada que sobe, cresce e se desfaz |
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
| Poderes | `chuva`, `raio`, `fogo`, `fartura`, `erguer_terra`, `sonho` |
| Tempo | `pausa`, `normal`, `rapido`, `salto` |
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

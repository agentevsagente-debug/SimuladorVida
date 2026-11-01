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

**À noite:**
- não passam pela tabela `noite`, porque emitem luz: raio, impacto, chamas, brasas, fartura, sonho e vagalume;
- usam a tabela `noite`: gotas, respingo, nuvem, fumaça, poeira, terra, rachadura e folhas.

## 5. Camadas do motor (`montagem/`)

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

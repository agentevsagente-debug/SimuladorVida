# Tarefas de arte

*Faça as tarefas na ordem. O protocolo está em `LEIA-ME.md` e as regras visuais em `guia-de-estilo.md`.*

> **Revisão do Claude (01/11):**
> - **T001 (paleta): APROVADA.**
> - **T001A (prancha): APROVADA.** O usuário escolheu a **direção C, Clássica 16 bits**. O guia de estilo foi atualizado.
> - **T002 a T005: SUBSTITUÍDAS.** Ficam como referência técnica de formato e são refeitas na direção C pelas tarefas T006 a T010. Não as altere.

---

## T001 — Paleta
**Estado:** APROVADA

Criar a paleta de 32 cores seguindo a tabela "Paleta" do guia de estilo.

**Entregar em `arte/paleta/`:**
- `paleta.hex`: as 32 cores, uma por linha, no formato `RRGGBB`, na ordem dos grupos do guia;
- `paleta.png`: uma amostra de 8 × 8 pixels por cor, numa grade de 8 colunas por 4 linhas (64 × 32 pixels);
- `paleta.gpl`: a mesma paleta no formato GIMP Palette;
- `paleta_teste.png`: uma tira de 480 × 160 pixels que mostra o céu de dia à esquerda, o entardecer no meio e a noite à direita, com uma faixa de chão e água embaixo, usando só a paleta;
- os scripts `.py` que geram cada PNG.

**Critérios de aceite:**
- exatamente 32 cores, sem repetição, distribuídas nos grupos do guia;
- os 4 tons de pele são claramente diferentes entre si;
- as cores de tecido se destacam sobre vegetação, terra e céu;
- na `paleta_teste.png`, a transição entre dia, entardecer e noite fica bonita usando só as cores da paleta.

---

## T001A — Prancha de estilo (3 direções)
**Estado:** APROVADA

Esta é a tarefa mais importante da fase de arte. Antes de produzir peças, precisamos **ver como o jogo vai parecer**. Pinte a **mesma cena** em 3 direções visuais diferentes, como se fossem 3 capturas de tela do jogo pronto. O usuário escolhe uma, e todas as tarefas seguintes passam a seguir a direção escolhida.

**A cena (igual nas 3 direções):** 480 × 160 pixels, corte lateral. Um pequeno mundo ao entardecer, com:
- céu com nuvens e o sol baixo;
- à esquerda, uma praia e a água com reflexo;
- no centro, um grupo de coletores (6 a 8 pessoas, incluindo crianças) em volta de uma fogueira, com duas cabanas de galhos;
- à direita, uma floresta e um morro;
- três planos de profundidade: montanhas ou colinas ao fundo, o mundo no meio e algumas plantas na frente.

**As 3 direções:**
- **A, Atmosférica:** inspirada em *Kingdom Two Crowns*. Cores contidas, silhuetas fortes, muita atmosfera (névoa, céu em degradê com pontilhado, reflexo marcante na água, brilho do fogo). Pouco detalhe nas pessoas, muito clima no cenário.
- **B, Aconchegante:** inspirada no clima do *Terraglass* e de jogos aconchegantes. Cores mais saturadas e quentes, formas arredondadas, mundo alegre e convidativo.
- **C, Clássica 16 bits:** inspirada nos jogos de 16 bits. Mais detalhe e contorno nos objetos, texturas no terreno, pessoas mais definidas.

Não copie nenhuma imagem desses jogos. Use apenas o espírito visual descrito.

**Liberdade de método nesta tarefa:** para a prancha, você pode pintar pixel a pixel por código ou usar geração de imagem e depois reduzir o resultado para a grade de pixels e para a paleta. O resultado final precisa respeitar as regras técnicas do guia (pixels nítidos, sem semitransparência). Cada direção pode usar a paleta da T001 ou propor ajustes de cor; nesse caso, entregue a paleta usada.

**Entregar em `arte/prancha/`:**
- `direcao_a.png`, `direcao_b.png`, `direcao_c.png`: a cena em 480 × 160;
- `direcao_a_4x.png`, `direcao_b_4x.png`, `direcao_c_4x.png`: as mesmas cenas ampliadas 4 vezes, sem suavização;
- `direcao_a_noite.png`, `direcao_b_noite.png`, `direcao_c_noite.png`: a mesma cena à noite, com a fogueira como fonte de luz;
- os scripts ou o processo usado, descritos em `arte/prancha/PROCESSO.md`.

**O que aprendemos com as T001 a T005 (revisão do Claude):** tecnicamente estão corretas, mas a cena parece um rascunho de programador, não um jogo. Na prancha, evite:
- céu em 3 faixas chapadas: use degradê com pontilhado e nuvens com volume;
- terreno como um bloco marrom liso e degraus quadrados: use perfis orgânicos, camadas de solo, raízes, pedras e grama irregular na borda;
- falta de profundidade: os 3 planos precisam existir, com o fundo mais claro e menos saturado;
- noite como simples troca de cores: a fogueira precisa iluminar o entorno e projetar luz quente nas pessoas e no chão;
- a faixa repetida na base da cena;
- água sem reflexo.

**Critérios de aceite:**
- as 3 direções são claramente diferentes entre si;
- cada imagem parece uma captura de um jogo bonito e acabado, não um rascunho;
- em 1x, as pessoas são visíveis e a fogueira é o centro da cena;
- a versão noturna é escura, mas legível.

---

## T002 — Terreno
**Estado:** SUBSTITUÍDA

Blocos de terreno de 8 × 8 pixels.

**Entregar em `arte/terreno/`:**
- `terreno.png`: folha com os blocos lado a lado, nesta ordem:
  1. grama (topo do chão), variação A
  2. grama, variação B
  3. terra, variação A
  4. terra, variação B
  5. pedra
  6. areia
  7. água funda
  8. grama seca (para secas)
- `agua_superficie_4q.png`: superfície da água animada, 4 quadros de 8 × 8;
- `terreno_teste.png`: um terreno de 480 × 160 pixels montado só com esses blocos: uma praia à esquerda, um lago no meio, um morro à direita, com céu transparente;
- os scripts `.py` geradores.

**Critérios de aceite:**
- blocos iguais encaixam lado a lado sem emenda visível;
- grama e terra encaixam verticalmente (grama em cima, terra embaixo);
- na `terreno_teste.png`, praia, lago e morro são reconhecíveis em escala 1x.

---

## T003 — Habitantes
**Estado:** SUBSTITUÍDA

Pessoas do estágio 1 (coletores, roupas simples de pele ou fibra).

**Entregar em `arte/habitantes/`:**
- `adulto_a_parado_2q.png` e `adulto_a_andar_4q.png`: adulto, corpo A, 8 × 12 por quadro;
- `adulto_b_parado_2q.png` e `adulto_b_andar_4q.png`: adulto, corpo B (silhueta diferente do A), 8 × 12 por quadro;
- `crianca_andar_4q.png`: criança, 6 × 8 por quadro;
- `habitantes_variacoes.png`: os adultos A e B parados, repetidos com os 4 tons de pele e as 3 cores de tecido, para mostrar as combinações;
- os scripts `.py` geradores.

**Critérios de aceite:**
- olhando para a direita;
- a animação de andar é legível e não "treme";
- a roupa usa só as cores do grupo "tecidos";
- adultos A e B se distinguem pela silhueta, não só pela cor.

---

## T004 — Estágio 1: abrigo e natureza
**Estado:** SUBSTITUÍDA

**Entregar em `arte/estagio1/`:**
- `cabana_galhos.png`: abrigo de galhos e folhas, 16 × 16;
- `fogueira_4q.png`: fogueira acesa animada, 4 quadros de 8 × 8;
- `fogueira_apagada.png`: a mesma fogueira apagada, 8 × 8;
- `arvore_a.png` e `arvore_b.png`: duas árvores diferentes, 16 × 24;
- `arbusto.png`: 8 × 8;
- os scripts `.py` geradores.

**Critérios de aceite:**
- a cabana é reconhecível como abrigo humano primitivo em escala 1x;
- o fogo se destaca à noite (teste mentalmente sobre o céu de noite da paleta).

---

## T005 — Cena de teste
**Estado:** SUBSTITUÍDA

Montar uma cena com tudo o que foi entregue nas tarefas T001 a T004.

**Entregar em `arte/cenas/`:**
- `cena_dia.png` e `cena_noite.png`: 480 × 160 pixels. Usam o terreno da T002 e o céu da T001. Mostram um pequeno grupo de coletores (5 a 8 pessoas, incluindo crianças) perto de duas cabanas e uma fogueira, com árvores e arbustos;
- `cena_dia_3x.png` e `cena_noite_3x.png`: as mesmas cenas ampliadas 3 vezes, sem suavização;
- o script `.py` que monta as cenas.

**Critérios de aceite:**
- em 1x, dá para contar as pessoas e distinguir adultos de crianças;
- a cena noturna é escura mas legível, com a fogueira como foco de luz;
- o conjunto parece um único estilo coerente.

---

# Produção na direção C

*Todas as tarefas abaixo seguem a seção "Direção escolhida: C, Clássica 16 bits" do guia de estilo, incluindo as correções. Gere por código, com o script ao lado de cada PNG, como nas tarefas anteriores. Use só a paleta da T001.*

---

## T006 — Cena-alvo da direção C
**Estado:** PENDENTE

Repintar a cena da prancha na direção C **com todas as correções do guia**. Esta cena passa a ser a imagem de referência do jogo: todas as peças seguintes precisam combinar com ela.

**Entregar em `arte/alvo/`:**
- `alvo_entardecer.png`, `alvo_dia.png`, `alvo_noite.png`: 480 × 160;
- as mesmas três ampliadas 4 vezes (`_4x`), sem suavização;
- os scripts `.py`.

**Critérios de aceite:**
- superfície do chão por volta de 75% da altura, com camadas de solo visíveis abaixo;
- pessoas nítidas e definidas, o elemento mais legível da cena em 1x;
- pelo menos 3 tipos de vegetação com o mesmo tratamento de luz;
- na noite, a fogueira ilumina o chão e as pessoas próximas;
- comparada com `arte/prancha/direcao_c.png`, a cena é claramente melhor e mantém o mesmo estilo.

---

## T007 — Terreno na direção C
**Estado:** PENDENTE

Refazer os blocos da T002 no estilo da cena-alvo. Mesmos arquivos e tamanhos da T002, agora em `arte/terreno_c/`, com estes blocos a mais na folha:
- terra escura com raízes;
- rocha;
- borda de grama irregular (2 variações), para quebrar a linha reta do chão;
- pedra aflorada pequena (8 × 8, com fundo transparente).

**Critérios de aceite:** os da T002, e uma montagem `terreno_c_teste.png` (480 × 160) com o perfil do terreno da cena-alvo que pareça a própria cena-alvo sem pessoas e sem objetos.

---

## T008 — Habitantes na direção C
**Estado:** PENDENTE

Refazer os habitantes da T003 com a definição pedida no guia. Mesmos arquivos, quadros e tamanhos da T003, agora em `arte/habitantes_c/`, com estes a mais:
- `idoso_andar_4q.png` (8 × 12, postura curvada);
- `adulto_a_rezar_2q.png` (8 × 12, ajoelhado com os braços erguidos);
- `adulto_a_colher_4q.png` (8 × 12, abaixando para pegar algo do chão).

**Critérios de aceite:** os da T003, e as pessoas precisam ter a mesma definição das pessoas da cena-alvo.

---

## T009 — Estágio 1 na direção C
**Estado:** PENDENTE

Refazer as peças da T004 no estilo da cena-alvo, em `arte/estagio1_c/`, com estas a mais:
- `pinheiro_a.png` e `pinheiro_b.png` (16 × 32);
- `capim.png` (8 × 8);
- `pedra_grande.png` (16 × 16).

**Critérios de aceite:** os da T004, e todas as peças combinam com a vegetação e as cabanas da cena-alvo.

---

## T010 — Cena montada com as peças
**Estado:** PENDENTE

Montar a cena-alvo **usando somente as peças das T007 a T009**, sem pintar nada à mão. Isso prova que o jogo, montando as peças, chega ao visual da cena-alvo.

**Entregar em `arte/cenas_c/`:** `montada_dia.png` e `montada_noite.png` (480 × 160), as versões 4x e o script.

**Critérios de aceite:** lado a lado com `arte/alvo/alvo_dia.png`, as duas imagens parecem o mesmo jogo. As únicas diferenças aceitas são céu, neblina, reflexo e luz, que no jogo serão efeitos do motor.

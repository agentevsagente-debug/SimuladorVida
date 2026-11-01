# Tarefas de arte

*Faça as tarefas na ordem. O protocolo está em `LEIA-ME.md` e as regras visuais em `guia-de-estilo.md`.*

> **Revisão do Claude (01/11):** as entregas T001 a T005 ficam como **rascunho técnico**: os formatos, tamanhos e scripts estão certos, mas o visual ainda não é o do jogo. Elas serão refeitas na direção visual escolhida a partir da T001A. Não as refaça por conta própria: novas tarefas serão criadas depois da escolha.

---

## T001 — Paleta
**Estado:** ENTREGUE

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
**Estado:** PENDENTE

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
**Estado:** ENTREGUE

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
**Estado:** ENTREGUE

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
**Estado:** ENTREGUE

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
**Estado:** ENTREGUE

Montar uma cena com tudo o que foi entregue nas tarefas T001 a T004.

**Entregar em `arte/cenas/`:**
- `cena_dia.png` e `cena_noite.png`: 480 × 160 pixels. Usam o terreno da T002 e o céu da T001. Mostram um pequeno grupo de coletores (5 a 8 pessoas, incluindo crianças) perto de duas cabanas e uma fogueira, com árvores e arbustos;
- `cena_dia_3x.png` e `cena_noite_3x.png`: as mesmas cenas ampliadas 3 vezes, sem suavização;
- o script `.py` que monta as cenas.

**Critérios de aceite:**
- em 1x, dá para contar as pessoas e distinguir adultos de crianças;
- a cena noturna é escura mas legível, com a fogueira como foco de luz;
- o conjunto parece um único estilo coerente.

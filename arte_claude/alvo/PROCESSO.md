# Cena-alvo da direção C: versão do Claude

Esta é a versão do Claude para a T006, feita para ser comparada com a do Codex. Para manter a comparação independente, não olhei `arte/alvo/`. As únicas referências foram o guia de estilo, a especificação da T006, a prancha C (dia e noite) e a paleta.

## Arquivos

| Arquivo | O que é |
|---|---|
| `alvo_entardecer.png`, `alvo_dia.png`, `alvo_noite.png` | a cena em 480 × 160 |
| `alvo_*_4x.png` | as mesmas cenas ampliadas 4 vezes por vizinho mais próximo |
| `cena.py` | toda a pintura, com a função `render(hora)` |
| `gerar.py` | grava os seis PNGs |
| `validar.py` | confere o tamanho, se todas as cores são da paleta e se todos os pixels são opacos |

Para recriar as imagens: `python gerar.py` e depois `python validar.py`. Os scripts funcionam a partir de qualquer pasta. O resultado é sempre o mesmo, porque todo sorteio usa uma semente fixa.

## Método

- Tudo é pintado em **índices da paleta** de `arte/paleta/paleta.hex`. Não existe mistura de cores, e o RGB só aparece na hora de gravar.
- Os degradês usam **pontilhado ordenado (Bayer 4 × 4)**, sempre numa faixa estreita entre duas cores. É o mesmo pontilhado da prancha C, porém sem as faixas chapadas largas.
- O **mundo** (chão, plantas, cabanas e pessoas) é pintado uma vez com as cores de dia e depois remapeado por tabela para cada horário. Céu, montanhas, mata distante e água são pintados separadamente em cada horário.
- Cada pixel recebe uma **etiqueta** (céu, mundo, pessoa, fogo, água ou frente). Os remapeamentos usam essas etiquetas. Por exemplo, a luz do fogo não entra no corte do solo e não altera o céu.

## Decisões visuais

**Composição (da esquerda para a direita):** mar em corte, com fundo de areia inclinado, algas e peixes; praia com juncos, tronco à deriva, conchas e um pescador com lança; clareira com uma árvore larga, a cabana A, os coletores em volta da fogueira e a cabana B; morro subindo para a direita, com floresta de pinheiros e árvores largas.

**Três planos de profundidade:**
1. Fundo: duas cordilheiras. A distante é mais clara e menos saturada. A próxima é mais escura.
2. Uma linha de mata distante com copas arredondadas, logo atrás das pessoas.
3. O mundo e algumas plantas escuras no primeiro plano, nas bordas.

**Chão a 75%:** a superfície da clareira fica em y = 120, exatamente 75% da altura. Abaixo dela vêm as camadas:
- grama em três tons, com a borda irregular e tufos acima da linha;
- terra com grãos claros e escuros;
- terra escura com raízes que saem das árvores e pedras arredondadas;
- rocha em blocos irregulares (diagrama de Voronoi), com rachaduras e escurecendo com a profundidade.

As fronteiras entre as camadas ondulam por ruído, de modo que nenhuma faixa se repete. Na praia, a areia substitui a grama e a terra.

**Vegetação, quatro tipos com a mesma regra de luz** (vem de cima e da esquerda, borda iluminada clara, miolo médio, base e lado direito no tom escuro):
- pinheiros segmentados em camadas, com pontas penduradas;
- árvores de copa larga feitas de vários círculos, cada pixel sombreado pela direção da sua normal;
- arbustos, alguns com frutinhas, já que são coletores;
- capim verde e capim seco, mais os juncos na beira d'água.

Os pinheiros do fundo do morro usam tons mais escuros para dar profundidade dentro da floresta.

**Montanhas:** são feitas de picos sobrepostos. O lado voltado ao sol fica claro, e o lado oposto fica escuro. A crista tem uma transição pontilhada, e há facetas curtas de sombra descendo do pico. Durante o dia, os picos distantes têm neve.

**Pessoas (8 × 12 adultos e 6 × 8 crianças, como na tabela do guia):** foram desenhadas à mão, como moldes de texto, sem gerar procedimentalmente. Cada uma tem:
- cabelo com um pixel de brilho e olho escuro;
- um pixel de sombra no rosto, junto ao cabelo;
- tronco em dois tons de roupa;
- braços em cor de pele, que se destacam da roupa;
- pernas em dois tons, com a de trás mais escura;
- pés.

Há seis poses: em pé, andando, apontando para o fogo, sentado num tronco, com lança, e criança com a mão erguida. Os personagens usam quatro tons de pele, cinco cores de cabelo (inclusive uma anciã de cabelo grisalho) e as três cores de tecido. O grupo tem seis adultos e duas crianças. Quem fica à direita do fogo está espelhado, olhando para ele.

**Cabanas de galhos (16 × 16):** galhos inclinados alternam com faixas de folhas, com a borda esquerda clara e a direita escura. A porta é um triângulo escuro. As pontas dos galhos se cruzam no topo.

**Fogueira:** chama em quatro tons (vermelho, laranja, amarelo e branco), lenha cruzada e anel de pedras. De dia sai fumaça. À noite a chama fica mais alta e soltam-se fagulhas.

### Por horário

- **Entardecer:** o céu vai do azul ao violeta, ao rosa e ao laranja. O sol está pousado num vale entre as montanhas distantes. As nuvens são alongadas, com a borda laranja, o corpo rosa e a sombra violeta, e têm fiapos embaixo. O reflexo do sol na água aparece em traços horizontais amarelos e laranja. A borda de cima da grama fica dourada. O sol baixo à esquerda cria uma **luz de contorno** na borda esquerda de cada pessoa, o que as separa da mata escura atrás.
- **Dia:** o céu vai do azul ao azul-claro. O sol fica alto, as nuvens são brancas, a cordilheira distante é azul com neve e a próxima é azul-esverdeada. A água tem raios de luz descendo.
- **Noite:** o céu é azul profundo com estrelas, algumas em forma de cruz, e uma lua crescente com halo. O mundo é remapeado para tons frios. A fogueira cria dois anéis de luz: o de perto é quente e claro, e o médio fica entre o dia e a noite. Os anéis têm pontilhado só numa faixa estreita da borda, para não virar chuvisco. A luz pega o chão da clareira, a grama, as plantas e as pessoas. Em cada pessoa, o lado voltado para o fogo recebe um nível de luz a mais que o lado de trás, e é isso que dá volume. No céu, a área atrás da fogueira ganha um halo leve.

## Rodadas de revisão

1. **Primeira versão.** As pessoas já ficavam legíveis. Problemas encontrados:
   - o céu tinha faixas chapadas largas;
   - as montanhas tinham riscos diagonais regulares que pareciam chuva;
   - a mata distante ficou quadriculada, parecendo uma cerca;
   - a rocha ficou clara demais, em blocos grandes, e dominava a cena;
   - as raízes eram longas demais e pareciam fios;
   - à noite o solo continuava marrom-claro e o halo do fogo virava um disco de pontinhos.
2. **Correções da primeira rodada:**
   - mais paradas no degradê do céu;
   - facetas curtas no lugar dos riscos das montanhas;
   - mata com copas arredondadas sólidas;
   - rocha em blocos menores e mais escura em direção ao fundo;
   - raízes curtas com ramificações;
   - noite mais escura no solo.

   As cores de cada plano foram reorganizadas por valor: fundo claro, meio médio e mata escura.
3. **Luz do fogo.** O pontilhado em degradê largo fazia os arbustos verdes ficarem salpicados de amarelo. Troquei por anéis com bordas estreitas e tabelas de luz menos amarelas para a vegetação. O anel médio passou a ser mais escuro que o dia.
4. **Legibilidade das pessoas ao entardecer.** O adulto sentado, de pele escura e cabelo preto, sumia contra a mata azul-escura. Clareei a mata do entardecer e criei a luz de contorno do sol. Também desci as faixas do céu, porque a face iluminada das montanhas distantes tinha a mesma cor do céu atrás e desaparecia. Agora a face rosa fica contra o céu laranja.
5. **Correção na noite.** O céu e as montanhas eram remapeados duas vezes e escureciam demais, a ponto de as montanhas sumirem. Depois da correção, a cordilheira volta a aparecer em violeta, iluminada pela lua.

## Conflitos e compromissos

- **Sombra da roupa fora do grupo "tecidos".** O guia pede roupa sombreada, mas a paleta só tem três tecidos e nenhum tom escuro para eles. Usei como sombra o vermelho do fogo para o rosa (27 → 20), a água média para o turquesa (28 → 18) e o violeta da noite para o lilás (29 → 5). **Na hora de trocar a cor da roupa por cultura, o motor precisa trocar também esses pares de sombra.** Outra saída seria acrescentar três tons escuros de tecido à paleta.
- **A luz de contorno do entardecer também tira a roupa do grupo de tecidos.** Na borda iluminada, rosa vira laranja do fogo (27 → 21), turquesa vira espuma (28 → 19) e lilás vira rosa do entardecer (29 → 7). É um efeito de luz do motor, pintado só nesta cena de teste. A camada que troca a cor da roupa por cultura não deve depender dele.
- **Crianças com 6 × 8.** A tarefa fala em pessoas de 8 × 12, e o guia define crianças com 6 × 8. Segui o guia.
- **Cabana.** O corpo da cabana tem 16 × 16. As pontas dos galhos cruzados passam 2 pixels acima desse quadro.
- **A luz do fogo não entra no corte do solo.** Ela ilumina só a superfície e até 3 pixels abaixo dela, porque o corte do solo é uma vista "de raio X", e não algo que o fogo alcançaria.

## Critérios de aceite da T006 (minha avaliação)

| Critério | Situação |
|---|---|
| Superfície do chão por volta de 75%, com camadas visíveis abaixo | **Atendido.** y = 120 na clareira, com grama, terra, terra escura com raízes e pedras, e rocha. |
| Pessoas nítidas e definidas, o elemento mais legível em 1x | **Atendido em grande parte.** São as cores mais vivas da cena, com cabelo, sombra no rosto, braços e pernas em dois tons. Em 1x, porém, os oito personagens ficam juntos numa faixa de 100 px, e os detalhes internos (olho, sombra do rosto) só aparecem ampliados. |
| Pelo menos 3 tipos de vegetação com a mesma luz | **Atendido.** São quatro tipos: pinheiro, árvore larga, arbusto e capim, além dos juncos. |
| À noite, a fogueira ilumina o chão e as pessoas próximas | **Atendido.** Há dois anéis de luz quente no chão e nas plantas, e as pessoas têm o lado voltado ao fogo mais claro. |
| Claramente melhor que `direcao_c.png`, mantendo o estilo | **Atendido na minha avaliação.** O estilo da prancha foi mantido: céu pontilhado, nuvens alongadas, montanhas em dois tons, pinheiros segmentados e reflexo em traços. A cena ganhou camadas de solo, terreno orgânico, mais vegetação, pessoas definidas e luz de fogo real. Quem decide é o usuário. |

## Pontos fracos que eu ainda vejo

- A **camada de rocha** chama um pouco de atenção demais para algo que fica no fundo. Os blocos parecem um calçamento.
- O **primeiro plano** é fraco. São só algumas samambaias escuras nas bordas. Pôr plantas grandes na frente cobriria o corte do solo, então ficou discreto.
- À noite, a **terra do morro** continua marrom e chama um pouco a atenção. Uma versão mais azulada ficaria mais noturna.
- As **raízes do morro** são longas e quase verticais, e lembram cipós.

# Atlas

Atlas de texturas gerados a partir de `arte_claude/pecas/`; os originais não mudam. Para recriar, rode `python atlas.py` e `python camadas.py`. Para conferir, rode `python verificar.py`, que testa as regiões pixel a pixel contra os originais, a margem entre peças e o tamanho em potência de 2.

## Atlas de peças

Cada atlas `<nome>.png` vem com `<nome>.json`. Os atlas são potência de 2, com no máximo 2048 × 1024, e têm 1 px de margem transparente entre as peças.

No JSON, `regioes` é indexado pelo nome da peça (`pasta/peça`, igual a `arte_claude/pecas`). Para cada peça, ele traz:
- o retângulo da folha inteira (`x`, `y`, `w`, `h`);
- o número de `quadros` e se eles são quadros de animação ou `variacoes`;
- o tamanho de cada quadro (`quadro_w` × `quadro_h`). Os quadros vão da esquerda para a direita.

| Atlas | Tamanho | Peças | Memória de vídeo (L × A × 4) |
|---|---|---|---|
| `comum` | 1024x512 | 275 | 2048 KB |
| `pessoas_inverno` | 256x256 | 82 | 256 KB |
| `nuvens` | 256x128 | 45 | 128 KB |
| `estacao_primavera` | 256x128 | 68 | 128 KB |
| `estacao_verao` | 256x128 | 68 | 128 KB |
| `estacao_outono` | 256x128 | 68 | 128 KB |
| `estacao_inverno` | 256x128 | 69 | 128 KB |
| `estagio1` | 128x64 | 8 | 32 KB |
| `estagio1_inverno` | 128x64 | 8 | 32 KB |
| `estagio2` | 256x128 | 33 | 128 KB |
| `estagio2_inverno` | 256x128 | 33 | 128 KB |
| `estagio3` | 256x256 | 51 | 256 KB |
| `estagio3_inverno` | 256x256 | 51 | 256 KB |
| `estagio4` | 256x256 | 62 | 256 KB |
| `estagio4_inverno` | 256x256 | 62 | 256 KB |
| `estagio5` | 256x256 | 66 | 256 KB |
| `estagio5_inverno` | 256x256 | 66 | 256 KB |
| `estagio6` | 256x256 | 73 | 256 KB |
| `estagio6_inverno` | 256x256 | 73 | 256 KB |

**Total, com todos carregados: 5,19 MB.** O jogo só precisa de uma parte por vez: o `comum`, a estação atual e o estágio atual (o de verão ou o de inverno). Isso dá cerca de 2,2 a 2,5 MB (o inverno soma o `pessoas_inverno`).

**O `comum` passou de 512 × 512 para 1024 × 512** com a pesca, a lavagem e os bichos novos (era 241 peças e passou de 249, sem lugar no 512 × 512). O motor lê as posições do `comum.json` e das fontes, então nada muda no código, desde que nada suponha o tamanho 512. Ele tem espaço de sobra para as próximas peças.

**O que vai em cada atlas:**
- **`comum`:** habitantes, ações e vida, chaminé e fumaça de chaminé (`luzes/`), interface (ícones 12 e 8, caixas, botões, alça e as 4 fontes), sinais, efeitos (fase 1, fase 2 e neve), criaturas, objetos, estante e as marcas da memória de qualquer estágio (túmulo, pedra erguida, terra e árvore queimadas), com o mato que cresce sobre elas. O ícone do jogo fica fora, porque a bandeja usa o `.ico`.
- **`pessoas_inverno`:** as folhas de `habitantes/` e `acoes/` com a roupa de frio. No inverno, as regiões com o mesmo nome valem no lugar das do `comum`.
- **`nuvens`:** as 45 nuvens soltas do céu vivo (5 climas × 3 camadas × 3 tamanhos). O motor só usa as do clima atual, mas o atlas é pequeno o bastante para ficar inteiro.
- **`estacao_<primavera|verao|outono|inverno>`:** todos os blocos de terreno e a vegetação do estágio 1, na versão da estação (a de verão quando a estação não muda a peça), mais a muda, a árvore jovem, o pinheiro jovem e a fogueira antiga, a agricultura da estação (roças, pomar, roça irrigada e roda d'água). O de inverno tem também o `gelo_superficie`.
- **`estagio<N>` e `estagio<N>_inverno`:** as construções do estágio, com as camadas de janelas acesas (`<casa>_luz`), as ruínas com os 3 graus de mato e os habitantes do estágio. As roças, o pomar e a roda d'água ficam nos atlas de estação. O `_inverno` traz as mesmas peças com neve, e é ele que o motor carrega no inverno.
  - O estágio 1 tem a cabana, as fogueiras e a cabana abandonada.
  - O estágio 2 traz também as variações de cultura de `culturas/` e a casa em ruína.
  - O estágio 5 traz também os telhados e símbolos do templo de colunas, que o templo da escrita usa.

**Fontes:** `fonte_5x7_clara.fnt`, `fonte_5x7_escura.fnt`, `fonte_5x7_dourada.fnt` e `fonte_5x7_titulo.fnt` são as mesmas fontes, mas apontam para o `comum.png`. As coordenadas de cada letra já estão somadas à posição da fonte no atlas.

## Camadas grandes (`camadas/`, `camadas.json`)

Céus, montanhas, mata distante e reflexo ficam fora dos atlas. Mesmo assim, deu para reduzir todos sem perder nenhum pixel: o script remonta cada camada e confere com a original.

- **Montanhas, mata distante e reflexo:** foram recortados ao retângulo que tem pixels. O motor desenha o recorte no `x`, `y` indicado em `camadas.json`, dentro da área de 480 × 160.
- **Céus:** o degradê pontilhado se repete a cada 4 px na horizontal, porque o pontilhado Bayer é 4 × 4. Cada céu virou:
  - uma **faixa** de 4 × 160, que o motor repete na largura (ou usa como textura com repetição);
  - uma camada de **detalhes** (sol ou lua, nuvens, estrelas), recortada ao seu retângulo.

**Antes: 9,08 MB nas 31 camadas. Depois: 2,39 MB.** Num momento qualquer, o jogo usa só as camadas de uma estação e de um horário (ou dois, na transição). Com as 15 camadas de uma estação carregadas (3 horários × céu, 2 montanhas, mata e reflexo), a conta cai de 4,4 MB para cerca de 1,2 MB.

| Camada | Antes | Depois |
|---|---|---|
| céu (dia, entardecer, noite) | 300 KB cada | 108, 146 e 174 KB (faixa + detalhes) |
| céu de seca | 300 KB | 5 KB (só faixa e sol) |
| montanhas longe | 300 KB | 136 KB (recorte de 480 × 73) |
| montanhas perto | 300 KB | 76 KB (recorte de 480 × 41) |
| mata distante | 300 KB | 24 KB (recorte de 372 × 17) |
| reflexo | 300 KB | 3 a 9 KB |

**Mais economia possível, se a sessão B precisar:**
- As montanhas e a mata podem ser geradas por código no próprio jogo, porque são uma soma de picos com ruído fixo (`alvo/cena.py`, função `cordilheira`). Seriam só uma dúzia de números por camada.
- O céu inteiro também pode virar shader: o degradê são 3 a 4 cores com pontilhado Bayer, e só os detalhes precisariam de textura.

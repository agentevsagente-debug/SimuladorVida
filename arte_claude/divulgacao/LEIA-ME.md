# Divulgação

Imagens de apresentação do jogo para a vitrine no GitHub. Todas são feitas só com a arte do jogo: a cena-alvo, as cenas de vila e as peças. Usam só cores da paleta e nenhum pixel semitransparente; os logos têm fundo transparente. Para recriar, rode `python divulgacao.py`.

| Arquivo | Tamanho | O que é |
|---|---|---|
| `logo_grande.png` (e `_4x`) | 298 × 32 (1192 × 128) | o ícone do jogo e "Simulador de vida" na fonte de título |
| `logo_pequeno.png` (e `_4x`) | 175 × 19 (700 × 76) | só o nome, para cabeçalhos |
| `capa.png` | 1280 × 640 | prévia social do GitHub: a moldura do jogo, com a alça e o relógio, sobre uma área de trabalho estilizada (papel de parede, duas janelas e a barra de tarefas com o ícone na bandeja), mostrando a cena-alvo ao entardecer. O logo fica no alto. |
| `destaque_1_prece.png` | 960 × 320 | "O povo reza. Você decide." O povo reza diante do altar ao entardecer, e as preces sobem em 3 intensidades. |
| `destaque_2_chuva.png` | 960 × 320 | "A chuva do deus na seca." Céu de seca, roças secas e a nuvem carregada despejando a chuva. |
| `destaque_3_vila.png` | 960 × 320 | "Da cabana ao moinho." A vila do estágio 6: casas de tijolo, templo de cúpula, roça irrigada e moinho no morro. |
| `destaque_4_cronica.png` | 960 × 320 | "Fica a crônica." O mundo vazio ao entardecer, com ruínas tomadas pelo mato e árvores jovens, e a estante com os livros das eras. |

**A fonte de título** é a fonte 5 × 7 do jogo ampliada em blocos inteiros (2x no logo pequeno, 3x no grande), com degradê dourado-alaranjado, contorno escuro e sombra. As frases dos destaques usam a mesma fonte em 1x, sobre a caixa escura da dica do cursor.

**Montagem:**
- A capa foi composta em 640 × 320 e ampliada 2x por vizinho mais próximo.
- Cada destaque é um recorte de 240 × 80 de uma cena de 480 × 160, ampliado 4x. Assim, as pessoas e as frases ficam grandes na prévia.
- Tudo segue em escala inteira, sem suavização.

O nome "Simulador de vida" é provisório. Para trocar, mude o texto em `divulgacao.py` (as funções `logo` e `capa`) e rode de novo.

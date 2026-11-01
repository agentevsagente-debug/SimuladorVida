# Divulgação

Imagens de apresentação do jogo, para a vitrine no GitHub e para a versão 0.1 (amigos). Os destaques são montados com a arte (a cena-alvo, as cenas de vila e as peças); a capa, os momentos e o GIF são **capturas do jogo de verdade** (`capturar_divulgacao.sh`, guardadas em `fontes/`). Usam só cores da paleta e nenhum pixel semitransparente; os logos têm fundo transparente. Para recriar, rode `python divulgacao.py`.

| Arquivo | Tamanho | O que é |
|---|---|---|
| `logo_grande.png` (e `_4x`) | 298 × 32 (1192 × 128) | o ícone do jogo e "Simulador de vida" na fonte de título |
| `logo_pequeno.png` (e `_4x`) | 175 × 19 (700 × 76) | só o nome, para cabeçalhos |
| `capa.png` | 1280 × 640 | prévia social do GitHub: a moldura do jogo, com a alça e o relógio, sobre uma área de trabalho estilizada (papel de parede, duas janelas e a barra de tarefas com o ícone na bandeja), mostrando o jogo de verdade ao entardecer: a vila do estágio 3 com a roda em volta do fogo (`fontes/jogo_entardecer.png`). O logo fica no alto. |
| `destaque_1_prece.png` | 960 × 320 | "O povo reza. Você decide." O povo reza diante do altar ao entardecer, e as preces sobem em 3 intensidades. |
| `destaque_2_chuva.png` | 960 × 320 | "A chuva do deus na seca." Céu de seca, roças secas e a nuvem carregada despejando a chuva. |
| `destaque_3_vila.png` | 960 × 320 | "Da cabana ao moinho." A vila do estágio 6: casas de tijolo, templo de cúpula, roça irrigada e moinho no morro. |
| `destaque_4_cronica.png` | 960 × 320 | "Fica a crônica." O mundo vazio ao entardecer, com ruínas tomadas pelo mato e árvores jovens, e a estante com os livros das eras. |
| `momento_1_entardecer.png` | 1440 × 480 | **versão 0.1:** o entardecer com a roda em volta do fogo, na vila do estágio 3 (semente 3, ano 90, 18h) |
| `momento_2_cacada.png` | 1440 × 480 | a caçada: a lança no ar sobre o porco, com os caçadores agachados (semente 3, dia 13, 16h40) |
| `momento_3_vila_estagio6.png` | 1440 × 480 | a vila do estágio 6 ao entardecer: casas de tijolo em camadas, cúpula, moinho, torres e barcos (semente 3, ano 200, 18h) |
| `momento_3b_vila_estagio6_noite.png` | 1440 × 480 | a mesma vila de noite, com as janelas acesas |
| `momento_4_livro.png` | 1440 × 534 | o livro da estante: índice, título com epíteto e "Em resumo" (com a alça do jogo) |
| `momento_5_dica_pessoa.png` | 1440 × 480 | a dica da pessoa com o humor e o pensamento: "Loa, 25 anos — esperançosa / Cavando raízes perto do fogo / 'O bebê não para de chutar'" |
| `momento_6_recomeco.png` | 1440 × 480 | o recomeço: o povo novo em volta da primeira fogueira, ao amanhecer, entre as ruínas tomadas pelo mato |
| `dia_em_50x.gif` | 1440 × 480, 110 quadros, 15 s, 4,1 MB | um dia inteiro em 50x na vila do estágio 6, do amanhecer à madrugada, em laço (um quadro a cada 0,5 s de jogo, mostrado a 136 ms) |

**A fonte de título** é a fonte 5 × 7 do jogo ampliada em blocos inteiros (2x no logo pequeno, 3x no grande), com degradê dourado-alaranjado, contorno escuro e sombra. As frases dos destaques usam a mesma fonte em 1x, sobre a caixa escura da dica do cursor.

**Montagem:**
- A capa foi composta em 640 × 320 e ampliada 2x por vizinho mais próximo.
- Cada destaque é um recorte de 240 × 80 de uma cena de 480 × 160, ampliado 4x. Assim, as pessoas e as frases ficam grandes na prévia.
- Tudo segue em escala inteira, sem suavização.

**Capturas do jogo:** os momentos e o GIF são capturados pelo código-fonte, com `--sem-config` e `--mundo-novo` (a pasta de dados do usuário não é tocada), e ampliados 3x por vizinho mais próximo, como a janela do jogo na escala 3. A janela vai para o segundo monitor (`--pos=2700,200`): com a tela bloqueada, o cursor parado sobre a janela abria dicas sozinho. O recomeço usa a entrada injetada da auditoria 8. Todas as imagens e o GIF usam só a paleta.

O nome "Simulador de vida" é provisório. Para trocar, mude o texto em `divulgacao.py` (as funções `logo` e `capa`) e rode de novo.

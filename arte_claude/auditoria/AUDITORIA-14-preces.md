# Auditoria 14: a caixa de preces e o termômetro de fé (leitura em 1x e 2x)

**O que foi olhado:** as peças novas, montadas sobre um quadro real da tarde em 1x (`capturas13/02_tarde_vila_1x.png`) por `folha14.py`.
- A tela da caixa de preces ainda não existe no jogo. Por isso, a caixa aberta e a dica da vila são **maquetes**, feitas com as peças, a fonte e as caixas de verdade, e não capturas do jogo.
- A auditoria deve ser refeita no jogo quando a B ligar a caixa.

| Arquivo em `capturas14/` | O que mostra |
|---|---|
| `maquete_1x.png` e `maquete_2x.png` | a cena inteira: a alça com som, lupa e caixa de preces nova; a caixa aberta com três povos; a dica da vila |
| `recorte_alca_1x_8.png` | a ponta direita da alça, ampliada 8 vezes |
| `recorte_caixa_1x_4.png` | os três termômetros no pergaminho, ampliados 4 vezes |
| `recorte_dica_1x_6.png` | o termômetro na dica escura, ampliado 6 vezes |

## O botão da caixa de preces

**Lê, em 1x e em 2x.** O desenho é uma urna de madeira, com um papel de pedido entrando pela fenda e duas faíscas amarelas subindo à esquerda: os pedidos chegando ao céu.
- Ao lado da lupa e do som, o botão tem o mesmo peso e o mesmo creme com sombra cinza. A madeira marrom é a única cor própria, como a estante.
- O ponto de prece nova (2 × 2, vermelho, no canto de cima) aparece em 1x sem gritar. É o mesmo vermelho do X do som mudo.

**A primeira versão foi descartada.** A faísca ficava em cima do papel e formava uma cruz, e o conjunto lia como lápide. As faíscas foram para o lado.

**Em 8 × 8:** a urna e o papel cabem, mas sem as faíscas. O ponto encosta na sombra do papel. Serve para a alça pequena, mas não sobre o pergaminho, onde o creme some (como os outros ícones de 8).

## O termômetro de fé

**Lê, em 1x e em 2x, nos dois fundos.** No pergaminho, o contorno escuro desenha o tubo; na dica escura, o vidro claro desenha o tubo. Nos dois, a ponta colorida diz a temperatura.
- Na maquete, com Ardem a 0,85, Vau a 0,45 e Pedra Alta a 0,12, os três se distinguem de longe: a ponta vermelha, a coluna verde-água e só o bulbo azul.

**A primeira versão foi descartada.** Ela tinha 5 × 14, um canal de 1 px e o vidro cinza.
- O azul escuro do frio sumia no cinza, e Ardem e Vau ficaram quase iguais em 2x.
- O tubo passou para 6 × 14, com um canal de 2 px e o vidro claro. O degradê tirou o pêssego e o amarelo, que pareciam arco-íris e sumiam no vidro claro: agora vai do azul ao verde-água, ao laranja e ao vermelho.

**O recorte (para a B):** mostre as linhas de `topo = 9 - round(fé × 8)` até 13.
- O bulbo fica sempre cheio, então fé zero é "frio", e não "vazio" nem "quebrado".
- Se o recorte começasse do fundo da imagem, a fé baixa mostraria só um pedaço do bulbo, que lê como defeito.

**As setas** são triângulos de 5 × 3 dentro de 5 × 5: laranja para cima e azul para baixo. Em 1x são pequenas, mas a cor e a direção bastam; ficam à direita do tubo, perto do topo. A primeira tentativa, com flecha de haste fina, lia como cruz; a com a haste grossa, como casinha.

## Nota

**4 de 5.** Tudo lê em 1x e 2x, nos dois fundos, sem número.
- Falta a prova no jogo de verdade: a caixa aberta, o ponto aceso depois de uma prece real e o termômetro sobre a vila ao passar o cursor.
- Em 1x, a seta de 5 px é o elemento mais fraco. Se a B achar que some, a saída é pôr a tendência no texto da dica, e não aumentar a seta.

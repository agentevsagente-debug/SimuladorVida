# Auditoria 14: a caixa de preces e o termômetro de fé (leitura em 1x e 2x)

## Refeita no jogo (main d97faef, com as peças ligadas pela B em 67c6957)

**Nota: 5 de 5, com a seta de subir corrigida.** Tudo lê no jogo, de dia e de noite:
- o botão com e sem o ponto;
- a caixa aberta com os termômetros dos povos;
- a dica da vila com o termômetro.

**Como foi feita:** `capturar14.sh`, sem mouse e sem tocar na pasta de dados do jogador. O APPDATA vai para uma pasta temporária e a janela fica no segundo monitor, sem foco.
- O mundo é `--mundo-novo --semente=7 --anos=3 --congelar`, às 12h (`dia`) e às 22h (`noite`).
- `--preces-falsas` enche a caixa, `--abrir=preces` a abre e `--dica=X,Y` põe o cursor sobre a vila.
- **O botão sem ponto** precisou de duas aberturas na mesma pasta temporária: a primeira lê a caixa (fica no moldura.cfg), e a segunda, no mesmo mundo congelado, não tem prece nova. Num mundo de 3 anos já há preces de verdade, então sem isso o ponto aparece sempre.
- **As capturas** saem com 480 × 178, o 1x de pixel. A janela tem escala mínima 2 e o Godot amplia sem filtro, então o 2x da tela é exatamente a captura ampliada 2 vezes (`folha_2x.png`).

| Arquivo em `capturas14/jogo/` | O que mostra |
|---|---|
| `folha_1x.png` e `folha_2x.png` | dia à esquerda e noite à direita. Por linha: o botão com ponto, o botão sem ponto, a caixa aberta e a dica da vila, já com a seta nova. |
| `botao_com_e_sem_ponto_8x.png` | a ponta da alça (som, lupa, caixa), ampliada 8 vezes: com ponto e sem ponto, de dia e de noite |
| `caixa_cabecalho_6x.png` | o cabeçalho da caixa (Toan esquentando, Ourem esfriando), de dia e de noite, com a seta antiga |
| `seta_antes_depois_6x.png` | a seta de subir antes (laranja, à esquerda) e depois (vermelha, à direita), na caixa e na dica, de dia e de noite |
| `*_1x.png` | cada captura; as `_seta` são com a peça nova |

### O botão
- **Lê.** A urna com o papel e as faíscas tem o mesmo peso do som e da lupa, de dia e de noite, porque a alça é a mesma.
- **O ponto vermelho é discreto e inequívoco.** Com e sem ponto, a diferença salta à vista em 1x, sem gritar.

### A caixa aberta
- **Os termômetros leem no cabeçalho do pergaminho.** Ao lado do nome do povo, o de Toan mostra a ponta vermelha e laranja (fé alta) e o de Ourem só o bulbo e um pouco de verde-água (fé baixa). A diferença se vê de longe.
- **De noite, a caixa é a mesma**, porque o pergaminho não escurece.
- O pontinho colorido de cada estado (esperando, atendida, "não por você") é da B e lê.

### A dica da vila
- **O termômetro lê na dica escura.** O vidro claro desenha o tubo e o contorno escuro some no fundo, como planejado.
- **De noite, a 230 px, a dica pega a tenda ("Dormem aqui: Lou e Rao"), sem termômetro.** A 215 px, pega a vila.
- **Não é defeito de arte. Fica para a B decidir:** à noite, quase todo o acampamento é tenda com gente dormindo, e o termômetro só aparece na beirada.

### A seta: estava fraca e foi corrigida
- **O problema:** o laranja (21) sobre o pergaminho tem contraste de luminância de só 1,3:1. Na caixa aberta, a seta de subir lia pela cor, mas não pela forma: um borrão alaranjado. A de descer, azul (18), tem 2,3:1 no pergaminho e 3,4:1 na dica, e lia bem.
- **A correção:** a seta de subir agora é vermelha (20), com a ponta laranja, e tem 2,4:1 no pergaminho e 3,2:1 na dica. No pergaminho, o triângulo ganhou contorno. Na dica escura, perdeu um pouco do brilho do laranja (que tinha 5,9:1), mas continua claro.
- **Por que não aumentei a seta:** um triângulo maior que 5 × 3 brigaria com o nome do povo ao lado. Ela continua a mesma peça, `termometro_fe_sobe.png`, com o mesmo tamanho e a mesma posição: a B só precisa sincronizar.

## A primeira versão, sobre maquete (antes de a caixa existir no jogo)

**O que foi olhado:** as peças novas, montadas sobre um quadro real da tarde em 1x (`capturas13/02_tarde_vila_1x.png`) por `folha14.py`.
- A tela da caixa de preces ainda não existe no jogo. Por isso, a caixa aberta e a dica da vila são **maquetes**, feitas com as peças, a fonte e as caixas de verdade, e não capturas do jogo.
- A auditoria deve ser refeita no jogo quando a B ligar a caixa.

| Arquivo em `capturas14/` | O que mostra |
|---|---|
| `maquete_1x.png` e `maquete_2x.png` | a cena inteira: a alça com som, lupa e caixa de preces nova; a caixa aberta com três povos; a dica da vila |
| `recorte_alca_1x_8.png` | a ponta direita da alça, ampliada 8 vezes |
| `recorte_caixa_1x_4.png` | os três termômetros no pergaminho, ampliados 4 vezes |
| `recorte_dica_1x_6.png` | o termômetro na dica escura, ampliado 6 vezes |

### O botão da caixa de preces

**Lê, em 1x e em 2x.** O desenho é uma urna de madeira, com um papel de pedido entrando pela fenda e duas faíscas amarelas subindo à esquerda: os pedidos chegando ao céu.
- Ao lado da lupa e do som, o botão tem o mesmo peso e o mesmo creme com sombra cinza. A madeira marrom é a única cor própria, como a estante.
- O ponto de prece nova (2 × 2, vermelho, no canto de cima) aparece em 1x sem gritar. É o mesmo vermelho do X do som mudo.

**A primeira versão foi descartada.** A faísca ficava em cima do papel e formava uma cruz, e o conjunto lia como lápide. As faíscas foram para o lado.

**Em 8 × 8:** a urna e o papel cabem, mas sem as faíscas. O ponto encosta na sombra do papel. Serve para a alça pequena, mas não sobre o pergaminho, onde o creme some (como os outros ícones de 8).

### O termômetro de fé

**Lê, em 1x e em 2x, nos dois fundos.** No pergaminho, o contorno escuro desenha o tubo; na dica escura, o vidro claro desenha o tubo. Nos dois, a ponta colorida diz a temperatura.
- Na maquete, com Ardem a 0,85, Vau a 0,45 e Pedra Alta a 0,12, os três se distinguem de longe: a ponta vermelha, a coluna verde-água e só o bulbo azul.

**A primeira versão foi descartada.** Ela tinha 5 × 14, um canal de 1 px e o vidro cinza.
- O azul escuro do frio sumia no cinza, e Ardem e Vau ficaram quase iguais em 2x.
- O tubo passou para 6 × 14, com um canal de 2 px e o vidro claro. O degradê tirou o pêssego e o amarelo, que pareciam arco-íris e sumiam no vidro claro: agora vai do azul ao verde-água, ao laranja e ao vermelho.

**O recorte (para a B):** mostre as linhas de `topo = 9 - round(fé × 8)` até 13.
- O bulbo fica sempre cheio, então fé zero é "frio", e não "vazio" nem "quebrado".
- Se o recorte começasse do fundo da imagem, a fé baixa mostraria só um pedaço do bulbo, que lê como defeito.

**As setas** são triângulos de 5 × 3 dentro de 5 × 5: laranja para cima e azul para baixo. Em 1x são pequenas, mas a cor e a direção bastam; ficam à direita do tubo, perto do topo. A primeira tentativa, com flecha de haste fina, lia como cruz; a com a haste grossa, como casinha.

### Nota da maquete

**4 de 5.** Tudo lê em 1x e 2x, nos dois fundos, sem número.
- Falta a prova no jogo de verdade: a caixa aberta, o ponto aceso depois de uma prece real e o termômetro sobre a vila ao passar o cursor.
- Em 1x, a seta de 5 px é o elemento mais fraco. Se a B achar que some, a saída é pôr a tendência no texto da dica, e não aumentar a seta.

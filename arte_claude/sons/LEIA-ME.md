# Os sons do jogo (versão 0.2)

Os sons são todos gerados por código, como a arte: síntese em Python (numpy, scipy e soundfile) com ruído filtrado, osciladores, envelopes e um eco curto. Não há amostras baixadas nem dependência no jogo.

O estilo é discreto, quente e levemente retrô, como uma janela aberta para o campo:
- os agudos são abafados e não há estalos secos;
- tudo é mono, a 22 050 Hz;
- tudo é gravado em Ogg Vorbis.

> **Ninguém ouviu estes sons ainda.** Foram conferidos só por espectrograma e por medidas de volume.
> - Primeiro, ouça as vozes por formantes (`vila`, `choro_bebe`, `galo` e `grito_cacada`), que podem soar zumbidas ou estranhas.
> - Depois, ouça os `passaros`.

**Tamanho:** os 29 sons somam **1,77 MB**. Com a prévia, a pasta tem 2,2 MB. A meta era ficar abaixo de 8 MB.

## Como gerar

```
python gerar_sons.py   # grava ambiente/ e eventos/ e imprime a tabela de medidas
python previa.py       # monta a prévia de 60 s a partir dos .ogg gerados
```

| Arquivo | O que faz |
|---|---|
| `sintese.py` | As ferramentas: ruído, filtros, envelopes, sino, voz sem palavras, eco, nivelamento e gravação. |
| `ambiente.py` | Os laços de ambiente. |
| `eventos.py` | Os sons curtos de acontecimento. |
| `previa.py` | A prévia `previa_um_dia_60s.ogg`. |

Tudo sai igual a cada geração, porque as sementes são fixas.

**Os laços não têm emenda.** São feitos periódicos no comprimento exato do laço:
- o ruído é gerado pela FFT inversa de um espectro moldado;
- as modulações têm um número inteiro de ciclos no laço;
- um evento que passa do fim continua no começo;
- o eco é uma convolução circular.

O `.ogg` decodificado tem exatamente o mesmo número de amostras. Ponha `loop = true` na importação do Godot, sem ponto de laço.

> **Nota técnica:** no Windows, o libsndfile fecha o Python sem aviso se receber o arquivo de uma vez só. Por isso, `gravar()` escreve em blocos de 2048 amostras.

## O volume

Todos os sons foram nivelados juntos, para tocarem **com o mesmo volume no jogo** (0 dB em cada `AudioStreamPlayer`). O equilíbrio já está nos arquivos:
- **Ambiente:** RMS de -25 a -34 dBFS. A tempestade é a mais forte e a neve, a mais baixa.
- **Acontecimentos:** de -24 a -33 dBFS, medidos no trecho que soa. O clique da alça fica em -37 dBFS.
- **Pico:** nenhum som passa de -7 dBFS.
- **O trovão** fica longe, com ataque de 80 a 200 ms e sem estalo agudo. Os trovões ficam com pico de -9 dBFS. Medido sobre um dia claro (o vento e os pássaros), o trovão sobe só 9 a 10 dB acima do fundo (no máximo em 400 ms), para não assustar quando o raio cai num dia sem tempestade.

O nivelamento nunca distorce: quando o pico passaria do teto, o som fica um pouco mais baixo que o RMS pedido. É o caso dos trovões, do terremoto e do dilúvio.

**Volume geral sugerido (o barramento Master): começar em -10 dB.** O documento pede que o volume comece baixo. A coluna "volume" das tabelas abaixo é um ajuste opcional, em dB, sobre o 0 dB de cada um.

## Laços de ambiente (`ambiente/`)

**Todos tocam em laço.** Conferi os `.ogg` decodificados: o número de amostras é exato e a emenda não tem degrau.

| Nome | Duração | Volume | Quando toca |
|---|---|---|---|
| `vento.ogg` | 32 s | 0 | Sempre, de dia e à noite, por baixo de tudo. Use -6 dB à noite e no inverno. |
| `passaros.ogg` | 36 s | 0 | Do amanhecer (5h) até as 17h, mais forte entre 5h e 9h. Para a manhã, use +2 dB. Não toca com chuva, tempestade ou neve. |
| `lago.ogg` | 30 s | 0 | Quando a vista tem água (o lago ou a praia), de dia e à noite. Use -4 dB à noite. |
| `grilos.ogg` | 30 s | 0 | Das 19h às 5h, menos no inverno e na chuva. |
| `fogo.ogg` | 28 s | 0 | Perto de fogueiras acesas, sobretudo ao entardecer e à noite. Use -3 dB de dia. |
| `chuva.ogg` | 30 s | 0 | Na chuva (o clima e o poder da chuva). Entra e sai em 3 s. |
| `tempestade.ogg` | 36 s | 0 | Na tempestade, no lugar da chuva, com o trovão por cima. Tem vento forte em rajadas e um rumor grave. |
| `neve.ogg` | 30 s | 0 | Quando neva, no lugar do vento e dos pássaros. É quase silêncio. |
| `vila.ogg` | 36 s | -6 a 0 | Quando há gente acordada, das 6h às 21h. O volume acompanha o tamanho do povo: -6 dB com até 15 pessoas e 0 dB com 60 ou mais (o documento diz que "a vila mais cheia soa mais viva"). São vozes sem palavras ao longe e batidas de trabalho. |

**Entre um laço e outro:** troque com 2 a 4 s de cruzamento.

## Sons curtos de acontecimento (`eventos/`)

**Nenhum é laço:** cada um toca uma vez.

| Nome | Duração | Volume | Quando toca |
|---|---|---|---|
| `trovao_1.ogg` | 7,0 s | 0 | No raio, na tempestade. É médio, com um estalo abafado. |
| `trovao_2.ogg` | 8,5 s | 0 | No raio, longe. É longo e rolando, sem estalo. Também vale na tempestade sem raio, de vez em quando. |
| `trovao_3.ogg` | 5,8 s | 0 | No raio, perto. É mais curto. **Sorteie entre os três**, sem repetir o anterior. |
| `terremoto.ogg` | 5,5 s | 0 | O poder do terremoto. É o ronco grave com o chacoalhar de pedrinhas. Repita em cruzamento se durar mais. |
| `fogo_acender.ogg` | 2,6 s | 0 | Uma fogueira acesa (ao entardecer, no recomeço) e o fogo forte do poder pegando. |
| `fogo_brando.ogg` | 3,2 s | 0 | O fogo brando (o milagre do fogo que não queima): um sopro morno. |
| `diluvio.ogg` | 6,6 s | 0 | O começo do dilúvio. Depois, segue com `chuva` ou `tempestade`. |
| `fartura.ogg` | 3,4 s | 0 | O brilho da fartura: sininhos que sobem. |
| `sonho.ogg` | 4,9 s | 0 | O sonho: um tom suave. |
| `milagre_sino.ogg` | 5,2 s | 0 | Um sino leve quando um poder é lido como milagre (o grau 2). |
| `pressagio.ogg` | 6,0 s | 0 | O presságio: um tom grave e escuro. |
| `cura.ogg` | 3,8 s | 0 | A cura: duas notas que sobem. |
| `arremesso.ogg` | 1,0 s | 0 | A lança saindo da mão (o ensinar e a caçada). Com o eco, o zunido dura 0,45 s. |
| `lanca_cravar.ogg` | 1,1 s | 0 | A lança cravando no alvo de capim ou na caça. Toque no quadro em que ela crava. |
| `grito_cacada.ogg` | 2,0 s | 0 | Na caçada, quando o bicho cai, ou quando os caçadores voltam. É um "ê-ô!" sem palavras. |
| `choro_bebe.ogg` | 4,2 s | 0 | Um nascimento: um choro abafado, ao longe. |
| `coruja.ogg` | 3,2 s | 0 | À noite, de vez em quando (a cada 1 a 3 min de tempo real), junto com a coruja da arte. |
| `galo.ogg` | 2,7 s | 0 | Ao amanhecer (5h a 6h), uma ou duas vezes, nos povos do estágio 2 em diante. |
| `sino_templo.ogg` | 8,5 s | 0 | O sino do templo, nos estágios 3 a 6: ao amanhecer, ao meio-dia e nas festas. É uma batida só; para três, toque com 2,5 s entre elas. |
| `clique_alca.ogg` | 0,1 s | 0 | O clique dos botões da alça, bem baixo. Não toca no botão de som. |

## A prévia

`previa_um_dia_60s.ogg` (60 s, 326 KB) mostra um dia passando:

| Trecho | O que toca |
|---|---|
| 0 a 12 s, o amanhecer | o vento, o galo e os pássaros entrando |
| 12 a 26 s, o dia | o lago, a vila, o sino do templo, o arremesso com a lança cravando, o grito da caçada e o brilho da fartura |
| 26 a 41 s, a chuva | a chuva e a tempestade, com dois trovões |
| 38 a 48 s, o entardecer | o fogo, a vila mais baixa, o choro de bebê e o sino do milagre |
| 46 a 60 s, a noite | os grilos, o fogo e a coruja duas vezes |

## O que ainda não tem som

- A neve e o terremoto foram feitos, mas não estão na prévia.
- Os passos, os bichos (porco, cervo, garça) e o mar da praia ficam para depois, se pedidos.
- O botão de som e a tecla M são do código (B).

# Revisão de arte dos primeiros 5 minutos (versão 0.1)

*Sessão C (arte), 01/11/2026. Feita sobre a main em `8699d5c`. É o que um amigo vê ao abrir o jogo: o ícone, a alça, a caixa de carga, as dicas e a estante. A entrada foi injetada, porque a sessão do Windows seguia bloqueada. Os recortes estão em `recortes_5min/`.*

## O ícone do .exe

`recortes_5min/icone_16_24_32_48.png`, sobre um fundo claro e um escuro.

- **O que estava errado:**
  - O .ico tinha 16, 32, 48, 64, 128 e 256, **sem o 24**. Na escala de 150% (a desta máquina, dpi 144), o Windows usa o 24 na bandeja e nos ícones pequenos e o 48 na barra de tarefas. Sem o 24, ele reduz o 32 ou amplia o 16, e o ícone borra.
  - O 48 era o 16 ampliado 3x: grosso e com menos desenho que o 32.
- **Corrigido (C):** o 24 e o 48 agora são desenhados no tamanho final, com o mesmo desenho do 32 (`interface/icone_jogo_24.png` e `icone_jogo_48.png`). O .ico passou a ter **16, 24, 32, 48, 64, 128 e 256**, cada tamanho do seu desenho, sem reamostrar. Conferi tamanho a tamanho que nenhum veio suavizado.
- **No fundo escuro,** o contorno mais escuro da moldura some, mas a borda de madeira e o céu claro seguram o desenho. No claro, lê bem em todos os tamanhos.

## A alça e os poderes

`botoes_da_alca.png` e `os_11_poderes.png`

- **Os 10 botões e os 11 poderes** se distinguem, e o realce do botão sob o cursor se vê.
- **Corrigido (C), o ícone do terremoto:** o chão rachado com as duas metades no mesmo nível lia como duas caixas marrons. Agora a metade direita sobe 1 px, a racha é dentada, e há o tremor dos lados em claro e as pedrinhas pulando. Vale nos ícones de 12 e de 8.

## A caixa de carga

`caixa_de_carga.png`

Ela é clara e cabe no gesto:
- o ícone do poder, a barra e o grau embaixo ("brando", "sinal" e "milagre");
- a marca da metade e a do fim do fogo brando.

Nada a corrigir.

## As dicas e a frase da estante

`estante_e_relogio.png` e `caixa_de_carga.png`

- **A dica da pessoa** traz o humor e o pensamento em lilás. A do poder diz "Segure mais para um milagre".
- **A frase da estante** fica no alto, na caixa da dica, sem cobrir os livros: "Aqui ficam as crônicas dos mundos que você deixar".
- **A versão** ("Simulador de vida 0.1.0") aparece no canto da estante e na dica do relógio, como pedido no B3.

## Para a B

| # | Item |
|---|---|
| 1 | **Copiar e exportar de novo:** o .ico novo (`interface/icone_jogo.ico`, com o 24), o ícone novo do terremoto (`icones_12/terremoto.png` e `icones_8/terremoto.png`) e o atlas `comum` regenerado. |
| 2 | **O ícone da bandeja** (`StatusIndicator`) usa o `icone_jogo_16.png`. Na escala de 150%, o Windows o amplia para 24 e ele fica grosso. Sugestão: escolher pela escala da tela (`icone_jogo_16` em 100%, `icone_jogo_24` em 150% e `icone_jogo_32` em 200%). |
| 3 | **Para conferir no B1, com a tela desbloqueada:** o ícone de verdade na barra de tarefas e na bandeja, nos temas claro e escuro do Windows. |
| 4 | **A frase da estante,** se quiserem: "dos mundos que você deixar" pode soar como "permitir". "Aqui ficam as crônicas dos mundos que você deixou para trás" é mais claro, mas só faz sentido depois do primeiro abandono. Na primeira vez, "Aqui vão ficar as crônicas dos mundos que você deixar para trás". |

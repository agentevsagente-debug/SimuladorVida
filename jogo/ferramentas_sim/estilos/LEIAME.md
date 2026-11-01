# Estilos de jogador

`ferramentas_sim/estilos.gd` simula 4 deuses por 100 anos, em 3 sementes cada, e compara os povos. A tabela está em `tabela.md`, e um trecho de crônica de cada estilo (anos 41 a 60 da semente 1) em `benevolente.md`, `cruel.md`, `ausente.md` e `caprichoso.md`.

## Os estilos

- **Benevolente:** atende toda prece aberta com o poder que ela pede (chuva na seca, fartura na fome, cura na doença, sonho na guerra).
- **Cruel:** raios uma vez por mês de jogo. Um em cada quatro acerta alguém, e os outros são sinais fracos, que assustam sem matar. Há também seca forte uma vez a cada 4 anos e fogo de vez em quando.
- **Ausente:** nunca intervém.
- **Caprichoso:** intervém ao acaso, uma vez a cada 25 dias em média, com qualquer poder, em qualquer lugar e com qualquer força.

Todos começam a agir no ano 5. Antes disso, a família inicial (12 pessoas) não aguenta nenhum estilo forte. Na primeira versão do teste, com raios todo dia, o cruel acabou com os 3 mundos em poucos anos, e o caprichoso com 2 de 3: o que se media era a extinção, não o estilo. O cruel só mata com 25 pessoas ou mais no mundo.

## O que sai de cada um (média de 3 sementes, no ano 100)

| | Benevolente | Cruel | Ausente | Caprichoso |
|---|---|---|---|---|
| População | 461 | 34 | 68 | 103 |
| Fé média (-1 a 1) | 0,65 | -1,00 | 0,06 | 0,58 |
| Povos dependentes, ao longo do tempo | 4 | 0 | 0 | 0 |
| Povos que passaram a exigir | 4 | 0 | 0 | 0 |
| Estoque por pessoa | 67 | 102 | 50 | 25 |
| Vezes que o deus mudou de nome | 15 | 6 | 3 | 10 |
| Costumes vivos | 7 | 1,7 | 4,3 | 10,7 |
| Secularizações | 0 | 0 | 0,7 | 0 |
| Mortos pelo deus | 0 | 25 | 0 | 2 |

- **Benevolente:** povos grandes (chegam ao limite da terra), devotos, dependentes e depois exigentes ("as preces ficaram pequenas: pedia-se até sol para a pesca"). O deus ganha nomes de quem dá: o Que Dá, o Generoso, a Mãe da Fartura, a Mão Que Cura.
- **Cruel:** povos pequenos, de fé hostil (-1: odeiam o deus em quem acreditam), que fazem oferendas para aplacá-lo e guardam comida como ninguém. Os nomes são de medo: o Senhor do Trovão, o Que Fere, a Terra Brava. Há guerra santa.
- **Ausente:** o deus é esquecido. A fé esfria até perto de zero, há secularização e poucos nomes. Ninguém fica dependente.
- **Caprichoso:** povos supersticiosos, com o maior número de costumes (tabus, oferendas, festas) e de nomes para o deus. A fé é alta, mas instável.

## O que foi ajustado para os estilos se separarem

Na primeira medição, o benevolente e o ausente davam povos parecidos (fé 0,65 e 0,72; nenhum povo dependente). O motivo era que o acaso respondia às preces quase tanto quanto o deus: 80 preces "atendidas" em 100 anos, sem deus nenhum. Mudou:

- **O acaso convence menos que o deus.** Uma prece que se cumpre sozinha sobe a fé de todos em 0,08 (antes, 0,15, o mesmo que um milagre de verdade), alivia menos o silêncio e não conta para a dependência. Só um deus que responde de verdade cria povos dependentes.
- **Um deus que nunca aparece é esquecido.** Depois de 15 anos sem nenhum gesto do deus, a fé de quem não é devoto esfria 3% ao ano, e o povo pode se secularizar a partir do estágio 3 (antes, só no 5).
- **Um deus que mata é aplacado.** Um raio do deus que mata, lido como castigo, cria o costume das oferendas.
- **A terra tem limite.** Acima de 320 pessoas no mundo, nascem cada vez menos crianças. Sem isso, o benevolente chegava a 2.121 pessoas em 100 anos. Os mundos sem deus quase nunca passam de 300.

## O que ainda vale olhar

- Os "silêncios sentidos" ficaram em zero nos 4 estilos. O deus ausente tem poucas preces sem resposta, porque o acaso resolve muitas, e as preces atendidas apagam o silêncio.
- A fé do cruel bate em -1,00 nos 3 mundos: medo e ódio se somam até o limite. Um povo que crê e só odeia talvez precise de um meio-termo (temor, fé positiva com medo).
- O mundo sem deus é o jogo padrão. A população no ano 100 das sementes 1 a 5 foi de 146, 7, 165, 205 e 100 para 146, 2, 55, 160 e 195 (total de 623 para 558). Dentro da variação, mas mais baixa.

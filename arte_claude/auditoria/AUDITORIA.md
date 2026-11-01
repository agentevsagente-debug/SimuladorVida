# Auditoria visual do jogo rodando

*Sessão C (arte), 01/11/2026, sobre a main em `237d6fe`. A referência é a cena-alvo (`arte_claude/alvo/`) e as peças de `arte_claude/pecas/`.*

## Como foi feito

O jogo rodou com o Godot 4.7.2, pelos argumentos de captura da sessão B: `--capturar`, `--hora`, `--dias`, `--anos`, `--demo` e `--efeito`. Os comandos estão em `capturar.sh`, e as 41 capturas, em `capturas/`.

| Grupo | Capturas |
|---|---|
| Estações (meio-dia, semente 7) | `est_primavera`, `est_verao`, `est_outono`, `est_inverno` (dias 2, 12, 22 e 32) |
| Horários (verão) | `hora_manha` (7h), `est_verao` (12h), `hora_tarde` (18h), `hora_noite` (22h); também `hora_noite_inverno` |
| Mundos | início: `est_verao` (ano 0); avançados: `mundo_avancado` (semente 7, 60 anos), `mundo_avancado2` (semente 3, 150 anos), `mundo_avancado_tudo` (com a alça) |
| Poderes | `poder_<chuva, raio, fogo, fartura, erguer_terra, sonho>_00` a `_03`: 4 quadros a cada 0,4 s depois do gesto, com intensidade máxima; `efeito_chuva` e `efeito_raio_00` a `_03` |

**Verificações automáticas.** Nenhuma das 41 capturas tem **cor fora da paleta** ou **pixel semitransparente**. Todas têm exatamente 480 × 160 (480 × 178 com a alça). Os pixels são nítidos, sem borrado nem escala fracionária.

**Limites desta auditoria:**
- Só 6 dos 11 poderes estão no jogo (veja o defeito 9). Seca, dilúvio, terremoto, presságio e cura não puderam ser vistos.
- O raio não apareceu em nenhum quadro capturado (veja o defeito 12).
- A neve caindo só aparece quando neva, e isso depende do clima da simulação. Não foi verificada.

**Para rodar de novo:** a primeira execução num checkout novo precisa importar os recursos uma vez (`Godot --headless --path jogo --import`). Sem isso, as texturas vêm nulas e a captura sai vazia. A importação cria `.uid` dos scripts do núcleo e mexe nos `.import` da arte; desfiz tudo depois, e nada fora de `arte_claude/` foi alterado.

## Defeitos, do mais grave ao mais leve

Cada defeito tem um recorte ampliado em 4x em `recortes/`.

### 1. Mundo avançado sem nenhuma construção (grave)
`recortes/01_mundo_avancado_sem_construcoes.png` (60 anos) e `capturas/mundo_avancado2.png` (150 anos)

- **O que está errado:** com 60 e 150 anos, o mundo tem dezenas de pessoas e nenhuma casa, celeiro, roça cercada, templo, forja, biblioteca, muralha ou moinho. Só aparecem as 2 cabanas, a fogueira e a vegetação. No código da vista (`vista.gd`), as únicas construções desenhadas são `cabana_galhos`, `altar` e as fases da `roca`. As peças dos estágios 2 a 6, as variações de cultura e as ruínas não são usadas.
- **O que deveria ser:** a vila do estágio em que o povo está, como nas cenas `arte_claude/pecas/cenas/cena_estagio2.png` a `cena_estagio6.png`, com o telhado, a parede e o símbolo da cultura de cada povo.
- **Quem corrige:** **B** (desenhar as construções de `sim.construcoes` por tipo e estágio, usando os atlas `estagioN`). **A** confirma se a API informa o tipo, o estágio e a cultura de cada construção.

### 2. Pessoas em pé sobre o lago (grave)
`recortes/02_pessoas_sobre_a_agua.png` (150 anos)

- **O que está errado:** uma fila de pessoas anda e fica parada sobre a superfície da água, de x = 0 a x = 100, na linha d'água. Elas flutuam sobre o lago.
- **O que deveria ser:** ninguém em x de água, a não ser num barco (`estagio6/barco_2q` + `acoes/remar_4q`). Quem pesca fica na margem (`acoes/pescar_4q`).
- **Quem corrige:** **B** (limitar o x de quem anda à terra e apoiar os pés na superfície da coluna) e **A** (as faixas de posição da rotina não devem cair na água).

### 3. Multidão numa fila só, uns por cima dos outros (grave)
`recortes/03_multidao_em_fila.png`

- **O que está errado:** com muita gente, as pessoas viram uma faixa contínua de corpos sobrepostos na mesma linha, de uma ponta à outra do mundo. Não dá para distinguir ninguém, e as pessoas deixam de ser o elemento mais legível, que era o critério da cena-alvo.
- **O que deveria ser:** no máximo uma pessoa a cada 6 a 8 px na mesma linha. Com mais gente, algumas ficam dentro de casa, na roça ou fora da vista. Quem fica atrás pode subir 1 ou 2 px, para dar profundidade, mas nunca cobrir a cabeça de quem está na frente.
- **Quem corrige:** **B** (distribuição e ordem de desenho) e **A** (onde a rotina põe cada pessoa).

### 4. Acampamento inicial amontoado (alto)
`recortes/04_acampamento_amontoado.png`: em cima a cena-alvo, embaixo o jogo

- **O que está errado:** os 8 habitantes do início ficam espremidos em uns 40 px, cobrindo a fogueira e as duas cabanas. Na cena-alvo, eles se espalham em roda, com espaço entre si e a fogueira visível.
- **O que deveria ser:** o arranjo da cena-alvo, com 6 a 10 px entre as pessoas e ninguém sobre a fogueira. Quem está à direita do fogo fica espelhado, olhando para ele.
- **Quem corrige:** **B**, com o apoio de **A** nas posições de `fogueira` e `parado`.

### 5. Fumaça vira um círculo de pontos em grade no céu (alto)
`recortes/05_fumaca_em_grade.png`

- **O que está errado:** os últimos quadros de `efeitos/fumaca_6q` se desfazem num pontilhado regular, que lê como uma grade. Como a fumaça sobe e fica alta, aparece um disco de pontos parado no céu, longe da fogueira. Nos primeiros quadros, ela é uma bola cinza dura.
- **O que deveria ser:** fumaça que se desfaz de forma irregular, sem grade, e some antes de passar da altura das copas.
- **Quem corrige:** **C** (redesenhar o sumiço da `fumaca_6q`) e **B** (limitar a subida e a duração de cada baforada).

### 6. Chuva: três nuvens iguais lado a lado e céu de sol (alto)
`recortes/06_chuva_nuvens_repetidas.png`

- **O que está errado:** a chuva e o raio põem três cópias idênticas da `nuvem_chuva_2q`, alinhadas em fila e no mesmo quadro, o que forma um padrão repetido. Enquanto isso, o céu continua com sol forte e o mesmo azul.
- **O que deveria ser:** nuvens com espaçamento e altura irregulares, alternando os 2 quadros, algumas espelhadas, e o céu escurecendo durante a chuva. Isso já estava previsto como efeito do motor ("o escurecer da tempestade").
- **Quem corrige:** **B**.

### 7. Mata distante no inverno com listras verticais regulares (médio)
`recortes/07_mata_inverno_listrada.png`

- **O que está errado:** as separações entre copas a cada 9 px, junto com o pontilhado, criam listras verticais regulares que parecem uma cerca.
- **O que deveria ser:** copas nevadas com separações irregulares, como no outono.
- **Quem corrige:** **C** (`estacoes/estacoes.py`, função `mata_sazonal`).

### 8. Montanhas nevadas claras demais à noite (médio)
`recortes/08_montanhas_inverno_noite.png`

- **O que está errado:** à noite, no inverno, a neve das montanhas usa o bege-claro (12) e fica mais clara que tudo na cena, mais do que a lua e a fogueira. Isso quebra a leitura de noite.
- **O que deveria ser:** neve noturna em violeta (5), com o lado da lua um tom acima, mantendo a fogueira como o ponto mais claro.
- **Quem corrige:** **C** (a função `montanha_inverno`, no horário da noite).

### 9. Os 5 poderes da fase 2 não estão no jogo (médio)
Sem recorte: não há o que capturar.

- **O que está errado:** o núcleo tem 11 poderes (`mundo.gd`, `PODERES`), mas a interface só oferece 6 (`interface.gd`, `PODERES`). Seca, dilúvio, terremoto, presságio e cura não têm botão nem gesto, e o `--demo` também não aceita esses nomes. Os efeitos e céus que fiz para eles só aparecem quando o evento é natural, como a seca e o eclipse.
- **O que deveria ser:** os 11 poderes no seletor, usando os ícones e efeitos da fase 2. Os ícones de 12 × 12 desses 5 poderes ainda não existem, e esse pedaço é meu.
- **Quem corrige:** **B** (seletor e gesto) e **C** (ícones dos 5 poderes novos).

### 10. A manhã é igual ao meio-dia (médio)
`recortes/10_manha_igual_meio_dia.png`: em cima 7h, embaixo 12h

- **O que está errado:** às 7h a cena é idêntica à do meio-dia, porque o jogo só tem 3 estados (dia, entardecer e noite). A virada da noite para o dia, ao amanhecer, é um corte seco.
- **O que deveria ser:** um amanhecer, que pode reaproveitar as cores do entardecer com o sol do outro lado, e uma transição pontilhada entre os estados (o shader já troca as tabelas).
- **Quem corrige:** **B**, e **C** se a sessão B quiser um céu de amanhecer próprio.

### 11. Pessoas com roupa de verão no inverno (baixo)
`capturas/est_inverno.png`

- **O que está errado:** no meio da neve, todos continuam de túnica curta e pernas de fora.
- **O que deveria ser:** uma capa ou manta de inverno sobre os mesmos moldes.
- **Quem corrige:** **C** (variação de inverno dos habitantes) e **B** (usar a variação no inverno).

### 12. O raio não aparece nas capturas (baixo, a confirmar)
`capturas/poder_raio_*.png`, `capturas/efeito_raio_*.png`

- **O que está errado:** em 8 quadros, capturados de 0,3 em 0,3 s e de 0,4 em 0,4 s depois do gesto, nenhum mostra o raio nem o clarão. O núcleo confirma o uso (`ok: true, alvo: 2`). Ou o raio dura menos de 0,3 s, ou não está sendo desenhado.
- **O que deveria ser:** o raio inteiro por 2 a 3 quadros (cerca de 0,15 s), depois o canal esfriando (quadro 2 da folha) e o `raio_impacto_4q` no chão.
- **Quem corrige:** **B**, que deve primeiro confirmar se o raio é desenhado.

### 13. Cabanas com contorno laranja forte à noite (baixo)
`recortes/13_cabanas_contorno_laranja.png`

- **O que está errado:** perto da fogueira, a luz quente pinta a borda inteira das cabanas de laranja vivo, e elas parecem contornadas a néon.
- **O que deveria ser:** só o lado voltado para o fogo mais quente, como nas pessoas, e o resto no tom médio.
- **Quem corrige:** **B** (aplicar ao cenário a regra de lado que já vale para as pessoas). Se preferirem, **C** suaviza a tabela `fogo_perto` (a cor 10 iria para 9 em vez de 21).

## O que está bom

- **Cena de verão, de dia:** é praticamente a cena-alvo. Céu, montanhas, mata, terreno em blocos, vegetação, cabanas e fogueira estão no lugar.
- **Estações:** cada uma lê bem: as flores da primavera, o outono laranja com a mata em copas e o inverno com céu pálido, montanhas nevadas, neve no chão e gelo na margem.
- **Entardecer e noite:** batem com a cena-alvo, com a fogueira iluminando as cabanas e o chão.
- **Efeitos dos poderes:** a chama do fogo e as árvores carbonizadas, a fartura com brilhos, a terra subindo com a pedra erguida e o sonho com as partículas lilás estão no estilo.
- **Alça:** os ícones estão nítidos sobre o fundo escuro, como pensado.
- **Técnica:** em todas as capturas, só cores da paleta, sem semitransparência e na escala inteira.

## Resumo por responsável

| Quem | Defeitos |
|---|---|
| B (apresentação) | 1, 2, 3, 4, 6, 9, 10, 12, 13, mais a parte de motor do 5 e do 11 |
| A (simulação) | apoio no 1 (dados das construções), 2 e 3 (posições), 4 |
| C (arte, esta sessão) | 5 (fumaça), 7 (mata no inverno), 8 (montanhas à noite), 9 (ícones dos 5 poderes), 11 (roupa de inverno) |

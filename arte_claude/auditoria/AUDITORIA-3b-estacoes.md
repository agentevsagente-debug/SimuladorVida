# Auditoria visual 3b: as estações

*Sessão C (arte), 01/11/2026. É uma auditoria curta, feita sobre os GIFs que a sessão B gravou com a arte nova, enquanto as encenações da auditoria 3 não chegam. Os GIFs estão no commit `357b511` da branch da B (`claude/fase0-moldura-e4e762`), que ainda não chegou à main.*

## Como foi feito

**Os arquivos:**
- os GIFs `dia-inteiro-50x-inverno.gif`, `dia-inteiro-50x.gif` e `estacao-<estacao>.gif`;
- a captura `luzes-inverno-pomar.png`, que mostra o estágio 6 de dia e de noite, no verão e no inverno.

Extraí todos os quadros: 165 de cada dia em 50x, das 5h20 às 4h10, e 48 de cada estação. O script é `extrair3b.py`. Os quadros ficam fora do git, em `capturas3b/`, e saem do commit da B. Os recortes estão em `recortes3b/`, ampliados 2x sobre a captura, que já está em 2x.

**O que conferi:**
- a neve no chão e nos telhados;
- a fumaça das chaminés;
- as janelas acesas;
- a roda d'água e o pomar;
- a paleta do inverno e do outono.

**Resultado:** dos 6 defeitos, 3 eram de arte e já estão corrigidos (E1 a E3). Os outros 3 são da B (E4 a E6).

| # | Defeito | Gravidade | Quem corrige | Situação |
|---|---|---|---|---|
| E1 | telhados vermelhos no inverno: a neve era só uma borda de 1 px | alto | C | **corrigido** |
| E2 | fumaça das chaminés: um fiapo pontilhado que some no céu claro | médio | C | **corrigido** |
| E3 | montanhas nevadas à noite: um cinza oliva que pesa mais que a cena | médio | C | **corrigido** |
| E4 | baforadas de fumaça que sobem alto demais e ficam inteiras | médio | B | aberto (é o D5 da auditoria 3) |
| E5 | lago sem gelo no inverno | baixo | B | aberto |
| E6 | roça e pomar entre os pinheiros do morro, com gente em pé por cima | baixo | B (e A) | aberto |

## O que está bom

- **A neve não branqueia mais a tela.** O inverno lê como inverno, de dia e de noite:
  - pinheiros nevados;
  - árvores de copa nuas;
  - cabanas com neve;
  - montanhas brancas;
  - céu pálido;
  - gente com capuz;
  - neve caindo.
- **Janelas acesas** (`recortes3b/ok_janelas_acesas.png`): acendem ao anoitecer, e de madrugada só algumas continuam acesas, como pedido. No estágio 6 à noite, a vila inteira tem janelas quentes (`ok_estagio6_noite.png`).
- **Pomar** (`ok_pomar_primavera.png`): a árvore de fruta muda com a estação. Na primavera tem flores rosadas, no verão fica verde, no outono fica laranja e no inverno fica nua.
- **Outono:** a paleta está certa. As copas laranja e ferrugem contrastam com os pinheiros verdes, e o capim fica oliva. O céu e o lago continuam os do verão, como deve ser.
- **Amanhecer de inverno (7h):** as montanhas rosadas sob o céu violeta são o quadro mais bonito do dia.

## Defeitos

### E1. Telhados vermelhos no inverno (alto) — arte, corrigido
`recortes3b/R1_telhados_sem_neve.png` e `R1_telhado_antes_depois.png`

- **O que estava errado:** com tudo nevado em volta, as casas de pedra continuavam com o telhado vermelho. A neve das construções era só o pixel exposto de cada coluna, e num telhado inclinado isso vira uma borda de 1 px na diagonal.
- **Correção:** a neve das construções agora tem 3 px de espessura, com a borda de baixo pontilhada. A parte de cima de cada água do telhado fica branca, e a cor do telhado aparece embaixo.
  - Vale para as casas, os templos, o celeiro, as torres e as ruínas, em `estacoes/inverno/estagioN/`, `culturas/` e `memoria/`.
  - A mudança está em `estacoes.py`: `neve_por_cima(..., espessura=3)`.
  - As chaminés de `chamines.json` continuam no mesmo lugar.

### E2. A fumaça das chaminés é um fiapo pontilhado (médio) — arte, corrigido
`recortes3b/R2_fumaca_chamine_fiapo.png` e `R2_fumaca_antes_depois.png`

- **O que estava errado:** a `fumaca_chamine_4q` era um fiapo de 1 px, em bege e cinza claros. Sobre o céu e as montanhas brancas do inverno, lia como uma linha pontilhada vertical, quase invisível.
- **Correção:** a folha agora tem 3 baforadas cinzas (11) com o lado de cima claro (12).
  - Elas nascem com 1 px na boca da chaminé, crescem até 3 px, derivam para a direita e se desfazem em pedaços no alto.
  - Os 4 quadros fecham o ciclo, subindo 4 px por quadro.
  - O tamanho e o encaixe não mudaram (8 × 16, base na boca da chaminé).

### E3. Montanhas nevadas à noite cinza-oliva (médio) — arte, corrigido
`recortes3b/R3_montanhas_noite_cinza.png` e `R3_montanhas_noite_antes_depois.png`

- **O que estava errado:** à noite, a neve das montanhas era cinza (11) com sombra lilás (5). Era a parte mais clara da tela à noite, mais que a fogueira e as janelas, e puxava para o oliva.
- **Correção:** a neve passou a azul de lua (18), com sombra azul-escura (4). Ainda lê como neve, mas fica atrás da vila.
  - Em `R3_..._antes_depois.png`, a primeira linha é a de antes e a segunda é a escolhida. As outras duas linhas foram alternativas que testei e descartei.
  - A mudança vale para `estacoes/inverno/montagem/montanhas_*_noite.png`.

### E4. Baforadas de fumaça altas no céu (médio) — B
`recortes3b/R4_baforadas_altas_no_ceu.png` (outono, quadros 0 e 47)

- **O que está errado:** baforadas cinzas sobem 25 a 30 px acima da vila e ficam inteiras por muitos segundos, nas 4 estações. Sobre as montanhas, leem como pássaros ou trapos no céu. É o D5 da auditoria 3, que continua aberto.
- **O que deveria ser:** a baforada sobe uns 6 a 10 px, passa pelos 6 quadros da `fumaca_6q` (que se desfaz em pedaços) e some. A fumaça da chaminé, no inverno, é a `fumaca_chamine_4q`, em ciclo, presa à boca da chaminé.

### E5. Lago sem gelo no inverno (baixo) — B
`recortes3b/R5_lago_sem_gelo.png`

- **O que está errado:** com a neve no chão e nas montanhas, o lago continua azul e aberto até a margem.
- **O que deveria ser:** nas colunas de água junto da margem, a superfície usa `estacoes/inverno/terreno/gelo_superficie.png` (LEIA-ME, seção 13). No inverno fundo, ou nos primeiros 30 a 40 px a partir da praia, o lago fica congelado.

### E6. Roça e pomar entre os pinheiros do morro (baixo) — B, com apoio da A
`recortes3b/R6_roca_entre_pinheiros.png` (outono e inverno)

- **O que está errado:** a roça e o pomar ficam no alto do morro, entre os pinheiros da floresta. Quase sempre há gente em pé na frente, cobrindo a roça, então quase não se vê como ela muda com a estação, nem no inverno, quando fica coberta de neve.
- **O que deveria ser:** as roças no terreno aberto e plano, perto das casas, longe da borda da floresta, e as pessoas que trabalham nela espalhadas, e não amontoadas na frente.

### A conferir

- **Roda d'água:** não aparece em nenhuma das capturas (os GIFs são de um povo do estágio 3, e a captura do estágio 6 não mostra roça irrigada). A arte de inverno dela vem congelada. Vou conferir na auditoria 4.
- **Neve no chão:** é uma faixa de 2 a 3 px de branco no alto do terreno. Na vista de lado, lê bem, e não mexi.
- **Uma janela por casa:** às 20h, só uma das duas janelas de cada casa de pedra parece acesa. A outra pode estar só coberta por gente na frente. Vou conferir na auditoria 4.

## Resumo por responsável

| Quem | Itens |
|---|---|
| C (arte) | E1, E2, E3: **corrigidos**, com as peças, as variações de inverno e os atlas regenerados |
| B (apresentação) | E4 (o D5 da auditoria 3), E5 e E6; conferir a roda d'água e as janelas |
| A (simulação) | apoio no E6, se o lugar da roça vier da simulação |

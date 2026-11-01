# Auditoria 12: roteiro (a primeira hora com o mundo começando vazio)

*Sessão C (arte), 01/11/2026. Preparado antes da entrega da A, sobre a main em `69791ad`. Decisão do orquestrador: o mundo novo começa vazio, de manhã, e o primeiro gesto do jogador é criar o povo, com a chegada e a primeira fogueira do recomeço.*

## A pergunta

Começar vazio é melhor ou pior que começar com gente (auditorias 8 e 10, notas 3 e 4)? A resposta tem de ser honesta, mesmo que seja "pior".

## Como rodar, quando a A entregar

1. **Trazer a main** e gerar o `.exe`. Fazer a cópia da pasta de dados do usuário e, no fim, **copiar por cima, sem apagar nada**.
2. **A primeira abertura com o `.exe` de verdade** (sem opções), para ver a manhã vazia e a dica.
3. **A sessão 1 com a entrada injetada,** igual à da auditoria 10 para comparar, com uma diferença:
   - antes dos poderes, **esperar 30 s sem fazer nada**, para ver se o mundo vazio segura o olhar e se a dica é achada;
   - depois, **clicar no mundo** para fazer nascer o povo.

   A base é `roteiro12_sessao1_base.json` (o da auditoria 10), com os tempos empurrados em uns 40 s.
4. **Reabrir e voltar depois de 8 horas,** como nas auditorias 8 e 10.
5. **Uma segunda primeira abertura,** com outra semente, para ver se o lugar onde o povo nasce e os bichos do primeiro minuto variam.

**O que medir:**
- **até o primeiro movimento:** quantos segundos até alguma coisa se mexer na tela;
- **até haver gente:** quantos segundos até a chegada do povo;
- **até a primeira fogueira:** quantos segundos até ela acender;
- **o primeiro poder:** se a fila de dicas leva a ele;
- **as palavras do aviso de nascimento:** precisam ser as do primeiro povo, e não "segunda era".

## A arte do mundo vazio no primeiro minuto (revisão de agora)

Simulei a manhã vazia com o que existe hoje: um mundo novo da semente 7, com todos mortos e 40 anos passados, para os restos do estágio 1 já terem sumido, às 7h. Depois de 30 s, um clique no mundo (`recortes_vazio_inicio/primeiro_minuto_simulado.png`).

| O que | Como está | Avaliação |
|---|---|---|
| **A luz da manhã** | o céu do amanhecer, as montanhas rosadas e o lago com o brilho do sol | **convida**: é das imagens mais bonitas do jogo |
| **A dica** | "Clique sobre o mundo para fazer nascer um povo" aparece na alça depois de uns 3 s | **lê bem, mas fica longe**: o olho está no mundo, e a alça é pequena e escura |
| **Movimento** | em 30 s, só um ou dois pássaros longe e o brilho do lago | **parado demais**: é o que pode parecer quebrado |
| **Os bichos da manhã** | as regras existem (o cervo das 5h às 9h, a garça das 5h30 às 16h, o coelho das 5h às 8h30), mas não apareceram nesse minuto | falta garantir que apareçam |
| **O clique** | o povo chega pelo morro, se junta e acende a primeira fogueira, e só depois sobem as cabanas | **funciona**: o melhor momento da abertura |
| **O aviso** | "Nasceu um povo novo: começa a segunda era." | **errado para o começo**, se ficar assim (no teste, o povo é o segundo de verdade) |

### Arte nova (C): o convite dentro do mundo

`sinais/convite_povo_4q` (24 × 16, LEIA-ME seção 5) e `recortes_vazio_inicio/convite_povo_sobre_a_clareira.png`.

No chão da clareira onde o povo vai nascer, um anel de luz morna pontilhada que respira e, em cima, a estrela do botão de criar povo, subindo e descendo. Ele fica do primeiro segundo até o primeiro clique. Assim, o mundo diz onde clicar, e não só a alça, e a tela vazia deixa de parecer parada.

### Para a B e a A, antes da auditoria 12

| # | Item | Quem |
|---|---|---|
| V1 | ligar o `convite_povo_4q` na clareira onde o povo vai nascer, até o primeiro clique | B |
| V2 | **garantir bichos no primeiro minuto do mundo vazio:** um cervo na borda da mata, uma garça na beira do lago e um coelho cruzando, nos primeiros 20 s; e os bandos de pássaros mais frequentes até o clique. A arte já existe. | B |
| V3 | o aviso de nascimento do primeiro povo: "Nasceu o primeiro povo" (ou o nome do povo), sem "segunda era" | A ou B |
| V4 | a dica do criar povo também perto do cursor quando ele está sobre o mundo vazio (por exemplo, "clique para fazer nascer um povo" na dica de lugar), e não só na alça | B |

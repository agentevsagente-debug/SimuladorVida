# Auditoria visual 3: o cotidiano

*Sessão C (arte), 01/11/2026. Feita sobre a main com a rotina nova na tela (`270364f`): detalhes com a arte do cotidiano, caçada com a caça no pau, incidentes, panela e espeto, porco e ave de dia. O foco é o que o usuário cobra: o cotidiano ser interessante de olhar.*

## Como foi feito

Joguei a semente 7, no verão, nos ritmos do jogo. Os comandos estão em `capturar3.sh`, e as 140 capturas, em `capturas3/`.

- **No ritmo 1x** (1 hora do jogo = 112,5 s): amostrei 10 horas do dia (6, 8, 10, 12, 14, 16, 18, 20, 22 e 1h). Em cada uma capturei 8 quadros, de 1,5 em 1,5 s, ou seja, uns 11 s de jogo de verdade, como alguém olhando de canto de olho.
- **No ritmo 50x:** um dia inteiro, das 5h às 5h, em 48 quadros (um a cada meia hora de jogo). O resumo está em `recortes3/dia_em_50x.png`.
- **Num mundo de 40 anos:** 10h e 16h, em 1x.

Nenhuma captura tem cor fora da paleta ou pixel semitransparente.

## Impressão de jogador

| Período | Nota | Por quê |
|---|---|---|
| **Manhã** (6h às 11h) | **3** | O amanhecer é bonito, e o povo sai da cabana e se espalha entre a praia, o arbusto e a fogueira. Dá a sensação de dia começando. Mas, depois de se espalhar, cada um fica parado no seu ponto, e em 1x quase não dá para saber o que estão fazendo. |
| **Tarde** (12h às 16h) | **2** | É o período mais morto. Os mesmos 2 a 4 grupos ficam nos mesmos lugares por horas, com pouca mudança de quadro para quadro (`recortes3/D6_meio_dia_parado.png`). A caçada acontece no morro, entre os pinheiros, mas não lê como caçada (D5). O porco e a ave aparecem, mas pequenos e longe do povo. |
| **Fim de tarde** (17h às 19h) | **4** | É o melhor momento. Todos voltam para o acampamento no céu de entardecer, a fogueira acende e a vila fica cheia e quente (`recortes3/ok_entardecer_reunido.png`). Só perde ponto porque a roda vira um amontoado em cima da fogueira (D1). |
| **Noite** (20h às 5h) | **3** | De 20h a 22h é bonito: roda em volta do fogo, vagalumes, estrelas e a vigia com a lança (`recortes3/ok_noite_fogueira.png`). Da meia-noite às 5h, sobra uma pessoa de vigia e a fogueira, por 5 horas de jogo, quase 10 minutos em 1x (`recortes3/D7_madrugada_vazia.png`). |

**Dá vontade de continuar olhando?**
- **No 50x, sim.** O dia tem ritmo: dispersa de manhã, se reúne no fim da tarde, faz a roda à noite e esvazia de madrugada. É agradável deixar rodando.
- **No 1x, só no fim de tarde e no começo da noite.** De manhã e à tarde, quem olha de canto de olho vê sempre a mesma imagem.

**Respostas às perguntas:**
- **As subações e os incidentes são legíveis em 1x?** Pouco. Em 8 × 12, o que se lê é a postura (agachado, ajoelhado, braço erguido) e o objeto grande (fogueira, panela, cesto). As ferramentas finas, como lança, vara, colher e cuia, só aparecem no 4x. Nas capturas em 1x, quase todas as pessoas parecem paradas ou andando (D4).
- **A caçada lê como caçada?** Não. Dois ou três vultos entre os pinheiros do morro, longe da vila e de costas para o bicho, sem a caça visível perto deles. Quando voltam com a caça no pau, o objeto é pequeno e passa rápido.
- **Quem está ocioso parece vivo?** Mais ou menos. A respiração e as microanimações existem, mas são lentas e sutis demais para 1x. O ocioso parece parado.
- **A noite tem alguma coisa?** Até as 22h, sim. Depois, quase nada.
- **Há momentos mortos?** Dois: das 12h às 16h e da meia-noite às 5h.

## Defeitos novos, do mais grave ao mais leve

Cada defeito tem um recorte em 4x em `recortes3/`.

### D1. Pessoas em pé dentro da fogueira (alto)
`recortes3/D1_pessoa_sobre_a_fogueira.png`

- **O que está errado:** em vários quadros, de dia e no fim de tarde, uma pessoa é desenhada em cima da chama, cobrindo o fogo. A roda do fim de tarde vira um amontoado em cima da fogueira.
- **O que deveria ser:** ninguém a menos de 6 px do centro do fogo. A roda fica em volta, como na cena-alvo, com quem está à direita espelhado, olhando para o fogo.
- **Quem corrige:** **B** (posição de desenho) e **A** (as posições de `fogueira` e de `cozinhar`).

### D2. A cada hora, alguém deveria fazer algo visível (alto, ritmo)
`recortes3/D6_meio_dia_parado.png`, `recortes3/D4_subacoes_ilegiveis_1x.png`

- **O que está errado:** das 12h às 16h, a mesma imagem por minutos. As subações existem, mas são curtas, pequenas ou feitas no lugar, então em 1x o povo parece parado.
- **O que deveria ser:**
  - pelo menos um **acontecimento legível** a cada 1 ou 2 minutos de 1x, como alguém atravessando a tela inteira (buscar água, levar lenha), um incidente, uma brincadeira de crianças ou um bicho se aproximando;
  - ociosos que trocam de lugar e de microanimação com mais frequência;
  - nas subações, preferir as que mudam a silhueta (`catar_lenha`, `carregar_cesto_cabeca`, `espantar`, `tropecar_cair`, crianças correndo e pulando) e as que deixam um objeto grande na tela (cesto, feixe, caça no pau).
- **Quem corrige:** **A** (frequência e variedade das subações na rotina) e **B** (intervalos de troca das microanimações). **C** pode fazer versões "exageradas" das ações para 1x, com objetos maiores e postura mais aberta, se a A e a B quiserem.

### D3. A caçada não lê como caçada (médio)
`recortes3/D5_cacada_no_morro.png`

- **O que está errado:** os caçadores ficam entre os pinheiros do morro, longe da vila, e o animal não fica perto deles. Não se vê espreitar, arremessar e acertar como uma sequência.
- **O que deveria ser:** a caçada na borda da floresta e mais perto da vista, com o porco (`porco_do_mato_4q`) visível, os caçadores agachados indo atrás dele, o arremesso, o bicho caído (`porco_abatido`) e a volta com a caça no pau (`carregar_caca_4q` + `caca_no_pau_porco`) atravessando até a fogueira.
- **Quem corrige:** **A** (onde e em que ordem) e **B** (encenação).

### D4. A madrugada vazia (médio)
`recortes3/D7_madrugada_vazia.png`

- **O que está errado:** da meia-noite às 5h, só a vigia e a fogueira, por quase 10 minutos em 1x.
- **O que deveria ser:** pequenos acontecimentos noturnos, por exemplo:
  - alguém que acorda e vai até o fogo (`bocejar_4q`, `esticar_4q`);
  - a fogueira baixando para brasas (`efeitos/brasas_4q`);
  - um bicho noturno (morcego, coruja) e vagalumes perto da água;
  - de vez em quando, uma estrela cadente (o céu vivo já tem);
  - a vigia cochilando (quadro 1 do `vigia_2q`) e acordando.
- **Quem corrige:** **A** (eventos noturnos) e **B**.

### D5. Fumaça parada e solta no céu (médio)
`recortes3/D2_fumaca_solta_no_ceu.png`

- **O que está errado:** uma baforada cinza fica parada no alto, longe da fogueira, por horas e em todos os horários. Parece uma pedra flutuando.
- **O que deveria ser:** a fumaça sai da fogueira, sobe uns 6 a 10 px, se desfaz nos 6 quadros da `fumaca_6q` e some. Uma nova baforada nasce a cada tanto.
- **Quem corrige:** **B**.

### D6. Uma linha tracejada escura ao lado da árvore do morro (baixo)
`recortes3/D3_samambaia_tracejada.png`

- **O que está errado:** a `samambaia_frente` posta em x = 316 aparece como um traço vertical pontilhado e escuro, que parece um artefato. Ela também está na cena-alvo, mas lá passava despercebida.
- **O que deveria ser:** uma samambaia de primeiro plano mais cheia, ou nenhuma nesse ponto.
- **Quem corrige:** **C** (redesenhar a `samambaia_frente` com folhagem cheia) ou **B** (tirar essa do layout).

### D7. Vila de 40 anos com 3 casas em ruína no meio (baixo, a confirmar)
`recortes3/D8_vila_com_ruinas_no_meio.png`

- **O que está errado:** no mundo de 40 anos, três ruínas de casa de taipa ficam lado a lado no meio da vila viva, entre o templo e o morro. Pode ser a vila que encolheu, mas lê como erro.
- **O que deveria ser:** se as casas foram abandonadas, que o mato tome conta delas com o tempo (`natureza/casa_ruina_mato_1` a `_3`). Também ajudaria que as ruínas fiquem nas pontas da vila, e não no meio.
- **Quem corrige:** **B** (usar os graus de mato) e **A** (quais casas são abandonadas).

## Sugestões de arte para o cotidiano (sessão C, se aprovado)

1. **Ações "de 1x":** versões das subações mais fortes em silhueta, com braços mais abertos e objeto de 2 px em vez de 1, para quem olha de canto de olho.
2. **Brincadeiras de crianças:** pega-pega e ciranda de mãos dadas, em 6 × 8. Movimento é o que mais chama o olho.
3. **Coruja e brasas:** uma coruja pousada piscando, para a madrugada. As brasas da fogueira baixa já existem (`efeitos/brasas_4q`).
4. **Ícone de pensamento ou fala** sobre quem conversa ou conta história: um balão de 6 × 5 com um sinal. Ajuda a ler a vida social em 1x.

## Resumo por responsável

| Quem | Itens |
|---|---|
| A (simulação) | D2 (frequência e variedade), D3 (caçada perto e em sequência), D4 (eventos noturnos); apoio no D1 e no D7 |
| B (apresentação) | D1, D5, D7; parte do D2, do D3 e do D4 |
| C (arte) | D6; as sugestões de arte acima, se aprovadas |

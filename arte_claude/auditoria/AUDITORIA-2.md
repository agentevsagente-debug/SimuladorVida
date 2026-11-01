# Auditoria visual 2 do jogo rodando

*Sessão C (arte), 01/11/2026. Feita sobre a main com a entrega da sessão B: construções por tipo e estágio, ruínas, 5 poderes novos, chuva irregular, amanhecer, raio, roupa de inverno, relógio e céu vivo. A referência é a cena-alvo e as peças de `arte_claude/pecas/`.*

## Como foi feito

Usei o mesmo método da primeira auditoria. Os comandos estão em `capturar2.sh`, e as 85 capturas, em `capturas2/`.

| Grupo | Capturas |
|---|---|
| Estações | 4 estações ao meio-dia |
| Horários | amanhecer (6h), manhã (8h), entardecer (18h) e noite (22h), mais `ceu_noite_seq` (4 quadros com 1,5 s de intervalo) |
| Mundos avançados | `mundo_s7_60`, `mundo_s7_150`, `mundo_s3_150` (também no inverno e à noite) e `mundo_s11_300`; `mundo_s7_60_tudo`, com a alça e o relógio |
| Vida | `vida_manha_seq` e `vida_tarde_seq` (6 quadros com 1 s de intervalo) |
| Poderes | os **11** poderes, 5 quadros cada, de 0,25 em 0,25 s depois do gesto |

**Verificações automáticas.** Nenhuma das 85 capturas tem cor fora da paleta ou pixel semitransparente. Todas estão na escala inteira.

A importação do Godot, necessária para rodar, mexeu de novo em `.import` e `.uid` dentro de `jogo/`. Desfiz tudo depois; nada fora de `arte_claude/` foi alterado.

## O que a primeira auditoria pediu, e como está

| # | Defeito da auditoria 1 | Situação |
|---|---|---|
| 1 | mundo avançado sem construções | **corrigido.** Casas, templos, torres, forja, biblioteca e muralha aparecem por estágio, com a cultura e com neve no inverno (`recortes2/ok_inverno_avancado.png`). Mas veja os defeitos novos N1 e N2. |
| 2 | pessoas sobre o lago | **corrigido.** Ninguém mais anda na água; na margem só há areia e barco. |
| 3 | multidão em fila sobreposta | **melhorou, mas continua grave.** Agora são 2 fileiras, porém a multidão ainda cobre as construções (N2). |
| 4 | acampamento amontoado | **corrigido.** No início, as pessoas ficam espalhadas em volta da fogueira. |
| 5 | fumaça em grade | **corrigido.** A fumaça nova se desfaz em pedaços. |
| 6 | chuva com nuvens repetidas | **corrigido em parte.** As nuvens agora são irregulares, mas o céu continua claro com chuva e com dilúvio (N8). |
| 7 | mata do inverno listrada | **corrigido.** |
| 8 | montanhas nevadas claras à noite | **corrigido na arte.** Não recapturei a noite de inverno no jogo. |
| 9 | 5 poderes fora do jogo | **corrigido.** Os 11 poderes respondem ao gesto. Veja N3, N4 e N7. |
| 10 | manhã igual ao meio-dia | **corrigido**, porque o amanhecer existe agora (sol nascendo às 7h e 8h). Mas veja N5. |
| 11 | roupa de verão no inverno | **corrigido.** As pessoas usam a roupa de inverno no mundo nevado. |
| 12 | raio invisível | **corrigido.** O raio aparece nos 2 primeiros quadros (`recortes2/ok_raio_visivel.png`). |
| 13 | cabanas em néon à noite | **melhorou.** O contorno laranja ficou mais suave. |

O relógio na alça está nítido e legível em 1x (`recortes2/ok_relogio_alca.png`).

## Defeitos novos, do mais grave ao mais leve

Cada defeito tem um recorte em 4x em `recortes2/`.

### N1. Construções sobrepostas umas às outras (grave)
`recortes2/N1_construcoes_sobrepostas.png` (semente 7, 150 anos)

- **O que está errado:** torres da muralha, o templo de colunas e casas são desenhados uns por cima dos outros. Uma torre entra no templo, uma casa cobre metade de outra construção e o símbolo do templo aparece sobre a torre. No morro, as 3 casas de enxaimel se encostam no templo e ficam por cima dele.
- **O que deveria ser:** cada construção no seu lote, com pelo menos 2 a 4 px entre elas, como nas cenas `pecas/cenas/cena_estagio*.png`. A muralha fica na ponta da vila, e o templo, com espaço em volta.
- **Quem corrige:** **B** (encaixe dos lotes na vista) e **A**, se o `x` das construções vier da simulação.

### N2. A multidão cobre as construções (grave)
`recortes2/N2_multidao_cobre_construcoes.png`

- **O que está errado:** com 100 ou mais pessoas, as 2 fileiras de gente cobrem a base de todas as construções, com portas, janelas e escadas dos templos. A vila vira uma faixa de corpos com telhados por cima, e as pessoas deixam de ser legíveis.
- **O que deveria ser:** só um tanto de pessoas visíveis por trecho, e o resto dentro de casa, na roça, no trabalho ou fora da vista. Ninguém parado na frente das portas. Uma referência é a cena de vila do estágio, com 4 a 6 pessoas por casa.
- **Quem corrige:** **B** (quantas pessoas desenhar e onde) e **A** (a rotina pode mandar parte das pessoas para dentro de casa, para a roça ou para fora da vista).

### N3. Terremoto: a poeira forma placas retas e depois uma grade (alto)
`recortes2/N3_terremoto_poeira_em_placas.png` (quadros 0, 2 e 4)

- **O que está errado:** a `poeira_terremoto_4q` aparece repetida lado a lado, na mesma altura e no mesmo quadro. Isso forma uma faixa marrom de bordas retas sobre a vila, e nos últimos quadros vira um pontilhado em grade.
- **O que deveria ser:** nuvens de poeira soltas, em alturas e quadros diferentes, que se desfazem em pedaços.
- **Quem corrige:** **C**, já corrigido nesta entrega: a poeira nova tem contorno irregular e se desfaz em pedaços, sem grade. Falta **B** espalhar as nuvens com deslocamentos e quadros diferentes, sem enfileirar.

### N4. Seca: o tremor de calor vira linhas pontilhadas regulares (médio)
`recortes2/N4_seca_calor_em_linhas.png`

- **O que está errado:** a `calor_4q` desenha fileiras inteiras de pontos que, repetidas sobre a vila, leem como uma grade. Além disso, logo depois do gesto não aparecem o céu amarelado (`ceu_seca`) nem as rachaduras (`seca_rachaduras_4q`).
- **O que deveria ser:** tracinhos ondulados soltos subindo do chão, com o céu amarelando e o chão rachando aos poucos.
- **Quem corrige:** **C**, já corrigido: a `calor_4q` nova tem tracinhos curtos em lugares sorteados. Falta **B** mostrar o céu de seca e as rachaduras quando a seca é do deus. Se isso já depende de dias de seca, o céu poderia ao menos amarelar um pouco logo após o gesto.

### N5. Amanhecer com corte reto no céu (médio)
`recortes2/N5_amanhecer_corte_reto.png` (6h)

- **O que está errado:** às 6h, o alto do céu ainda é de noite e o resto já é laranja de entardecer, separados por uma linha reta horizontal, sem transição.
- **O que deveria ser:** a mesma passagem pontilhada de faixas do céu da cena-alvo. O motor pode passar de um céu para o outro com o pontilhado Bayer (troca por pixel, conforme o limiar), sem uma emenda horizontal.
- **Quem corrige:** **B**.

### N6. Céu vivo: fiapos de nuvem como linhas pontilhadas soltas (médio)
`recortes2/N6_ceu_fiapos_pontilhados.png`

- **O que está errado:** no alto do céu aparecem linhas retas de pontos (fiapos de nuvem sem a nuvem), que leem como artefato. Também há traços verticais pontilhados abaixo do sol. As nuvens das 3 camadas às vezes se encavalam com bordas diferentes.
- **O que deveria ser:** fiapos só embaixo de uma nuvem, curtos e com parte cheia, como no céu da cena-alvo, e nada vertical sob o sol. Nuvens da mesma camada não se encavalam.
- **Quem corrige:** **B**. Se a sessão B quiser, **C** entrega nuvens soltas em folhas, já com o fiapo e em 3 tamanhos, para as camadas.

### N7. Presságio sem cometa nem eclipse visível (médio, a confirmar)
`recortes2/N7_pressagio_sem_cometa.png`

- **O que está errado:** de 1,6 a 2,6 s depois do gesto, o céu não mostra o cometa (`cometa_4q`) nem o eclipse (`eclipse_4q` e `ceu_eclipse`). Só aparecem uns pontinhos rosa.
- **O que deveria ser:** o cometa atravessando o céu por alguns segundos, ou o disco escuro cobrindo o sol, conforme o grau do presságio.
- **Quem corrige:** **B**. Pode ser que o efeito chegue depois da janela capturada.

### N8. Chuva e dilúvio com o céu claro (baixo)
`recortes2/N8_diluvio_ceu_claro.png`

- **O que está errado:** a chuva e o dilúvio caem com o céu azul e o sol forte, e a água não sobe nos segundos capturados.
- **O que deveria ser:** o céu escurecendo durante a chuva e mais ainda no dilúvio. A enchente usa os blocos `enchente_superficie_4q` e `enchente_agua_1q`.
- **Quem corrige:** **B**.

## O que está bom

- **Vilas:** as vilas dos estágios avançados aparecem, com construções de vários estágios, culturas e templos com símbolo. No inverno, a vila inteira fica nevada.
- **Poderes:** os 11 poderes respondem. O raio, o fogo com árvores queimadas, a fartura, a pedra erguida, o sonho, a cura e o dilúvio leem bem.
- **Céu:** o amanhecer existe, com o sol nascendo, e as estrelas e a lua estão no estilo.
- **Alça:** o relógio é legível e combina com a fonte.

## Resumo por responsável

| Quem | Defeitos |
|---|---|
| B (apresentação) | N1, N2, N5, N6, N7, N8, e a parte de motor do N3 e do N4 |
| A (simulação) | apoio no N1 (lotes) e no N2 (onde as pessoas ficam) |
| C (arte, esta sessão) | N3 e N4: **corrigidos** nesta entrega (`efeitos/poeira_terremoto_4q` e `efeitos/calor_4q` novos, com os atlas regenerados) |

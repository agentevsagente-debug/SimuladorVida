# Relatório da apresentação (sessão B, fase 1)

Tarefas 1 a 5 do briefing `sessoes/fase1-b-apresentacao.md`. Este relatório cobre o ajuste das pessoas no acampamento e as tarefas 4 (interação) e 5 (leveza). As capturas estão em `jogo/capturas/`.

## Auditoria 6 (D4 e as cenas da tarde) e auditoria 7 (estágios)

| # | O que foi feito |
|---|---|
| **D4** | À noite, a dica sobre uma cabana mostra quem dorme ali (em dourado; com mais de 5, os 4 primeiros e "e mais N") e o sonho de um deles na linha lilás, com o balãozinho e sem aspas ("Losura, sonhando com Totoim"). Quem dorme fora de casa também mostra o `sonho` como narração. Captura: `capturas/dica-da-cabana.png`. |
| **Pesca** | Na água rasa, num ponto sem mato na frente. Espera curvado (`pescar_espreitar_forte_2q`, cada quadro por 2 s), com um peixe pulando à frente a cada 9 s. O golpe mira, arpoa e, no certo, ergue o peixe se debatendo. Volta ao fogo com o peixe na lança (`carregar_peixe_forte_4q`). |
| **Lavagem** | Os adultos lavam ajoelhados na beira (`lavar_margem_forte_4q`), a 10 px um do outro, com o pano sobre a água. As crianças se banham na água rasa (`crianca_banho_4q`), duas a duas, frente a frente. A beira é onde a água desenhada acaba (`vista.beira_visivel`), não a coluna de terreno. |
| **Coleta** | A descida em fila usa o cesto na cabeça (forte). No fogo, quem despeja agacha com o cesto cheio à frente. Não vi a coleta na tela, porque nenhum dia da semente 7 até o 60 teve coleta. |
| **Caçada** | Conferida na posição nova (dia 13): o porco além da última cabana, a fila na espreita e a volta pela vila. GIF: `capturas/tarde-cacada-1x.gif`, das 13h às 18h, com um quadro a cada 2 s, tocando 8 vezes mais rápido. |
| **A1** | As 9 folhas de sempre (andar, parado, rezar, colher, sentado, criança, idoso) e as 5 da pesca e da lavagem entram em `COM_ROUPA_DO_ESTAGIO`. |
| **A2** | A casa caiada do estágio 5 entra em `CASAS` (vista), `PECAS`, `CAMADAS_CULTURA` e `RUINAS` (obras). |
| **V1** | No máximo 45 pessoas acordadas na tela. Com mais gente, o excesso passa a hora em casa, escolhido a cada hora, e nunca quem está numa cena ou é seguido. Na frente da vila, até 3 parados por casa (no mínimo 10). Dos ociosos que sobram, metade vai para a beira do lago, o morro ou uma roça, e a outra metade fica em casa. |
| **C1** | 10 px a mais entre construções de povos diferentes, no encaixe dos lotes. |
| **E4** | A baforada nasce dentro das chamas, sobe só 3 a 5 px, dura 2,2 s e sai a cada 2,5 a 4 s. Ela some rente ao fogo, sem ficar no céu. |

Captura: `capturas/auditoria7-estagios.png`, com a semente 3 nos anos 250 e 500 e a semente 7 nos anos 122 e 400 (às 10h e às 19h).

## Auditoria 6 (B)

| # | O que foi feito |
|---|---|
| **H1** | No abate, os dois que vão carregar (os dois primeiros da cena) amarram o porco agachados, um de cada lado, a 7 px dele. Os outros comemoram no começo do abate e depois esperam atrás, de pé. Na volta, só esses dois carregam o pau com a caça, e os outros vêm andando atrás. Ninguém mais fica com o pau vazio na cabeça. |
| **H2** | Na espreita, na mira e no arremesso, os caçadores vão em fila atrás do da frente, a 7 px um do outro, e o da frente desliza de um avanço para o outro. |
| **D3** | A linha "a linhagem que você segue" saiu. No lugar dela, o ícone da linhagem (8 × 8) aparece ao lado do nome. |
| **Sugestão** | Quando o pensamento cita pelo nome alguém que está na tela, um ponto dourado (2 × 2, com contorno escuro) fica sobre a cabeça dessa pessoa enquanto a dica estiver aberta, e acompanha quem anda. |

Capturas:
- `capturas/auditoria6-cacada.png`: a caçada de 13 dias, das 16h30 às 17h20, com a fila na espreita e os dois amarrando;
- `capturas/auditoria6-dica.png`: o ponto dourado sobre Ulim, no pensamento de Hayoil, e o ícone da linhagem ao lado de Totoim.

O **D4** (a dica da cabana à noite) espera o dado da A.

**Pássaro pousado:** troquei pelo `passaro_pousado_forte_2q` (5 × 3), da arte nova da C.

**Memória depois da arte nova:** medi 10 min em 1x, pelo editor. O resultado não substituiu a medição final no repositório.

| | CPU | Gerenciador, média | Gerenciador, máximo |
|---|---|---|---|
| Agora | 0,185% | 127,8 MB | 128,5 MB |
| Medição final | 0,192% | 122,7 MB | 124,6 MB |

A diferença de cerca de 5 MB vem das 53 peças novas e da dica. O jogo não carrega os atlas, então o atlas de 1024 × 512 não pesa.

## O executável (builds/Simulador de vida.exe)

**Exportação:** fiz com `--export-release "Windows"` a partir desta branch, que é a main com as entregas da B. O executável tem 105 MB.

**verificar.ps1:** os 23 itens passaram (19 antigos e 4 novos). O item 8 novo:
- gera o executável;
- devolve ao git os `.import` em que a exportação só trocou as quebras de linha;
- abre o executável por 15 s e confere a janela de 960 × 356, a passagem do mouse na faixa e o log sem erros.

Para pular o item 8, use `-SemExportar`.

**Teste à mão, com a configuração de verdade:**

| O que | Resultado |
|---|---|
| Janela transparente | OK |
| Passagem do mouse pela faixa | OK |
| Escala pela roda (2x para 3x) | OK |
| Atalho global (Ctrl+Alt+H esconde e mostra) | OK |
| Dica da pessoa | OK |
| Salvar ao fechar e retomar ao abrir | OK, com a escala e a posição guardadas |
| Erros nos dois logs | nenhum |

A pasta de dados do usuário voltou ao que era: não havia mundo nem `moldura.cfg`.

**Defeito achado e corrigido:** as dicas da primeira abertura e os avisos ao lado da alça nunca apareciam na janela de verdade.
- **Causa:** no Windows, a passagem do mouse recorta também o desenho, e a caixa ficava na faixa transparente. Só a captura interna a mostrava.
- **Correção:** a interface expõe `caixa_na_faixa`, e a moldura a inclui na região da janela enquanto ela está na tela. Enquanto isso, a caixa recebe o mouse.

**Memória:** medida com `medir.ps1 -Cenario normal -Executavel` (a opção `-Executavel` é nova), 10 min em 1x.

| | CPU média | Gerenciador, média | Gerenciador, máximo | Conjunto de trabalho | Privada, máximo |
|---|---|---|---|---|---|
| Executável | 0,189% | 106,7 MB | 107,2 MB | 199 MB | 212 MB |
| Pelo editor (medição final) | 0,192% | 122,7 MB | 124,6 MB | 226 MB | 230 MB |

## A dica sobre a pessoa

Com `mundo.dica(id)` da A, a dica de pessoa mostra:
- **Linha 1:** o nome, a idade e o humor, como em "Lora, 7 anos — de luto", na letra dourada. A fonte não tem o ponto do meio, então o separador é o travessão.
- **Linha 2:** o que a pessoa faz, com o papel na frente para líder e sacerdote.
- **Linha 3:** o pensamento entre aspas, em lilás da paleta (A995DB), com o balãozinho de pensamento (`balao_5v`, variação 2) ao lado. A linha some quando o pensamento vem vazio, o que acontece com quem dorme sem sonhar.
- **Depois:** a prece e a linhagem, como antes.

**Como a dica se comporta:**
- O texto tem no máximo 140 px de largura, com quebra de linha.
- A dica fica acima da cabeça, com o bico apontando para ela. Se não houver espaço acima, ela vai para o lado da pessoa e nunca a cobre.
- Com o cursor parado, ela se refaz a cada 0,5 s e acompanha o que a pessoa passa a fazer.
- Sem a função da A, a dica mostra os traços, como antes.

**Opção de teste nova:** `--dica-pessoa=ID[:S]` põe o cursor sobre a pessoa e a segue.

**Captura:** `capturas/dica-da-pessoa.png`, em 2x, com um adulto, uma criança de luto e um líder de luto. O mundo tem 40 anos, e a morte foi provocada com um raio.

## Auditoria 5, T3 (a volta e a repartição)

| O que | Como ficou |
|---|---|
| Espreita | O porco desliza de um ponto ao outro entre os avanços. |
| Mira | Quem vai arremessar segura a lança erguida (quadro 1 do arremesso forte). Os de trás apontam (`cacar_apontar_2q`). |
| Arremesso | A lança sai logo no começo da etapa, que agora dura 6 min, e o porco cambaleia quando ela crava. |
| Volta | Os dois do pau ficam a 16 px um do outro, e a caça vai pendurada entre eles, também enquanto esperam. Os outros caçadores seguem atrás. |
| Repartição | A caça fica no chão do fogo, do lado de quem espera com o espeto, até ir para o espeto (`cozinhar_espeto_4q` com o objeto `espeto`). Os caçadores repartem agachados. |

O lado da mata agora sai da saída (do fogo para o porco). Antes, no abate, ele era sempre para a direita.

O GIF `capturas/tarde-1x.gif` foi gravado em 1x, com a semente 7 e 13 dias, das 15h às 17h56, num quadro por segundo. Ele toca 4 vezes mais rápido. Nesse dia a caçada acerta. A semente 7 com 12 dias, usada na auditoria, erra.

## Auditoria 5 (tarde)

| # | O que foi feito |
|---|---|
| **T1** | A caçada usa as peças fortes: `cacar_espreitar_forte_4q` (agachado com a lança de 2 px à frente) na espreita e na ida, e `cacar_arremessar_forte_4q` no arremesso, com a roupa do estágio (3 a 6) e a de inverno. O arremesso segue a lança: ergue (quadro 0), segura a lança erguida (quadro 1) por cerca de 1 s, solta (quadro 2) e acompanha (quadro 3). A `lanca_voando_forte` sai da mão em arco raso entre 20% e 30% da etapa, e o porco só cambaleia quando ela chega (antes, ele já caía no início do arremesso). |
| **T4** | Pássaros pousados: até 4 ao mesmo tempo, um novo a cada 10 a 22 s de dia, 6 em cada 10 no alto dos telhados (contra o céu; os pontos saem da própria construção desenhada) e o resto no chão. Coelho de dia (8h30 às 17h), a cada 60 a 150 s: sai da borda de uma roça (sem roça, de uma ponta da vila), em chão aberto, e foge aos pulos para fora da vila. |

Captura: `capturas/auditoria5-cacada-e-bichos.png`. Em cima, a caçada da semente 7 às 15h em 1x: a espreita com a lança, a lança erguida, a lança voando até o porco e o caçador acompanhando. Embaixo, o pássaro no telhado e o coelho subindo o morro no mundo de 40 anos. O T3 (a volta pela vila e a repartição no fogo) espera a entrega da A.

## Auditoria 3c (interface)

| # | O que foi feito |
|---|---|
| **A2** | A `fonte_5x7_titulo` (vinho) entra em todo título sobre o pergaminho: o título do livro aberto, "Não resta ninguém", "Abandonar este mundo?" e o título novo da crônica. |
| **B1** | Sobre o acampamento ou a vila (até 24 px de uma fogueira ou construção), a dica diz "O acampamento de X" (estágio 1) ou "A vila de X", com a zona embaixo, e fica acima do cursor. |
| **B2** | A dica ganhou o bico (`dica_ponteiro`) na borda de baixo. Na dica de pessoa, ele aponta para a cabeça de quem ela descreve. |
| **B3** | Ao seguir: "Seguindo Loa, 25 anos" na alça, e o bico fica fixo sobre a cabeça de quem é seguido enquanto a câmera acompanha. |
| **B4** | A crônica tem título ("Crônica: A Primeira Era") e setinhas de 5 × 3 na tinta escura quando há mais texto acima ou abaixo. Continua abrindo no fim, onde está o mais recente. |
| **B5** | Com mais de um mundo na estante, a lombada diz o mundo e a era ("M2 EIII"); com um só, "ERA II". |
| **B6** | "Voltar" é o padrão, à esquerda, em caixa e letra dourada. "Abandonar" fica à direita, só sublinhado, e ganha caixa quando o cursor passa por cima. |
| **B7** | Sem ninguém vivo, o botão de seguir a linhagem sai da alça. |
| **B8** | Toda mensagem da alça começa com maiúscula, mesmo quando o texto vem do núcleo em minúscula. |

Capturas: `capturas/auditoria3c-interface.png` (crônica, livro, pergunta de abandono, estante com vários mundos, mundo vazio, dica da vila e seguir). O verificar.ps1 não rodou desta vez: a captura da área de trabalho falha com "Identificador inválido", o que indica tela bloqueada ou desligada. Fidelidade e céu sem grade não mudam com estes itens.

## Auditoria 3 (cotidiano) e 3b (estações)

| # | O que foi feito |
|---|---|
| **D1** | Ninguém fica parado com o centro a menos de 9 px do centro do fogo; quem cairia ali vai para o lado em que já estava. A roda (fogueira, jantar, atiçar, cochilar, histórias) olha para o fogo, e quem está à direita fica espelhado. |
| **D5 / E4** | A baforada nasce no fogo, sobe 6 a 10 px enquanto passa pelos 6 quadros e some. |
| **D7** | O mato cresce mais cedo: graus 1, 2 e 3 aos 2, 6 e 15 anos, muda aos 10 e árvore jovem aos 15. Vale também para as casas vazias de um povo vivo (`abandonada`, `anos`), que a A agora põe nas pontas da vila. |
| **D2** | Microanimações dos ociosos a cada 3 a 6 s, em 4 de cada 5 fatias (antes, 5 a 11 s e metade das fatias). |
| **Enchente** | As zonas alagadas pelo dilúvio ganham a água barrenta (`enchente_*`), num nível só por zona, sem parede de água nas encostas. A gota de chuva não fica mais desenhada dentro da terra nos quadros longos do 50x. |
| **E5** | No inverno, o lago congela nos 40 px junto da praia; no inverno rigoroso, inteiro. |
| **E6** | A roça (e o pomar) abre uma clareira: árvores e pinheiros com o tronco sobre ela saem. |
| **Encenações** | **Ações de 1x:** catar lenha, cesto na cabeça, pote d'água, buscar água, espantar e tropeçar, nas versões fortes, com a roupa do estágio do povo (`estagioN/`, e a de inverno pela estação). **Brincadeiras:** pega-pega correndo, com os papéis trocando, e ciranda parada. **Caçada por etapas** (API `etapas`): o porco fuçando enquanto espreitam; a lança voando em arco; o porco atingido e caído com o pau no chão (ou fugindo, com a lança cravada); uns amarram e outros comemoram; a volta com a caça no pau (forte) entre os dois. **Madrugada:** o fogo baixa para brasas (cena `brasas`), o vigia cochila, alguém boceja e atiça o fogo, e aparecem a coruja (de neve ou de chuva conforme o tempo), o morcego e o sapo (cena `bicho_noturno`; a raposa ainda não tem arte). **Balões de fala**, no máximo 3 de cada vez: conversa, história, pensamento (o vigia cochilando), coração (quem nina) e raiva (discussão, briga de crianças). Também: deitar à sombra, tecer, consertar, cozinhar, comer e ninar. |
| Prova de montagem | `ferramentas/referencia/` atualizada com a montagem nova da C (samambaia do D6): fidelidade de 0,00% de dia e 59 px à noite, como antes. |

GIFs em 1x, em trechos de 60 s de jogo de verdade: `capturas/tarde-1x.gif` (a partir das 15h, a caçada) e `capturas/madrugada-1x.gif` (a partir de 1h).

## Medição final do jogo completo

10 minutos por cenário (`ferramentas/rodar-medicoes.ps1`, resultados em `medicoes/*.json`), com 28 núcleos lógicos. A memória vai em três medidas; a coluna "Memória" do Gerenciador de Tarefas é o conjunto de trabalho privado.

| Cenário | CPU média | CPU (1 núcleo) | Pico de amostra | Gerenciador, média / máx. | Conjunto de trabalho, máx. |
|---|---|---|---|---|---|
| Normal, 1x (semente 7, ano 1) | 0,192% | 5,4% | 0,33% | 123 / 125 MB | 228 MB |
| 10x | 0,179% | 5,0% | 0,27% | 128 / 130 MB | 233 MB |
| 50x | 0,184% | 5,2% | 0,30% | 130 / 133 MB | 236 MB |
| Escondido | 0,008% | 0,2% | 0,05% | 102 MB | 203 MB |
| **Avançado:** 50x num mundo de 150 anos (estágio 6, 4 povos, ruínas, culturas) | 0,307% | 8,6% | 0,69% | 189 / 211 MB | 315 MB |

- A CPU fica abaixo de 1% em todos os cenários, até no mundo avançado a 50x.
- A memória cresce com o mundo: cerca de 125 MB no início e de 190 a 210 MB num mundo de 150 anos (coluna do Gerenciador). O usuário já aceitou passar dos 200 MB de conjunto de trabalho.

## Luz, inverno e agricultura (arte, seção 19)

- **Janelas acesas:** as camadas `_luz` das casas dos estágios 2 a 6 ficam numa camada própria, por cima das casas e sem a tabela de noite. Acendem das 17h30 às 6h30. De madrugada (23h às 4h30), só uma casa em cada três continua acesa.
- **Inverno:** as construções e ruínas de inverno entram sozinhas, porque a peça é procurada primeiro em `estacoes/inverno/`. As casas ganham a chaminé (`luzes/chamines.json`, por casa e telhado), e de cada uma sobe um fiapo de fumaça (`fumaca_chamine_4q`).
- **Pomar:** a árvore de fruta (`arvore_fruta`, nas 4 estações) fica ao lado de duas em cada três roças.
- **Roda d'água:** ao lado de cada roça irrigada, animada; no inverno, fica congelada pela própria arte.
- **Defeito antigo corrigido: a neve branqueava a tela inteira.** Em todo dia de neve, o mundo ficava branco. A importação de textura do Godot preenche a cor dos pixels transparentes com a vizinha (`fix_alpha_border`), e essa cor vazava na janela transparente. A folha da neve agora é limpa ao carregar (alfa pré-multiplicado). A auditoria não pegou porque nenhuma captura caiu num dia de neve. `FORCAR_NEVE=1` liga a neve para testar.
- Captura: `capturas/luzes-inverno-pomar.png` (inverno à noite e de dia, verão à noite, estágio 6). verificar.ps1 (19 de 19), fidelidade e céu sem grade passam.

## Auditoria 2 da sessão C (itens da B)

| # | Defeito | O que foi feito | Captura |
|---|---|---|---|
| **N1** | Construções sobrepostas | Cada construção ganha um lote pela largura real da peça (a arte é mais larga que a `largura` da API), com 3 px de folga e o menor deslocamento possível do `x` do núcleo; é o mesmo empacotamento das pessoas, agora com larguras diferentes. Nada vai para o lago. **Limite:** com 4 povos no estágio 6, a vila soma cerca de 780 px de peças para uns 340 px de terra. Aí a folga encolhe por igual e as peças se encostam um pouco, em vez de uma cobrir a outra inteira. Para sumir de vez, a A precisaria espalhar os lotes ou limitar construções por povo. | `auditoria2-lotes-e-multidao.png` |
| **N2** | Multidão cobrindo as construções | Fora da roda do fogo, aparecem até 28 parados. Os ociosos (parados sem cena, descansando, guardando, doentes) ficam "dentro de casa" primeiro, depois os outros sem cena; quem está numa cena sempre aparece. A roda do fogo tem duas fileiras, e o resto fica em casa. A escolha muda a cada dia. | idem |
| **N3** | Poeira do terremoto em placas | Cada nuvem de poeira fica no seu trecho, com altura, quadro inicial, deriva, duração e lado sorteados. | `auditoria2-seca-terremoto.png` |
| **N4** | Seca sem céu nem rachaduras | O gesto da seca amarela o céu na hora, por 4 a 10 horas de jogo conforme o grau; as rachaduras e o calor já vinham do gesto. | idem |
| **N5** | Corte reto no amanhecer | A frente da troca de horário no céu virou uma faixa pontilhada de 14 linhas que vai rareando, sem emenda. O teste do céu sem grade continua passando (96 de 96). | `auditoria2-amanhecer.png` |
| **N6** | Fiapos pontilhados soltos | O céu vivo usa as nuvens soltas da C (`arte/nuvens/`), em 3 tamanhos por camada. Cada nuvem anda numa vaga própria da sua camada e nunca encavala com a vizinha. A troca de clima (dia, entardecer, noite, tempestade, seca) só troca o desenho. | `auditoria2-nuvens-e-ceus.png` |
| **N7** | Presságio sem cometa nem eclipse | O cometa e o eclipse aparecem; a API dá cometa abaixo de 0,34 de intensidade, eclipse abaixo de 0,67 e luzes acima. A auditoria usou a intensidade máxima, ou seja, luzes, e elas viraram cortinas de brilho ondulando pelo céu. | `auditoria2-pressagios.png` |
| **N8** | Chuva com céu claro | Com chuva (do deus ou tempestade), o céu passa ao de tempestade, e no dilúvio, ao de dilúvio, de dia e no entardecer, com as nuvens de tempestade por cima. **Falta:** a enchente com os blocos `enchente_*` (a água subindo). | `auditoria2-nuvens-e-ceus.png` |

## Rotina nova (API v10 com `detalhe`)

- **Detalhes com arte própria** (LEIA-ME da arte, seção 20):
  - na coleta: colher no arbusto, cavar raiz e catar lenha;
  - na margem: buscar água e banho;
  - na roça: a enxada;
  - cozinhar: mexendo a panela ou girando o espeto, com o objeto diante de quem cozinha;
  - vigia: de madrugada, a cabeça pesa de sono;
  - roda de histórias: o primeiro da cena conta, de pé, e os outros ouvem sentados;
  - incidentes: tombo (cai, fica no chão e levanta), espantar, discussão, crianças brigando, criança perdida;
  - parados: comer, descansar, olhar o céu e o doente, sentados; guardar e repartir, agachados.
- **Andando:** o cesto na cabeça na volta, o cesto nas costas na ida e o cesto no quadril com água. Detalhe sem folha cai na folha da `acao`, como antes.
- **Caçada:** os caçadores espreitam agachados com a lança e, de vez em quando, arremessam. O bicho (porco do mato ou ave grande) fica no lugar da caça até ser abatido. Na volta, os dois carregadores levam a caça no pau, entre eles. No incidente `animal`, o bicho aparece onde a cena diz.
- **Vida ambiente:** porco do mato (borda da floresta e mato) e ave grande (campos e margem) de dia, além dos que já havia. Com eles, o mundo inteiro tem bicho.
- **Salvar:** o salvamento de cada dia usa `salvar_async()`, numa thread. Ao fechar e ao abandonar, continua o `salvar()` síncrono.
- **GIF:** `capturas/dia-inteiro-50x.gif`, um dia inteiro no 50x (das 5h às 5h, 55 s, 3 quadros por segundo, ampliado 2x).

## Ritmos 1x, 10x e 50x

| Ritmo | Hora de jogo | Um dia dura | Tecla |
|---|---|---|---|
| Pausa | — | — | 0 (e espaço) |
| Normal, 1x | 112,5 s | 45 min | 1 |
| 10x | 11,25 s | 4,5 min | 2 |
| 50x | 2,25 s | 54 s | 3 |
| Salto até o próximo acontecimento | — | — | S |

- **Alça:** cada ritmo tem o seu botão, com o atual marcado. O 10x usa o ícone `rapido` e o 50x o `rapido2`, da arte. A dica do botão diz o nome, a tecla e quanto dura um dia (`capturas/ritmos-alca.png`). A escala passou para Ctrl+2, Ctrl+3 e Ctrl+4.
- **Andar:** o passo acelera 2,5 vezes no 10x e 4 vezes no 50x (teto), e a animação das pernas acompanha. No 50x, o relógio anda de 10 em 10 minutos.
- **Persistência:** o ritmo fica no `moldura.cfg` e volta na abertura seguinte. Se a ausência passou de um dia real, o jogo abre no normal. `--ritmo=` ainda manda nos testes.
- **Medido no 50x** (`medicoes/rapido2.json`, 5 min): CPU de 0,171% em média (4,8% de um núcleo), pico de amostra de 0,23%, dentro da meta; 122 MB na coluna "Memória" do Gerenciador de Tarefas.
- O verificar.ps1 foi atualizado para a alça com 10 botões e passa nos 19 itens.

## Entrega da A: caçada perto da vila, troca de lugar, arquivo dos antigos

- **Caçada:** a encenação segue a posição nova (o porco a uns 20 px da borda, em x de 216 a 224). Como o chão ali já é aberto, a busca de chão aberto não mexe nele. GIF: `capturas/tarde-1x.gif`.
- **Bichos noturnos:** a coruja fica na copa mais perto do `x` que a API dá a ela (`fixo`). A raposa e o morcego vão de `x` a `x_fim` ao longo da cena; a raposa para, cheira e olha para trás a cada 7 s. GIF: `capturas/madrugada-1x.gif`.
- **Troca de lugar (N5), conferida:** um registro de teste (`REGISTRAR_LUGARES=1`) gravou, a cada 10 s, o x de cada parado na tela e o x que o núcleo dá. A tela fica a 1,4 px do núcleo em média, então ela segue a troca sem prender ninguém. Os ociosos (parado, conversa, fogo) mudaram de ponto a cada 10 a 20 s. Quem trabalha (colher, construir) e as crianças brincando ficam até 90 s no mesmo lugar: isso vem da rotina, que só move os parados.
- **Arquivo dos antigos, conferido** com um mundo de 371 anos salvo no caminho padrão, com `mundo.antigos.txt` e as cópias:
  - o jogo abre o mundo normalmente, e a crônica mostra os anos 369 a 371;
  - abandonar apaga o mundo, as cópias e o `mundo.antigos.txt`, e o livro "A Primeira Era, anos 1 a 371" vai para a estante;
  - a apresentação não lida com esse arquivo: tudo passa pela `Persistencia`.
  - Depois do teste, voltei a estante e o mundo salvo ao estado de antes. Captura: `capturas/mundo-371-anos.png`.
- O arquivo só aparece depois de mais de 300 linhas arquivadas; antes disso, elas vão dentro do próprio `mundo.txt`.

## Auditoria 4

| # | O que foi feito |
|---|---|
| **N1** | O abate da caçada fica em chão aberto: o bicho anda até o primeiro ponto, do lado dos caçadores, sem arbusto, capim ou pedra atrás. Quem amarra (o primeiro da cena) fica a 8 px dele, virado para ele; os outros, de pé com a lança erguida (`cacar_comemorar_4q`), a 12 a 20 px. O `pau_no_chao` fica do outro lado do bicho. Na espreita, os caçadores ficam agachados (`cacar_espreitar_4q`, também parados), e a lança voa num arco até o bicho. |
| **N2** | A coruja é presença fixa das 21h às 5h, com a base no topo da copa da árvore mais perto da vila (a primeira linha opaca da copa); usa a versão de neve no inverno e a de chuva com tempestade. A raposa (cena `bicho_noturno`) trota pela borda, para, cheira e olha para trás, vai e volta e espelha ao virar. |
| **N3** | Além das conversas, a cada 14 s alguém parado ou trabalhando (colher, construir, pescar, fogo...) solta um balão de fala por 2,5 s. Continua no máximo 3 de cada vez. |
| **N4** | Os pontinhos claros em arco eram a neblina da manhã: pixels soltos por ruído, numa faixa na altura do acampamento e por cima dele. Agora ela fica atrás da vila (antes do mundo) e é feita de fiapos horizontais de 4 a 7 px. |
| **N5** | Aguarda a troca de lugar da A para conferir na tela. |
| Correção | Algumas cenas têm `id` em texto, e a comparação com número quebrava; os ids passaram a ser comparados como texto. |

GIFs em 1x: `capturas/tarde-1x.gif` e `capturas/madrugada-1x.gif`; neblina em `capturas/auditoria4-neblina.png`. O verificar.ps1 segue sem rodar, porque a sessão do Windows continua bloqueada ("Backstop Window" sob o cursor).

## Exportação para Windows (preparo, sem baixar nada)

**Preset** (`jogo/export_presets.cfg`, "Windows"):
- executável portátil, com o pacote embutido (`embed_pck`), x86_64;
- ícone `arte/interface/icone_jogo.ico`;
- nome "Simulador de vida", versão 0.1.0.0;
- saída em `builds/Simulador de vida.exe`, pasta que o `.gitignore` da raiz já ignora.

O `.gitignore` da raiz ignorava os presets; o de `jogo/` abre uma exceção para este.

**O que vai junto:**
- **Recursos importados** (texturas, imagens, fontes `.fnt`, cena, scripts compilados): vão pelo filtro "todos os recursos". Os atlas da sessão C não são usados pelo jogo, que lê as peças de `jogo/arte/`, então não vão.
- **Arquivos que não são recursos:** entram pelo `include_filter`.
  - os JSON: layout, tabelas de luz, estrelas, chaminés, trocas;
  - a paleta (`arte/paleta.hex`);
  - o auxiliar do atalho global (`atalho/atalho_global.ps1`).
- **Ficam de fora:** capturas, medições, ferramentas, testes do núcleo (`ferramentas_sim/`) e os `.md`.

**Conferido sem os modelos de exportação:**
- O `--export-pack` gera só os dados (1,3 MB), e o jogo rodou só a partir desse pacote, numa pasta vazia, com mundo, alça, inverno e atalho global.
- O teste achou e corrigiu 2 defeitos:
  - a paleta (`.hex`) não entrava no pacote, e o jogo abria sem as trocas de cor e sem ícones;
  - o atalho global rodava o `.ps1` direto de `res://`, que no executável fica dentro do pacote. Agora o script é copiado para `user://` e roda de lá.
- Corrigido também: o auxiliar do atalho agora é encerrado em qualquer fechamento.

**O que falta baixar** (precisa da autorização do usuário):
- **Os modelos de exportação do Godot 4.7.2:** `Godot_v4.7.2-stable_export_templates.tpz`, cerca de 1 GB, com todas as plataformas. Pelo editor (Editor > Gerenciar modelos de exportação) ou pelo arquivo, em `%APPDATA%\Godot\export_templates.7.2.stable\`. Deles, o jogo usa só `windows_release_x86_64.exe` (e o `windows_debug_x86_64.exe`, para testes).
- Nada mais. O ícone e a versão entram sem o rcedit, porque o Godot 4.7 grava os recursos do executável sozinho (`application/modify_resources`). A assinatura de código fica desligada: sem ela, o Windows mostra o aviso do SmartScreen na primeira abertura.

**Depois de baixar:**

```
Godot --headless --path jogo --export-release "Windows"
```

O comando gera `builds/Simulador de vida.exe`.

## Primeira abertura: dicas na alça

Quem abre o jogo pela primeira vez aprende sozinho, sem manual. Ao lado da alça aparece uma dica discreta de cada vez, em letra dourada numa caixa escura, e ela some quando o jogador faz o que ela ensina. A próxima vem 4 s depois:

1. "Escolha um poder e segure sobre o mundo": some quando um poder é usado.
2. "Passe o cursor sobre as pessoas": some com a primeira dica de pessoa.
3. "C abre a crônica do mundo": some quando a crônica abre.
4. "0 a 3 mudam a velocidade do tempo": some com qualquer troca de ritmo.
5. "H esconde; o ícone fica na bandeja": some ao esconder.

Uma ação feita fora da ordem também conta, e a dica dela não aparece mais. O registro fica no `moldura.cfg`, em `[dicas] feitas`: conferido que, depois de usar um poder, ele grava `feitas=["poder"]`. O `_guardar_config` agora preserva o que já havia no arquivo. A mensagem de um aviso tem prioridade sobre a dica. Os testes com `--sem-config` não mostram as dicas, e `--primeira-vez` mostra todas desde o começo. O pergaminho de boas-vindas anterior saiu. Captura: `capturas/dicas-primeira-abertura.png`.

## Fase 2 na tela (API v6 a v10)

**Culturas nas construções.** Casas e templos se montam em camadas: a parede, o telhado e o símbolo da `aparencia` de cada construção (API v10; antes, a do povo). Os estágios 3 a 6 usam as camadas `_parede`, `_telhado_<t>`, `_base` e `_simbolo_<s>`, e o templo da escrita usa o telhado e o símbolo do templo de colunas, como pede a arte. Estágio 1, celeiro, forja, moinho, muralha e barco não têm variação e saem inteiros. A roupa de todo o povo é a cor da cultura: turquesa, rosa ou lilás. Captura: `capturas/fase2-culturas.png`.

**Fim do mundo.** O facho "os últimos" já existia. Quando chega `fim_do_mundo`, aparece um aviso no pergaminho, com a era que terminou, os anos e o livro que foi para a estante; ele some com um clique (`capturas/fase2-fim.png`). No mundo vazio, o botão de poderes vira **criar povo** (ícone novo). Com ele escolhido, um clique no mundo chama `criar_povo(x)`, e começa a era seguinte.

**Natureza retomando.** Cada ruína ganha mato pela idade: grau 1 aos 3 anos, grau 2 aos 10 e grau 3 aos 25. Uma muda nasce ao lado aos 15 anos, e uma árvore ou um pinheiro jovem aos 25. A fogueira de um povo de pedra em diante vira `fogueira_antiga`. O desenho fixo é refeito quando a natureza avança (`capturas/fase2-vazio.png`: um povo de pedra 20 anos depois).

**Estante de crônicas** (botão novo na alça e tecla E): fundo e prateleiras da arte, um livro por era, com a cor da lombada igual em todo o mundo (pela semente) e o nome ("ERA II") girado na etiqueta. Ao passar o mouse aparecem o título, o mundo e os anos. A era em curso fica por último, com uma fita dourada. O livro aberto pagina o texto em linhas de até 104 px e 10 linhas por página. O título vai em dourado, como pede a arte; os anos ficam na tinta escura, porque o dourado mal se lê no pergaminho. Para folhear: clicar na página, usar a roda ou as setas. O botão direito ou o Esc voltam. Capturas: `fase2-estante.png` e `fase2-livro.png`.

**Abandonar o mundo:** pelo botão da estante, depois de uma pergunta de confirmação (`fase2-abandonar.png`). A simulação chama `Persistencia.abandonar` e começa outro mundo com `Mundo.new`; a vida em cena e o desenho fixo recomeçam. Os mundos de teste (que não salvam) guardam os livros em `user://estante_teste`, para não misturar com a estante do jogador. `fase2-abandonado.png` mostra três livros: dois mundos abandonados e a era em curso.

**Correção que vale para toda a interface: o texto saía ampliado 1,45 vez.** O Godot desenhava as fontes 5x7 no tamanho padrão 16, e não no 11 do arquivo, então relógio, dica, crônica e mensagens ficavam fora da grade de pixels. Agora tudo usa o tamanho 11 e sai pixel a pixel, e a crônica passou a mostrar mais texto por linha (`fase2-cronica-fonte11.png`).

**Para testar:** `--extinguir[=N]` mata todos (e, com N, o mundo vazio anda N anos); `--demo=criar_povo:X:0:S`; `--abrir=estante|livro|abandonar|abandonado`. O verificar.ps1 foi atualizado para a alça mais larga (botão da estante) e passa nos 19 itens; a fidelidade e o céu sem grade continuam passando.

**Ícones novos:** `criar_povo` e `estante`, desenhados por `ferramentas/icones_fase2.py` com a paleta e o contorno dos outros. Se a sessão de arte entregar os seus, o sincronizar_arte os troca.

## Critérios de saída da fase 1

Conferidos um a um em 01/11/2026, com o código da branch `claude/fase0-moldura-e4e762` depois do céu vivo.

| # | Critério | Situação | Evidência |
|---|---|---|---|
| 1 | O jogo abre na moldura, cria o primeiro povo e roda sozinho. | **Atendido** | `ferramentas/verificar.ps1` passa inteiro: janela transparente, sempre por cima, clique atravessando, arrastar, escala, esconder e mostrar, e nitidez em 2x, 3x e 4x. Sem mundo salvo, o log mostra `[simulacao] novo ano=1 dia=1 hora=0`, e o tempo anda sozinho no ritmo normal. |
| 2 | Pessoas vivendo, preces como sinais e os 6 poderes por gesto, com reação do povo. | **Atendido** | Vida: `capturas/cotidiano-dia.gif` e `cotidiano-tarde.gif`, com agenda, ações, microanimações e cenas. Preces: `tarefa4-sinal-prece.png` e `tarefa4-dica-sinal.png`. Gesto: o `verificar.ps1` aperta, segura 1,5 s e solta sobre o céu, e o raio sai com intensidade 0,75, um milagre. Os 6 poderes, mais os 5 da fase 2, em `tarefa4-poder-*.png` e `auditoria-9-*.png`. A reação do povo vem do núcleo e aparece no aviso da alça e na crônica; os incêndios, por exemplo, derrubam cabanas e deixam a zona queimada. |
| 3 | Acompanhar uma linhagem e ler a crônica dentro do jogo. | **Atendido** | `tarefa4-seguir-linhagem.png` (a vista aproxima 2x e segue a pessoa, com paralaxe) e `tarefa4-cronica.png` (o pergaminho abre no fim). Clicar numa pessoa passa a acompanhá-la. |
| 4 | Fechar e abrir retoma o mundo, com a ausência e a crônica do período. | **Atendido** | Salvei (`salvo=true ... passo=13`), fechei e reabri (`carregado ... passo=13`). Com 30 h de ausência simulada (`--simular-ausencia=30`), passaram 40 dias, e a crônica abriu com o relato (`capturas/fase1-ausencia.png`). O jogo salva a cada dia de jogo e ao fechar. O mundo de teste foi apagado. |
| 5 | Leveza: CPU média abaixo de 2% e memória abaixo de 200 MB. | **Atendido, com a memória aceita pelo usuário** | CPU média de 0,15% a 0,19% da máquina nos cenários de 10 minutos e no céu vivo. Memória: 113 a 115 MB na coluna "Memória" do Gerenciador de Tarefas e cerca de 217 MB de conjunto de trabalho, com o executável do editor. O usuário aceitou a memória perto de 200 MB. |
| 6 | O visual em jogo parece a cena-alvo. | **Atendido** | `ferramentas/fidelidade.sh`: a montagem da cena-alvo no jogo bate pixel a pixel com a da arte de dia (0,00%), e de noite difere em 59 pixels (0,08%), nas bordas das cabanas, de propósito (item 13 da auditoria). O céu da noite e o do entardecer batem com a cena-alvo nas 60 linhas de cima (0,03% e 0,06%), e o teste do céu sem grade passa em 96 de 96. Comparações lado a lado: `correcao-*-vs-alvo.png` e `tarefa4-*-vs-alvo.png`. |

**Nada ficou faltando para a saída da fase 1.**

## Ajuste: pessoas no acampamento

**Antes:** à noite, o povo inteiro se amontoava sobre a fogueira.

**Agora:**
- **Roda da fogueira:** quem está `fogueira` ganha um lugar na roda, dos dois lados do fogo, a 11 px do centro e com 7 px entre vizinhos.
- **Os outros:** querem o x que o núcleo dá. Todos os que não dormem entram numa única fila empacotada, com 7 px entre vizinhos; blocos que se encostam se juntam e se centram nas posições desejadas.
- **Estabilidade:** a ordem segue o x desejado e o id, então ninguém troca de lugar entre quadros.
- **Margem:** ninguém fica à esquerda de x = 130, que é água.
- **Andar:** as pessoas andam até o lugar em velocidade de caminhada, igual para todos (9 px/s, ou 36 px/s no ritmo rápido). Assim, quem sai em fila chega em fila. O ritmo normal da API tem um passo a cada 112,5 s, e interpolar entre passos faria todos deslizarem.
- **Cabanas:** quem acorda junto sai da cabana em fila, com um pequeno atraso por pessoa.

**Medido** (`CONTAR_SOBREPOSICAO=1`, ritmo rápido, cerca de 2 dias de jogo, sementes 7 e 3, até 20 pessoas): conta quantas figuras cobrem a mesma coluna de pixels.
- **Pessoas paradas:** no máximo 1. Nunca há duas no mesmo pixel; vizinhas a 7 px, com sprites de 8 px, só encostam a borda.
- **Contando quem anda:** no máximo 4, por um instante, na volta do trabalho para a fogueira, quando as pessoas se cruzam porque a ordem na roda não é a mesma do trabalho.

Captura: `tarefa4-noite-vs-alvo.png` (20h).

## Tarefa 4: interação

| Item | Como funciona | Captura |
|---|---|---|
| **6 poderes por gesto** | Escolha o poder na alça e segure o botão sobre o mundo. A intensidade vai de 0 a 1 em 2 s, numa caixinha escura com o ícone e a barra de carga. Soltar chama `usar_poder(poder, x, intensidade)`. O botão direito cancela. O resultado aparece na alça: "Raio: um milagre sobre Doim". | `tarefa4-poder-*.png`, `sequencia-fogo/` |
| **Efeitos** | **Chuva:** nuvens, gotas e respingos, por 8 a 16 s conforme o grau. **Raio:** canal, impacto, poeira e clarão. **Fogo:** chamas, brasas e fumaça; depois a zona fica queimada, com terra queimada e árvores carbonizadas enquanto o núcleo marcar `queimada`. **Fartura:** aura e brilhos. **Erguer a terra:** terra subindo, poeira e depois a pedra erguida no lugar que o núcleo dá. **Sonho:** espiral e brilhos sobre a pessoa atingida. | |
| **Seletor de poder discreto** | A alça mostra só o poder escolhido e o ritmo atual. Clicar abre a fileira de opções, que se fecha depois da escolha. Os ícones ficam só sobre a madeira escura da alça ou numa caixa escura, nunca direto sobre o céu. | `tarefa4-alca-poderes.png` |
| **Dica do cursor** | **Pessoa:** nome, idade, traços, papel e a prece, com o ícone da necessidade. **Sinal:** quem reza, o texto e há quantos dias espera. **Lugar:** o nome da zona, os nomes dados pelos povos e o estado (seca, queimada, farta). Caixa e fontes da sessão C. | `tarefa4-dica-*.png` |
| **Sinais de prece** | Ficam sobre a cabeça de quem reza; se a pessoa dorme, acima da cabana. A intensidade segue a regra do orquestrador: comum até 10 dias, urgente até 30, desesperado acima disso ou com importância 8 ou mais. A prece banal é sempre comum. "Os últimos": facho sobre a vila enquanto restarem 5 pessoas ou menos. | `tarefa4-sinal-prece.png` |
| **Tempo** | Pausa, normal (112,5 s por hora de jogo), rápido (1,9 s) e salto até o próximo acontecimento de camada "nota" ou "chamado", com aviso do que houve. A barra de espaço pausa. | `tarefa4-salto.png` |
| **Seguir a linhagem** | O botão (ou L) aproxima a vista 2x e segue a pessoa acompanhada, com paralaxe nas montanhas e na mata. Se ela dorme, mira a cabana. Clicar numa pessoa sem poder escolhido passa a acompanhá-la (`acompanhar`). | `tarefa4-seguir-linhagem.png` |
| **Crônica** | O botão (ou C) abre o pergaminho com `cronica()`, no fim, onde está o mais recente; a roda do mouse rola. Ao voltar de uma ausência de 1 dia ou mais, abre sozinha com "Enquanto você esteve fora (N dias)" e o relato da ausência. | `tarefa4-cronica.png` |
| **Modo discreto e esconder** | D liga e desliga o modo discreto: o fogo e o raio do deus não mostram chamas nem impacto, e a crônica continua igual. H ou F8 escondem; também escondem o botão da alça, a bandeja e o atalho global opcional. | |
| **Salvar e carregar** | O jogo salva em `user://mundo.txt` a cada dia de jogo e ao fechar, e carrega com `carregar_e_avancar()` ao abrir. | |
| **Ícone** | O ícone da sessão C aparece na janela, na barra de tarefas (conferido na captura da barra) e na bandeja. O `.ico` está ligado para a exportação. | |
| **Céus da fase 2** | O `ceu_seca` substitui o céu de dia enquanto `clima.seca` for verdadeiro, e o `ceu_eclipse` por 3 horas depois de um evento `eclipse`. | |

**Verificação no Windows** (`jogo/ferramentas/verificar.ps1`, 19 de 19 itens; resultado em `capturas/verificacao.json`):
- os itens da moldura: transparência, sempre por cima, clique atravessando, arrastar, escala pela roda na alça, esconder e mostrar, nitidez em 2x, 3x e 4x;
- **o gesto real:** abre os poderes, escolhe o raio, segura 1,5 s sobre o céu e solta. Resultado: raio em x = 300, intensidade 0,75, um milagre.

**Teste de fidelidade** (`jogo/ferramentas/fidelidade.sh`): 0,00% de diferença com a montagem da arte, de dia e de noite.

**Teste de ausência:** salvei, fechei e reabri; o mundo voltou no mesmo passo. Depois, com 30 horas de ausência simulada (`--simular-ausencia=30`), passaram 40 dias e o relato abriu na crônica. Apaguei os arquivos de teste (`mundo.txt` e o `moldura.cfg` da tarefa 1) da pasta do jogo, para a primeira abertura do jogador começar do zero.

### Problemas encontrados e corrigidos

- **Clique duplo no Windows:** o Godot entrega um segundo "apertou", marcado como duplo, sem soltar no meio. Na alça, isso apertava o botão duas vezes; no gesto, reiniciava a carga. Agora o segundo evento é ignorado.
- **Pessoas na água:** o espalhamento empurrava gente para dentro da água. Agora existe a margem de x = 130.

### O que fica em aberto (decisão do orquestrador)

- **Clique numa pessoa:** sem poder escolhido, ele chama `acompanhar()`. Isso troca a linhagem no núcleo, então um clique distraído muda quem o jogador segue. Alternativa: pedir confirmação ou exigir clique duplo.
- **Os 5 poderes da fase 2** (seca, dilúvio, terremoto, presságio e cura) não estão na API. Só os céus de seca e de eclipse estão ligados. O núcleo já emite `cometa` e `terremoto`; os efeitos `cometa_4q` e fenda, poeira e pedras podem ser ligados quando o orquestrador quiser.
- **Poses:** `colher`, `rezar` e `sentado` só existem para o adulto A, então as mulheres aparecem com a silhueta dele. Os idosos não têm nenhuma das três. É assunto da sessão C.
- **Clique perdido:** numa rodada da verificação, o primeiro clique na moldura logo depois de um clique na janela de trás se perdeu. A janela-alvo, que não é o jogo, perdeu um clique do mesmo jeito noutra rodada. Num teste de 10 repetições, chegaram 10 de 10. Parece ser do clique sintético, não da moldura, mas convém observar no uso real.
- **Argumentos de teste**, que não são funções do jogo: `--demo`, `--dica`, `--abrir`, `--anos`, `--simular-ausencia`, `--capturar*`, `--quadros`, `--intervalo`, `--cena=layout`, `--efeito` e as variáveis `CONTAR_SOBREPOSICAO` e `DEPURAR_ALCA`.

## Correção do céu (grade de pontos)

**Causa:** nas horas de transição (5h–7h, 17h–18h, 19h–20h), o shader misturava os dois céus com pontilhado ordenado na tela inteira. No ritmo normal, cada transição dura cerca de 2 minutos reais, por isso a grade aparecia e sumia. A neblina noturna também desenhava pontos em grade na base das montanhas.

**Correção:**
- **Céu:** a troca de horário é uma frente (a noite desce do alto, a manhã sobe do horizonte), com pontilhado só numa faixa de 2 linhas.
- **Resto da cena:** montanhas, chão e pessoas trocam inteiros no meio da transição.
- **Neblina:** não existe à noite; de manhã, fiapos esparsos e irregulares (ruído fixo, não grade), num tom vizinho.

**Teste:** `ferramentas/ceu_sem_grade.py` captura a vista de meia em meia hora, o dia inteiro, com e sem chuva (96 capturas), e conta os pixels isolados do céu.
- **Reprova a versão antiga:** 22.212 pixels isolados às 19h30, contra um limite de 8.198.
- **Aprova a atual:** 96 de 96. À noite, o céu tem os mesmos 115 pixels isolados da cena-alvo.

## Vida em cena (API v8 e arte da seção 18)

Em `apresentacao/vida.gd`:

- **Agenda:** cada pessoa segue os trechos da hora (`x0` → `x1`, ação, para onde olha, cena).
  - Como a agenda espalha uma caminhada pelo trecho inteiro (uma hora são 112,5 s), a pessoa anda em passo natural até o destino, de 7 a 11 px/s conforme a pessoa, com pausas curtas no caminho. Lá, faz a ação até o trecho seguinte.
- **Ações e folhas** (mapa da seção 18):

  | Ação | Folha |
  |---|---|
  | andar | adulto A, adulto B ou idoso andando; as crianças correm |
  | colher | colher; com roça perto, enxada; na margem, pescar e segurar o peixe |
  | pescar | pescar e segurar o peixe |
  | lenha | carregar lenha |
  | construir, forjar, escrever, remar, lutar | a folha de mesmo nome |
  | rezar | rezar |
  | fogueira | sentado ou sentado no chão |
  | conversar | um fala e o outro ouve, alternando |
  | cuidar | mãe com bebê |
  | dançar | dançar; na festa, o primeiro participante toca o tambor |
  | carregar_morto | carregar no funeral |

- **Parado com vida:** microanimações de olhar para os lados, esticar, sentar no chão, agachar, coçar a cabeça e bocejar, em fatias de tempo irregulares e fixas por pessoa. O idoso fica apoiado na bengala, e as crianças pulam de vez em quando.
- **Cenas:**
  - **funeral:** dois carregadores com a mortalha por cima;
  - **festa e casamento:** dança, tambor e bandeirolas sobre a roda;
  - **migração:** trouxa e cesto;
  - **guerra:** o primeiro da cena leva o estandarte, e os outros lutam.
- **Ainda sem efeito na tela:** a cena `corvos` (ver "Criaturas"), as folhas dos estágios 3 a 6 (`estagioN/adulto_eN_*`) e o casal de mãos dadas.
- **Teste de sobreposição** (`CONTAR_SOBREPOSICAO=1`): entre os parados, no máximo 1 figura por coluna de pixels; com quem anda, no máximo 4 por um instante, quando as pessoas se cruzam.
- **Sequências:** `capturas/cotidiano-dia.gif` (9h) e `capturas/cotidiano-tarde.gif` (17h), cada uma com 15 s a 4 quadros por segundo.

## Estações e vida ambiente

- **Estações:** cada peça é procurada primeiro em `arte/estacoes/<estação>/` e, se não estiver lá, vale a de verão, como no `montar.py`. Isso vale para o terreno, a vegetação, as construções, as marcas, os planos de fundo e o céu. Os fundos da estação anterior são soltos na troca.
- **Inverno:** as 3 colunas de água mais perto da praia congelam (`gelo_superficie`), e cai neve em boa parte dos dias.
- **Outono:** folhas secas caem das copas.
- **Criaturas** (`apresentacao/criaturas.gd`), conforme a tabela de estação e horário da seção 17: bandos de pássaros, pássaro pousado, peixe saltando, sapo, garça na margem, coelho (que pula para longe de gente), cervo pastando no morro, morcegos ao entardecer e o bando migrando no inverno. Os corvos ainda não estão ligados à cena `corvos` da API.
- **Captura:** `capturas/estacoes.png` mostra primavera, verão, outono e inverno, nessa ordem.

## Memória: o que foi medido e o que foi feito

1. **Peças usadas só na CPU importadas como Image.** Terreno, peças, camadas, folhas de pessoas e estações (292 arquivos) eram importados como textura. Ler a imagem de volta criava uma textura no driver para cada um. Ganho de 9,5 MB em 3x: de 224,6 para 215,1 MB de conjunto de trabalho.
2. **Testes que não mudaram nada:**
   - reduzir o buffer de lote 2D, o atlas de sombras e a fila de mensagens;
   - pôr todas as pessoas numa folha só: só 1,4 MB, então um atlas de texturas renderia pouco.
3. **Contadores do Godot:** comparado ao protótipo da fase 0, o jogo tem 6,5 MB a mais de memória estática do motor, 3 MB de texturas e 3 MB de vídeo. O resto da diferença está fora do motor: driver, bibliotecas e sobra do heap depois da montagem.
4. **Correção de método:** desde a fase 0, chamei o conjunto de trabalho de "a Memória do Gerenciador de Tarefas", e isso está errado. A coluna "Memória" do Gerenciador de Tarefas é o conjunto de trabalho **privado**, que não conta as páginas compartilhadas do executável do editor. O `medir.ps1` agora grava as três medidas.

## Auditoria visual da sessão C (itens da B)

"Antes" são as capturas da auditoria, em `arte_claude/auditoria/`. "Depois" são as capturas em `jogo/capturas/auditoria-*.png`.

| Item | O que mudou | Depois |
|---|---|---|
| **1. Construções** | `apresentacao/obras.gd` liga `construcoes()` (tipo e estágio) às peças da arte: cabana, taipa, casa de pedra, enxaimel e tijolo; templo de cada estágio; celeiro; forja; arquivo; moinho; muralha; barco na linha d'água; roça (irrigada no estágio 6). As ruínas de `ruinas_visiveis()` ficam atrás. As variações de cultura (telhado e símbolo) ainda usam a peça de exemplo, porque a API não diz a cultura de cada povo. | `auditoria-1-mundo-60-anos.png`, `auditoria-1-mundo-150-anos.png` |
| **2. Gente sobre o lago** | Só quem `remar` fica sobre a água. Os outros têm o x preso à margem (x ≥ 130), inclusive nos trechos da agenda. | mundo de 150 anos |
| **3 e 4. Multidão e acampamento** | Com mais de 14 pessoas paradas, formam-se duas fileiras: uma meio passo atrás, 2 px acima e desenhada antes. A roda da fogueira pula as cabanas. A distribuição fina depende do x de descanso que a sessão A vai dar a cada pessoa. | `cotidiano-*.gif` |
| **6. Chuva** | Nuvens em duas camadas, com espaço, altura, quadro e lado irregulares, cobrindo o alto do céu sobre a chuva. | `auditoria-6-chuva.png` |
| **9. Os 5 poderes da fase 2** | Seca, dilúvio, terremoto, presságio e cura no seletor (ícones da C) e no gesto. Efeitos: seca (calor e rachaduras), dilúvio (chuva pesada), terremoto (tela tremendo, fenda, poeira e pedras), presságio (cometa, eclipse com o céu de eclipse, ou luzes) e cura (luz e brilhos). | `auditoria-9-*.png` |
| **10. Manhã** | A noite vira entardecer até as 6h30, e o dia só fica pleno às 8h. Às 7h há amanhecer. | `auditoria-10-manha-7h.png` |
| **12. Raio** | A descarga e o canal esfriando duram 0,6 s, o impacto 0,8 s e o clarão 0,12 s. | `auditoria-12-raio.png` |
| **13. Cabanas à noite** | As construções têm etiqueta própria e pegam um nível a menos de luz do fogo, então perdem o contorno néon. Por isso a fidelidade de noite com a montagem da arte passou de 0 para 59 pixels (0,08%), todos nas bordas das cabanas perto do fogo. | `auditoria-13-noite.png` |

**Também mudou:**
- **Inverno:** as pessoas usam o capuz e o manto da C.
- **Fumaça, mata e montanhas:** vêm da arte corrigida, sincronizada por `ferramentas/sincronizar_arte.py`.

## Relógio do mundo

- **Onde e como:** canto superior direito da faixa da alça, numa pastilha escura (`caixa_dica_9s`), com a fonte 5×7 clara (dourada à noite).
- **Minutos:** saem da fração da hora; no ritmo rápido, de 10 em 10; na pausa, parado; no salto, avançam junto.
- **Cursor por cima:** a dica mostra "Dia 12 do outono, ano 37".
- **Mouse:** a área do relógio entra no polígono de passagem do mouse.

## Céu vivo

O céu agora é só o degradê da arte: a faixa de 4 × 160 da sessão C, repetida na largura. Por cima dele, e atrás das montanhas, `apresentacao/ceu.gd` desenha:

- **Nuvens em 3 camadas de profundidade,** tiradas das nuvens da arte de cada horário por `ferramentas/preparar_ceu.py` e separadas pelo tamanho:
  - longe: fiapos e nuvens pequenas, 1 px a cada 20 s;
  - meio: 1 px a cada 8 s;
  - perto: as maiores, 1 px a cada 3 s.

  O vento muda de direção de um dia para outro e fica 4 vezes mais forte na tempestade. As nuvens saem por um lado e voltam pelo outro, com forma, altura e lado sorteados.
- **Sol e lua em arco, ligados ao relógio:** o sol nasce à esquerda às 6h, passa pelo alto ao meio-dia e se põe à direita às 18h, maior e dourado de manhã cedo e no fim da tarde. A lua faz o arco da noite, com fases num ciclo de 10 dias (nova, crescente, cheia e minguante). As posições ficam sempre em pixel inteiro.
- **Estrelas:** as 116 estrelas da arte surgem aos poucos das 19h às 21h, as mais fortes primeiro, e somem até as 5h30. O céu gira cerca de 6° ao longo da noite em volta de um ponto abaixo do horizonte. Quatro estrelas cintilam, e passa uma estrela cadente a cada 40 a 120 s.
- **Paralaxe:** ao seguir a linhagem, o céu fica quase parado (fator 0,05), as montanhas distantes andam devagar (0,35), as próximas um pouco mais (0,55), a mata mais rápido (0,8) e o mundo na velocidade normal.
- **Leveza:** só pede desenho quando algum pixel muda. A CPU ficou como antes: 0,149% ao meio-dia e 0,161% à noite, em 60 s, em 3x.
- **Testes:**
  - o teste de fidelidade continua usando o céu inteiro da arte;
  - o teste do céu sem grade passa em 96 de 96. Nas capturas com chuva, a margem é 600 pixels maior, porque as nuvens de chuva da arte têm pontilhado próprio e as gotas são pixels soltos. Conferi a olho: não há grade.
- **Capturas:** `capturas/ceu-vivo-7h.png`, `ceu-vivo-12h.png`, `ceu-vivo-18h30.png`, `ceu-vivo-2h-lua.png` e `ceu-vivo-rapido.gif`, este com 20 s no ritmo rápido.
- **Visto uma vez e não reproduzido:** numa captura, a vista saiu aproximada 2x sem estar seguindo a linhagem. Nas capturas seguintes, nos mesmos parâmetros, não se repetiu.

## Tarefa 5: leveza

**Método:** o mesmo da fase 0. `jogo/ferramentas/medir.ps1`:
- espera 10 s de aquecimento e depois lê, a cada 5 s durante 10 minutos, o tempo de CPU e a memória do processo;
- a CPU % é Δ tempo de CPU ÷ (Δ tempo real × 28 núcleos) × 100;
- usa o executável do editor; os modelos de exportação não foram autorizados;
- o mundo é novo, com a semente 7, começando às 17h, na escala padrão desta tela (3x, 144 dpi);
- os CSVs estão em `jogo/medicoes/`.

**Cenários:**
- **normal:** visível, ritmo normal;
- **rápido:** visível, ritmo rápido, com gente andando o tempo todo;
- **escondido:** minimizado.

**Medições de 10 minutos** (código de `f78be96`, peças de CPU importadas como Image, escala 3x):

| Cenário | CPU média (máquina) | % de 1 núcleo | Conjunto de trabalho (médio) | Gerenciador de Tarefas, "Memória" (médio) | Bytes privados (máx.) |
|---|---|---|---|---|---|
| normal | 0,164% | 4,6% | 216,9 MB | 113,3 MB | 217,3 MB |
| rápido | 0,185% | 5,2% | 215,6 MB | 112,3 MB | 215,3 MB |
| escondido, 6 min sozinho | ~0,014% | 0,4% | 199–200 MB | — | — |

**Leitura de 60 s com o código final** (construções, poderes, relógio), em 3x: 217,8 MB de conjunto de trabalho, 114,7 MB na coluna "Memória" do Gerenciador de Tarefas e 217,1 MB de bytes privados.

- **CPU:** muito abaixo da meta de 2% nos três cenários.
- **Memória:** depende de qual medida vale para a meta.
  - Na coluna "Memória" do Gerenciador de Tarefas, que é o que o usuário vê, o jogo usa cerca de 113 MB, abaixo de 200.
  - No conjunto de trabalho e nos bytes privados, usa cerca de 216 MB, acima de 200.
  - **Decisão do usuário (01/11/2026):** a memória acima de 200 MB no conjunto de trabalho pode passar.
- **Escondido nas medições em lote:** nas duas vezes, algo de fora restaurou a janela por volta de 150 a 250 s, e a CPU e a memória subiram ao nível do visível. O CSV de `escondido` registra isso. Rodando sozinho por 6 minutos, o cenário ficou minimizado o tempo todo, sem restaurações, com 199–200 MB e 0,4% de um núcleo.

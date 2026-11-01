# Relatório da apresentação (sessão B, fase 1)

Tarefas 1 a 5 do briefing `sessoes/fase1-b-apresentacao.md`. Este relatório cobre o ajuste das pessoas no acampamento e as tarefas 4 (interação) e 5 (leveza). As capturas estão em `jogo/capturas/`.

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

__TABELA__

__LEITURA__

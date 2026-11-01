# Relatório da fase 0: teste da moldura

**Pergunta:** a moldura funciona no Windows como companheiro de área de trabalho e é leve o bastante para ficar aberta o dia todo?

**Resposta curta:** sim. Transparência, sempre por cima, mouse atravessando, arrastar, escala inteira com pixels nítidos e esconder/mostrar funcionam no Godot 4.7.2 padrão, sem extensão. Com os 30 bonecos andando, a CPU média ficou em 0,053% (1,48% de um núcleo) e a memória em 180 MB, dentro das metas, mas com pouca folga de memória. Há três ressalvas, explicadas abaixo:

- esconder a janela exige minimizar;
- o ícone da bandeja vai para o menu de ícones ocultos do Windows 11;
- o atalho global só funciona com um processo auxiliar.

## Ambiente do teste

| Item | Valor |
|---|---|
| Sistema | Windows 11 Home Single Language, build 26200 |
| CPU | Intel Core i7-14700HX, 28 núcleos lógicos |
| Memória | 32 GB |
| GPU | NVIDIA GeForce RTX 4070 Laptop, driver 610.62 |
| Telas | principal 2560 × 1600 com escala de 150%; secundária 1920 × 1080 |
| Godot | 4.7.2 estável, executável do editor (`Godot_v4.7.2-stable_win64.exe`), sem exportar |
| Renderizador | Compatibilidade (OpenGL 3.3, `opengl3`) |

O executável do editor carrega mais código que um jogo exportado. Os números de memória abaixo são, portanto, um teto, e não o valor final.

## Como rodar

```
Godot_v4.7.2-stable_win64.exe --path prototipos/moldura
```

Argumentos opcionais, depois de `--`:

| Argumento | Efeito |
|---|---|
| `--cenario=andando\|parado\|escondido` | estado inicial (padrão: andando) |
| `--escala=2\|3\|4` | escala inicial (padrão: 2) |
| `--pos=X,Y` | posição da janela (padrão: canto inferior direito) |
| `--duracao=S` | fecha sozinha depois de S segundos |
| `--sem-foco` | a janela nunca recebe o foco do teclado |
| `--atalho-global[=TECLA]` | liga o atalho global Ctrl+Alt+TECLA (padrão: H) |

**Controles**

| Onde | O que fazer | Efeito |
|---|---|---|
| Alça (no topo, à esquerda) | arrastar pelos pontinhos | move a janela |
| Alça | botões `−` e `+`, ou roda do mouse | troca a escala (2x, 3x, 4x) |
| Alça | botão `_` | esconde a moldura |
| Céu | clicar | faz chover sobre o ponto |
| Teclado, com a moldura em foco | `H` ou `F8` | esconde |
| Teclado, com a moldura em foco | `2`, `3`, `4` | troca a escala |
| Teclado, com a moldura em foco | `Espaço` | para ou solta os bonecos |
| Teclado, com a moldura em foco | `Ctrl+Q` | fecha |
| Ícone na bandeja | clique esquerdo | mostra ou esconde |
| Ícone na bandeja | clique direito | fecha |
| Barra de tarefas | botão da moldura | mostra de novo |

## Critérios de aceite

| Critério | Situação |
|---|---|
| Janela transparente fora da área do mundo e sempre por cima | **atendido** |
| Clicar fora da área do mundo atinge a janela de trás | **atendido** (clique real contado pela janela-alvo) |
| Arrastar e redimensionar funcionam, com pixels sempre nítidos | **atendido** (100% de blocos de cor única em 2x, 3x e 4x) |
| Com 30 bonecos andando, CPU média abaixo de 2% e memória abaixo de 200 MB | **atendido**: 0,053% de CPU e 179,7 MB no máximo. Ressalva: a folga de memória é de cerca de 20 MB, e no cenário parado houve um pico isolado de memória privada de 209,9 MB (conjunto de trabalho de 195,5 MB). |

## Como foi construída

- **Tela base de 480 × 176:** uma faixa transparente de 16 pixels no topo, só com a alça, e o mundo de 480 × 160 embaixo. A faixa existe para que haja área transparente de verdade onde testar o clique atravessando.
- **Escala inteira por construção.** O projeto usa o modo de ampliação `viewport` com escala `integer`: o Godot desenha na resolução base e amplia sem filtro. A janela tem sempre exatamente base × k (k = 2, 3 ou 4), e é o código que muda o tamanho. Não há borda de redimensionar livre, então não existe tamanho que distorça os pixels.
- **Passagem do mouse:** `DisplayServer.window_set_mouse_passthrough` recebe um polígono que cobre o mundo e a alça. Ele é refeito a cada troca de escala e ao mostrar a janela de novo.
- **Arrastar:** `Window.start_drag()`, o arraste nativo do Windows.
- **Leveza:**
  - `max_fps = 30` e modo de baixo consumo (`low_processor_mode`), que só desenha quando algo pede.
  - Os bonecos andam em passos de 1 pixel a 12 Hz. O céu é recalculado 2 vezes por segundo, com cores quantizadas, e só pede desenho quando alguma faixa muda de cor.
  - Áudio desligado (driver `Dummy`).
  - `keep_screen_on` desligado, para não impedir o monitor de dormir.
- **Escondida:** a janela minimiza, `RenderingServer.render_loop_enabled = false` e `max_fps` cai para 12. O mundo continua avançando, mas nada é desenhado.

## O que funcionou e o que não funcionou no Windows

Verificado de forma automática por `ferramentas/verificar.ps1`. O script põe uma janela-alvo atrás da moldura, lê o estilo da janela, consulta `WindowFromPoint`, faz cliques e arrastes reais com o mouse e compara capturas de tela pixel a pixel. Resultado em `capturas/verificacao.json`; as imagens estão em `capturas/`.

| Item | Resultado | Evidência |
|---|---|---|
| Sem borda e fundo transparente | funciona | Na faixa transparente, 100% dos pixels da captura são iguais ao fundo sem a moldura. No mundo, 100% são diferentes. |
| Sempre por cima | funciona | O estilo estendido da janela tem `WS_EX_TOPMOST`. A moldura fica sobre as outras janelas, inclusive a que está em foco. |
| Mouse atravessa fora do mundo | funciona | `WindowFromPoint` na faixa transparente devolve a janela de trás. Um clique real ali chegou à janela-alvo (1 clique contado). Um clique no chão do mundo não chegou ao alvo. |
| Só o mundo recebe cliques | funciona | O clique no céu fez chover (registrado no log; ver `capturas/chuva.png`). |
| Arrastar pela alça | funciona | Um arraste de (120, 60) moveu a janela exatamente (120, 60). |
| Redimensionar em escala inteira | funciona | O botão `+` levou a janela de 960 × 352 para 1440 × 528. A passagem do mouse foi refeita na nova escala. |
| Pixels nítidos | funciona | Em 2x, 3x e 4x, 100% dos blocos k × k do mundo têm uma cor só. |
| Esconder | funciona, com ressalva | Ver "Limitações", item 1. |
| Mostrar pelo ícone da bandeja | funciona, com ressalva | Testado à mão: abrir o menu de ícones ocultos e clicar no ícone. Ver "Limitações", item 2. |
| Mostrar pela barra de tarefas | funciona | A janela volta na mesma posição e escala, e a passagem do mouse continua certa. |
| Atalho com a moldura em foco | funciona | `H` ou `F8` esconde. Mas não serve para mostrar, porque uma janela escondida não recebe teclado. |
| Atalho global | não existe no Godot; funciona com processo auxiliar | Ver "Limitações", item 3. |

## Medições de CPU e memória

**Como medi:** `ferramentas/medir.ps1` abre a moldura no cenário pedido e espera 10 s de aquecimento. Depois, durante 10 minutos, lê a cada 5 s, pelo `System.Diagnostics.Process` do .NET:

- o tempo de CPU acumulado do processo (`TotalProcessorTime`);
- o conjunto de trabalho (`WorkingSet64`, a "Memória" do Gerenciador de Tarefas);
- a memória privada (`PrivateMemorySize64`).

A CPU % é Δ tempo de CPU ÷ (Δ tempo real × 28 núcleos lógicos) × 100, a mesma conta do Gerenciador de Tarefas. A tabela também mostra a % de um núcleo, para comparar com máquinas de menos núcleos. As amostras estão em `medicoes/*.csv` e os resumos em `medicoes/*.json`. Os três cenários rodaram em sequência por `ferramentas/rodar-medicoes.ps1`, com a moldura em 2x no canto inferior direito da tela principal.

O que cada cenário significa:

- **parado:** moldura visível, bonecos parados. Só o céu muda.
- **andando:** moldura visível, 30 bonecos andando.
- **escondido:** moldura minimizada. Os bonecos continuam andando na lógica, sem desenho.

| Cenário | CPU média (máquina, 28 núcleos) | CPU média (% de 1 núcleo) | Maior amostra de 5 s | Conjunto de trabalho, médio / máximo | Memória privada, máxima |
|---|---|---|---|---|---|
| parado | 0,019% | 0,52% | 0,122% | 184,3 / 195,5 MB | 209,9 MB |
| andando (30 bonecos) | **0,053%** | 1,48% | 0,156% | **179,5 / 179,7 MB** | 167,6 MB |
| escondido | 0,027% | 0,76% | 0,133% | 177,0 / 180,0 MB | 166,8 MB |

Meta: CPU média abaixo de 2% e memória abaixo de 200 MB.

**Leitura:**

- **CPU:** muito abaixo da meta nos três cenários. Mesmo contada como % de um único núcleo, fica abaixo de 2%. Numa medição de teste de 45 s, o cenário andando deu 0,11% (3,2% de um núcleo), então a variação entre execuções é de cerca de 2x. Ainda assim, folga grande.
- **Memória com os bonecos andando:** estável em 179,6 MB por 10 minutos, sem crescer. Fica dentro da meta, mas com só cerca de 20 MB de folga. Quase tudo é custo fixo do motor e do driver OpenGL da NVIDIA, não do mundo: a cena é mínima.
- **Degrau de memória no cenário parado:** por volta de 4 minutos, a memória privada subiu de 167 MB para 192 MB e uma amostra isolada chegou a 209,9 MB. Depois ficou parada em 183 MB até o fim. O conjunto de trabalho chegou a 195,5 MB. Não há crescimento contínuo, então não parece vazamento; o mais provável é uma alocação do motor ou do driver. Mas é um sinal de que a folga de memória é pequena. Pelo conjunto de trabalho, que é a "Memória" do Gerenciador de Tarefas, todos os cenários ficaram abaixo de 200 MB. Pela memória privada, o cenário parado passou em um pico.
- **Escondida:** fica perto de 0%, mas não zera: 0,027% da máquina. O laço principal do motor continua girando a 12 quadros por segundo para a lógica do mundo seguir, como pede o documento técnico ("só a simulação, sem desenhar"). O custo que resta é desse laço, não do desenho; na fase 1, uma simulação a 1–2 Hz quando escondida reduziria ainda mais.
- **Parado contra andando:** o modo de baixo consumo funciona. Com só o céu mudando, o motor quase não desenha, e a CPU cai a cerca de um terço.

**Fora da conta:** o `dwm.exe`, que compõe a janela transparente na tela, não pôde ser lido sem permissão de administrador. O custo de composição de uma janela pequena e quase sempre parada deve ser baixo, mas não foi medido.

**Memória por renderizador**, com a mesma cena, cerca de 15 s depois de abrir:

| Driver | Conjunto de trabalho | Privada |
|---|---|---|
| OpenGL 3 (escolhido) | 179 MB | 168 MB |
| OpenGL via ANGLE (Direct3D 11) | 189 MB | 164 MB |
| Direct3D 12 (Mobile) | 323 MB | 315 MB |
| Vulkan (Mobile) | 617 MB | 877 MB |

O renderizador de Compatibilidade é o único que cabe na meta de 200 MB. Os renderizadores Forward+ e Mobile devem ficar de fora do jogo.

## Limitações encontradas

1. **`Window.visible = false` não esconde a janela principal no Windows.** Ela some da tela, mas continua lá, invisível, segurando os cliques na área do mundo, o que é pior que não esconder. A solução usada foi **minimizar**. Efeito colateral: a moldura tem botão na barra de tarefas, com o ícone do Godot, o tempo todo. Isso tem um lado bom: é um segundo caminho para mostrar a moldura de novo, e funciona.
2. **O ícone da bandeja (`StatusIndicator`) vai para o menu de ícones ocultos ("^") no Windows 11.** É o padrão do sistema para ícones novos. Mostrar a moldura custa então dois cliques, a menos que o jogador fixe o ícone na barra (Configurações → Personalização → Barra de tarefas → Outros ícones da bandeja). Além disso, `StatusIndicator.get_rect()` devolve o retângulo da seta, não o do ícone. O clique esquerdo alterna e o direito fecha. Não usei menu de contexto, porque o `PopupMenu` viraria uma subjanela dentro da moldura.
3. **Atalho global: o Godot não tem API para isso.** Procurei na referência de classes do 4.7.2 (`--doctool`) e não há nada parecido com `RegisterHotKey`. Um atalho comum só funciona com a moldura em foco, então serve para esconder, mas nunca para mostrar.
   - **Implementado como opção (`--atalho-global`):** um processo auxiliar em PowerShell (`atalho/atalho_global.ps1`) registra Ctrl+Alt+H no Windows e avisa a moldura por um pipe (`OS.execute_with_pipe`). Funciona com outra janela em foco e não usa nada além do que vem no Windows. Custa cerca de 77 MB a mais de memória (um `powershell.exe` com .NET carregado), com CPU praticamente zero, e fecha sozinho quando a moldura fecha.
   - Nesta máquina, **Ctrl+Alt+M já estava registrado por outro programa**. Qualquer atalho global precisa ser configurável e avisar quando não conseguir registrar.
4. **Clicar no mundo tira o foco do programa em que o jogador está trabalhando.** O clique no céu ativa a moldura, e o teclado deixa de ir para o editor de texto, por exemplo. `--sem-foco` (`Window.unfocusable`) evita isso, mas aí os atalhos de teclado da moldura deixam de funcionar. Testado: com `--sem-foco`, o clique no céu faz chover e o foco continua na outra janela.
5. **Escala de tela:** o Godot informa escala 1,0 nesta tela de 150%, e a janela é medida em pixels físicos. Por isso, 2x aqui ocupa 960 × 352 pixels físicos, que é pequeno numa tela de alta densidade.
6. **Redimensionar é por botões, roda e teclado, não pela borda.** Uma janela sem borda não tem borda de redimensionar do sistema, e o arraste livre teria de ser arredondado para a escala inteira mais próxima. Ficou de fora porque os botões resolvem.
7. **Os números são do executável do editor, numa máquina forte.** Num notebook comum, a % de CPU sobe na proporção dos núcleos. Pela coluna "% de 1 núcleo" (1,48% no cenário andando), mesmo uma máquina de 4 núcleos com metade da velocidade ficaria por volta de 0,75%.

## Recomendações para a fase 1

1. **Manter** o renderizador de Compatibilidade (`opengl3`), o modo `viewport` com escala `integer`, a janela de tamanho base × k definida pelo código e o polígono de passagem do mouse refeito a cada mudança.
2. **Esconder = minimizar** e desligar o laço de desenho. Ficam três caminhos para mostrar de novo: o ícone da bandeja, o botão da barra de tarefas e o atalho global.
3. **Desenhar só quando algo muda.** O ganho entre "andando" e "parado" mostra que o modo de baixo consumo funciona. A fase 1 deve manter a lógica em passos fixos e pedir desenho só quando um pixel muda. Animações a 12 Hz combinam com pixel art e custam pouco.
4. **Atalho global:** decidir entre duas opções.
   - **(a)** O processo auxiliar em PowerShell. Pronto e sem dependências, mas custa cerca de 77 MB e estoura a meta de 200 MB se for somado à moldura.
   - **(b)** Uma GDExtension mínima em C++ que chame `RegisterHotKey` dentro do próprio processo. Fica sem memória extra, mas exige compilador e quebra a regra de "nenhuma extensão".
   - Minha recomendação: (a) desligado por padrão na fase 1, e reavaliar (b) se o atalho global virar essencial.
5. **Medir de novo com um executável exportado** (modelo de exportação de lançamento), que deve usar menos memória que o editor. Os modelos de exportação não estão instalados. Baixá-los (cerca de 1 GB) precisa de autorização.
6. **Escolher a escala inicial pela densidade da tela** (`DisplayServer.screen_get_dpi`), para a moldura não nascer minúscula em telas de alta densidade.
7. **Foco:** testar na fase 1 um modo em que o clique no mundo não roube o foco, com os atalhos ficando só no atalho global e na bandeja.
8. **Primeira execução:** avisar o jogador que o ícone está no menu de ícones ocultos e sugerir fixá-lo.

# Simulador de vida — documento técnico

*Versão inicial em 31/10/2026. Complementa o documento funcional (`prompt-funcional-simulador-de-vida.md`), que define o que o jogo é. Este documento define como construí-lo.*

## Decisões de produto

| Tema | Decisão |
|---|---|
| Plataforma | Windows 10 e 11, 64 bits |
| Distribuição | Gratuita, como executável portátil (sem instalador obrigatório) |
| Dependências externas | Nenhuma: sem internet, sem serviços, sem modelo de linguagem |
| Construção | Tudo por IA: sessões do Claude Code orquestradas pelo Claude, e arte feita pelo Codex |
| Estilo visual | Pixel art 2D, corte lateral (diorama) |
| Motor | Godot 4.7.2, versão padrão (GDScript), sem .NET |
| Idioma | Português do Brasil |

## Ambiente

- Godot 4.7.2 instalado via winget. O comando `godot` **não** está no PATH (o winget não criou o atalho sem privilégio de administrador). Use o caminho completo:
  - console (para rodar sem gráfico e ver a saída): `C:\Users\sergi\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
  - com janela: o mesmo caminho, arquivo `Godot_v4.7.2-stable_win64.exe`
- Python 3.12 (usado pelo Codex para gerar a arte por código).
- Git.

## Arquitetura

### Simulação separada da apresentação

- **Núcleo de simulação** em GDScript puro, sem depender de cenas, nós ou gráficos. Ele recebe o tempo e os comandos do deus e devolve o estado do mundo e uma lista de eventos.
- **Apresentação** (moldura, sprites, sons) só lê o estado e os eventos. Nunca decide nada.
- **Determinismo:** a simulação usa uma semente de aleatoriedade própria. A mesma semente com os mesmos comandos produz o mesmo mundo. Isso permite testar, reproduzir problemas e comparar versões.
- O núcleo roda **sem gráfico** (`godot --headless`). É assim que roda o protótipo das histórias e o avanço durante a ausência.

### Tempo

| Grandeza | Valor |
|---|---|
| Passo de simulação | 1 hora de jogo |
| Dia de jogo | 24 passos, cerca de 45 minutos reais no ritmo normal (um passo a cada ~1,9 s) |
| Ano de jogo | 40 dias (4 estações de 10 dias) = 960 passos |
| Teto da ausência | 1 ano de jogo = 960 passos |

- As velocidades maiores só aceleram os passos. A simulação é a mesma.
- A apresentação interpola os movimentos entre passos, para que as pessoas andem suavemente.
- **Avanço durante a ausência:** ao abrir, o jogo calcula o tempo real desde o último fechamento e roda os passos que faltam, até o teto, sem gráfico. Meta: um ano de jogo em poucos segundos.

### Eventos: a fonte de todas as histórias

Tudo o que é significativo gera um **evento estruturado**: tipo, quem participou, onde, quando e a causa (natural, social ou divina).

A partir dos eventos saem:
- a **memória do mundo** (nomes de lugares, rancores, costumes);
- a **crônica**;
- as **preces** (pedidos ligados a necessidades e eventos);
- os **chamados** na moldura.

Nenhuma dessas partes inventa fatos. Todas leem os mesmos eventos.

### Texto sem modelo de linguagem

- Crônica, preces e nomes do deus são gerados por **gramática de frases**: modelos de frase com variações, preenchidos com dados dos eventos.
- A gramática trata a **concordância de gênero e número** do português.
- Nomes de pessoas e lugares saem de **conjuntos de sílabas por cultura**, de modo que cada cultura tenha sonoridade própria.

### Persistência

- O mundo é salvo localmente na pasta de dados do usuário (`user://`), em arquivo de texto legível.
- Salva automaticamente a cada dia de jogo e ao fechar.
- O arquivo guarda a hora real do último salvamento, para calcular a ausência.
- As crônicas de mundos e eras anteriores ficam em arquivos próprios, na estante.

### Moldura

- Janela **sem borda, transparente, sempre por cima** das outras.
- O mouse **atravessa** as áreas transparentes. Só a área do mundo recebe cliques.
- Pode ser **arrastada e redimensionada**. A escala do pixel art é sempre um número inteiro (2x, 3x, 4x) para não distorcer os pixels.
- **Atalho para esconder** a moldura na hora.

### Resolução e arte

| Item | Tamanho |
|---|---|
| Área base do mundo | 480 × 160 pixels (proporção 3:1), exibida em escala inteira |
| Bloco de terreno | 8 × 8 pixels |
| Habitante | 8 × 12 pixels |
| Construções | múltiplos de 8, de 16 × 16 (cabana) a 32 × 32 (templo) |
| Paleta | fixa, 32 cores, definida no guia de estilo |

- **Profundidade em camadas:** 3 planos (fundo, meio, frente).
- **Céu desenhado por código:** gradiente que muda com o dia, a noite e o clima. Não é arte pronta.
- **Culturas por peças modulares:** telhado, parede, cor e símbolo combinados, para muitas variações com pouca arte.

### Atmosfera feita por código

Boa parte da beleza do jogo não vem dos sprites, mas de efeitos desenhados pelo motor. Eles são código, não arte do Codex:
- **céu** em degradê com pontilhado (dithering), nuvens em movimento e cores que mudam com a hora e o clima;
- **reflexo na água** do céu, das pessoas e do fogo, com leve ondulação;
- **luz do fogo à noite:** brilho ao redor de fogueiras e tochas, que ilumina quem está perto;
- **neblina** nos planos de fundo de manhã e à noite;
- **paralaxe** entre os 3 planos quando a vista se move;
- **partículas:** chuva, faíscas, fumaça, folhas, vagalumes;
- **clima na tela:** o clarão do raio, o escurecer da tempestade, o calor da seca.

Esses efeitos são feitos com shaders simples e baixo custo, respeitando a meta de leveza.

### Leveza (meta para rodar o dia todo)

| Medida | Meta |
|---|---|
| CPU com a moldura visível | média abaixo de 2% num computador comum |
| CPU com a moldura escondida | perto de 0% (só a simulação, sem desenhar) |
| Memória | abaixo de 200 MB |
| Quadros por segundo | no máximo 30, e menos quando nada se move |

## Estrutura de pastas

```
SimuladorVida/
├── prompt-funcional-simulador-de-vida.md   documento funcional
├── tecnico-simulador-de-vida.md            este documento
├── codex/                                  canal com o Codex (tarefas, status, guia de estilo, controle)
├── arte/                                   arte entregue pelo Codex, com o script gerador ao lado de cada PNG
├── sessoes/                                briefings das sessões do Claude Code
├── prototipos/
│   ├── simulacao/                          sessão A: simulação só em texto
│   └── moldura/                            sessão B: teste da moldura
└── jogo/                                   projeto Godot definitivo (a partir da fase 1)
```

## Fases

### Fase 0: testes de risco (em paralelo)

| Frente | Quem | Pergunta que responde |
|---|---|---|
| A. Simulação em texto | Sessão do Claude Code | A simulação produz histórias que valem a pena ler? |
| B. Moldura | Sessão do Claude Code | A janela transparente funciona no Windows e é leve o bastante? |
| Arte inicial | Codex | O Codex produz pixel art consistente dentro do guia de estilo? |

Os briefings estão em `sessoes/` e as tarefas de arte em `codex/tarefas.md`.

**A fase 0 termina quando:**
- a crônica de 100 anos de mundo for interessante de ler em pelo menos 2 de 3 sementes;
- a moldura atingir as metas de leveza;
- as primeiras peças de arte forem aprovadas.

### Fase 1: menor conjunto que entrega a essência

O núcleo de simulação da sessão A e a moldura da sessão B são unidos no projeto `jogo/`, com a arte aprovada, até cobrir o menor conjunto definido no documento funcional.

### Fase 2 em diante

O restante do modelo funcional: os 11 poderes, as culturas completas, o progresso até o estágio 6, o fim do mundo e a estante de crônicas.

## Orquestração

- **Claude (orquestrador):** divide o trabalho, escreve os briefings e as tarefas, revisa entregas, junta as partes e mantém este documento atualizado.
- **Sessões do Claude Code:** cada uma trabalha só na própria pasta e entrega um relatório no fim.
- **Codex:** produz arte a partir de `codex/tarefas.md`, responde em `codex/status.md` e para quando `codex/controle.md` contiver `Desligar_Codex = True`. O protocolo completo está em `codex/LEIA-ME.md`.
- **Versão:** o projeto usa git. Cada sessão trabalha em pasta própria para que nunca duas mexam nos mesmos arquivos.

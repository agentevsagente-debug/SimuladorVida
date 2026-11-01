# Sessão A — simulação só em texto

## Objetivo

Responder à pergunta mais arriscada do projeto: **a simulação produz histórias que valem a pena ler?**

Você vai construir o primeiro núcleo da simulação, sem nenhum gráfico, e fazê-lo escrever a **crônica de 100 anos** de um mundo. O código não é descartável: ele é a semente do núcleo que o jogo vai usar.

## Leia antes

1. `prompt-funcional-simulador-de-vida.md`: o modelo funcional completo. É a fonte de verdade sobre o que o jogo é.
2. `tecnico-simulador-de-vida.md`: em especial "Simulação separada da apresentação", "Tempo", "Eventos" e "Texto sem modelo de linguagem".

## Regras do ambiente

- Trabalhe **somente** em `prototipos/simulacao/`. Não edite nenhum outro arquivo do projeto.
- Godot 4.7.2, versão padrão, GDScript. Sem .NET, sem extensões, sem dependências externas.
- O núcleo é **GDScript puro**: classes `RefCounted` ou `Resource`, sem nós de cena, sem gráficos. Ele precisa poder ser copiado depois para o projeto do jogo sem mudanças.
- Rode tudo sem gráfico: `<godot_console> --headless --path prototipos/simulacao --script <script>`. O comando `godot` não está no PATH. O caminho completo do executável de console está na seção "Ambiente" do documento técnico.
- Simulação **determinística**: semente própria (`RandomNumberGenerator` com semente fixa). Mesma semente, mesmo mundo.

## Escopo

Implemente o essencial do modelo funcional, em versão simplificada:

**Mundo**
- Região com zonas: praia, lago, floresta, morro. Cada zona tem recursos (comida, água, madeira) que se renovam por estação.
- Tempo: passo de 1 hora de jogo, dia de 24 passos, ano de 40 dias com 4 estações.
- Eventos naturais: seca, tempestade, inverno rigoroso, doença.

**Pessoas**
- Começo: 12 coletores no estágio 1, uma família estendida.
- Cada pessoa tem nome, idade, sexo, família, 2 traços (de uma lista de 8 a 10: ambicioso, pacífico, rancoroso, curioso, devoto, desconfiado, generoso, engenhoso...) e memória dos eventos que viveu.
- Necessidades: comida, abrigo, relações.
- Ciclo de vida: nascimento, crescimento, casamento, envelhecimento, morte.

**Sociedade**
- Grupos se separam: uma migração ou uma briga funda um segundo grupo em outra zona.
- Conflito entre grupos por recursos.
- Progresso simples: um grupo pode chegar ao estágio 2 (agricultura) por necessidade e por pessoas engenhosas. O conhecimento pode se perder se quem o detém morrer sem ensinar.

**O deus e a religião**
- Poderes como comandos de cenário: chuva, raio, fartura, fogo, erguer terra e sonho. Um arquivo de cenário diz o que o deus faz e quando (exemplo: "ano 5, dia 12: chuva sobre a floresta"). Rode também um cenário **sem nenhuma intervenção**.
- As pessoas interpretam eventos inexplicáveis (os divinos e também os naturais coincidentes). Daí surgem as primeiras crenças, as preces e os nomes do deus por grupo.
- Preces: pedidos ligados a necessidades reais ("que a chuva volte"), registradas como eventos.

**Memória e cultura**
- Lugares ganham nomes por causa de eventos marcantes.
- Pelo menos um costume nasce de um evento (exemplo: depois de uma fome, o grupo passa a estocar comida).

**Crônica**
- Todo evento significativo é registrado de forma estruturada (tipo, participantes, lugar, tempo, causa).
- A crônica é gerada a partir desses eventos por **gramática de frases em português**, com concordância de gênero e número. Nada de modelo de linguagem.
- A crônica escolhe o que é importante: não é um log de tudo. Um ano de crônica deve ter algumas linhas a poucos parágrafos.

## Entregas

Em `prototipos/simulacao/`:
- o projeto Godot com o núcleo;
- `cronicas/`: a crônica de 100 anos para as sementes 1, 2 e 3, sem intervenção, e para a semente 1 com um cenário de intervenções;
- `RELATORIO.md` com:
  - o que foi implementado e o que ficou de fora;
  - o tempo para simular 1 ano e 100 anos;
  - uma avaliação honesta: as crônicas são interessantes? Que tipos de história surgiram? O que se repete demais?
  - recomendações para a fase 1.

## Critérios de aceite

- mesma semente, mesma crônica (rode duas vezes e compare);
- 1 ano de jogo simulado em poucos segundos, no máximo;
- as crônicas mostram pelo menos: nascimentos e mortes que importam, uma separação de grupos, um conflito, o surgimento de uma crença e um costume nascido de um evento;
- as 3 sementes contam histórias visivelmente diferentes.

# Fase 1 — Sessão A: núcleo da simulação

Leia antes: `sessoes/fase1-plano.md` (divisão do trabalho e contrato com a apresentação).

**Sua área:** `jogo/nucleo/` e `jogo/ferramentas_sim/`. Não edite nada fora delas. O `jogo/project.godot` pertence à sessão B: use-o para rodar sem gráfico, mas não o altere.

O núcleo foi copiado do seu protótipo para `jogo/nucleo/`. Porte as ferramentas que precisar para `jogo/ferramentas_sim/`. O protótipo em `prototipos/simulacao/` fica congelado.

## Tarefas, em ordem de prioridade

1. **API para a apresentação** (`jogo/nucleo/API.md` e o código correspondente):
   - **estado legível:** pessoas com posição na zona (um x em pixels do mundo de 480 de largura, que a apresentação usa para desenhar) e ação atual (andar, parado, colher, rezar, sentado na fogueira, dormir), grupos, construções (cabanas, fogueiras, roças) com posição, e zonas com a faixa de x que ocupam;
   - **preces abertas** (quem, o quê, onde, desde quando), para os sinais na moldura;
   - **chamados** (eventos de importância alta, inclusive "os últimos");
   - **poderes:** `usar_poder(poder, x, intensidade)`, com x na tela e intensidade de 0 a 1 vinda do gesto. O grau (sinal, milagre, imposição) sai da intensidade, da precisão e da repetição, como diz o documento funcional;
   - **linhagem acompanhada:** escolher uma pessoa, seguir para os descendentes quando ela morrer, e a lista de sugestões de quem acompanhar;
   - **crônica:** o texto por ano, consultável a qualquer momento.
2. **Persistência:**
   - salvar e carregar o mundo inteiro em `user://`, em arquivo de texto;
   - o arquivo guarda a hora real do último salvamento.
3. **Ausência:** ao carregar, avançar sem gráfico até o teto de 1 ano de jogo e gerar a crônica do período.
4. **Melhorias da fase 0** (recomendações do seu relatório):
   - arco dos personagens: a crônica lembra o que a pessoa fez quando ela morre;
   - repetição vira escalada: preces atendidas em série geram dependência e exigência banal, e eventos repetidos viram resumo de período;
   - guerras como episódios com nome, motivo, campanha e desfecho;
   - segurar a fragmentação: no máximo 3 a 4 povos vivos e no mínimo uns 8 fundadores;
   - mais duas dimensões culturais (relação com estranhos e os mortos) e mutação de costumes herdados (reforma);
   - outras fontes de mistério natural além do eclipse;
   - perda de conhecimento e expedição além da borda disparando de verdade;
   - comandos condicionais no cenário, para testes.
5. **Regressão:** um teste sem gráfico que roda 5 sementes por 100 anos, confere o determinismo e salva as crônicas em `jogo/ferramentas_sim/cronicas/`.

## Entrega

Faça commits na sua branch ao longo do trabalho. Ao terminar cada bloco (1, 2 e 3 juntos; depois o 4; depois o 5), reporte o que mudou na API. A apresentação depende dela, então entregue o bloco 1 primeiro.

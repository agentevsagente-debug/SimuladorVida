# Fase 1 — Sessão B: apresentação do jogo

Leia antes:
- `sessoes/fase1-plano.md`: divisão do trabalho e contrato com o núcleo;
- `tecnico-simulador-de-vida.md`: em especial "Atmosfera feita por código";
- `arte_claude/pecas/LEIA-ME.md`: as peças, as camadas e como a montagem foi feita.

**Sua área:** todo `jogo/`, exceto `jogo/nucleo/` e `jogo/ferramentas_sim/`, que são da sessão A. O `jogo/project.godot` é seu: ele foi semeado com as configurações da sua moldura. A arte vem de `arte_claude/`; copie para `jogo/arte/` o que for usar, sem editar os originais.

## Tarefas, em ordem

1. **Moldura no jogo:** traga do seu protótipo a janela, a passagem do mouse, a escala inteira, o esconder por minimização, a bandeja e o atalho global opcional. Escolha a escala inicial pela densidade da tela.
2. **Mundo desenhado:**
   - camadas do céu por horário, montanhas em 2 planos e mata distante, com paralaxe;
   - terreno montado com os blocos;
   - vegetação, cabanas e fogueiras nas posições que o núcleo informa;
   - habitantes animados conforme a ação de cada um.

   O resultado parado precisa parecer `arte_claude/alvo/`.
3. **Atmosfera por código:**
   - transição do céu ao longo do dia;
   - reflexo na água;
   - luz da fogueira à noite, iluminando as pessoas (use o mapa de luz da montagem como referência);
   - neblina;
   - partículas de chuva e faíscas;
   - clarão do raio.

   Tudo dentro da meta de leveza.
4. **Interação:**
   - **6 poderes por gesto:** chuva, raio, fogo, fartura, erguer terra e sonho. A intensidade vem de quanto tempo o jogador segura;
   - **seletor de poder discreto** na alça;
   - **passar o cursor** sobre pessoa, lugar ou sinal mostra nome, traço e prece;
   - **sinais de prece** visíveis na moldura;
   - **controles de tempo:** normal, rápido e salto até o próximo acontecimento;
   - **acompanhar a linhagem:** a vista segue a pessoa;
   - **leitor da crônica** dentro do jogo;
   - **modo discreto** e atalho para esconder.
5. **Leveza:** meça de novo com o jogo completo, com o mesmo método da fase 0 (10 minutos, 3 cenários).

## Enquanto o núcleo não tem a API nova

Use o que já existe (`mundo.grupos`, `mundo.pessoas`, `mundo.zonas`, `mundo.eventos`, `avancar_hora()`) e posições provisórias calculadas na apresentação. Quando a sessão A entregar `jogo/nucleo/API.md`, o orquestrador avisa e você troca para a API.

## Entrega

Faça commits na sua branch ao longo do trabalho. Ao fim de cada tarefa, mande uma captura em `jogo/capturas/` e reporte o que funciona e o que não funciona.

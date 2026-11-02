# Simulador de vida 0.2.0

*Texto pronto para a página da Release no GitHub. Copie a partir da linha abaixo.*

---

**O mundo ganhou som, e ele se cala com um clique.** A 0.2.0 traz o som do mundo, sempre discreto, como uma janela aberta para o campo, e um botão de lupa para mudar o tamanho da janela.

Gratuito, para Windows, sem instalador e sem internet. Código aberto, sob a [licença MIT](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/LICENSE). O guia completo está em [Como jogar](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-jogar.md).

## Baixar e jogar

1. Baixe o `Simulador.de.vida.exe` (cerca de 108 MB) aqui embaixo, em **Assets**, e rode. Não há instalador.
2. O Windows pode mostrar "O Windows protegeu o computador", porque o jogo não tem assinatura digital. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. O mundo começa vazio. Clique sobre ele para fazer nascer o primeiro povo.

Quem já joga uma versão anterior pode só trocar o `.exe`: o mundo salvo continua.

**Requisitos:** Windows 10 ou 11, 64 bits.

## O que mudou desde a 0.1.2

- **O som do mundo**, todo gerado por código, sem nenhuma gravação:
  - **ambiente:** vento, pássaros e o lago de dia; grilos, coruja e fogo à noite; chuva, tempestade e neve conforme o clima; o murmúrio da vila, que cresce com ela;
  - **acontecimentos:** o trovão do raio, o ronco do terremoto, o fogo, o dilúvio, um sino leve no milagre, a caçada, o choro de um bebê ao longe, o galo ao amanhecer e o sino do templo;
  - o som vem do lado da tela onde a coisa acontece.
- **Silêncio fácil, para reuniões:**
  - o **botão de som** na alça e a tecla **M** calam tudo na hora;
  - o **menu do ícone perto do relógio** (botão direito) tem "Som ligado", para calar sem abrir a janela;
  - o jogo se cala sozinho quando a janela é escondida ou minimizada;
  - a escolha fica guardada, e o volume começa baixo;
  - no modo discreto, os sons pesados (terremoto, dilúvio, fogo forte, batalha) não tocam.
- **A lupa:** um botão na alça muda o tamanho da janela. O clique aumenta (2x, 3x, 4x, até o que cabe na tela) e o botão direito diminui. A janela não sai da tela ao crescer.
- **O som pesa pouco:** menos de 1% de um núcleo do processador e cerca de 4 MB de memória a mais.

## Problemas conhecidos

- **O aviso do SmartScreen.** O jogo não tem assinatura digital. Veja acima como abrir.
- **Só Windows 10 e 11, 64 bits, e só em português.**
- **O ícone perto do relógio pode estar escondido** na setinha "^" do Windows 11. Para trazer a janela de volta, use também o **Ctrl+Alt+H** ou o jogo na barra de tarefas.
- **O Ctrl+Alt+H pode já estar em uso** por outro programa. Nesse caso, use o ícone ou a barra de tarefas.
- **A memória cresce com o mundo:** cerca de 110 a 140 MB no Gerenciador de Tarefas num mundo novo e de 180 a 190 MB depois de 150 a 200 anos. O atalho Ctrl+Alt+H roda num processo à parte, com cerca de 28 MB.
- **Os sons foram ouvidos por pouca gente.** Se algum incomodar, conte numa issue.
- **Testado sobretudo por máquinas.** Quase todos os testes foram automáticos ou feitos por sessões de IA jogando o jogo, inclusive no próprio executável. Os seus relatos ajudam muito.

## Como relatar um erro

Abra uma [issue](https://github.com/agentevsagente-debug/SimuladorVida/issues) com:
1. **a versão:** passe o cursor sobre o relógio, no canto da alça (deve dizer "Simulador de vida 0.2.0");
2. **o que você fez logo antes** do erro;
3. **o arquivo de registro** `godot.log`, anexado. Ele fica em:
   ```
   %APPDATA%\Simulador de vida\logs\godot.log
   ```
   Cole esse caminho na barra de endereço do Explorador de Arquivos.

Se o problema for com o mundo salvo, anexe também o `mundo.txt` da pasta `%APPDATA%\Simulador de vida`.

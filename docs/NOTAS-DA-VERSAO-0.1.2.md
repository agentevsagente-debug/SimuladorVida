# Simulador de vida 0.1.2

*Texto pronto para a página da Release no GitHub. Copie a partir da linha abaixo.*

---

**Uma tarde mais viva.** A 0.1.2 traz três cenas novas para o começo da tarde, que era o período mais parado do dia, e deixa o jogo mais leve em mundos grandes.

Gratuito, para Windows, sem instalador e sem internet. Código aberto, sob a [licença MIT](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/LICENSE). O guia completo está em [Como jogar](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-jogar.md).

## Baixar e jogar

1. Baixe o `Simulador.de.vida.exe` (cerca de 106 MB) aqui embaixo, em **Assets**, e rode. Não há instalador.
2. O Windows pode mostrar "O Windows protegeu o computador", porque o jogo não tem assinatura digital. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. O mundo começa vazio. Clique sobre ele para fazer nascer o primeiro povo.

Quem já joga a 0.1.1 pode só trocar o `.exe`: o mundo salvo continua.

**Requisitos:** Windows 10 ou 11, 64 bits.

## O que mudou desde a 0.1.1

- **Três cenas novas na tarde da vila (das 12h30 às 15h40 do jogo):**
  - **a sesta:** os adultos dormem deitados ao lado da casa; uma criança cutuca, quem acorda ralha, e a criança foge;
  - **ensinar a lança:** além da última casa, o velho mira e crava a lança num alvo de capim, e depois a criança tenta; quando erra, a lança fica caída até alguém buscar;
  - **o artesanato em roda:** o povo trança cestos, molda potes ou afia lanças, e no fim alguém ergue a peça pronta e a leva.
- **Mais leve em mundos grandes:** num mundo de 200 anos, visível em 1x, o jogo caiu de cerca de 8,2% para 7% de um núcleo do processador, com o pico de 13,8% para 8,1%.
- **Menos engasgos em 50x:** a montagem do dia agora é feita por povo, em paralelo, e caiu de cerca de 200 ms para cerca de 100 ms num mundo de 240 pessoas.
- **A crônica do mundo novo** ganha um prólogo antes do primeiro povo.
- **Arte:** o balão de fala, que de longe parecia uma caveira, foi redesenhado.

## Problemas conhecidos

- **O aviso do SmartScreen.** O jogo não tem assinatura digital. Veja acima como abrir.
- **Não tem som.** O jogo é silencioso nesta versão.
- **Só Windows 10 e 11, 64 bits, e só em português.**
- **O ícone perto do relógio pode estar escondido** na setinha "^" do Windows 11. Para trazer a janela de volta, use também o **Ctrl+Alt+H** ou o jogo na barra de tarefas.
- **O Ctrl+Alt+H pode já estar em uso** por outro programa. Nesse caso, use o ícone ou a barra de tarefas.
- **A memória cresce com o mundo:** cerca de 110 MB no Gerenciador de Tarefas num mundo novo e de 180 a 190 MB depois de 150 a 200 anos. O atalho Ctrl+Alt+H roda num processo à parte, com cerca de 28 MB.
- **Testado sobretudo por máquinas.** Quase todos os testes foram automáticos ou feitos por sessões de IA jogando o jogo, inclusive no próprio executável. Os seus relatos ajudam muito.

## Como relatar um erro

Abra uma [issue](https://github.com/agentevsagente-debug/SimuladorVida/issues) com:
1. **a versão:** passe o cursor sobre o relógio, no canto da alça (deve dizer "Simulador de vida 0.1.2");
2. **o que você fez logo antes** do erro;
3. **o arquivo de registro** `godot.log`, anexado. Ele fica em:
   ```
   %APPDATA%\Simulador de vida\logs\godot.log
   ```
   Cole esse caminho na barra de endereço do Explorador de Arquivos.

Se o problema for com o mundo salvo, anexe também o `mundo.txt` da pasta `%APPDATA%\Simulador de vida`.

# Simulador de vida 0.3.1

*Texto pronto para a página da Release no GitHub. Copie a partir da linha abaixo.*

---

**Conheça o seu povo.** A 0.3.1 traz o painel da população: quantas pessoas vivem no mundo, quais povos existem e quem mora em cada um.

Gratuito, para Windows, sem instalador e sem internet. Código aberto, sob a [licença MIT](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/LICENSE). O guia completo está em [Como jogar](https://github.com/agentevsagente-debug/SimuladorVida/blob/main/docs/como-jogar.md).

## Baixar e jogar

1. Baixe o `Simulador.de.vida.exe` aqui embaixo, em **Assets**, e rode. Não há instalador.
2. O Windows pode mostrar "O Windows protegeu o computador", porque o jogo não tem assinatura digital. Clique em **Mais informações** e depois em **Executar assim mesmo**.
3. O mundo começa vazio. Clique sobre ele para fazer nascer o primeiro povo.

Quem já joga uma versão anterior pode só trocar o `.exe`: o mundo salvo continua.

**Requisitos:** Windows 10 ou 11, 64 bits.

## O que mudou desde a 0.3.0

- **O painel da população:**
  - abre com um botão novo na alça, depois da caixa de preces, ou com a tecla **G**;
  - no topo, mostra quantos habitantes o mundo tem agora. A dica do botão mostra o mesmo número;
  - lista os povos vivos: o nome, quantas pessoas tem, onde vive, o estágio e o deus em que crê;
  - clicar num povo mostra a gente dele, com o nome, o papel e a idade: primeiro o líder e o sacerdote, depois os adultos do mais velho ao mais novo e, no fim, as crianças. A roda do mouse rola a lista;
  - clicar numa pessoa leva a vista até ela;
  - **Voltar**, Esc ou o botão direito voltam aos povos.
- O painel mostra só o que já se via passando o cursor. A fé de cada pessoa continua escondida.

## Problemas conhecidos

- **Um povo que acabou de se extinguir** ainda aparece no painel com 0 habitantes por algumas horas do jogo, até a virada do dia.
- **O aviso do SmartScreen.** O jogo não tem assinatura digital. Veja acima como abrir.
- **Só Windows 10 e 11, 64 bits, e só em português.**
- **O ícone perto do relógio pode estar escondido** na setinha "^" do Windows 11. Para trazer a janela de volta, use também o **Ctrl+Alt+H** ou o jogo na barra de tarefas.
- **O Ctrl+Alt+H pode já estar em uso** por outro programa. Nesse caso, use o ícone ou a barra de tarefas.
- **Testado sobretudo por máquinas.** Quase todos os testes foram automáticos ou feitos por sessões de IA jogando o jogo. Os seus relatos ajudam muito.

## Como relatar um erro

Abra uma [issue](https://github.com/agentevsagente-debug/SimuladorVida/issues) com:
1. **a versão:** passe o cursor sobre o relógio, no canto da alça (deve dizer "Simulador de vida 0.3.1");
2. **o que você fez logo antes** do erro;
3. **o arquivo de registro** `godot.log`, anexado. Ele fica em:
   ```
   %APPDATA%\Simulador de vida\logs\godot.log
   ```
   Cole esse caminho na barra de endereço do Explorador de Arquivos.

Se o problema for com o mundo salvo, anexe também o `mundo.txt` da pasta `%APPDATA%\Simulador de vida`.

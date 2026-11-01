# Cenários de QA com o jogo em janela (sessão D). Sem mouse nem teclado reais: só as opções
# de teste da apresentação (jogo/RELATORIO.md) e a captura interna da vista.
#
# Uso (da raiz do repositório):
#   powershell -ExecutionPolicy Bypass -File jogo/qa/janela/rodar_janela.ps1 [-Parte fechar|fecharjanela|capturas|leveza|tudo] [-Segundos 90]
#
# Isolamento: APPDATA aponta para %TEMP%\simvida_qa_janela, então o user:// do jogo (mundo salvo,
# moldura.cfg, estante, logs) fica fora da pasta de dados real do jogador.
# Saída: qa/janela/resultado-*.json e qa/capturas/*.png na raiz do repositório.
param(
    [ValidateSet('fechar', 'fecharjanela', 'capturas', 'leveza', 'tudo')][string]$Parte = 'tudo',
    [int]$Segundos = 90,
    [int]$Aberturas = 10,
    [int[]]$AnosLeveza = @(0, 200),
    [switch]$ComAtalho,   # liga o atalho global (Ctrl+Alt+H), como no jogo de verdade: sem ele, --sem-atalho
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
)
$ErrorActionPreference = 'Stop'
$projeto = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$raiz = Split-Path $projeto -Parent
$saida = Join-Path $raiz 'qa\janela'
$capturas = Join-Path $raiz 'qa\capturas'
New-Item -ItemType Directory -Force $saida, $capturas | Out-Null
$isolado = Join-Path $env:TEMP 'simvida_qa_janela'
New-Item -ItemType Directory -Force $isolado | Out-Null
$env:APPDATA = $isolado
$userdir = Join-Path $isolado 'Godot\app_userdata\Simulador de vida'
$nucleos = [Environment]::ProcessorCount

function Abrir([string[]]$opcoes, [string]$rotulo) {
    $log = Join-Path $saida "log-$rotulo.txt"
    $atalho = if ($ComAtalho) { '--atalho-global' } else { '--sem-atalho' }
    $argumentos = @('--path', "`"$projeto`"", '--') + $opcoes + @('--sem-foco', $atalho)
    # -NoNewWindow: o console fica no do PowerShell; a janela do jogo abre normal (não escondida,
    # para a medição de leveza valer com o jogo visível)
    $p = Start-Process -FilePath $Godot -ArgumentList $argumentos -PassThru -NoNewWindow `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    $null = $p.Handle   # sem guardar o handle agora, o ExitCode vem vazio depois
    return $p
}

function Esperar($p, [int]$limite) {
    if (-not $p.WaitForExit($limite * 1000)) { $p.Kill(); return 'travou' }
    return $p.ExitCode
}

# ------------------------------------------------------------ QA-164: fechar sem falha
if ($Parte -in 'fechar', 'tudo') {
    $res = @()
    for ($i = 1; $i -le $Aberturas; $i++) {
        # metade com mundo de teste (não salva), metade com o mundo salvo no user:// isolado
        $op = if ($i % 2) { @('--sem-config', '--mundo-novo', "--semente=$i", '--duracao=8') } else { @('--duracao=8') }
        $sufixo = if ($ComAtalho) { '-atalho' } else { '' }
        $p = Abrir $op "fechar$sufixo-$i"
        $codigo = Esperar $p 90
        $log = Get-Content (Join-Path $saida "log-fechar$sufixo-$i.txt") -Raw -ErrorAction SilentlyContinue
        $err = Get-Content (Join-Path $saida "log-fechar$sufixo-$i.txt.err") -Raw -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $orfaos = @(Get-CimInstance Win32_Process -Filter "Name like 'powershell%'" | Where-Object { $_.CommandLine -match 'simvida_qa_janela' -and $_.CommandLine -match 'atalho_global' })
        $orfaos | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        $res += [pscustomobject]@{
            abertura = $i; atalho = [bool]$ComAtalho; auxiliares_orfaos = $orfaos.Count; modo = $(if ($i % 2) { 'mundo-novo' } else { 'mundo-salvo' }); codigo = "$codigo"
            salvou = [bool]($log -match 'salvo=true'); carregou = [bool]($log -match '\[simulacao\] carregado')
            erros = (($err + $log) -split "`n" | Where-Object { $_ -match 'ERROR|SCRIPT ERROR|CrashHandler|signal 11|Segmentation' } | Select-Object -First 5) -join ' | '
        }
        Write-Host ("fechar {0}: código {1}" -f $i, $codigo)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida "resultado-fechar$sufixo.json") -Encoding utf8
}

# ------------------------------------------------------------ QA-164: fechar pela mensagem da janela
# O caminho de Alt+F4 e do "fechar janela" da barra de tarefas (NOTIFICATION_WM_CLOSE_REQUEST),
# diferente do sair() do --duracao. A mensagem WM_CLOSE vai pelo CloseMainWindow(), sem mouse
# nem teclado. No 50x, com o mundo salvo, um dia passa a cada 54 s: fechando em tempos variados,
# algumas vezes cai durante o salvar_async do dia.
if ($Parte -in 'fecharjanela', 'tudo') {
    $res = @()
    $tempos = @(6, 9, 13, 17, 22, 27, 31, 38, 44, 52)
    for ($i = 1; $i -le $Aberturas; $i++) {
        $espera = $tempos[($i - 1) % $tempos.Count]
        $sufixo = if ($ComAtalho) { '-atalho' } else { '' }
        $p = Abrir @('--ritmo=rapido2', '--duracao=300') "fecharjanela$sufixo-$i"
        Start-Sleep -Seconds $espera
        $filho = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.Id)" | Select-Object -First 1
        $alvo = if ($filho) { Get-Process -Id $filho.ProcessId -ErrorAction SilentlyContinue } else { $p }
        $fechou = $false
        if ($alvo) { $fechou = $alvo.CloseMainWindow() }
        $codigo = Esperar $p 60
        $log = Get-Content (Join-Path $saida "log-fecharjanela$sufixo-$i.txt") -Raw -ErrorAction SilentlyContinue
        $err = Get-Content (Join-Path $saida "log-fecharjanela$sufixo-$i.txt.err") -Raw -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $orfaos = @(Get-CimInstance Win32_Process -Filter "Name like 'powershell%'" | Where-Object { $_.CommandLine -match 'simvida_qa_janela' -and $_.CommandLine -match 'atalho_global' })
        $orfaos | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        $res += [pscustomobject]@{ abertura = $i; segundos = $espera; atalho = [bool]$ComAtalho; auxiliares_orfaos = $orfaos.Count; mensagem_entregue = $fechou; codigo = "$codigo"
            salvou = [bool]($log -match 'salvo=true'); salvando_em_segundo_plano = [bool]($log -match 'salvando em segundo plano')
            erros = (($err + $log) -split "`n" | Where-Object { $_ -match 'ERROR|SCRIPT ERROR|CrashHandler|signal 11|Segmentation' } | Select-Object -First 5) -join ' | ' }
        Write-Host ("fecharjanela {0} ({1} s): mensagem {2}, código {3}" -f $i, $espera, $fechou, $codigo)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida "resultado-fecharjanela$sufixo.json") -Encoding utf8
}

# ------------------------------------------------------------ capturas dos cenários de tela
if ($Parte -in 'capturas', 'tudo') {
    $base = @('--sem-config', '--mundo-novo', '--semente=7', '--dias=12', '--hora=10')
    $cenarios = [ordered]@{
        'QA-098-ausencia'   = $base + @('--simular-ausencia=240', '--capturar-apos=4')
        # a vista só relê o mundo a cada passo, e o núcleo só declara o fim na virada do dia: no 50x,
        # das 10h à 1h são 15 passos de 2,25 s; 2 quadros, aos 6 s e aos 40 s
        'QA-129-extincao'   = $base + @('--extinguir', '--ritmo=rapido2', '--capturar-apos=6', '--quadros=2', '--intervalo=34')
        # o --carregar fixa o começo da carga em 1 s, e ela continua subindo (0,5 por segundo):
        # a captura vai logo depois, em 1,15 s
        'QA-036-carga-raio' = $base + @('--carregar=raio:300:0.3', '--capturar-apos=1.15')
        'QA-036-carga-fogo' = $base + @('--carregar=fogo:260:0.2', '--capturar-apos=1.15')
        'QA-145-estante'    = $base + @('--abrir=estante', '--capturar-apos=3')
        'QA-151-discreto'   = $base + @('--discreto', '--demo=fogo:260:0.8:2', '--capturar-apos=3.5')
        'QA-151-normal'     = $base + @('--demo=fogo:260:0.8:2', '--capturar-apos=3.5')
        'QA-162-escala4'    = $base + @('--escala=4', '--capturar-apos=3', '--capturar-tudo')
        'QA-018-salto'      = $base + @('--abrir=salto', '--capturar-apos=3')
        # ataque às 8h no 50x (2,25 s por hora): a luta deve estar na tela das 11h30 às 13h,
        # entre 8 e 11 s depois; 3 quadros, de 8 a 12 s
        'QA-180-batalha'    = @('--sem-config', '--mundo-novo', '--semente=3', '--anos=60', '--hora=8', '--ritmo=rapido2',
                                '--cenario-raro=batalha', '--capturar-apos=8', '--quadros=3', '--intervalo=2')
    }
    $res = @()
    foreach ($nome in $cenarios.Keys) {
        $png = Join-Path $capturas "$nome.png"
        if (Test-Path $png) { Remove-Item $png }
        $p = Abrir ($cenarios[$nome] + @("--capturar=$png", '--duracao=40')) $nome
        $codigo = Esperar $p 90
        $tem = (Test-Path $png) -or (Test-Path ($png -replace '\.png$', '_00.png'))
        $res += [pscustomobject]@{ cenario = $nome; codigo = "$codigo"; captura = $tem }
        Write-Host ("{0}: código {1}, captura {2}" -f $nome, $codigo, $tem)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida 'resultado-capturas.json') -Encoding utf8
}

# ------------------------------------------------------------ QA-171/172/175: leveza em 1x
if ($Parte -in 'leveza', 'tudo') {
    $res = @()
    $lista = $AnosLeveza | ForEach-Object {
        if ($_ -eq 0) { @{ nome = 'novo-1x'; op = @('--semente=7', '--hora=17') } }
        else { @{ nome = "$($_)anos-1x"; op = @('--semente=7', "--anos=$_", '--hora=17') } } }
    foreach ($c in $lista) {
        $p = Abrir (@('--sem-config', '--mundo-novo', '--ritmo=normal', "--duracao=$($Segundos + 60)") + $c.op) "leveza-$($c.nome)"
        Start-Sleep -Seconds 20   # carregar e aquecer (o mundo de 200 anos leva alguns segundos)
        # o _console.exe é só um invólucro: o jogo é o processo filho, e é ele que se mede
        $envoltorio = $p
        $filho = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($p.Id)" | Select-Object -First 1
        if ($filho) { $p = Get-Process -Id $filho.ProcessId }
        $p.Refresh(); $t0 = Get-Date; $cpu0 = $p.TotalProcessorTime.TotalSeconds
        $amostras = @(); $tA = $t0; $cA = $cpu0; $mem = 0; $privada = 0
        while (((Get-Date) - $t0).TotalSeconds -lt $Segundos) {
            Start-Sleep -Seconds 5
            $p.Refresh()
            if ($p.HasExited) { break }
            $t = Get-Date; $cpu = $p.TotalProcessorTime.TotalSeconds
            $amostras += [math]::Round(($cpu - $cA) / ($t - $tA).TotalSeconds * 100, 2)
            $mem = [math]::Max($mem, [math]::Round($p.WorkingSet64 / 1MB, 1))
            $privada = [math]::Max($privada, [math]::Round($p.PrivateMemorySize64 / 1MB, 1))
            $tA = $t; $cA = $cpu
        }
        $dt = ((Get-Date) - $t0).TotalSeconds
        $media = [math]::Round(($p.TotalProcessorTime.TotalSeconds - $cpu0) / $dt * 100, 2)
        if (-not $p.HasExited) { $p.Kill() }
        if (-not $envoltorio.HasExited) { $envoltorio.Kill() }
        $res += [pscustomobject]@{ cenario = $c.nome; processo = $p.ProcessName; segundos = [math]::Round($dt); cpu_1nucleo_media = $media
            cpu_1nucleo_pico = ($amostras | Measure-Object -Maximum).Maximum; cpu_maquina_media = [math]::Round($media / $nucleos, 3)
            working_set_max_mb = $mem; privada_max_mb = $privada; nucleos = $nucleos }
        Write-Host ("leveza {0}: {1}% de um núcleo (pico {2}%), {3} MB" -f $c.nome, $media, ($amostras | Measure-Object -Maximum).Maximum, $mem)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida "resultado-leveza-$($AnosLeveza -join '-').json") -Encoding utf8
}
Write-Host "user:// isolado: $userdir"

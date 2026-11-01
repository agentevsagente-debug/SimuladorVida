# Cenários de QA com o jogo em janela (sessão D). Sem mouse nem teclado reais: só as opções
# de teste da apresentação (jogo/RELATORIO.md) e a captura interna da vista.
#
# Uso (da raiz do repositório):
#   powershell -ExecutionPolicy Bypass -File jogo/qa/janela/rodar_janela.ps1 [-Parte fechar|capturas|leveza|tudo] [-Segundos 90]
#
# Isolamento: APPDATA aponta para %TEMP%\simvida_qa_janela, então o user:// do jogo (mundo salvo,
# moldura.cfg, estante, logs) fica fora da pasta de dados real do jogador.
# Saída: qa/janela/resultado-*.json e qa/capturas/*.png na raiz do repositório.
param(
    [ValidateSet('fechar', 'capturas', 'leveza', 'tudo')][string]$Parte = 'tudo',
    [int]$Segundos = 90,
    [int]$Aberturas = 10,
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
    $argumentos = @('--path', "`"$projeto`"", '--') + $opcoes + @('--sem-foco', '--sem-atalho')
    # -NoNewWindow: o console fica no do PowerShell; a janela do jogo abre normal (não escondida,
    # para a medição de leveza valer com o jogo visível)
    $p = Start-Process -FilePath $Godot -ArgumentList $argumentos -PassThru -NoNewWindow `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
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
        $p = Abrir $op "fechar-$i"
        $codigo = Esperar $p 90
        $log = Get-Content (Join-Path $saida "log-fechar-$i.txt") -Raw -ErrorAction SilentlyContinue
        $err = Get-Content (Join-Path $saida "log-fechar-$i.txt.err") -Raw -ErrorAction SilentlyContinue
        $res += [pscustomobject]@{
            abertura = $i; modo = $(if ($i % 2) { 'mundo-novo' } else { 'mundo-salvo' }); codigo = "$codigo"
            salvou = [bool]($log -match 'salvo=true'); carregou = [bool]($log -match '\[simulacao\] carregado')
            erros = (($err + $log) -split "`n" | Where-Object { $_ -match 'ERROR|SCRIPT ERROR|CrashHandler|signal 11|Segmentation' } | Select-Object -First 5) -join ' | '
        }
        Write-Host ("fechar {0}: código {1}" -f $i, $codigo)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida 'resultado-fechar.json') -Encoding utf8
}

# ------------------------------------------------------------ capturas dos cenários de tela
if ($Parte -in 'capturas', 'tudo') {
    $base = @('--sem-config', '--mundo-novo', '--semente=7', '--dias=12', '--hora=10')
    $cenarios = [ordered]@{
        'QA-098-ausencia'   = $base + @('--simular-ausencia=240', '--capturar-apos=4')
        'QA-129-extincao'   = $base + @('--extinguir', '--capturar-apos=6')
        'QA-036-carga-raio' = $base + @('--carregar=raio:300:0.7', '--capturar-apos=3')
        'QA-036-carga-fogo' = $base + @('--carregar=fogo:260:0.2', '--capturar-apos=3')
        'QA-145-estante'    = $base + @('--abrir=estante', '--capturar-apos=3')
        'QA-151-discreto'   = $base + @('--discreto', '--demo=fogo:260:0.8:2', '--capturar-apos=3.5')
        'QA-151-normal'     = $base + @('--demo=fogo:260:0.8:2', '--capturar-apos=3.5')
        'QA-162-escala4'    = $base + @('--escala=4', '--capturar-apos=3', '--capturar-tudo')
        'QA-018-salto'      = $base + @('--abrir=salto', '--capturar-apos=3')
    }
    $res = @()
    foreach ($nome in $cenarios.Keys) {
        $png = Join-Path $capturas "$nome.png"
        if (Test-Path $png) { Remove-Item $png }
        $p = Abrir ($cenarios[$nome] + @("--capturar=$png", '--duracao=40')) $nome
        $codigo = Esperar $p 90
        $res += [pscustomobject]@{ cenario = $nome; codigo = "$codigo"; captura = (Test-Path $png) }
        Write-Host ("{0}: código {1}, captura {2}" -f $nome, $codigo, (Test-Path $png))
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida 'resultado-capturas.json') -Encoding utf8
}

# ------------------------------------------------------------ QA-171/172/175: leveza em 1x
if ($Parte -in 'leveza', 'tudo') {
    $res = @()
    foreach ($c in @(@{ nome = 'novo-1x'; op = @('--semente=7', '--hora=17') },
                     @{ nome = '200anos-1x'; op = @('--semente=7', '--anos=200', '--hora=17') })) {
        $p = Abrir (@('--sem-config', '--mundo-novo', '--ritmo=normal', "--duracao=$($Segundos + 60)") + $c.op) "leveza-$($c.nome)"
        Start-Sleep -Seconds 20   # carregar e aquecer (o mundo de 200 anos leva alguns segundos)
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
        $res += [pscustomobject]@{ cenario = $c.nome; segundos = [math]::Round($dt); cpu_1nucleo_media = $media
            cpu_1nucleo_pico = ($amostras | Measure-Object -Maximum).Maximum; cpu_maquina_media = [math]::Round($media / $nucleos, 3)
            working_set_max_mb = $mem; privada_max_mb = $privada; nucleos = $nucleos }
        Write-Host ("leveza {0}: {1}% de um núcleo (pico {2}%), {3} MB" -f $c.nome, $media, ($amostras | Measure-Object -Maximum).Maximum, $mem)
    }
    $res | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $saida 'resultado-leveza.json') -Encoding utf8
}
Write-Host "user:// isolado: $userdir"

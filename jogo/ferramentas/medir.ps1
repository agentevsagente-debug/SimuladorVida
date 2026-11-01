# Mede CPU e memória da moldura num cenário.
# Uso: medir.ps1 -Cenario normal|rapido|escondido -Segundos 600
#   normal: visível, ritmo normal (1 hora de jogo a cada 112,5 s)
#   rapido: visível, ritmo rápido (1 hora a cada 1,9 s: gente andando o tempo todo)
#   escondido: minimizada, ritmo normal
#
# CPU% = Δ tempo de CPU do processo / (Δ tempo real × núcleos lógicos) × 100,
# a mesma conta do Gerenciador de Tarefas. O dwm.exe, que compõe a janela
# transparente, não pode ser lido sem administrador e fica de fora.
#
# Memória, três medidas:
#   working_set_mb: conjunto de trabalho (inclui as páginas compartilhadas do executável);
#   privada_mb: bytes privados (memória reservada só para o processo);
#   gerenciador_mb: conjunto de trabalho privado, a coluna "Memória" do Gerenciador de Tarefas.
param(
    [Parameter(Mandatory)][ValidateSet('normal', 'rapido', 'escondido')][string]$Cenario,
    [int]$Segundos = 600,
    [int]$Intervalo = 5,
    [int]$Aquecimento = 10,
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
)
$ErrorActionPreference = 'Stop'
$projeto = Split-Path $PSScriptRoot -Parent
$saida = Join-Path $projeto 'medicoes'
New-Item -ItemType Directory -Force $saida | Out-Null
$nucleos = [Environment]::ProcessorCount

$p = Start-Process -FilePath $Godot -PassThru -ArgumentList @(
    '--path', "`"$projeto`"", '--', '--sem-config', '--semente=7', '--hora=17', "--duracao=$($Segundos + $Aquecimento + 30)",
    $(if ($Cenario -eq 'escondido') { '--cenario=escondido' } else { "--ritmo=$Cenario" }))
Start-Sleep -Seconds $Aquecimento

$linhas = @()
$p.Refresh()
$t0 = Get-Date; $cpu0 = $p.TotalProcessorTime.TotalSeconds
$tAnt = $t0; $cpuAnt = $cpu0
while (((Get-Date) - $t0).TotalSeconds -lt $Segundos) {
    Start-Sleep -Seconds $Intervalo
    $p.Refresh()
    if ($p.HasExited) { throw 'a moldura fechou antes do fim da medição' }
    $t = Get-Date; $cpu = $p.TotalProcessorTime.TotalSeconds
    $dt = ($t - $tAnt).TotalSeconds
    $linhas += [pscustomobject]@{
        segundos         = [math]::Round(($t - $t0).TotalSeconds, 1)
        cpu_pct          = [math]::Round(($cpu - $cpuAnt) / ($dt * $nucleos) * 100, 3)
        cpu_pct_1nucleo  = [math]::Round(($cpu - $cpuAnt) / $dt * 100, 2)
        working_set_mb   = [math]::Round($p.WorkingSet64 / 1MB, 1)
        privada_mb       = [math]::Round($p.PrivateMemorySize64 / 1MB, 1)
        gerenciador_mb   = [math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -Filter "IDProcess=$($p.Id)").WorkingSetPrivate / 1MB, 1)
    }
    $tAnt = $t; $cpuAnt = $cpu
}
$total = ((Get-Date) - $t0).TotalSeconds
Stop-Process -Id $p.Id -ErrorAction SilentlyContinue

$linhas | Export-Csv -Path (Join-Path $saida "$Cenario.csv") -NoTypeInformation -Encoding utf8
$resumo = [pscustomobject]@{
    cenario             = $Cenario
    duracao_s           = [math]::Round($total)
    nucleos_logicos     = $nucleos
    cpu_media_pct       = [math]::Round(($cpuAnt - $cpu0) / ($total * $nucleos) * 100, 3)
    cpu_media_1nucleo   = [math]::Round(($cpuAnt - $cpu0) / $total * 100, 2)
    cpu_max_amostra_pct = ($linhas | Measure-Object cpu_pct -Maximum).Maximum
    ws_media_mb         = [math]::Round(($linhas | Measure-Object working_set_mb -Average).Average, 1)
    ws_max_mb           = ($linhas | Measure-Object working_set_mb -Maximum).Maximum
    privada_max_mb      = ($linhas | Measure-Object privada_mb -Maximum).Maximum
    gerenciador_media_mb = [math]::Round(($linhas | Measure-Object gerenciador_mb -Average).Average, 1)
    gerenciador_max_mb  = ($linhas | Measure-Object gerenciador_mb -Maximum).Maximum
}
$resumo | ConvertTo-Json | Set-Content (Join-Path $saida "$Cenario.json") -Encoding utf8
$resumo

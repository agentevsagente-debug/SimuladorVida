# Janela-alvo que fica atrás da moldura e conta os cliques que recebe.
# Uso: alvo.ps1 -X 200 -Y 200 -Arquivo cliques.txt -Segundos 120
param([int]$X = 200, [int]$Y = 200, [string]$Arquivo, [int]$Segundos = 120)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -Name Dpi -Namespace W
[W.Dpi]::SetProcessDPIAware() | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Alvo da moldura'
$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point($X, $Y)
$form.Size = New-Object System.Drawing.Size(1000, 420)
$form.BackColor = [System.Drawing.Color]::FromArgb(200, 0, 200)
$form.ShowInTaskbar = $false
$script:cliques = 0
Set-Content -Path $Arquivo -Value 0
$form.Add_MouseDown({
    $script:cliques++
    Set-Content -Path $Arquivo -Value $script:cliques
})
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $Segundos * 1000
$timer.Add_Tick({ $form.Close() })
$timer.Start()
[System.Windows.Forms.Application]::Run($form)

# Corrige la contrasena de registro del agente Wazuh (Windows) tomandola del portapapeles.
# Uso: copiar el contenido de authd.pass del manager y ejecutar COMO ADMINISTRADOR:
#   powershell -ExecutionPolicy Bypass -File .\set-agent-password.ps1
# La contrasena no se muestra ni se registra; el portapapeles se vacia al terminar.
$ErrorActionPreference = 'Stop'

$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Ejecuta este script como Administrador.' }

Read-Host 'Copia la contrasena de authd.pass (Ctrl+C) y luego pulsa Enter aqui' | Out-Null
$pass = (Get-Clipboard -Raw)
if ($null -eq $pass) { $pass = '' }
$pass = $pass.Trim()
if ($pass.Length -lt 4 -or $pass -match '\s') { throw "El portapapeles no parece contener la contrasena (longitud $($pass.Length)). Copiala de nuevo y repite." }
Write-Host "Contrasena tomada del portapapeles ($($pass.Length) caracteres)."

$dir = "${env:ProgramFiles(x86)}\ossec-agent"
Stop-Service WazuhSvc
[IO.File]::WriteAllText((Join-Path $dir 'authd.pass'), $pass, (New-Object Text.ASCIIEncoding))
$pass = $null
Set-Clipboard -Value ' '

Start-Service WazuhSvc
Write-Host 'Servicio reiniciado; esperando el registro...'
Start-Sleep -Seconds 20
Get-Service WazuhSvc | Format-Table -AutoSize Name, Status
Get-Content (Join-Path $dir 'ossec.log') -Tail 12
Write-Host ''
Write-Host 'Configuracion del agente (servidor y grupo):'
Select-String -Path (Join-Path $dir 'ossec.conf') -Pattern '<address>|<groups>' | ForEach-Object { $_.Line.Trim() }

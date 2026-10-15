# Instala en este equipo los scripts de respuesta de TripleSOC que el agente de Wazuh puede ejecutar
# cuando alguien aprueba una acción en el dashboard. Ejecutar en PowerShell COMO ADMINISTRADOR:
#   powershell -ExecutionPolicy Bypass -File .\install-response-scripts.ps1
# No modifica el agente ni su configuración: solo añade archivos a su carpeta de respuestas.
$ErrorActionPreference = 'Stop'

$bin = Join-Path ${env:ProgramFiles(x86)} 'ossec-agent\active-response\bin'
if (-not (Test-Path $bin)) { throw "No se encontró la carpeta del agente: $bin" }

# Cada script hace una sola cosa fija y no lee argumentos: lo que llegue en una alerta no puede cambiarla.
# El agente es de 32 bits y pnputil solo existe en 64: desde aquí se llega a él por Sysnative.
$scripts = @{
    # Bloquea el almacenamiento USB y expulsa los discos USB que ya estén conectados: sin esto, el
    # dispositivo que disparó la respuesta seguiría montado hasta que alguien lo desconectara. Al
    # retirarlo del sistema con el controlador ya desactivado, no puede volver a montarse.
    # La línea del registro se escribe antes de expulsar: es la confirmación que lee el servidor.
    'triplesoc-block-usb.cmd'   = @'
@echo off
set "PNP=%windir%\Sysnative\pnputil.exe"
if not exist "%PNP%" set "PNP=%windir%\System32\pnputil.exe"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo %date% %time% triplesoc-block-usb: almacenamiento USB bloqueado (codigo %errorlevel%) >> "%~dp0..\active-responses.log"
for /f "tokens=1,* delims=:" %%a in ('%PNP% /enum-devices /connected /class DiskDrive ^| findstr /i /c:"USBSTOR\\"') do for /f "tokens=*" %%i in ("%%b") do "%PNP%" /remove-device "%%i" >nul 2>&1
'@
    # Deshace el bloqueo y vuelve a buscar dispositivos (los discos USB conectados reaparecen).
    'triplesoc-unblock-usb.cmd' = @'
@echo off
set "PNP=%windir%\Sysnative\pnputil.exe"
if not exist "%PNP%" set "PNP=%windir%\System32\pnputil.exe"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo %date% %time% triplesoc-unblock-usb: almacenamiento USB habilitado (codigo %errorlevel%) >> "%~dp0..\active-responses.log"
"%PNP%" /scan-devices >nul 2>&1
'@
    # Teléfonos y tabletas (MTP/PTP): el bloqueo de USBSTOR no los cubre. El modo va fijo en cada .cmd.
    'triplesoc-block-phone.cmd'   = @'
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0triplesoc-phone.ps1" block >> "%~dp0..\active-responses.log" 2>nul
'@
    'triplesoc-unblock-phone.cmd' = @'
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0triplesoc-phone.ps1" unblock >> "%~dp0..\active-responses.log" 2>nul
'@
    # block:   desactiva en Windows cada teléfono USB conectado que no esté en la lista de autorizados
    #          (la misma que usa la auditoría: shared\triplesoc-usb-allowlist.txt). El teléfono sigue
    #          cargando, pero el equipo deja de verlo, también si se desconecta y se vuelve a conectar.
    # unblock: vuelve a habilitar exactamente los que este script desactivó (los apunta en ProgramData).
    # Siempre deja una línea en active-responses.log: es la confirmación que lee el servidor.
    'triplesoc-phone.ps1' = @'
param([string]$Mode)
$ErrorActionPreference = 'Stop'
$log       = Join-Path $PSScriptRoot '..\active-responses.log'
$allowFile = Join-Path $PSScriptRoot '..\..\shared\triplesoc-usb-allowlist.txt'
$stateDir  = Join-Path $env:ProgramData 'TripleSOC'
$stateFile = Join-Path $stateDir 'phones-blocked.txt'
$pnputil   = Join-Path $env:windir 'Sysnative\pnputil.exe'
if (-not (Test-Path -LiteralPath $pnputil)) { $pnputil = Join-Path $env:windir 'System32\pnputil.exe' }

function Clean([string]$s) { if ($null -eq $s) { return '' }; return (($s -replace '[\x00-\x1f"]', "'" -replace '[^\x20-\x7e]', '?').Trim()) }
# La línea sale por la salida estándar y el .cmd la añade al registro con >> (igual que los scripts del USB).
function Say([string]$text) { Write-Output ((Get-Date -Format 'dd/MM/yyyy HH:mm:ss.ff') + ' ' + $text) }

if ($Mode -eq 'block') {
    $done = @(); $code = 0; $err = ''
    try {
        $allow = @()
        if (Test-Path -LiteralPath $allowFile) {
            $allow = @(Get-Content -LiteralPath $allowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim().ToUpperInvariant() } | Where-Object { $_ })
        }
        $phones = @(Get-PnpDevice -Class WPD -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.InstanceId -match '^USB\\' })
        foreach ($d in $phones) {
            if ([string]$d.Problem -eq 'CM_PROB_DISABLED') { continue }
            $parent = ''
            try { $parent = [string](Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop).Data } catch { }
            $vid = ''; $pid_ = ''; $serial = ''
            $usbId = @($d.InstanceId, $parent) | Where-Object { $_ -match '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}\\' } | Select-Object -First 1
            if ($usbId -and $usbId -match '^USB\\VID_([0-9A-F]{4})&PID_([0-9A-F]{4})\\(.+)$') { $vid = $Matches[1]; $pid_ = $Matches[2]; $serial = $Matches[3] }
            $keys = @($serial, "${vid}:${pid_}", $d.InstanceId) | ForEach-Object { $_.ToUpperInvariant() }
            if (@($keys | Where-Object { $allow -contains $_ }).Count -gt 0) { continue }
            Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false
            if (-not (Test-Path -LiteralPath $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
            Add-Content -LiteralPath $stateFile -Value $d.InstanceId -Encoding ASCII
            $done += [pscustomobject]@{ Name = (Clean $d.FriendlyName); Vid = $vid; Pid = $pid_ }
        }
    } catch { $code = 1; $err = Clean $_.Exception.Message }
    if ($code -ne 0) { Say ('triplesoc-block-phone: telefonos USB bloqueados (codigo 1) error="{0}"' -f $err) }
    elseif ($done.Count -eq 0) { Say 'triplesoc-block-phone: sin telefonos por bloquear (codigo 0)' }
    else { Say ('triplesoc-block-phone: telefonos USB bloqueados (codigo 0) n={0} device="{1}" vid={2} pid={3}' -f $done.Count, $done[0].Name, $done[0].Vid, $done[0].Pid) }
}
elseif ($Mode -eq 'unblock') {
    $n = 0; $code = 0; $err = ''
    try {
        $ids = @()
        if (Test-Path -LiteralPath $stateFile) { $ids = @(Get-Content -LiteralPath $stateFile | Where-Object { $_ } | Select-Object -Unique) }
        foreach ($id in $ids) {
            $dev = Get-PnpDevice -InstanceId $id -ErrorAction SilentlyContinue
            if ($dev -and $dev.Present) { Enable-PnpDevice -InstanceId $id -Confirm:$false }
            else {
                # Desconectado: se borra su ficha y Windows lo instala de nuevo, ya habilitado, al volver a conectarlo.
                & $pnputil /remove-device $id | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "pnputil /remove-device devolvio $LASTEXITCODE" }
            }
            $n++
        }
        if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile -Force }
        & $pnputil /scan-devices | Out-Null
    } catch { $code = 1; $err = Clean $_.Exception.Message }
    Say ('triplesoc-unblock-phone: telefonos USB habilitados (codigo {0}) n={1}{2}' -f $code, $n, $(if ($err) { ' error="' + $err + '"' } else { '' }))
}
'@
    # Ratones y teclados USB (posible "BadUSB"): mismo esquema que los teléfonos.
    'triplesoc-block-input.cmd'   = @'
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0triplesoc-input.ps1" block >> "%~dp0..\active-responses.log" 2>nul
'@
    'triplesoc-unblock-input.cmd' = @'
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0triplesoc-input.ps1" unblock >> "%~dp0..\active-responses.log" 2>nul
'@
    # block:   desactiva cada dispositivo de entrada USB conectado (nodo "USB\VID_..." de clase HIDClass, el
    #          mismo que vigila la auditoría) que no esté en la lista de autorizados. El teclado y el touchpad
    #          integrados de un portátil no son USB: nunca se tocan.
    # unblock: vuelve a habilitar exactamente los que este script desactivó (los apunta en ProgramData).
    # Siempre deja una línea en active-responses.log: es la confirmación que lee el servidor.
    'triplesoc-input.ps1' = @'
param([string]$Mode)
$ErrorActionPreference = 'Stop'
$log       = Join-Path $PSScriptRoot '..\active-responses.log'
$allowFile = Join-Path $PSScriptRoot '..\..\shared\triplesoc-usb-allowlist.txt'
$stateDir  = Join-Path $env:ProgramData 'TripleSOC'
$stateFile = Join-Path $stateDir 'input-blocked.txt'
$pnputil   = Join-Path $env:windir 'Sysnative\pnputil.exe'
if (-not (Test-Path -LiteralPath $pnputil)) { $pnputil = Join-Path $env:windir 'System32\pnputil.exe' }

function Clean([string]$s) { if ($null -eq $s) { return '' }; return (($s -replace '[\x00-\x1f"]', "'" -replace '[^\x20-\x7e]', '?').Trim()) }
# La línea sale por la salida estándar y el .cmd la añade al registro con >> (igual que los scripts del USB).
function Say([string]$text) { Write-Output ((Get-Date -Format 'dd/MM/yyyy HH:mm:ss.ff') + ' ' + $text) }

if ($Mode -eq 'block') {
    $done = @(); $code = 0; $err = ''
    try {
        $allow = @()
        if (Test-Path -LiteralPath $allowFile) {
            $allow = @(Get-Content -LiteralPath $allowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim().ToUpperInvariant() } | Where-Object { $_ })
        }
        $devs = @(Get-PnpDevice -Class HIDClass -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.InstanceId -match '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}' })
        foreach ($d in $devs) {
            $vid = ''; $pid_ = ''; $serial = ''
            if ($d.InstanceId -match '^USB\\VID_([0-9A-F]{4})&PID_([0-9A-F]{4})[^\\]*\\(.+)$') { $vid = $Matches[1]; $pid_ = $Matches[2]; $serial = $Matches[3] }
            $parent = ''
            try { $parent = [string](Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop).Data } catch { }
            $keys = @($serial, "${vid}:${pid_}", $d.InstanceId, $parent) | Where-Object { $_ } | ForEach-Object { $_.ToUpperInvariant() }
            if (@($keys | Where-Object { $allow -contains $_ }).Count -gt 0) { continue }
            $name = $d.FriendlyName
            try { $desc = [string](Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction Stop).Data; if ($desc) { $name = $desc } } catch { }
            # Ya desactivado (se volvió a conectar uno bloqueado): sigue bloqueado, se confirma como tal.
            if ([string]$d.Problem -eq 'CM_PROB_DISABLED') { $done += [pscustomobject]@{ Name = (Clean $name); Vid = $vid; Pid = $pid_ }; continue }
            Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false
            if (-not (Test-Path -LiteralPath $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
            Add-Content -LiteralPath $stateFile -Value $d.InstanceId -Encoding ASCII
            $done += [pscustomobject]@{ Name = (Clean $name); Vid = $vid; Pid = $pid_ }
        }
    } catch { $code = 1; $err = Clean $_.Exception.Message }
    if ($code -ne 0) { Say ('triplesoc-block-input: entrada USB bloqueada (codigo 1) error="{0}"' -f $err) }
    elseif ($done.Count -eq 0) { Say 'triplesoc-block-input: sin entrada USB por bloquear (codigo 0)' }
    else { Say ('triplesoc-block-input: entrada USB bloqueada (codigo 0) n={0} device="{1}" vid={2} pid={3}' -f $done.Count, $done[0].Name, $done[0].Vid, $done[0].Pid) }
}
elseif ($Mode -eq 'unblock') {
    $n = 0; $code = 0; $err = ''
    try {
        $ids = @()
        if (Test-Path -LiteralPath $stateFile) { $ids = @(Get-Content -LiteralPath $stateFile | Where-Object { $_ } | Select-Object -Unique) }
        foreach ($id in $ids) {
            $dev = Get-PnpDevice -InstanceId $id -ErrorAction SilentlyContinue
            if ($dev -and $dev.Present) { Enable-PnpDevice -InstanceId $id -Confirm:$false }
            else {
                & $pnputil /remove-device $id | Out-Null
                if ($LASTEXITCODE -ne 0) { throw "pnputil /remove-device devolvio $LASTEXITCODE" }
            }
            $n++
        }
        if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile -Force }
        & $pnputil /scan-devices | Out-Null
    } catch { $code = 1; $err = Clean $_.Exception.Message }
    Say ('triplesoc-unblock-input: entrada USB habilitada (codigo {0}) n={1}{2}' -f $code, $n, $(if ($err) { ' error="' + $err + '"' } else { '' }))
}
'@
}

foreach ($name in $scripts.Keys) {
    $path = Join-Path $bin $name
    Set-Content -Path $path -Value $scripts[$name] -Encoding ASCII
    Write-Host "Instalado: $path"
}
Write-Host "Listo. Para deshacer a mano, ejecute como administrador:"
Write-Host "  almacenamiento USB: `"$bin\triplesoc-unblock-usb.cmd`""
Write-Host "  telefonos:          `"$bin\triplesoc-unblock-phone.cmd`""
Write-Host "  raton/teclado USB:  `"$bin\triplesoc-unblock-input.cmd`""

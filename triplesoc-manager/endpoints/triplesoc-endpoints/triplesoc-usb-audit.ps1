# TripleSOC - Auditoria de dispositivos USB: almacenamiento, telefonos y dispositivos de entrada (Windows).
# Lo distribuye el gestor (grupo triplesoc-endpoints, agent.conf) y el agente lo
# ejecuta cada 30 s como SYSTEM. Solo imprime una linea por cada dispositivo que
# aparecio desde la ejecucion anterior (sin salida = sin eventos):
#   TRIPLESOC_USB status=unauthorized device="..." vid=... pid=... serial=... instance="..." blocked=yes|no
# blocked=yes: es almacenamiento USB y el equipo lo tiene bloqueado (USBSTOR desactivado por
# triplesoc-block-usb.cmd), o es un telefono, raton o teclado que triplesoc-block-phone/input dejo
# desactivado: el dispositivo se ve pero no se puede usar.
# Lista de permitidos: triplesoc-usb-allowlist.txt (se distribuye junto a este script).
$ErrorActionPreference = 'Stop'

$stateDir  = Join-Path $env:ProgramData 'TripleSOC'
$stateFile = Join-Path $stateDir 'usb-audit.state'
$allowFile = Join-Path $PSScriptRoot 'triplesoc-usb-allowlist.txt'

function Clean([string]$s) { if ($null -eq $s) { return '' }; return (($s -replace '[\x00-\x1f"]', "'" -replace '[^\x20-\x7e]', '?').Trim()) }

try {
    # Lista de permitidos: un numero de serie, VID:PID o instance ID por linea; '#' comenta.
    $allow = @()
    if (Test-Path -LiteralPath $allowFile) {
        $allow = @(Get-Content -LiteralPath $allowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim().ToUpperInvariant() } | Where-Object { $_ })
    }

    # Dispositivos USB capaces de transferir datos:
    #  - DiskDrive con padre USB: memorias (USBSTOR) y discos USB 3 (UASP).
    #  - WPD con instancia o padre USB: telefonos/tablets en modo "Transferencia de archivos" (MTP/PTP).
    #    Los volumenes de memorias montados (SWD\WPDBUSENUM) no cuentan: su padre no es USB.
    #  - HIDClass con instancia USB: dispositivos de entrada USB (teclados, ratones, mandos, "BadUSB").
    #    Los de entrada internos (I2C/ACPI) y Bluetooth no son USB y se ignoran. Un dispositivo
    #    con varias interfaces (&MI_xx) se cuenta una sola vez, por su dispositivo USB padre.
    $devices = @(Get-PnpDevice -Class DiskDrive -PresentOnly -ErrorAction SilentlyContinue) +
               @(Get-PnpDevice -Class WPD -PresentOnly -ErrorAction SilentlyContinue) +
               @(Get-PnpDevice -Class HIDClass -PresentOnly -ErrorAction SilentlyContinue)
    $current = @{}
    foreach ($d in $devices) {
        if ($null -eq $d) { continue }
        $parent = ''
        try { $parent = [string](Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop).Data } catch { }
        $key = $d.InstanceId; $name = $d.FriendlyName
        if ($d.Class -eq 'HIDClass') {
            if ($d.InstanceId -notmatch '^USB\\') { continue }
            if ($d.InstanceId -match '&MI_[0-9A-F]{2}' -and $parent -match '^USB\\VID_') { $key = $parent }
            if ($current.ContainsKey($key)) { continue }
            $desc = ''
            try { $desc = [string](Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_BusReportedDeviceDesc' -ErrorAction Stop).Data } catch { }
            $name = if ($desc) { "$desc (dispositivo de entrada USB)" } else { $d.FriendlyName }
        }
        elseif ($d.InstanceId -notmatch '^(USBSTOR|USB)\\' -and $parent -notmatch '^USB\\') { continue }

        # VID/PID/serie del dispositivo USB fisico: la propia instancia si no es una interfaz (&MI_), si no el padre.
        $vid = ''; $pid_ = ''; $serial = ''
        $usbId = @($d.InstanceId, $parent) | Where-Object { $_ -match '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}\\' } | Select-Object -First 1
        if ($usbId -and $usbId -match '^USB\\VID_([0-9A-F]{4})&PID_([0-9A-F]{4})\\(.+)$') { $vid = $Matches[1]; $pid_ = $Matches[2]; $serial = $Matches[3] }
        elseif ($d.InstanceId -match '\\([^\\]+?)(&\d+)?$') { $serial = $Matches[1] }

        $current[$key] = [pscustomobject]@{
            Instance = $key; Name = $name; Vid = $vid; Pid = $pid_; Serial = $serial; Storage = ($d.Class -eq 'DiskDrive')
            # Telefono, raton o teclado desactivado por triplesoc-block-phone/input: Windows lo ve conectado
            # pero no lo deja usar. Se informa como ya bloqueado (regla 100914), no como amenaza nueva.
            Disabled = ($d.Class -in 'WPD', 'HIDClass' -and [string]$d.Problem -eq 'CM_PROB_DISABLED')
        }
    }

    $previous = @()
    if (Test-Path -LiteralPath $stateFile) { $previous = @(Get-Content -LiteralPath $stateFile | Where-Object { $_ }) }

    # Start=4 en USBSTOR = almacenamiento USB desactivado (lo pone triplesoc-block-usb.cmd; 3 = normal).
    $storageBlocked = $false
    try { $storageBlocked = ((Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR' -Name Start -ErrorAction Stop).Start -eq 4) } catch { }

    foreach ($dev in $current.Values) {
        if ($previous -contains $dev.Instance) { continue }   # ya conectado en la ejecucion anterior
        $keys = @($dev.Serial, "$($dev.Vid):$($dev.Pid)", $dev.Instance) | ForEach-Object { $_.ToUpperInvariant() }
        $status = if (@($keys | Where-Object { $allow -contains $_ }).Count -gt 0) { 'authorized' } else { 'unauthorized' }
        $blocked = if (($dev.Storage -and $storageBlocked) -or $dev.Disabled) { 'yes' } else { 'no' }
        'TRIPLESOC_USB status={0} device="{1}" vid={2} pid={3} serial={4} instance="{5}" blocked={6}' -f `
            $status, (Clean $dev.Name), $dev.Vid, $dev.Pid, (Clean $dev.Serial), (Clean $dev.Instance), $blocked
    }

    if (-not (Test-Path -LiteralPath $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    Set-Content -LiteralPath $stateFile -Value @($current.Keys) -Encoding ASCII
}
catch {
    'TRIPLESOC_USB status=error message="{0}"' -f (Clean $_.Exception.Message)
}

# Instala el agente Wazuh en un equipo Windows y lo une al grupo triplesoc-endpoints.
# Ejecutar en PowerShell COMO ADMINISTRADOR:
#   powershell -ExecutionPolicy Bypass -File .\install-agent-windows.ps1
# La contrasena de registro (authd.pass del manager) se pide por teclado y no se guarda.
param(
    [string]$Manager = '20.65.219.193',
    [string]$Group   = 'triplesoc-endpoints',
    [string]$Version = '4.14.7-1'
)
$ErrorActionPreference = 'Stop'

$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Ejecuta este script como Administrador.' }

$msi = Join-Path $env:TEMP "wazuh-agent-$Version.msi"
Write-Host "Descargando wazuh-agent-$Version.msi desde packages.wazuh.com..."
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-$Version.msi" -OutFile $msi -UseBasicParsing

$sig = Get-AuthenticodeSignature $msi
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Wazuh') { throw "Firma del instalador no valida: $($sig.Status) $($sig.SignerCertificate.Subject)" }
Write-Host "Firma verificada: $($sig.SignerCertificate.Subject)"

$sec = Read-Host 'Contrasena de registro de agentes (authd.pass)' -AsSecureString
$pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))

$args_ = @('/i', "`"$msi`"", '/qn', "WAZUH_MANAGER=$Manager", "WAZUH_REGISTRATION_SERVER=$Manager",
           "WAZUH_REGISTRATION_PASSWORD=$pass", "WAZUH_AGENT_GROUP=$Group", "WAZUH_AGENT_NAME=$env:COMPUTERNAME")
$p = Start-Process msiexec.exe -ArgumentList $args_ -Wait -PassThru
$pass = $null
if ($p.ExitCode -ne 0) { throw "msiexec termino con codigo $($p.ExitCode)" }

# Permite al agente ejecutar los comandos que llegan por la configuracion centralizada
# (agent.conf del grupo). Wazuh lo exige en local por seguridad; se fija una sola vez al instalar.
$dir  = "${env:ProgramFiles(x86)}\ossec-agent"
$opts = Join-Path $dir 'local_internal_options.conf'
if (-not (Select-String -Path $opts -Pattern '^\s*logcollector\.remote_commands\s*=\s*1' -Quiet)) {
    Add-Content -Path $opts -Value "`r`n# TripleSOC: comandos del agent.conf centralizado (auditoria USB)`r`nlogcollector.remote_commands=1" -Encoding ASCII
}

Start-Service WazuhSvc
Start-Sleep -Seconds 15
Get-Service WazuhSvc | Format-Table -AutoSize Name, Status
Get-Content (Join-Path $dir 'ossec.log') -Tail 15

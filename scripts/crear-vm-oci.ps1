<#
.SYNOPSIS
    Configura los secretos de Oracle Cloud y dispara el pipeline que crea la VM con Terraform.
.DESCRIPTION
    Lee los datos OCI de secrets/credenciales.txt, registra los secretos en GitHub
    y hace push a main. La clave API se guarda como base64 para soportar saltos de línea.
    No imprime secretos.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$cfg = @{}
$configPath = Join-Path $root 'secrets\credenciales.txt'
if (-not (Test-Path -LiteralPath $configPath)) { throw 'Falta secrets/credenciales.txt' }
foreach ($line in Get-Content -LiteralPath $configPath) {
    if ($line -match '^\s*([A-Z0-9_]+)\s*=\s*(.*)$') { $cfg[$Matches[1]] = $Matches[2].Trim().Trim('"', "'") }
}
if ($cfg.ContainsKey('GH_TOKEN') -and -not $env:GH_TOKEN) { $env:GH_TOKEN = $cfg['GH_TOKEN'] }

$required = @('OCI_TENANCY_OCID', 'OCI_USER_OCID', 'OCI_FINGERPRINT', 'OCI_PRIVATE_KEY_B64')
$missing = $required | Where-Object { -not $cfg[$_] }
if ($missing) { throw "Faltan en secrets/credenciales.txt: $($missing -join ', ')" }

$repo = if ($cfg['REPO']) { $cfg['REPO'] } else { 'rodr1go258/duo-portfolio' }
$region = if ($cfg['OCI_REGION']) { $cfg['OCI_REGION'] } else { 'sa-saopaulo-1' }
$compartment = if ($cfg['OCI_COMPARTMENT_OCID']) { $cfg['OCI_COMPARTMENT_OCID'] } else { $cfg['OCI_TENANCY_OCID'] }
$shape = if ($cfg['OCI_SHAPE']) { $cfg['OCI_SHAPE'] } else { 'VM.Standard.E3.Flex' }

function Write-Step([string]$message) { Write-Host "`n=== $message ===" -ForegroundColor Cyan }
function Invoke-Native([scriptblock]$Command) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return & $Command 2>&1 } finally { $ErrorActionPreference = $previous }
}

$privateKey = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($cfg['OCI_PRIVATE_KEY_B64']))
$sshPublicKeyPath = Join-Path $root 'secrets\id_ed25519.pub'
$sshPrivateKeyPath = Join-Path $root 'secrets\id_ed25519'
$sshPublicKey = if (Test-Path -LiteralPath $sshPublicKeyPath) { (Get-Content -LiteralPath $sshPublicKeyPath -Raw).Trim() } else { $null }
$sshPrivateKey = if (Test-Path -LiteralPath $sshPrivateKeyPath) { (Get-Content -LiteralPath $sshPrivateKeyPath -Raw) } else { $null }

Write-Step "1/4 Configurando secretos OCI en $repo"
$secrets = @{
    'OCI_TENANCY_OCID'    = $cfg['OCI_TENANCY_OCID']
    'OCI_USER_OCID'       = $cfg['OCI_USER_OCID']
    'OCI_FINGERPRINT'     = $cfg['OCI_FINGERPRINT']
    'OCI_PRIVATE_KEY'     = $privateKey
    'OCI_REGION'          = $region
    'OCI_COMPARTMENT_OCID' = $compartment
    'OCI_SHAPE'           = $shape
    'SSH_PUBLIC_KEY'      = $sshPublicKey
    'SSH_PRIVATE_KEY'     = $sshPrivateKey
}
foreach ($name in $secrets.Keys) {
    if ([string]::IsNullOrWhiteSpace($secrets[$name])) { Write-Host "  - $name : omitido" -ForegroundColor DarkGray; continue }
    $null = Invoke-Native { $secrets[$name] | gh secret set $name --repo $repo }
    if ($LASTEXITCODE -ne 0) { throw "No se pudo registrar $name" }
    Write-Host "  + $name" -ForegroundColor Green
}

Write-Step '2/4 Secretos registrados'
Invoke-Native { gh secret list --repo $repo } | Select-String 'OCI_'

Write-Step '3/4 Disparando el pipeline (push a main)'
$msg = 'trigger: aprovisionar VM OCI (Terraform + setup_vm.sh)'
$null = Invoke-Native { git commit --allow-empty -m $msg } | Out-Null
Invoke-Native { git push origin main } | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falló el push a main' }
Invoke-Native { git push origin dev } | Out-Null
Invoke-Native { git push backup main:main dev:dev --force } | Out-Null

Write-Step '4/4 Ejecución lanzada'
$run = Invoke-Native { gh run list --repo $repo --branch main --limit 1 --json databaseId,url }
Write-Host $run -ForegroundColor Green

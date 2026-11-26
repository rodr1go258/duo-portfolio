<#
.SYNOPSIS
    Configura los secretos AWS y dispara el pipeline que crea la VM con Terraform.
.DESCRIPTION
    Lee AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY y AWS_REGION de
    secrets/credenciales.txt, los registra en el repositorio y hace push a main.
    No imprime las claves.
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

$missing = @('AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY') | Where-Object { -not $cfg[$_] }
if ($missing) { throw "Faltan en secrets/credenciales.txt: $($missing -join ', ')" }
$region = if ($cfg['AWS_REGION']) { $cfg['AWS_REGION'] } else { 'us-east-1' }
$repo = if ($cfg['REPO']) { $cfg['REPO'] } else { 'rodr1go258/duo-portfolio' }

function Write-Step([string]$message) { Write-Host "`n=== $message ===" -ForegroundColor Cyan }
function Invoke-Native([scriptblock]$Command) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return & $Command 2>&1 } finally { $ErrorActionPreference = $previous }
}

Write-Step "1/4 Configurando secretos AWS en $repo"
foreach ($name in @('AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY')) {
    $null = Invoke-Native { $cfg[$name] | gh secret set $name --repo $repo }
    if ($LASTEXITCODE -ne 0) { throw "No se pudo registrar $name" }
    Write-Host "  + $name" -ForegroundColor Green
}
$null = Invoke-Native { $region | gh secret set AWS_REGION --repo $repo }
if ($LASTEXITCODE -ne 0) { throw 'No se pudo registrar AWS_REGION' }
Write-Host "  + AWS_REGION=$region" -ForegroundColor Green

Write-Step '2/4 Secretos registrados'
Invoke-Native { gh secret list --repo $repo } | Select-String 'AWS_'

Write-Step '3/4 Disparando el pipeline (push a main)'
$msg = 'trigger: aprovisionar VM AWS (Terraform + setup_vm.sh)'
$null = Invoke-Native { git commit --allow-empty -m $msg } | Out-Null
Invoke-Native { git push origin main } | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falló el push a main' }
Invoke-Native { git push origin dev } | Out-Null
Invoke-Native { git push backup main:main dev:dev --force } | Out-Null

Write-Step '4/4 Ejecución lanzada'
$run = Invoke-Native { gh run list --repo $repo --branch main --limit 1 --json databaseId,url }
Write-Host $run -ForegroundColor Green
Write-Host @"

El pipeline creara: VPC, 2 subnets, EIP, EC2 Ubuntu 24.04 + VNC,
configurara la VM con Docker/Git/UFW/iptables 80-443 y desplegara el stack.
"@ -ForegroundColor Yellow

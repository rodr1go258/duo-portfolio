<#
.SYNOPSIS
    Abre la demostración completa: VS Code, Docker Desktop, stack local y evidencias en el navegador.
.DESCRIPTION
    Prepara el entorno para la defensa sin depender de AWS: levanta los contenedores,
    abre los archivos clave en VS Code y las URLs de evidencia en el navegador.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step([string]$message) { Write-Host "`n=== $message ===" -ForegroundColor Cyan }

Write-Step '1/4 Docker Desktop'
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
    if (Test-Path -LiteralPath $dockerDesktop) { Start-Process -FilePath $dockerDesktop | Out-Null }
}
$deadline = (Get-Date).AddSeconds(60)
while ((Get-Date) -lt $deadline) {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 2
}
if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop no respondió; ábrelo manualmente.' }
Write-Host 'Docker Desktop OK' -ForegroundColor Green

Write-Step '2/4 Stack local (HTTP 8081 / HTTPS 8443)'
$env:HTTP_PORT = '8081'
$env:HTTPS_PORT = '8443'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$null = docker compose up -d 2>&1
$ErrorActionPreference = $previous
$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    try {
        $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8081/api/health' -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) { break }
    } catch { Start-Sleep -Seconds 2 }
}
Write-Host 'Contenedores levantados y API respondiendo' -ForegroundColor Green

Write-Step '3/4 VS Code'
$files = @(
    '.github\workflows\pipeline.yml',
    'README.md',
    'docs\DEFENSA.md',
    'docs\ARQUITECTURA.md',
    'infra\terraform\main.tf',
    'scripts\setup_vm.sh'
) | ForEach-Object { Join-Path $root $_ }
code --new-window $files | Out-Null
Write-Host 'VS Code abierto con los archivos clave' -ForegroundColor Green

Write-Step '4/4 Navegador'
$urls = @(
    'https://github.com/rodr1go258/duo-portfolio',
    'https://github.com/rodr1go258/duo-portfolio/actions',
    'https://github.com/rodr1go258/duo-portfolio/actions/runs/45826186316',
    'https://hub.docker.com/r/rodr1go258/duo-portfolio',
    'http://127.0.0.1:8081/api/health',
    'https://github.com/rodr1go258/duo-portfolio/blob/main/docs/DEFENSA.md'
)
foreach ($url in $urls) { Start-Process $url | Out-Null }
Write-Host 'Evidencias abiertas en el navegador' -ForegroundColor Green

Write-Host @"

Listo para defender:
  - Repo y pipeline: https://github.com/rodr1go258/duo-portfolio
  - dev: 39 tests en verde
  - main: Docker Hub OK; Terraform init/validate OK; plan detenido por OptInRequired (EC2 sin suscribir, cuenta sin tarjeta)
  - Local: HTTP 8081 y HTTPS 8443 respondiendo

No digas que la VM de AWS existe: el bloqueo es externo y está documentado en docs/DEFENSA.md.
"@ -ForegroundColor Yellow

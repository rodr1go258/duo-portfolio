<#
.SYNOPSIS
    Crea el repositorio en Docker Hub y publica la imagen del proyecto.
.DESCRIPTION
    Lee DOCKERHUB_USERNAME y DOCKERHUB_TOKEN de secrets/credenciales.txt.
    No imprime el token. Etiqueta con 'latest' y con el SHA corto del commit.
#>
[CmdletBinding()]
param(
    [string]$ImageName = 'duo-portfolio'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$cfg = @{}
$configPath = Join-Path $root 'secrets\credenciales.txt'
if (-not (Test-Path -LiteralPath $configPath)) { throw 'Falta secrets/credenciales.txt' }
foreach ($line in Get-Content -LiteralPath $configPath) {
    if ($line -match '^\s*([A-Z0-9_]+)\s*=\s*(.*)$') { $cfg[$Matches[1]] = $Matches[2].Trim().Trim('"', "'") }
}
$user = $cfg['DOCKERHUB_USERNAME']
$token = $cfg['DOCKERHUB_TOKEN']
if (-not $user -or -not $token) { throw 'Faltan DOCKERHUB_USERNAME o DOCKERHUB_TOKEN' }

function Write-Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

$fullName = "$user/$ImageName"
$apiRepo = "https://hub.docker.com/v2/namespaces/$user/repositories/$ImageName"

Write-Step "1/4 Login en Docker Hub como $user"
$token | docker login -u $user --password-stdin
if ($LASTEXITCODE -ne 0) { throw 'docker login falló' }

Write-Step "2/4 Asegurando el repositorio $fullName"
# La API de Hub no acepta el PAT como bearer: primero se cambia por un JWT.
$authBody = @{ identifier = $user; secret = $token } | ConvertTo-Json
$authResp = Invoke-RestMethod -Uri 'https://hub.docker.com/v2/auth/token' -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 60
$jwt = $authResp.access_token
if (-not $jwt) { throw 'No se pudo obtener el token de la API de Docker Hub' }
$headers = @{ Authorization = "Bearer $jwt" }
$apiBase = "https://hub.docker.com/v2/namespaces/$user/repositories"
$exists = $false
try {
    $null = Invoke-RestMethod -Uri $apiRepo -Headers $headers -Method Get -TimeoutSec 30
    $exists = $true
} catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
}
if (-not $exists) {
    $body = @{
        name        = $ImageName
        namespace   = $user
        registry    = 'docker.io'
        is_private  = $true
        description = 'MVP duo-portfolio: React + Express + PostgreSQL, CI/CD con GitHub Actions'
    } | ConvertTo-Json
    $null = Invoke-RestMethod -Uri "$apiBase" -Headers $headers -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 60
    Write-Host 'Repositorio creado.' -ForegroundColor Green
} else {
    Write-Host 'El repositorio ya existía.' -ForegroundColor DarkGray
}

$sha = (git rev-parse --short HEAD).Trim()
Write-Step "3/4 Construyendo y etiquetando ($sha)"
docker build -t "${fullName}:latest" -t "${fullName}:${sha}" .
if ($LASTEXITCODE -ne 0) { throw 'docker build falló' }

Write-Step '4/4 Publicando imagen'
docker push "${fullName}:latest"
if ($LASTEXITCODE -ne 0) { throw 'docker push latest falló' }
docker push "${fullName}:${sha}"
if ($LASTEXITCODE -ne 0) { throw "docker push $sha falló" }

Write-Host @"

IMAGEN PUBLICADA:
  ${fullName}:latest
  ${fullName}:${sha}
  https://hub.docker.com/r/$fullName
"@ -ForegroundColor Green

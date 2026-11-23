<#
.SYNOPSIS
    Simula localmente el pipeline completo y verifica el stack desplegado.
.DESCRIPTION
    Ejecuta build, 39 pruebas, construcción de la imagen Docker, arranque de
    docker compose y smoke test HTTP/HTTPS. No necesita AWS ni Docker Hub.
#>
[CmdletBinding()]
param(
    [int]$HttpPort = 8081,
    [int]$HttpsPort = 8443,
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

function Invoke-Checked([string]$command, [string]$message, [int]$retries = 1) {
    Write-Step $message
    for ($attempt = 1; $attempt -le $retries; $attempt++) {
        Invoke-Expression $command
        if ($LASTEXITCODE -eq 0) { return }
        if ($attempt -lt $retries) {
            Write-Host "  Reintentando ($attempt/$retries) en 5 s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    throw "Fallo en: $command (exit=$LASTEXITCODE)"
}

Write-Step '0/9 Comprobación de herramientas'
foreach ($tool in @('node', 'npm', 'docker')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "No se encontró $tool en el PATH"
    }
}
node --version
npm --version
docker --version

if (-not $SkipInstall) {
    Invoke-Checked 'npm ci --no-audit --no-fund' '1/9 Instalando dependencias'
} else {
    Write-Step '1/9 Instalación omitida (-SkipInstall)'
}

Invoke-Checked 'npm run build' '2/9 Compilando API y frontend'
Invoke-Checked 'npm run test:unit -w @duo/api' '3/9 Tests unitarios (16)'
Invoke-Checked 'npm run test:integration -w @duo/api' '4/9 Tests de integración (12)'

Write-Step '5/9 Instalando Chromium para Playwright'
Push-Location (Join-Path $root 'apps\web')
try {
    npx playwright install chromium
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar Chromium' }
} finally {
    Pop-Location
}

Invoke-Checked 'npm run test:e2e -w @duo/web' '6/9 Tests E2E (11)'
Invoke-Checked 'docker build -t duo-portfolio:local .' '7/9 Construyendo imagen Docker' -retries 3

$env:HTTP_PORT = "$HttpPort"
$env:HTTPS_PORT = "$HttpsPort"
$composeUp = $false
try {
    Invoke-Checked 'docker compose up -d' '8/9 Levantando contenedores' -retries 3
    $composeUp = $true

    $healthy = $false
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        for ($i = 1; $i -le 30; $i++) {
            $body = & curl.exe --noproxy '*' -s "http://127.0.0.1:$HttpPort/api/health" 2>$null
            if ($LASTEXITCODE -eq 0 -and $body -match '"status":"ok"') {
                $healthy = $true
                break
            }
            Start-Sleep -Seconds 1
        }
    } finally {
        $ErrorActionPreference = $previousEap
    }
    if (-not $healthy) { throw 'La API no respondió /api/health tras 30 segundos' }

    Write-Step '9/9 Smoke test'
    Write-Host "HTTP  : $body" -ForegroundColor Green

    $httpsStatus = & curl.exe --noproxy '*' -k -sS -o NUL -w '%{http_code}' "https://127.0.0.1:$HttpsPort/api/health"
    Write-Host "HTTPS : status=$httpsStatus" -ForegroundColor Green
    if ($httpsStatus -ne '200') { throw "HTTPS devolvió $httpsStatus" }

    $projects = & curl.exe --noproxy '*' -sS "http://127.0.0.1:$HttpPort/api/projects"
    $count = ($projects | ConvertFrom-Json).Count
    Write-Host "BD    : $count proyectos semilla" -ForegroundColor Green
    if ($count -lt 3) { throw "Se esperaban al menos 3 proyectos, hay $count" }

    docker compose ps
    Write-Host "`nVERIFICACIÓN COMPLETA: build + 39 tests + Docker + HTTP/HTTPS OK" -ForegroundColor Green
} finally {
    if ($composeUp) {
        Write-Step 'Limpiando contenedores y volúmenes'
        docker compose down -v
    }
}

<#
.SYNOPSIS
    Prepara el repositorio remoto, los secretos y los pushes del pipeline.
.DESCRIPTION
    Requiere GitHub CLI (gh) autenticado:  gh auth login
    Ejemplo:
      .\bootstrap-github.ps1 -Repo TU_USUARIO/duo-portfolio -DockerHubUser TU_USER `
        -DockerHubToken TU_TOKEN -AwsKey ... -AwsSecret ... `
        -SshPublicKey 'ssh-ed25519 AAAA...' -SshPrivateKeyPath C:\claves\id_ed25519 -Push
#>
[CmdletBinding()]
param(
    [string]$Repo,

    [string]$DockerHubUser,
    [string]$DockerHubToken,
    [string]$AwsKey,
    [string]$AwsSecret,
    [string]$AwsRegion = 'us-east-1',
    [string]$SshPublicKey,
    [string]$SshPrivateKeyPath,
    [string]$SshUser = 'ubuntu',
    [string]$SshCidr = '0.0.0.0/0',
    [string]$DbPassword = 'portfolio',
    [string]$VncPassword = 'duoportfolio',

    [switch]$CreateRepo,
    [switch]$Push,
    [switch]$SkipSecrets,
    [switch]$InstallGh
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Los valores pueden venir de secrets/credenciales.txt (ignorado por Git).
$configPath = Join-Path $root 'secrets\credenciales.txt'
$cfg = @{}
if (Test-Path -LiteralPath $configPath) {
    foreach ($line in Get-Content -LiteralPath $configPath) {
        if ($line -match '^\s*([A-Z0-9_]+)\s*=\s*(.*)$') {
            $cfg[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
        }
    }
}
$configMap = @{
    Repo            = 'REPO'
    DockerHubUser   = 'DOCKERHUB_USERNAME'
    DockerHubToken  = 'DOCKERHUB_TOKEN'
    AwsKey          = 'AWS_ACCESS_KEY_ID'
    AwsSecret       = 'AWS_SECRET_ACCESS_KEY'
    AwsRegion       = 'AWS_REGION'
    SshUser         = 'SSH_USER'
    SshCidr         = 'SSH_CIDR'
    DbPassword      = 'DB_PASSWORD'
    VncPassword     = 'VNC_PASSWORD'
}
foreach ($param in $configMap.Keys) {
    if (-not $PSBoundParameters.ContainsKey($param) -and $cfg.ContainsKey($configMap[$param])) {
        Set-Variable -Name $param -Value $cfg[$configMap[$param]]
    }
}
foreach ($switchMap in @(@('CreateRepo', 'CREATE_REPO'), @('Push', 'PUSH'), @('SkipSecrets', 'SKIP_SECRETS'))) {
    if (-not $PSBoundParameters.ContainsKey($switchMap[0]) -and
        $cfg.ContainsKey($switchMap[1]) -and
        $cfg[$switchMap[1]] -match '^(1|true|si|yes)$') {
        Set-Variable -Name $switchMap[0] -Value $true
    }
}
if (-not $SshPublicKey -and (Test-Path -LiteralPath (Join-Path $root 'secrets\id_ed25519.pub'))) {
    $SshPublicKey = Get-Content -LiteralPath (Join-Path $root 'secrets\id_ed25519.pub') -Raw
}
if (-not $SshPrivateKeyPath -and (Test-Path -LiteralPath (Join-Path $root 'secrets\id_ed25519'))) {
    $SshPrivateKeyPath = Join-Path $root 'secrets\id_ed25519'
}
if ([string]::IsNullOrWhiteSpace($Repo)) {
    throw 'Falta REPO: pásalo con -Repo o defínelo en secrets/credenciales.txt'
}
if ($cfg.ContainsKey('GH_TOKEN') -and -not $env:GH_TOKEN) {
    $env:GH_TOKEN = $cfg['GH_TOKEN']
}

function Write-Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

# Los comandos nativos escriben en stderr incluso cuando salen bien; con
# ErrorActionPreference=Stop PowerShell lo trataba como error terminating.
function Invoke-Native([scriptblock]$Command) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return & $Command 2>&1 } finally { $ErrorActionPreference = $previous }
}

Write-Step '0/5 Comprobando GitHub CLI'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    if ($InstallGh) {
        winget install --id GitHub.cli --exact --accept-source-agreements --accept-package-agreements
        throw 'GitHub CLI instalado. Vuelve a abrir la terminal y ejecuta: gh auth login'
    }
    throw 'Falta GitHub CLI. Instálalo con: winget install --id GitHub.cli  y luego: gh auth login'
}

$auth = Invoke-Native { gh auth status }
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub CLI no está autenticado. Ejecuta: gh auth login'
}
Write-Host 'GitHub CLI autenticado.' -ForegroundColor Green

# Acepta owner/repo, https://github.com/owner/repo(.git) o git@github.com:owner/repo.git
$slug = $Repo
if ($Repo -match 'github\.com[:/]([^/]+)/([^/\s]+?)(\.git)?$') {
    $slug = "$($Matches[1])/$($Matches[2])"
}
$remoteUrl = "https://github.com/$slug.git"

Write-Step "1/5 Repositorio remoto: $slug"
if ($CreateRepo) {
    $existing = Invoke-Native { gh repo view $slug }
    if ($LASTEXITCODE -ne 0) {
        Invoke-Native { gh repo create $slug --private --confirm } | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el repositorio' }
    }
}

$currentRemote = Invoke-Native { git remote get-url origin }
if ($LASTEXITCODE -eq 0) {
    git remote set-url origin $remoteUrl
} else {
    git remote add origin $remoteUrl
}
Write-Host "origin = $remoteUrl" -ForegroundColor Green

if (-not $SkipSecrets) {
    Write-Step '2/5 Configurando secretos'
    $privateKey = $null
    if ($SshPrivateKeyPath) {
        if (-not (Test-Path $SshPrivateKeyPath)) { throw "No existe $SshPrivateKeyPath" }
        $privateKey = Get-Content -LiteralPath $SshPrivateKeyPath -Raw
    }

    $secrets = @{
        DOCKERHUB_USERNAME   = $DockerHubUser
        DOCKERHUB_TOKEN      = $DockerHubToken
        AWS_ACCESS_KEY_ID    = $AwsKey
        AWS_SECRET_ACCESS_KEY = $AwsSecret
        AWS_REGION           = $AwsRegion
        SSH_PUBLIC_KEY       = $SshPublicKey
        SSH_PRIVATE_KEY      = $privateKey
        SSH_USER             = $SshUser
        SSH_CIDR             = $SshCidr
        DB_PASSWORD          = $DbPassword
        VNC_PASSWORD         = $VncPassword
    }

    foreach ($name in $secrets.Keys | Sort-Object) {
        $value = $secrets[$name]
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "  - $name : omitido (no proporcionado)" -ForegroundColor DarkGray
            continue
        }
        $null = Invoke-Native { $value | gh secret set $name --repo $slug }
        if ($LASTEXITCODE -ne 0) { throw "No se pudo configurar $name" }
        Write-Host "  + $name" -ForegroundColor Green
    }
} else {
    Write-Step '2/5 Secretos omitidos (-SkipSecrets)'
}

Write-Step '3/5 Estado local'
$branch = (Invoke-Native { git rev-parse --abbrev-ref HEAD } | Select-Object -First 1)
Write-Host "Rama actual: $branch"
git status --short

if ($Push) {
    Write-Step '4/5 Publicando ramas'
    Invoke-Native { git push -u origin main } | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Falló el push a main' }
    Invoke-Native { git push -u origin dev } | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Falló el push a dev' }
    Write-Host 'Push completado: el pipeline se dispara automáticamente.' -ForegroundColor Green
} else {
    Write-Step '4/5 Push omitido (añade -Push para publicar)'
}

Write-Step '5/5 Resumen'
Write-Host @"
Repositorio : $remoteUrl
Secretos    : $(if ($SkipSecrets) { 'omitidos' } else { 'configurados' })
Push        : $(if ($Push) { 'realizado' } else { 'pendiente' })

Siguiente paso recomendado:
  git push -u origin main   # dispara las 10 etapas de infraestructura
  git push -u origin dev    # dispara las 39 pruebas
"@ -ForegroundColor Yellow

<#
.SYNOPSIS
    Recupera los tokens ya guardados en esta máquina y los escribe en
    secrets/credenciales.txt (ignorado por Git). No imprime los secretos.
.DESCRIPTION
    - GitHub: Git Credential Manager (entrada git:https://github.com).
    - Docker Hub: Docker Desktop credential helper (index.docker.io/v1).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root 'secrets\credenciales.txt'

function Get-GithubCredential {
    $env:GIT_TERMINAL_PROMPT = '0'
    $raw = ("protocol=https`nhost=github.com`n`n" | git credential fill 2>&1) -join "`n"
    $user = [regex]::Match($raw, '(?m)^username=(.+)$').Groups[1].Value.Trim()
    $pass = [regex]::Match($raw, '(?m)^password=(.+)$').Groups[1].Value.Trim()
    if (-not $user -or -not $pass) { throw 'No se pudo recuperar la credencial de GitHub' }
    return @{ User = $user; Token = $pass }
}

function Get-DockerCredential {
    $helper = 'C:\Users\10\AppData\Local\Programs\DockerDesktop\resources\bin\docker-credential-desktop.exe'
    if (-not (Test-Path -LiteralPath $helper)) {
        $helper = (Get-Command docker-credential-desktop.exe -ErrorAction SilentlyContinue).Source
    }
    if (-not $helper) { throw 'No se encontró docker-credential-desktop.exe' }
    $json = ('https://index.docker.io/v1/' | & $helper get 2>&1) -join "`n"
    $obj = $json | ConvertFrom-Json
    if (-not $obj.Username -or -not $obj.Secret) { throw 'No se pudo recuperar la credencial de Docker Hub' }
    return @{ User = $obj.Username; Token = $obj.Secret }
}

$gh = Get-GithubCredential
$dh = Get-DockerCredential

$lines = @(
    '# Generado automaticamente desde el almacen de credenciales local. NO versionar.',
    "REPO=$($gh.User)/duo-portfolio",
    "GH_TOKEN=$($gh.Token)",
    "DOCKERHUB_USERNAME=$($dh.User)",
    "DOCKERHUB_TOKEN=$($dh.Token)",
    'AWS_REGION=us-east-1',
    'SSH_USER=ubuntu',
    'SSH_CIDR=0.0.0.0/0',
    'DB_PASSWORD=portfolio',
    'VNC_PASSWORD=duoportfolio',
    'CREATE_REPO=true',
    'PUSH=true'
)
Set-Content -LiteralPath $dest -Value $lines -Encoding UTF8

Write-Host "GitHub  : usuario=$($gh.User)  tokenLen=$($gh.Token.Length)"
Write-Host "Docker  : usuario=$($dh.User)  tokenLen=$($dh.Token.Length)"
Write-Host "Archivo : $dest (ignorado por Git)"

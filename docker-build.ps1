# PowerShell helper script to build Tejas Linux using Docker on Windows
# Usage: .\docker-build.ps1 [user|pro]

param(
    [Parameter(Position=0)]
    [ValidateSet("user", "pro")]
    [string]$BuildProfile = "user"
)

$ErrorActionPreference = "Stop"

# Check if Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Error: Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}

# Always rebuild the Docker image to ensure latest code is included
# Docker's layer caching makes this fast if nothing changed
Write-Host "[INFO] Building Docker image (with project code)..." -ForegroundColor Cyan
docker build -t tejas-builder .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Docker image" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Building Tejas Linux ($BuildProfile edition)..." -ForegroundColor Cyan

# Get current directory (Windows path)
$workspace = (Get-Location).Path

# Ensure output directory exists
$outDir = Join-Path $workspace "iso\out"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# Run the build (only mount iso/out to save the final ISO)
docker run --rm --privileged `
    -v "${outDir}:/workspace/iso/out" `
    -w /workspace `
    tejas-builder `
    sudo PROFILE=$BuildProfile /workspace/iso/build.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host "[DONE] Build complete! Check iso\out\ for the ISO file." -ForegroundColor Green
} else {
    Write-Host "Error: Build failed" -ForegroundColor Red
    exit 1
}

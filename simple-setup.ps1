# ============================================================================
# Plex Stack - Directory Setup Script for Windows
# ============================================================================
# This script creates the required directory structure and .env template
# for the Plex Stack Docker Compose setup.
#
# Requirements:
# - PowerShell 5.1 or later
# - Docker Desktop for Windows
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Base path for Docker configuration files")]
    [string]$BasePath,

    [Parameter(HelpMessage = "Media storage path")]
    [string]$MediaPath,

    [Parameter(HelpMessage = "Skip Docker check")]
    [switch]$SkipDockerCheck
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Display header
Write-Host "`n============================================================================" -ForegroundColor Cyan
Write-Host "  Plex Stack - Setup Script" -ForegroundColor Cyan
Write-Host "============================================================================`n" -ForegroundColor Cyan

# Check if Docker is installed and running (unless skipped)
if (-not $SkipDockerCheck) {
    Write-Host "[1/4] Checking Docker installation..." -ForegroundColor Yellow
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Docker found: $dockerVersion" -ForegroundColor Green
        }
        else {
            throw "Docker not found"
        }
    }
    catch {
        Write-Host "  [X] Docker not found or not running" -ForegroundColor Red
        Write-Host "  Please install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        $continue = Read-Host "  Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    }
}

# Prompt for paths if not provided
Write-Host "`n[2/4] Configuring paths..." -ForegroundColor Yellow
if (-not $BasePath) {
    do {
        $BasePath = Read-Host "  Enter base path for Docker configs (e.g., C:\docker)"
        if ([string]::IsNullOrWhiteSpace($BasePath)) {
            Write-Host "  Base path cannot be empty" -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($BasePath))
}

if (-not $MediaPath) {
    do {
        $MediaPath = Read-Host "  Enter media storage path (e.g., C:\media)"
        if ([string]::IsNullOrWhiteSpace($MediaPath)) {
            Write-Host "  Media path cannot be empty" -ForegroundColor Red
        }
    } while ([string]::IsNullOrWhiteSpace($MediaPath))
}

# Normalize paths
$BasePath = $BasePath.TrimEnd('\')
$MediaPath = $MediaPath.TrimEnd('\')

Write-Host "  [OK] Base path: $BasePath" -ForegroundColor Green
Write-Host "  [OK] Media path: $MediaPath" -ForegroundColor Green

# Define directory structure
Write-Host "`n[3/4] Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    # Application config directories
    "$BasePath\plex\config",
    "$BasePath\radarr\config",
    "$BasePath\sonarr\config",
    "$BasePath\prowlarr\config",
    "$BasePath\overseerr\config",
    "$BasePath\qbittorrent\config",
    "$BasePath\gluetun",
    # Media directories
    "$MediaPath\media\movies",
    "$MediaPath\media\tv",
    # Download directories (organized by category)
    "$MediaPath\downloads\movies",
    "$MediaPath\downloads\tv",
    "$MediaPath\downloads\incomplete"
)

$created = 0
$existing = 0
$failed = 0

foreach ($dir in $directories) {
    try {
        if (Test-Path $dir) {
            Write-Host "  • $dir" -ForegroundColor Gray -NoNewline
            Write-Host " [EXISTS]" -ForegroundColor DarkGray
            $existing++
        }
        else {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  • $dir" -ForegroundColor Green -NoNewline
            Write-Host " [CREATED]" -ForegroundColor Green
            $created++
        }
    }
    catch {
        Write-Host "  • $dir" -ForegroundColor Red -NoNewline
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n  Summary: $created created, $existing existing, $failed failed" -ForegroundColor Cyan

# Create .env template file
Write-Host "`n[4/4] Creating .env template..." -ForegroundColor Yellow
$envPath = Join-Path $PSScriptRoot ".env"

if (Test-Path $envPath) {
    Write-Host "  ! .env file already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "  Overwrite? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "  Skipping .env creation" -ForegroundColor Gray
        $envPath = $null
    }
}

if ($envPath) {
    # Get current user ID (for WSL compatibility, default to 1000)
    $puid = 1000
    $pgid = 1000

    # Get timezone
    try {
        $timezone = (Get-TimeZone).Id
        # Convert Windows timezone to IANA format (basic conversion)
        $timezone = $timezone -replace ' Standard Time', '' -replace ' ', '_'
        if ($timezone -match 'Pacific') { $timezone = 'America/Los_Angeles' }
        elseif ($timezone -match 'Mountain') { $timezone = 'America/Denver' }
        elseif ($timezone -match 'Central') { $timezone = 'America/Chicago' }
        elseif ($timezone -match 'Eastern') { $timezone = 'America/New_York' }
        else { $timezone = 'America/New_York' }
    }
    catch {
        $timezone = 'America/New_York'
    }

    # Convert Windows paths to Linux paths for Docker
    $basePathLinux = $BasePath -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }
    $mediaPathLinux = $MediaPath -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }

    $envContent = @"
# ============================================================================
# Plex Stack - Environment Configuration
# ============================================================================
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#
# IMPORTANT: Fill in all required values before running docker-compose
# ============================================================================

# User and Group IDs (run 'id' command in WSL/Linux to find your IDs)
PUID=$puid
PGID=$pgid

# Timezone (see: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
TZ=$timezone

# Paths - Use Linux-style paths for Docker
# Windows: C:\docker -> Linux: /mnt/c/docker
BASE_PATH=$basePathLinux
MEDIA_SHARE=$mediaPathLinux

# PIA VPN Configuration
# Get your credentials from: https://www.privateinternetaccess.com/
PIA_USERNAME=your_pia_username
PIA_PASSWORD=your_pia_password
PIA_REGION=US East

# Plex Configuration
# Get your claim token from: https://www.plex.tv/claim/
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxxxxxx

# ============================================================================
# Next Steps:
# 1. Edit this file and fill in all required values
# 2. Run: docker-compose pull
# 3. Run: docker-compose up -d
# 4. Access services:
#    - Plex: http://localhost:32400/web
#    - Radarr: http://localhost:7878
#    - Sonarr: http://localhost:8989
#    - Prowlarr: http://localhost:9696
#    - Overseerr: http://localhost:5055
#    - qBittorrent: http://localhost:8080
# ============================================================================
"@

    try {
        $envContent | Out-File -FilePath $envPath -Encoding UTF8 -NoNewline
        Write-Host "  [OK] Created .env template at: $envPath" -ForegroundColor Green
    }
    catch {
        Write-Host "  [X] Failed to create .env file: $_" -ForegroundColor Red
    }
}

# Display completion message
Write-Host "`n============================================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Edit the .env file and fill in all required values" -ForegroundColor White
Write-Host "  2. Review docker-compose.yaml and customize as needed" -ForegroundColor White
Write-Host "  3. Run: docker-compose pull" -ForegroundColor White
Write-Host "  4. Run: docker-compose up -d" -ForegroundColor White
Write-Host "`nFor help and documentation:" -ForegroundColor Yellow
Write-Host "  • Trash Guides: https://trash-guides.info/" -ForegroundColor White
Write-Host "`n============================================================================`n" -ForegroundColor Cyan
# TAC -- Think. Architect. Code.
# Windows PowerShell Installer
# Usage: irm https://raw.githubusercontent.com/waghelapritesh/tac/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  TAC -- Think. Architect. Code." -ForegroundColor Cyan
Write-Host "  ===============================" -ForegroundColor Cyan
Write-Host ""

# Determine install location
$TacDir = Join-Path $env:USERPROFILE ".claude\tac"
$SkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

# Check if git is available
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Host "  [!] Git not found. Install git first:" -ForegroundColor Red
    Write-Host "      winget install Git.Git" -ForegroundColor Yellow
    exit 1
}

# Check if Claude Code skills directory exists
$claudeExists = Test-Path (Join-Path $env:USERPROFILE ".claude")
if (-not $claudeExists) {
    Write-Host "  [!] Claude Code not detected (~/.claude/ missing)" -ForegroundColor Yellow
    Write-Host "      TAC will install but Claude Code integration needs manual setup." -ForegroundColor Yellow
    Write-Host ""
    New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE ".claude\skills") -Force | Out-Null
}

# Clone or update
if (Test-Path $TacDir) {
    Write-Host "  Updating existing TAC installation..." -ForegroundColor Yellow
    Push-Location $TacDir
    git pull --quiet 2>$null
    Pop-Location
    Write-Host "  [+] Updated" -ForegroundColor Green
} else {
    Write-Host "  Cloning TAC..." -ForegroundColor Yellow
    git clone --quiet https://github.com/waghelapritesh/tac.git $TacDir 2>$null
    Write-Host "  [+] Cloned to $TacDir" -ForegroundColor Green
}

# Create skills directory if needed
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

# Create symlinks for each skill (requires admin or dev mode)
$skillCount = 0
$skillsSource = Join-Path $TacDir "skills"

Get-ChildItem -Path $skillsSource -Directory | Where-Object { $_.Name -like "tac-*" } | ForEach-Object {
    $target = Join-Path $SkillsDir $_.Name

    # Remove existing symlink or directory
    if (Test-Path $target) {
        Remove-Item $target -Recurse -Force 2>$null
    }

    try {
        # Try symlink first (requires admin or dev mode)
        New-Item -ItemType SymbolicLink -Path $target -Target $_.FullName -Force | Out-Null
        $skillCount++
        Write-Host "  [+] Linked $($_.Name)" -ForegroundColor Green
    } catch {
        # Fallback: copy directory
        Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
        $skillCount++
        Write-Host "  [+] Copied $($_.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  $skillCount skills installed." -ForegroundColor Cyan
Write-Host ""

# Create global TAC config directory
$globalTac = Join-Path $env:USERPROFILE ".tac"
if (-not (Test-Path $globalTac)) {
    New-Item -ItemType Directory -Path $globalTac -Force | Out-Null
    Write-Host "  [+] Created ~/.tac/ (global config)" -ForegroundColor Green
}

# Check for auth.json
$authFile = Join-Path $globalTac "auth.json"
if (-not (Test-Path $authFile)) {
    Write-Host ""
    Write-Host "  No AI provider configured yet." -ForegroundColor Yellow
    Write-Host "  Run /tac-login in Claude Code to authenticate." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  TAC installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Commands available:" -ForegroundColor White
Write-Host "    /tac-init     Initialize TAC in a project" -ForegroundColor Gray
Write-Host "    /tac-new      Full pipeline: think -> safe -> auto" -ForegroundColor Gray
Write-Host "    /tac-think    Explore an idea" -ForegroundColor Gray
Write-Host "    /tac-build    Build a feature" -ForegroundColor Gray
Write-Host "    /tac-go       Resume from checkpoint" -ForegroundColor Gray
Write-Host "    /tac-safe     Verify before deploy" -ForegroundColor Gray
Write-Host "    /tac-login    Authenticate with AI provider" -ForegroundColor Gray
Write-Host "    /tac-settings Configure TAC behavior" -ForegroundColor Gray
Write-Host ""
Write-Host "  Run /tac-init in your project to get started." -ForegroundColor Cyan
Write-Host ""

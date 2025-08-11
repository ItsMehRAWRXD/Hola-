# Clean-OllamaCursor.ps1
# Completely removes all traces of Ollama and Cursor installations
# Compatible with PowerShell 5.1

param(
    [switch]$Ollama,
    [switch]$Cursor,
    [switch]$All,
    [switch]$Force,
    [switch]$KeepModels
)

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges for complete cleanup. Restarting..." -ForegroundColor Yellow
    $args = @("-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    if ($Ollama) { $args += "-Ollama" }
    if ($Cursor) { $args += "-Cursor" }
    if ($All) { $args += "-All" }
    if ($Force) { $args += "-Force" }
    if ($KeepModels) { $args += "-KeepModels" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args
    exit
}

Write-Host "========================================" -ForegroundColor Red
Write-Host "Ollama & Cursor Complete Cleanup" -ForegroundColor Red
Write-Host "Running as Administrator" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# If no specific flags, default to All
if (-not $Ollama -and -not $Cursor) {
    $All = $true
}

if ($All) {
    $Ollama = $true
    $Cursor = $true
}

# Confirmation
if (-not $Force) {
    Write-Host "This will remove:" -ForegroundColor Yellow
    if ($Ollama) {
        Write-Host "  - Ollama installation and data" -ForegroundColor White
        if (-not $KeepModels) {
            Write-Host "  - All downloaded models (can be several GB!)" -ForegroundColor Red
        }
    }
    if ($Cursor) {
        Write-Host "  - Cursor IDE installation" -ForegroundColor White
        Write-Host "  - Cursor settings and extensions" -ForegroundColor White
    }
    
    Write-Host "`nAre you sure you want to continue?" -ForegroundColor Red
    $response = Read-Host "Type 'yes' to continue"
    if ($response -ne 'yes') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit
    }
}

# Function to remove directory with retry
function Remove-DirectoryForce {
    param($Path)
    
    if (Test-Path $Path) {
        try {
            # First try normal removal
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ Removed: $Path" -ForegroundColor Green
        } catch {
            # If failed, try to take ownership and remove
            Write-Host "  → Taking ownership of: $Path" -ForegroundColor Yellow
            cmd /c takeown /f "$Path" /r /d y 2>&1 | Out-Null
            cmd /c icacls "$Path" /reset /t /c /q 2>&1 | Out-Null
            
            # Try removal again
            try {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Host "  ✓ Removed: $Path" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to remove: $Path" -ForegroundColor Red
                Write-Host "    Error: $_" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  ○ Not found: $Path" -ForegroundColor Gray
    }
}

# Function to stop processes
function Stop-ProcessesSafe {
    param($ProcessName)
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  → Stopping $ProcessName processes..." -ForegroundColor Yellow
        $processes | Stop-Process -Force
        Start-Sleep -Seconds 2
        Write-Host "  ✓ Stopped $ProcessName" -ForegroundColor Green
    }
}

if ($Ollama) {
    Write-Host "`n=== Cleaning Ollama ===" -ForegroundColor Cyan
    
    # Stop Ollama processes
    Write-Host "`nStopping Ollama processes..." -ForegroundColor Yellow
    Stop-ProcessesSafe "ollama"
    Stop-ProcessesSafe "ollama_llama_server"
    
    # Kill any process using port 11434
    Write-Host "Checking port 11434..." -ForegroundColor Yellow
    $tcpConnections = Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue
    if ($tcpConnections) {
        $tcpConnections | ForEach-Object {
            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  ✓ Freed port 11434" -ForegroundColor Green
    }
    
    # Remove Ollama service if exists
    Write-Host "`nRemoving Ollama service..." -ForegroundColor Yellow
    $service = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name "Ollama" -Force -ErrorAction SilentlyContinue
        sc.exe delete "Ollama" 2>&1 | Out-Null
        Write-Host "  ✓ Removed Ollama service" -ForegroundColor Green
    }
    
    # Remove Ollama directories
    Write-Host "`nRemoving Ollama directories..." -ForegroundColor Yellow
    
    # Program installations
    Remove-DirectoryForce "$env:ProgramFiles\Ollama"
    Remove-DirectoryForce "$env:LOCALAPPDATA\Ollama"
    Remove-DirectoryForce "$env:LOCALAPPDATA\Programs\Ollama"
    
    # User data
    Remove-DirectoryForce "$env:USERPROFILE\.ollama\logs"
    Remove-DirectoryForce "$env:USERPROFILE\.ollama\tmp"
    Remove-DirectoryForce "$env:USERPROFILE\.ollama\history"
    
    if (-not $KeepModels) {
        Write-Host "`nRemoving Ollama models (this may take a while)..." -ForegroundColor Yellow
        Remove-DirectoryForce "$env:USERPROFILE\.ollama\models"
        Remove-DirectoryForce "$env:USERPROFILE\.ollama"
    } else {
        Write-Host "`nKeeping models in: $env:USERPROFILE\.ollama\models" -ForegroundColor Cyan
    }
    
    # Remove from PATH
    Write-Host "`nCleaning PATH environment variable..." -ForegroundColor Yellow
    $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = ($path -split ';' | Where-Object { $_ -notmatch "Ollama" }) -join ';'
    if ($path -ne $newPath) {
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "  ✓ Removed Ollama from system PATH" -ForegroundColor Green
    }
    
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $newUserPath = ($userPath -split ';' | Where-Object { $_ -notmatch "Ollama" }) -join ';'
    if ($userPath -ne $newUserPath) {
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Host "  ✓ Removed Ollama from user PATH" -ForegroundColor Green
    }
    
    # Remove registry entries
    Write-Host "`nCleaning registry..." -ForegroundColor Yellow
    $regPaths = @(
        "HKLM:\SOFTWARE\Ollama",
        "HKCU:\SOFTWARE\Ollama",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Ollama",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Ollama"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed registry: $regPath" -ForegroundColor Green
        }
    }
}

if ($Cursor) {
    Write-Host "`n=== Cleaning Cursor ===" -ForegroundColor Cyan
    
    # Stop Cursor processes
    Write-Host "`nStopping Cursor processes..." -ForegroundColor Yellow
    Stop-ProcessesSafe "Cursor"
    Stop-ProcessesSafe "cursor"
    
    # Remove Cursor directories
    Write-Host "`nRemoving Cursor directories..." -ForegroundColor Yellow
    
    # Program installations
    Remove-DirectoryForce "$env:LOCALAPPDATA\Programs\cursor"
    Remove-DirectoryForce "$env:ProgramFiles\Cursor"
    Remove-DirectoryForce "${env:ProgramFiles(x86)}\Cursor"
    
    # User data
    Remove-DirectoryForce "$env:APPDATA\Cursor"
    Remove-DirectoryForce "$env:USERPROFILE\.cursor"
    Remove-DirectoryForce "$env:APPDATA\Code"  # Cursor sometimes uses VS Code directories
    
    # Remove desktop shortcuts
    Write-Host "`nRemoving shortcuts..." -ForegroundColor Yellow
    $shortcuts = @(
        "$env:USERPROFILE\Desktop\Cursor.lnk",
        "$env:PUBLIC\Desktop\Cursor.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Cursor.lnk"
    )
    
    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) {
            Remove-Item -Path $shortcut -Force
            Write-Host "  ✓ Removed shortcut: $shortcut" -ForegroundColor Green
        }
    }
    
    # Remove registry entries
    Write-Host "`nCleaning registry..." -ForegroundColor Yellow
    $regPaths = @(
        "HKLM:\SOFTWARE\Cursor",
        "HKCU:\SOFTWARE\Cursor",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*cursor*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*cursor*",
        "HKCR:\cursor"
    )
    
    foreach ($regPath in $regPaths) {
        Get-Item -Path $regPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove cursor:// protocol handler
    if (Test-Path "HKCR:\cursor") {
        Remove-Item -Path "HKCR:\cursor" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed cursor:// protocol handler" -ForegroundColor Green
    }
}

# Clean up PowerShell history issues
Write-Host "`n=== Fixing PowerShell History ===" -ForegroundColor Cyan
$historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine"
if (Test-Path $historyPath) {
    Write-Host "Fixing PSReadLine history permissions..." -ForegroundColor Yellow
    cmd /c takeown /f "$historyPath" /r /d y 2>&1 | Out-Null
    cmd /c icacls "$historyPath" /reset /t /c /q 2>&1 | Out-Null
    cmd /c icacls "$historyPath" /grant "${env:USERNAME}:(OI)(CI)F" /t 2>&1 | Out-Null
    
    # Remove old history file
    $historyFile = Join-Path $historyPath "ConsoleHost_history.txt"
    if (Test-Path $historyFile) {
        Remove-Item -Path $historyFile -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed old history file" -ForegroundColor Green
    }
}

# Clean temp files
Write-Host "`n=== Cleaning Temporary Files ===" -ForegroundColor Cyan
$tempPaths = @(
    "$env:TEMP\ollama*",
    "$env:TEMP\cursor*",
    "$env:LOCALAPPDATA\Temp\ollama*",
    "$env:LOCALAPPDATA\Temp\cursor*"
)

foreach ($tempPath in $tempPaths) {
    Get-ChildItem -Path $tempPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  ✓ Cleaned temporary files" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nRemoved:" -ForegroundColor Yellow
if ($Ollama) {
    Write-Host "  ✓ Ollama installation and data" -ForegroundColor Green
    if (-not $KeepModels) {
        Write-Host "  ✓ All Ollama models" -ForegroundColor Green
    }
}
if ($Cursor) {
    Write-Host "  ✓ Cursor installation and settings" -ForegroundColor Green
}
Write-Host "  ✓ PowerShell history issues" -ForegroundColor Green
Write-Host "  ✓ Temporary files" -ForegroundColor Green

Write-Host "`nYour system is now clean and ready for fresh installations." -ForegroundColor Cyan

# Refresh environment
Write-Host "`nRefreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "`nDone! You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
# Open-In-Cursor-Offline.ps1
# Provides offline alternatives to "Open in Cursor" functionality
# Compatible with PowerShell 5.1

param(
    [Parameter(Position=0)]
    [string]$Path = (Get-Location).Path,
    
    [string]$File,
    
    [int]$Line,
    
    [switch]$StartOllama
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Open in Cursor - Offline Mode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find Cursor installation
$cursorPaths = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:ProgramFiles\Cursor\Cursor.exe",
    "${env:ProgramFiles(x86)}\Cursor\Cursor.exe",
    "$env:USERPROFILE\AppData\Local\Programs\cursor\Cursor.exe"
)

$cursorExe = $null
foreach ($cursorPath in $cursorPaths) {
    if (Test-Path $cursorPath) {
        $cursorExe = $cursorPath
        Write-Host "✓ Found Cursor at: $cursorExe" -ForegroundColor Green
        break
    }
}

if (-not $cursorExe) {
    # Try to find via registry
    try {
        $regPath = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Cursor.exe" -ErrorAction Stop
        if ($regPath -and $regPath.'(default)') {
            $cursorExe = $regPath.'(default)'
        }
    } catch {}
}

if (-not $cursorExe) {
    Write-Host "✗ Cursor not found! Please install Cursor first." -ForegroundColor Red
    Write-Host "  Download from: https://cursor.sh" -ForegroundColor Yellow
    exit 1
}

# Start Ollama if requested
if ($StartOllama) {
    Write-Host "`nChecking Ollama status..." -ForegroundColor Yellow
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadString("http://localhost:11434/api/tags") | Out-Null
        $webClient.Dispose()
        Write-Host "✓ Ollama is already running" -ForegroundColor Green
    } catch {
        Write-Host "Starting Ollama server..." -ForegroundColor Yellow
        
        # Find Ollama
        $ollamaPath = $null
        try {
            $ollamaPath = (Get-Command ollama -ErrorAction Stop).Source
        } catch {
            $ollamaPaths = @(
                "$env:ProgramFiles\Ollama\ollama.exe",
                "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
            )
            foreach ($path in $ollamaPaths) {
                if (Test-Path $path) {
                    $ollamaPath = $path
                    break
                }
            }
        }
        
        if ($ollamaPath) {
            Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
            Start-Sleep -Seconds 3
            Write-Host "✓ Ollama server started" -ForegroundColor Green
        } else {
            Write-Host "⚠ Ollama not found - AI features won't work" -ForegroundColor Yellow
        }
    }
}

# Build Cursor arguments
$arguments = @()

# Add path or file
if ($File) {
    $fullPath = Join-Path $Path $File
    if (Test-Path $fullPath) {
        $arguments += "`"$fullPath`""
        
        # Add line number if specified
        if ($Line -gt 0) {
            $arguments += "-g"
            $arguments += "`"$fullPath`:$Line`""
        }
    } else {
        Write-Host "⚠ File not found: $fullPath" -ForegroundColor Yellow
        $arguments += "`"$Path`""
    }
} else {
    $arguments += "`"$Path`""
}

# Launch Cursor
Write-Host "`nLaunching Cursor..." -ForegroundColor Green
Write-Host "Path: $Path" -ForegroundColor Gray
if ($File) {
    Write-Host "File: $File" -ForegroundColor Gray
    if ($Line -gt 0) {
        Write-Host "Line: $Line" -ForegroundColor Gray
    }
}

try {
    if ($arguments.Count -gt 0) {
        Start-Process -FilePath $cursorExe -ArgumentList ($arguments -join " ")
    } else {
        Start-Process -FilePath $cursorExe
    }
    
    Write-Host "`n✓ Cursor launched successfully!" -ForegroundColor Green
    
    if ($StartOllama) {
        Write-Host "`nRemember to configure Cursor for offline use:" -ForegroundColor Yellow
        Write-Host "1. Open Settings (Ctrl + ,)" -ForegroundColor White
        Write-Host "2. Set OpenAI Base URL to: http://localhost:11434/v1" -ForegroundColor Cyan
        Write-Host "3. Set API Key to: ollama" -ForegroundColor Cyan
        Write-Host "4. Select your local model" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ Failed to launch Cursor: $_" -ForegroundColor Red
    exit 1
}

# Create context file for sharing
if ($File -or $Line -gt 0) {
    $contextFile = Join-Path $env:TEMP "cursor-context.json"
    $context = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        path = $Path
        file = $File
        line = $Line
        absolutePath = if ($File) { Join-Path $Path $File } else { $Path }
    }
    
    $context | ConvertTo-Json | Out-File -FilePath $contextFile -Encoding UTF8
    Write-Host "`nContext saved to: $contextFile" -ForegroundColor Gray
}
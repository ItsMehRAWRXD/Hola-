# Register-CursorProtocol.ps1
# Registers a custom protocol handler for cursor:// URLs to work offline
# Requires Administrator privileges

param(
    [switch]$Unregister
)

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", $(if($Unregister){"-Unregister"})
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cursor Protocol Handler Registration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$protocolName = "cursor"
$protocolDescription = "Cursor IDE Protocol (Offline)"

if ($Unregister) {
    Write-Host "`nUnregistering cursor:// protocol handler..." -ForegroundColor Yellow
    
    try {
        Remove-Item -Path "HKCR:\$protocolName" -Recurse -Force -ErrorAction Stop
        Write-Host "✓ Successfully unregistered cursor:// protocol" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to unregister: $_" -ForegroundColor Red
    }
    
    exit
}

# Create handler script
$handlerScript = @'
param($url)

# Parse cursor:// URL
# Format: cursor://open?path=C:\project&file=main.py&line=42

function Parse-CursorUrl {
    param($Url)
    
    $result = @{
        path = ""
        file = ""
        line = 0
    }
    
    if ($Url -match "cursor://open\?(.+)") {
        $params = $matches[1]
        
        foreach ($param in ($params -split "&")) {
            if ($param -match "([^=]+)=(.+)") {
                $key = $matches[1]
                $value = [System.Web.HttpUtility]::UrlDecode($matches[2])
                
                switch ($key) {
                    "path" { $result.path = $value }
                    "file" { $result.file = $value }
                    "line" { $result.line = [int]$value }
                }
            }
        }
    }
    
    return $result
}

# Load .NET assembly for URL decoding
Add-Type -AssemblyName System.Web

$parsed = Parse-CursorUrl -Url $url

# Find Open-In-Cursor-Offline.ps1
$scriptPaths = @(
    "$PSScriptRoot\Open-In-Cursor-Offline.ps1",
    "$env:USERPROFILE\Documents\windows-scripts\Open-In-Cursor-Offline.ps1",
    "C:\Scripts\Open-In-Cursor-Offline.ps1"
)

$openScript = $null
foreach ($path in $scriptPaths) {
    if (Test-Path $path) {
        $openScript = $path
        break
    }
}

if ($openScript) {
    $args = @("-ExecutionPolicy", "Bypass", "-File", "`"$openScript`"")
    
    if ($parsed.path) { $args += "-Path"; $args += "`"$($parsed.path)`"" }
    if ($parsed.file) { $args += "-File"; $args += "`"$($parsed.file)`"" }
    if ($parsed.line -gt 0) { $args += "-Line"; $args += $parsed.line }
    $args += "-StartOllama"
    
    Start-Process powershell.exe -ArgumentList $args
} else {
    # Fallback: try to open Cursor directly
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:ProgramFiles\Cursor\Cursor.exe"
    )
    
    foreach ($cursorPath in $cursorPaths) {
        if (Test-Path $cursorPath) {
            if ($parsed.path) {
                Start-Process -FilePath $cursorPath -ArgumentList "`"$($parsed.path)`""
            } else {
                Start-Process -FilePath $cursorPath
            }
            break
        }
    }
}
'@

# Save handler script
$handlerPath = "$env:ProgramData\CursorProtocol"
New-Item -ItemType Directory -Force -Path $handlerPath | Out-Null

$handlerScriptPath = Join-Path $handlerPath "cursor-handler.ps1"
$handlerScript | Out-File -FilePath $handlerScriptPath -Force -Encoding UTF8

Write-Host "✓ Created handler script at: $handlerScriptPath" -ForegroundColor Green

# Create registry entries
Write-Host "`nRegistering cursor:// protocol..." -ForegroundColor Yellow

try {
    # Create main protocol key
    New-Item -Path "HKCR:\$protocolName" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\$protocolName" -Name "(Default)" -Value $protocolDescription
    Set-ItemProperty -Path "HKCR:\$protocolName" -Name "URL Protocol" -Value ""
    
    # Create shell command
    New-Item -Path "HKCR:\$protocolName\shell" -Force | Out-Null
    New-Item -Path "HKCR:\$protocolName\shell\open" -Force | Out-Null
    New-Item -Path "HKCR:\$protocolName\shell\open\command" -Force | Out-Null
    
    # Set command to run PowerShell with our handler
    $command = "`"$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe`" -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$handlerScriptPath`" `"%1`""
    Set-ItemProperty -Path "HKCR:\$protocolName\shell\open\command" -Name "(Default)" -Value $command
    
    Write-Host "✓ Successfully registered cursor:// protocol" -ForegroundColor Green
    
    # Also update the script location in handler
    $updatedHandler = $handlerScript -replace '\$PSScriptRoot\\Open-In-Cursor-Offline\.ps1', "$((Get-Location).Path)\Open-In-Cursor-Offline.ps1"
    $updatedHandler | Out-File -FilePath $handlerScriptPath -Force -Encoding UTF8
    
} catch {
    Write-Host "✗ Failed to register protocol: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Registration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nThe cursor:// protocol is now registered for offline use." -ForegroundColor Yellow
Write-Host "Example URLs that will now work offline:" -ForegroundColor Yellow
Write-Host "  cursor://open?path=C:\MyProject" -ForegroundColor Gray
Write-Host "  cursor://open?path=C:\MyProject&file=main.py" -ForegroundColor Gray
Write-Host "  cursor://open?path=C:\MyProject&file=main.py&line=42" -ForegroundColor Gray

Write-Host "`nTo unregister, run:" -ForegroundColor Yellow
Write-Host "  .\Register-CursorProtocol.ps1 -Unregister" -ForegroundColor Cyan

Write-Host "`nNote: This enables cursor:// URLs to work offline by opening" -ForegroundColor Cyan
Write-Host "Cursor directly without requiring internet connectivity." -ForegroundColor Cyan
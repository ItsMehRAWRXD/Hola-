# Stop-OllamaProcess.ps1
# Finds and stops processes using port 11434 (Ollama's default port)
# Compatible with PowerShell 5.1

param(
    [switch]$Force,
    [switch]$ListOnly
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ollama Process Manager" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find processes using port 11434
Write-Host "`nSearching for processes using port 11434..." -ForegroundColor Yellow

$netstatOutput = netstat -ano | Select-String ":11434"

if (-not $netstatOutput) {
    Write-Host "✓ No processes found using port 11434" -ForegroundColor Green
    exit 0
}

# Parse PIDs from netstat output
$pids = @()
foreach ($line in $netstatOutput) {
    # Extract PID from the last column
    if ($line -match '\s+(\d+)\s*$') {
        $pid = [int]$matches[1]
        if ($pid -gt 0 -and $pids -notcontains $pid) {
            $pids += $pid
        }
    }
}

if ($pids.Count -eq 0) {
    Write-Host "✓ No valid PIDs found" -ForegroundColor Green
    exit 0
}

# Display found processes
Write-Host "`nFound processes using port 11434:" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Gray

foreach ($pid in $pids) {
    try {
        $process = Get-Process -Id $pid -ErrorAction Stop
        Write-Host "PID: $pid | Name: $($process.ProcessName) | Path: $($process.Path)" -ForegroundColor White
    } catch {
        Write-Host "PID: $pid | (Unable to get process details)" -ForegroundColor Gray
    }
}

if ($ListOnly) {
    Write-Host "`nUse -Force parameter to stop these processes" -ForegroundColor Cyan
    exit 0
}

# Ask for confirmation if not forced
if (-not $Force) {
    Write-Host "`nDo you want to stop these processes?" -ForegroundColor Yellow
    $response = Read-Host "Type 'yes' to continue or press Enter to cancel"
    
    if ($response -ne 'yes') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Stop processes
Write-Host "`nStopping processes..." -ForegroundColor Yellow
$stopped = 0
$failed = 0

foreach ($pid in $pids) {
    try {
        $process = Get-Process -Id $pid -ErrorAction Stop
        $processName = $process.ProcessName
        
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "✓ Stopped process $processName (PID: $pid)" -ForegroundColor Green
        $stopped++
    } catch {
        if ($_.Exception.Message -match "Cannot find a process") {
            Write-Host "○ Process with PID $pid already stopped" -ForegroundColor Gray
        } else {
            Write-Host "✗ Failed to stop PID $pid`: $_" -ForegroundColor Red
            $failed++
        }
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "Stopped: $stopped processes" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed: $failed processes" -ForegroundColor Red
}

# Check if port is now free
Start-Sleep -Seconds 1
$stillInUse = netstat -ano | Select-String ":11434"

if (-not $stillInUse) {
    Write-Host "`n✓ Port 11434 is now free!" -ForegroundColor Green
} else {
    Write-Host "`n⚠ Port 11434 may still be in use" -ForegroundColor Yellow
    Write-Host "  Try running this script as Administrator" -ForegroundColor Yellow
}
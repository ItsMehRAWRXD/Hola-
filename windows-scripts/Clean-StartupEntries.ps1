# Clean-StartupEntries.ps1
# Removes all startup entries for Ollama and Cursor
# Compatible with PowerShell 5.1

param(
    [switch]$Force
)

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", $(if($Force){"-Force"})
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleaning Startup Entries" -ForegroundColor Cyan
Write-Host "Running as Administrator" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$removedCount = 0

# 1. Registry Run Keys (Current User)
Write-Host "Checking Current User Registry Run Keys..." -ForegroundColor Yellow
$cuRunPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$cuRunOnce = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

foreach ($path in @($cuRunPath, $cuRunOnce)) {
    if (Test-Path $path) {
        $keys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $keys.PSObject.Properties | Where-Object {
            $_.Name -notmatch "^PS" -and 
            ($_.Value -match "ollama|cursor")
        } | ForEach-Object {
            Write-Host "  Found: $($_.Name) = $($_.Value)" -ForegroundColor Gray
            Remove-ItemProperty -Path $path -Name $_.Name -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed: $($_.Name)" -ForegroundColor Green
            $removedCount++
        }
    }
}

# 2. Registry Run Keys (Local Machine)
Write-Host "`nChecking Local Machine Registry Run Keys..." -ForegroundColor Yellow
$lmRunPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$lmRunOnce = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$lmRun64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"

foreach ($path in @($lmRunPath, $lmRunOnce, $lmRun64)) {
    if (Test-Path $path) {
        $keys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $keys.PSObject.Properties | Where-Object {
            $_.Name -notmatch "^PS" -and 
            ($_.Value -match "ollama|cursor")
        } | ForEach-Object {
            Write-Host "  Found: $($_.Name) = $($_.Value)" -ForegroundColor Gray
            Remove-ItemProperty -Path $path -Name $_.Name -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed: $($_.Name)" -ForegroundColor Green
            $removedCount++
        }
    }
}

# 3. Startup Folders
Write-Host "`nChecking Startup Folders..." -ForegroundColor Yellow
$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:USERPROFILE\Start Menu\Programs\Startup"
)

foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Filter "*.lnk" -ErrorAction SilentlyContinue | ForEach-Object {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($_.FullName)
            if ($shortcut.TargetPath -match "ollama|cursor") {
                Write-Host "  Found shortcut: $($_.Name)" -ForegroundColor Gray
                Write-Host "  Target: $($shortcut.TargetPath)" -ForegroundColor Gray
                Remove-Item $_.FullName -Force
                Write-Host "  ✓ Removed: $($_.Name)" -ForegroundColor Green
                $removedCount++
            }
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
    }
}

# 4. Task Scheduler
Write-Host "`nChecking Task Scheduler..." -ForegroundColor Yellow
try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskName -match "ollama|cursor" -or
        $_.Actions.Execute -match "ollama|cursor"
    }
    
    foreach ($task in $tasks) {
        Write-Host "  Found task: $($task.TaskName)" -ForegroundColor Gray
        Write-Host "  Path: $($task.TaskPath)" -ForegroundColor Gray
        
        if (-not $Force) {
            $response = Read-Host "  Remove this task? (y/n)"
            if ($response -ne 'y') {
                continue
            }
        }
        
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed task: $($task.TaskName)" -ForegroundColor Green
        $removedCount++
    }
} catch {
    Write-Host "  Could not check Task Scheduler (may require different permissions)" -ForegroundColor Gray
}

# 5. Services set to Automatic
Write-Host "`nChecking Services..." -ForegroundColor Yellow
$services = Get-Service | Where-Object {
    ($_.Name -match "ollama|cursor") -and 
    ($_.StartType -eq 'Automatic')
}

foreach ($service in $services) {
    Write-Host "  Found service: $($service.Name) (StartType: $($service.StartType))" -ForegroundColor Gray
    
    try {
        # Stop the service
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $service.Name -Force -ErrorAction Stop
            Write-Host "  ✓ Stopped service: $($service.Name)" -ForegroundColor Green
        }
        
        # Set to Manual or Disabled
        Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
        Write-Host "  ✓ Disabled service: $($service.Name)" -ForegroundColor Green
        
        # Try to remove the service
        sc.exe delete $service.Name 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Removed service: $($service.Name)" -ForegroundColor Green
        }
        
        $removedCount++
    } catch {
        Write-Host "  ⚠ Could not modify service: $($service.Name)" -ForegroundColor Yellow
    }
}

# 6. Registry Startup Approved
Write-Host "`nChecking Startup Approved Registry..." -ForegroundColor Yellow
$approvedPaths = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
)

foreach ($path in $approvedPaths) {
    if (Test-Path $path) {
        Get-Item -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
            $_.Property | Where-Object { $_ -match "ollama|cursor" } | ForEach-Object {
                Write-Host "  Found approved startup: $_" -ForegroundColor Gray
                Remove-ItemProperty -Path $path -Name $_ -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ Removed: $_" -ForegroundColor Green
                $removedCount++
            }
        }
    }
}

# 7. Shell Extensions and Context Menu Handlers
Write-Host "`nChecking Shell Extensions..." -ForegroundColor Yellow
$shellPaths = @(
    "HKCR:\Directory\Background\shell",
    "HKCR:\Directory\shell",
    "HKCR:\*\shell",
    "HKLM:\SOFTWARE\Classes\Directory\Background\shell",
    "HKLM:\SOFTWARE\Classes\Directory\shell",
    "HKLM:\SOFTWARE\Classes\*\shell"
)

foreach ($path in $shellPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "cursor|ollama"
        } | ForEach-Object {
            Write-Host "  Found shell extension: $($_.Name)" -ForegroundColor Gray
            Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed: $($_.Name)" -ForegroundColor Green
            $removedCount++
        }
    }
}

# 8. Check for AutoStart entries in registry
Write-Host "`nChecking AutoStart Registry Entries..." -ForegroundColor Yellow
$autoStartPaths = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
)

# Check for modified startup paths
foreach ($path in $autoStartPaths) {
    if (Test-Path $path) {
        $startup = Get-ItemProperty -Path $path -Name "Startup" -ErrorAction SilentlyContinue
        if ($startup.Startup -match "ollama|cursor") {
            Write-Host "  Found modified startup path: $($startup.Startup)" -ForegroundColor Yellow
            Write-Host "  ⚠ Manual intervention may be required" -ForegroundColor Yellow
        }
    }
}

# 9. Windows Defender Exclusions (that might auto-start)
Write-Host "`nChecking Windows Defender Exclusions..." -ForegroundColor Yellow
try {
    $exclusions = Get-MpPreference -ErrorAction SilentlyContinue
    
    # Check process exclusions
    if ($exclusions.ExclusionProcess) {
        $exclusions.ExclusionProcess | Where-Object { $_ -match "ollama|cursor" } | ForEach-Object {
            Write-Host "  Found process exclusion: $_" -ForegroundColor Gray
            Remove-MpPreference -ExclusionProcess $_ -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed exclusion: $_" -ForegroundColor Green
            $removedCount++
        }
    }
    
    # Check path exclusions
    if ($exclusions.ExclusionPath) {
        $exclusions.ExclusionPath | Where-Object { $_ -match "ollama|cursor" } | ForEach-Object {
            Write-Host "  Found path exclusion: $_" -ForegroundColor Gray
            Remove-MpPreference -ExclusionPath $_ -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed exclusion: $_" -ForegroundColor Green
            $removedCount++
        }
    }
} catch {
    Write-Host "  Could not check Windows Defender settings" -ForegroundColor Gray
}

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Startup Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if ($removedCount -eq 0) {
    Write-Host "`nNo startup entries found for Ollama or Cursor." -ForegroundColor Cyan
} else {
    Write-Host "`nRemoved $removedCount startup entries." -ForegroundColor Yellow
}

Write-Host "`nRecommended: Restart your computer to ensure all changes take effect." -ForegroundColor Cyan

# Additional manual checks
Write-Host "`nManual checks you can perform:" -ForegroundColor Yellow
Write-Host "1. Check Event Viewer > Windows Logs > System for startup errors" -ForegroundColor Gray
Write-Host "2. Run 'msconfig' and check the Startup tab" -ForegroundColor Gray
Write-Host "3. Check 'Task Manager > Startup' tab" -ForegroundColor Gray
Write-Host "4. Run 'autoruns' from Sysinternals for comprehensive view" -ForegroundColor Gray
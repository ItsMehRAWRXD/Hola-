# Start-CursorOffline.ps1
# Main startup script for Cursor + Ollama offline environment on Windows
# Compatible with PowerShell 5.1

param(
    [switch]$Uncensored,
    [switch]$Secure,
    [string]$Model = "llama3:8b"
)

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "This script requires PowerShell 5.1 or higher" -ForegroundColor Red
    Write-Host "Your version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($Secure -and -not $isAdmin) {
    Write-Host "Secure mode requires Administrator privileges. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Secure", $(if($Uncensored){"-Uncensored"})
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cursor + Ollama Offline Environment" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set environment variables
$env:OLLAMA_HOST = "127.0.0.1:11434"
$env:OLLAMA_ORIGINS = "*"
$env:OLLAMA_NOTELEMETRY = "1"
$env:OLLAMA_OFFLINE = "1"

if ($Uncensored) {
    Write-Host "Mode: UNCENSORED" -ForegroundColor Yellow
    $Model = "wizard-uncensored:13b"
}

if ($Secure) {
    Write-Host "Mode: SECURE (Network Disabled)" -ForegroundColor Red
    $env:OLLAMA_ORIGINS = "http://localhost:*"
    
    # Disable network adapters
    Write-Host "`nDisabling network adapters..." -ForegroundColor Yellow
    try {
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        foreach ($adapter in $adapters) {
            Write-Host "  Disabling: $($adapter.Name)" -ForegroundColor Gray
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "✓ Network disabled for security" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to disable network adapters: $_" -ForegroundColor Red
    }
}

# Check if Ollama is installed
$ollamaPath = $null
try {
    $ollamaPath = (Get-Command ollama -ErrorAction Stop).Source
    Write-Host "✓ Ollama found at: $ollamaPath" -ForegroundColor Green
} catch {
    # Check common installation paths
    $commonPaths = @(
        "$env:ProgramFiles\Ollama\ollama.exe",
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "$env:USERPROFILE\AppData\Local\Programs\Ollama\ollama.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $ollamaPath = $path
            Write-Host "✓ Ollama found at: $ollamaPath" -ForegroundColor Green
            break
        }
    }
    
    if (-not $ollamaPath) {
        Write-Host "✗ Ollama not found! Please install Ollama first." -ForegroundColor Red
        Write-Host "  Download from: https://ollama.com/download/windows" -ForegroundColor Yellow
        exit 1
    }
}

# Kill existing Ollama processes
$existingOllama = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($existingOllama) {
    Write-Host "`nStopping existing Ollama processes..." -ForegroundColor Yellow
    $existingOllama | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# Start Ollama server
Write-Host "`nStarting Ollama server..." -ForegroundColor Green
if ($ollamaPath -match "\.exe$") {
    $ollamaProcess = Start-Process -FilePath $ollamaPath -ArgumentList "serve" -PassThru -WindowStyle Hidden
} else {
    $ollamaProcess = Start-Process ollama -ArgumentList "serve" -PassThru -WindowStyle Hidden
}

# Wait for Ollama to start
$attempts = 0
$maxAttempts = 30
Write-Host "Waiting for Ollama to start" -NoNewline
while ($attempts -lt $maxAttempts) {
    try {
        $webClient = New-Object System.Net.WebClient
        $response = $webClient.DownloadString("http://localhost:11434/api/tags")
        $webClient.Dispose()
        Write-Host ""
        Write-Host "✓ Ollama server is running!" -ForegroundColor Green
        break
    } catch {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        $attempts++
    }
}

if ($attempts -eq $maxAttempts) {
    Write-Host ""
    Write-Host "✗ Failed to start Ollama server" -ForegroundColor Red
    exit 1
}

# List available models
Write-Host "`nAvailable models:" -ForegroundColor Yellow
try {
    if ($ollamaPath) {
        $models = & $ollamaPath list 2>$null | Out-String
    } else {
        $models = ollama list 2>$null | Out-String
    }
    Write-Host $models -ForegroundColor Gray
    
    if ($Uncensored) {
        Write-Host "Uncensored models:" -ForegroundColor Yellow
        $uncensoredModels = $models -split "`n" | Where-Object { $_ -match "uncensored|wizard|dolphin|nous|mytho" }
        if ($uncensoredModels) {
            foreach ($model in $uncensoredModels) {
                if ($model.Trim()) {
                    Write-Host "  $model" -ForegroundColor Magenta
                }
            }
        } else {
            Write-Host "  No uncensored models found. Run Setup-UncensoredModels.ps1 first." -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Could not list models: $_" -ForegroundColor Red
}

# Create and start local proxy
Write-Host "`nCreating local proxy..." -ForegroundColor Green

# Create proxy script compatible with PowerShell 5.1
$proxyScript = @'
# Ollama Local Proxy for PowerShell 5.1
$host.UI.RawUI.WindowTitle = "Ollama Local Proxy"

Write-Host "Starting Ollama Local Proxy..." -ForegroundColor Green
Write-Host "Proxy: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Target: http://localhost:11434" -ForegroundColor Cyan

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")

try {
    $listener.Start()
    Write-Host "`nProxy is running. Press Ctrl+C to stop." -ForegroundColor Green
    
    while ($listener.IsListening) {
        try {
            # Get incoming request
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Build target URL
            $targetUrl = "http://localhost:11434" + $request.Url.PathAndQuery
            
            Write-Host "Forwarding: $($request.HttpMethod) $($request.Url.PathAndQuery)" -ForegroundColor Gray
            
            # Create web request
            $webRequest = [System.Net.WebRequest]::Create($targetUrl)
            $webRequest.Method = $request.HttpMethod
            $webRequest.ContentType = $request.ContentType
            
            # Copy headers
            foreach ($header in $request.Headers.AllKeys) {
                if ($header -notin @("Host", "Content-Length", "Content-Type", "Connection")) {
                    try {
                        $webRequest.Headers.Add($header, $request.Headers[$header])
                    } catch {}
                }
            }
            
            # Copy request body if present
            if ($request.HttpMethod -in @("POST", "PUT", "PATCH")) {
                $requestBody = New-Object System.IO.StreamReader($request.InputStream)
                $bodyContent = $requestBody.ReadToEnd()
                $requestBody.Close()
                
                if ($bodyContent) {
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($bodyContent)
                    $webRequest.ContentLength = $bytes.Length
                    $requestStream = $webRequest.GetRequestStream()
                    $requestStream.Write($bytes, 0, $bytes.Length)
                    $requestStream.Close()
                }
            }
            
            # Get response from Ollama
            try {
                $webResponse = $webRequest.GetResponse()
                $responseStream = $webResponse.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($responseStream)
                $responseContent = $reader.ReadToEnd()
                $reader.Close()
                $webResponse.Close()
                
                # Send response back
                $response.StatusCode = [int]$webResponse.StatusCode
                $response.ContentType = $webResponse.ContentType
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseContent)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            } catch [System.Net.WebException] {
                $errorResponse = $_.Exception.Response
                if ($errorResponse) {
                    $response.StatusCode = [int]$errorResponse.StatusCode
                } else {
                    $response.StatusCode = 500
                }
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            $response.Close()
        } catch {
            Write-Host "Request error: $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Failed to start proxy: $_" -ForegroundColor Red
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}
'@

# Save proxy script
$proxyScriptPath = Join-Path $env:TEMP "ollama-proxy.ps1"
$proxyScript | Out-File -FilePath $proxyScriptPath -Force -Encoding UTF8

# Start proxy in new window
$proxyProcess = Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$proxyScriptPath`"" -PassThru

Start-Sleep -Seconds 3

# Test proxy
try {
    $webClient = New-Object System.Net.WebClient
    $testResponse = $webClient.DownloadString("http://localhost:8080/api/tags")
    $webClient.Dispose()
    Write-Host "✓ Proxy is working!" -ForegroundColor Green
} catch {
    Write-Host "⚠ Proxy may not be working correctly" -ForegroundColor Yellow
}

# Display configuration
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nCursor Configuration:" -ForegroundColor Yellow
Write-Host "1. Open Cursor Settings (Ctrl + ,)" -ForegroundColor White
Write-Host "2. Search for 'OpenAI Base URL'" -ForegroundColor White
Write-Host "3. Set Base URL to: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:8080/v1" -ForegroundColor Cyan
Write-Host "4. Set API Key to: " -NoNewline -ForegroundColor White
Write-Host "ollama" -ForegroundColor Cyan
Write-Host "5. Add custom model: " -NoNewline -ForegroundColor White
Write-Host $Model -ForegroundColor Cyan
Write-Host "6. Disable all cloud models" -ForegroundColor White

Write-Host "`nServices Running:" -ForegroundColor Yellow
Write-Host "  - Ollama Server (PID: $($ollamaProcess.Id))" -ForegroundColor Gray
Write-Host "  - Local Proxy (PID: $($proxyProcess.Id))" -ForegroundColor Gray

if ($Secure) {
    Write-Host "`nSecurity Status:" -ForegroundColor Red
    Write-Host "  ✓ Network adapters disabled" -ForegroundColor Green
    Write-Host "  ✓ Ollama restricted to localhost" -ForegroundColor Green
    Write-Host "  ✓ Telemetry disabled" -ForegroundColor Green
}

Write-Host "`nPress Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host "Or close this window to stop everything" -ForegroundColor Gray

# Register cleanup
$cleanupScript = {
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    
    # Stop processes
    $ollamaProc = Get-Variable -Name ollamaProcess -ValueOnly -ErrorAction SilentlyContinue
    $proxyProc = Get-Variable -Name proxyProcess -ValueOnly -ErrorAction SilentlyContinue
    
    if ($ollamaProc) {
        Stop-Process -Id $ollamaProc.Id -Force -ErrorAction SilentlyContinue
    }
    if ($proxyProc) {
        Stop-Process -Id $proxyProc.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Re-enable network if in secure mode
    if (Get-Variable -Name Secure -ValueOnly -ErrorAction SilentlyContinue) {
        Write-Host "Re-enabling network adapters..." -ForegroundColor Yellow
        Get-NetAdapter | Enable-NetAdapter -ErrorAction SilentlyContinue
        Write-Host "✓ Network re-enabled" -ForegroundColor Green
    }
    
    # Clean up temp files
    Remove-Item (Join-Path $env:TEMP "ollama-proxy.ps1") -Force -ErrorAction SilentlyContinue
    
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
}

# Handle Ctrl+C
[Console]::TreatControlCAsInput = $false
$null = Register-ObjectEvent -InputObject ([Console]) -EventName "CancelKeyPress" -Action $cleanupScript

# Keep running
try {
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Check if processes are still running
        if ($ollamaProcess -and -not (Get-Process -Id $ollamaProcess.Id -ErrorAction SilentlyContinue)) {
            Write-Host "`nOllama process terminated!" -ForegroundColor Red
            break
        }
        if ($proxyProcess -and -not (Get-Process -Id $proxyProcess.Id -ErrorAction SilentlyContinue)) {
            Write-Host "`nProxy process terminated!" -ForegroundColor Red
            break
        }
    }
} finally {
    & $cleanupScript
}
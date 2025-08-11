# Start-CursorOffline.ps1
# Main startup script for Cursor + Ollama offline environment on Windows

param(
    [switch]$Uncensored,
    [switch]$Secure,
    [string]$Model = "llama3:8b"
)

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($Secure -and -not $isAdmin) {
    Write-Host "Secure mode requires Administrator privileges. Restarting..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File", $PSCommandPath, "-Secure", $(if($Uncensored){"-Uncensored"})
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cursor + Ollama Offline Environment" -ForegroundColor Cyan
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
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    $adapters | ForEach-Object {
        Write-Host "  Disabling: $($_.Name)" -ForegroundColor Gray
        $_ | Disable-NetAdapter -Confirm:$false
    }
    Write-Host "✓ Network disabled for security" -ForegroundColor Green
}

# Check if Ollama is installed
try {
    $ollamaPath = Get-Command ollama -ErrorAction Stop
    Write-Host "✓ Ollama found at: $($ollamaPath.Source)" -ForegroundColor Green
} catch {
    Write-Host "✗ Ollama not found! Please install Ollama first." -ForegroundColor Red
    Write-Host "  Download from: https://ollama.com/download/windows" -ForegroundColor Yellow
    exit 1
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
$ollamaProcess = Start-Process ollama -ArgumentList "serve" -PassThru -WindowStyle Hidden

# Wait for Ollama to start
$attempts = 0
$maxAttempts = 30
Write-Host "Waiting for Ollama to start" -NoNewline
while ($attempts -lt $maxAttempts) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -ErrorAction Stop
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
    $models = ollama list | Out-String
    Write-Host $models -ForegroundColor Gray
    
    if ($Uncensored) {
        Write-Host "Uncensored models:" -ForegroundColor Yellow
        $uncensoredModels = $models -split "`n" | Where-Object { $_ -match "uncensored|wizard|dolphin|nous|mytho" }
        if ($uncensoredModels) {
            $uncensoredModels | ForEach-Object { Write-Host "  $_" -ForegroundColor Magenta }
        } else {
            Write-Host "  No uncensored models found. Run Setup-UncensoredModels.ps1 first." -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Could not list models" -ForegroundColor Red
}

# Create and start local proxy
Write-Host "`nCreating local proxy..." -ForegroundColor Green

$proxyScript = @'
$host.UI.RawUI.WindowTitle = "Ollama Local Proxy"

Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.IO;
using System.Text;
using System.Threading.Tasks;

public class SimpleProxy
{
    private HttpListener listener;
    private string targetUrl;
    
    public SimpleProxy(int port, string target)
    {
        listener = new HttpListener();
        listener.Prefixes.Add($"http://localhost:{port}/");
        targetUrl = target;
    }
    
    public async Task Start()
    {
        listener.Start();
        Console.WriteLine($"Proxy started on http://localhost:8080");
        Console.WriteLine($"Forwarding to {targetUrl}");
        
        while (listener.IsListening)
        {
            try
            {
                var context = await listener.GetContextAsync();
                _ = Task.Run(() => HandleRequest(context));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Listener error: {ex.Message}");
            }
        }
    }
    
    private async Task HandleRequest(HttpListenerContext context)
    {
        try
        {
            var request = context.Request;
            var response = context.Response;
            
            // Create target URL
            var path = request.Url.PathAndQuery;
            var targetUri = targetUrl + path;
            
            // Forward request
            using (var client = new System.Net.WebClient())
            {
                client.Headers.Add("Content-Type", request.ContentType ?? "application/json");
                
                byte[] responseData;
                
                if (request.HttpMethod == "POST")
                {
                    using (var reader = new StreamReader(request.InputStream))
                    {
                        var body = reader.ReadToEnd();
                        responseData = client.UploadData(targetUri, "POST", Encoding.UTF8.GetBytes(body));
                    }
                }
                else
                {
                    responseData = client.DownloadData(targetUri);
                }
                
                // Send response
                response.ContentType = client.ResponseHeaders["Content-Type"] ?? "application/json";
                response.ContentLength64 = responseData.Length;
                await response.OutputStream.WriteAsync(responseData, 0, responseData.Length);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Request error: {ex.Message}");
            context.Response.StatusCode = 500;
        }
        finally
        {
            context.Response.Close();
        }
    }
    
    public void Stop()
    {
        listener.Stop();
        listener.Close();
    }
}
"@

$proxy = New-Object SimpleProxy -ArgumentList 8080, "http://localhost:11434"

try {
    $task = $proxy.Start()
    
    # Keep running
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
catch {
    Write-Host "Proxy error: $_" -ForegroundColor Red
}
'@

$proxyScript | Out-File -FilePath "$env:TEMP\ollama-proxy.ps1" -Force

# Start proxy in new window
$proxyProcess = Start-Process powershell -ArgumentList "-NoExit", "-File", "$env:TEMP\ollama-proxy.ps1" -PassThru

Start-Sleep -Seconds 2

# Display configuration
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nCursor Configuration:" -ForegroundColor Yellow
Write-Host "1. Open Cursor Settings (Ctrl + ,)" -ForegroundColor White
Write-Host "2. Set OpenAI Base URL to: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:8080/v1" -ForegroundColor Cyan
Write-Host "3. Set OpenAI API Key to: " -NoNewline -ForegroundColor White
Write-Host "ollama" -ForegroundColor Cyan
Write-Host "4. Add custom model: " -NoNewline -ForegroundColor White
Write-Host $Model -ForegroundColor Cyan
Write-Host "5. Disable all other models" -ForegroundColor White

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

# Handle cleanup
try {
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Check if processes are still running
        if (-not (Get-Process -Id $ollamaProcess.Id -ErrorAction SilentlyContinue)) {
            Write-Host "`nOllama process terminated!" -ForegroundColor Red
            break
        }
    }
} finally {
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    
    # Stop processes
    Stop-Process -Id $ollamaProcess.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $proxyProcess.Id -Force -ErrorAction SilentlyContinue
    
    # Re-enable network if in secure mode
    if ($Secure) {
        Write-Host "Re-enabling network adapters..." -ForegroundColor Yellow
        Get-NetAdapter | Enable-NetAdapter -ErrorAction SilentlyContinue
        Write-Host "✓ Network re-enabled" -ForegroundColor Green
    }
    
    # Clean up temp files
    Remove-Item "$env:TEMP\ollama-proxy.ps1" -Force -ErrorAction SilentlyContinue
    
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
}
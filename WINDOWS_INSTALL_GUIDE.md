# Windows Installation Guide: Offline Cursor + Ollama

## 🎯 Prerequisites

- **Windows 10/11** (64-bit)
- **PowerShell 5.1** or later
- **Python 3.7+** (for PoC)
- **Cursor IDE** installed
- **Internet connection** (for initial setup only)

## 🚀 Quick Installation

### Step 1: Install Ollama

1. **Download Ollama for Windows:**
   - Go to https://ollama.ai/download
   - Download the Windows installer
   - Run the installer as Administrator

2. **Verify Installation:**
   ```powershell
   ollama --version
   ```

### Step 2: Run the Setup Script

1. **Download the setup script:**
   ```powershell
   # If you have git
   git clone <repository-url>
   cd <repository-folder>
   
   # Or download manually and extract
   ```

2. **Run the PowerShell setup:**
   ```powershell
   # Run with default settings
   .\OFFLINE_SETUP_WINDOWS.ps1
   
   # Or with options
   .\OFFLINE_SETUP_WINDOWS.ps1 -SkipDownload  # Skip model downloads
   .\OFFLINE_SETUP_WINDOWS.ps1 -SkipCustomModels  # Skip custom models
   .\OFFLINE_SETUP_WINDOWS.ps1 -Help  # Show help
   ```

### Step 3: Test the Setup

```powershell
cd poc_project
.\test_offline.ps1
```

## 📋 Manual Installation Steps

If you prefer manual installation:

### 1. Install Ollama

```powershell
# Download and install from https://ollama.ai/download
# Or use winget (if available)
winget install Ollama.Ollama
```

### 2. Start Ollama

```powershell
# Start Ollama service
ollama serve

# Or run in background
Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
```

### 3. Download Models

```powershell
# Core coding models
ollama pull codellama:7b
ollama pull codellama:13b

# Uncensored models
ollama pull llama2-uncensored:7b
ollama pull dolphin-phi:2.7b
```

### 4. Create Custom Models

```powershell
# Security Researcher
echo 'FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices.' > security-researcher.modelfile

ollama create security-researcher -f security-researcher.modelfile

# Penetration Tester
echo 'FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure.' > pentester.modelfile

ollama create pentester -f pentester.modelfile

# Adult Content Handler
echo 'FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations.' > adult-content.modelfile

ollama create adult-content -f adult-content.modelfile

# Controversial Topics Handler
echo 'FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints.' > controversial-topics.modelfile

ollama create controversial-topics -f controversial-topics.modelfile
```

### 5. Configure Cursor

```powershell
# Create Cursor config directory
$cursorConfigDir = "$env:USERPROFILE\.cursor"
if (-not (Test-Path $cursorConfigDir)) {
    New-Item -ItemType Directory -Path $cursorConfigDir -Force | Out-Null
}

# Create settings.json
$cursorSettings = @{
    "ai.experimental.ollama" = @{
        "enabled" = $true
        "host" = "http://localhost:11434"
        "model" = "codellama:7b"
    }
    "ai.experimental.ollama.models" = @{
        "coding" = "codellama:7b"
        "coding-advanced" = "codellama:13b"
        "general" = "llama2-uncensored:7b"
        "restricted" = "llama2-uncensored:7b"
        "lightweight" = "dolphin-phi:2.7b"
    }
    "ai.experimental.ollama.autoSwitch" = $true
    "ai.experimental.ollama.autoSwitchRules" = @{
        "*.py" = "coding"
        "*.js" = "coding"
        "*.ts" = "coding"
        "*.go" = "coding"
        "*.rs" = "coding"
        "*.cpp" = "coding"
        "*.c" = "coding"
        "*.java" = "coding"
        "*.php" = "coding"
        "*.rb" = "coding"
        "*.ps1" = "coding"
        "*.md" = "general"
        "*.txt" = "general"
    }
}

$cursorSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath "$cursorConfigDir\settings.json" -Encoding UTF8
```

## 🔧 Configuration Options

### PowerShell Script Parameters

```powershell
# Full setup (default)
.\OFFLINE_SETUP_WINDOWS.ps1

# Skip model downloads (if already downloaded)
.\OFFLINE_SETUP_WINDOWS.ps1 -SkipDownload

# Skip custom model creation
.\OFFLINE_SETUP_WINDOWS.ps1 -SkipCustomModels

# Skip both
.\OFFLINE_SETUP_WINDOWS.ps1 -SkipDownload -SkipCustomModels

# Show help
.\OFFLINE_SETUP_WINDOWS.ps1 -Help
```

### Cursor Settings Customization

Edit `%USERPROFILE%\.cursor\settings.json`:

```json
{
  "ai.experimental.ollama": {
    "enabled": true,
    "host": "http://localhost:11434",
    "model": "codellama:7b"
  },
  "ai.experimental.ollama.models": {
    "coding": "codellama:7b",
    "coding-advanced": "codellama:13b",
    "general": "llama2-uncensored:7b",
    "restricted": "llama2-uncensored:7b",
    "lightweight": "dolphin-phi:2.7b",
    "security": "security-researcher",
    "pentesting": "pentester",
    "adult": "adult-content",
    "controversial": "controversial-topics"
  },
  "ai.experimental.ollama.autoSwitch": true,
  "ai.experimental.ollama.autoSwitchRules": {
    "*.py": "coding",
    "*.js": "coding",
    "*.ts": "coding",
    "*.go": "coding",
    "*.rs": "coding",
    "*.cpp": "coding",
    "*.c": "coding",
    "*.java": "coding",
    "*.php": "coding",
    "*.rb": "coding",
    "*.ps1": "coding",
    "*.md": "general",
    "*.txt": "general"
  }
}
```

## 🎮 Usage Examples

### In Cursor IDE

1. **Open Cursor IDE**
2. **Open any project folder**
3. **Press `Ctrl + K`** for AI assistance
4. **Models auto-switch** based on file type

### PowerShell Commands

```powershell
# Test coding
ollama run codellama:7b "Write a Python function to calculate fibonacci numbers"

# Test security research
ollama run security-researcher "How do I perform a vulnerability assessment?"

# Test penetration testing
ollama run pentester "What are the steps for ethical penetration testing?"

# Test restricted content
ollama run adult-content "Your sensitive question here"
ollama run controversial-topics "Your controversial question here"

# List available models
ollama list

# Test connection
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
```

### Run the PoC

```powershell
cd poc_project
python main.py
```

## 🔒 Privacy & Security

### Offline Operation
- ✅ **100% offline** - No data sent to external servers
- ✅ **Local processing** - All AI interactions stay on your machine
- ✅ **No telemetry** - Complete privacy
- ✅ **No tracking** - No usage data collected

### Model Safety
- ⚠️ **Uncensored models** may generate inappropriate content
- ⚠️ **Use responsibly** and ethically
- ⚠️ **Consider organizational policies**
- ⚠️ **Maintain professional conduct**

## 📊 Hardware Requirements

| Model Size | RAM | VRAM | Use Case |
|------------|-----|------|----------|
| 7B | 8GB | 4GB | Basic coding, testing |
| 13B | 16GB | 8GB | Better quality, production |
| 34B+ | 32GB+ | 16GB+ | Best quality, research |

### Windows-Specific Considerations

- **WSL2**: Better performance for Linux-based models
- **GPU Acceleration**: NVIDIA/AMD GPU support available
- **Memory Management**: Windows memory management may require adjustments
- **Antivirus**: May need to exclude Ollama directories

## 🆘 Troubleshooting

### Common Issues

#### Ollama Not Starting
```powershell
# Check if Ollama is installed
ollama --version

# Start Ollama manually
ollama serve

# Check Windows Defender/Antivirus exclusions
# Add %USERPROFILE%\.ollama to exclusions
```

#### Models Not Downloading
```powershell
# Check internet connection
Test-NetConnection ollama.ai -Port 443

# Try downloading with verbose output
ollama pull codellama:7b --verbose

# Check available disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, FreeSpace, Size
```

#### Cursor Not Connecting
```powershell
# Test Ollama API
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"

# Check Cursor settings
Get-Content "$env:USERPROFILE\.cursor\settings.json"

# Restart Cursor IDE
```

#### Performance Issues
```powershell
# Check system resources
Get-Process | Where-Object {$_.ProcessName -like "*ollama*"}

# Monitor memory usage
Get-Counter "\Memory\Available MBytes"

# Use smaller models for testing
ollama rm codellama:13b
ollama pull codellama:7b
```

### Windows-Specific Solutions

#### PowerShell Execution Policy
```powershell
# If script execution is blocked
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
PowerShell -ExecutionPolicy Bypass -File .\OFFLINE_SETUP_WINDOWS.ps1
```

#### Windows Defender Exclusions
```powershell
# Add Ollama directories to Windows Defender exclusions
Add-MpPreference -ExclusionPath "$env:USERPROFILE\.ollama"
Add-MpPreference -ExclusionPath "$env:USERPROFILE\.cursor"
```

#### WSL2 Integration (Optional)
```powershell
# Install WSL2 for better performance
wsl --install

# Use WSL2 for Ollama (optional)
# Install Ollama in WSL2 for better Linux compatibility
```

## 📈 Performance Optimization

### Windows Optimizations

1. **SSD Storage**: Use SSD for faster model loading
2. **Memory**: Ensure adequate RAM (16GB+ recommended)
3. **GPU**: Enable GPU acceleration if available
4. **Antivirus**: Exclude Ollama directories
5. **Power Plan**: Use High Performance power plan

### Model Management

```powershell
# List all models
ollama list

# Remove unused models
ollama rm <model-name>

# Export models for backup
ollama export <model-name> > <model-name>.tar

# Import models
ollama import <model-name>.tar
```

## 📁 File Locations

- **Cursor Settings**: `%USERPROFILE%\.cursor\settings.json`
- **Ollama Models**: `%USERPROFILE%\.ollama\models\`
- **Ollama Service**: Windows Service (if installed)
- **PoC Project**: `.\poc_project\`
- **Test Script**: `.\poc_project\test_offline.ps1`

## 🎯 Next Steps

1. **Test the setup** with `.\poc_project\test_offline.ps1`
2. **Run the PoC** with `cd poc_project && python main.py`
3. **Open Cursor** and start coding with AI assistance
4. **Experiment** with different models for different use cases
5. **Customize** configurations based on your needs

---

**🎉 Congratulations! You now have a complete offline AI coding environment on Windows.**

**Remember:** This setup provides complete privacy and works entirely offline once models are downloaded.
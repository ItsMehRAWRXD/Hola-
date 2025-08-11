# Windows 11 Offline Cursor + Ollama Quick Start Guide

This guide provides everything you need to run Cursor IDE with Ollama completely offline on Windows 11, including uncensored models for unrestricted development.

## 📋 Prerequisites

- Windows 11 (or Windows 10 version 20H2+)
- PowerShell 5.1 (included with Windows)
- 16GB+ RAM (32GB recommended for larger models)
- 50GB+ free disk space
- Administrator privileges for secure mode

## 🚀 Quick Start

### Step 1: Initial Setup (Requires Internet)

1. **Install Ollama:**
   ```powershell
   # Download from https://ollama.com/download/windows
   # Run OllamaSetup.exe as Administrator
   ```

2. **Install Cursor:**
   ```powershell
   # Download from https://cursor.sh
   # Run cursor-setup.exe
   ```

3. **Download Models:**
   ```powershell
   # Open PowerShell as Administrator
   cd path\to\windows-scripts
   
   # Set execution policy
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
   
   # Install uncensored models
   .\Setup-UncensoredModels.ps1
   ```

### Step 2: Offline Operation

Once setup is complete, you can disconnect from the internet and run completely offline:

```powershell
# Normal offline mode
.\Start-CursorOffline.ps1

# Uncensored mode
.\Start-CursorOffline.ps1 -Uncensored

# Secure mode (disables network)
.\Start-CursorOffline.ps1 -Uncensored -Secure
```

### Step 3: Configure Cursor

When the script starts, it will display configuration instructions:

1. Open Cursor Settings (`Ctrl + ,`)
2. Search for "OpenAI Base URL"
3. Set Base URL to: `http://localhost:8080/v1`
4. Set API Key to: `ollama`
5. Add custom model (e.g., `wizard-uncensored:13b` or `uncensored-coder`)
6. Disable all cloud models

## 📁 Script Descriptions

### `Start-CursorOffline.ps1`
Main startup script that:
- Starts Ollama server
- Creates local proxy for Cursor compatibility
- Manages network isolation in secure mode
- Handles cleanup on exit

**Parameters:**
- `-Uncensored`: Use uncensored models
- `-Secure`: Disable network adapters for air-gapped operation
- `-Model`: Specify custom model name

### `Setup-UncensoredModels.ps1`
Installs and configures uncensored models:
- Downloads various uncensored models
- Creates custom "uncensored-coder" model
- Verifies installation

**Parameters:**
- `-All`: Install all available models
- `-CreateCustom`: Only create custom model

### `Test-UncensoredModels.ps1`
Tests uncensored models with PoC examples:
- Security research tools
- Adult content systems
- Medical/pharmaceutical applications
- Game hacking tools

**Parameters:**
- `-TestType`: Security, Adult, Medical, GameHack, All, or Custom
- `-Model`: Model to test with
- `-SaveResults`: Save outputs to files

## 🔒 Security Modes

### Normal Mode
- Ollama runs on localhost
- Network remains active
- Suitable for general development

### Secure Mode (`-Secure`)
- Requires Administrator privileges
- Disables all network adapters
- Complete air-gap for sensitive projects
- Network automatically re-enabled on exit

## 🤖 Available Uncensored Models

| Model | Size | Use Case |
|-------|------|----------|
| `wizard-uncensored:13b` | 8GB | General purpose, best overall |
| `dolphin-llama3:8b` | 5GB | Efficient, good for most tasks |
| `nous-hermes:13b` | 8GB | Technical and coding tasks |
| `mythomax:13b` | 8GB | Creative content |
| `uncensored-coder` | 8GB | Custom model for coding |

## 🛠️ Troubleshooting

### PowerShell Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

### Ollama Not Found
Check installation paths:
```powershell
Get-Command ollama
# Or check: C:\Program Files\Ollama\ollama.exe
```

### Port Already in Use
```powershell
# Find process using port
netstat -ano | findstr :11434
# Kill process
Stop-Process -Id [PID] -Force
```

### Proxy Not Working
- Ensure Windows Firewall allows localhost connections
- Try running as Administrator
- Check if port 8080 is available

### Models Not Loading
```powershell
# Verify models exist
ollama list

# Check model storage
Get-ChildItem "$env:USERPROFILE\.ollama\models" -Recurse
```

## 💾 Offline Model Transfer

To transfer models to an offline machine:

**On Internet-Connected Machine:**
```powershell
# Backup models
$source = "$env:USERPROFILE\.ollama\models"
$dest = "D:\ollama-backup"
Copy-Item -Path $source -Destination $dest -Recurse
```

**On Offline Machine:**
```powershell
# Restore models
$source = "D:\ollama-backup\models"
$dest = "$env:USERPROFILE\.ollama"
Copy-Item -Path $source -Destination $dest -Recurse
```

## 🧪 Testing Uncensored Models

Run the test script to verify uncensored capabilities:

```powershell
# Test all PoCs
.\Test-UncensoredModels.ps1 -TestType All -SaveResults

# Test specific use case
.\Test-UncensoredModels.ps1 -TestType Security -SaveResults

# Custom test
.\Test-UncensoredModels.ps1 -TestType Custom
```

## ⚠️ Important Notes

1. **Legal Compliance**: Ensure all usage complies with local laws and regulations
2. **Authorization**: Only use generated code where you have proper authorization
3. **Privacy**: In secure mode, all data remains on your machine
4. **Resources**: Larger models require more RAM and may run slowly on some systems

## 📞 Support

- **Ollama Issues**: https://github.com/ollama/ollama/issues
- **Cursor Support**: https://forum.cursor.sh
- **Model Information**: https://ollama.ai/library

## 🔐 Privacy & Security

This setup ensures:
- ✅ No data sent to cloud services
- ✅ Complete offline operation after initial setup
- ✅ Air-gapped mode for sensitive projects
- ✅ No telemetry or tracking
- ✅ All processing on local hardware

Remember: With great power comes great responsibility. Use these tools ethically and legally.
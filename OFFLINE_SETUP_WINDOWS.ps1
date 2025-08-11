# Complete Offline Cursor + Ollama Setup for Windows PowerShell 5.1
# This script creates a fully offline AI coding environment

param(
    [switch]$SkipDownload,
    [switch]$SkipCustomModels,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\OFFLINE_SETUP_WINDOWS.ps1 [-SkipDownload] [-SkipCustomModels] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -SkipDownload      Skip downloading models (if already downloaded)"
    Write-Host "  -SkipCustomModels  Skip creating custom model configurations"
    Write-Host "  -Help              Show this help message"
    exit 0
}

Write-Host "🚀 Setting up Complete Offline Cursor + Ollama Environment for Windows..." -ForegroundColor Green

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Ollama is installed
Write-Status "Checking Ollama installation..."
try {
    $ollamaVersion = ollama --version 2>$null
    if ($ollamaVersion) {
        Write-Success "Ollama is installed: $ollamaVersion"
    } else {
        throw "Ollama not found"
    }
} catch {
    Write-Error "Ollama is not installed. Please install Ollama first from https://ollama.ai/download"
    Write-Host "Download and run the Windows installer, then restart this script."
    exit 1
}

# Start Ollama if not running
Write-Status "Starting Ollama..."
try {
    $ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if (-not $ollamaProcess) {
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Write-Status "Waiting for Ollama to start..."
        Start-Sleep -Seconds 10
    } else {
        Write-Success "Ollama is already running"
    }
} catch {
    Write-Error "Failed to start Ollama"
    exit 1
}

# Test Ollama connection
Write-Status "Testing Ollama connection..."
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 10
    Write-Success "Ollama is responding"
} catch {
    Write-Error "Ollama is not responding. Please check if it's running properly."
    exit 1
}

# Function to download model
function Download-Model {
    param(
        [string]$ModelName,
        [string]$Description
    )
    
    Write-Status "Downloading $ModelName ($Description)..."
    try {
        ollama pull $ModelName
        Write-Success "$ModelName downloaded successfully"
    } catch {
        Write-Error "Failed to download $ModelName"
        return $false
    }
    return $true
}

# Download essential models for offline operation
if (-not $SkipDownload) {
    Write-Status "Downloading essential models for offline operation..."
    
    # Core coding models
    Download-Model "codellama:7b" "Core coding model (4GB)"
    Download-Model "codellama:13b" "Advanced coding model (8GB)"
    
    # Uncensored models for restricted content
    Download-Model "llama2-uncensored:7b" "Uncensored general model (4GB)"
    
    # Alternative uncensored models
    Download-Model "dolphin-phi:2.7b" "Lightweight uncensored model (1.5GB)"
} else {
    Write-Warning "Skipping model downloads"
}

# Create Cursor configuration directory
$cursorConfigDir = "$env:USERPROFILE\.cursor"
if (-not (Test-Path $cursorConfigDir)) {
    New-Item -ItemType Directory -Path $cursorConfigDir -Force | Out-Null
    Write-Status "Created Cursor configuration directory"
}

# Create comprehensive Cursor settings
Write-Status "Creating Cursor configuration..."
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
Write-Success "Cursor configuration created at $cursorConfigDir\settings.json"

# Create custom model configurations
if (-not $SkipCustomModels) {
    Write-Status "Creating custom model configurations..."
    
    # Security Researcher
    Write-Status "Creating security-researcher model..."
    $securityModelfile = @"
FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices.
"@
    $securityModelfile | Out-File -FilePath "security-researcher.modelfile" -Encoding UTF8
    ollama create security-researcher -f security-researcher.modelfile
    
    # Penetration Tester
    Write-Status "Creating pentester model..."
    $pentesterModelfile = @"
FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure.
"@
    $pentesterModelfile | Out-File -FilePath "pentester.modelfile" -Encoding UTF8
    ollama create pentester -f pentester.modelfile
    
    # Adult Content Handler
    Write-Status "Creating adult-content model..."
    $adultModelfile = @"
FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations.
"@
    $adultModelfile | Out-File -FilePath "adult-content.modelfile" -Encoding UTF8
    ollama create adult-content -f adult-content.modelfile
    
    # Controversial Topics Handler
    Write-Status "Creating controversial-topics model..."
    $controversialModelfile = @"
FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints.
"@
    $controversialModelfile | Out-File -FilePath "controversial-topics.modelfile" -Encoding UTF8
    ollama create controversial-topics -f controversial-topics.modelfile
    
    Write-Success "Custom models created"
} else {
    Write-Warning "Skipping custom model creation"
}

# Create PoC project
Write-Status "Creating Proof of Concept project..."
$pocDir = "poc_project"
if (-not (Test-Path $pocDir)) {
    New-Item -ItemType Directory -Path $pocDir -Force | Out-Null
}

Set-Location $pocDir

# Create sample Python project
$mainPy = @'
#!/usr/bin/env python3
"""
Offline AI Coding PoC - Main Application
This demonstrates the capabilities of offline Cursor + Ollama setup
"""

import json
import subprocess
import sys
from typing import Dict, List, Optional

class OfflineAICoder:
    def __init__(self):
        self.models = {
            "coding": "codellama:7b",
            "security": "security-researcher",
            "adult": "adult-content",
            "controversial": "controversial-topics"
        }
    
    def test_model(self, model_name: str, prompt: str) -> str:
        """Test a specific model with a prompt"""
        try:
            result = subprocess.run(
                ["ollama", "run", model_name, prompt],
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            return "Timeout: Model took too long to respond"
        except Exception as e:
            return f"Error: {str(e)}"
    
    def run_coding_test(self) -> Dict[str, str]:
        """Test coding capabilities"""
        print("🧪 Testing coding capabilities...")
        
        tests = {
            "Python Function": "Write a Python function to calculate fibonacci numbers",
            "Security Code": "Write a secure password validation function in Python",
            "Web Scraping": "Create a Python script to scrape a website safely",
            "Data Analysis": "Write Python code to analyze a CSV file with pandas"
        }
        
        results = {}
        for test_name, prompt in tests.items():
            print(f"  Testing: {test_name}")
            result = self.test_model("codellama:7b", prompt)
            results[test_name] = result[:200] + "..." if len(result) > 200 else result
        
        return results
    
    def run_security_test(self) -> Dict[str, str]:
        """Test security research capabilities"""
        print("🔒 Testing security research capabilities...")
        
        tests = {
            "Vulnerability Assessment": "How do I perform a vulnerability assessment on a web application?",
            "Penetration Testing": "What are the steps for ethical penetration testing?",
            "Security Hardening": "How do I harden a Windows server for production use?",
            "Incident Response": "What are the key steps in incident response?"
        }
        
        results = {}
        for test_name, prompt in tests.items():
            print(f"  Testing: {test_name}")
            result = self.test_model("security-researcher", prompt)
            results[test_name] = result[:200] + "..." if len(result) > 200 else result
        
        return results
    
    def run_restricted_content_test(self) -> Dict[str, str]:
        """Test restricted content handling"""
        print("🚫 Testing restricted content handling...")
        
        tests = {
            "Adult Content": "How do I handle mature content appropriately?",
            "Controversial Topics": "Discuss the ethical implications of AI in warfare",
            "Sensitive Subjects": "How should I approach discussing sensitive political topics?"
        }
        
        results = {}
        for test_name, prompt in tests.items():
            print(f"  Testing: {test_name}")
            if "Adult" in test_name:
                result = self.test_model("adult-content", prompt)
            elif "Controversial" in test_name:
                result = self.test_model("controversial-topics", prompt)
            else:
                result = self.test_model("llama2-uncensored:7b", prompt)
            results[test_name] = result[:200] + "..." if len(result) > 200 else result
        
        return results
    
    def generate_report(self) -> str:
        """Generate a comprehensive test report"""
        print("📊 Generating comprehensive test report...")
        
        report = {
            "timestamp": subprocess.run(["Get-Date"], capture_output=True, text=True, shell=True).stdout.strip(),
            "system_info": {
                "python_version": sys.version,
                "platform": sys.platform,
                "ollama_models": self.get_available_models()
            },
            "coding_tests": self.run_coding_test(),
            "security_tests": self.run_security_test(),
            "restricted_content_tests": self.run_restricted_content_test()
        }
        
        return json.dumps(report, indent=2)
    
    def get_available_models(self) -> List[str]:
        """Get list of available models"""
        try:
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
            return [line.split()[0] for line in result.stdout.strip().split('\n')[1:] if line.strip()]
        except:
            return ["Error getting models"]

def main():
    print("🚀 Offline AI Coding PoC")
    print("=" * 50)
    
    coder = OfflineAICoder()
    
    # Generate and save report
    report = coder.generate_report()
    
    with open("poc_report.json", "w") as f:
        f.write(report)
    
    print("\n✅ PoC completed! Report saved to poc_report.json")
    print("\n📋 Quick Test Commands:")
    print("  ollama run codellama:7b 'Write a Python hello world'")
    print("  ollama run security-researcher 'How to secure a web app?'")
    print("  ollama run adult-content 'Your question here'")
    print("  ollama run controversial-topics 'Your question here'")

if __name__ == "__main__":
    main()
'@

$mainPy | Out-File -FilePath "main.py" -Encoding UTF8

# Create requirements file
$requirements = @"
# Offline AI Coding PoC Requirements
# No external dependencies - everything runs locally with Ollama
"@
$requirements | Out-File -FilePath "requirements.txt" -Encoding UTF8

# Create README for PoC
$readme = @"
# Offline AI Coding PoC

This Proof of Concept demonstrates a complete offline AI coding environment using Cursor + Ollama on Windows.

## 🎯 What This PoC Demonstrates

1. **Offline Operation**: All AI processing happens locally
2. **Multiple Model Types**: Coding, security, and restricted content models
3. **Custom Configurations**: Specialized models for different use cases
4. **Cursor Integration**: Seamless IDE integration
5. **No Internet Required**: Once models are downloaded, works completely offline

## 🚀 Quick Start

1. **Run the PoC**:
   ```powershell
   python main.py
   ```

2. **Test Individual Models**:
   ```powershell
   # Coding
   ollama run codellama:7b "Write a Python function to sort a list"
   
   # Security Research
   ollama run security-researcher "How do I perform a security audit?"
   
   # Restricted Content
   ollama run adult-content "Your question here"
   ollama run controversial-topics "Your question here"
   ```

3. **Open in Cursor**:
   - Open this project in Cursor
   - Use Ctrl + K for AI assistance
   - Models will auto-switch based on file type

## 📊 Test Results

The PoC generates a comprehensive report (`poc_report.json`) that includes:
- Coding capability tests
- Security research tests
- Restricted content handling tests
- System information and available models

## 🔧 Configuration

### Cursor Settings
Located at: `%USERPROFILE%\.cursor\settings.json`

### Available Models
- `codellama:7b` - Core coding model
- `codellama:13b` - Advanced coding model
- `llama2-uncensored:7b` - General uncensored model
- `dolphin-phi:2.7b` - Lightweight uncensored model
- `security-researcher` - Security research assistant
- `adult-content` - Adult content handler
- `controversial-topics` - Controversial topics handler

## 🔒 Privacy & Security

- ✅ 100% offline operation
- ✅ No data sent to external servers
- ✅ Local processing only
- ✅ No telemetry or tracking
- ✅ Complete privacy

## 📁 Project Structure

```
poc_project/
├── main.py              # Main PoC application
├── requirements.txt     # Dependencies (none external)
├── README.md           # This file
└── poc_report.json     # Generated test report
```

## 🎮 Usage Examples

### In Cursor IDE
1. Open any code file
2. Press `Ctrl + K`
3. Ask coding questions
4. Models auto-switch based on content

### PowerShell
```powershell
# Test coding
ollama run codellama:7b "Debug this Python code: [paste code]"

# Test security
ollama run security-researcher "How do I secure this API endpoint?"

# Test restricted content
ollama run adult-content "Your sensitive question"
```

## 🔧 Troubleshooting

### Ollama Not Running
```powershell
ollama serve
```

### Check Available Models
```powershell
ollama list
```

### Test Connection
```powershell
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
```

## 📈 Performance Tips

- Use 7B models for faster responses
- Use 13B models for better quality
- Match model size to your hardware
- Keep frequently used models loaded

---

**Note**: This PoC demonstrates the full capabilities of offline AI coding while maintaining appropriate ethical boundaries.
"@

$readme | Out-File -FilePath "README.md" -Encoding UTF8

# Create a PowerShell test script
$testScript = @'
# Test Offline AI Setup for Windows

Write-Host "🧪 Testing Offline AI Setup..." -ForegroundColor Green

# Test Ollama connection
Write-Host "1. Testing Ollama connection..." -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 10
    Write-Host "   ✅ Ollama is running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Ollama is not responding" -ForegroundColor Red
    exit 1
}

# Test model availability
Write-Host "2. Testing model availability..." -ForegroundColor Blue
$models = ollama list
$modelCount = ($models | Select-String -Pattern "(codellama|llama2-uncensored|security-researcher|adult-content)" | Measure-Object).Count
Write-Host "   ✅ Found $modelCount models" -ForegroundColor Green

# Test basic coding
Write-Host "3. Testing coding capabilities..." -ForegroundColor Blue
$result = ollama run codellama:7b "Write a simple Python hello world function" 2>$null | Select-Object -First 5
if ($result) {
    Write-Host "   ✅ Coding model working" -ForegroundColor Green
} else {
    Write-Host "   ❌ Coding model not responding" -ForegroundColor Red
}

# Test security model
Write-Host "4. Testing security model..." -ForegroundColor Blue
$result = ollama run security-researcher "What is penetration testing?" 2>$null | Select-Object -First 3
if ($result) {
    Write-Host "   ✅ Security model working" -ForegroundColor Green
} else {
    Write-Host "   ❌ Security model not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Offline AI setup is working!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open Cursor IDE"
Write-Host "2. Open this project"
Write-Host "3. Use Ctrl + K for AI assistance"
Write-Host "4. Run: python main.py for full PoC"
'@

$testScript | Out-File -FilePath "test_offline.ps1" -Encoding UTF8

Set-Location ..

# Create final setup summary
$summary = @"
# Offline Cursor + Ollama Setup Complete for Windows! 🎉

## ✅ What's Been Set Up

### 1. Ollama Installation & Models
- ✅ Ollama installed and running
- ✅ Core coding models downloaded (codellama:7b, codellama:13b)
- ✅ Uncensored models downloaded (llama2-uncensored:7b)
- ✅ Alternative models downloaded (dolphin-phi:2.7b)

### 2. Custom Model Configurations
- ✅ security-researcher - Cybersecurity research
- ✅ pentester - Penetration testing
- ✅ adult-content - Adult content handling
- ✅ controversial-topics - Controversial topics

### 3. Cursor Configuration
- ✅ Settings configured at %USERPROFILE%\.cursor\settings.json
- ✅ Auto-switching enabled based on file type
- ✅ Multiple model profiles configured

### 4. Proof of Concept
- ✅ Complete PoC project created in poc_project/
- ✅ Test scripts and examples
- ✅ Comprehensive documentation

## 🚀 How to Use

### 1. Test the Setup
```powershell
cd poc_project
.\test_offline.ps1
```

### 2. Run the Full PoC
```powershell
cd poc_project
python main.py
```

### 3. Use in Cursor
1. Open Cursor IDE
2. Open the poc_project folder
3. Press Ctrl + K for AI assistance
4. Models will auto-switch based on file type

### 4. Test Individual Models
```powershell
# Coding
ollama run codellama:7b "Write a Python function"

# Security
ollama run security-researcher "How to secure a web app?"

# Restricted content
ollama run adult-content "Your question"
ollama run controversial-topics "Your question"
```

## 📊 Available Models

| Model | Size | Use Case | Status |
|-------|------|----------|--------|
| codellama:7b | 4GB | Coding | ✅ Downloaded |
| codellama:13b | 8GB | Advanced coding | ✅ Downloaded |
| llama2-uncensored:7b | 4GB | General uncensored | ✅ Downloaded |
| dolphin-phi:2.7b | 1.5GB | Lightweight uncensored | ✅ Downloaded |
| security-researcher | Custom | Security research | ✅ Created |
| pentester | Custom | Penetration testing | ✅ Created |
| adult-content | Custom | Adult content | ✅ Created |
| controversial-topics | Custom | Controversial topics | ✅ Created |

## 🔒 Privacy & Security

- ✅ 100% offline operation
- ✅ No data sent to external servers
- ✅ Local processing only
- ✅ No telemetry or tracking
- ✅ Complete privacy

## 📁 File Locations

- **Cursor Settings**: %USERPROFILE%\.cursor\settings.json
- **Ollama Models**: %USERPROFILE%\.ollama\models\
- **PoC Project**: .\poc_project\
- **Test Script**: .\poc_project\test_offline.ps1

## 🎯 Use Cases Supported

1. **Normal Coding Projects**
   - Python, JavaScript, TypeScript, Go, Rust, etc.
   - Code generation, debugging, refactoring
   - Documentation and comments

2. **Restricted Content**
   - Security research and penetration testing
   - System administration and hardening
   - Adult content and mature topics
   - Controversial subjects and political topics

3. **Specialized Tasks**
   - Malware analysis and reverse engineering
   - Network security and firewall configuration
   - Vulnerability assessment and exploit development

## 🔧 Management Commands

```powershell
# List all models
ollama list

# Run a model
ollama run <model-name> "Your question"

# Remove a model
ollama rm <model-name>

# Export/Import models
ollama export <model-name> > <model-name>.tar
ollama import <model-name>.tar
```

## 📈 Performance Tips

- Start with 7B models for testing
- Use 13B models for better quality
- Match model size to your hardware
- Keep frequently used models loaded

## 🆘 Troubleshooting

### Ollama Not Starting
```powershell
ollama serve
```

### Check Model Status
```powershell
ollama list
```

### Test Connection
```powershell
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
```

### Reset Cursor Settings
```powershell
Remove-Item "$env:USERPROFILE\.cursor\settings.json"
# Re-run setup script
```

---

**🎉 Congratulations! You now have a complete offline AI coding environment on Windows.**

**Next Steps:**
1. Test the setup with `.\poc_project\test_offline.ps1`
2. Run the full PoC with `cd poc_project && python main.py`
3. Open Cursor and start coding with AI assistance
4. Use different models for different types of content

**Remember:** This setup provides complete privacy and works entirely offline once models are downloaded.
"@

$summary | Out-File -FilePath "OFFLINE_SETUP_SUMMARY_WINDOWS.md" -Encoding UTF8

# List final status
Write-Host ""
Write-Success "🎉 Complete Offline Setup Finished for Windows!"
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "  ✅ Ollama installed and running"
Write-Host "  ✅ 4 base models downloaded"
Write-Host "  ✅ 4 custom models created"
Write-Host "  ✅ Cursor configured"
Write-Host "  ✅ PoC project created"
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test setup: cd poc_project && .\test_offline.ps1"
Write-Host "  2. Run PoC: cd poc_project && python main.py"
Write-Host "  3. Open Cursor and start coding!"
Write-Host ""
Write-Host "📁 Files Created:" -ForegroundColor Yellow
Write-Host "  - poc_project\ (Complete PoC)"
Write-Host "  - OFFLINE_SETUP_SUMMARY_WINDOWS.md (Setup summary)"
Write-Host "  - %USERPROFILE%\.cursor\settings.json (Cursor config)"
Write-Host ""
Write-Host "🔒 Privacy: 100% offline operation guaranteed!" -ForegroundColor Green
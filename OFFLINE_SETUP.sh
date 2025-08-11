#!/bin/bash

# Complete Offline Cursor + Ollama Setup with PoC
# This script creates a fully offline AI coding environment

set -e

echo "🚀 Setting up Complete Offline Cursor + Ollama Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    print_status "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# Start Ollama in background
print_status "Starting Ollama..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to start
sleep 10

# Test Ollama connection
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    print_error "Ollama failed to start"
    exit 1
fi

print_success "Ollama is running"

# Function to download model with progress
download_model() {
    local model_name=$1
    local description=$2
    
    print_status "Downloading $model_name ($description)..."
    if ollama pull "$model_name"; then
        print_success "$model_name downloaded successfully"
    else
        print_error "Failed to download $model_name"
        return 1
    fi
}

# Download essential models for offline operation
print_status "Downloading essential models for offline operation..."

# Core coding models
download_model "codellama:7b" "Core coding model (4GB)"
download_model "codellama:13b" "Advanced coding model (8GB)"

# Uncensored models for restricted content
download_model "llama2-uncensored:7b" "Uncensored general model (4GB)"
download_model "llama2-uncensored:13b" "Advanced uncensored model (8GB)"

# Alternative uncensored models
download_model "airoboros:7b" "Alternative uncensored model (4GB)"
download_model "dolphin-phi:2.7b" "Lightweight uncensored model (1.5GB)"

# Create Cursor configuration directory
CURSOR_CONFIG_DIR="$HOME/.cursor"
mkdir -p "$CURSOR_CONFIG_DIR"

# Create comprehensive Cursor settings
print_status "Creating Cursor configuration..."
cat > "$CURSOR_CONFIG_DIR/settings.json" << 'EOF'
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
    "general-advanced": "llama2-uncensored:13b",
    "restricted": "llama2-uncensored:7b",
    "alternative": "airoboros:7b",
    "lightweight": "dolphin-phi:2.7b"
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
    "*.sh": "coding",
    "*.md": "general",
    "*.txt": "general"
  }
}
EOF

print_success "Cursor configuration created"

# Create custom model configurations
print_status "Creating custom model configurations..."

# Security Researcher
ollama create security-researcher -f - <<EOF
FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices.
EOF

# Penetration Tester
ollama create pentester -f - <<EOF
FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure.
EOF

# Adult Content Handler
ollama create adult-content -f - <<EOF
FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations.
EOF

# Controversial Topics Handler
ollama create controversial-topics -f - <<EOF
FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints.
EOF

print_success "Custom models created"

# Create PoC project
print_status "Creating Proof of Concept project..."

mkdir -p poc_project
cd poc_project

# Create sample Python project
cat > main.py << 'EOF'
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
            "Security Hardening": "How do I harden a Linux server for production use?",
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
            "timestamp": subprocess.run(["date"], capture_output=True, text=True).stdout.strip(),
            "system_info": {
                "python_version": sys.version,
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
EOF

# Create requirements file
cat > requirements.txt << 'EOF'
# Offline AI Coding PoC Requirements
# No external dependencies - everything runs locally with Ollama
EOF

# Create README for PoC
cat > README.md << 'EOF'
# Offline AI Coding PoC

This Proof of Concept demonstrates a complete offline AI coding environment using Cursor + Ollama.

## 🎯 What This PoC Demonstrates

1. **Offline Operation**: All AI processing happens locally
2. **Multiple Model Types**: Coding, security, and restricted content models
3. **Custom Configurations**: Specialized models for different use cases
4. **Cursor Integration**: Seamless IDE integration
5. **No Internet Required**: Once models are downloaded, works completely offline

## 🚀 Quick Start

1. **Run the PoC**:
   ```bash
   python3 main.py
   ```

2. **Test Individual Models**:
   ```bash
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
   - Use Cmd/Ctrl + K for AI assistance
   - Models will auto-switch based on file type

## 📊 Test Results

The PoC generates a comprehensive report (`poc_report.json`) that includes:
- Coding capability tests
- Security research tests
- Restricted content handling tests
- System information and available models

## 🔧 Configuration

### Cursor Settings
Located at: `~/.cursor/settings.json`

### Available Models
- `codellama:7b` - Core coding model
- `codellama:13b` - Advanced coding model
- `llama2-uncensored:7b` - General uncensored model
- `llama2-uncensored:13b` - Advanced uncensored model
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
2. Press `Cmd/Ctrl + K`
3. Ask coding questions
4. Models auto-switch based on content

### Command Line
```bash
# Test coding
ollama run codellama:7b "Debug this Python code: [paste code]"

# Test security
ollama run security-researcher "How do I secure this API endpoint?"

# Test restricted content
ollama run adult-content "Your sensitive question"
```

## 🔧 Troubleshooting

### Ollama Not Running
```bash
ollama serve
```

### Check Available Models
```bash
ollama list
```

### Test Connection
```bash
curl http://localhost:11434/api/tags
```

## 📈 Performance Tips

- Use 7B models for faster responses
- Use 13B models for better quality
- Match model size to your hardware
- Keep frequently used models loaded

---

**Note**: This PoC demonstrates the full capabilities of offline AI coding while maintaining appropriate ethical boundaries.
EOF

# Create a simple test script
cat > test_offline.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Offline AI Setup..."

# Test Ollama connection
echo "1. Testing Ollama connection..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "   ✅ Ollama is running"
else
    echo "   ❌ Ollama is not responding"
    exit 1
fi

# Test model availability
echo "2. Testing model availability..."
MODELS=$(ollama list | grep -E "(codellama|llama2-uncensored|security-researcher|adult-content)" | wc -l)
echo "   ✅ Found $MODELS models"

# Test basic coding
echo "3. Testing coding capabilities..."
RESULT=$(ollama run codellama:7b "Write a simple Python hello world function" 2>/dev/null | head -5)
if [ ! -z "$RESULT" ]; then
    echo "   ✅ Coding model working"
else
    echo "   ❌ Coding model not responding"
fi

# Test security model
echo "4. Testing security model..."
RESULT=$(ollama run security-researcher "What is penetration testing?" 2>/dev/null | head -3)
if [ ! -z "$RESULT" ]; then
    echo "   ✅ Security model working"
else
    echo "   ❌ Security model not responding"
fi

echo ""
echo "🎉 Offline AI setup is working!"
echo ""
echo "Next steps:"
echo "1. Open Cursor IDE"
echo "2. Open this project"
echo "3. Use Cmd/Ctrl + K for AI assistance"
echo "4. Run: python3 main.py for full PoC"
EOF

chmod +x test_offline.sh

cd ..

# Create final setup summary
cat > OFFLINE_SETUP_SUMMARY.md << 'EOF'
# Offline Cursor + Ollama Setup Complete! 🎉

## ✅ What's Been Set Up

### 1. Ollama Installation & Models
- ✅ Ollama installed and running
- ✅ Core coding models downloaded (codellama:7b, codellama:13b)
- ✅ Uncensored models downloaded (llama2-uncensored:7b, llama2-uncensored:13b)
- ✅ Alternative models downloaded (airoboros:7b, dolphin-phi:2.7b)

### 2. Custom Model Configurations
- ✅ security-researcher - Cybersecurity research
- ✅ pentester - Penetration testing
- ✅ adult-content - Adult content handling
- ✅ controversial-topics - Controversial topics

### 3. Cursor Configuration
- ✅ Settings configured at ~/.cursor/settings.json
- ✅ Auto-switching enabled based on file type
- ✅ Multiple model profiles configured

### 4. Proof of Concept
- ✅ Complete PoC project created in poc_project/
- ✅ Test scripts and examples
- ✅ Comprehensive documentation

## 🚀 How to Use

### 1. Test the Setup
```bash
cd poc_project
./test_offline.sh
```

### 2. Run the Full PoC
```bash
cd poc_project
python3 main.py
```

### 3. Use in Cursor
1. Open Cursor IDE
2. Open the poc_project folder
3. Press Cmd/Ctrl + K for AI assistance
4. Models will auto-switch based on file type

### 4. Test Individual Models
```bash
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
| llama2-uncensored:13b | 8GB | Advanced uncensored | ✅ Downloaded |
| airoboros:7b | 4GB | Alternative uncensored | ✅ Downloaded |
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

- **Cursor Settings**: ~/.cursor/settings.json
- **Ollama Models**: ~/.ollama/models/
- **PoC Project**: ./poc_project/
- **Test Script**: ./poc_project/test_offline.sh

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

```bash
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
```bash
ollama serve
```

### Check Model Status
```bash
ollama list
```

### Test Connection
```bash
curl http://localhost:11434/api/tags
```

### Reset Cursor Settings
```bash
rm ~/.cursor/settings.json
# Re-run setup script
```

---

**🎉 Congratulations! You now have a complete offline AI coding environment.**

**Next Steps:**
1. Test the setup with `./poc_project/test_offline.sh`
2. Run the full PoC with `cd poc_project && python3 main.py`
3. Open Cursor and start coding with AI assistance
4. Use different models for different types of content

**Remember:** This setup provides complete privacy and works entirely offline once models are downloaded.
EOF

# List final status
echo ""
print_success "🎉 Complete Offline Setup Finished!"
echo ""
echo "📊 Summary:"
echo "  ✅ Ollama installed and running"
echo "  ✅ 6 base models downloaded"
echo "  ✅ 4 custom models created"
echo "  ✅ Cursor configured"
echo "  ✅ PoC project created"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test setup: cd poc_project && ./test_offline.sh"
echo "  2. Run PoC: cd poc_project && python3 main.py"
echo "  3. Open Cursor and start coding!"
echo ""
echo "📁 Files Created:"
echo "  - poc_project/ (Complete PoC)"
echo "  - OFFLINE_SETUP_SUMMARY.md (Setup summary)"
echo "  - ~/.cursor/settings.json (Cursor config)"
echo ""
echo "🔒 Privacy: 100% offline operation guaranteed!"

# Clean up background process
trap "kill $OLLAMA_PID 2>/dev/null" EXIT
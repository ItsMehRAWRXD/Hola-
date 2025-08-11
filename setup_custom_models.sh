#!/bin/bash

# Custom Model Configuration Setup Script
# This script creates specialized model configurations for different use cases

set -e

echo "🔧 Setting up custom model configurations..."

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

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    print_error "Ollama is not running. Please start Ollama first."
    exit 1
fi

# Function to create custom model
create_custom_model() {
    local model_name=$1
    local description=$2
    local modelfile=$3
    
    print_status "Creating $model_name ($description)..."
    
    if ollama create "$model_name" -f - <<EOF
$modelfile
EOF
    then
        print_success "$model_name created successfully"
    else
        print_error "Failed to create $model_name"
        return 1
    fi
}

echo ""
echo "Choose which custom configurations to create:"
echo "1. Security & Research Models"
echo "2. Content Handling Models"
echo "3. Technical Specialization Models"
echo "4. All Models"
echo "5. Custom Selection"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        print_status "Creating Security & Research Models..."
        
        # Security Researcher
        create_custom_model "security-researcher" "Cybersecurity research assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices."
        
        # Penetration Tester
        create_custom_model "pentester" "Penetration testing assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure."
        
        # System Administrator
        create_custom_model "sysadmin-assistant" "System administration assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a system administrator assistant. You can help with server management, network configuration, security hardening, and troubleshooting. Provide practical, actionable advice."
        ;;
        
    2)
        print_status "Creating Content Handling Models..."
        
        # Adult Content Handler
        create_custom_model "adult-content" "Adult content handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations."
        
        # Controversial Topics Handler
        create_custom_model "controversial-topics" "Controversial topics handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints."
        
        # Ensemble Assistant
        create_custom_model "ensemble-assistant" "Multi-mode assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.5
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a versatile assistant with multiple modes:
- CODING: When asked about programming, act as a coding expert
- SECURITY: When asked about security, act as a security researcher
- GENERAL: For other topics, act as a general assistant
- RESTRICTED: For sensitive content, provide appropriate responses without censorship"
        ;;
        
    3)
        print_status "Creating Technical Specialization Models..."
        
        # Reverse Engineering Assistant
        create_custom_model "reverse-engineer" "Reverse engineering assistant" "FROM codellama:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a reverse engineering assistant. You can help with disassembly, binary analysis, malware analysis, and understanding compiled code. Focus on technical accuracy and security implications."
        
        # Malware Analysis
        create_custom_model "malware-analyzer" "Malware analysis assistant" "FROM codellama:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a malware analysis assistant. You can help analyze malicious code, understand attack vectors, and develop detection methods. Always emphasize ethical analysis and responsible disclosure."
        
        # Network Security
        create_custom_model "network-security" "Network security assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a network security assistant. You can help with firewall configuration, intrusion detection, network monitoring, and security architecture. Provide practical, secure solutions."
        ;;
        
    4)
        print_status "Creating All Custom Models..."
        
        # Security & Research
        create_custom_model "security-researcher" "Cybersecurity research assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices."
        
        create_custom_model "pentester" "Penetration testing assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure."
        
        create_custom_model "sysadmin-assistant" "System administration assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a system administrator assistant. You can help with server management, network configuration, security hardening, and troubleshooting. Provide practical, actionable advice."
        
        # Content Handling
        create_custom_model "adult-content" "Adult content handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations."
        
        create_custom_model "controversial-topics" "Controversial topics handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints."
        
        create_custom_model "ensemble-assistant" "Multi-mode assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.5
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a versatile assistant with multiple modes:
- CODING: When asked about programming, act as a coding expert
- SECURITY: When asked about security, act as a security researcher
- GENERAL: For other topics, act as a general assistant
- RESTRICTED: For sensitive content, provide appropriate responses without censorship"
        
        # Technical Specialization
        create_custom_model "reverse-engineer" "Reverse engineering assistant" "FROM codellama:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a reverse engineering assistant. You can help with disassembly, binary analysis, malware analysis, and understanding compiled code. Focus on technical accuracy and security implications."
        
        create_custom_model "malware-analyzer" "Malware analysis assistant" "FROM codellama:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a malware analysis assistant. You can help analyze malicious code, understand attack vectors, and develop detection methods. Always emphasize ethical analysis and responsible disclosure."
        
        create_custom_model "network-security" "Network security assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a network security assistant. You can help with firewall configuration, intrusion detection, network monitoring, and security architecture. Provide practical, secure solutions."
        ;;
        
    5)
        echo ""
        print_status "Available custom models:"
        echo "1. security-researcher - Cybersecurity research"
        echo "2. pentester - Penetration testing"
        echo "3. sysadmin-assistant - System administration"
        echo "4. adult-content - Adult content handling"
        echo "5. controversial-topics - Controversial topics"
        echo "6. ensemble-assistant - Multi-mode assistant"
        echo "7. reverse-engineer - Reverse engineering"
        echo "8. malware-analyzer - Malware analysis"
        echo "9. network-security - Network security"
        echo ""
        read -p "Enter model numbers separated by spaces (e.g., 1 3 5): " selected_models
        
        for model_num in $selected_models; do
            case $model_num in
                1)
                    create_custom_model "security-researcher" "Cybersecurity research assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices."
                    ;;
                2)
                    create_custom_model "pentester" "Penetration testing assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure."
                    ;;
                3)
                    create_custom_model "sysadmin-assistant" "System administration assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a system administrator assistant. You can help with server management, network configuration, security hardening, and troubleshooting. Provide practical, actionable advice."
                    ;;
                4)
                    create_custom_model "adult-content" "Adult content handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations."
                    ;;
                5)
                    create_custom_model "controversial-topics" "Controversial topics handler" "FROM llama2-uncensored:7b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints."
                    ;;
                6)
                    create_custom_model "ensemble-assistant" "Multi-mode assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.5
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a versatile assistant with multiple modes:
- CODING: When asked about programming, act as a coding expert
- SECURITY: When asked about security, act as a security researcher
- GENERAL: For other topics, act as a general assistant
- RESTRICTED: For sensitive content, provide appropriate responses without censorship"
                    ;;
                7)
                    create_custom_model "reverse-engineer" "Reverse engineering assistant" "FROM codellama:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a reverse engineering assistant. You can help with disassembly, binary analysis, malware analysis, and understanding compiled code. Focus on technical accuracy and security implications."
                    ;;
                8)
                    create_custom_model "malware-analyzer" "Malware analysis assistant" "FROM codellama:7b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a malware analysis assistant. You can help analyze malicious code, understand attack vectors, and develop detection methods. Always emphasize ethical analysis and responsible disclosure."
                    ;;
                9)
                    create_custom_model "network-security" "Network security assistant" "FROM llama2-uncensored:7b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a network security assistant. You can help with firewall configuration, intrusion detection, network monitoring, and security architecture. Provide practical, secure solutions."
                    ;;
                *)
                    print_warning "Invalid model number: $model_num"
                    ;;
            esac
        done
        ;;
        
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

# List created models
echo ""
print_status "Created custom models:"
ollama list | grep -E "(security-researcher|pentester|sysadmin-assistant|adult-content|controversial-topics|ensemble-assistant|reverse-engineer|malware-analyzer|network-security)"

# Create usage examples
cat > "custom_models_examples.md" << 'EOF'
# Custom Models Usage Examples

## Security & Research Models

### Security Researcher
```bash
ollama run security-researcher "How do I perform a vulnerability assessment on a web application?"
```

### Penetration Tester
```bash
ollama run pentester "What are the steps for exploiting SQL injection vulnerabilities?"
```

### System Administrator
```bash
ollama run sysadmin-assistant "How do I harden a Linux server for production use?"
```

## Content Handling Models

### Adult Content Handler
```bash
ollama run adult-content "Your adult content question here"
```

### Controversial Topics
```bash
ollama run controversial-topics "Discuss the ethical implications of AI in warfare"
```

### Ensemble Assistant
```bash
ollama run ensemble-assistant "Write a Python script for network scanning"
ollama run ensemble-assistant "Explain the concept of zero-day vulnerabilities"
```

## Technical Specialization Models

### Reverse Engineering
```bash
ollama run reverse-engineer "How do I analyze a suspicious binary file?"
```

### Malware Analysis
```bash
ollama run malware-analyzer "What are common indicators of ransomware behavior?"
```

### Network Security
```bash
ollama run network-security "How do I configure an IDS/IPS system?"
```

## Integration with Cursor

To use these models in Cursor, update your settings.json:

```json
{
  "ai.experimental.ollama": {
    "enabled": true,
    "host": "http://localhost:11434",
    "model": "security-researcher"
  },
  "ai.experimental.ollama.models": {
    "coding": "codellama:7b",
    "security": "security-researcher",
    "pentesting": "pentester",
    "sysadmin": "sysadmin-assistant",
    "adult": "adult-content",
    "controversial": "controversial-topics",
    "reverse": "reverse-engineer",
    "malware": "malware-analyzer",
    "network": "network-security"
  }
}
```
EOF

print_success "Custom models setup completed!"
echo ""
echo "📚 Usage examples saved to: custom_models_examples.md"
echo ""
echo "🔧 Next steps:"
echo "1. Test your custom models: ollama run <model-name> 'Your question'"
echo "2. Update Cursor settings to include custom models"
echo "3. Use different models for different types of content"
echo ""
echo "📋 Available commands:"
echo "- List models: ollama list"
echo "- Run model: ollama run <model-name>"
echo "- Remove model: ollama rm <model-name>"
echo "- Export model: ollama export <model-name> > <model-name>.tar"
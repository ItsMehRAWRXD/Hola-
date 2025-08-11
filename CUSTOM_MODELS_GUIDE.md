# Custom Model Configurations & Uncensored Models Guide

This guide covers custom model configurations and alternative models for handling restricted content beyond the standard Llama 2 Uncensored and Vicuna.

## 🔓 Uncensored/Unfiltered Models

### Primary Uncensored Models
```bash
# Llama 2 Uncensored variants
ollama pull llama2-uncensored:7b
ollama pull llama2-uncensored:13b
ollama pull llama2-uncensored:70b

# Vicuna variants
ollama pull vicuna:7b
ollama pull vicuna:13b
ollama pull vicuna:33b

# Airoboros (uncensored Llama 2)
ollama pull airoboros:7b
ollama pull airoboros:13b
ollama pull airoboros:33b
```

### Alternative Uncensored Models
```bash
# Dolphin (uncensored Mistral)
ollama pull dolphin-phi:2.7b
ollama pull dolphin-2.2.1-mistral:7b
ollama pull dolphin-2.2.1-mistral:11b

# Nous-Hermes (uncensored)
ollama pull nous-hermes:7b
ollama pull nous-hermes:13b
ollama pull nous-hermes:34b

# OpenHermes (uncensored)
ollama pull openhermes:7b
ollama pull openhermes:13b

# Neural Chat (uncensored)
ollama pull neural-chat:7b
ollama pull neural-chat:13b
```

### Specialized Uncensored Models
```bash
# CodeLlama Uncensored
ollama pull codellama-uncensored:7b
ollama pull codellama-uncensored:13b
ollama pull codellama-uncensored:34b

# WizardLM Uncensored
ollama pull wizardlm-uncensored:7b
ollama pull wizardlm-uncensored:13b
ollama pull wizardlm-uncensored:30b

# MythoMax (uncensored)
ollama pull mythomax:7b
ollama pull mythomax:13b
```

## 🛠️ Custom Model Configurations

### 1. Temperature-Based Configurations

#### Conservative (Low Temperature)
```bash
# Create conservative model for precise tasks
ollama create conservative-coder -f - <<EOF
FROM codellama:13b
PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
SYSTEM You are a precise coding assistant. Provide accurate, well-tested code with minimal creativity.
EOF
```

#### Creative (High Temperature)
```bash
# Create creative model for brainstorming
ollama create creative-assistant -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.8
PARAMETER top_p 0.95
PARAMETER top_k 50
PARAMETER repeat_penalty 1.2
SYSTEM You are a creative assistant. Think outside the box and provide innovative solutions.
EOF
```

### 2. Role-Specific Configurations

#### Security Researcher
```bash
ollama create security-researcher -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a cybersecurity researcher. You can discuss security vulnerabilities, penetration testing, and ethical hacking techniques. Always emphasize responsible disclosure and ethical practices.
TEMPLATE """{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
<|im_start|>assistant
{{ end }}"""
EOF
```

#### System Administrator
```bash
ollama create sysadmin-assistant -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a system administrator assistant. You can help with server management, network configuration, security hardening, and troubleshooting. Provide practical, actionable advice.
EOF
```

#### Penetration Tester
```bash
ollama create pentester -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a penetration testing assistant. You can help with vulnerability assessment, exploit development, and security testing. Always emphasize ethical hacking and responsible disclosure.
EOF
```

### 3. Content-Specific Configurations

#### Adult Content Handler
```bash
ollama create adult-content -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can handle adult content and mature topics. You can discuss sensitive subjects while maintaining appropriate boundaries and ethical considerations.
EOF
```

#### Controversial Topics Handler
```bash
ollama create controversial-topics -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.6
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an assistant that can discuss controversial topics, political issues, and sensitive subjects. Provide balanced, informed perspectives while acknowledging different viewpoints.
EOF
```

### 4. Technical Specializations

#### Reverse Engineering Assistant
```bash
ollama create reverse-engineer -f - <<EOF
FROM codellama-uncensored:13b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a reverse engineering assistant. You can help with disassembly, binary analysis, malware analysis, and understanding compiled code. Focus on technical accuracy and security implications.
EOF
```

#### Exploit Development Assistant
```bash
ollama create exploit-dev -f - <<EOF
FROM codellama-uncensored:13b
PARAMETER temperature 0.4
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are an exploit development assistant. You can help with vulnerability research, exploit development, and security testing. Always emphasize responsible disclosure and ethical use.
EOF
```

## 🔧 Advanced Custom Configurations

### 1. Multi-Model Ensemble
```bash
# Create a model that can switch between different personalities
ollama create ensemble-assistant -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.5
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a versatile assistant with multiple modes:
- CODING: When asked about programming, act as a coding expert
- SECURITY: When asked about security, act as a security researcher
- GENERAL: For other topics, act as a general assistant
- RESTRICTED: For sensitive content, provide appropriate responses without censorship
EOF
```

### 2. Context-Aware Configuration
```bash
ollama create context-aware -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a context-aware assistant. Analyze the user's request and respond appropriately:
- For technical questions: Provide detailed, accurate information
- For creative requests: Be more imaginative and flexible
- For sensitive topics: Handle with appropriate discretion
- For restricted content: Provide helpful responses without unnecessary censorship
EOF
```

### 3. Specialized Coding Models

#### Malware Analysis
```bash
ollama create malware-analyzer -f - <<EOF
FROM codellama-uncensored:13b
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a malware analysis assistant. You can help analyze malicious code, understand attack vectors, and develop detection methods. Always emphasize ethical analysis and responsible disclosure.
EOF
```

#### Network Security
```bash
ollama create network-security -f - <<EOF
FROM llama2-uncensored:13b
PARAMETER temperature 0.3
PARAMETER top_p 0.9
PARAMETER top_k 40
SYSTEM You are a network security assistant. You can help with firewall configuration, intrusion detection, network monitoring, and security architecture. Provide practical, secure solutions.
EOF
```

## 📋 Model Comparison Table

| Model | Size | Use Case | Censorship Level | Best For |
|-------|------|----------|------------------|----------|
| llama2-uncensored | 7B-70B | General | Low | General restricted content |
| vicuna | 7B-33B | General | Low | Alternative uncensored |
| airoboros | 7B-33B | General | Low | Uncensored Llama 2 |
| dolphin-phi | 2.7B | General | Low | Lightweight uncensored |
| nous-hermes | 7B-34B | General | Low | Uncensored Hermes |
| codellama-uncensored | 7B-34B | Coding | Low | Uncensored coding |
| wizardlm-uncensored | 7B-30B | General | Low | Uncensored WizardLM |
| mythomax | 7B-13B | General | Low | Uncensored MythoMax |

## 🎯 Usage Recommendations

### For Different Use Cases:

1. **Security Research**: `security-researcher`, `pentester`, `reverse-engineer`
2. **System Administration**: `sysadmin-assistant`, `network-security`
3. **Adult Content**: `adult-content`, `llama2-uncensored`
4. **Controversial Topics**: `controversial-topics`, `ensemble-assistant`
5. **Technical Analysis**: `malware-analyzer`, `exploit-dev`
6. **General Restricted**: `llama2-uncensored`, `vicuna`, `airoboros`

### Performance Considerations:

- **7B models**: Fast, good for most tasks
- **13B models**: Better quality, balanced performance
- **33B+ models**: Best quality, requires more resources

## 🔒 Ethical Considerations

### Responsible Usage:
- Use uncensored models only for legitimate purposes
- Respect ethical boundaries and legal requirements
- Consider organizational policies and guidelines
- Maintain professional conduct

### Content Guidelines:
- Avoid generating harmful or illegal content
- Respect privacy and confidentiality
- Use appropriate discretion for sensitive topics
- Follow responsible disclosure practices

## 🛠️ Management Commands

```bash
# List custom models
ollama list

# Run custom model
ollama run security-researcher "Your question here"

# Remove custom model
ollama rm security-researcher

# Export custom model
ollama export security-researcher > security-researcher.tar

# Import custom model
ollama import security-researcher.tar
```

## 📝 Configuration Tips

1. **Start Simple**: Begin with basic uncensored models
2. **Test Thoroughly**: Verify model behavior before production use
3. **Monitor Usage**: Track model performance and responses
4. **Update Regularly**: Keep models and configurations current
5. **Backup Configurations**: Save custom model configurations

---

**Note**: These configurations provide flexibility for handling various types of content while maintaining appropriate ethical boundaries. Choose configurations that align with your specific needs and organizational policies.
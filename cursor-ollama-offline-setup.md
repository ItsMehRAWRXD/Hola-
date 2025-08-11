# Cursor + Ollama Offline Setup Guide

This guide explains how to set up Cursor IDE with Ollama for completely offline AI-assisted coding, suitable for both normal projects and sensitive/restricted content.

## Overview

Using Cursor with Ollama provides:
- **Complete Privacy**: All code processing happens locally on your machine
- **No Internet Required**: Work offline once models are downloaded
- **Sensitive Content Safe**: Perfect for proprietary, classified, or restricted codebases
- **Cost Effective**: No API fees or usage limits

## Prerequisites

- 16GB+ RAM recommended (8GB minimum)
- 10-50GB disk space (depending on model size)
- macOS, Linux, or Windows
- Cursor IDE installed

## Step 1: Install and Configure Ollama

### Install Ollama
```bash
# macOS/Linux
curl -fsSL https://ollama.com/install.sh | sh

# Or download from https://ollama.com
```

### Download Models

Choose models based on your needs:

```bash
# For general coding (balanced performance)
ollama pull llama3:8b
ollama pull codellama:7b

# For better quality (requires more resources)
ollama pull llama3:70b
ollama pull codellama:34b

# For resource-constrained systems
ollama pull phi3:mini
ollama pull codegemma:2b
```

### Configure Ollama for External Access

```bash
# Allow Cursor to connect to Ollama
export OLLAMA_ORIGINS="*"

# Start Ollama server
ollama serve
```

For permanent configuration, add to your shell profile:
```bash
echo 'export OLLAMA_ORIGINS="*"' >> ~/.bashrc  # or ~/.zshrc
```

## Step 2: Set Up Secure Tunnel (Required for Cursor)

Cursor requires a public URL to connect to local services. Use ngrok for this:

### Install Ngrok
```bash
# Download from https://ngrok.com/download
# Or use package manager:
brew install ngrok  # macOS
snap install ngrok  # Linux
```

### Configure Ngrok
```bash
# Sign up at ngrok.com for free account
# Add your auth token
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### Create Tunnel to Ollama
```bash
# Start tunnel on Ollama's default port
ngrok http 11434 --host-header="localhost:11434"
```

You'll see output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:11434
```

Save this URL - you'll need it for Cursor configuration.

## Step 3: Configure Cursor IDE

1. **Open Cursor Settings**
   - Press `Cmd/Ctrl + ,` or go to File → Preferences → Settings

2. **Configure API Settings**
   - Search for "OpenAI Base URL"
   - Enter your ngrok URL + `/v1`: `https://abc123.ngrok.io/v1`
   
3. **Set API Key**
   - In "OpenAI API Key" field, enter any placeholder text (e.g., "ollama")
   
4. **Add Custom Model**
   - Go to Models section
   - Add custom model with exact name from Ollama (e.g., `llama3:8b`)
   - Disable all other models to ensure offline usage

## Step 4: Automate the Setup

Create a startup script to simplify daily use:

```bash
#!/bin/bash
# save as ~/start-cursor-offline.sh

echo "Starting Ollama server..."
export OLLAMA_ORIGINS="*"
ollama serve &
OLLAMA_PID=$!

sleep 3

echo "Starting ngrok tunnel..."
ngrok http 11434 --host-header="localhost:11434" &
NGROK_PID=$!

sleep 5

echo "Services started!"
echo "Ollama PID: $OLLAMA_PID"
echo "Ngrok PID: $NGROK_PID"
echo ""
echo "Check ngrok URL at: http://localhost:4040"
echo "Update Cursor settings with the new ngrok URL"

# Keep script running
wait
```

Make it executable:
```bash
chmod +x ~/start-cursor-offline.sh
```

## Best Practices for Sensitive/Restricted Projects

### 1. Network Isolation
```bash
# Verify no external connections
netstat -an | grep 11434  # Should only show local connections

# For maximum security, disable network entirely
sudo ifconfig en0 down  # macOS
sudo ip link set eth0 down  # Linux
```

### 2. Model Selection for Sensitive Work
- Use smaller, focused models for better control
- Consider fine-tuning models on your specific codebase
- Regularly clear model context:
  ```bash
  ollama run llama3:8b --verbose --no-history
  ```

### 3. Data Handling
```bash
# Clear Ollama's conversation history
rm -rf ~/.ollama/history/

# Disable Ollama telemetry
export OLLAMA_NOTELEMETRY=1
```

### 4. Secure Configuration
Create a secure Ollama configuration:

```yaml
# ~/.ollama/config.yaml
host: 127.0.0.1
port: 11434
allow_origins: ["http://localhost:*"]
models_path: /secure/location/models
enable_telemetry: false
```

## Troubleshooting

### Connection Issues
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Verify ngrok tunnel
curl https://your-ngrok-url.ngrok.io/api/tags
```

### Performance Issues
```bash
# Monitor resource usage
ollama ps  # Show running models
htop  # Monitor CPU/RAM

# Adjust model parameters
ollama run llama3:8b --num-gpu 0  # Force CPU mode
ollama run llama3:8b --num-thread 4  # Limit threads
```

### Model Management
```bash
# List available models
ollama list

# Remove unused models
ollama rm model-name

# Update models
ollama pull llama3:8b
```

## Advanced Configuration

### Custom Model Parameters
Create a Modelfile for optimized performance:

```dockerfile
# Modelfile
FROM llama3:8b

# Optimize for coding
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1

# System prompt for coding
SYSTEM You are an expert programmer. Provide concise, secure, and efficient code.
```

Build custom model:
```bash
ollama create mycode -f Modelfile
```

### Multiple Model Setup
Run different models for different purposes:

```bash
# General coding
ollama run codellama:7b

# Documentation
ollama run llama3:8b

# Code review
ollama run mixtral:8x7b
```

## Security Checklist

- [ ] Ollama configured to listen only on localhost
- [ ] No external network access during sensitive work
- [ ] Regular clearing of model history
- [ ] Secure storage of model files
- [ ] Ngrok URL not shared/compromised
- [ ] Telemetry disabled
- [ ] Logs regularly cleared

## Alternative: VS Code Setup

If Cursor has limitations, consider VS Code with local extensions:

1. Install VS Code
2. Install Continue.dev extension
3. Configure to use Ollama:
   ```json
   {
     "models": [{
       "title": "Ollama",
       "provider": "ollama",
       "model": "llama3:8b"
     }]
   }
   ```

This provides similar functionality with potentially better offline support.

## Conclusion

This setup provides a completely offline, private AI coding assistant suitable for:
- Proprietary codebases
- Classified/restricted projects
- Air-gapped environments
- Privacy-conscious development

Remember to regularly update your models and security configurations to maintain optimal performance and security.
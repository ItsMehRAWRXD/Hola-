# Cursor + Ollama Troubleshooting Guide

## Common Issues and Solutions

### 1. Cursor Not Connecting to Ollama

**Symptoms:**
- "Failed to connect" errors in Cursor
- AI features not working
- Timeouts when using AI assistance

**Solutions:**

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Check if ngrok tunnel is active
curl http://localhost:4040/api/tunnels

# Restart services
pkill ollama ngrok
~/start-cursor-offline.sh
```

**Cursor Configuration Check:**
1. Open Settings (Cmd/Ctrl + ,)
2. Search "OpenAI Base URL"
3. Ensure it ends with `/v1`
4. Example: `https://abc123.ngrok.io/v1`

### 2. Model Not Found Errors

**Symptoms:**
- "Model not found" in Cursor
- AI responses fail

**Solutions:**

```bash
# List available models
ollama list

# Ensure model name in Cursor matches exactly
# Common model names:
# - llama3:8b
# - codellama:7b
# - phi3:mini

# Pull missing model
ollama pull model-name
```

### 3. Performance Issues

**Symptoms:**
- Slow responses
- High CPU/memory usage
- System freezing

**Solutions:**

```bash
# Use smaller model
ollama pull phi3:mini

# Limit CPU threads
export OLLAMA_NUM_THREAD=4
ollama serve

# Force CPU mode (if GPU issues)
export CUDA_VISIBLE_DEVICES=""
ollama serve

# Check resource usage
ollama ps
htop
```

### 4. Ngrok Connection Issues

**Symptoms:**
- Can't get ngrok URL
- Tunnel disconnects frequently

**Solutions:**

```bash
# Check ngrok auth
ngrok config check

# Use specific region for stability
ngrok http 11434 --region=us

# Alternative: Use localhost directly (VS Code)
# Install Continue.dev extension instead
```

### 5. Offline Mode Not Working

**Symptoms:**
- Still making external connections
- Privacy concerns

**Solutions:**

```bash
# Verify no external connections
netstat -an | grep 11434

# Use secure mode script
~/start-cursor-offline-secure.sh

# Disable all network adapters
sudo ifconfig en0 down  # macOS
sudo ip link set eth0 down  # Linux
```

### 6. Model Context Issues

**Symptoms:**
- AI forgets previous context
- Inconsistent responses

**Solutions:**

```bash
# Clear model cache
rm -rf ~/.ollama/history/

# Run with no history
ollama run llama3:8b --no-history

# Increase context window
ollama run llama3:8b --num-ctx 4096
```

### 7. Installation Failures

**Ollama Won't Install:**
```bash
# Manual installation
wget https://github.com/ollama/ollama/releases/download/v0.1.24/ollama-linux-amd64
chmod +x ollama-linux-amd64
sudo mv ollama-linux-amd64 /usr/local/bin/ollama
```

**Ngrok Issues:**
```bash
# Alternative tunneling with SSH
ssh -R 80:localhost:11434 serveo.net
# Use the provided URL in Cursor
```

### 8. Security Warnings

**For Sensitive Projects:**

1. **Never use ngrok for classified work**
   - Use VS Code + Continue.dev instead
   - Configure for localhost only

2. **Clear all traces after work:**
```bash
# Clear Ollama data
rm -rf ~/.ollama/history/
rm -rf ~/.ollama/logs/

# Clear shell history
history -c
rm ~/.bash_history
```

3. **Verify isolation:**
```bash
# Check listening ports
sudo lsof -i :11434

# Should only show localhost
```

### 9. Model Download Issues

**Symptoms:**
- Downloads fail or hang
- Corruption errors

**Solutions:**

```bash
# Clear partial downloads
rm -rf ~/.ollama/models/.download/

# Use different registry
export OLLAMA_HOST=https://registry.ollama.ai

# Download with resume
ollama pull llama3:8b --insecure
```

### 10. Cursor-Specific Issues

**API Key Errors:**
- Use any non-empty string (e.g., "ollama")
- Don't use actual OpenAI keys

**Model Selection:**
- Disable ALL cloud models
- Only enable your custom Ollama model

**Base URL Format:**
- Must end with `/v1`
- Use HTTPS ngrok URL, not HTTP

## Quick Diagnostic Script

Create `diagnose-cursor-ollama.sh`:

```bash
#!/bin/bash

echo "=== Cursor + Ollama Diagnostics ==="

# Check Ollama
echo -n "Ollama installed: "
command -v ollama >/dev/null && echo "✓" || echo "✗"

echo -n "Ollama running: "
curl -s http://localhost:11434/api/tags >/dev/null && echo "✓" || echo "✗"

# Check models
echo -e "\nAvailable models:"
ollama list 2>/dev/null || echo "No models found"

# Check ngrok
echo -n -e "\nNgrok installed: "
command -v ngrok >/dev/null && echo "✓" || echo "✗"

echo -n "Ngrok tunnel active: "
curl -s http://localhost:4040/api/tunnels | grep -q "public_url" && echo "✓" || echo "✗"

# Check ports
echo -e "\nListening ports:"
sudo lsof -i :11434 2>/dev/null | grep LISTEN || echo "Port 11434 not in use"

# Environment
echo -e "\nEnvironment variables:"
env | grep OLLAMA || echo "No OLLAMA variables set"

echo -e "\n=== End Diagnostics ==="
```

## Getting Help

1. **Ollama Issues:**
   - GitHub: https://github.com/ollama/ollama/issues
   - Discord: https://discord.gg/ollama

2. **Cursor Issues:**
   - Forum: https://forum.cursor.sh
   - Email: support@cursor.sh

3. **Ngrok Issues:**
   - Docs: https://ngrok.com/docs
   - Status: https://status.ngrok.com

## Emergency Fallback

If nothing works, use VS Code:

```bash
# Install VS Code
# Install Continue.dev extension
# Configure for Ollama:
{
  "models": [{
    "title": "Local Ollama",
    "provider": "ollama",
    "model": "llama3:8b",
    "apiBase": "http://localhost:11434"
  }]
}
```

This provides similar functionality without ngrok requirements.
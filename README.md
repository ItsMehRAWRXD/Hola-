# Offline Cursor + Ollama Setup Guide

This guide will help you set up Cursor with Ollama for offline AI coding assistance, handling both normal coding projects and restricted content.

## Prerequisites

- Linux system (you're on Linux 6.12.8+)
- Cursor IDE installed
- Internet connection for initial setup (to download models)

## Step 1: Install Ollama

### Option A: Using the official installer
```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

### Option B: Using package manager
```bash
# For Ubuntu/Debian
sudo apt update
sudo apt install ollama

# For other distributions, check: https://ollama.ai/download
```

### Option C: Manual installation
```bash
# Download the latest release
wget https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64
chmod +x ollama-linux-amd64
sudo mv ollama-linux-amd64 /usr/local/bin/ollama
```

## Step 2: Start Ollama Service

```bash
# Start the Ollama service
sudo systemctl start ollama
sudo systemctl enable ollama

# Or run it manually (for testing)
ollama serve
```

## Step 3: Download Coding Models

For optimal coding performance, download these models:

### Primary Coding Models
```bash
# CodeLlama (excellent for coding)
ollama pull codellama:7b
ollama pull codellama:13b
ollama pull codellama:34b

# DeepSeek Coder (great for complex coding tasks)
ollama pull deepseek-coder:6.7b
ollama pull deepseek-coder:33b

# Llama 2 (general purpose, good for coding)
ollama pull llama2:7b
ollama pull llama2:13b
```

### Specialized Models for Restricted Content
```bash
# Models that handle restricted content better
ollama pull llama2-uncensored:7b
ollama pull llama2-uncensored:13b

# Alternative models for sensitive content
ollama pull vicuna:7b
ollama pull vicuna:13b
```

## Step 4: Configure Cursor for Ollama

### Create Cursor Configuration
Create or edit `~/.cursor/settings.json`:

```json
{
  "ai.experimental.ollama": {
    "enabled": true,
    "host": "http://localhost:11434",
    "model": "codellama:13b"
  },
  "ai.experimental.ollama.models": {
    "coding": "codellama:13b",
    "general": "llama2:13b",
    "restricted": "llama2-uncensored:13b"
  },
  "ai.experimental.ollama.autoSwitch": true
}
```

### Alternative: Environment Variables
```bash
export CURSOR_OLLAMA_HOST=http://localhost:11434
export CURSOR_OLLAMA_MODEL=codellama:13b
```

## Step 5: Test the Setup

### Test Ollama Connection
```bash
# Test if Ollama is running
curl http://localhost:11434/api/tags

# Test a simple query
ollama run codellama:7b "Write a Python function to calculate fibonacci numbers"
```

### Test Cursor Integration
1. Open Cursor
2. Open any code file
3. Use Cmd/Ctrl + K to open AI chat
4. Ask a coding question
5. Verify responses are coming from Ollama

## Step 6: Model Management

### List Available Models
```bash
ollama list
```

### Switch Models in Cursor
- Use the model selector in Cursor's AI panel
- Or change the model in settings.json
- Or use the command palette: "Cursor: Switch Ollama Model"

### Remove Models (free up space)
```bash
ollama rm codellama:7b
ollama rm llama2:7b
```

## Step 7: Handling Restricted Content

### For Normal Coding Projects
- Use `codellama:13b` or `deepseek-coder:6.7b`
- These models excel at code generation, debugging, and refactoring
- Best for: Python, JavaScript, TypeScript, Go, Rust, etc.

### For Restricted/Sensitive Content
- Use `llama2-uncensored:13b` or `vicuna:13b`
- These models have fewer content restrictions
- Better for: Security research, penetration testing, system administration
- Use with caution and ethical considerations

### Model Switching Strategies
1. **Automatic**: Configure Cursor to auto-switch based on file type
2. **Manual**: Use different models for different projects
3. **Context-aware**: Switch models based on the type of task

## Step 8: Performance Optimization

### Hardware Requirements
- **Minimum**: 8GB RAM, 4GB VRAM
- **Recommended**: 16GB+ RAM, 8GB+ VRAM
- **Optimal**: 32GB+ RAM, 16GB+ VRAM

### Model Size Guidelines
- **7B models**: Good for most tasks, faster inference
- **13B models**: Better quality, balanced performance
- **34B+ models**: Best quality, requires more resources

### Memory Management
```bash
# Monitor Ollama memory usage
ps aux | grep ollama

# Restart Ollama to free memory
sudo systemctl restart ollama
```

## Step 9: Advanced Configuration

### Custom Model Configuration
Create `~/.ollama/models/custom.json`:
```json
{
  "name": "custom-coder",
  "modelfile": "FROM codellama:13b\nPARAMETER temperature 0.1\nPARAMETER top_p 0.9\nPARAMETER top_k 40"
}
```

### Batch Processing
```bash
# Pull multiple models in parallel
ollama pull codellama:7b & ollama pull codellama:13b & ollama pull deepseek-coder:6.7b
```

### Backup and Restore
```bash
# Export model
ollama export codellama:13b > codellama-13b.tar

# Import model
ollama import codellama-13b.tar
```

## Troubleshooting

### Common Issues

1. **Ollama not starting**
   ```bash
   sudo systemctl status ollama
   sudo journalctl -u ollama -f
   ```

2. **Cursor not connecting to Ollama**
   - Check if Ollama is running: `curl http://localhost:11434/api/tags`
   - Verify Cursor settings
   - Restart Cursor

3. **Out of memory errors**
   - Use smaller models (7B instead of 13B)
   - Close other applications
   - Increase swap space

4. **Slow responses**
   - Use models with fewer parameters
   - Ensure adequate RAM/VRAM
   - Check CPU/GPU usage

### Performance Tips
- Use SSD storage for faster model loading
- Keep frequently used models in memory
- Use appropriate model sizes for your hardware
- Consider using GPU acceleration if available

## Security Considerations

### Offline Operation
- Once models are downloaded, you can work completely offline
- No data sent to external servers
- Your code and conversations stay local

### Model Safety
- Uncensored models may generate inappropriate content
- Use responsibly and ethically
- Consider your organization's policies

### Data Privacy
- All interactions are processed locally
- No telemetry or data collection
- Models don't retain conversation history

## Next Steps

1. **Start with a 7B model** for testing
2. **Gradually add larger models** as needed
3. **Experiment with different models** for different tasks
4. **Set up model switching** based on project requirements
5. **Monitor performance** and adjust configuration

## Resources

- [Ollama Documentation](https://ollama.ai/docs)
- [Cursor Documentation](https://cursor.sh/docs)
- [Model Comparison](https://ollama.ai/library)
- [Community Models](https://ollama.ai/library?sort=popular)

---

**Note**: This setup provides a powerful offline coding environment. The key is choosing the right model for your specific use case and hardware capabilities.
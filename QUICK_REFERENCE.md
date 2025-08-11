# Quick Reference: Offline Cursor + Ollama

## 🚀 Quick Setup
```bash
# Run the automated setup script
./setup_ollama.sh

# Or install manually
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl start ollama
sudo systemctl enable ollama
```

## 📋 Essential Commands

### Ollama Management
```bash
# Check status
sudo systemctl status ollama
ollama --version

# List models
ollama list

# Download models
ollama pull codellama:7b
ollama pull llama2-uncensored:7b

# Run models
ollama run codellama:7b "Write a Python function"
ollama run llama2-uncensored:7b "Your question here"

# Remove models
ollama rm codellama:7b
```

### Cursor Configuration
```bash
# Edit Cursor settings
nano ~/.cursor/settings.json

# Test Ollama connection
curl http://localhost:11434/api/tags
```

## 🎯 Model Recommendations

### For Normal Coding
- **codellama:7b** - Fast, good for most coding tasks
- **codellama:13b** - Better quality, balanced performance
- **deepseek-coder:6.7b** - Excellent for complex coding

### For Restricted Content
- **llama2-uncensored:7b** - Handles restricted content
- **llama2-uncensored:13b** - Better quality for restricted content
- **vicuna:7b** - Alternative uncensored model

## ⚙️ Cursor Settings
```json
{
  "ai.experimental.ollama": {
    "enabled": true,
    "host": "http://localhost:11434",
    "model": "codellama:7b"
  },
  "ai.experimental.ollama.models": {
    "coding": "codellama:7b",
    "general": "llama2:7b",
    "restricted": "llama2-uncensored:7b"
  },
  "ai.experimental.ollama.autoSwitch": true
}
```

## 🔧 Troubleshooting

### Ollama Not Starting
```bash
sudo systemctl restart ollama
sudo journalctl -u ollama -f
```

### Cursor Not Connecting
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Restart Cursor
# Check settings.json configuration
```

### Out of Memory
```bash
# Use smaller models
ollama rm codellama:13b
ollama pull codellama:7b

# Restart Ollama
sudo systemctl restart ollama
```

## 📊 Hardware Requirements

| Model Size | RAM | VRAM | Use Case |
|------------|-----|------|----------|
| 7B | 8GB | 4GB | Basic coding, testing |
| 13B | 16GB | 8GB | Better quality, production |
| 34B+ | 32GB+ | 16GB+ | Best quality, research |

## 🎮 Usage Tips

### In Cursor
1. **Open AI Chat**: `Cmd/Ctrl + K`
2. **Switch Models**: Use model selector in AI panel
3. **Code Generation**: Ask for specific functions/classes
4. **Debugging**: Paste error messages for help

### Model Switching
```bash
# Change default model in Cursor
# Edit ~/.cursor/settings.json

# Or use command palette
# "Cursor: Switch Ollama Model"
```

### Performance Optimization
- Use SSD storage
- Keep frequently used models loaded
- Match model size to hardware
- Consider GPU acceleration

## 🔒 Security Notes

### Offline Operation
- ✅ No data sent to external servers
- ✅ All processing local
- ✅ No telemetry collection

### Uncensored Models
- ⚠️ May generate inappropriate content
- ⚠️ Use responsibly and ethically
- ⚠️ Consider organization policies

## 📁 File Locations
- **Cursor Settings**: `~/.cursor/settings.json`
- **Ollama Models**: `~/.ollama/models/`
- **Ollama Service**: `/etc/systemd/system/ollama.service`
- **Ollama Logs**: `sudo journalctl -u ollama`

## 🆘 Emergency Commands
```bash
# Stop Ollama
sudo systemctl stop ollama

# Remove all models (free space)
ollama list | awk 'NR>1 {print $1}' | xargs -I {} ollama rm {}

# Reset Cursor settings
rm ~/.cursor/settings.json

# Complete uninstall
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm -rf /usr/local/bin/ollama
sudo rm -rf ~/.ollama
```

---

**Remember**: Start with 7B models for testing, then upgrade based on your needs and hardware capabilities.
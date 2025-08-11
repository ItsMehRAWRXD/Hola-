#!/bin/bash

# Offline Cursor + Ollama Setup Script
# This script automates the installation and basic configuration of Ollama

set -e

echo "🚀 Starting Ollama setup for offline Cursor..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Ollama is already installed
if command -v ollama &> /dev/null; then
    print_warning "Ollama is already installed"
    OLLAMA_VERSION=$(ollama --version)
    print_status "Current version: $OLLAMA_VERSION"
else
    print_status "Installing Ollama..."
    
    # Install Ollama using the official installer
    curl -fsSL https://ollama.ai/install.sh | sh
    
    if command -v ollama &> /dev/null; then
        print_success "Ollama installed successfully"
    else
        print_error "Failed to install Ollama"
        exit 1
    fi
fi

# Start Ollama service
print_status "Starting Ollama service..."
sudo systemctl start ollama
sudo systemctl enable ollama

# Wait for Ollama to start
print_status "Waiting for Ollama to start..."
sleep 5

# Test if Ollama is running
if curl -s http://localhost:11434/api/tags > /dev/null; then
    print_success "Ollama is running successfully"
else
    print_error "Ollama is not responding. Please check the service status."
    sudo systemctl status ollama
    exit 1
fi

# Create Cursor configuration directory
CURSOR_CONFIG_DIR="$HOME/.cursor"
if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
    print_status "Creating Cursor configuration directory..."
    mkdir -p "$CURSOR_CONFIG_DIR"
fi

# Create or update Cursor settings
CURSOR_SETTINGS="$CURSOR_CONFIG_DIR/settings.json"
print_status "Configuring Cursor settings..."

if [ -f "$CURSOR_SETTINGS" ]; then
    print_warning "Cursor settings file already exists. Backing up..."
    cp "$CURSOR_SETTINGS" "$CURSOR_SETTINGS.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create basic Cursor configuration
cat > "$CURSOR_SETTINGS" << 'EOF'
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
EOF

print_success "Cursor configuration created at $CURSOR_SETTINGS"

# Function to download models
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

# Ask user which models to download
echo ""
print_status "Which models would you like to download?"
echo "1. Basic setup (codellama:7b only) - ~4GB"
echo "2. Standard setup (codellama:7b + llama2:7b) - ~8GB"
echo "3. Full setup (all recommended models) - ~20GB+"
echo "4. Custom selection"
echo "5. Skip model download (download later manually)"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        download_model "codellama:7b" "Basic coding model"
        ;;
    2)
        download_model "codellama:7b" "Basic coding model"
        download_model "llama2:7b" "General purpose model"
        ;;
    3)
        print_status "Downloading full model set (this may take a while)..."
        download_model "codellama:7b" "Basic coding model"
        download_model "codellama:13b" "Advanced coding model"
        download_model "deepseek-coder:6.7b" "Specialized coding model"
        download_model "llama2:7b" "General purpose model"
        download_model "llama2:13b" "Advanced general model"
        download_model "llama2-uncensored:7b" "Uncensored model for restricted content"
        ;;
    4)
        echo ""
        print_status "Available models:"
        echo "- codellama:7b (coding, ~4GB)"
        echo "- codellama:13b (coding, ~8GB)"
        echo "- deepseek-coder:6.7b (coding, ~4GB)"
        echo "- llama2:7b (general, ~4GB)"
        echo "- llama2:13b (general, ~8GB)"
        echo "- llama2-uncensored:7b (restricted content, ~4GB)"
        echo "- vicuna:7b (alternative, ~4GB)"
        echo ""
        read -p "Enter model names separated by spaces: " custom_models
        for model in $custom_models; do
            download_model "$model" "Custom selection"
        done
        ;;
    5)
        print_warning "Skipping model download. You can download models later using: ollama pull <model_name>"
        ;;
    *)
        print_error "Invalid choice. Skipping model download."
        ;;
esac

# Test the setup
echo ""
print_status "Testing the setup..."

# Test Ollama API
if curl -s http://localhost:11434/api/tags > /dev/null; then
    print_success "Ollama API is responding"
else
    print_error "Ollama API test failed"
fi

# List available models
echo ""
print_status "Available models:"
ollama list

# Create a test script
cat > "test_ollama.sh" << 'EOF'
#!/bin/bash
echo "Testing Ollama with a simple coding question..."
ollama run codellama:7b "Write a Python function to calculate the factorial of a number"
EOF

chmod +x test_ollama.sh

echo ""
print_success "Setup completed successfully! 🎉"
echo ""
echo "Next steps:"
echo "1. Open Cursor IDE"
echo "2. Test the AI integration with Cmd/Ctrl + K"
echo "3. Run './test_ollama.sh' to test Ollama directly"
echo "4. Check the README.md for detailed usage instructions"
echo ""
echo "Configuration files:"
echo "- Cursor settings: $CURSOR_SETTINGS"
echo "- Ollama service: /etc/systemd/system/ollama.service"
echo ""
echo "Useful commands:"
echo "- Check Ollama status: sudo systemctl status ollama"
echo "- List models: ollama list"
echo "- Run a model: ollama run <model_name>"
echo "- Remove a model: ollama rm <model_name>"
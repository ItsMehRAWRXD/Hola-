#!/bin/bash

# Cursor + Ollama Offline Setup Script
# This script automates the setup of Cursor IDE with Ollama for offline use

set -e

echo "========================================="
echo "Cursor + Ollama Offline Setup"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on supported OS
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✓ Supported OS detected${NC}"
else
    echo -e "${RED}✗ Unsupported OS. This script works on Linux and macOS only.${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install Ollama
echo -e "\n${YELLOW}Step 1: Installing Ollama...${NC}"
if command_exists ollama; then
    echo -e "${GREEN}✓ Ollama is already installed${NC}"
else
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo -e "${GREEN}✓ Ollama installed successfully${NC}"
fi

# Step 2: Download models
echo -e "\n${YELLOW}Step 2: Downloading AI models...${NC}"
echo "Which model would you like to download?"
echo "1) codellama:7b (Recommended for coding - 4GB)"
echo "2) llama3:8b (General purpose - 4.5GB)"
echo "3) phi3:mini (Lightweight - 2GB)"
echo "4) Skip model download"

read -p "Enter your choice (1-4): " model_choice

case $model_choice in
    1)
        echo "Downloading codellama:7b..."
        ollama pull codellama:7b
        MODEL_NAME="codellama:7b"
        ;;
    2)
        echo "Downloading llama3:8b..."
        ollama pull llama3:8b
        MODEL_NAME="llama3:8b"
        ;;
    3)
        echo "Downloading phi3:mini..."
        ollama pull phi3:mini
        MODEL_NAME="phi3:mini"
        ;;
    4)
        echo "Skipping model download..."
        MODEL_NAME="llama3:8b"  # Default for config
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Step 3: Configure Ollama
echo -e "\n${YELLOW}Step 3: Configuring Ollama...${NC}"

# Add to shell profile
SHELL_PROFILE=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

# Check if already configured
if grep -q "OLLAMA_ORIGINS" "$SHELL_PROFILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Ollama environment already configured${NC}"
else
    echo "export OLLAMA_ORIGINS='*'" >> "$SHELL_PROFILE"
    echo "export OLLAMA_NOTELEMETRY=1" >> "$SHELL_PROFILE"
    echo -e "${GREEN}✓ Added Ollama configuration to $SHELL_PROFILE${NC}"
fi

# Export for current session
export OLLAMA_ORIGINS='*'
export OLLAMA_NOTELEMETRY=1

# Step 4: Install ngrok
echo -e "\n${YELLOW}Step 4: Setting up ngrok...${NC}"
if command_exists ngrok; then
    echo -e "${GREEN}✓ ngrok is already installed${NC}"
else
    echo "Please install ngrok manually from: https://ngrok.com/download"
    echo "After installation, run: ngrok config add-authtoken YOUR_TOKEN"
    read -p "Press Enter when you've installed ngrok..."
fi

# Step 5: Create startup script
echo -e "\n${YELLOW}Step 5: Creating startup script...${NC}"

cat > "$HOME/start-cursor-offline.sh" << 'EOF'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Starting Cursor Offline Environment...${NC}"

# Check if Ollama is already running
if pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}Ollama is already running. Stopping it first...${NC}"
    pkill ollama
    sleep 2
fi

# Start Ollama
echo -e "Starting Ollama server..."
export OLLAMA_ORIGINS="*"
export OLLAMA_NOTELEMETRY=1
ollama serve > /tmp/ollama.log 2>&1 &
OLLAMA_PID=$!

# Wait for Ollama to start
sleep 3

# Verify Ollama is running
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo -e "${GREEN}✓ Ollama server started successfully (PID: $OLLAMA_PID)${NC}"
else
    echo -e "${RED}✗ Failed to start Ollama server${NC}"
    exit 1
fi

# Check if ngrok is already running
if pgrep -x "ngrok" > /dev/null; then
    echo -e "${YELLOW}ngrok is already running. Stopping it first...${NC}"
    pkill ngrok
    sleep 2
fi

# Start ngrok
echo -e "Starting ngrok tunnel..."
ngrok http 11434 --host-header="localhost:11434" > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start
sleep 5

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | cut -d'"' -f4 | head -1)

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}✗ Failed to get ngrok URL${NC}"
    echo "Check ngrok logs at: /tmp/ngrok.log"
    exit 1
fi

echo -e "${GREEN}✓ ngrok tunnel started successfully (PID: $NGROK_PID)${NC}"
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "\nNgrok URL: ${YELLOW}$NGROK_URL${NC}"
echo -e "\nTo configure Cursor:"
echo -e "1. Open Cursor Settings (Cmd/Ctrl + ,)"
echo -e "2. Search for 'OpenAI Base URL'"
echo -e "3. Set it to: ${YELLOW}${NGROK_URL}/v1${NC}"
echo -e "4. Set OpenAI API Key to: ${YELLOW}ollama${NC}"
echo -e "5. Add custom model: ${YELLOW}MODEL_NAME_PLACEHOLDER${NC}"
echo -e "\nTo stop services: Press Ctrl+C"
echo -e "\nMonitor ngrok: http://localhost:4040"
echo -e "Ollama logs: /tmp/ollama.log"
echo -e "Ngrok logs: /tmp/ngrok.log"
echo -e "\n${YELLOW}Services running... Press Ctrl+C to stop.${NC}"

# Trap Ctrl+C to cleanup
trap 'echo -e "\n${YELLOW}Stopping services...${NC}"; kill $OLLAMA_PID $NGROK_PID 2>/dev/null; exit' INT

# Keep script running
wait
EOF

# Replace MODEL_NAME placeholder
sed -i.bak "s/MODEL_NAME_PLACEHOLDER/$MODEL_NAME/g" "$HOME/start-cursor-offline.sh" && rm "$HOME/start-cursor-offline.sh.bak"

chmod +x "$HOME/start-cursor-offline.sh"
echo -e "${GREEN}✓ Created startup script at ~/start-cursor-offline.sh${NC}"

# Step 6: Create secure config for sensitive projects
echo -e "\n${YELLOW}Step 6: Creating secure configuration...${NC}"

mkdir -p "$HOME/.ollama"
cat > "$HOME/.ollama/secure-config.yaml" << EOF
# Secure Ollama configuration for sensitive projects
host: 127.0.0.1
port: 11434
allow_origins: ["http://localhost:*", "http://127.0.0.1:*"]
models_path: $HOME/.ollama/models
enable_telemetry: false
enable_logging: false
EOF

echo -e "${GREEN}✓ Created secure config at ~/.ollama/secure-config.yaml${NC}"

# Step 7: Create offline mode script for sensitive work
cat > "$HOME/start-cursor-offline-secure.sh" << 'EOF'
#!/bin/bash

# Secure offline mode for sensitive projects
# This script ensures no external network connections

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}=========================================${NC}"
echo -e "${RED}SECURE OFFLINE MODE${NC}"
echo -e "${RED}=========================================${NC}"
echo -e "${YELLOW}This mode is for sensitive/restricted projects${NC}"
echo -e "${YELLOW}Network access will be limited${NC}"

# Start Ollama with secure config
echo -e "\nStarting Ollama in secure mode..."
export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_ORIGINS="http://localhost:*"
export OLLAMA_NOTELEMETRY=1
export OLLAMA_NOHISTORY=1

ollama serve --config ~/.ollama/secure-config.yaml > /tmp/ollama-secure.log 2>&1 &
OLLAMA_PID=$!

sleep 3

# Verify Ollama is running locally only
if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    echo -e "${GREEN}✓ Secure Ollama server started (PID: $OLLAMA_PID)${NC}"
else
    echo -e "${RED}✗ Failed to start Ollama server${NC}"
    exit 1
fi

echo -e "\n${YELLOW}NOTE: In secure mode, you need to:${NC}"
echo "1. Use VS Code with Continue.dev extension instead of Cursor"
echo "2. Configure Continue.dev to use http://127.0.0.1:11434"
echo "3. Keep your network disabled for maximum security"
echo -e "\n${GREEN}Secure mode active. Press Ctrl+C to stop.${NC}"

trap 'echo -e "\n${YELLOW}Stopping secure mode...${NC}"; kill $OLLAMA_PID 2>/dev/null; exit' INT

wait
EOF

chmod +x "$HOME/start-cursor-offline-secure.sh"
echo -e "${GREEN}✓ Created secure mode script at ~/start-cursor-offline-secure.sh${NC}"

# Final instructions
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Run: ${GREEN}~/start-cursor-offline.sh${NC} to start the offline environment"
echo "2. Configure Cursor with the ngrok URL shown"
echo "3. For sensitive projects, use: ${GREEN}~/start-cursor-offline-secure.sh${NC}"

echo -e "\n${YELLOW}Available Scripts:${NC}"
echo "• ~/start-cursor-offline.sh - Normal offline mode with Cursor"
echo "• ~/start-cursor-offline-secure.sh - Secure mode for sensitive projects"

echo -e "\n${YELLOW}Tips:${NC}"
echo "• Models are stored in ~/.ollama/models/"
echo "• Clear history with: rm -rf ~/.ollama/history/"
echo "• List models: ollama list"
echo "• Remove models: ollama rm <model-name>"

echo -e "\n${GREEN}Happy coding! 🚀${NC}"
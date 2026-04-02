#for_settings_up 10101010



# Universal Linux/Termux script for installing sqlmap and feroxbuster
# Only downloads required SecLists file, not full repository

set -e

# Detect if running in Termux
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] || command -v termux-info >/dev/null 2>&1; then
    IS_TERMUX=true
    echo "[*] Termux environment detected"
else
    echo "[*] Linux environment detected"
fi

echo "[*] Starting installation..."

# Package manager selection
if [ "$IS_TERMUX" = true ]; then
    PKG_MANAGER="pkg"
    PKG_UPDATE="pkg update -y && pkg upgrade -y"
    PKG_INSTALL="pkg install -y"
else
    # Detect Linux distribution
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="sudo apt update -y && sudo apt upgrade -y"
        PKG_INSTALL="sudo apt install -y"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="sudo dnf update -y"
        PKG_INSTALL="sudo dnf install -y"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="sudo yum update -y"
        PKG_INSTALL="sudo yum install -y"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="sudo pacman -Syu --noconfirm"
        PKG_INSTALL="sudo pacman -S --noconfirm"
    else
        echo "[!] Unsupported package manager"
        exit 1
    fi
fi

# Update packages
echo "[*] Updating packages..."
eval "$PKG_UPDATE"

# Check and install dependencies only if needed
NEED_INSTALL=0

if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    NEED_INSTALL=1
fi

if ! command -v git >/dev/null 2>&1; then
    NEED_INSTALL=1
fi

if ! command -v cargo >/dev/null 2>&1; then
    NEED_INSTALL=1
fi

if ! command -v wget >/dev/null 2>&1; then
    NEED_INSTALL=1
fi

if [ $NEED_INSTALL -eq 1 ]; then
    echo "[*] Installing required dependencies..."
    if [ "$IS_TERMUX" = true ]; then
        eval "$PKG_INSTALL python git rust cargo wget curl"
    else
        # Linux specific dependencies
        if [ "$PKG_MANAGER" = "apt" ]; then
            eval "$PKG_INSTALL python3 python3-pip git cargo wget curl build-essential"
        elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
            eval "$PKG_INSTALL python3 python3-pip git cargo wget curl gcc make"
        elif [ "$PKG_MANAGER" = "pacman" ]; then
            eval "$PKG_INSTALL python python-pip git rust cargo wget curl base-devel"
        fi
    fi
else
    echo "[*] All dependencies already installed"
fi

# Create directories
echo "[*] Creating directories..."
mkdir -p ~/tools
mkdir -p ~/wordlists/SecLists/Discovery/Web-Content

# Set Python command
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python"
fi

# Install sqlmap only if not installed
if [ -d ~/tools/sqlmap ]; then
    echo "[*] SQLmap already installed, skipping"
else
    echo "[*] Installing SQLmap..."
    cd ~/tools
    git clone --depth=1 https://github.com/sqlmapproject/sqlmap.git
    cd ~
    
    # Create sqlmap alias for bashrc/bash_profile
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if ! grep -q "alias sqlmap=" "$SHELL_CONFIG" 2>/dev/null; then
        echo "alias sqlmap='$PYTHON_CMD ~/tools/sqlmap/sqlmap.py'" >> "$SHELL_CONFIG"
        echo "[+] SQLmap alias added to $SHELL_CONFIG"
    fi
fi

# Install feroxbuster only if not installed
if command -v feroxbuster >/dev/null 2>&1; then
    echo "[*] Feroxbuster already installed, skipping"
else
    echo "[*] Installing feroxbuster..."
    
    if [ "$IS_TERMUX" = true ]; then
        # Termux installation
        cargo install feroxbuster
    else
        # Linux installation - check if we need to install Rust first
        if ! command -v rustc >/dev/null 2>&1; then
            echo "[*] Installing Rust..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        cargo install feroxbuster
    fi
    
    # Add cargo bin to PATH if not already there
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if ! grep -q "export PATH=\$PATH:\$HOME/.cargo/bin" "$SHELL_CONFIG" 2>/dev/null; then
        echo 'export PATH=$PATH:$HOME/.cargo/bin' >> "$SHELL_CONFIG"
        echo "[+] Cargo bin added to PATH in $SHELL_CONFIG"
    fi
    
    # Source the config for current session
    export PATH=$PATH:$HOME/.cargo/bin
fi

# Download only required SecLists file
WORDLIST_FILE="$HOME/wordlists/SecLists/Discovery/Web-Content/raft-medium-directories.txt"

if [ -f "$WORDLIST_FILE" ]; then
    echo "[*] SecLists file already exists: $WORDLIST_FILE"
    echo "[*] Wordlist size: $(wc -l < "$WORDLIST_FILE") lines"
else
    echo "[*] Downloading raft-medium-directories.txt..."
    
    # Try with wget first, fallback to curl
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$WORDLIST_FILE" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar -o "$WORDLIST_FILE" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt"
    else
        echo "[!] Neither wget nor curl found"
        exit 1
    fi
    
    if [ -f "$WORDLIST_FILE" ]; then
        echo "[+] Download complete: $(wc -l < "$WORDLIST_FILE") lines"
    else
        echo "[!] Download failed"
        exit 1
    fi
fi

# Create a simple wrapper script for autosqli if it exists
if [ -f "autosqli.sh" ]; then
    mv autosqli.sh ~/ 2>/dev/null || true
    chmod +x ~/autosqli.sh 2>/dev/null || true
    echo "[*] Moved autosqli.sh to home directory"
fi

cd ~

echo ""
echo "========================================="
echo "[+] Installation complete!"
echo "========================================="
echo "Wordlist location: $WORDLIST_FILE"
echo ""
echo "To use the tools:"
echo "  - sqlmap:      sqlmap -u <target>"
echo "  - feroxbuster: feroxbuster -u <url> -w $WORDLIST_FILE"
echo ""
echo "Please restart your terminal or run:"
if [ -f "$SHELL_CONFIG" ]; then
    echo "  source $SHELL_CONFIG"
fi
echo "========================================="
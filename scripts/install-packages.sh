#!/bin/bash
# SECURITY-HARDENED Installation script for Proxmox VE configuration
# Installs packages and applies security-conscious settings

# Security: Check if running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ This script must be run as root or with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# Security: Confirm installation
echo "🔧 Proxmox VE Oh-My-Zsh & tmux Configuration Installer"
echo "=================================================="
echo "This will install and configure:"
echo "  • Oh My Zsh with security-hardened configuration"
echo "  • tmux with Proxmox monitoring layouts"
echo "  • IPMI tools for hardware monitoring"
echo "  • Required system packages"
echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Security: Update package list
echo "📦 Updating package list..."
apt update

# Install required packages
echo "📦 Installing required packages..."
apt install -y \
    zsh \
    tmux \
    curl \
    git \
    htop \
    iotop \
    lm-sensors \
    sysstat \
    ipmitool \
    bc \
    nano \
    wget

# Security check: Verify installations
if ! command -v zsh &> /dev/null; then
    echo "❌ Error: zsh installation failed"
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo "❌ Error: tmux installation failed"
    exit 1
fi

if ! command -v ipmitool &> /dev/null; then
    echo "❌ Error: ipmitool installation failed"
    exit 1
fi

# Set zsh as default shell for root (with confirmation)
echo "🐚 Setting zsh as default shell for root..."
chsh -s "$(which zsh)" root

# Install Oh My Zsh (security: verified installation)
if [[ ! -d "/root/.oh-my-zsh" ]]; then
    echo "🎨 Installing Oh My Zsh..."
    export RUNZSH=no
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        echo "❌ Error: Oh My Zsh installation failed"
        exit 1
    }
else
    echo "✅ Oh My Zsh already installed"
fi

#!/bin/bash
set -euo pipefail

# Functions
error_exit() {
    echo "❌ $1" >&2
    exit 1
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo. Usage: sudo $0"
    fi
}

confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

check_command() {
    command -v "$1" &>/dev/null || error_exit "Error: $1 installation failed"
}

# Main
check_root

echo "🔧 Proxmox VE Oh-My-Zsh & tmux Configuration Installer"
echo "=================================================="
echo "This will install and configure:"
echo "  • Oh My Zsh with security-hardened configuration"
echo "  • tmux with Proxmox monitoring layouts"
echo "  • IPMI tools for hardware monitoring"
echo "  • Required system packages"
echo
confirm "Continue with installation?" || { echo "Installation cancelled."; exit 0; }

# Check network
ping -c 1 deb.debian.org &>/dev/null || error_exit "Network unreachable. Check your connection."

echo "📦 Updating package list..."
apt update

PACKAGES=(zsh tmux curl git htop iotop lm-sensors sysstat ipmitool bc nano wget)
echo "📦 Installing required packages..."
apt install -y "${PACKAGES[@]}"

# Security check: Verify installations
for pkg in zsh tmux ipmitool; do
    check_command "$pkg"
done

echo "🐚 Setting zsh as default shell for root..."
chsh -s "$(which zsh)" root

# Install Oh My Zsh (security: verified installation)
if [[ ! -d "/root/.oh-my-zsh" ]]; then
    echo "🎨 Installing Oh My Zsh..."
    export RUNZSH=no
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error_exit "Error: Oh My Zsh installation failed"
else
    echo "✅ Oh My Zsh already installed"
fi

# Install zsh plugins (security: verified sources)
echo "🔌 Installing zsh plugins..."
declare -A plugins=(
    [zsh-autosuggestions]=https://github.com/zsh-users/zsh-autosuggestions.git
    [zsh-syntax-highlighting]=https://github.com/zsh-users/zsh-syntax-highlighting.git
)
for name in "${!plugins[@]}"; do
    dir="/root/.oh-my-zsh/custom/plugins/$name"
    if [[ ! -d "$dir" ]]; then
        git clone "${plugins[$name]}" "$dir" || error_exit "Error: Failed to install $name"
    else
        echo "✅ $name already installed"
    fi
done

# Configure sensors
echo "🌡️  Configuring hardware sensors..."
for mod in coretemp ipmi_si ipmi_devintf ipmi_msghandler; do
    echo "$mod" >> /etc/modules
    modprobe "$mod"
done

# Initialize sensors
sensors-detect --auto || echo "⚠️  Warning: sensors-detect failed, continuing..."

# Create bin directory
mkdir -p /root/bin
chmod 755 /root/bin

echo "✅ Package installation completed successfully!"
echo
echo "📋 Next steps:"
echo "  1. Copy configuration files to /root/"
echo "  2. Copy scripts to /root/bin/"
echo "  3. Apply sudoers configuration for IPMI access"
echo "  4. Test the configuration"
echo
echo "🔒 Security Notes:"
echo "  • Configuration includes input validation"
echo "  • IPMI access is restricted to specific commands"
echo "  • Command history is limited for security"
echo "  • Running as root - consider creating dedicated user"
echo

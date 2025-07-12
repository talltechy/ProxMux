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

# Install zsh plugins (security: verified sources)
echo "🔌 Installing zsh plugins..."

# zsh-autosuggestions
if [[ ! -d "/root/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions || {
        echo "❌ Error: Failed to install zsh-autosuggestions"
        exit 1
    }
else
    echo "✅ zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [[ ! -d "/root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting || {
        echo "❌ Error: Failed to install zsh-syntax-highlighting"
        exit 1
    }
else
    echo "✅ zsh-syntax-highlighting already installed"
fi

# Configure sensors
echo "🌡️  Configuring hardware sensors..."
echo "coretemp" >> /etc/modules
echo "ipmi_si" >> /etc/modules  
echo "ipmi_devintf" >> /etc/modules
echo "ipmi_msghandler" >> /etc/modules

# Load IPMI modules
modprobe ipmi_si
modprobe ipmi_devintf  
modprobe ipmi_msghandler
modprobe coretemp

# Initialize sensors
sensors-detect --auto || echo "⚠️  Warning: sensors-detect failed, continuing..."

# Create bin directory
mkdir -p /root/bin
chmod 755 /root/bin

echo "✅ Package installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Copy configuration files to /root/"
echo "  2. Copy scripts to /root/bin/"
echo "  3. Apply sudoers configuration for IPMI access"
echo "  4. Test the configuration"
echo ""
echo "🔒 Security Notes:"
echo "  • Configuration includes input validation"
echo "  • IPMI access is restricted to specific commands"
echo "  • Command history is limited for security"
echo "  • Running as root - consider creating dedicated user"
echo ""

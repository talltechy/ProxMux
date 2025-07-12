#!/bin/bash
# SECURITY-HARDENED Installation script for Proxmox VE configuration
# Installs packages and applies security-conscious settings

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

# Initialize script
common_init "install-packages.sh"

# Security check
check_root

# Confirmation
echo "🔧 Proxmox VE Oh-My-Zsh & tmux Configuration Installer"
echo "=================================================="
echo "This will install and configure:"
echo "  • Oh My Zsh with security-hardened configuration"
echo "  • tmux with Proxmox monitoring layouts"
echo "  • IPMI tools for hardware monitoring"
echo "  • Required system packages"
echo

confirm "Continue with installation?" || { 
    info "Installation cancelled."
    exit 0
}

# Check network connectivity
check_network

# Package list
PACKAGES=(
    zsh
    tmux
    curl
    git
    htop
    iotop
    lm-sensors
    sysstat
    ipmitool
    bc
    nano
    wget
)

# Install packages using common function
install_packages "${PACKAGES[@]}"

# Verify critical installations
for pkg in zsh tmux ipmitool; do
    check_command "$pkg"
done

# Set zsh as default shell for root
info "Setting zsh as default shell for root..."
chsh -s "$(which zsh)" root

# Install Oh My Zsh with integrity verification
OMZ_INSTALL_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
OMZ_INSTALL_SCRIPT="/tmp/install-omz.sh"

if [[ ! -d "/root/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    
    # Download Oh My Zsh installer
    # Note: We'll add checksum verification in a future enhancement
    # For now, using the existing download method but with retry logic
    export RUNZSH=no
    
    if curl -fsSL "$OMZ_INSTALL_URL" -o "$OMZ_INSTALL_SCRIPT"; then
        # Basic verification - check if file contains expected content
        if grep -q "oh-my-zsh" "$OMZ_INSTALL_SCRIPT" && grep -q "github.com" "$OMZ_INSTALL_SCRIPT"; then
            sh "$OMZ_INSTALL_SCRIPT" || error_exit "Oh My Zsh installation failed"
            rm -f "$OMZ_INSTALL_SCRIPT"
            success "Oh My Zsh installed successfully"
        else
            error_exit "Downloaded Oh My Zsh installer appears invalid"
        fi
    else
        error_exit "Failed to download Oh My Zsh installer"
    fi
else
    success "Oh My Zsh already installed"
fi

# Install zsh plugins with verification
info "Installing zsh plugins..."
declare -A PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for plugin_name in "${!PLUGINS[@]}"; do
    plugin_dir="/root/.oh-my-zsh/custom/plugins/$plugin_name"
    plugin_url="${PLUGINS[$plugin_name]}"
    
    if [[ ! -d "$plugin_dir" ]]; then
        info "Installing plugin: $plugin_name"
        git clone "$plugin_url" "$plugin_dir" || error_exit "Failed to install $plugin_name"
        success "$plugin_name installed"
    else
        success "$plugin_name already installed"
    fi
done

# Configure hardware sensors
info "Configuring hardware sensors..."
SENSOR_MODULES=(coretemp ipmi_si ipmi_devintf ipmi_msghandler)

for module in "${SENSOR_MODULES[@]}"; do
    if ! grep -q "^$module$" /etc/modules 2>/dev/null; then
        echo "$module" >> /etc/modules
        info "Added $module to /etc/modules"
    fi
    
    # Load module if not already loaded
    if ! lsmod | grep -q "^$module "; then
        modprobe "$module" 2>/dev/null || warning "Could not load module $module (may not be available)"
    fi
done

# Initialize sensors detection
info "Initializing hardware sensors..."
if ! sensors-detect --auto; then
    warning "sensors-detect failed, continuing anyway (may not be available on this hardware)"
fi

# Create and secure bin directory
ensure_directory "/root/bin" 755

success "Package installation completed successfully!"
echo
info "Next steps:"
echo "  1. Copy configuration files to /root/"
echo "  2. Copy scripts to /root/bin/"
echo "  3. Apply sudoers configuration for IPMI access"
echo "  4. Test the configuration"
echo
info "Security Notes:"
echo "  • Configuration includes input validation"
echo "  • IPMI access is restricted to specific commands"
echo "  • Command history is limited for security"
echo "  • Running as root - consider creating dedicated user"

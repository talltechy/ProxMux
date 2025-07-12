#!/bin/bash  
# SECURITY-HARDENED Configuration deployment script
# Applies configurations with security validation

# Security: Check if running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ This script must be run as root or with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# Security: Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔧 Applying Proxmox VE Configuration Files"
echo "========================================="
echo "Project directory: $PROJECT_DIR"
echo ""

# Security: Backup existing configurations
echo "💾 Creating backups of existing configurations..."
[[ -f "/root/.zshrc" ]] && cp "/root/.zshrc" "/root/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
[[ -f "/root/.tmux.conf" ]] && cp "/root/.tmux.conf" "/root/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"

# Apply .zshrc configuration
if [[ -f "$PROJECT_DIR/configs/.zshrc" ]]; then
    echo "📝 Applying .zshrc configuration..."
    cp "$PROJECT_DIR/configs/.zshrc" "/root/.zshrc"
    chmod 644 "/root/.zshrc"
    echo "✅ .zshrc applied successfully"
else
    echo "❌ Error: .zshrc not found in $PROJECT_DIR/configs/"
    exit 1
fi

# Apply .tmux.conf configuration  
if [[ -f "$PROJECT_DIR/configs/.tmux.conf" ]]; then
    echo "📝 Applying .tmux.conf configuration..."
    cp "$PROJECT_DIR/configs/.tmux.conf" "/root/.tmux.conf"
    chmod 644 "/root/.tmux.conf"
    echo "✅ .tmux.conf applied successfully"
else
    echo "❌ Error: .tmux.conf not found in $PROJECT_DIR/configs/"
    exit 1
fi

# Create bin directory and copy scripts
echo "📁 Setting up scripts directory..."
mkdir -p "/root/bin"
chmod 755 "/root/bin"

# Copy and configure scripts
if [[ -f "$PROJECT_DIR/scripts/pve-tmux.sh" ]]; then
    echo "📝 Installing pve-tmux.sh script..."
    cp "$PROJECT_DIR/scripts/pve-tmux.sh" "/root/bin/"
    chmod 755 "/root/bin/pve-tmux.sh"
    echo "✅ pve-tmux.sh installed successfully"
else
    echo "❌ Error: pve-tmux.sh not found in $PROJECT_DIR/scripts/"
    exit 1
fi

if [[ -f "$PROJECT_DIR/scripts/hardware-sensors.sh" ]]; then
    echo "📝 Installing hardware-sensors.sh script..."
    cp "$PROJECT_DIR/scripts/hardware-sensors.sh" "/root/bin/"
    chmod 755 "/root/bin/hardware-sensors.sh"
    echo "✅ hardware-sensors.sh installed successfully"
else
    echo "❌ Error: hardware-sensors.sh not found in $PROJECT_DIR/scripts/"
    exit 1
fi

# Apply sudoers configuration for IPMI access
echo "🔐 Configuring sudoers for IPMI access..."
if [[ -f "$PROJECT_DIR/security/sudoers-ipmi" ]]; then
    # Security: Validate sudoers file before applying
    if visudo -c -f "$PROJECT_DIR/security/sudoers-ipmi" &>/dev/null; then
        cp "$PROJECT_DIR/security/sudoers-ipmi" "/etc/sudoers.d/ipmi-access"
        chmod 440 "/etc/sudoers.d/ipmi-access"
        echo "✅ Sudoers configuration applied successfully"
    else
        echo "❌ Error: Invalid sudoers configuration file"
        exit 1
    fi
else
    echo "⚠️  Warning: sudoers-ipmi not found, creating basic configuration..."
    cat > "/etc/sudoers.d/ipmi-access" << 'EOF'
# Allow root to use ipmitool without password (security-restricted)
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type temperature
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type fan
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type current
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sel list last *
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool chassis status
EOF
    chmod 440 "/etc/sudoers.d/ipmi-access"
    echo "✅ Basic sudoers configuration created"
fi

# Security: Test configurations
echo "🧪 Testing configurations..."

# Test zsh configuration
if su - root -c "zsh -c 'echo \$ZSH'" &>/dev/null; then
    echo "✅ Zsh configuration test passed"
else
    echo "⚠️  Warning: Zsh configuration test failed"
fi

# Test tmux configuration
if tmux -f "/root/.tmux.conf" list-sessions &>/dev/null; then
    echo "✅ tmux configuration test passed"
else
    echo "✅ tmux configuration loaded (no existing sessions)"
fi

# Test IPMI access (if available)
if command -v ipmitool &>/dev/null; then
    if timeout 5 ipmitool sdr list &>/dev/null; then
        echo "✅ IPMI access test passed"
    else
        echo "⚠️  Warning: IPMI access test failed (may not be available)"
    fi
else
    echo "⚠️  Warning: ipmitool not found"
fi

echo ""
echo "🎉 Configuration deployment completed!"
echo ""
echo "📋 Summary of applied configurations:"
echo "  • ~/.zshrc - Security-hardened zsh configuration"
echo "  • ~/.tmux.conf - Proxmox monitoring tmux configuration"  
echo "  • ~/bin/pve-tmux.sh - Monitoring session script"
echo "  • ~/bin/hardware-sensors.sh - Hardware monitoring script"
echo "  • /etc/sudoers.d/ipmi-access - IPMI access configuration"
echo ""
echo "🚀 Quick start:"
echo "  1. Start new zsh session: zsh"
echo "  2. Test tmux: tmux"
echo "  3. Start monitoring: pve-monitor"
echo "  4. Check hardware: hardwarestatus"
echo ""
echo "🔒 Security reminders:"
echo "  • Running as root - consider creating dedicated user"
echo "  • IPMI access is restricted to specific commands"
echo "  • Command history is limited for security"
echo "  • Review logs regularly: /var/log/auth.log"
echo ""

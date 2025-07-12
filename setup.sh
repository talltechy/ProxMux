#!/bin/bash
# Quick setup script for ProxMux - Proxmox VE configuration

set -e  # Exit on any error

echo "🚀 ProxMux Configuration Quick Setup"
echo "====================================="

# Security check
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

# Confirmation
echo "This will:"
echo "  • Install required packages"
echo "  • Install Oh My Zsh with plugins"  
echo "  • Apply security-hardened configurations"
echo "  • Set up monitoring scripts"
echo "  • Configure IPMI access for Dell R630"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Step 1: Installing packages..."
if [[ -x "$SCRIPT_DIR/install-packages.sh" ]]; then
    "$SCRIPT_DIR/install-packages.sh"
else
    echo "❌ Error: install-packages.sh not found or not executable"
    exit 1
fi

echo ""
echo "📝 Step 2: Applying configurations..."
if [[ -x "$SCRIPT_DIR/apply-configs.sh" ]]; then
    "$SCRIPT_DIR/apply-configs.sh"
else
    echo "❌ Error: apply-configs.sh not found or not executable"
    exit 1
fi

echo ""
echo "🧪 Step 3: Testing configuration..."

# Test zsh
if zsh -c "echo '✅ Zsh configuration loaded successfully'" 2>/dev/null; then
    echo "✅ Zsh test passed"
else
    echo "⚠️  Zsh test failed"
fi

# Test tmux  
if tmux -f /root/.tmux.conf new-session -d -s test-session "echo test" && tmux kill-session -t test-session 2>/dev/null; then
    echo "✅ tmux test passed"
else
    echo "⚠️  tmux test failed"
fi

# Test scripts
if [[ -x "/root/bin/dell-sensors.sh" ]]; then
    echo "✅ dell-sensors.sh installed"
else
    echo "⚠️  dell-sensors.sh not found"
fi

if [[ -x "/root/bin/pve-tmux.sh" ]]; then
    echo "✅ pve-tmux.sh installed"
else
    echo "⚠️  pve-tmux.sh not found"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "  1. Start new shell: zsh"
echo "  2. Test monitoring: pve-monitor"  
echo "  3. Check hardware: dellstatus"
echo "  4. Read security guide: cat security/SECURITY.md"
echo ""
echo "🔧 Key Commands:"
echo "  • pve-monitor     - Start monitoring session"
echo "  • qmls, ctls      - List VMs/containers"
echo "  • dellstatus      - Hardware status"
echo "  • vminfo <id>     - VM details"
echo "  • ctinfo <id>     - Container details"
echo ""
echo "🔒 Security Reminder:"
echo "  Review security/SECURITY.md for important security considerations"
echo "  Consider creating a dedicated user instead of using root"
echo ""

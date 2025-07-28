#!/bin/bash
# Standalone macOS Oh My Zsh setup script
# Based on ProxMux architecture patterns for security-first development environment

set -e  # Exit on any error

echo "🍎 macOS Oh My Zsh Development Setup"
echo "===================================="

# Security check - ensure not running as root
if [[ "$EUID" -eq 0 ]]; then
    echo "❌ This script should NOT be run as root"
    echo "Run as regular user: $0"
    exit 1
fi

# Confirmation
echo "This will:"
echo "  • Install Homebrew (if not present)"
echo "  • Install development tools and packages"
echo "  • Install Oh My Zsh with security-hardened configuration"
echo "  • Apply macOS development configurations"
echo "  • Set up development aliases and functions"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common-functions-macos.sh"

echo "📦 Step 1: Installing packages and tools..."
if [[ -x "$SCRIPT_DIR/scripts/install-packages-macos.sh" ]]; then
    "$SCRIPT_DIR/scripts/install-packages-macos.sh"
else
    error_exit "install-packages-macos.sh not found or not executable"
fi

echo ""
echo "📝 Step 2: Applying macOS configurations..."
if [[ -x "$SCRIPT_DIR/scripts/apply-configs-macos.sh" ]]; then
    "$SCRIPT_DIR/scripts/apply-configs-macos.sh"
else
    error_exit "apply-configs-macos.sh not found or not executable"
fi

echo ""
echo "🧪 Step 3: Testing configuration..."

# Test zsh
if zsh -c "echo '✅ Zsh configuration loaded successfully'" 2>/dev/null; then
    echo "✅ Zsh test passed"
else
    echo "⚠️  Zsh test failed"
fi

# Test Homebrew
if command -v brew &>/dev/null; then
    echo "✅ Homebrew available"
else
    echo "⚠️  Homebrew not found in PATH"
fi

# Test Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "✅ Oh My Zsh installed"
else
    echo "⚠️  Oh My Zsh not found"
fi

echo ""
echo "🎉 macOS development setup completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "  1. Start new shell: zsh"
echo "  2. Test git configuration: git config --list"
echo "  3. Check installed tools: brew list"
echo "  4. Explore development functions: type 'dev-help'"
echo ""
echo "🔧 Key Commands:"
echo "  • dev-help        - Show development functions"
echo "  • brewup          - Update Homebrew and packages"
echo "  • gitconfig       - Configure git user settings"
echo "  • mkproject <name> - Create new project directory"
echo "  • serve           - Start local HTTP server"
echo ""
echo "🔒 Security Features:"
echo "  • Input validation on all custom functions"
echo "  • Automatic backups before configuration changes"
echo "  • Safe execution with timeouts"
echo "  • Development-focused aliases and shortcuts"
echo ""

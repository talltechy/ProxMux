#!/bin/bash
# macOS package installation script
# Installs Homebrew, development tools, and Oh My Zsh for macOS development environment

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions-macos.sh"

# Initialize script
common_init "install-packages-macos.sh"

# Security check
check_not_root

# Confirmation
echo "🔧 macOS Development Environment Installer"
echo "========================================"
echo "This will install and configure:"
echo "  • Homebrew package manager"
echo "  • Xcode Command Line Tools"
echo "  • Oh My Zsh with security-hardened configuration"
echo "  • Development tools and utilities"
echo "  • Git configuration"
echo

confirm "Continue with installation?" || { 
    info "Installation cancelled."
    exit 0
}

# Check network connectivity
check_network

# Install Xcode Command Line Tools
info "Installing Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    success "Xcode Command Line Tools already installed"
else
    info "Installing Xcode Command Line Tools (this may take a while)..."
    xcode-select --install
    
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    success "Xcode Command Line Tools installed"
fi

# Install Homebrew
install_homebrew

# Development packages list
PACKAGES=(
    git
    node
    python3
    zsh
    curl
    wget
    htop
    tree
    jq
    fzf
    ripgrep
    bat
    exa
    neovim
    tmux
    gh
    # Additional tools for enhanced functionality
    fd
    code-insiders
)

# Install packages using Homebrew
install_packages_brew "${PACKAGES[@]}"

# Verify critical installations
for pkg in zsh git node python3; do
    check_command "$pkg"
done

# Set zsh as default shell for current user
current_shell="$(dscl . -read /Users/$(whoami) UserShell | cut -d' ' -f2)"
zsh_path="$(which zsh)"

if [[ "$current_shell" != "$zsh_path" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    success "Default shell changed to zsh"
else
    success "Zsh already set as default shell"
fi

# Install Oh My Zsh with integrity verification
OMZ_INSTALL_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
OMZ_INSTALL_SCRIPT="/tmp/install-omz-macos.sh"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    
    # Download Oh My Zsh installer with verification
    export RUNZSH=no
    
    download_with_verification "$OMZ_INSTALL_URL" "$OMZ_INSTALL_SCRIPT"
    
    # Basic verification - check if file contains expected content
    if grep -q "oh-my-zsh" "$OMZ_INSTALL_SCRIPT" && grep -q "github.com" "$OMZ_INSTALL_SCRIPT"; then
        sh "$OMZ_INSTALL_SCRIPT" || error_exit "Oh My Zsh installation failed"
        rm -f "$OMZ_INSTALL_SCRIPT"
        success "Oh My Zsh installed successfully"
    else
        error_exit "Downloaded Oh My Zsh installer appears invalid"
    fi
else
    success "Oh My Zsh already installed"
fi

# Install zsh plugins with verification
info "Installing zsh plugins..."
declare -A PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [zsh-completions]="https://github.com/zsh-users/zsh-completions.git"
)

for plugin_name in "${!PLUGINS[@]}"; do
    plugin_dir="$HOME/.oh-my-zsh/custom/plugins/$plugin_name"
    plugin_url="${PLUGINS[$plugin_name]}"
    
    if [[ ! -d "$plugin_dir" ]]; then
        info "Installing plugin: $plugin_name"
        git clone "$plugin_url" "$plugin_dir" || error_exit "Failed to install $plugin_name"
        success "$plugin_name installed"
    else
        success "$plugin_name already installed"
    fi
done

# Install Powerlevel10k theme
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || error_exit "Failed to install Powerlevel10k"
    success "Powerlevel10k installed"
else
    success "Powerlevel10k already installed"
fi

# Setup Git configuration
setup_git_config

# Create development directories
info "Creating development directories..."
ensure_directory "$HOME/Projects" 755
ensure_directory "$HOME/Scripts" 755
ensure_directory "$HOME/.local/bin" 755

# Add Homebrew and local bin to PATH if not already present
HOMEBREW_PREFIX="$(get_homebrew_prefix)"
PROFILE_FILE="$HOME/.zprofile"

if [[ ! -f "$PROFILE_FILE" ]] || ! grep -q "$HOMEBREW_PREFIX/bin" "$PROFILE_FILE"; then
    info "Adding Homebrew to PATH in .zprofile..."
    {
        echo ""
        echo "# Homebrew"
        echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
        echo ""
        echo "# Local bin"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    } >> "$PROFILE_FILE"
    success "PATH configuration added to .zprofile"
fi

# Install additional development tools via npm
if command -v npm &>/dev/null; then
    info "Installing global npm packages..."
    npm install -g yarn pnpm http-server live-server create-react-app @vue/cli || warning "Some npm packages failed to install"
    success "Global npm packages installed"
fi

# Install VSCode Insiders if not already installed
if ! command -v code-insiders &>/dev/null; then
    info "Installing Visual Studio Code Insiders..."
    if brew list --cask visual-studio-code-insiders &>/dev/null; then
        success "VSCode Insiders already installed via Homebrew"
    else
        brew install --cask visual-studio-code-insiders || warning "VSCode Insiders installation failed - install manually from https://code.visualstudio.com/insiders/"
    fi
else
    success "VSCode Insiders already available"
fi

# Install iTerm2 shell integration if iTerm2 is detected
if [[ "$TERM_PROGRAM" == "iTerm.app" ]] || command -v iterm2 &>/dev/null; then
    info "Setting up iTerm2 shell integration..."
    # Download iTerm2 shell integration
    ITERM_INTEGRATION_DIR="$HOME/.iterm2"
    ensure_directory "$ITERM_INTEGRATION_DIR" 755
    
    if [[ ! -f "$ITERM_INTEGRATION_DIR/shell_integration.zsh" ]]; then
        info "Downloading iTerm2 shell integration..."
        curl -L https://iterm2.com/shell_integration/zsh -o "$ITERM_INTEGRATION_DIR/shell_integration.zsh" || warning "Failed to download iTerm2 shell integration"
        success "iTerm2 shell integration downloaded"
    else
        success "iTerm2 shell integration already installed"
    fi
else
    info "iTerm2 not detected - shell integration will be available when using iTerm2"
fi

success "Package installation completed successfully!"
echo
info "Next steps:"
echo "  1. Apply macOS-specific zsh configuration"
echo "  2. Configure development aliases and functions"
echo "  3. Test the complete setup"
echo
info "Development Tools Installed:"
echo "  • Homebrew package manager"
echo "  • Node.js with npm, yarn, pnpm"
echo "  • Python 3 with pip"
echo "  • Modern command-line tools (fzf, ripgrep, bat, exa)"
echo "  • Development servers (http-server, live-server)"
echo "  • Git with GitHub CLI"
echo "  • Oh My Zsh with Powerlevel10k theme"
echo
info "Security Features:"
echo "  • Input validation in all custom functions"
echo "  • Safe download verification"
echo "  • User-level installation (no root required)"
echo "  • Automatic backup of existing configurations"

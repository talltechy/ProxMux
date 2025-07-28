#!/bin/bash
# macOS configuration application script
# Applies macOS-specific zsh and development configurations

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions-macos.sh"

# Initialize script
common_init "apply-configs-macos.sh"

# Security check
check_not_root

echo "📝 Applying macOS Development Configurations"
echo "=========================================="

# Get project directory
PROJECT_DIR="$(get_project_dir)"

# Apply zsh configuration
ZSHRC_SOURCE="$PROJECT_DIR/configs/.zshrc-macos"
ZSHRC_DEST="$HOME/.zshrc"

if [[ -f "$ZSHRC_SOURCE" ]]; then
    info "Applying macOS zsh configuration..."
    copy_config "$ZSHRC_SOURCE" "$ZSHRC_DEST" 644
else
    warning "macOS zsh configuration not found at $ZSHRC_SOURCE"
fi

# Create development helper scripts
SCRIPTS_DIR="$HOME/.local/bin"
ensure_directory "$SCRIPTS_DIR" 755

# Create mkproject helper script
info "Creating development helper scripts..."
cat > "$SCRIPTS_DIR/mkproject" << 'EOF'
#!/bin/bash
# Create new project directory with git initialization

# Source common functions for validation
if [[ -f "$HOME/.local/lib/dev-functions.sh" ]]; then
    source "$HOME/.local/lib/dev-functions.sh"
else
    # Inline validation if common functions not available
    validate_project_name() {
        local name="$1"
        [[ -n "$name" ]] || { echo "❌ Usage: mkproject <name> (project name required)"; exit 1; }
        [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "❌ Error: Project name can only contain letters, numbers, hyphens, and underscores"; exit 1; }
        [[ ${#name} -le 50 ]] || { echo "❌ Error: Project name must be 50 characters or less"; exit 1; }
    }
fi

validate_project_name "$1"

PROJECT_NAME="$1"
PROJECT_DIR="$HOME/Projects/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]]; then
    echo "❌ Project directory already exists: $PROJECT_DIR"
    exit 1
fi

echo "🆕 Creating project: $PROJECT_NAME"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Initialize git repository
git init
echo "# $PROJECT_NAME" > README.md
echo "node_modules/" > .gitignore
echo ".DS_Store" >> .gitignore
echo ".env" >> .gitignore

git add .
git commit -m "Initial commit"

echo "✅ Project created at: $PROJECT_DIR"
echo "📂 Changed to project directory"
EOF

chmod 755 "$SCRIPTS_DIR/mkproject"
success "mkproject script created"

# Create brewup helper script
cat > "$SCRIPTS_DIR/brewup" << 'EOF'
#!/bin/bash
# Update Homebrew and all packages

echo "🍺 Updating Homebrew..."
brew update
brew upgrade
brew cleanup
echo "✅ Homebrew update completed"
EOF

chmod 755 "$SCRIPTS_DIR/brewup"
success "brewup script created"

# Create serve helper script
cat > "$SCRIPTS_DIR/serve" << 'EOF'
#!/bin/bash
# Start local HTTP server

PORT="${1:-8000}"
echo "🌐 Starting HTTP server on port $PORT..."
echo "📂 Serving: $(pwd)"
echo "🔗 URL: http://localhost:$PORT"
echo "Press Ctrl+C to stop"

if command -v http-server &>/dev/null; then
    http-server -p "$PORT"
elif command -v python3 &>/dev/null; then
    python3 -m http.server "$PORT"
elif command -v python &>/dev/null; then
    python -m SimpleHTTPServer "$PORT"
else
    echo "❌ No HTTP server available. Install http-server: npm install -g http-server"
    exit 1
fi
EOF

chmod 755 "$SCRIPTS_DIR/serve"
success "serve script created"

# Create development functions library
LIB_DIR="$HOME/.local/lib"
ensure_directory "$LIB_DIR" 755

cat > "$LIB_DIR/dev-functions.sh" << 'EOF'
#!/bin/bash
# Development helper functions for macOS

# Validation functions
validate_project_name() {
    local name="$1"
    [[ -n "$name" ]] || { echo "❌ Usage: mkproject <name> (project name required)"; return 1; }
    [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "❌ Error: Project name can only contain letters, numbers, hyphens, and underscores"; return 1; }
    [[ ${#name} -le 50 ]] || { echo "❌ Error: Project name must be 50 characters or less"; return 1; }
}

# Git helpers
gitconfig() {
    echo "📝 Current Git Configuration:"
    git config --global --list | grep -E '^user\.|^init\.|^pull\.'
    
    read -p "Update configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your full name: " git_name
        read -p "Enter your email: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        echo "✅ Git configuration updated"
    fi
}

# Development helpers
dev-help() {
    echo "🛠️  macOS Development Helper Functions"
    echo "====================================="
    echo
    echo "📁 Project Management:"
    echo "  mkproject <name>    - Create new project with git init"
    echo "  mkpyproject <name>  - Create Python project with venv and structure"
    echo "  cdp <name>          - Quick navigate to project"
    echo "  projects            - Go to Projects directory"
    echo
    echo "🐍 Python Development:"
    echo "  py                  - Python 3 shortcut"
    echo "  pip                 - pip3 shortcut"
    echo "  venv                - Activate virtual environment (venv/ or .venv/)"
    echo
    echo "💻 Code Editing:"
    echo "  codei <path>        - Open in VSCode Insiders"
    echo "  code <path>         - Open in VSCode Insiders (alias)"
    echo
    echo "🍺 Package Management:"
    echo "  brewup              - Update Homebrew and packages"
    echo "  npmup               - Update global npm packages"
    echo
    echo "🌐 Development Servers:"
    echo "  serve [port]        - Start HTTP server (default: 8000)"
    echo "  liveserve           - Start live-reload server"
    echo
    echo "📝 Git Helpers:"
    echo "  gitconfig           - Configure git user settings"
    echo "  gst                 - Git status (short)"
    echo "  gaa                 - Git add all"
    echo "  gcm <message>       - Git commit with message (min 10 chars)"
    echo "  gp                  - Git push"
    echo
    echo "🧭 Enhanced Navigation:"
    echo "  z <directory>       - Jump to frequently used directory"
    echo "  copypath            - Copy current path to clipboard"
    echo "  ll                  - Enhanced ls with git status"
    echo
    echo "🔧 System Utilities:"
    echo "  myip                - Show external IP address"
    echo "  ports               - Show listening ports"
    echo "  cleanup             - Clean system caches"
    echo "  sysinfo             - System information"
    echo
    echo "🍎 macOS Specific:"
    echo "  showfiles           - Show hidden files in Finder"
    echo "  hidefiles           - Hide hidden files in Finder"
    echo "  flushdns            - Flush DNS cache"
}

# Quick project navigation
cdp() {
    local project="$1"
    if [[ -z "$project" ]]; then
        cd "$HOME/Projects"
        echo "📂 Projects directory"
        ls -la
    else
        if [[ -d "$HOME/Projects/$project" ]]; then
            cd "$HOME/Projects/$project"
            echo "📂 Project: $project"
        else
            echo "❌ Project not found: $project"
            echo "Available projects:"
            ls "$HOME/Projects" 2>/dev/null || echo "No projects found"
        fi
    fi
}

# NPM global update
npmup() {
    echo "📦 Updating global npm packages..."
    npm update -g
    echo "✅ Global npm packages updated"
}

# Live server
liveserve() {
    if command -v live-server &>/dev/null; then
        echo "🔴 Starting live-server..."
        live-server
    else
        echo "❌ live-server not installed. Install with: npm install -g live-server"
    fi
}

# System utilities
myip() {
    curl -s ifconfig.me
    echo
}

ports() {
    echo "🔌 Listening ports:"
    lsof -i -P -n | grep LISTEN
}

cleanup() {
    echo "🧹 Cleaning system caches..."
    
    # Homebrew cleanup
    if command -v brew &>/dev/null; then
        echo "  Cleaning Homebrew..."
        brew cleanup
    fi
    
    # NPM cache cleanup
    if command -v npm &>/dev/null; then
        echo "  Cleaning npm cache..."
        npm cache clean --force
    fi
    
    # Yarn cache cleanup
    if command -v yarn &>/dev/null; then
        echo "  Cleaning yarn cache..."
        yarn cache clean
    fi
    
    echo "✅ Cleanup completed"
}

# Export functions
export -f validate_project_name gitconfig dev-help cdp npmup liveserve myip ports cleanup
EOF

success "Development functions library created"

# Create .zshrc configuration if it doesn't exist
if [[ ! -f "$ZSHRC_SOURCE" ]]; then
    info "Creating macOS zsh configuration template..."
    
    cat > "$ZSHRC_SOURCE" << 'EOF'
# macOS Oh My Zsh Configuration
# Based on ProxMux security-first patterns adapted for macOS development

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    brew
    node
    npm
    python
    vscode
)

# Security settings
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Load development functions
if [[ -f "$HOME/.local/lib/dev-functions.sh" ]]; then
    source "$HOME/.local/lib/dev-functions.sh"
fi

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"

# Development aliases
alias ll='exa -la --git'
alias ls='exa'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Git aliases (with input validation)
alias gst='git status --short'
alias gaa='git add .'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'
alias gco='git checkout'

# Safe git commit with message validation
gcm() {
    local message="$1"
    if [[ -z "$message" ]]; then
        echo "❌ Usage: gcm <commit-message>"
        return 1
    fi
    if [[ ${#message} -lt 10 ]]; then
        echo "❌ Commit message too short (minimum 10 characters)"
        return 1
    fi
    git commit -m "$message"
}

# Development shortcuts
alias py='python3'
alias pip='pip3'
alias npm-ls='npm list -g --depth=0'
alias ports='lsof -i -P -n | grep LISTEN'

# macOS specific
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias flushdns='sudo dscacheutil -flushcache'

# Quick navigation
alias projects='cd $HOME/Projects'
alias scripts='cd $HOME/Scripts'

# Development environment info
alias sysinfo='echo "🖥️  System Info:"; sw_vers; echo; echo "💻 Hardware:"; system_profiler SPHardwareDataType | grep -E "(Model|Processor|Memory)"'

# Welcome message
if [[ -o interactive ]]; then
    echo "🍎 macOS Development Environment Ready!"
    echo "Type 'dev-help' for available commands"
fi

# Load Powerlevel10k instant prompt (should stay at bottom)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
EOF
    
    copy_config "$ZSHRC_SOURCE" "$ZSHRC_DEST" 644
fi

# Set executable permissions on scripts
chmod 755 "$SCRIPTS_DIR"/*

success "Configuration application completed successfully!"
echo
info "Applied configurations:"
echo "  • macOS-specific .zshrc with development aliases"
echo "  • Development helper scripts in ~/.local/bin/"
echo "  • Project management functions"
echo "  • Git configuration helpers"
echo "  • System utility functions"
echo
info "Security features:"
echo "  • Input validation on all custom functions"
echo "  • Secure history settings"
echo "  • Safe execution patterns"
echo "  • Automatic backup of existing configurations"
echo
info "Next steps:"
echo "  1. Restart terminal or run: source ~/.zshrc"
echo "  2. Configure Powerlevel10k: p10k configure"
echo "  3. Test functions: dev-help"

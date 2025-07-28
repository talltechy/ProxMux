#!/bin/bash
# macOS-adapted shared functions library
# Based on ProxMux common functions but adapted for macOS development environment
set -euo pipefail

# Error handling and messaging
error_exit() {
    echo "❌ $1" >&2
    exit 1
}

warning() {
    echo "⚠️  Warning: $1" >&2
}

success() {
    echo "✅ $1"
}

info() {
    echo "ℹ️  $1"
}

# Security and validation functions
check_not_root() {
    [[ "$EUID" -ne 0 ]] || error_exit "This script should NOT be run as root. Run as regular user."
}

confirm() {
    local prompt="$1"
    read -p "$prompt (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

validate_project_name() {
    local name="$1"
    
    [[ -n "$name" ]] || error_exit "Usage: mkproject <name> (project name required)"
    [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || error_exit "Error: Project name can only contain letters, numbers, hyphens, and underscores"
    [[ ${#name} -le 50 ]] || error_exit "Error: Project name must be 50 characters or less"
}

validate_config_file() {
    local file="$1"
    [[ -f "$file" ]] || error_exit "Error: Configuration file $file not found"
    [[ -r "$file" ]] || error_exit "Error: Cannot read configuration file $file"
}

# File operations
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        info "Backed up $file to $backup"
    fi
}

copy_config() {
    local src="$1"
    local dest="$2"
    local perms="${3:-644}"
    
    validate_config_file "$src"
    backup_file "$dest"
    cp "$src" "$dest"
    chmod "$perms" "$dest"
    success "$(basename "$dest") applied successfully"
}

# System checks and utilities
check_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    command -v "$cmd" &>/dev/null || error_exit "Error: $package installation failed or $cmd not found"
}

check_network() {
    local host="${1:-8.8.8.8}"
    ping -c 1 "$host" &>/dev/null || error_exit "Network unreachable. Check your connection."
}

safe_exec() {
    local cmd="$1"
    local timeout_duration="${2:-30}"
    
    timeout "$timeout_duration" bash -c "$cmd" 2>/dev/null
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        warning "Command timed out after ${timeout_duration}s: $cmd"
        return 1
    fi
    
    return $exit_code
}

# Directory and path utilities
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

get_project_dir() {
    local script_dir="$(get_script_dir)"
    echo "$(dirname "$script_dir")"
}

ensure_directory() {
    local dir="$1"
    local perms="${2:-755}"
    
    mkdir -p "$dir"
    chmod "$perms" "$dir"
    info "Directory $dir ready"
}

# Homebrew package management
install_homebrew() {
    if command -v brew &>/dev/null; then
        success "Homebrew already installed"
        return 0
    fi
    
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Homebrew installation failed"
    
    # Add Homebrew to PATH for current session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    success "Homebrew installed successfully"
}

install_packages_brew() {
    local packages=("$@")
    
    info "Installing packages via Homebrew: ${packages[*]}"
    
    # Update Homebrew
    brew update || error_exit "Failed to update Homebrew"
    
    # Install packages
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            info "$package already installed"
        else
            brew install "$package" || error_exit "Failed to install $package"
        fi
    done
    
    success "Package installation completed"
}

# macOS-specific functions
detect_mac_architecture() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        arm64)
            echo "apple_silicon"
            ;;
        x86_64)
            echo "intel"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

get_homebrew_prefix() {
    local arch
    arch="$(detect_mac_architecture)"
    case "$arch" in
        apple_silicon)
            echo "/opt/homebrew"
            ;;
        intel)
            echo "/usr/local"
            ;;
        *)
            echo "/usr/local"  # fallback
            ;;
    esac
}

# Integrity verification functions
download_with_verification() {
    local url="$1"
    local output_file="$2"
    local max_retries="${3:-3}"
    
    for ((i=1; i<=max_retries; i++)); do
        info "Download attempt $i/$max_retries: $url"
        
        if curl -fsSL "$url" -o "$output_file"; then
            # Basic verification - check if file is not empty and readable
            if [[ -s "$output_file" && -r "$output_file" ]]; then
                success "Downloaded: $output_file"
                return 0
            else
                warning "Downloaded file appears invalid on attempt $i"
                rm -f "$output_file"
            fi
        else
            warning "Download failed on attempt $i"
        fi
        
        if [[ $i -lt $max_retries ]]; then
            sleep 2
        fi
    done
    
    error_exit "Failed to download $url after $max_retries attempts"
}

# Development environment helpers
setup_git_config() {
    if ! git config --global user.name &>/dev/null; then
        echo "Git user configuration not found."
        read -p "Enter your full name: " git_name
        read -p "Enter your email: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        success "Git configuration completed"
    else
        success "Git already configured"
    fi
}

# Common initialization for scripts
common_init() {
    local script_name="${1:-script}"
    
    # Set secure defaults
    umask 022
    
    # Ensure we're in a known state
    cd "$(get_script_dir)"
    
    info "Starting $script_name (macOS Development Setup)"
}

# Test functions for validation
test_configuration() {
    local config_type="$1"
    
    case "$config_type" in
        zsh)
            if zsh -c "echo \$ZSH" &>/dev/null; then
                success "Zsh configuration test passed"
                return 0
            else
                warning "Zsh configuration test failed"
                return 1
            fi
            ;;
        homebrew)
            if command -v brew &>/dev/null; then
                if brew --version &>/dev/null; then
                    success "Homebrew test passed"
                    return 0
                else
                    warning "Homebrew test failed"
                    return 1
                fi
            else
                warning "Homebrew not found"
                return 1
            fi
            ;;
        git)
            if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
                success "Git configuration test passed"
                return 0
            else
                warning "Git configuration incomplete"
                return 1
            fi
            ;;
        *)
            error_exit "Unknown configuration type: $config_type"
            ;;
    esac
}

# Export functions for use in other scripts
export -f error_exit warning success info
export -f check_not_root confirm validate_project_name validate_config_file
export -f backup_file copy_config
export -f check_command check_network safe_exec
export -f get_script_dir get_project_dir ensure_directory
export -f install_homebrew install_packages_brew
export -f detect_mac_architecture get_homebrew_prefix
export -f download_with_verification setup_git_config
export -f common_init test_configuration

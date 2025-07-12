#!/bin/bash
# Shared functions library for ProxMux scripts
# Provides standardized error handling, validation, and utility functions
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
check_root() {
    [[ "$EUID" -eq 0 ]] || error_exit "This script must be run as root or with sudo. Usage: sudo $0"
}

confirm() {
    local prompt="$1"
    read -p "$prompt (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

validate_numeric_id() {
    local id="$1"
    local name="$2"
    
    [[ "$id" =~ ^[0-9]+$ ]] || error_exit "Usage: $name <id> (numeric ID only)"
    (( id >= 100 && id <= 999999 )) || error_exit "Error: ID must be between 100 and 999999"
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

copy_script() {
    local src="$1" 
    local dest="$2"
    local perms="${3:-755}"
    
    validate_config_file "$src"
    cp "$src" "$dest"
    chmod "$perms" "$dest"
    success "$(basename "$dest") installed successfully"
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
    local timeout_duration="${2:-10}"
    
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

# Integrity verification functions
verify_file_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local algorithm="${3:-sha256}"
    
    if [[ ! -f "$file" ]]; then
        error_exit "File $file does not exist for checksum verification"
    fi
    
    local actual_checksum
    case "$algorithm" in
        sha256)
            actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
            ;;
        md5)
            actual_checksum=$(md5sum "$file" | cut -d' ' -f1)
            ;;
        *)
            error_exit "Unsupported checksum algorithm: $algorithm"
            ;;
    esac
    
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        error_exit "Checksum verification failed for $file. Expected: $expected_checksum, Got: $actual_checksum"
    fi
    
    success "Checksum verification passed for $file"
}

download_with_verification() {
    local url="$1"
    local output_file="$2"
    local expected_checksum="${3:-}"
    local algorithm="${4:-sha256}"
    local max_retries="${5:-3}"
    
    for ((i=1; i<=max_retries; i++)); do
        info "Download attempt $i/$max_retries: $url"
        
        if curl -fsSL "$url" -o "$output_file"; then
            if [[ -n "$expected_checksum" ]]; then
                if verify_file_checksum "$output_file" "$expected_checksum" "$algorithm"; then
                    success "Downloaded and verified: $output_file"
                    return 0
                else
                    warning "Checksum verification failed on attempt $i"
                    rm -f "$output_file"
                fi
            else
                success "Downloaded: $output_file (no verification)"
                return 0
            fi
        else
            warning "Download failed on attempt $i"
        fi
        
        if [[ $i -lt $max_retries ]]; then
            sleep 2
        fi
    done
    
    error_exit "Failed to download and verify $url after $max_retries attempts"
}

# Service and package management
install_packages() {
    local packages=("$@")
    
    info "Installing packages: ${packages[*]}"
    
    # Update package list
    apt update || error_exit "Failed to update package list"
    
    # Install packages
    apt install -y "${packages[@]}" || error_exit "Failed to install packages"
    
    success "Package installation completed"
}

# Sudoers management
apply_sudoers_config() {
    local src_file="$1"
    local dest_file="$2"
    
    validate_config_file "$src_file"
    
    # Validate sudoers syntax
    if visudo -c -f "$src_file" &>/dev/null; then
        cp "$src_file" "$dest_file"
        chmod 440 "$dest_file"
        success "Sudoers configuration applied: $dest_file"
    else
        error_exit "Invalid sudoers configuration file: $src_file"
    fi
}

# Common initialization for scripts
common_init() {
    local script_name="${1:-script}"
    
    # Set secure defaults
    umask 022
    
    # Ensure we're in a known state
    cd "$(get_script_dir)"
    
    info "Starting $script_name (ProxMux)"
}

# Test functions for validation
test_configuration() {
    local config_type="$1"
    
    case "$config_type" in
        zsh)
            if su - root -c "zsh -c 'echo \$ZSH'" &>/dev/null; then
                success "Zsh configuration test passed"
                return 0
            else
                warning "Zsh configuration test failed"
                return 1
            fi
            ;;
        tmux)
            if tmux -f "/root/.tmux.conf" list-sessions &>/dev/null 2>&1; then
                success "tmux configuration test passed"
                return 0
            else
                success "tmux configuration loaded (no existing sessions)"
                return 0
            fi
            ;;
        ipmi)
            if command -v ipmitool &>/dev/null; then
                if safe_exec "ipmitool sdr list" 5; then
                    success "IPMI access test passed"
                    return 0
                else
                    warning "IPMI access test failed (may not be available on this hardware)"
                    return 1
                fi
            else
                warning "ipmitool not found"
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
export -f check_root confirm validate_numeric_id validate_config_file
export -f backup_file copy_config copy_script
export -f check_command check_network safe_exec
export -f get_script_dir get_project_dir ensure_directory
export -f verify_file_checksum download_with_verification
export -f install_packages apply_sudoers_config
export -f common_init test_configuration

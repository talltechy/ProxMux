#!/bin/bash
# SECURITY-HARDENED Configuration deployment script
# Applies configurations with security validation

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

# Initialize script
common_init "apply-configs.sh"

# Security check
check_root

# Get project directory
PROJECT_DIR="$(get_project_dir)"

echo "🔧 Applying Proxmox VE Configuration Files"
echo "========================================="
info "Project directory: $PROJECT_DIR"
echo

# Backup existing configurations
info "Creating backups of existing configurations..."
backup_file "/root/.zshrc"
backup_file "/root/.tmux.conf"

# Configuration files mapping
declare -A CONFIG_FILES=(
    ["$PROJECT_DIR/configs/.zshrc"]="/root/.zshrc"
    ["$PROJECT_DIR/configs/.tmux.conf"]="/root/.tmux.conf"
)

# Apply configuration files
info "Applying configuration files..."
for src_file in "${!CONFIG_FILES[@]}"; do
    dest_file="${CONFIG_FILES[$src_file]}"
    copy_config "$src_file" "$dest_file" 644
done

# Create and secure scripts directory
ensure_directory "/root/bin" 755

# Script files mapping
declare -A SCRIPT_FILES=(
    ["$PROJECT_DIR/scripts/pve-tmux.sh"]="/root/bin/pve-tmux.sh"
    ["$PROJECT_DIR/scripts/hardware-sensors.sh"]="/root/bin/hardware-sensors.sh"
)

# Install scripts
info "Installing scripts..."
for src_script in "${!SCRIPT_FILES[@]}"; do
    dest_script="${SCRIPT_FILES[$src_script]}"
    copy_script "$src_script" "$dest_script" 755
done

# Apply sudoers configuration for IPMI access
info "Configuring sudoers for IPMI access..."
SUDOERS_SRC="$PROJECT_DIR/security/sudoers-ipmi"
SUDOERS_DEST="/etc/sudoers.d/ipmi-access"

if [[ -f "$SUDOERS_SRC" ]]; then
    apply_sudoers_config "$SUDOERS_SRC" "$SUDOERS_DEST"
else
    warning "sudoers-ipmi not found, creating basic configuration..."
    cat > "$SUDOERS_DEST" << 'EOF'
# Allow root to use ipmitool without password (security-restricted)
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type temperature
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type fan
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sdr type current
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool sel list last *
root ALL=(ALL) NOPASSWD: /usr/bin/ipmitool chassis status
EOF
    chmod 440 "$SUDOERS_DEST"
    success "Basic sudoers configuration created"
fi

# Test configurations
info "Testing configurations..."

# Test zsh configuration
test_configuration "zsh"

# Test tmux configuration  
test_configuration "tmux"

# Test IPMI access
test_configuration "ipmi"

echo
success "Configuration deployment completed!"
echo
info "Summary of applied configurations:"
echo "  • ~/.zshrc - Security-hardened zsh configuration"
echo "  • ~/.tmux.conf - Proxmox monitoring tmux configuration"
echo "  • ~/bin/pve-tmux.sh - Monitoring session script"
echo "  • ~/bin/hardware-sensors.sh - Hardware monitoring script"
echo "  • /etc/sudoers.d/ipmi-access - IPMI access configuration"
echo
info "Quick start:"
echo "  1. Start new zsh session: zsh"
echo "  2. Test tmux: tmux"
echo "  3. Start monitoring: pve-monitor"
echo "  4. Check hardware: hardwarestatus"
echo
info "Security reminders:"
echo "  • Running as root - consider creating dedicated user"
echo "  • IPMI access is restricted to specific commands"
echo "  • Command history is limited for security"
echo "  • Review logs regularly: /var/log/auth.log"

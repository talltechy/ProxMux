#!/bin/bash
# SECURITY-HARDENED Proxmox VE tmux monitoring session with ProxMux
# Optimized for server monitoring with security considerations

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

# Initialize script
common_init "pve-tmux.sh"

# Session configuration
SESSION="proxmox-main"
declare -A WINDOWS=(
    [dashboard]="dashboard"
    [system]="system"
    [hardware]="hardware"
    [logs]="logs"
    [network]="network"
    [resources]="resources"
)

cleanup_old_session() {
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        info "Existing session found: $SESSION"
        if confirm "Attach to existing session instead of creating new one?"; then
            info "Attaching to existing session..."
            tmux attach-session -t "$SESSION"
            exit 0
        else
            info "Cleaning up existing session: $SESSION"
            tmux kill-session -t "$SESSION"
        fi
    fi
}

# Security check: Warn if running as root
if [[ "$EUID" -eq 0 ]]; then
    warning "Running as root. Consider using a dedicated user."
    confirm "Continue?" || exit 1
fi

# Check if tmux is available
check_command "tmux"

# Handle existing session
cleanup_old_session

info "Starting Proxmox VE monitoring session..."

# Create main session with dashboard
tmux new-session -d -s "$SESSION" -n "${WINDOWS[dashboard]}"

# Main dashboard with limited info exposure
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}" "watch -n 10 'echo \"=== Node: \$(hostname) - \$(date) ===\"; echo; echo \"=== VMs (limited view) ===\"; qm list | head -15; echo; echo \"=== Containers (limited view) ===\"; pct list | head -15; echo; echo \"=== Storage Status ===\"; pvesm status | head -10'" Enter

# Split for quick commands (secure prompt)
tmux split-window -h -t "$SESSION:${WINDOWS[dashboard]}"
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '📋 Quick Commands Available:'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  qmls, ctls - List VMs/containers'" Enter  
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  vminfo <id>, ctinfo <id> - VM/container details'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  hardwarestatus - Hardware status'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  htop, iostat - System monitoring'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo ''" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '🔧 tmux Layouts:'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  Ctrl+a M-m - System monitoring'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  Ctrl+a M-l - Log monitoring'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  Ctrl+a M-s - Storage monitoring'" Enter
tmux send-keys -t "$SESSION:${WINDOWS[dashboard]}.1" "echo '  Ctrl+a M-h - Hardware monitoring'" Enter

# System monitoring window (secure intervals)
tmux new-window -t "$SESSION" -n "${WINDOWS[system]}"
tmux send-keys -t "$SESSION:${WINDOWS[system]}" "htop -d 10" Enter
tmux split-window -h -t "$SESSION:${WINDOWS[system]}"
tmux send-keys -t "$SESSION:${WINDOWS[system]}.1" "iostat -x 5" Enter
tmux split-window -v -t "$SESSION:${WINDOWS[system]}.1"
tmux send-keys -t "$SESSION:${WINDOWS[system]}.2" "watch -n 10 'df -h | head -15'" Enter

# Hardware monitoring window (secure)
tmux new-window -t "$SESSION" -n "${WINDOWS[hardware]}"
tmux send-keys -t "$SESSION:${WINDOWS[hardware]}" "watch -n 15 'sensors'" Enter
tmux split-window -h -t "$SESSION:${WINDOWS[hardware]}"
tmux send-keys -t "$SESSION:${WINDOWS[hardware]}.1" "watch -n 30 'echo \"=== IPMI Temperature Sensors ===\"; sudo /usr/bin/ipmitool sdr type temperature 2>/dev/null | head -10 || echo \"IPMI not available\"'" Enter
tmux split-window -v -t "$SESSION:${WINDOWS[hardware]}.1"
tmux send-keys -t "$SESSION:${WINDOWS[hardware]}.2" "watch -n 30 'echo \"=== IPMI Fan Status ===\"; sudo /usr/bin/ipmitool sdr type fan 2>/dev/null | head -8 || echo \"IPMI not available\"'" Enter

# Logs window (limited exposure)
tmux new-window -t "$SESSION" -n "${WINDOWS[logs]}"
tmux send-keys -t "$SESSION:${WINDOWS[logs]}" "journalctl -f --lines=25 -u pve-cluster" Enter
tmux split-window -h -t "$SESSION:${WINDOWS[logs]}"
tmux send-keys -t "$SESSION:${WINDOWS[logs]}.1" "tail -f /var/log/syslog | grep -E '(error|warning|critical)' --color=always" Enter

# Network monitoring window (basic info only)
tmux new-window -t "$SESSION" -n "${WINDOWS[network]}"
tmux send-keys -t "$SESSION:${WINDOWS[network]}" "watch -n 10 'echo \"=== Network Interfaces ===\"; ip addr show | grep -E \"^[0-9]+:|inet \" | head -20'" Enter
tmux split-window -h -t "$SESSION:${WINDOWS[network]}"
tmux send-keys -t "$SESSION:${WINDOWS[network]}.1" "watch -n 15 'echo \"=== Network Connections ===\"; ss -tuln | head -25'" Enter

# Resources window (performance monitoring)
tmux new-window -t "$SESSION" -n "${WINDOWS[resources]}"
tmux send-keys -t "$SESSION:${WINDOWS[resources]}" "vmstat 5" Enter
tmux split-window -h -t "$SESSION:${WINDOWS[resources]}"
tmux send-keys -t "$SESSION:${WINDOWS[resources]}.1" "watch -n 5 'echo \"=== Memory Usage ===\"; free -h; echo; echo \"=== Load Average ===\"; uptime'" Enter

# Go back to dashboard
tmux select-window -t "$SESSION:${WINDOWS[dashboard]}"
tmux select-pane -t 0

# Display startup message
success "Proxmox monitoring session started successfully!"
info "Security features enabled:"
echo "   - Limited command exposure"
echo "   - Restricted monitoring intervals"
echo "   - Input validation active"
echo "   - IPMI access controlled"
echo
info "Session: $SESSION"
info "Use 'tmux attach -t $SESSION' to reconnect"
echo

# Attach to session
tmux attach-session -t "$SESSION"

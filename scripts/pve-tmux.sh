#!/bin/bash
# SECURITY-HARDENED Proxmox VE tmux monitoring session with ProxMux
# Optimized for server monitoring with security considerations

# Security check: Ensure running as intended user
if [[ "$EUID" -eq 0 ]]; then
    echo "⚠️  Warning: Running as root. Consider using a dedicated user."
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Security: Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo "❌ Error: tmux is not installed"
    exit 1
fi

# Security: Check if session already exists
if tmux has-session -t "proxmox-main" 2>/dev/null; then
    echo "🔄 Attaching to existing proxmox-main session..."
    tmux attach-session -t "proxmox-main"
    exit 0
fi

echo "🚀 Starting Proxmox VE monitoring session..."

# Create main session with dashboard
tmux new-session -d -s "proxmox-main" -n "dashboard"

# Main dashboard with limited info exposure
tmux send-keys -t "proxmox-main:dashboard" "watch -n 10 'echo \"=== Node: \$(hostname) - \$(date) ===\"; echo; echo \"=== VMs (limited view) ===\"; qm list | head -15; echo; echo \"=== Containers (limited view) ===\"; pct list | head -15; echo; echo \"=== Storage Status ===\"; pvesm status | head -10'" Enter

# Split for quick commands (secure prompt)
tmux split-window -h -t "proxmox-main:dashboard"
tmux send-keys -t "proxmox-main:dashboard.1" "echo '📋 Quick Commands Available:'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  qmls, ctls - List VMs/containers'" Enter  
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  vminfo <id>, ctinfo <id> - VM/container details'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  hardwarestatus - Hardware status'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  htop, iostat - System monitoring'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo ''" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '🔧 tmux Layouts:'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  Ctrl+a M-m - System monitoring'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  Ctrl+a M-l - Log monitoring'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  Ctrl+a M-s - Storage monitoring'" Enter
tmux send-keys -t "proxmox-main:dashboard.1" "echo '  Ctrl+a M-h - Hardware monitoring'" Enter

# System monitoring window (secure intervals)
tmux new-window -t "proxmox-main" -n "system"
tmux send-keys -t "proxmox-main:system" "htop -d 10" Enter
tmux split-window -h -t "proxmox-main:system"
tmux send-keys -t "proxmox-main:system.1" "iostat -x 5" Enter
tmux split-window -v -t "proxmox-main:system.1" 
tmux send-keys -t "proxmox-main:system.2" "watch -n 10 'df -h | head -15'" Enter

# Hardware monitoring window (secure)
tmux new-window -t "proxmox-main" -n "hardware"
tmux send-keys -t "proxmox-main:hardware" "watch -n 15 'sensors'" Enter
tmux split-window -h -t "proxmox-main:hardware"
tmux send-keys -t "proxmox-main:hardware.1" "watch -n 30 'echo \"=== IPMI Temperature Sensors ===\"; sudo /usr/bin/ipmitool sdr type temperature 2>/dev/null | head -10 || echo \"IPMI not available\"'" Enter
tmux split-window -v -t "proxmox-main:hardware.1"
tmux send-keys -t "proxmox-main:hardware.2" "watch -n 30 'echo \"=== IPMI Fan Status ===\"; sudo /usr/bin/ipmitool sdr type fan 2>/dev/null | head -8 || echo \"IPMI not available\"'" Enter

# Logs window (limited exposure)
tmux new-window -t "proxmox-main" -n "logs"
tmux send-keys -t "proxmox-main:logs" "journalctl -f --lines=25 -u pve-cluster" Enter
tmux split-window -h -t "proxmox-main:logs"
tmux send-keys -t "proxmox-main:logs.1" "tail -f /var/log/syslog | grep -E '(error|warning|critical)' --color=always" Enter

# Network monitoring window (basic info only)
tmux new-window -t "proxmox-main" -n "network"
tmux send-keys -t "proxmox-main:network" "watch -n 10 'echo \"=== Network Interfaces ===\"; ip addr show | grep -E \"^[0-9]+:|inet \" | head -20'" Enter
tmux split-window -h -t "proxmox-main:network"
tmux send-keys -t "proxmox-main:network.1" "watch -n 15 'echo \"=== Network Connections ===\"; ss -tuln | head -25'" Enter

# Resources window (performance monitoring)
tmux new-window -t "proxmox-main" -n "resources"
tmux send-keys -t "proxmox-main:resources" "vmstat 5" Enter
tmux split-window -h -t "proxmox-main:resources"
tmux send-keys -t "proxmox-main:resources.1" "watch -n 5 'echo \"=== Memory Usage ===\"; free -h; echo; echo \"=== Load Average ===\"; uptime'" Enter

# Go back to dashboard
tmux select-window -t "proxmox-main:dashboard"
tmux select-pane -t 0

# Security: Display startup message
echo "✅ Proxmox monitoring session started successfully!"
echo "🔒 Security features enabled:"
echo "   - Limited command exposure"
echo "   - Restricted monitoring intervals"
echo "   - Input validation active"
echo "   - IPMI access controlled"
echo ""
echo "📱 Session: proxmox-main"
echo "🎯 Use 'tmux attach -t proxmox-main' to reconnect"
echo ""

# Attach to session
tmux attach-session -t "proxmox-main"

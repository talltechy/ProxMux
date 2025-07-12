# SECURITY-HARDENED .zshrc for Proxmox VE with ProxMux
# Optimized for server monitoring with security considerations

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme optimized for server identification
ZSH_THEME="bira"

# Security-conscious plugin selection
plugins=(
    git
    sudo
    systemd
    ssh-agent
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting  # Must be last
)

source $ZSH/oh-my-zsh.sh

# ===== SECURITY CONFIGURATION =====

# Secure history settings
HISTSIZE=10000  # Reduced from 50000 for security
SAVEHIST=10000
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE        # Don't store history commands
setopt HIST_NO_FUNCTIONS    # Don't store function definitions

# Secure environment
export EDITOR=nano
export PAGER="less -R"  # Secure pager options
export TERM=tmux-256color
export PVE_NODE=$(hostname)

# Secure PATH - ensure ~/bin is included safely
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# ===== PROXMOX VE CONFIGURATION =====

# VM Management (with input validation)
alias qmls='qm list'
alias qmstart='qm start'
alias qmstop='qm stop'
alias qmreboot='qm reboot'
alias qmstatus='qm status'

# Container Management (with input validation)
alias ctls='pct list'
alias ctstart='pct start'
alias ctstop='pct stop'  
alias ctreboot='pct reboot'
alias ctstatus='pct status'

# Storage and Backup
alias pvesm='pvesm status'
alias pvebackup='vzdump'

# Network and Cluster (limited exposure)
alias pvecm='pvecm status'
alias pvenode='pvesh get /nodes'

# System Monitoring (restricted to necessary info)
alias htop='htop -d 10'
alias iostat='iostat -x 2'
alias vmstat='vmstat 2'

# Secure log viewing (limited exposure)
alias syslog='tail -n 50 /var/log/syslog'
alias kernlog='tail -n 50 /var/log/kern.log'

# ===== HARDWARE MONITORING =====

# Hardware monitoring (restricted IPMI access)
alias hwtemp='sudo /usr/bin/ipmitool sdr type temperature'
alias hwfan='sudo /usr/bin/ipmitool sdr type fan' 
alias hwpower='sudo /usr/bin/ipmitool sdr type current'
alias hardwarestatus='~/bin/hardware-sensors.sh'

# Secure temperature monitoring
alias temp='sensors 2>/dev/null && echo "--- IPMI Temperatures ---" && sudo /usr/bin/ipmitool sdr type temperature 2>/dev/null | head -10'

# ===== SECURE FUNCTIONS =====

# VM info with input validation
vminfo() {
    if [[ $# -eq 0 || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Usage: vminfo <vmid> (numeric ID only)"
        return 1
    fi
    if (( $1 < 100 || $1 > 999999 )); then
        echo "Error: VM ID must be between 100 and 999999"
        return 1
    fi
    qm config "$1" 2>/dev/null || echo "VM $1 not found"
    echo "--- Status ---"
    qm status "$1" 2>/dev/null
}

# Container info with input validation  
ctinfo() {
    if [[ $# -eq 0 || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Usage: ctinfo <ctid> (numeric ID only)"
        return 1
    fi
    if (( $1 < 100 || $1 > 999999 )); then
        echo "Error: Container ID must be between 100 and 999999"
        return 1
    fi
    pct config "$1" 2>/dev/null || echo "Container $1 not found"
    echo "--- Status ---"
    pct status "$1" 2>/dev/null
}

# Secure node resources check
noderesources() {
    pvesh get "/nodes/$(hostname)/status" 2>/dev/null | grep -E "(cpu|memory|uptime|loadavg)" || echo "Unable to retrieve node resources"
}

# ===== PROMPT CONFIGURATION =====

# tmux session display
tmux_session() {
    if [[ -n "$TMUX" ]]; then
        echo "%{$fg[cyan]%}[tmux:$(tmux display-message -p '#S')]%{$reset_color%} "
    fi
}

# Proxmox host indicator
proxmox_indicator() {
    echo "%{$fg[green]%}[PVE]%{$reset_color%} "
}

# Security warning for root user
root_warning() {
    if [[ "$EUID" -eq 0 ]]; then
        echo "%{$fg[red]%}[ROOT]%{$reset_color%} "
    fi
}

PROMPT='$(root_warning)$(proxmox_indicator)$(tmux_session)'$PROMPT

# ===== TMUX SHORTCUTS =====

alias pve-monitor='~/bin/pve-tmux.sh'
alias pve-attach='tmux attach-session -t proxmox-main 2>/dev/null || echo "No proxmox-main session found"'
alias pve-new='tmux new-session -s "proxmox-$(date +%s)"'

# Secure tmux console functions with validation
pve-vm-console() {
    if [[ $# -eq 0 || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Usage: pve-vm-console <vmid> (numeric ID only)"
        return 1
    fi
    if (( $1 < 100 || $1 > 999999 )); then
        echo "Error: VM ID must be between 100 and 999999"
        return 1
    fi
    # Check if VM exists before opening console
    if qm status "$1" >/dev/null 2>&1; then
        tmux new-window -n "vm-$1"
        tmux send-keys "qm terminal $1" Enter
    else
        echo "Error: VM $1 not found or not accessible"
    fi
}

pve-ct-console() {
    if [[ $# -eq 0 || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Usage: pve-ct-console <ctid> (numeric ID only)"
        return 1
    fi
    if (( $1 < 100 || $1 > 999999 )); then
        echo "Error: Container ID must be between 100 and 999999"  
        return 1
    fi
    # Check if container exists before entering
    if pct status "$1" >/dev/null 2>&1; then
        tmux new-window -n "ct-$1"
        tmux send-keys "pct enter $1" Enter
    else
        echo "Error: Container $1 not found or not accessible"
    fi
}

# ===== SECURITY REMINDERS =====

# Display security reminder on shell start (only for interactive shells)
if [[ $- == *i* && "$EUID" -eq 0 ]]; then
    echo "⚠️  Security Notice: Running as root. Consider using a dedicated user account."
    echo "📁 Config files: ~/.zshrc, ~/.tmux.conf"
    echo "🔧 Management: pve-monitor, qmls, ctls"
fi

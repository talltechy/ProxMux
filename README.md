# ProxMux

**A comprehensive configuration package for Oh My Zsh and tmux, specifically optimized for Proxmox VE hosts.**

## 🔒 Security Analysis Summary

### ✅ **Security Improvements Made:**

1. **Input Validation** - All functions validate parameters and check bounds
2. **Restricted IPMI Access** - Limited to read-only monitoring commands only  
3. **Reduced Attack Surface** - Limited command history, timeouts, safe defaults
4. **Error Handling** - Graceful failures without information disclosure
5. **Access Controls** - Specific sudoers rules, no wildcard permissions

### ⚠️ **Security Considerations:**

- **Root User**: Configuration designed for root - consider dedicated user
- **IPMI Hardware Access**: Provides hardware monitoring capabilities
- **SSH Agent**: Keys persist in memory - use timeouts and rotation
- **tmux Sessions**: Long-running sessions increase exposure
- **Network Access**: Ensure proper firewall configuration

## � File Structure

```
proxmux/
├── README.md                   # Project overview and quick start
├── setup.sh                   # One-command setup script
├── configs/
│   ├── .zshrc                 # Security-hardened zsh configuration
│   └── .tmux.conf            # Proxmox monitoring tmux config
├── scripts/
│   ├── install-packages.sh   # Package installation script
│   ├── apply-configs.sh      # Configuration deployment script
│   ├── pve-tmux.sh          # Monitoring session launcher
│   └── hardware-sensors.sh  # Hardware monitoring
└── security/
    ├── SECURITY.md           # Comprehensive security guide
    └── sudoers-ipmi         # Restricted IPMI sudoers rules
```

## � Quick Installation

### Option 1: Complete Setup (Recommended)
```bash
# Copy entire folder to Proxmox host, then:
sudo ./setup.sh
```

### Option 2: Manual Installation
```bash
# 1. Install packages
sudo ./scripts/install-packages.sh

# 2. Apply configurations
sudo ./scripts/apply-configs.sh

# 3. Test setup
zsh
pve-monitor
```

## 🔧 Key Features

### Proxmox Management
- **VM/Container Control**: `qmls`, `ctls`, `vminfo <id>`, `ctinfo <id>`
- **Resource Monitoring**: `noderesources`, system load tracking
- **Storage Management**: `pvesm` status, backup shortcuts
- **Network Overview**: Interface and connection monitoring

### Hardware Monitoring
- **Temperature Monitoring**: CPU sensors + IPMI thermal data
- **Fan Status**: RPM monitoring with color-coded alerts
- **Power Consumption**: Current draw and power status
- **System Events**: Recent hardware events and logs
- **Health Summary**: Automated threshold checking

### Advanced tmux Layouts
- **Ctrl+a M-m**: System monitoring (htop, iostat, VM list)
- **Ctrl+a M-l**: Log monitoring (syslog, journal, PVE logs)
- **Ctrl+a M-s**: Storage monitoring (disk usage, PVE storage)
- **Ctrl+a M-h**: Hardware monitoring (temps, fans, IPMI)
- **Ctrl+a M-v**: VM management dashboard
- **Ctrl+a M-c**: Container management dashboard
- **Ctrl+a M-n**: Network monitoring
- **Ctrl+a M-r**: Resource utilization

### Security Features
- **Input Validation**: All functions check parameters and ranges
- **Restricted Commands**: IPMI limited to read-only operations
- **Safe Defaults**: Timeouts, error handling, limited exposure
- **Audit Trail**: Command logging and access monitoring
- **Access Controls**: Specific sudoers rules, no wildcards

## 📋 Usage Examples

### Basic Commands
```bash
# List VMs and containers
qmls && ctls

# Get detailed info
vminfo 100
ctinfo 101

# Hardware status
hardwarestatus
temp

# Start monitoring session
pve-monitor
```

### tmux Monitoring
```bash
# Start comprehensive monitoring
pve-monitor

# Within tmux session:
Ctrl+a M-m    # System monitoring layout
Ctrl+a M-h    # Hardware monitoring layout
Ctrl+a M-l    # Log monitoring layout
```

### Security Commands
```bash
# Check recent authentication attempts
grep "Failed password" /var/log/auth.log | tail -10

# Monitor IPMI access
grep "ipmitool" /var/log/auth.log

# Review active sessions
tmux list-sessions
```

## ⚠️ Important Security Notes

1. **Review Security Guide**: Read `security/SECURITY.md` completely
2. **Root User**: Consider creating dedicated user instead of root
3. **IPMI Access**: Hardware control capabilities - audit carefully
4. **Regular Updates**: Keep Proxmox and packages updated
5. **Monitor Logs**: Check authentication and access logs regularly

## 🆘 Support & Troubleshooting

### Common Issues
- **Plugin errors**: Run `source ~/.zshrc` after installation
- **IPMI not working**: Check `sudo ipmitool sdr list`
- **tmux layouts not working**: Verify key bindings with `Ctrl+a ?`
- **Permission errors**: Ensure scripts have execute permissions

### Getting Help
- Check security guide: `security/SECURITY.md`
- Review configuration files for comments and explanations
- Test individual components before full deployment
- Use `--brief` flag with monitoring scripts for minimal output

## 🔄 Updates & Maintenance

### Regular Tasks
- Update packages monthly: `apt update && apt upgrade`
- Review logs weekly: Check `/var/log/auth.log`
- Rotate SSH keys quarterly
- Test backup configurations
- Audit user access and permissions

### Configuration Changes
- Backup configs before changes: `cp ~/.zshrc ~/.zshrc.backup`
- Test changes in isolated environment first
- Document modifications for audit trail
- Review security implications of changes

---

**Created with security and monitoring in mind for Proxmox VE with ProxMux**

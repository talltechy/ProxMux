# Security Hardening Guide for ProxMux Configuration

## 🔴 CRITICAL SECURITY CONSIDERATIONS

### Running as Root User
- **Risk**: Full system access, no privilege separation
- **Recommendation**: Create dedicated user account
- **Implementation**:
  ```bash
  useradd -m -s /bin/zsh -G sudo pveadmin
  passwd pveadmin
  # Apply same configurations to /home/pveadmin/
  ```

### IPMI Hardware Access
- **Risk**: Hardware-level control capabilities
- **Mitigation**: Restricted sudoers configuration (monitoring only)
- **Audit**: Review /var/log/auth.log for IPMI command usage

### SSH Agent Persistence
- **Risk**: Compromised keys remain active
- **Mitigation**: Use SSH key timeouts, regular key rotation
- **Implementation**: `ssh-add -t 3600` (1 hour timeout)

## 🟡 MEDIUM SECURITY CONSIDERATIONS

### tmux Session Persistence
- **Risk**: Long-running sessions increase attack surface
- **Mitigation**: Regular session cleanup, activity monitoring
- **Best Practice**: Exit sessions when not needed

### Command History Storage
- **Risk**: Sensitive commands stored in history
- **Mitigation**: Reduced history size (10,000 vs 50,000)
- **Additional**: Use `HIST_IGNORE_SPACE` for sensitive commands

### System Log Access
- **Risk**: Information disclosure through log files
- **Mitigation**: Limited log output, restricted access
- **Monitoring**: Review log access patterns

## 🔒 IMPLEMENTED SECURITY MEASURES

### Input Validation
- All functions validate numeric inputs
- Parameter bounds checking (VM/CT IDs: 100-999999)
- Command existence verification before execution

### Restricted Command Execution
- IPMI commands limited to read-only operations
- Timeout protection for long-running commands
- Error handling prevents information disclosure

### Limited Information Exposure
- Reduced monitoring intervals
- Truncated output displays
- Sanitized error messages

### Access Controls
- Specific sudoers rules for IPMI access only
- No wildcard permissions
- Command path restrictions

## 📋 SECURITY CHECKLIST

### Pre-Installation
- [ ] Review all configuration files
- [ ] Understand IPMI security implications
- [ ] Plan for dedicated user account
- [ ] Backup existing configurations

### During Installation
- [ ] Verify package signatures
- [ ] Apply restricted sudoers configuration
- [ ] Test with limited privileges first
- [ ] Monitor installation logs

### Post-Installation
- [ ] Change default passwords
- [ ] Configure SSH key authentication
- [ ] Disable password authentication
- [ ] Set up log monitoring
- [ ] Regular security updates
- [ ] Audit user access

### Ongoing Security
- [ ] Regular configuration reviews
- [ ] Monitor authentication logs
- [ ] Update packages monthly
- [ ] Rotate SSH keys quarterly
- [ ] Review IPMI access logs
- [ ] Audit tmux sessions weekly

## 🛡️ ADDITIONAL HARDENING

### Network Security
```bash
# Configure firewall for SSH only
ufw allow 22/tcp
ufw enable

# Disable unused services
systemctl disable bluetooth
systemctl disable cups
```

### SSH Hardening
```bash
# /etc/ssh/sshd_config additions:
PasswordAuthentication no
PermitRootLogin prohibit-password
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

### System Monitoring
```bash
# Install intrusion detection
apt install fail2ban aide rkhunter

# Configure log monitoring
apt install logwatch
```

### File Permissions
```bash
# Secure configuration files
chmod 600 ~/.zshrc ~/.tmux.conf
chmod 700 ~/bin/
chmod 755 ~/bin/*.sh
```

## ⚠️ SECURITY WARNINGS

1. **Root Access**: This configuration runs as root. Consider dedicated user.

2. **IPMI Commands**: Hardware control capabilities - audit access carefully.

3. **Network Exposure**: Proxmox web interface - ensure proper firewall rules.

4. **Update Schedule**: Keep Proxmox and packages updated regularly.

5. **Access Logging**: Monitor /var/log/auth.log for unauthorized access.

## 🔍 SECURITY MONITORING

### Log Files to Monitor
- `/var/log/auth.log` - Authentication attempts
- `/var/log/syslog` - System events
- `/var/log/pve-cluster.log` - Proxmox cluster events
- `~/.zsh_history` - Command history review

### Regular Checks
```bash
# Check for failed login attempts
grep "Failed password" /var/log/auth.log | tail -20

# Review sudo usage
grep "sudo" /var/log/auth.log | tail -20

# Check IPMI access
grep "ipmitool" /var/log/auth.log | tail -10

# Monitor tmux sessions
tmux list-sessions
```

### Incident Response
1. Immediately revoke compromised SSH keys
2. Kill suspicious tmux sessions
3. Review and rotate passwords
4. Check system integrity with AIDE
5. Audit all configuration changes

## 📞 EMERGENCY PROCEDURES

### Lockout Recovery
- Physical console access required
- Reset root password via recovery mode
- Restore configurations from backup
- Review security logs for compromise

### Suspected Compromise
1. Disconnect from network immediately
2. Kill all active sessions
3. Change all passwords and keys
4. Restore from known-good backup
5. Conduct full security audit

#!/bin/bash
# SECURITY-HARDENED Hardware Monitoring Script for ProxMux
# Provides comprehensive hardware status with security considerations

# Security: Ensure proper permissions
if [[ ! -r /usr/bin/ipmitool ]]; then
    echo "❌ Error: ipmitool not accessible. Check installation and permissions."
    exit 1
fi

# Security: Input validation for command line arguments
if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [--brief]"
    exit 1
fi

BRIEF_MODE=false
if [[ "$1" == "--brief" ]]; then
    BRIEF_MODE=true
fi

# Colors for output (security: limited escape sequences)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Security function: Safe command execution with timeout
safe_exec() {
    local cmd="$1"
    local timeout_duration=10
    
    timeout "$timeout_duration" bash -c "$cmd" 2>/dev/null
    return $?
}

echo -e "${BLUE}=== Hardware Status ===${NC}"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime | cut -d',' -f1)"
echo

# CPU Temperature Monitoring (sensors)
echo -e "${GREEN}--- CPU Temperatures (Sensors) ---${NC}"
if safe_exec "sensors coretemp-isa-* 2>/dev/null"; then
    sensors coretemp-isa-* 2>/dev/null | grep -E "(Core|Package)" | head -10
else
    echo "⚠️  CPU temperature sensors not available"
fi
echo

# IPMI Temperature Monitoring (security: limited output)
echo -e "${GREEN}--- System Temperatures (IPMI) ---${NC}"
if safe_exec "sudo /usr/bin/ipmitool sdr type temperature"; then
    sudo /usr/bin/ipmitool sdr type temperature 2>/dev/null | grep -v "Not Present" | head -15 | while read line; do
        if [[ "$line" == *"degrees C"* ]]; then
            temp=$(echo "$line" | grep -o '[0-9]\+\s*degrees' | grep -o '[0-9]\+')
            if [[ -n "$temp" && "$temp" -gt 80 ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ -n "$temp" && "$temp" -gt 70 ]]; then
                echo -e "${YELLOW}$line${NC}"
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done
else
    echo "⚠️  IPMI temperature data not available"
fi
echo

# Fan Status (security: limited exposure)
echo -e "${GREEN}--- Fan Status ---${NC}"
if safe_exec "sudo /usr/bin/ipmitool sdr type fan"; then
    sudo /usr/bin/ipmitool sdr type fan 2>/dev/null | grep -v "Not Present" | head -12 | while read line; do
        if [[ "$line" == *"RPM"* ]]; then
            rpm=$(echo "$line" | grep -o '[0-9]\+\s*RPM' | grep -o '[0-9]\+')
            if [[ -n "$rpm" && "$rpm" -lt 1000 ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ -n "$rpm" && "$rpm" -lt 2000 ]]; then
                echo -e "${YELLOW}$line${NC}"
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done
else
    echo "⚠️  Fan status data not available"
fi
echo

if [[ "$BRIEF_MODE" == "false" ]]; then
    # Power Status (security: limited info)
    echo -e "${GREEN}--- Power Status ---${NC}"
    if safe_exec "sudo /usr/bin/ipmitool sdr type current"; then
        sudo /usr/bin/ipmitool sdr type current 2>/dev/null | head -8
    else
        echo "⚠️  Power status data not available"
    fi
    echo

    # System Event Log (security: recent events only)
    echo -e "${GREEN}--- Recent System Events (Last 5) ---${NC}"
    if safe_exec "sudo /usr/bin/ipmitool sel list last 5"; then
        sudo /usr/bin/ipmitool sel list last 5 2>/dev/null | tail -5
    else
        echo "⚠️  System event log not available"
    fi
    echo

    # Chassis Status (security: basic info only)
    echo -e "${GREEN}--- Chassis Status ---${NC}"
    if safe_exec "sudo /usr/bin/ipmitool chassis status"; then
        sudo /usr/bin/ipmitool chassis status 2>/dev/null | grep -E "(Power|Cooling|Drive)" | head -5
    else
        echo "⚠️  Chassis status not available"
    fi
    echo

    # Memory Information (basic info)
    echo -e "${GREEN}--- Memory Status ---${NC}"
    free -h | head -2
    echo

    # Storage Overview (limited info)
    echo -e "${GREEN}--- Storage Overview ---${NC}"
    df -h | grep -E "(Filesystem|/dev/)" | head -6
    echo

    # Network Interface Status (basic info)
    echo -e "${GREEN}--- Network Interface Status ---${NC}"
    ip addr show | grep -E "^[0-9]+:|inet " | head -10
    echo
fi

# Summary with health indicators
echo -e "${BLUE}=== Health Summary ===${NC}"

# Check critical thresholds (security: safe checks only)
critical_issues=0
warnings=0

# Temperature check
if safe_exec "sensors coretemp-isa-*"; then
    max_temp=$(sensors coretemp-isa-* 2>/dev/null | grep -o '+[0-9]\+\.[0-9]*°C' | grep -o '[0-9]\+' | sort -n | tail -1)
    if [[ -n "$max_temp" && "$max_temp" -gt 85 ]]; then
        echo -e "${RED}⚠️  CRITICAL: CPU temperature high ($max_temp°C)${NC}"
        ((critical_issues++))
    elif [[ -n "$max_temp" && "$max_temp" -gt 75 ]]; then
        echo -e "${YELLOW}⚠️  WARNING: CPU temperature elevated ($max_temp°C)${NC}"
        ((warnings++))
    fi
fi

# Load average check
load_1min=$(cut -d' ' -f1 /proc/loadavg)
if (( $(echo "$load_1min > 16.0" | bc -l) )); then
    echo -e "${RED}⚠️  CRITICAL: High system load ($load_1min)${NC}"
    ((critical_issues++))
elif (( $(echo "$load_1min > 8.0" | bc -l) )); then
    echo -e "${YELLOW}⚠️  WARNING: Elevated system load ($load_1min)${NC}"
    ((warnings++))
fi

# Summary
if [[ $critical_issues -eq 0 && $warnings -eq 0 ]]; then
    echo -e "${GREEN}✅ System status: HEALTHY${NC}"
elif [[ $critical_issues -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  System status: WARNING ($warnings issues)${NC}"
else
    echo -e "${RED}❌ System status: CRITICAL ($critical_issues critical, $warnings warnings)${NC}"
fi

echo
echo "🔄 For continuous monitoring: watch -n 30 '~/bin/hardware-sensors.sh --brief'"
echo "📊 For tmux monitoring: pve-monitor (use Ctrl+a M-h for hardware layout)"

#!/bin/bash

# Script to check system prerequisites for hibernation setup
# Author: System Setup Script
# Description: Validates system requirements before setting up hibernation

set -e  # Exit on any error

echo "=== Hibernation Prerequisites Check ==="
echo "Checking system requirements for hibernation setup..."
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[⚠]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[✗]${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}[i]${NC} $message"
            ;;
    esac
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_status "WARNING" "Running as root. Some checks may need non-root perspective."
        print_status "INFO" "System modifications can be performed automatically (with your confirmation)."
    else
        print_status "INFO" "Running as non-root user: $(whoami)"
        print_status "INFO" "Will provide commands to run manually for any required fixes."
    fi
}

# Check system information
check_system_info() {
    echo -e "\n${BLUE}=== System Information ===${NC}"
    
    # OS Information
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        print_status "INFO" "OS: $NAME $VERSION"
    fi
    
    # Kernel version
    kernel_version=$(uname -r)
    print_status "INFO" "Kernel: $kernel_version"
    
    # Architecture
    arch=$(uname -m)
    print_status "INFO" "Architecture: $arch"
    
    # Uptime
    uptime_info=$(uptime -p 2>/dev/null || uptime)
    print_status "INFO" "Uptime: $uptime_info"
}

# Check RAM and memory information
check_memory() {
    echo -e "\n${BLUE}=== Memory Information ===${NC}"
    
    # Total RAM
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_ram_gb=$((total_ram_kb / 1024 / 1024))
    total_ram_mb=$((total_ram_kb / 1024))
    
    print_status "INFO" "Total RAM: ${total_ram_gb}GB (${total_ram_mb}MB)"
    
    # Available RAM
    available_ram_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    available_ram_gb=$((available_ram_kb / 1024 / 1024))
    
    print_status "INFO" "Available RAM: ${available_ram_gb}GB"
}

# Check swap information
check_swap() {
    echo -e "\n${BLUE}=== Swap Information ===${NC}"
    
    # Get total RAM in MB for comparison
    total_ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    
    # Check if swap is enabled
    swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    
    if [[ $swap_total -eq 0 ]]; then
        print_status "ERROR" "No swap space detected!"
        print_status "ERROR" "Hibernation requires swap space at least equal to RAM size"
        return 1
    fi
    
    swap_total_mb=$((swap_total / 1024))
    print_status "INFO" "Total swap: ${swap_total_mb}MB"
    
    # Check if swap size is adequate for hibernation
    if [[ $swap_total_mb -ge $total_ram_mb ]]; then
        print_status "OK" "Swap size is adequate for hibernation (${swap_total_mb}MB >= ${total_ram_mb}MB RAM)"
    else
        print_status "WARNING" "Swap size may be insufficient for hibernation"
        print_status "WARNING" "Recommended: Swap >= RAM size (${total_ram_mb}MB)"
        print_status "WARNING" "Current swap: ${swap_total_mb}MB"
    fi
    
    # Show swap devices
    print_status "INFO" "Swap devices:"
    while IFS= read -r line; do
        echo "    $line"
    done < <(swapon --show 2>/dev/null || echo "    No swap devices shown")
}

# Check secure boot status
check_secure_boot() {
    echo -e "\n${BLUE}=== Secure Boot Status ===${NC}"
    
    if [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]]; then
        secure_boot_status=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | awk '{print $NF}')
        if [[ $secure_boot_status -eq 1 ]]; then
            print_status "WARNING" "Secure Boot is ENABLED"
            print_status "WARNING" "This may interfere with hibernation on some systems"
        else
            print_status "OK" "Secure Boot is disabled"
        fi
    elif [[ -d /sys/firmware/efi ]]; then
        print_status "INFO" "UEFI system detected, but Secure Boot status unclear"
    else
        print_status "INFO" "Legacy BIOS system (not UEFI)"
    fi
}

# Check hibernation kernel support
check_hibernation_support() {
    echo -e "\n${BLUE}=== Hibernation Support ===${NC}"
    
    # Check if hibernation is supported in kernel
    if [[ -f /sys/power/state ]]; then
        power_states=$(cat /sys/power/state)
        print_status "INFO" "Available power states: $power_states"
        
        if echo "$power_states" | grep -q "disk"; then
            print_status "OK" "Hibernation (disk) is supported by kernel"
        else
            print_status "ERROR" "Hibernation (disk) is NOT supported by kernel"
        fi
    else
        print_status "ERROR" "Cannot access /sys/power/state"
    fi
    
    # Check current hibernation mode
    if [[ -f /sys/power/disk ]]; then
        hibernation_modes=$(cat /sys/power/disk)
        print_status "INFO" "Available hibernation modes: $hibernation_modes"
    fi
}

# Check systemd and power management
check_systemd() {
    echo -e "\n${BLUE}=== Power Management ===${NC}"
    
    # Check if systemd is running
    if systemctl --version >/dev/null 2>&1; then
        print_status "OK" "systemd is available"
        
        # Check logind configuration
        if [[ -f /etc/systemd/logind.conf ]]; then
            hibernate_key=$(grep -E "^HandleHibernateKey=" /etc/systemd/logind.conf 2>/dev/null || echo "")
            hibernate_lid=$(grep -E "^HandleLidSwitch=" /etc/systemd/logind.conf 2>/dev/null || echo "")
            
            if [[ -n "$hibernate_key" ]]; then
                print_status "INFO" "Hibernate key setting: $hibernate_key"
            fi
            if [[ -n "$hibernate_lid" ]]; then
                print_status "INFO" "Lid switch setting: $hibernate_lid"
            fi
        fi
        
        # Check if hibernate target exists
        if systemctl list-unit-files | grep -q hibernate.target; then
            print_status "OK" "hibernate.target is available"
        else
            print_status "WARNING" "hibernate.target may not be available"
        fi
    else
        print_status "WARNING" "systemd not detected - using different init system"
    fi
}

# Check file system and mount points
check_filesystem() {
    echo -e "\n${BLUE}=== Filesystem Information ===${NC}"
    
    # Check root filesystem
    root_fs=$(df -T / | tail -n 1 | awk '{print $2}')
    print_status "INFO" "Root filesystem: $root_fs"
    
    # Check for encrypted filesystems
    if command -v lsblk >/dev/null 2>&1; then
        encrypted_devices=$(lsblk -f | grep -i crypt | wc -l)
        if [[ $encrypted_devices -gt 0 ]]; then
            print_status "INFO" "Encrypted devices detected: $encrypted_devices"
            print_status "WARNING" "Encrypted systems may need additional hibernation setup"
        fi
    fi
}

# Check disk space and storage information
check_disk_space() {
    echo -e "\n${BLUE}=== Disk Space Information ===${NC}"
    
    # Get RAM size for swap recommendations
    total_ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    recommended_swap_gb=$((total_ram_mb / 1024 + 1))
    
    # Check root filesystem space
    root_space=$(df -h / | tail -n 1)
    root_total=$(echo $root_space | awk '{print $2}')
    root_used=$(echo $root_space | awk '{print $3}')
    root_avail=$(echo $root_space | awk '{print $4}')
    root_percent=$(echo $root_space | awk '{print $5}')
    
    print_status "INFO" "Root filesystem (/) space:"
    echo "    Total: $root_total, Used: $root_used, Available: $root_avail ($root_percent used)"
    
    # Convert available space to MB for comparison
    root_avail_mb=$(df / | tail -n 1 | awk '{print int($4/1024)}')
    
    # Check if there's enough space for recommended swap
    if [[ $root_avail_mb -ge $((recommended_swap_gb * 1024)) ]]; then
        print_status "OK" "Sufficient space for ${recommended_swap_gb}GB swap file (${root_avail_mb}MB available)"
    else
        print_status "WARNING" "Limited space for optimal swap file"
        print_status "WARNING" "Available: ${root_avail_mb}MB, Recommended swap: ${recommended_swap_gb}GB ($((recommended_swap_gb * 1024))MB)"
    fi
    
    # Check current swapfile location and size if it exists
    if [[ -f /swapfile ]]; then
        swapfile_size=$(ls -lh /swapfile | awk '{print $5}')
        swapfile_location=$(df /swapfile | tail -n 1 | awk '{print $1}')
        print_status "INFO" "Current swapfile: /swapfile (${swapfile_size}) on ${swapfile_location}"
    elif [[ -f /swap.img ]]; then
        swapfile_size=$(ls -lh /swap.img | awk '{print $5}')
        swapfile_location=$(df /swap.img | tail -n 1 | awk '{print $1}')
        print_status "INFO" "Current swapfile: /swap.img (${swapfile_size}) on ${swapfile_location}"
    fi
    
    # Show all mounted filesystems with space info
    print_status "INFO" "All mounted filesystems:"
    echo "    Filesystem      Size  Used Avail Use% Mounted on"
    df -h | grep -E "^/dev|^tmpfs" | head -10 | while read line; do
        echo "    $line"
    done
    
    # Show disk devices and their sizes
    if command -v lsblk >/dev/null 2>&1; then
        print_status "INFO" "Block devices:"
        lsblk -d -o NAME,SIZE,TYPE,MODEL | while read line; do
            echo "    $line"
        done
    fi
    
    # Check for potential locations for swapfile
    print_status "INFO" "Swap file recommendations:"
    echo "    • For ${total_ram_mb}MB RAM, recommend ${recommended_swap_gb}GB swap"
    echo "    • Current root filesystem has ${root_avail}B available"
    echo "    • Swapfile location options:"
    echo "      - /swapfile (most common)"
    echo "      - /swap.img (alternative)"
    echo "      - Custom location with sufficient space"
    
    # Warn about low disk space
    root_used_percent=$(echo $root_percent | tr -d '%')
    if [[ $root_used_percent -gt 85 ]]; then
        print_status "WARNING" "Root filesystem is ${root_percent} full - consider freeing space before creating large swapfile"
    fi
}

# Check hardware information
check_hardware() {
    echo -e "\n${BLUE}=== Hardware Information ===${NC}"
    
    # CPU information
    if [[ -f /proc/cpuinfo ]]; then
        cpu_model=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d: -f2 | xargs)
        cpu_cores=$(nproc)
        print_status "INFO" "CPU: $cpu_model"
        print_status "INFO" "CPU cores: $cpu_cores"
    fi
    
    # Check for laptops (battery presence)
    if [[ -d /sys/class/power_supply ]]; then
        batteries=$(find /sys/class/power_supply -name "BAT*" 2>/dev/null | wc -l)
        if [[ $batteries -gt 0 ]]; then
            print_status "INFO" "Laptop detected ($batteries battery/batteries)"
        else
            print_status "INFO" "Desktop system (no batteries detected)"
        fi
    fi
}

# Check existing hibernation configuration
check_existing_config() {
    echo -e "\n${BLUE}=== Existing Configuration ===${NC}"
    
    # Check GRUB configuration
    if [[ -f /etc/default/grub ]]; then
        if grep -q "resume=" /etc/default/grub; then
            resume_param=$(grep "resume=" /etc/default/grub)
            print_status "INFO" "GRUB resume parameter found: $resume_param"
        else
            print_status "INFO" "No resume parameter in GRUB configuration"
        fi
    fi
    
    # Check initramfs tools
    if command -v update-initramfs >/dev/null 2>&1; then
        print_status "OK" "update-initramfs available (Debian/Ubuntu)"
    elif command -v mkinitcpio >/dev/null 2>&1; then
        print_status "OK" "mkinitcpio available (Arch)"
    elif command -v dracut >/dev/null 2>&1; then
        print_status "OK" "dracut available (RHEL/Fedora)"
    else
        print_status "WARNING" "No known initramfs tool detected"
    fi
}

# Analyze prerequisites and identify issues
analyze_prerequisites() {
    echo -e "\n${BLUE}=== Prerequisites Analysis ===${NC}"
    
    local issues_found=0
    local critical_issues=0
    local warnings=0
    
    # Get current values for analysis
    local total_ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    local swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    local swap_total_mb=$((swap_total / 1024))
    local recommended_swap_gb=$((total_ram_mb / 1024 + 1))
    
    # Check swap size issue
    if [[ $swap_total_mb -lt $total_ram_mb ]]; then
        print_status "ERROR" "Insufficient swap space for hibernation"
        echo "    Current swap: ${swap_total_mb}MB"
        echo "    Required: ${total_ram_mb}MB (equal to RAM)"
        echo "    Recommended: ${recommended_swap_gb}GB"
        critical_issues=$((critical_issues + 1))
        issues_found=$((issues_found + 1))
        
        # Set global variable for swap issue
        SWAP_INSUFFICIENT=1
        CURRENT_SWAP_MB=$swap_total_mb
        REQUIRED_SWAP_MB=$total_ram_mb
        RECOMMENDED_SWAP_GB=$recommended_swap_gb
    fi
    
    # Check if hibernation is supported
    if [[ -f /sys/power/state ]]; then
        if ! grep -q "disk" /sys/power/state; then
            print_status "ERROR" "Hibernation not supported by kernel"
            critical_issues=$((critical_issues + 1))
            issues_found=$((issues_found + 1))
        fi
    else
        print_status "ERROR" "Cannot access power state information"
        critical_issues=$((critical_issues + 1))
        issues_found=$((issues_found + 1))
    fi
    
    # Check for secure boot warnings
    if [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]]; then
        local secure_boot_status=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | awk '{print $NF}')
        if [[ $secure_boot_status -eq 1 ]]; then
            print_status "WARNING" "Secure Boot enabled - may cause hibernation issues"
            warnings=$((warnings + 1))
        fi
    fi
    
    # Check GRUB configuration
    if [[ -f /etc/default/grub ]] && ! grep -q "resume=" /etc/default/grub; then
        print_status "WARNING" "GRUB not configured for hibernation resume"
        warnings=$((warnings + 1))
        
        # Set global variable for GRUB issue
        GRUB_NOT_CONFIGURED=1
    fi
    
    # Check disk space for swap expansion
    local root_avail_mb=$(df / | tail -n 1 | awk '{print int($4/1024)}')
    if [[ $root_avail_mb -lt $((recommended_swap_gb * 1024)) ]]; then
        print_status "WARNING" "Limited disk space for optimal swap file"
        warnings=$((warnings + 1))
    fi
    
    # Check KDE polkit configuration (only for KDE desktops)
    if [[ -n "$XDG_CURRENT_DESKTOP" ]] && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        if [[ ! -f /etc/polkit-1/rules.d/10-enable-hibernate.rules ]]; then
            print_status "WARNING" "KDE polkit rules not configured for hibernation menu"
            warnings=$((warnings + 1))
            
            # Set global variable for KDE polkit issue
            KDE_POLKIT_NEEDED=1
        else
            print_status "OK" "KDE polkit rules configured for hibernation"
        fi
    fi
    
    # Summary of issues
    echo
    if [[ $critical_issues -eq 0 && $warnings -eq 0 ]]; then
        print_status "OK" "All prerequisites met for hibernation setup"
    else
        if [[ $critical_issues -gt 0 ]]; then
            print_status "ERROR" "Found $critical_issues critical issue(s) that must be fixed"
        fi
        if [[ $warnings -gt 0 ]]; then
            print_status "WARNING" "Found $warnings warning(s) that should be addressed"
        fi
    fi
    
    # Set global variable instead of return
    CRITICAL_ISSUES_COUNT=$critical_issues
}

# Prompt user to fix swap file size
prompt_fix_swap() {
    if [[ $SWAP_INSUFFICIENT -eq 1 ]]; then
        echo -e "\n${YELLOW}=== Swap File Fix Required ===${NC}"
        echo "Your system has insufficient swap space for hibernation:"
        echo "  Current swap: ${CURRENT_SWAP_MB}MB"
        echo "  Required: ${REQUIRED_SWAP_MB}MB (equal to RAM)"
        echo "  Recommended: ${RECOMMENDED_SWAP_GB}GB"
        echo
        echo "To fix this, we need to resize your swap file."
        echo "This is safe and will not lose data, but requires root privileges."
        echo
        
        # Check if running in interactive mode
        if [[ -t 0 ]]; then
            # Interactive mode
            if [[ $EUID -eq 0 ]]; then
                read -p "Would you like to fix the swap file size now? (y/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Check if we'll also be fixing GRUB later
                    if [[ $GRUB_NOT_CONFIGURED -eq 1 ]]; then
                        echo
                        print_status "INFO" "Note: After fixing swap, you'll also be prompted to fix GRUB configuration."
                        echo
                    fi
                    fix_swap_size
                else
                    print_status "INFO" "Swap file fix declined. Hibernation setup cannot proceed."
                    echo "Run this script again after fixing the swap file size."
                fi
            else
                # Non-root user - just show commands without prompting
                show_swap_fix_commands
            fi
        else
            # Non-interactive mode - just show the commands
            print_status "INFO" "Non-interactive mode detected."
            if [[ $EUID -eq 0 ]]; then
                print_status "INFO" "Run this script interactively to automatically fix the swap file."
            else
                show_swap_fix_commands
            fi
        fi
    fi
}

# Prompt user to fix GRUB configuration
prompt_fix_grub() {
    if [[ $GRUB_NOT_CONFIGURED -eq 1 ]]; then
        echo -e "\n${YELLOW}=== GRUB Configuration Fix Required ===${NC}"
        echo "Your GRUB bootloader is not configured for hibernation resume."
        echo "This is required to restore your system state after hibernation."
        echo
        echo "The fix involves:"
        echo "  1. Adding resume parameter to GRUB configuration"
        echo "  2. Updating GRUB bootloader"
        echo "  3. Updating initramfs"
        echo
        
        # Check if running in interactive mode
        if [[ -t 0 ]]; then
            # Interactive mode
            if [[ $EUID -eq 0 ]]; then
                read -p "Would you like to fix the GRUB configuration now? (y/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    fix_grub_config
                else
                    print_status "INFO" "GRUB fix declined. Hibernation will not work properly."
                    echo "You can run this script again later to configure GRUB."
                fi
            else
                # Non-root user - just show commands without prompting
                show_grub_fix_commands
            fi
        else
            # Non-interactive mode - just show the commands
            print_status "INFO" "Non-interactive mode detected."
            if [[ $EUID -eq 0 ]]; then
                print_status "INFO" "Run this script interactively to automatically fix GRUB."
            else
                show_grub_fix_commands
            fi
        fi
    fi
}

# Prompt user to fix KDE polkit configuration
prompt_fix_kde_polkit() {
    if [[ $KDE_POLKIT_NEEDED -eq 1 ]]; then
        echo -e "\n${YELLOW}=== KDE Polkit Configuration Required ===${NC}"
        echo "KDE polkit rules are not configured for hibernation menu."
        echo "This is required for hibernation options to appear in KDE's power menu."
        echo
        echo "The fix involves:"
        echo "  1. Creating polkit rules file for hibernation permissions"
        echo "  2. Enabling hibernation and suspend-then-hibernate in KDE"
        echo
        
        # Check if running in interactive mode
        if [[ -t 0 ]]; then
            # Interactive mode
            if [[ $EUID -eq 0 ]]; then
                read -p "Would you like to configure KDE polkit rules now? (y/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    configure_kde_hibernation
                else
                    print_status "INFO" "KDE polkit configuration declined."
                    echo "Hibernation will work via terminal but not appear in KDE power menu."
                fi
            else
                # Non-root user - just show commands without prompting
                show_kde_polkit_commands
            fi
        else
            # Non-interactive mode - just show the commands
            print_status "INFO" "Non-interactive mode detected."
            if [[ $EUID -eq 0 ]]; then
                print_status "INFO" "Run this script interactively to automatically configure KDE polkit."
            else
                show_kde_polkit_commands
            fi
        fi
    fi
}

# Show commands to fix KDE polkit (for non-root users)
show_kde_polkit_commands() {
    echo -e "\n${BLUE}=== Commands to Configure KDE Polkit Rules ===${NC}"
    echo "Run this command as root (with sudo) to enable hibernation in KDE power menu:"
    echo
    echo -e "${GREEN}# Create KDE polkit rules for hibernation menu${NC}"
    echo "sudo tee /etc/polkit-1/rules.d/10-enable-hibernate.rules << 'EOF'"
    echo "polkit.addRule(function(action, subject) {"
    echo "    if (action.id == \"org.freedesktop.login1.hibernate\" ||"
    echo "        action.id == \"org.freedesktop.login1.hibernate-multiple-sessions\" ||"
    echo "        action.id == \"org.freedesktop.upower.hibernate\" ||"
    echo "        action.id == \"org.freedesktop.login1.handle-hibernate-key\" ||"
    echo "        action.id == \"org.freedesktop.login1.hibernate-ignore-inhibit\")"
    echo "    {"
    echo "        return polkit.Result.YES;"
    echo "    }"
    echo "});"
    echo "EOF"
    echo
    print_status "INFO" "After running this command, restart KDE session or reboot."
    print_status "INFO" "Then run this script again to verify the fix. Or run this script as root to fix the KDE polkit configuration."
}

# Show commands to fix swap size (for non-root users)
show_swap_fix_commands() {
    echo -e "\n${BLUE}=== Commands to Fix Swap File Size ===${NC}"
    echo "Run these commands as root (with sudo) to resize your swap file:"
    echo
    echo -e "${GREEN}# Turn off current swap${NC}"
    echo "sudo swapoff /swapfile"
    echo
    echo -e "${GREEN}# Create new ${RECOMMENDED_SWAP_GB}GB swap file${NC}"
    echo "sudo fallocate -l ${RECOMMENDED_SWAP_GB}G /swapfile"
    echo
    echo -e "${GREEN}# Set correct permissions${NC}"
    echo "sudo chmod 600 /swapfile"
    echo
    echo -e "${GREEN}# Initialize swap file${NC}"
    echo "sudo mkswap /swapfile"
    echo
    echo -e "${GREEN}# Enable the swap file${NC}"
    echo "sudo swapon /swapfile"
    echo
    echo -e "${GREEN}# Verify swap is working${NC}"
    echo "sudo swapon --show"
    echo "free -h"
    echo
    print_status "INFO" "After running these commands, run this script again to verify the fix. Or run this script as root to fix the swap file size."
}

# Actually fix swap size (for root users)
fix_swap_size() {
    echo -e "\n${BLUE}=== Fixing Swap File Size ===${NC}"
    
    echo "About to perform the following operations:"
    echo "  1. Turn off current swap (swapoff /swapfile)"
    echo "  2. Create new ${RECOMMENDED_SWAP_GB}GB swap file (fallocate -l ${RECOMMENDED_SWAP_GB}G /swapfile)"
    echo "  3. Set permissions (chmod 600 /swapfile)"
    echo "  4. Initialize swap (mkswap /swapfile)"
    echo "  5. Enable new swap (swapon /swapfile)"
    echo
    print_status "WARNING" "This will temporarily disable swap during the resize process."
    echo
    
    read -p "Are you sure you want to proceed with resizing the swap file? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "INFO" "Swap file resize cancelled by user."
        return 1
    fi
    
    print_status "INFO" "Turning off current swap..."
    if swapoff /swapfile; then
        print_status "OK" "Swap disabled"
    else
        print_status "ERROR" "Failed to disable swap"
        return 1
    fi
    
    print_status "INFO" "Creating ${RECOMMENDED_SWAP_GB}GB swap file..."
    if fallocate -l ${RECOMMENDED_SWAP_GB}G /swapfile; then
        print_status "OK" "Swap file created"
    else
        print_status "ERROR" "Failed to create swap file"
        # Try to re-enable old swap
        swapon /swapfile 2>/dev/null
        return 1
    fi
    
    print_status "INFO" "Setting permissions..."
    chmod 600 /swapfile
    
    print_status "INFO" "Initializing swap file..."
    if mkswap /swapfile; then
        print_status "OK" "Swap file initialized"
    else
        print_status "ERROR" "Failed to initialize swap file"
        return 1
    fi
    
    print_status "INFO" "Enabling swap..."
    if swapon /swapfile; then
        print_status "OK" "Swap enabled successfully"
    else
        print_status "ERROR" "Failed to enable swap"
        return 1
    fi
    
    # Verify the fix
    local new_swap_mb=$(grep SwapTotal /proc/meminfo | awk '{print int($2/1024)}')
    print_status "OK" "Swap file resized successfully to ${new_swap_mb}MB"
    
    echo
    print_status "INFO" "Swap status:"
    swapon --show
    free -h
}

# Show commands to fix GRUB configuration (for non-root users)
show_grub_fix_commands() {
    echo -e "\n${BLUE}=== Commands to Fix GRUB Configuration ===${NC}"
    echo "Run these commands as root (with sudo) to configure GRUB for hibernation:"
    echo
    
    # Determine swap device/file info
    local swap_device=""
    local resume_param=""
    
    if [[ -f /swapfile ]]; then
        # Using swapfile - need to find the device and offset
        local swap_file_device=$(df /swapfile | tail -n 1 | awk '{print $1}')
        local swap_file_uuid=$(blkid -s UUID -o value "$swap_file_device")
        
        echo -e "${GREEN}# Find the swap file offset${NC}"
        echo "sudo filefrag -v /swapfile | awk '\$1==\"0:\" {print \$4}' | sed 's/\\.\\.//'"
        echo
        echo -e "${GREEN}# Add resume parameter to GRUB (replace OFFSET with the number from above)${NC}"
        echo "sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 resume=UUID=${swap_file_uuid} resume_offset=OFFSET\"/' /etc/default/grub"
    else
        echo -e "${GREEN}# Add resume parameter to GRUB${NC}"
        echo "# First, find your swap device:"
        echo "swapon --show"
        echo "# Then add resume parameter (replace /dev/sdXY with your swap device):"
        echo "sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 resume=\\/dev\\/sdXY\"/' /etc/default/grub"
    fi
    
    echo
    echo -e "${GREEN}# Update GRUB configuration${NC}"
    echo "sudo update-grub"
    echo
    echo -e "${GREEN}# Update initramfs${NC}"
    echo "sudo update-initramfs -u -k all"
    echo
    echo -e "${GREEN}# Verify GRUB configuration${NC}"
    echo "grep resume /etc/default/grub"
    echo
    print_status "INFO" "After running these commands, run this script again to verify the fix. Or run this script as root to fix the GRUB configuration."
}

# Actually fix GRUB configuration (for root users)
fix_grub_config() {
    echo -e "\n${BLUE}=== Fixing GRUB Configuration ===${NC}"
    
    echo "About to perform the following operations:"
    echo "  1. Backup current GRUB configuration"
    echo "  2. Calculate swap file offset (if using swap file)"
    echo "  3. Add resume parameter to GRUB configuration"
    echo "  4. Update GRUB bootloader (update-grub)"
    echo "  5. Update initramfs (update-initramfs -u -k all)"
    echo
    print_status "WARNING" "This will modify your bootloader configuration."
    print_status "WARNING" "A backup will be created before making changes."
    echo
    
    read -p "Are you sure you want to proceed with GRUB configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "INFO" "GRUB configuration cancelled by user."
        return 1
    fi
    
    # Determine swap configuration
    local swap_device=""
    local resume_param=""
    
    if [[ -f /swapfile ]]; then
        print_status "INFO" "Configuring GRUB for swap file hibernation..."
        
        # Get swap file device and UUID
        local swap_file_device=$(df /swapfile | tail -n 1 | awk '{print $1}')
        local swap_file_uuid=$(blkid -s UUID -o value "$swap_file_device")
        
        if [[ -z "$swap_file_uuid" ]]; then
            print_status "ERROR" "Could not determine UUID for swap file device"
            return 1
        fi
        
        print_status "INFO" "Swap file is on device: $swap_file_device (UUID: $swap_file_uuid)"
        
        # Get swap file offset
        print_status "INFO" "Calculating swap file offset..."
        local swap_offset=$(filefrag -v /swapfile | awk '$1=="0:" {print $4}' | sed 's/\.\.//')
        
        if [[ -z "$swap_offset" ]]; then
            print_status "ERROR" "Could not determine swap file offset"
            return 1
        fi
        
        print_status "INFO" "Swap file offset: $swap_offset"
        resume_param="resume=UUID=$swap_file_uuid resume_offset=$swap_offset"
        
    else
        # Using swap partition
        local swap_partition=$(swapon --show --noheadings | head -n 1 | awk '{print $1}')
        if [[ -n "$swap_partition" ]]; then
            print_status "INFO" "Configuring GRUB for swap partition: $swap_partition"
            resume_param="resume=$swap_partition"
        else
            print_status "ERROR" "No swap device found"
            return 1
        fi
    fi
    
    # Backup GRUB configuration
    print_status "INFO" "Backing up GRUB configuration..."
    cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)
    
    # Check if resume parameter already exists
    if grep -q "resume=" /etc/default/grub; then
        print_status "INFO" "Resume parameter already exists, updating..."
        # Remove existing resume parameters
        sed -i 's/ resume=[^ ]*//g' /etc/default/grub
        sed -i 's/ resume_offset=[^ ]*//g' /etc/default/grub
    fi
    
    # Add resume parameter to GRUB_CMDLINE_LINUX_DEFAULT
    print_status "INFO" "Adding resume parameter to GRUB..."
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
        # Add to existing line
        sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 $resume_param\"/" /etc/default/grub
    else
        # Add new line
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$resume_param\"" >> /etc/default/grub
    fi
    
    # Clean up any double spaces
    sed -i 's/  / /g' /etc/default/grub
    sed -i 's/=" /="/g' /etc/default/grub
    
    echo
    print_status "INFO" "GRUB configuration file has been modified."
    print_status "INFO" "Resume parameter: $resume_param"
    echo
    echo "The following commands will now be executed to apply the changes:"
    echo "  - update-grub (to rebuild GRUB configuration)"
    echo "  - update-initramfs -u -k all (to include resume support)"
    echo
    
    read -p "Proceed with updating GRUB and initramfs? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "WARNING" "GRUB/initramfs update cancelled."
        print_status "WARNING" "Configuration file modified but not applied."
        print_status "INFO" "You can manually run 'update-grub' and 'update-initramfs -u -k all' later."
        return 1
    fi
    
    print_status "INFO" "Updating GRUB bootloader..."
    if update-grub; then
        print_status "OK" "GRUB updated successfully"
    else
        print_status "ERROR" "Failed to update GRUB"
        return 1
    fi
    
    print_status "INFO" "Updating initramfs..."
    if update-initramfs -u -k all; then
        print_status "OK" "Initramfs updated successfully"
    else
        print_status "ERROR" "Failed to update initramfs"
        return 1
    fi
    
    echo
    print_status "OK" "GRUB configuration completed successfully"
    print_status "INFO" "Current GRUB resume configuration:"
    grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
}

# Configure polkit rules for KDE hibernation menu
configure_kde_hibernation() {
    echo -e "\n${BLUE}=== Configuring KDE Hibernation Menu ===${NC}"
    
    local polkit_rules_file="/etc/polkit-1/rules.d/10-enable-hibernate.rules"
    
    print_status "INFO" "Creating polkit rules for KDE hibernation menu..."
    
    # Create the polkit rules file
    cat > "$polkit_rules_file" << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.upower.hibernate" ||
        action.id == "org.freedesktop.login1.handle-hibernate-key" ||
        action.id == "org.freedesktop.login1.hibernate-ignore-inhibit")
    {
        return polkit.Result.YES;
    }
});
EOF
    
    if [[ $? -eq 0 ]]; then
        print_status "OK" "Created polkit rules file: $polkit_rules_file"
        print_status "INFO" "This enables hibernate option in KDE power menu"
        print_status "INFO" "You may need to restart KDE session or reboot for changes to take effect"
    else
        print_status "ERROR" "Failed to create polkit rules file"
        return 1
    fi
}

# Main execution
main() {
    # Initialize global variables for issue tracking
    SWAP_INSUFFICIENT=0
    CURRENT_SWAP_MB=0
    REQUIRED_SWAP_MB=0
    RECOMMENDED_SWAP_GB=0
    CRITICAL_ISSUES_COUNT=0
    GRUB_NOT_CONFIGURED=0
    KDE_POLKIT_NEEDED=0
    
    check_root
    check_system_info
    check_memory
    check_swap
    check_secure_boot
    check_hibernation_support
    check_systemd
    check_filesystem
    check_disk_space
    check_hardware
    check_existing_config
    
    # Analyze all prerequisites and identify critical issues
    analyze_prerequisites
    local critical_issues=$CRITICAL_ISSUES_COUNT
    
    # If there are critical issues, offer to fix them
    if [[ $critical_issues -gt 0 ]]; then
        # Focus on swap issues first as they're most common and fixable
        prompt_fix_swap
    fi
    
    # Check for GRUB configuration issues (can be fixed regardless of critical issues)
    if [[ $GRUB_NOT_CONFIGURED -eq 1 ]]; then
        prompt_fix_grub
    fi
    
    # Check for KDE polkit configuration issues (only for KDE desktops)
    if [[ $KDE_POLKIT_NEEDED -eq 1 ]]; then
        prompt_fix_kde_polkit
    fi
    
    # Final status message
    if [[ $critical_issues -eq 0 && $GRUB_NOT_CONFIGURED -eq 0 && $KDE_POLKIT_NEEDED -eq 0 ]]; then
        echo
        echo -e "${GREEN}=== All Prerequisites Met! ===${NC}"
        print_status "OK" "Your system is ready for hibernation"
        echo
        echo "Next steps:"
        echo "1. Test hibernation: sudo systemctl hibernate"
        echo "2. Configure power management settings as needed"
        echo "3. Set up hibernation triggers (lid close, power button, etc.)"
    fi
    
    echo
    echo -e "${BLUE}=== Summary ===${NC}"
    print_status "INFO" "System prerequisites check completed"
    
    if [[ $critical_issues -gt 0 ]]; then
        print_status "INFO" "Critical issues found that must be resolved before hibernation setup"
    else
        print_status "INFO" "System meets all requirements for hibernation"
    fi
}

# Run the main function
main "$@"

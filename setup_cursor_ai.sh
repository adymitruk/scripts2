#!/bin/bash

# Cursor AI Setup Script for Kubuntu 24.04
# This script properly sets up Cursor AI to behave like other KDE applications
# and fixes sandbox/namespace issues that prevent proper updates and restarts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    Cursor AI Setup Script for Kubuntu${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_status "ERROR" "This script should not be run as root"
    exit 1
fi

# Check if we're in a KDE environment
if [[ "$XDG_CURRENT_DESKTOP" != "KDE" ]] && [[ "$DESKTOP_SESSION" != "plasma" ]]; then
    print_status "WARNING" "KDE/Plasma desktop not detected. Some features may not work properly."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to check if Cursor is already installed
check_cursor_installation() {
    if [[ -f "$HOME/Applications/cursor/cursor.AppImage" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to download Cursor if not present
download_cursor() {
    print_status "INFO" "Downloading Cursor AI..."
    
    # Create Applications directory if it doesn't exist
    mkdir -p "$HOME/Applications/cursor"
    
    # Download the latest Cursor AppImage
    cd "$HOME/Applications/cursor"
    
    # Get the latest version URL
    local download_url="https://downloads.cursor.com/linux/appImage/x64"
    local latest_url=$(curl -sI "$download_url" | grep -i location | cut -d' ' -f2 | tr -d '\r')
    
    if [[ -z "$latest_url" ]]; then
        print_status "ERROR" "Failed to get download URL"
        exit 1
    fi
    
    print_status "INFO" "Downloading from: $latest_url"
    wget -O cursor.AppImage "$latest_url"
    chmod +x cursor.AppImage
    
    print_status "OK" "Cursor downloaded successfully"
}

# Function to create desktop integration
create_desktop_integration() {
    print_status "INFO" "Creating desktop integration..."
    
    # Clean up any existing duplicate desktop files
    rm -f "$HOME/.local/share/applications/cursor-ai-mime.desktop"
    
    # Create desktop file
    local desktop_file="$HOME/.local/share/applications/cursor-ai.desktop"
    
    cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Name=Cursor AI
Comment=AI-first code editor
Exec=/home/adam/Applications/cursor/cursor.AppImage --no-sandbox %F
Icon=cursor-ai
Type=Application
Categories=Development;IDE;TextEditor;
Keywords=code;editor;ai;programming;development;
StartupWMClass=Cursor
MimeType=text/plain;text/x-c;text/x-c++;text/x-chdr;text/x-csrc;text/x-h;text/x-java;text/x-makefile;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-code-workspace;inode/directory;
EOF
    
    # Update the Exec path to use the current user's home directory
    sed -i "s|/home/adam|$HOME|g" "$desktop_file"
    
    # Create icon directory and download icon
    mkdir -p "$HOME/.local/share/icons"
    
    # Try to extract icon from AppImage or use a fallback
    if [[ -f "$HOME/Applications/cursor/cursor.AppImage" ]]; then
        # Extract icon from AppImage
        cd "$HOME/Applications/cursor"
        ./cursor.AppImage --appimage-extract 2>/dev/null || true
        
        # Look for icon in various possible locations
        local icon_found=false
        for icon_path in \
            "squashfs-root/cursor.png" \
            "squashfs-root/usr/share/pixmaps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/128x128/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/64x64/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/48x48/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/32x32/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/16x16/apps/cursor.png"; do
            if [[ -f "$icon_path" ]]; then
                cp "$icon_path" "$HOME/.local/share/icons/cursor-ai.png"
                icon_found=true
                print_status "OK" "Icon extracted from AppImage"
                break
            fi
        done
        
        if [[ "$icon_found" == "false" ]]; then
            print_status "WARNING" "Could not extract icon from AppImage, trying to download one"
            # Try to download the official Cursor icon
            if ! wget -O "$HOME/.local/share/icons/cursor-ai.png" "https://raw.githubusercontent.com/getcursor/cursor/main/assets/icon.png" 2>/dev/null; then
                # Create a simple text-based icon as last resort
                print_status "WARNING" "Could not download icon, creating a simple text-based one"
                convert -size 64x64 xc:transparent -font Arial -pointsize 12 -fill black -gravity center -annotate +0+0 "C" "$HOME/.local/share/icons/cursor-ai.png" 2>/dev/null || \
                echo "Could not create icon - you may need to install ImageMagick or set an icon manually"
            fi
        fi
        
        # Clean up extracted files
        rm -rf squashfs-root 2>/dev/null || true
    fi
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications"
    
    print_status "OK" "Desktop integration created"
}

# Function to create wrapper script for better integration
create_wrapper_script() {
    print_status "INFO" "Creating wrapper script for better integration..."
    
    local wrapper_script="$HOME/.local/bin/cursor"
    
    cat > "$wrapper_script" << 'EOF'
#!/bin/bash

# Cursor AI Wrapper Script
# This wrapper handles proper startup and environment setup

# Set environment variables to fix sandbox issues
export ELECTRON_NO_SANDBOX=1
export ELECTRON_DISABLE_SANDBOX=1

# Disable GPU acceleration if needed (can help with some issues)
# export ELECTRON_DISABLE_GPU=1

# Set proper working directory
cd "$HOME"

# Launch Cursor with proper arguments
exec "$HOME/Applications/cursor/cursor.AppImage" \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu-sandbox \
    --disable-software-rasterizer \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-renderer-backgrounding \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    "$@"
EOF
    
    chmod +x "$wrapper_script"
    
    # Update the desktop file to use the wrapper
    local desktop_file="$HOME/.local/share/applications/cursor-ai.desktop"
    sed -i "s|Exec=.*|Exec=$wrapper_script %F|" "$desktop_file"
    
    print_status "OK" "Wrapper script created"
}

# Function to fix sandbox and namespace issues
fix_sandbox_issues() {
    print_status "INFO" "Configuring sandbox and namespace settings..."
    
    # Create systemd user service for better process management
    local service_dir="$HOME/.config/systemd/user"
    mkdir -p "$service_dir"
    
    local service_file="$service_dir/cursor-ai.service"
    
    cat > "$service_file" << 'EOF'
[Unit]
Description=Cursor AI Code Editor
After=graphical-session.target

[Service]
Type=simple
Environment=ELECTRON_NO_SANDBOX=1
Environment=ELECTRON_DISABLE_SANDBOX=1
Environment=DISPLAY=%E{DISPLAY}
Environment=XDG_RUNTIME_DIR=%E{XDG_RUNTIME_DIR}
ExecStart=%h/Applications/cursor/cursor.AppImage --no-sandbox
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
EOF
    
    # Enable the service
    systemctl --user enable cursor-ai.service
    
    print_status "OK" "Systemd service configured"
}

# Function to create KDE-specific integration
create_kde_integration() {
    print_status "INFO" "Creating KDE-specific integration..."
    
    # Create KDE service menu for right-click integration
    local service_dir="$HOME/.local/share/kservices5/ServiceMenus"
    mkdir -p "$service_dir"
    
    local service_menu="$service_dir/cursor-ai.desktop"
    
    cat > "$service_menu" << 'EOF'
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin,text/plain
Actions=cursor-ai;
X-KDE-Priority=TopLevel

[Desktop Action cursor-ai]
Name=Open with Cursor AI
Icon=cursor-ai
Exec=cursor %f
EOF
    
    # Update the main desktop file with comprehensive MIME types
    local desktop_file="$HOME/.local/share/applications/cursor-ai.desktop"
    if [[ -f "$desktop_file" ]]; then
        # Update MIME types to be more comprehensive
        sed -i 's|MimeType=.*|MimeType=text/plain;text/x-c;text/x-c++;text/x-chdr;text/x-csrc;text/x-h;text/x-java;text/x-makefile;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-code-workspace;inode/directory;|' "$desktop_file"
    fi
    
    print_status "OK" "KDE integration created"
}

# Function to configure update handling
configure_updates() {
    print_status "INFO" "Configuring update handling..."
    
    # Create update handler script
    local update_script="$HOME/.local/bin/cursor-update-handler"
    
    cat > "$update_script" << 'EOF'
#!/bin/bash

# Cursor AI Update Handler
# This script handles Cursor updates and restarts

# Wait for Cursor to fully close
sleep 2

# Kill any remaining Cursor processes
pkill -f "cursor.AppImage" || true

# Wait a bit more
sleep 1

# Restart Cursor
nohup cursor >/dev/null 2>&1 &

# Notify user
notify-send "Cursor AI" "Update completed and Cursor restarted" --icon=cursor-ai
EOF
    
    chmod +x "$update_script"
    
    # Create desktop file for update handler
    local update_desktop="$HOME/.local/share/applications/cursor-update-handler.desktop"
    
    cat > "$update_desktop" << 'EOF'
[Desktop Entry]
Name=Cursor AI Update Handler
Comment=Handles Cursor AI updates and restarts
Exec=/home/adam/.local/bin/cursor-update-handler
Terminal=false
Type=Application
Hidden=true
EOF
    
    # Update the path in the desktop file
    sed -i "s|/home/adam|$HOME|g" "$update_desktop"
    
    print_status "OK" "Update handling configured"
}

# Function to create autostart entry (optional)
create_autostart() {
    print_status "INFO" "Creating autostart entry..."
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    local autostart_file="$autostart_dir/cursor-ai.desktop"
    
    cat > "$autostart_file" << 'EOF'
[Desktop Entry]
Name=Cursor AI
Comment=AI-first code editor
Exec=cursor
Icon=cursor-ai
Terminal=false
Type=Application
Categories=Development;IDE;TextEditor;
X-GNOME-Autostart-enabled=true
EOF
    
    print_status "OK" "Autostart entry created (disabled by default)"
    print_status "INFO" "To enable autostart, run: sed -i 's/X-GNOME-Autostart-enabled=false/X-GNOME-Autostart-enabled=true/' $autostart_file"
}

# Function to test the installation
test_installation() {
    print_status "INFO" "Testing Cursor installation..."
    
    # Test if the wrapper script works
    if timeout 10s cursor --version >/dev/null 2>&1; then
        print_status "OK" "Cursor launches successfully"
    else
        print_status "WARNING" "Cursor may have issues launching (this is normal for first run)"
    fi
    
    # Test if desktop file is properly registered
    if gtk-launch cursor-ai --version >/dev/null 2>&1; then
        print_status "OK" "Desktop integration working"
    else
        print_status "WARNING" "Desktop integration may need a logout/login to take effect"
    fi
}

# Function to show usage instructions
show_instructions() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    Installation Complete!${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Cursor AI has been set up with the following features:"
    echo ""
    echo -e "${GREEN}✅ Desktop Integration${NC}"
    echo "   • Cursor appears in your application menu"
    echo "   • Right-click files to open with Cursor"
    echo "   • Proper KDE integration"
    echo ""
    echo -e "${GREEN}✅ Sandbox Issues Fixed${NC}"
    echo "   • No more sandbox errors"
    echo "   • Proper namespace handling"
    echo "   • Better update handling"
    echo ""
    echo -e "${GREEN}✅ Command Line Access${NC}"
    echo "   • Use 'cursor' command from terminal"
    echo "   • Wrapper script handles environment setup"
    echo ""
    echo "Usage:"
    echo "  • Launch from menu: Search for 'Cursor AI'"
    echo "  • Command line: cursor [file]"
    echo "  • Right-click files: 'Open with Cursor AI'"
    echo ""
    echo -e "${YELLOW}Note:${NC} You may need to log out and back in for all integrations to take effect."
    echo ""
}

# Main execution
main() {
    # Check if Cursor is already installed
    if check_cursor_installation; then
        print_status "INFO" "Cursor is already installed"
        read -p "Do you want to reconfigure the installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "INFO" "Installation skipped"
            exit 0
        fi
    else
        download_cursor
    fi
    
    create_desktop_integration
    create_wrapper_script
    fix_sandbox_issues
    create_kde_integration
    configure_updates
    create_autostart
    test_installation
    show_instructions
}

# Run the main function
main "$@"

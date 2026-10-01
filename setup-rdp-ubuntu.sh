#!/bin/bash

# Ubuntu RDP Setup Script with Tailscale Integration
# Optimized for remote access via Tailscale

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Ubuntu RDP Server Setup (Tailscale Ready)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo -e "${RED}❌ This script requires sudo privileges${NC}"
    exit 1
fi

# Verify Tailscale is installed
echo -e "${YELLOW}📋 Checking Tailscale installation...${NC}"
if ! command -v tailscale &> /dev/null; then
    echo -e "${RED}❌ Tailscale is not installed${NC}"
    echo -e "${YELLOW}ℹ️  Please install Tailscale first:${NC}"
    echo -e "curl -fsSL https://tailscale.com/install.sh | sh"
    exit 1
fi
echo -e "${GREEN}✓ Tailscale found${NC}"

# Update system
echo -e "\n${YELLOW}📦 Updating Ubuntu packages...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

# Install XRDP and dependencies
echo -e "\n${YELLOW}📦 Installing XRDP...${NC}"
sudo apt-get install -y xrdp xorgxrdp

# Install desktop environment (XFCE4 - lightweight)
echo -e "\n${YELLOW}📦 Installing XFCE4 desktop environment...${NC}"
sudo apt-get install -y xfce4 xfce4-goodies

# Install additional utilities
echo -e "\n${YELLOW}📦 Installing additional utilities...${NC}"
sudo apt-get install -y firefox vlc gedit file-manager

# Configure XRDP
echo -e "\n${YELLOW}⚙️  Configuring XRDP...${NC}"

# Create XRDP session configuration for XFCE4
sudo bash -c 'cat > /etc/xrdp/xrdp.ini.template << EOF
[Globals]
bitmap_cache=yes
bitmap_compression=yes
bulk_compression=yes
max_bpp=32
new_cursors=yes
EOF'

# Set default session to XFCE4
echo "xfce4-session" > ~/.Xsession
chmod +x ~/.Xsession

# Enable XRDP service
echo -e "\n${YELLOW}🚀 Enabling XRDP service...${NC}"
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Configure firewall for RDP (optional - ufw)
if command -v ufw &> /dev/null; then
    echo -e "\n${YELLOW}🔥 Configuring firewall rules...${NC}"
    sudo ufw allow 3389/tcp
    echo -e "${GREEN}✓ Firewall rule added for port 3389${NC}"
fi

# Verify XRDP is running
echo -e "\n${YELLOW}🔍 Verifying XRDP service...${NC}"
if sudo systemctl is-active --quiet xrdp; then
    echo -e "${GREEN}✓ XRDP service is running${NC}"
else
    echo -e "${RED}❌ XRDP service failed to start${NC}"
    exit 1
fi

# Get system information
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not connected yet")
LOCAL_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
USERNAME=$(whoami)

# Display connection information
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ RDP Setup Complete!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}📡 CONNECTION INFORMATION:${NC}"
echo -e "  ${YELLOW}Hostname:${NC} $HOSTNAME"
echo -e "  ${YELLOW}Local IP:${NC} $LOCAL_IP"
echo -e "  ${YELLOW}Tailscale IP:${NC} $TAILSCALE_IP"
echo -e "  ${YELLOW}RDP Port:${NC} 3389"
echo -e "  ${YELLOW}Username:${NC} $USERNAME"
echo -e "  ${YELLOW}Password:${NC} Your system password"

echo -e "\n${BLUE}🔗 HOW TO CONNECT:${NC}"
echo -e "  ${YELLOW}1. Via Tailscale (Secure):${NC}"
echo -e "     Remote Desktop to: ${GREEN}$TAILSCALE_IP:3389${NC}"
echo -e "\n  ${YELLOW}2. Via Local Network:${NC}"
echo -e "     Remote Desktop to: ${GREEN}$LOCAL_IP:3389${NC}"
echo -e "\n  ${YELLOW}3. Client Software:${NC}"
echo -e "     - Windows: Remote Desktop Connection (built-in)"
echo -e "     - Mac: Microsoft Remote Desktop (App Store)"
echo -e "     - Linux: Remmina or GNOME Remote Desktop"

echo -e "\n${BLUE}📝 VERIFICATION COMMANDS:${NC}"
echo -e "  ${YELLOW}Check XRDP status:${NC} sudo systemctl status xrdp"
echo -e "  ${YELLOW}Restart XRDP:${NC} sudo systemctl restart xrdp"
echo -e "  ${YELLOW}View XRDP logs:${NC} sudo journalctl -u xrdp -f"
echo -e "  ${YELLOW}Check Tailscale:${NC} tailscale status"

echo -e "\n${GREEN}✓ System is ready to accept RDP connections!${NC}\n"

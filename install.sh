#!/bin/bash
# =============================================================================
# Installation Script for RTSP to YouTube Stream Relay
# Run this on your Raspberry Pi
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     RTSP to YouTube Stream Relay - Installer              ║"
echo "║     For Raspberry Pi                                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}Step 1: Installing dependencies...${NC}"
apt-get update
apt-get install -y ffmpeg

echo -e "${GREEN}✓ FFmpeg installed${NC}"

echo -e "${YELLOW}Step 2: Creating configuration directory...${NC}"
mkdir -p /etc/rtsp-youtube
mkdir -p /var/log/rtsp-youtube

# Only copy example config if config doesn't exist
if [ ! -f /etc/rtsp-youtube/config.env ]; then
    cp "$SCRIPT_DIR/config.env.example" /etc/rtsp-youtube/config.env
    chmod 600 /etc/rtsp-youtube/config.env
    echo -e "${GREEN}✓ Created config at /etc/rtsp-youtube/config.env${NC}"
else
    echo -e "${YELLOW}! Config already exists, skipping${NC}"
fi

echo -e "${YELLOW}Step 3: Installing stream script...${NC}"
cp "$SCRIPT_DIR/stream-to-youtube.sh" /usr/local/bin/
chmod +x /usr/local/bin/stream-to-youtube.sh
echo -e "${GREEN}✓ Script installed to /usr/local/bin/stream-to-youtube.sh${NC}"

echo -e "${YELLOW}Step 4: Installing systemd service...${NC}"
cp "$SCRIPT_DIR/rtsp-youtube.service" /etc/systemd/system/
systemctl daemon-reload
echo -e "${GREEN}✓ Service installed${NC}"

# Set ownership for log directory
chown -R pi:pi /var/log/rtsp-youtube

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    INSTALLATION COMPLETE                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Edit the configuration file with your stream details:"
echo -e "   ${GREEN}sudo nano /etc/rtsp-youtube/config.env${NC}"
echo ""
echo "2. Set your RTSP_URL and YOUTUBE_STREAM_KEY"
echo ""
echo "3. Test the stream manually first:"
echo -e "   ${GREEN}sudo /usr/local/bin/stream-to-youtube.sh${NC}"
echo "   (Press Ctrl+C to stop)"
echo ""
echo "4. Once working, enable auto-start on boot:"
echo -e "   ${GREEN}sudo systemctl enable rtsp-youtube${NC}"
echo -e "   ${GREEN}sudo systemctl start rtsp-youtube${NC}"
echo ""
echo "Useful commands:"
echo -e "  ${BLUE}sudo systemctl status rtsp-youtube${NC}  - Check status"
echo -e "  ${BLUE}sudo systemctl stop rtsp-youtube${NC}    - Stop streaming"
echo -e "  ${BLUE}sudo systemctl restart rtsp-youtube${NC} - Restart stream"
echo -e "  ${BLUE}sudo journalctl -u rtsp-youtube -f${NC}  - View live logs"
echo ""

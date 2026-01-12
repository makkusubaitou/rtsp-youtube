#!/bin/bash
# =============================================================================
# Uninstall Script for RTSP to YouTube Stream Relay
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}Stopping service...${NC}"
systemctl stop rtsp-youtube 2>/dev/null || true
systemctl disable rtsp-youtube 2>/dev/null || true

echo -e "${YELLOW}Removing files...${NC}"
rm -f /etc/systemd/system/rtsp-youtube.service
rm -f /usr/local/bin/stream-to-youtube.sh
systemctl daemon-reload

echo ""
read -p "Remove configuration and logs? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /etc/rtsp-youtube
    rm -rf /var/log/rtsp-youtube
    echo -e "${GREEN}✓ Configuration and logs removed${NC}"
else
    echo -e "${YELLOW}! Configuration preserved at /etc/rtsp-youtube${NC}"
fi

echo -e "${GREEN}✓ Uninstallation complete${NC}"

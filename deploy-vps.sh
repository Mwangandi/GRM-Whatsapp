#!/bin/bash

################################################################################
# GRM-WhatsApp VPS Deployment Script
# Run this once on your VPS to set up the service properly
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   GRM-WhatsApp VPS Deployment Setup                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run with sudo"
    exit 1
fi

# Check Node.js
log_info "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    log_error "Node.js not found. Installing..."
    curl -sL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    log_success "Node.js installed"
else
    log_success "Node.js $(node -v) found"
fi

# Ensure frappe user exists
log_info "Checking frappe user..."
if ! id -u frappe > /dev/null 2>&1; then
    log_error "User 'frappe' not found"
    exit 1
fi
log_success "User 'frappe' found"

# Setup directories
log_info "Setting up directories..."
mkdir -p /home/frappe/GRM
mkdir -p /var/log/grm-whatsapp

# Change ownership
chown -R frappe:frappe /home/frappe/GRM
chown frappe:frappe /var/log/grm-whatsapp

log_success "Directories configured"

# Check if repository exists
if [ ! -d "/home/frappe/GRM/GRM-Whatsapp" ]; then
    log_warning "GRM-Whatsapp directory not found"
    log_info "Cloning repository..."
    cd /home/frappe/GRM
    sudo -u frappe git clone git@github.com:Mwangandi/GRM-Whatsapp.git
    log_success "Repository cloned"
fi

# Setup build script
log_info "Setting up build script..."
chmod +x /home/frappe/GRM/GRM-Whatsapp/build.sh
log_success "Build script executable"

# Setup systemd service
log_info "Setting up systemd service..."
cp /home/frappe/GRM/GRM-Whatsapp/grm-whatsapp.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable grm-whatsapp

log_success "Systemd service configured"

# Create log rotation
log_info "Setting up log rotation..."
cat > /etc/logrotate.d/grm-whatsapp << 'EOF'
/var/log/grm-whatsapp/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 frappe frappe
    sharedscripts
    postrotate
        systemctl reload grm-whatsapp > /dev/null 2>&1 || true
    endscript
}
EOF
log_success "Log rotation configured"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete! Next Steps:                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "1. As the frappe user, configure the environment:"
echo "   $ cd /home/frappe/GRM/GRM-Whatsapp"
echo "   $ cp .env.template .env"
echo "   $ nano .env  # Add Twilio credentials"
echo ""
echo "2. Run the build setup:"
echo "   $ ./build.sh build"
echo ""
echo "3. Start the service:"
echo "   $ sudo systemctl start grm-whatsapp"
echo ""
echo "4. Check status:"
echo "   $ sudo systemctl status grm-whatsapp"
echo ""
echo "5. View logs:"
echo "   $ sudo journalctl -u grm-whatsapp -f"
echo ""
echo "Service runs on: http://127.0.0.1:8090"
echo "Apache proxy:    http://203.161.56.134:8002"
echo "Dashboard:       http://203.161.56.134:8002/dashboard"
echo ""

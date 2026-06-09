#!/bin/bash

################################################################################
# VPS Setup: Clone & Deploy GRM-WhatsApp
# Run this on the VPS to set everything up
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

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

print_header "VPS Setup: GRM-WhatsApp"

# Check if frappe user
if [ "$(whoami)" != "frappe" ]; then
    log_error "This script must be run as frappe user"
    exit 1
fi

# Go to home directory
cd ~

print_header "Step 1: Creating Project Directory"
if [ -d "GRM/GRM-Whatsapp" ]; then
    log_warning "Directory already exists: ~/GRM/GRM-Whatsapp"
else
    mkdir -p GRM
    log_success "Created directory: ~/GRM"
fi

cd GRM

print_header "Step 2: Cloning Repository (via HTTPS)"

if [ -d "GRM-Whatsapp/.git" ]; then
    log_warning "Repository already cloned"
    cd GRM-Whatsapp
    log_info "Pulling latest changes..."
    git pull origin master 2>/dev/null || git pull origin main 2>/dev/null || log_warning "Could not pull updates"
else
    log_info "Cloning GRM-Whatsapp from GitHub (using HTTPS)..."
    git clone https://github.com/Mwangandi/GRM-Whatsapp.git
    cd GRM-Whatsapp
    log_success "Repository cloned"
fi

print_header "Step 3: Installing Dependencies"
log_info "This may take 3-5 minutes..."
npm install

print_header "Step 4: Building Application"
./build.sh build

print_header "Step 5: Configuring Environment"
if [ ! -f ".env" ]; then
    cp .env.template .env
    log_success "Created .env from template"
    log_warning "⚠️  IMPORTANT: Edit .env and add your Twilio credentials!"
    log_info "Edit: nano .env"
else
    log_success ".env already exists"
fi

print_header "Step 6: Setting Up Systemd Service"
log_info "Installing systemd service..."
sudo cp grm-whatsapp.service /etc/systemd/system/
sudo mkdir -p /var/log/grm-whatsapp
sudo chown frappe:frappe /var/log/grm-whatsapp
sudo systemctl daemon-reload
sudo systemctl enable grm-whatsapp
log_success "Systemd service configured"

print_header "✅ Setup Complete!"
echo ""
log_success "Next steps:"
echo ""
echo "1. Configure Twilio credentials:"
echo "   nano ~/.env"
echo ""
echo "2. Start the service:"
echo "   sudo systemctl start grm-whatsapp"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status grm-whatsapp"
echo ""
echo "4. View logs:"
echo "   sudo journalctl -u grm-whatsapp -f"
echo ""
echo "5. Test health:"
echo "   curl http://127.0.0.1:8090/health"
echo ""

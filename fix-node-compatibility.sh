#!/bin/bash

################################################################################
# Fix Node.js/better-sqlite3 Compatibility Issue on VPS
# Run this script to resolve compilation errors on Node.js 24.x
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

print_header "Node.js & better-sqlite3 Compatibility Fix"

# Check if running as frappe user
if [ "$(whoami)" != "frappe" ]; then
    log_error "This script must be run as 'frappe' user"
    exit 1
fi

# Check directory
if [ ! -f "package.json" ]; then
    log_error "package.json not found. Run from project root."
    exit 1
fi

log_info "Stopping application..."
sudo systemctl stop grm-whatsapp || log_warning "Service not running"

log_info "Pulling latest changes from GitHub..."
git pull origin master

log_info "Clearing old dependencies..."
rm -rf node_modules package-lock.json

log_info "Installing updated dependencies (this may take 3-5 minutes)..."
npm install

log_info "Clearing npm cache..."
npm cache clean --force

log_info "Building application..."
./build.sh build

log_info "Starting application..."
sudo systemctl start grm-whatsapp

sleep 2

log_info "Checking service status..."
sudo systemctl status grm-whatsapp

echo ""
print_header "✅ Fix Complete!"

log_success "better-sqlite3 upgraded to v11 (Node.js 24 compatible)"
log_success "All dependencies installed successfully"
log_success "Service started and running"

echo ""
log_info "Verify everything is working:"
echo "  sudo systemctl status grm-whatsapp"
echo "  sudo journalctl -u grm-whatsapp -n 20"
echo "  curl http://127.0.0.1:8090/health"
echo ""

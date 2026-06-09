#!/bin/bash

################################################################################
# Port Management for VPS
# Diagnose and fix port conflicts
################################################################################

set +e

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

print_header "VPS Port Diagnostics"

PORT=${1:-8090}

log_info "Checking port: $PORT"
echo ""

# Check using lsof
print_header "What's Using Port $PORT?"
if command -v lsof &> /dev/null; then
    log_info "Using lsof:"
    lsof -i :$PORT || log_info "Port $PORT is free"
else
    log_warning "lsof not available"
fi

echo ""

# Check using netstat
if command -v netstat &> /dev/null; then
    log_info "Using netstat:"
    netstat -tulpn | grep $PORT || log_info "Port $PORT is free"
else
    log_warning "netstat not available"
fi

echo ""

# Check using ss
if command -v ss &> /dev/null; then
    log_info "Using ss:"
    ss -tulpn | grep $PORT || log_info "Port $PORT is free"
else
    log_warning "ss not available"
fi

echo ""
print_header "Next Steps"

if lsof -i :$PORT &>/dev/null || netstat -tulpn 2>/dev/null | grep -q ":$PORT " || ss -tulpn 2>/dev/null | grep -q ":$PORT "; then
    log_warning "Port $PORT is IN USE"
    echo ""
    echo "Options:"
    echo "1. Use a different port for GRM-WhatsApp:"
    echo "   Edit: /home/frappe/GRM/GRM-Whatsapp/.env"
    echo "   Set: PORT=8091"
    echo ""
    echo "2. Stop the service using port $PORT:"
    echo "   sudo systemctl stop <service-name>"
    echo ""
    echo "3. Kill the process using port $PORT:"
    echo "   PID=\$(lsof -ti:$PORT)"
    echo "   sudo kill -9 \$PID"
else
    log_success "Port $PORT is FREE"
    echo ""
    echo "You can use GRM-WhatsApp on this port."
fi

echo ""
print_header "Configuration"

echo "Current GRM-WhatsApp settings:"
if [ -f ".env" ]; then
    grep "^PORT=" .env || log_warning "PORT not set in .env"
else
    log_error ".env not found"
fi

echo ""
echo "Current Apache proxy (for port 8002):"
echo "Check: /etc/apache2/conf.d/includes/post_virtualhost_global.conf"
echo ""

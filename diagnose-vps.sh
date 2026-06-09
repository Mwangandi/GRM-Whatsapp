#!/bin/bash

################################################################################
# GRM-WhatsApp VPS Troubleshooting Script
# Run this to diagnose startup issues
################################################################################

set +e  # Don't exit on errors

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

print_header "GRM-WhatsApp VPS Diagnostic"

# Check current directory
log_info "Current directory: $(pwd)"

# Check if we're in the right place
if [ ! -f "package.json" ]; then
    log_error "package.json not found!"
    log_info "You should be in /home/frappe/GRM/GRM-Whatsapp"
    exit 1
fi

# Check Node.js
print_header "Checking Node.js"
log_info "Node version: $(node -v)"
log_info "npm version: $(npm -v)"

# Check dependencies
print_header "Checking Dependencies"
if [ -d "node_modules" ]; then
    log_success "node_modules directory exists"
    if [ -d "node_modules/express" ]; then
        log_success "Express is installed"
    else
        log_error "Express NOT installed"
    fi
    if [ -d "node_modules/better-sqlite3" ]; then
        log_success "better-sqlite3 is installed"
    else
        log_error "better-sqlite3 NOT installed"
    fi
else
    log_error "node_modules NOT installed! Run: npm install"
fi

# Check .env file
print_header "Checking Configuration"
if [ -f ".env" ]; then
    log_success ".env file exists"
    if grep -q "TWILIO_ACCOUNT_SID" .env; then
        log_success ".env has TWILIO_ACCOUNT_SID"
    else
        log_error ".env missing TWILIO_ACCOUNT_SID"
    fi
else
    log_error ".env file NOT found!"
    log_info "Create it: cp .env.template .env"
fi

# Check database
print_header "Checking Database"
if [ -f "grm.db" ]; then
    log_success "Database file (grm.db) exists"
    ls -lah grm.db
else
    log_warning "Database file NOT found (will be created on first run)"
fi

# Check port
print_header "Checking Port"
log_info "Checking if port 8090 is in use..."
if lsof -i :8090 >/dev/null 2>&1; then
    log_warning "Port 8090 is ALREADY IN USE"
    lsof -i :8090
else
    log_success "Port 8090 is available"
fi

# Try to run the app directly
print_header "Testing Application Startup"
log_info "Attempting to start app (will timeout after 5 seconds)..."
timeout 5 node index.js 2>&1 || true

# Check logs directory
print_header "Checking Logs"
if [ -d "logs" ]; then
    log_success "logs directory exists"
    if [ -f "logs/grm-whatsapp.log" ]; then
        log_info "Last 20 lines of grm-whatsapp.log:"
        tail -20 logs/grm-whatsapp.log
    fi
else
    log_warning "logs directory not found"
fi

echo ""
print_header "Troubleshooting Steps"
echo "1. Install dependencies:"
echo "   npm install"
echo ""
echo "2. Configure .env file:"
echo "   cp .env.template .env"
echo "   nano .env  # Add Twilio credentials"
echo ""
echo "3. Test app directly:"
echo "   node index.js"
echo ""
echo "4. Check for port conflicts:"
echo "   lsof -i :8090"
echo ""
echo "5. Kill any stray processes:"
echo "   pkill -f 'node index.js'"
echo ""
echo "6. Try starting with build script:"
echo "   ./build.sh stop   # If running"
echo "   ./build.sh start  # Start fresh"
echo ""

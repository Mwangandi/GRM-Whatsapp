#!/bin/bash

################################################################################
# GRM-WhatsApp Build and Deployment Script
# This script handles building, installing dependencies, and running the app
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="GRM-WhatsApp"
SERVICE_NAME="grm-whatsapp"
PORT=${PORT:-8090}
NODE_ENV=${NODE_ENV:-production}
LOG_DIR="./logs"
PID_FILE="$LOG_DIR/${SERVICE_NAME}.pid"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

################################################################################
# Main Functions
################################################################################

# Check Node.js version
check_nodejs() {
    print_header "Checking Node.js Installation"
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    NODE_VERSION=$(node -v)
    log_success "Node.js ${NODE_VERSION} found"
    
    NPM_VERSION=$(npm -v)
    log_success "npm ${NPM_VERSION} found"
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    if [ ! -d "node_modules" ]; then
        log_info "Installing npm packages..."
        npm install
        log_success "Dependencies installed"
    else
        log_info "Dependencies already installed. Running npm install to update..."
        npm install
        log_success "Dependencies updated"
    fi
}

# Create necessary directories
setup_directories() {
    print_header "Setting Up Directories"
    
    mkdir -p "$LOG_DIR"
    log_success "Log directory created: $LOG_DIR"
}

# Create/update .env file if needed
setup_env() {
    print_header "Checking Environment Configuration"
    
    if [ ! -f ".env" ]; then
        log_warning ".env file not found. Creating template..."
        cat > .env.template << 'EOF'
# Server Configuration
PORT=8090
NODE_ENV=production

# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_whatsapp_number

# Database Configuration
DATABASE_PATH=./grm.db

# API Configuration
API_URL=https://edatuzen.com

# Dashboard Configuration
DASHBOARD_PORT=8090
EOF
        log_warning "Created .env.template - please configure and rename to .env"
    else
        log_success ".env file found"
    fi
}

# Verify database
verify_database() {
    print_header "Verifying Database"
    
    if [ -f "grm.db" ]; then
        log_success "Database found: grm.db"
    else
        log_warning "Database not found. It will be created on first run."
    fi
}

# Start the application
start_app() {
    print_header "Starting $PROJECT_NAME"
    
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            log_warning "Application is already running (PID: $OLD_PID)"
            return 1
        fi
    fi
    
    log_info "Starting application on port $PORT..."
    
    NODE_ENV=$NODE_ENV PORT=$PORT nohup node index.js >> "$LOG_DIR/${SERVICE_NAME}.log" 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    
    sleep 2
    
    if kill -0 $NEW_PID 2>/dev/null; then
        log_success "Application started successfully (PID: $NEW_PID)"
        log_info "Logs available at: $LOG_DIR/${SERVICE_NAME}.log"
    else
        log_error "Failed to start application"
        return 1
    fi
}

# Stop the application
stop_app() {
    print_header "Stopping $PROJECT_NAME"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log_info "Stopping process $PID..."
            kill $PID
            rm -f "$PID_FILE"
            sleep 2
            log_success "Application stopped"
        else
            log_warning "Process not running, removing stale PID file"
            rm -f "$PID_FILE"
        fi
    else
        log_warning "No PID file found"
    fi
}

# Restart the application
restart_app() {
    print_header "Restarting $PROJECT_NAME"
    stop_app
    sleep 1
    start_app
}

# Check application status
status_app() {
    print_header "Application Status"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log_success "Application is running (PID: $PID)"
            
            # Check if port is listening
            if command -v lsof &> /dev/null; then
                if lsof -i :$PORT &>/dev/null; then
                    log_success "Service is listening on port $PORT"
                else
                    log_warning "PID exists but not listening on port $PORT"
                fi
            fi
            
            return 0
        else
            log_error "Application is NOT running (stale PID: $PID)"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        log_warning "Application is NOT running"
        return 1
    fi
}

# View logs
view_logs() {
    LOG_FILE="$LOG_DIR/${SERVICE_NAME}.log"
    if [ -f "$LOG_FILE" ]; then
        print_header "Application Logs (last 50 lines)"
        tail -50 "$LOG_FILE"
    else
        log_error "Log file not found: $LOG_FILE"
    fi
}

# Build and setup everything
build() {
    print_header "Running Complete Build"
    
    check_nodejs
    setup_directories
    setup_env
    install_dependencies
    verify_database
    
    log_success "Build completed successfully!"
    log_info "Next step: Configure .env file and run './build.sh start'"
}

# Show usage
usage() {
    cat << EOF
Usage: ./build.sh [COMMAND]

Commands:
    build       Complete build setup (install dependencies, setup config)
    start       Start the application
    stop        Stop the application
    restart     Restart the application
    status      Show application status
    logs        View application logs
    help        Show this help message

Examples:
    ./build.sh build                # First time setup
    ./build.sh start                # Start the service
    ./build.sh status               # Check if running
    ./build.sh logs                 # View recent logs
    ./build.sh restart              # Restart service

Environment Variables:
    PORT        Service port (default: 8090)
    NODE_ENV    Node environment (default: production)

EOF
}

################################################################################
# Main Script
################################################################################

# Ensure we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Parse command
COMMAND=${1:-help}

case $COMMAND in
    build)
        build
        ;;
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    status)
        status_app
        ;;
    logs)
        view_logs
        ;;
    help)
        usage
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac

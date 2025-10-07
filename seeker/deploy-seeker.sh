#!/bin/bash

# Deploy Seeker Service Script for Linux
# Description: Deploys seeker binary as a systemd service on Linux
# Author: Auto-generated deployment script
# Version: 1.1.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVICE_NAME="ctrlb-seeker"
readonly BINARY_NAME="seeker"
readonly BINARY_SOURCE="${SCRIPT_DIR}/${BINARY_NAME}"
readonly BINARY_DEST="/opt/ctrlb/seeker/ctrlb-seeker"
readonly SERVICE_FILE_SOURCE="${SCRIPT_DIR}/${SERVICE_NAME}.service"
readonly SERVICE_FILE_DEST="/etc/systemd/system/${SERVICE_NAME}.service"
readonly SERVICE_USER="ctrlb"
readonly WORKING_DIR="/opt/ctrlb/seeker"
readonly LOG_DIR="/var/log/ctrlb"

# Configuration files
readonly ENV_FILE_SOURCE="${SCRIPT_DIR}/.env"
readonly ENV_FILE_DEST="${WORKING_DIR}/.env"
readonly PUBLIC_KEY_SOURCE="${SCRIPT_DIR}/keys/public.key"
readonly PUBLIC_KEY_DEST="${WORKING_DIR}/keys/public.key"
readonly PRIVATE_KEY_SOURCE="${SCRIPT_DIR}/keys/private.key"
readonly PRIVATE_KEY_DEST="${WORKING_DIR}/keys/private.key"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Config file handling mode: skip, overwrite, backup
CONFIG_MODE="${CONFIG_MODE:-skip}"  # Default to backup

# Validate CONFIG_MODE
if [[ ! "$CONFIG_MODE" =~ ^(skip|overwrite|backup)$ ]]; then
    echo -e "${RED}[ERROR]${NC} Invalid CONFIG_MODE: $CONFIG_MODE" >&2
    echo -e "${RED}[ERROR]${NC} Must be one of: skip, overwrite, backup" >&2
    exit 1
fi

# Logging functions
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
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    if [[ ! -f "$BINARY_SOURCE" ]]; then
        log_error "Source binary not found: $BINARY_SOURCE"
        exit 1
    fi
    
    if [[ ! -x "$BINARY_SOURCE" ]]; then
        log_warning "Source binary is not executable, adding execute permission..."
        chmod +x "$BINARY_SOURCE"
    fi
    
    if [[ ! -f "$SERVICE_FILE_SOURCE" ]]; then
        log_error "Service file not found: $SERVICE_FILE_SOURCE"
        exit 1
    fi
    
    if ! command -v systemctl &> /dev/null; then
        log_error "systemctl not found. This script requires a systemd-based Linux distribution."
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Create service user
create_service_user() {
    log_info "Creating service user..."
    
    # Create user if it doesn't exist
    if ! getent passwd "$SERVICE_USER" &> /dev/null; then
        useradd --system \
                --home-dir "$WORKING_DIR" \
                --no-create-home \
                --shell /usr/sbin/nologin \
                --comment "CtrlB Seeker service user" \
                "$SERVICE_USER"
        log_info "Created user: $SERVICE_USER"
    else
        log_info "User $SERVICE_USER already exists"
    fi
    
    log_success "Service user ready"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p "$WORKING_DIR"
    mkdir -p "$WORKING_DIR/keys"
    mkdir -p "$LOG_DIR"
    
    # Set ownership and permissions
    chown "$SERVICE_USER:$SERVICE_USER" "$WORKING_DIR"
    chown "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
    chown "$SERVICE_USER:$SERVICE_USER" "$WORKING_DIR/keys"
    chmod 750 "$WORKING_DIR/keys"
    chmod 750 "$WORKING_DIR"
    chmod 755 "$LOG_DIR"
    
    log_success "Directories created and configured"
}

# Install binary
install_binary() {
    log_info "Installing binary to $BINARY_DEST..."
    
    # Check if binary already exists
    if [[ -f "$BINARY_DEST" ]]; then
        log_warning "Existing binary found at $BINARY_DEST"
        local backup_file="${BINARY_DEST}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Creating backup: $backup_file"
        cp "$BINARY_DEST" "$backup_file"
        log_success "Backup created successfully"
    fi
    
    cp "$BINARY_SOURCE" "$BINARY_DEST"
    chmod +x "$BINARY_DEST"
    chown "$SERVICE_USER:$SERVICE_USER" "$BINARY_DEST"
    
    log_success "Binary installed successfully"
}


# Helper function to install a single config file with backup/skip/overwrite options
install_config_file() {
    local source_file="$1"
    local dest_file="$2"
    local permissions="$3"
    local file_name="$4"
    local backup_suffix="$5"
    
    # Check if destination file exists
    if [[ -f "$dest_file" ]]; then
        case "$CONFIG_MODE" in
            skip)
                log_warning "$file_name already exists at $dest_file - SKIPPING (use --force=overwrite or --force=backup to update)"
                return 0
                ;;
            overwrite)
                log_warning "$file_name already exists - OVERWRITING without backup"
                ;;
            backup)
                log_info "$file_name already exists - creating backup"
                cp "$dest_file" "${dest_file}${backup_suffix}"
                log_success "Backup created: ${dest_file}${backup_suffix}"
                ;;
            *)
                log_error "Invalid CONFIG_MODE: $CONFIG_MODE"
                exit 1
                ;;
        esac
    else
        log_info "Installing $file_name..."
    fi
    
    # Install the file
    cp "$source_file" "$dest_file"
    chmod "$permissions" "$dest_file"
    chown "$SERVICE_USER:$SERVICE_USER" "$dest_file"
    log_success "$file_name installed successfully"
}

# Install configuration files
install_config_files() {
    local files_installed=0
    local backup_suffix=".backup.$(date +%Y%m%d_%H%M%S)"
    
    log_info "Configuration mode: $CONFIG_MODE"
    echo
    
    # Install .env file
    if [[ -f "$ENV_FILE_SOURCE" ]]; then
        install_config_file "$ENV_FILE_SOURCE" "$ENV_FILE_DEST" "600" ".env" "$backup_suffix"
        files_installed=$((files_installed + 1))
    else
        log_warning ".env file not found at $ENV_FILE_SOURCE (skipping)"
    fi
    
    # Install public key
    if [[ -f "$PUBLIC_KEY_SOURCE" ]]; then
        install_config_file "$PUBLIC_KEY_SOURCE" "$PUBLIC_KEY_DEST" "644" "public.key" "$backup_suffix"
        files_installed=$((files_installed + 1))
    else
        log_warning "public.key not found at $PUBLIC_KEY_SOURCE (skipping)"
    fi
    
    # Install private key
    if [[ -f "$PRIVATE_KEY_SOURCE" ]]; then
        install_config_file "$PRIVATE_KEY_SOURCE" "$PRIVATE_KEY_DEST" "600" "private.key" "$backup_suffix"
        files_installed=$((files_installed + 1))
    else
        log_warning "private.key not found at $PRIVATE_KEY_SOURCE (skipping)"
    fi
    
    echo
    if [[ $files_installed -eq 0 ]]; then
        log_warning "No configuration files were installed"
    else
        log_success "Processed $files_installed configuration file(s)"
    fi
}

# Install systemd service
install_service() {
    log_info "Installing systemd service..."
    
    # Backup existing service file if it exists
    if [[ -f "$SERVICE_FILE_DEST" ]]; then
        local backup_file="${SERVICE_FILE_DEST}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing service file to: $backup_file"
        cp "$SERVICE_FILE_DEST" "$backup_file"
    fi
    
    cp "$SERVICE_FILE_SOURCE" "$SERVICE_FILE_DEST"
    chmod 644 "$SERVICE_FILE_DEST"
    chown root:root "$SERVICE_FILE_DEST"
    
    # Reload systemd to recognize the new service
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload
    log_success "Daemon reloaded"
    
    log_success "Service file installed successfully"
}

# Enable and start service
enable_service() {
    log_info "Enabling and starting $SERVICE_NAME service..."
    
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    log_success "Service enabled and started"
}

# Stop service
stop_service() {
    log_info "Stopping $SERVICE_NAME service..."
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        log_success "Service stopped"
    else
        log_warning "Service was not running"
    fi
}

# Start service
start_service() {
    log_info "Starting $SERVICE_NAME service..."
    if systemctl start "$SERVICE_NAME"; then
        log_success "Service started"
    else
        log_error "Failed to start service"
        return 1
    fi
}

# Restart service
restart_service() {
    log_info "Restarting $SERVICE_NAME service..."
    if systemctl restart "$SERVICE_NAME"; then
        log_success "Service restarted"
    else
        log_error "Failed to restart service"
        return 1
    fi
}

# Get service status
service_status() {
    echo "=== $SERVICE_NAME Service Status ==="
    systemctl status "$SERVICE_NAME" --no-pager || true
    echo
    
    echo "=== Service Logs (last 20 lines) ==="
    journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true
}

# Disable and remove service
uninstall_service() {
    log_info "Uninstalling $SERVICE_NAME service..."
    
    # Stop the service if it's running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
        log_info "Service stopped"
    fi
    
    # Disable the service if it's enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        systemctl disable "$SERVICE_NAME"
        log_info "Service disabled"
    fi
    
    # Remove service file
    if [[ -f "$SERVICE_FILE_DEST" ]]; then
        rm -f "$SERVICE_FILE_DEST"
        log_info "Service file removed"
    fi
    
    # Remove binary
    if [[ -f "$BINARY_DEST" ]]; then
        rm -f "$BINARY_DEST"
        log_info "Binary removed"
    fi
    
    # Reload systemd
    systemctl daemon-reload
    systemctl reset-failed "$SERVICE_NAME" 2>/dev/null || true
    
    log_success "Service uninstalled successfully"
    
    log_warning "Note: Service user '$SERVICE_USER' and directories were not removed."
    log_warning "To remove them manually, run:"
    log_warning "  userdel $SERVICE_USER"
    log_warning "  rm -rf $WORKING_DIR $LOG_DIR"
}

check_if_service_running() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_warning "Service $SERVICE_NAME is currently running"
        log_info "Stopping service before binary replacement..."
        systemctl stop "$SERVICE_NAME"
        log_success "Service stopped"
    fi
}

# Binary Installation and Service Setup
install() {
    log_info "Starting seeker service installation..."
    
    validate_prerequisites
    create_service_user
    create_directories
    
    # Check and stop service before binary replacement
    check_if_service_running
    
    install_binary
    install_config_files
    install_service
    
    echo
    log_success "=== Installation Complete ==="
    log_info "Service: $SERVICE_NAME"
    log_info "Binary: $BINARY_DEST"
    log_info "Service file: $SERVICE_FILE_DEST"
    log_info "Working directory: $WORKING_DIR"
    log_info "Log directory: $LOG_DIR"
}

# Full installation
install-enable() {
    log_info "Starting seeker service installation..."
    
    validate_prerequisites
    create_service_user
    create_directories
    
    # Check and stop service before binary replacement
    check_if_service_running
    
    install_binary
    install_config_files
    install_service
    enable_service
    
    echo
    log_success "=== Installation Complete ==="
    log_info "Service: $SERVICE_NAME"
    log_info "Binary: $BINARY_DEST"
    log_info "Service file: $SERVICE_FILE_DEST"
    log_info "Working directory: $WORKING_DIR"
    log_info "Log directory: $LOG_DIR"
    echo
    log_info "Use 'sudo $0 status' to check service status"
    log_info "Use 'sudo journalctl -u $SERVICE_NAME -f' to follow logs"
}

# Install only configuration files (without reinstalling service)
install_config_only() {
    log_info "Installing/updating configuration files only..."
    
    if [[ ! -d "$WORKING_DIR" ]]; then
        log_error "Working directory $WORKING_DIR does not exist. Run 'install' first."
        exit 1
    fi
    
    # Verify service user exists
    if ! getent passwd "$SERVICE_USER" &> /dev/null; then
        log_error "Service user '$SERVICE_USER' does not exist. Run 'install' first."
        exit 1
    fi
    
    install_config_files
    
    echo
    log_success "Configuration files updated"
    log_info "Restart the service to apply changes: sudo $0 restart"
}

# Install only binary (with safety checks)
install_binary_only() {
    log_info "Installing/updating binary only..."
    
    # Validate binary source exists
    if [[ ! -f "$BINARY_SOURCE" ]]; then
        log_error "Source binary not found: $BINARY_SOURCE"
        exit 1
    fi
    
    if [[ ! -x "$BINARY_SOURCE" ]]; then
        log_warning "Source binary is not executable, adding execute permission..."
        chmod +x "$BINARY_SOURCE"
    fi
    
    # Check if working directory exists
    if [[ ! -d "$WORKING_DIR" ]]; then
        log_error "Working directory $WORKING_DIR does not exist. Run 'install' first."
        exit 1
    fi
    
    # Verify service user exists
    if ! getent passwd "$SERVICE_USER" &> /dev/null; then
        log_error "Service user '$SERVICE_USER' does not exist. Run 'install' first."
        exit 1
    fi
    
    # Check and stop service before binary replacement
    check_if_service_running
    
    install_binary
    
    echo
    log_success "Binary updated successfully"
    log_info "Binary: $BINARY_DEST"
    log_info "Restart the service to use the new binary: sudo $0 restart"
}

# Display help
show_help() {
    cat << EOF
Deploy Seeker Service Script

USAGE:
    sudo ./deploy-seeker.sh [OPTIONS] <command>

COMMANDS:
    install              Install binary and setup service (don't start)
    install-enable       Install binary, setup service, and enable/start it
    install-binary       Update only the binary (with backup)
    install-config       Update only configuration files (.env, keys)
    start                Start the seeker service
    stop                 Stop the seeker service
    restart              Restart the seeker service
    status               Show service status and recent logs
    uninstall            Remove the service (preserves user and directories)
    help                 Display this help message

OPTIONS:
    -f, --force=MODE     Config file handling mode when files exist:
                         skip      - Skip if file exists (no changes)
                         overwrite - Replace without backup
                         backup    - Backup then replace (default)
    
    -h, --help           Display this help message

CONFIGURATION FILES:
    .env                 Environment variables (optional)
    public.key           Public key for cryptographic operations (optional)
    private.key          Private key for cryptographic operations (optional)

EXAMPLES:
    # Install without starting service
    sudo ./deploy-seeker.sh install

    # Full installation (install and start service)  
    sudo ./deploy-seeker.sh install-enable

    # Update only the binary (creates backup)
    sudo ./deploy-seeker.sh install-binary

    # Update configs with backup (default)
    sudo ./deploy-seeker.sh install-config

    # Update configs, skip if exists
    sudo ./deploy-seeker.sh --force=skip install-config

    # Update configs, overwrite without backup
    sudo ./deploy-seeker.sh --force=overwrite install-config

    # Update configs with explicit backup
    sudo ./deploy-seeker.sh --force=backup install-config

    # Check service status
    sudo ./deploy-seeker.sh status

    # View live logs
    sudo journalctl -u seeker -f

NOTE: This script requires root privileges (use sudo)
EOF
}

# Main script logic
main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                CONFIG_MODE="$2"
                if [[ ! "$CONFIG_MODE" =~ ^(skip|overwrite|backup)$ ]]; then
                    log_error "Invalid --force value: $CONFIG_MODE"
                    log_error "Must be one of: skip, overwrite, backup"
                    exit 1
                fi
                shift 2
                ;;
            --force=*)
                CONFIG_MODE="${1#*=}"
                if [[ ! "$CONFIG_MODE" =~ ^(skip|overwrite|backup)$ ]]; then
                    log_error "Invalid --force value: $CONFIG_MODE"
                    log_error "Must be one of: skip, overwrite, backup"
                    exit 1
                fi
                shift
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            install|install-enable|install-binary|install-config|start|stop|restart|status|uninstall)
                # Valid command, break option parsing
                break
                ;;
            *)
                log_error "Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check for command
    if [[ $# -eq 0 ]]; then
        log_error "No command specified"
        echo
        show_help
        exit 1
    fi
    
    local command=$1
    case $command in
        install-enable)
            check_root
            install-enable
            ;;
        install)
            check_root
            install
            ;;
        install-config)
            check_root
            install_config_only
            ;;
        install-binary)
            check_root
            install_binary_only
            ;;
        start)
            check_root
            start_service
            ;;
        stop)
            check_root
            stop_service
            ;;
        restart)
            check_root
            restart_service
            ;;
        status)
            service_status
            ;;
        uninstall)
            check_root
            uninstall_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

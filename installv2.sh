#!/usr/bin/env bash
set -e  # Exit on error

########################################################
# Simple TypeGen Installer
# A straightforward installation script
########################################################

# Configuration
INSTALL_DIR="/opt/typegen"
BIN_DIR="/usr/local/bin"
BINARY_NAME="typegenctl"
GITHUB_ORG="khanalsaroj"
GITHUB_REPO="typegenctl"
VERSION="${TYPEGEN_VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple logging functions
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

# Show banner
show_banner() {
    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   TypeGen Installer v1.0           ║"
    echo "╚════════════════════════════════════╝"
    echo ""
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root. Please use sudo."
    fi
}

# Check required commands
check_dependencies() {
    info "Checking dependencies..."
    
    for cmd in curl tar; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
        fi
    done
    
    success "All dependencies found"
}

# Detect system
detect_system() {
    info "Detecting system..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Normalize architecture
    case "$ARCH" in
        x86_64|x64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) error "Unsupported architecture: $ARCH" ;;
    esac
    
    info "System: $OS / $ARCH"
}

# Get latest version
get_version() {
    if [ "$VERSION" = "latest" ]; then
        info "Fetching latest version..."
        
        VERSION=$(curl -sf "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/releases/latest" \
            | grep '"tag_name"' \
            | cut -d'"' -f4 \
            | sed 's/^v//')
        
        if [ -z "$VERSION" ]; then
            error "Failed to fetch latest version"
        fi
    fi
    
    info "Installing version: $VERSION"
}

# Spinner function
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    echo -n "$message "
    while kill -0 $pid 2>/dev/null; do
        local char="${spinstr:i++%${#spinstr}:1}"
        printf "\r$message %s" "$char"
        sleep 0.1
    done
    printf "\r$message ✓\n"
}

# Download binary with spinner
download_binary() {
    local url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/v${VERSION}/${BINARY_NAME}-${OS}-${ARCH}.tar.gz"
    local temp_dir=$(mktemp -d)
    local archive="${temp_dir}/download.tar.gz"
    
    # Download in background with spinner
    (curl -fL "$url" -o "$archive" 2>/dev/null) &
    local download_pid=$!
    
    spinner $download_pid "${BLUE}[INFO]${NC} Downloading binary..."
    
    wait $download_pid
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        rm -rf "$temp_dir"
        error "Failed to download from: $url"
    fi
    
    success "Download complete"
    echo "$temp_dir"
}

# Extract and install
install_binary() {
    local temp_dir="$1"
    local archive="${temp_dir}/download.tar.gz"
    
    info "Extracting binary..."
    tar -xzf "$archive" -C "$temp_dir"
    
    # Find the binary
    local binary=$(find "$temp_dir" -type f -name "$BINARY_NAME" -o -type f -executable | head -1)
    
    if [ -z "$binary" ] || [ ! -f "$binary" ]; then
        error "Binary not found in archive"
    fi
    
    info "Installing to $BIN_DIR..."
    chmod +x "$binary"
    cp "$binary" "$BIN_DIR/$BINARY_NAME"
    
    success "Binary installed"
}

# Create directories
create_directories() {
    info "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/data"
    mkdir -p "$INSTALL_DIR/logs"
    
    chmod 755 "$INSTALL_DIR"
    
    success "Directories created"
}

# Create basic config
create_config() {
    info "Creating configuration..."
    
    cat > "$INSTALL_DIR/config/config.yaml" <<EOF
# TypeGen Configuration
version: "$VERSION"
install_date: "$(date -I)"

typegen:
  mode: production
  log_level: info
  data_dir: $INSTALL_DIR/data
EOF
    
    chmod 644 "$INSTALL_DIR/config/config.yaml"
    success "Configuration created"
}

# Verify installation
verify_installation() {
    info "Verifying installation..."
    
    if [ ! -x "$BIN_DIR/$BINARY_NAME" ]; then
        error "Binary not found or not executable"
    fi
    
    if ! "$BIN_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
        warn "Binary may not support --version flag, but it exists"
    fi
    
    success "Installation verified"
}

# Cleanup
cleanup() {
    if [ -n "${temp_dir:-}" ] && [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Main installation
main() {
    show_banner
    
    trap cleanup EXIT
    
    info "Starting TypeGen installation..."
    echo ""
    
    check_root
    check_dependencies
    detect_system
    get_version
    
    temp_dir=$(download_binary)
    install_binary "$temp_dir"
    create_directories
    create_config
    verify_installation
    
    echo ""
    success "TypeGen installed successfully!"
    echo ""
    echo "  Binary location: $BIN_DIR/$BINARY_NAME"
    echo "  Config location: $INSTALL_DIR/config/config.yaml"
    echo "  Data directory:  $INSTALL_DIR/data"
    echo ""
    echo "Run '$BINARY_NAME --help' to get started"
    echo ""
}

# Run main function
main

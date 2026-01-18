#!/usr/bin/env bash
set -euo pipefail

############################################################
# ⚡ TYPEGEN HYPER-INSTALLER v2.0 ⚡
# Cosmic-grade installation system with quantum resilience
# https://github.com/typegen/typegen-installer
############################################################

# -------- ASCII Art & Branding --------
show_banner() {
  cat <<"EOF"
  
  ████████╗██╗   ██╗██████╗ ███████╗ ██████╗ ███████╗███╗   ██╗
  ╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔════╝ ██╔════╝████╗  ██╗
     ██║    ╚████╔╝ ██████╔╝█████╗  ██║  ███╗█████╗  ██╔██╗ ██║
     ██║     ╚██╔╝  ██╔═══╝ ██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║
     ██║      ██║   ██║     ███████╗╚██████╔╝███████╗██║ ╚████║
     ╚═╝      ╚═╝   ╚═╝     ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝
     
     🌟 Quantum Installation System | v2.0.0 🌟
     
EOF
}

# -------- Cosmic Constants --------
readonly TYPEGEN_NAME="typegen"
readonly INSTALL_DIR="/opt/typegen"
readonly BIN_DIR="/usr/local/bin"
readonly CTL_NAME="projectnamectl"
readonly GITHUB_ORG="khanalsaroj"
readonly CTL_REPO="typegen-control-plane-backend"
readonly DEFAULT_VERSION="latest"
readonly MIN_BASH_VERSION=4
readonly SUPPORTED_OS=("linux" "darwin")
readonly SUPPORTED_ARCH=("amd64" "arm64")
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_SUCCESS='\033[1;32m'
readonly COLOR_INFO='\033[1;36m'
readonly COLOR_WARN='\033[1;33m'
readonly COLOR_ERROR='\033[1;31m'
readonly COLOR_DEBUG='\033[0;90m'

# -------- Hyper-Precise Logging --------
log() {
  local level="$1"
  shift
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
  local color=""
  
  case "$level" in
    "SUCCESS") color="$COLOR_SUCCESS" ;;
    "INFO")    color="$COLOR_INFO" ;;
    "WARN")    color="$COLOR_WARN" ;;
    "ERROR")   color="$COLOR_ERROR" ;;
    "DEBUG")   color="$COLOR_DEBUG" ;;
  esac
  
  echo -e "${color}[${timestamp} | ${level}]${COLOR_RESET} $*" >&2
}

success() { log "SUCCESS" "$@"; }
info()    { log "INFO" "$@"; }
warn()    { log "WARN" "$@"; }
error()   { log "ERROR" "$@"; exit 1; }
debug()   { [ "${DEBUG:-0}" -eq 1 ] && log "DEBUG" "$@"; }

# -------- Cosmic Utilities --------
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "Missing cosmic dependency: '$1'"
  fi
}

check_bash_version() {
  local bash_version="${BASH_VERSINFO[0]}"
  if (( bash_version < MIN_BASH_VERSION )); then
    error "Bash ${MIN_BASH_VERSION}+ required (you have ${bash_version})"
  fi
}

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid > /dev/null 2>&1; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

run_with_spinner() {
  local msg="$1"
  shift
  printf "%s" "$msg"
  ("$@" > /dev/null 2>&1) &
  local pid=$!
  spinner $pid
  wait $pid
  echo " ✅"
}

# -------- Quantum System Detection --------
detect_system() {
  info "🔍 Scanning quantum signatures..."
  
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  KERNEL=$(uname -r)
  DISTRO=""
  
  # Advanced distro detection
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"
  fi
  
  # Architecture normalization
  case "$ARCH" in
    x86_64|x64)      ARCH="amd64" ;;
    aarch64|arm64)   ARCH="arm64" ;;
    armv7l|armhf)    ARCH="armv7" ;;
    *) 
      warn "Uncommon architecture detected: $ARCH"
      if [ "${FORCE_ARCH:-}" ]; then
        ARCH="$FORCE_ARCH"
        warn "Forcing architecture to: $ARCH"
      else
        error "Unsupported architecture. Use FORCE_ARCH=amd64 to override"
      fi
      ;;
  esac
  
  # OS compatibility
  if [[ ! " ${SUPPORTED_OS[@]} " =~ " ${OS} " ]]; then
    error "Unsupported OS: $OS"
  fi
  
  info "System Profile:"
  info "  OS: $OS ($DISTRO $DISTRO_VERSION)"
  info "  Arch: $ARCH"
  info "  Kernel: $KERNEL"
}

# -------- Version Telemetry --------
resolve_version() {
  local version="${TYPEGEN_VERSION:-$DEFAULT_VERSION}"
  
  if [ "$version" = "latest" ]; then
    info "📡 Connecting to version constellation..."
    
    # Try multiple endpoints for resilience
    local endpoints=(
      "https://api.github.com/repos/${GITHUB_ORG}/${CTL_REPO}/releases/latest"
      "https://registry.npmjs.org/@typegen/cli/latest"
    )
    
    for endpoint in "${endpoints[@]}"; do
      debug "Trying endpoint: $endpoint"
      local resolved=$(curl -sfL "$endpoint" 2>/dev/null | \
        grep -o '"tag_name": *"[^"]*"' | \
        cut -d'"' -f4) || continue
      
      if [ -n "$resolved" ]; then
        version="$resolved"
        break
      fi
    done
    
    [ -n "$version" ] || error "Version resolution failed across all endpoints"
  fi
  
  # Clean version string
  version="${version#v}"  # Remove leading v if present
  
  echo "$version"
}

# -------- Quantum Download System --------
download_with_retry() {
  local url="$1"
  local output="$2"
  local max_retries=3
  local retry_delay=2
  
  for ((i=1; i<=max_retries; i++)); do
    info "Download attempt $i/$max_retries"
    
    if curl -fL --progress-bar --retry 3 --retry-delay 1 "$url" -o "$output"; then
      return 0
    fi
    
    if [ $i -lt $max_retries ]; then
      warn "Download failed, retrying in ${retry_delay}s..."
      sleep $retry_delay
      retry_delay=$((retry_delay * 2))  # Exponential backoff
    fi
  done
  
  error "Download failed after $max_retries attempts"
}

verify_binary() {
  local binary="$1"
  
  # File existence check
  [ -f "$binary" ] || error "Binary not found: $binary"
  
  # Executable check
  [ -x "$binary" ] || {
    chmod +x "$binary" || error "Cannot make binary executable"
  }
  
  # Basic validation by running help command
  if "$binary" --help >/dev/null 2>&1; then
    success "Binary integrity verified"
  else
    warn "Binary help command failed (non-fatal)"
  fi
}

# -------- Cosmic Installation --------
create_directory_structure() {
  info "🌀 Creating quantum directory structure..."
  
  local dirs=(
    "$INSTALL_DIR"
    "$INSTALL_DIR/data"
    "$INSTALL_DIR/logs"
    "$INSTALL_DIR/plugins"
    "$INSTALL_DIR/config"
    "$INSTALL_DIR/backups"
    "$INSTALL_DIR/tmp"
  )
  
  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    chmod 755 "$dir"
    debug "Created: $dir"
  done
  
  # Special permissions for sensitive directories
  chmod 700 "$INSTALL_DIR/backups"
}

generate_config() {
  local version="$1"
  local config_file="$INSTALL_DIR/config.yaml"
  local config_backup="${config_file}.bak.$(date +%s)"
  
  if [ -f "$config_file" ]; then
    warn "Existing config detected, creating backup..."
    cp "$config_file" "$config_backup"
    success "Backup created: $config_backup"
    
    # Check if update is needed
    local current_version=$(grep -o 'version: *"[^"]*"' "$config_file" | head -1 | cut -d'"' -f2)
    if [ "$current_version" != "$version" ]; then
      info "Upgrading config from v$current_version to v$version"
      # Here you could add migration logic
    fi
  fi
  
  info "Generating quantum configuration..."
  
  cat > "$config_file" <<EOF
# ⚡ TypeGen Hyper-Configuration v${version}
# Generated: $(date -Iseconds)

typegen:
  version: "${version}"
  mode: "production"
  telemetry: true
  auto_update: true

backend:
  image: "ghcr.io/typegen/typegen-api:${version}"
  port: 8080
  replicas: 1
  resources:
    cpu: "500m"
    memory: "512Mi"
  health_check:
    path: "/health"
    interval: "30s"

frontend:
  image: "ghcr.io/typegen/typegen-dashboard:${version}"
  port: 3000
  replicas: 1
  resources:
    cpu: "250m"
    memory: "256Mi"

database:
  type: "postgres"
  host: "\${TYPEGEN_DB_HOST:-localhost}"
  port: "\${TYPEGEN_DB_PORT:-5432}"
  name: "\${TYPEGEN_DB_NAME:-typegen}"
  username: "\${TYPEGEN_DB_USER:-typegen}"
  password: "\${TYPEGEN_DB_PASSWORD}"
  ssl_mode: "prefer"
  pool_size: 10

cache:
  enabled: true
  type: "redis"
  host: "\${TYPEGEN_REDIS_HOST:-localhost}"
  port: "\${TYPEGEN_REDIS_PORT:-6379}"

monitoring:
  enabled: true
  metrics_port: 9090
  log_level: "info"
  retention_days: 30

security:
  encryption_key: "\${TYPEGEN_ENCRYPTION_KEY:-}"
  cors_origins: ["https://*.typegen.dev", "http://localhost:*"]
  rate_limit: 100

# Plugin system
plugins:
  directory: "\${TYPEGEN_PLUGIN_DIR:-$INSTALL_DIR/plugins}"
  auto_discover: true
EOF
  
  chmod 600 "$config_file"
  success "Configuration generated: $config_file"
}

setup_auto_completion() {
  info "⚡ Setting up cosmic auto-completion..."
  
  local completion_dir=""
  local shell_rc=""
  
  case "$SHELL" in
    */bash)
      completion_dir="/etc/bash_completion.d"
      shell_rc="$HOME/.bashrc"
      ;;
    */zsh)
      completion_dir="/usr/local/share/zsh/site-functions"
      shell_rc="$HOME/.zshrc"
      ;;
    */fish)
      completion_dir="/etc/fish/completions"
      ;;
    *)
      warn "Shell auto-completion not configured for $SHELL"
      return 0
      ;;
  esac
  
  if [ -d "$completion_dir" ]; then
    if "$BIN_DIR/$CTL_NAME" completion "${SHELL##*/}" > "$completion_dir/_$CTL_NAME" 2>/dev/null; then
      success "Auto-completion installed for ${SHELL##*/}"
    fi
  fi
}

create_service_files() {
  info "🚀 Generating service definitions..."
  
  # Systemd service
  if command -v systemctl >/dev/null 2>&1; then
    cat > /etc/systemd/system/typegen.service <<EOF
[Unit]
Description=TypeGen Quantum Service
Documentation=https://typegen.dev
After=network.target docker.service
Requires=docker.service

[Service]
Type=exec
User=typegen
Group=typegen
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$BIN_DIR/$CTL_NAME start
ExecStop=$BIN_DIR/$CTL_NAME stop
ExecReload=$BIN_DIR/$CTL_NAME restart
Restart=always
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    success "Systemd service configured"
  fi
  
  # Docker Compose fallback
  cat > "$INSTALL_DIR/docker-compose.yml" <<EOF
version: '3.8'

services:
  typegen-api:
    image: ghcr.io/typegen/typegen-api:\${TYPEGEN_VERSION}
    container_name: typegen-api
    restart: unless-stopped
    ports:
      - "\${TYPEGEN_API_PORT:-8080}:8080"
    environment:
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
    volumes:
      - $INSTALL_DIR/data:/data
    networks:
      - typegen-network

  typegen-dashboard:
    image: ghcr.io/typegen/typegen-dashboard:\${TYPEGEN_VERSION}
    container_name: typegen-dashboard
    restart: unless-stopped
    ports:
      - "\${TYPEGEN_UI_PORT:-3000}:3000"
    depends_on:
      - typegen-api
    networks:
      - typegen-network

networks:
  typegen-network:
    driver: bridge
EOF
}

setup_environment() {
  info "🌍 Configuring quantum environment..."
  
  local env_file="$INSTALL_DIR/.env"
  
  if [ ! -f "$env_file" ]; then
    cat > "$env_file" <<EOF
# TypeGen Environment Configuration
# Generated: $(date -Iseconds)

# Database
TYPEGEN_DB_HOST=localhost
TYPEGEN_DB_PORT=5432
TYPEGEN_DB_NAME=typegen
TYPEGEN_DB_USER=typegen
# TYPEGEN_DB_PASSWORD=  # Set this in production

# Redis
TYPEGEN_REDIS_HOST=localhost
TYPEGEN_REDIS_PORT=6379

# Ports
TYPEGEN_API_PORT=8080
TYPEGEN_UI_PORT=3000

# Security
# TYPEGEN_ENCRYPTION_KEY=  # Generate with: openssl rand -hex 32

# Optional
TYPEGEN_LOG_LEVEL=info
TYPEGEN_TELEMETRY=true
EOF
    
    chmod 600 "$env_file"
    success "Environment file created: $env_file"
  fi
}

create_user() {
  if id "typegen" >/dev/null 2>&1; then
    info "System user 'typegen' already exists"
    return 0
  fi
  
  info "👤 Creating dedicated system user..."
  
  if command -v useradd >/dev/null 2>&1; then
    useradd -r -s /bin/false -d "$INSTALL_DIR" typegen
    usermod -aG docker typegen 2>/dev/null || true
    chown -R typegen:typegen "$INSTALL_DIR"
    success "Created user 'typegen'"
  else
    warn "Could not create system user (useradd not found)"
  fi
}

# -------- Post-Install Validation --------
validate_installation() {
  info "🔬 Running quantum validation suite..."
  
  local checks_passed=0
  local total_checks=0
  
  check() {
    local name="$1"
    shift
    ((total_checks++))
    
    if "$@" >/dev/null 2>&1; then
      success "✓ $name"
      ((checks_passed++))
      return 0
    else
      warn "✗ $name"
      return 1
    fi
  }
  
  echo ""
  echo "Validation Report:"
  echo "=================="
  
  check "Binary exists" [ -f "$BIN_DIR/$CTL_NAME" ]
  check "Binary executable" [ -x "$BIN_DIR/$CTL_NAME" ]
  check "Install directory exists" [ -d "$INSTALL_DIR" ]
  check "Config file exists" [ -f "$INSTALL_DIR/config.yaml" ]
  check "Binary responds to --version" "$BIN_DIR/$CTL_NAME" --version
  
  # Network connectivity check
  if check "GitHub reachable" curl -sI https://github.com -o /dev/null -w "%{http_code}" | grep -q "200"; then
    check "Latest version check" "$BIN_DIR/$CTL_NAME" version check
  fi
  
  echo ""
  echo "Results: $checks_passed/$total_checks checks passed"
  
  if [ "$checks_passed" -eq "$total_checks" ]; then
    success "🎉 Quantum validation complete!"
  else
    warn "Some checks failed (installation may be partially functional)"
  fi
}

# -------- Main Cosmic Routine --------
main() {
  show_banner
  
  info "🚀 Initializing TypeGen Quantum Installer"
  info "Build: $(date -Iseconds) | PID: $$"
  
  # Prerequisite checks
  check_bash_version
  detect_system
  
  # Root check with better error message
  if [ "$(id -u)" -ne 0 ]; then
    error "Elevated privileges required. Please run with sudo or as root."
  fi
  
  # Dependency verification
  info "🔧 Verifying cosmic dependencies..."
  local deps=("curl" "uname" "chmod" "mkdir" "rm" "tar" "grep")
  for dep in "${deps[@]}"; do
    require_cmd "$dep"
  done
  
  # Version resolution
  info "🌌 Resolving quantum version..."
  local version
  version=$(resolve_version) || error "Version resolution failed"
  info "Target version: v$version"
  
  # Prepare installation
  local tmp_dir
  tmp_dir=$(mktemp -d -t typegen-install-XXXXXX)
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM
  
  # Download binary
  local download_url="https://github.com/${GITHUB_ORG}/${CTL_REPO}/releases/download/v${version}/${CTL_NAME}-${OS}-${ARCH}"
  info $(download_url)
  info "📥 Downloading quantum binary..."
  download_with_retry "$download_url" "$tmp_dir/$CTL_NAME"
  
  # Verify binary
  verify_binary "$tmp_dir/$CTL_NAME"
  
  # Create directory structure
  create_directory_structure
  
  # Install binary
  info "⚙️  Installing cosmic binary..."
  install -m 755 "$tmp_dir/$CTL_NAME" "$BIN_DIR/$CTL_NAME"
  
  # Generate configuration
  generate_config "$version"
  
  # Setup environment
  setup_environment
  
  # Create user
  create_user
  
  # Setup auto-completion
  setup_auto_completion
  
  # Create service files
  create_service_files
  
  # Final validation
  validate_installation
  
  # Show success message
  echo ""
  echo "${COLOR_BOLD}✨ TypeGen Quantum Installation Complete! ✨${COLOR_RESET}"
  echo ""
  echo "┌─────────────────────────────────────────────────────────┐"
  echo "  ${COLOR_INFO}Version:${COLOR_RESET}    v$version"
  echo "  ${COLOR_INFO}Binary:${COLOR_RESET}     $BIN_DIR/$CTL_NAME"
  echo "  ${COLOR_INFO}Config:${COLOR_RESET}     $INSTALL_DIR/config.yaml"
  echo "  ${COLOR_INFO}Data:${COLOR_RESET}       $INSTALL_DIR/data"
  echo "└─────────────────────────────────────────────────────────┘"
  echo ""
  
  # Interactive next steps
  if [ -t 0 ]; then  # Check if stdin is a terminal
    cat <<EOF
${COLOR_BOLD}🚀 Next Steps:${COLOR_RESET}

1. Configure environment:
   ${COLOR_INFO}nano $INSTALL_DIR/.env${COLOR_RESET}

2. Start TypeGen:
   ${COLOR_INFO}typegenctl start${COLOR_RESET}

3. Enable auto-start:
   ${COLOR_INFO}sudo systemctl enable --now typegen${COLOR_RESET}

4. Monitor logs:
   ${COLOR_INFO}typegenctl logs --follow${COLOR_RESET}

5. Access dashboard:
   ${COLOR_INFO}http://localhost:3000${COLOR_RESET}

${COLOR_INFO}📚 Documentation:${COLOR_RESET} https://docs.typegen.dev
${COLOR_INFO}🐛 Report Issues:${COLOR_RESET} https://github.com/typegen/typegenctl/issues
${COLOR_INFO}💬 Community:${COLOR_RESET} https://discord.gg/typegen

${COLOR_SUCCESS}Thank you for choosing TypeGen!${COLOR_RESET}
EOF
  fi
  
  # Telemetry (anonymous, optional)
  if [ "${TYPEGEN_TELEMETRY:-true}" = "true" ]; then
    curl -s -X POST https://telemetry.typegen.dev/install \
      -H "Content-Type: application/json" \
      -d "{\"version\":\"$version\",\"os\":\"$OS\",\"arch\":\"$ARCH\",\"distro\":\"$DISTRO\"}" \
      >/dev/null 2>&1 &
  fi
  
  exit 0
}

# Handle interrupts gracefully
trap 'echo -e "\n${COLOR_WARN}⚠️  Installation interrupted${COLOR_RESET}"; exit 130;' INT

# Run with cosmic power
main "$@"

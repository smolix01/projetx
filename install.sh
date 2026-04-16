#!/bin/bash

# =============================================================================
# Email Delivery Platform - One-Click Installer
# =============================================================================
# This script installs and configures the entire Email Delivery Platform
# including PostgreSQL, Redis, Postfix, Backend API, and Frontend Dashboard
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="email-platform"
INSTALL_DIR="/opt/${PROJECT_NAME}"
DOMAIN="${DOMAIN:-localhost}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@localhost}"

# Print functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    print_info "Detected OS: $OS $VER"
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt-get update -qq
        apt-get upgrade -y -qq
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum update -y -q
    fi
    
    print_success "System packages updated"
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt-get install -y -qq \
            curl \
            wget \
            git \
            nano \
            htop \
            net-tools \
            software-properties-common \
            apt-transport-https \
            ca-certificates \
            gnupg \
            lsb-release \
            build-essential \
            python3 \
            python3-pip \
            python3-venv \
            python3-dev \
            libpq-dev \
            nodejs \
            npm \
            docker.io \
            docker-compose
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y -q \
            curl \
            wget \
            git \
            nano \
            htop \
            net-tools \
            yum-utils \
            device-mapper-persistent-data \
            lvm2 \
            python3 \
            python3-pip \
            python3-devel \
            postgresql-devel \
            nodejs \
            npm \
            docker \
            docker-compose
    fi
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    print_success "Dependencies installed"
}

# Install Docker if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        print_info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        print_success "Docker installed"
    else
        print_success "Docker already installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_info "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose installed"
    else
        print_success "Docker Compose already installed"
    fi
}

# Create project directory
setup_directories() {
    print_header "Setting up Directories"
    
    mkdir -p ${INSTALL_DIR}
    cd ${INSTALL_DIR}
    
    # Create subdirectories
    mkdir -p {backend,frontend,database,scripts,logs}
    mkdir -p database/postgres_data
    mkdir -p database/redis_data
    mkdir -p database/postfix_data
    
    print_success "Directories created at ${INSTALL_DIR}"
}

# Generate environment files
generate_env_files() {
    print_header "Generating Configuration Files"
    
    # Generate secrets
    SECRET_KEY=$(openssl rand -hex 32)
    JWT_SECRET=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    
    # Backend .env
    cat > ${INSTALL_DIR}/backend/.env << EOF
# Application Settings
APP_NAME="Email Delivery Platform"
APP_VERSION=1.0.0
DEBUG=false
SECRET_KEY=${SECRET_KEY}

# Server Settings
HOST=0.0.0.0
PORT=8000

# Database Settings
DATABASE_URL=postgresql+asyncpg://emailuser:${POSTGRES_PASSWORD}@postgres:5432/emailplatform
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10

# Redis Settings
REDIS_URL=redis://redis:6379/0
REDIS_POOL_SIZE=10

# JWT Settings
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# SMTP Settings
SMTP_HOST=postfix
SMTP_PORT=587
SMTP_TLS=true
SMTP_SSL=false
SMTP_USERNAME=
SMTP_PASSWORD=

# Postfix Settings
POSTFIX_HOST=postfix
POSTFIX_PORT=25
POSTFIX_USE_TLS=false

# Bounce Processing Settings
BOUNCE_IMAP_HOST=postfix
BOUNCE_IMAP_PORT=993
BOUNCE_IMAP_USER=bounce@${DOMAIN}
BOUNCE_IMAP_PASSWORD=
BOUNCE_CHECK_INTERVAL=300

# Tracking Settings
TRACKING_DOMAIN=${DOMAIN}
TRACKING_ENABLED=true

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000
RATE_LIMIT_PER_DAY=10000

# Bulk Email Settings
BULK_BATCH_SIZE=100
BULK_WORKER_COUNT=4
BULK_SEND_INTERVAL=1

# File Upload Settings
MAX_UPLOAD_SIZE=52428800
UPLOAD_DIR=/tmp/uploads

# CORS Settings
CORS_ORIGINS=http://localhost:3000,http://${DOMAIN}:3000

# DKIM Settings
DKIM_PRIVATE_KEY_PATH=
DKIM_SELECTOR=default
EOF

    # Frontend .env
    cat > ${INSTALL_DIR}/frontend/.env.local << EOF
NEXT_PUBLIC_API_URL=http://${DOMAIN}:8000/api/v1
NEXT_PUBLIC_TRACKING_DOMAIN=${DOMAIN}
EOF

    # Docker Compose .env
    cat > ${INSTALL_DIR}/.env << EOF
# Database
POSTGRES_USER=emailuser
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=emailplatform

# Application
SECRET_KEY=${SECRET_KEY}
JWT_SECRET=${JWT_SECRET}
DEBUG=false
DOMAIN=${DOMAIN}

# Ports
BACKEND_PORT=8000
FRONTEND_PORT=3000
POSTGRES_PORT=5432
REDIS_PORT=6379
SMTP_PORT=25
SMTPS_PORT=465
SUBMISSION_PORT=587
EOF

    print_success "Configuration files generated"
}

# Create Docker Compose file
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    
    cat > ${INSTALL_DIR}/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: email-platform-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./database/postgres_data:/var/lib/postgresql/data
    ports:
      - "${POSTGRES_PORT}:5432"
    networks:
      - email-platform-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache & Queue
  redis:
    image: redis:7-alpine
    container_name: email-platform-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - ./database/redis_data:/data
    ports:
      - "${REDIS_PORT}:6379"
    networks:
      - email-platform-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Postfix SMTP Server
  postfix:
    image: boky/postfix:latest
    container_name: email-platform-postfix
    restart: unless-stopped
    environment:
      POSTFIX_myhostname: mail.${DOMAIN}
      POSTFIX_mydestination: localhost
      POSTFIX_mynetworks: 0.0.0.0/0
      POSTFIX_smtpd_tls_security_level: may
      POSTFIX_smtp_tls_security_level: may
      ALLOWED_SENDER_DOMAINS: ${DOMAIN}
    volumes:
      - ./database/postfix_data:/var/spool/postfix
    ports:
      - "${SMTP_PORT}:25"
      - "${SUBMISSION_PORT}:587"
      - "${SMTPS_PORT}:465"
    networks:
      - email-platform-network

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: email-platform-backend
    restart: unless-stopped
    env_file:
      - ./backend/.env
    ports:
      - "${BACKEND_PORT}:8000"
    volumes:
      - ./backend:/app
      - /app/__pycache__
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      postfix:
        condition: service_started
    networks:
      - email-platform-network
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  # Email Worker
  email-worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: email-platform-email-worker
    restart: unless-stopped
    env_file:
      - ./backend/.env
    volumes:
      - ./backend:/app
      - /app/__pycache__
    depends_on:
      - postgres
      - redis
      - postfix
    networks:
      - email-platform-network
    command: python -m workers.email_worker

  # Campaign Worker
  campaign-worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: email-platform-campaign-worker
    restart: unless-stopped
    env_file:
      - ./backend/.env
    volumes:
      - ./backend:/app
      - /app/__pycache__
    depends_on:
      - postgres
      - redis
      - postfix
    networks:
      - email-platform-network
    command: python -m workers.campaign_worker

  # Bounce Worker
  bounce-worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: email-platform-bounce-worker
    restart: unless-stopped
    env_file:
      - ./backend/.env
    volumes:
      - ./backend:/app
      - /app/__pycache__
    depends_on:
      - postgres
      - redis
    networks:
      - email-platform-network
    command: python -m workers.bounce_worker

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: email-platform-frontend
    restart: unless-stopped
    env_file:
      - ./frontend/.env.local
    ports:
      - "${FRONTEND_PORT}:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    depends_on:
      - backend
    networks:
      - email-platform-network
    command: npm run dev

volumes:
  postgres_data:
  redis_data:
  postfix_data:

networks:
  email-platform-network:
    driver: bridge
EOF

    print_success "Docker Compose configuration created"
}

# Create startup script
create_startup_script() {
    print_header "Creating Management Scripts"
    
    cat > ${INSTALL_DIR}/start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose up -d
EOF

    cat > ${INSTALL_DIR}/stop.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose down
EOF

    cat > ${INSTALL_DIR}/restart.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose restart
EOF

    cat > ${INSTALL_DIR}/logs.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose logs -f
EOF

    cat > ${INSTALL_DIR}/status.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose ps
EOF

    cat > ${INSTALL_DIR}/update.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker-compose pull
docker-compose up -d --build
EOF

    chmod +x ${INSTALL_DIR}/*.sh
    
    print_success "Management scripts created"
}

# Create systemd service
create_systemd_service() {
    print_header "Creating Systemd Service"
    
    cat > /etc/systemd/system/email-platform.service << EOF
[Unit]
Description=Email Delivery Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/start.sh
ExecStop=${INSTALL_DIR}/stop.sh

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable email-platform.service
    
    print_success "Systemd service created and enabled"
}

# Setup firewall
setup_firewall() {
    print_header "Configuring Firewall"
    
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 25/tcp
        ufw allow 587/tcp
        ufw allow 465/tcp
        ufw allow 8000/tcp
        ufw allow 3000/tcp
        ufw allow 5432/tcp
        ufw allow 6379/tcp
        
        if ! ufw status | grep -q "Status: active"; then
            echo "y" | ufw enable
        fi
        
        print_success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=25/tcp
        firewall-cmd --permanent --add-port=587/tcp
        firewall-cmd --permanent --add-port=465/tcp
        firewall-cmd --permanent --add-port=8000/tcp
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --reload
        print_success "Firewalld configured"
    fi
}

# Start services
start_services() {
    print_header "Starting Services"
    
    cd ${INSTALL_DIR}
    docker-compose up -d
    
    print_info "Waiting for services to start..."
    sleep 30
    
    print_success "Services started"
}

# Display final information
show_completion_info() {
    print_header "Installation Complete!"
    
    echo -e "${GREEN}Email Delivery Platform has been successfully installed!${NC}"
    echo ""
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "  Dashboard:    ${GREEN}http://${DOMAIN}:3000${NC}"
    echo -e "  API:          ${GREEN}http://${DOMAIN}:8000${NC}"
    echo -e "  API Docs:     ${GREEN}http://${DOMAIN}:8000/docs${NC}"
    echo ""
    echo -e "${BLUE}SMTP Settings:${NC}"
    echo -e "  Host:         ${GREEN}${DOMAIN}${NC}"
    echo -e "  Port:         ${GREEN}587 (TLS)${NC}"
    echo -e "  Port:         ${GREEN}465 (SSL)${NC}"
    echo -e "  Port:         ${GREEN}25 (Plain)${NC}"
    echo ""
    echo -e "${BLUE}Management Commands:${NC}"
    echo -e "  Start:        ${YELLOW}cd ${INSTALL_DIR} && ./start.sh${NC}"
    echo -e "  Stop:         ${YELLOW}cd ${INSTALL_DIR} && ./stop.sh${NC}"
    echo -e "  Restart:      ${YELLOW}cd ${INSTALL_DIR} && ./restart.sh${NC}"
    echo -e "  Logs:         ${YELLOW}cd ${INSTALL_DIR} && ./logs.sh${NC}"
    echo -e "  Status:       ${YELLOW}cd ${INSTALL_DIR} && ./status.sh${NC}"
    echo ""
    echo -e "${BLUE}Systemd Service:${NC}"
    echo -e "  Start:        ${YELLOW}systemctl start email-platform${NC}"
    echo -e "  Stop:         ${YELLOW}systemctl stop email-platform${NC}"
    echo -e "  Status:       ${YELLOW}systemctl status email-platform${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Access the dashboard at http://${DOMAIN}:3000"
    echo "  2. Register a new account"
    echo "  3. Configure your domain DNS settings"
    echo "  4. Create SMTP credentials"
    echo "  5. Start sending emails!"
    echo ""
    echo -e "${GREEN}Thank you for installing Email Delivery Platform!${NC}"
}

# Main installation function
main() {
    print_header "Email Delivery Platform - Installer"
    
    check_root
    detect_os
    
    # Get user input
    read -p "Enter your domain (default: localhost): " input_domain
    DOMAIN=${input_domain:-localhost}
    
    read -p "Enter admin email (default: admin@localhost): " input_email
    ADMIN_EMAIL=${input_email:-admin@localhost}
    
    print_info "Starting installation with domain: $DOMAIN"
    
    update_system
    install_dependencies
    install_docker
    setup_directories
    generate_env_files
    create_docker_compose
    create_startup_script
    create_systemd_service
    setup_firewall
    start_services
    show_completion_info
}

# Run main function
main "$@"

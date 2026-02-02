#!/bin/bash

# SSL Setup Script for Dendreo Progression
# This script helps set up SSL certificates for the production environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=${1:-"localhost"}
EMAIL=${2:-"admin@example.com"}
PROJECT_DIR=$(pwd)
SSL_DIR="$PROJECT_DIR/ssl"

echo -e "${GREEN}SSL Setup for Dendreo Progression${NC}"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Project Directory: $PROJECT_DIR"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are available${NC}"

# Create SSL directory
echo -e "${YELLOW}Creating SSL directory...${NC}"
mkdir -p "$SSL_DIR"
echo -e "${GREEN}✓ SSL directory created${NC}"

# Function to generate self-signed certificate
generate_self_signed() {
    echo -e "${YELLOW}Generating self-signed certificate...${NC}"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/key.pem" \
        -out "$SSL_DIR/cert.pem" \
        -subj "/C=US/ST=State/L=City/O=Dendreo/CN=$DOMAIN"
    
    chmod 644 "$SSL_DIR/cert.pem"
    chmod 600 "$SSL_DIR/key.pem"
    
    echo -e "${GREEN}✓ Self-signed certificate generated${NC}"
}

# Function to setup Let's Encrypt
setup_lets_encrypt() {
    echo -e "${YELLOW}Setting up Let's Encrypt certificate...${NC}"
    
    if ! command_exists certbot; then
        echo -e "${RED}Certbot is not installed. Installing...${NC}"
        if command_exists apt; then
            sudo apt update
            sudo apt install -y certbot
        elif command_exists yum; then
            sudo yum install -y certbot
        else
            echo -e "${RED}Could not install certbot automatically. Please install it manually.${NC}"
            exit 1
        fi
    fi
    
    # Stop nginx if running to free port 80
    echo -e "${YELLOW}Stopping nginx to free port 80...${NC}"
    docker-compose -f docker-compose.prod.yml stop nginx 2>/dev/null || true
    
    # Obtain certificate
    echo -e "${YELLOW}Obtaining Let's Encrypt certificate...${NC}"
    sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
    
    # Copy certificates
    echo -e "${YELLOW}Copying certificates...${NC}"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"
    
    # Set permissions
    sudo chown "$USER:$USER" "$SSL_DIR/cert.pem" "$SSL_DIR/key.pem"
    chmod 644 "$SSL_DIR/cert.pem"
    chmod 600 "$SSL_DIR/key.pem"
    
    echo -e "${GREEN}✓ Let's Encrypt certificate obtained${NC}"
    
    # Setup auto-renewal
    echo -e "${YELLOW}Setting up auto-renewal...${NC}"
    RENEWAL_SCRIPT="$PROJECT_DIR/scripts/renew-ssl.sh"
    
    cat > "$RENEWAL_SCRIPT" << EOF
#!/bin/bash
# SSL Certificate Renewal Script

DOMAIN="$DOMAIN"
PROJECT_DIR="$PROJECT_DIR"
SSL_DIR="$SSL_DIR"

# Renew certificate
sudo certbot renew --quiet

# Copy renewed certificates
sudo cp "/etc/letsencrypt/live/\$DOMAIN/fullchain.pem" "\$SSL_DIR/cert.pem"
sudo cp "/etc/letsencrypt/live/\$DOMAIN/privkey.pem" "\$SSL_DIR/key.pem"

# Set permissions
sudo chown "\$USER:\$USER" "\$SSL_DIR/cert.pem" "\$SSL_DIR/key.pem"
chmod 644 "\$SSL_DIR/cert.pem"
chmod 600 "\$SSL_DIR/key.pem"

# Restart nginx
cd "\$PROJECT_DIR"
docker-compose -f docker-compose.prod.yml restart nginx

echo "SSL certificate renewed and nginx restarted"
EOF
    
    chmod +x "$RENEWAL_SCRIPT"
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "0 12 * * * $RENEWAL_SCRIPT") | crontab -
    
    echo -e "${GREEN}✓ Auto-renewal configured${NC}"
}

# Function to setup commercial certificate
setup_commercial() {
    echo -e "${YELLOW}Setting up commercial certificate...${NC}"
    echo "Please place your certificate files in the ssl directory:"
    echo "  - Certificate file: $SSL_DIR/cert.pem"
    echo "  - Private key file: $SSL_DIR/key.pem"
    echo ""
    echo "After placing the files, run:"
    echo "  chmod 644 $SSL_DIR/cert.pem"
    echo "  chmod 600 $SSL_DIR/key.pem"
    echo ""
    read -p "Press Enter when you have placed the certificate files..."
    
    if [[ ! -f "$SSL_DIR/cert.pem" ]] || [[ ! -f "$SSL_DIR/key.pem" ]]; then
        echo -e "${RED}Certificate files not found. Please place them in $SSL_DIR${NC}"
        exit 1
    fi
    
    chmod 644 "$SSL_DIR/cert.pem"
    chmod 600 "$SSL_DIR/key.pem"
    
    echo -e "${GREEN}✓ Commercial certificate configured${NC}"
}

# Main menu
echo ""
echo "Choose SSL certificate type:"
echo "1) Let's Encrypt (Recommended - Free)"
echo "2) Self-signed (Development only)"
echo "3) Commercial certificate"
echo "4) Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_lets_encrypt
        ;;
    2)
        generate_self_signed
        ;;
    3)
        setup_commercial
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Update nginx configuration with domain name
echo -e "${YELLOW}Updating nginx configuration...${NC}"
sed -i "s/server_name localhost;/server_name $DOMAIN;/g" nginx/prod.conf
echo -e "${GREEN}✓ Nginx configuration updated${NC}"

# Test SSL configuration
echo -e "${YELLOW}Testing SSL configuration...${NC}"
if docker-compose -f docker-compose.prod.yml config >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker Compose configuration is valid${NC}"
else
    echo -e "${RED}✗ Docker Compose configuration has errors${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}SSL setup completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Start the production environment:"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "2. Test HTTPS access:"
echo "   https://$DOMAIN"
echo ""
echo "3. For Let's Encrypt certificates, renewal is automatic via cron"
echo ""
echo "Note: For production use, make sure your domain points to this server's IP address." 
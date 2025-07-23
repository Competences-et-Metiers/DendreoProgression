# SSL Certificate Setup

## Option 1: Let's Encrypt (Recommended - Free)

### Prerequisites
- A domain name pointing to your server
- Port 80 and 443 open on your server
- Docker and docker-compose installed

### Setup Steps

1. **Install Certbot**
```bash
# On Ubuntu/Debian
sudo apt update
sudo apt install certbot

# On CentOS/RHEL
sudo yum install certbot
```

2. **Obtain Certificate**
```bash
# Replace your-domain.com with your actual domain  
sudo certbot certonly --standalone -d your-domain.com

# For multiple domains/subdomains
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com
```

3. **Copy Certificates to Project**
```bash
# Create ssl directory if it doesn't exist
mkdir -p ssl

# Copy certificates (adjust paths as needed)
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# Set proper permissions
sudo chown $USER:$USER ssl/cert.pem ssl/key.pem
chmod 644 ssl/cert.pem
chmod 600 ssl/key.pem
```

4. **Auto-renewal Setup**
```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab for automatic renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet && cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /path/to/your/project/ssl/cert.pem && cp /etc/letsencrypt/live/your-domain.com/privkey.pem /path/to/your/project/ssl/key.pem && docker-compose -f /path/to/your/project/docker-compose.prod.yml restart nginx
```

## Option 2: Self-Signed Certificate (Development Only)

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

## Option 3: Commercial SSL Certificate

If you have a commercial SSL certificate:
1. Place your certificate file as `ssl/cert.pem`
2. Place your private key file as `ssl/key.pem`
3. Ensure proper permissions (644 for cert, 600 for key)

## Security Notes

- Never commit SSL certificates to version control
- Keep private keys secure and backed up
- Use strong passwords for private keys
- Regularly update certificates before expiration
- Monitor certificate expiration dates 
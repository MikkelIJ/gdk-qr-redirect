#!/bin/bash
# Setup Nginx, Certbot, and auto-renewal for gdk.isaksenrobinson.com

DOMAIN="gdk.isaksenrobinson.com"
APP_PORT=666

# Install Nginx and Certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Run Certbot to get SSL certificate
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m mikkelisaksen88@gmail.com --redirect

# Configure Nginx reverse proxy
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
cat <<EOF | sudo tee $NGINX_CONF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site and restart Nginx
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Set up auto-renewal with reload
sudo bash -c 'echo "0 3 * * * certbot renew --quiet --post-hook \"systemctl reload nginx\"" > /etc/cron.d/certbot-renew'

echo "Setup complete! Your app will be available at https://$DOMAIN"

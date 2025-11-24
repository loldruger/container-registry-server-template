#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1/3] Setting up environment...${NC}"

# Create default .env if missing
if [ ! -f ./.env ]; then
    echo "Creating default .env file..."
    cat > ./.env <<EOF
REGISTRY_DOMAIN=localhost
REGISTRY_PORT=443
ADMIN_USER=admin
ADMIN_PASSWORD=admin123
# Root path for all persistent data (auth, certs, images)
# Example: /mnt/external_drive/registry
DATA_ROOT=./data
CERTBOT_EMAIL=
CERTBOT_DOMAIN=
EOF
else
    echo ".env file already exists. Loading..."
fi

# Load environment variables
set -a
source ./.env
set +a

echo "Using data root: $DATA_ROOT"

# Determine which compose tool to use
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
    CLIENT_CMD="podman"
    echo "Using podman-compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    CLIENT_CMD="docker"
    echo "Using docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    CLIENT_CMD="docker"
    echo "Using docker compose (plugin)"
else
    echo -e "${RED}Error: Neither podman-compose nor docker-compose found.${NC}"
    echo "Please install one of them to proceed."
    exit 1
fi

# Create data directories
mkdir -p "$DATA_ROOT/auth" "$DATA_ROOT/images" "$DATA_ROOT/letsencrypt" "$DATA_ROOT/nginx_conf_d"

echo -e "${GREEN}[1.5/3] Initializing configuration files...${NC}"

# 1. Generate htpasswd if missing
if [ ! -f "$DATA_ROOT/auth/htpasswd" ]; then
    echo "Generating htpasswd for user: $ADMIN_USER"
    # Use temporary alpine container to generate htpasswd
    $CLIENT_CMD run --rm -v "$DATA_ROOT/auth:/auth" alpine sh -c "apk add --no-cache apache2-utils && htpasswd -Bbc /auth/htpasswd '$ADMIN_USER' '$ADMIN_PASSWORD'"
else
    echo "htpasswd already exists. Skipping."
fi

# 2. Generate Nginx Configuration
# We use sed to replace variables in the template and save it to the mounted volume.
# This ensures the config persists on the host and can be modified by Certbot.
if [ ! -f "$DATA_ROOT/nginx_conf_d/registry.conf" ]; then
    echo "Generating Nginx configuration from template..."
    sed "s/\${REGISTRY_DOMAIN}/$REGISTRY_DOMAIN/g" ./nginx/registry.conf.template > "$DATA_ROOT/nginx_conf_d/registry.conf"
else
    echo "Nginx configuration already exists. Skipping generation to preserve SSL settings."
fi

echo -e "${GREEN}[2/3] Starting services...${NC}"

echo "Initializing and starting containers..."
$COMPOSE_CMD up --build -d

# Optional: Setup SSL with Certbot
if [ -n "$CERTBOT_EMAIL" ]; then
    echo -e "${GREEN}[Extra] Setting up HTTPS with Certbot...${NC}"
    DOMAIN=${CERTBOT_DOMAIN:-$REGISTRY_DOMAIN}
    
    echo "Requesting certificate for $DOMAIN..."
    $CLIENT_CMD exec registry_nginx certbot --nginx \
      -d "$DOMAIN" \
      --email "$CERTBOT_EMAIL" \
      --agree-tos \
      --non-interactive \
      --redirect
fi

echo -e "${GREEN}[3/3] Deployment Complete!${NC}"
echo "Registry is available at https://${REGISTRY_DOMAIN}:${REGISTRY_PORT}"
echo "Login with: $CLIENT_CMD login ${REGISTRY_DOMAIN}:${REGISTRY_PORT} --tls-verify=false -u ${ADMIN_USER} -p ${ADMIN_PASSWORD}"

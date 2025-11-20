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
EOF
else
    echo ".env file already exists. Loading..."
fi

# Load environment variables
set -a
source ./.env
set +a

echo "Using data root: $DATA_ROOT"

# Create data directories
mkdir -p "$DATA_ROOT/auth" "$DATA_ROOT/certs" "$DATA_ROOT/images"

echo -e "${GREEN}[2/3] Starting services...${NC}"

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

echo "Initializing and starting containers..."
$COMPOSE_CMD up --build -d

echo -e "${GREEN}[3/3] Deployment Complete!${NC}"
echo "Registry is available at https://${REGISTRY_DOMAIN}:${REGISTRY_PORT}"
echo "Login with: $CLIENT_CMD login ${REGISTRY_DOMAIN}:${REGISTRY_PORT} --tls-verify=false -u ${ADMIN_USER} -p ${ADMIN_PASSWORD}"

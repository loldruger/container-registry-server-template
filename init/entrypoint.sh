#!/bin/sh
set -e

echo "Starting initialization..."

# 1. Generate htpasswd if missing
if [ ! -f /auth/htpasswd ]; then
    echo "Generating htpasswd for user: $ADMIN_USER"
    htpasswd -Bc /auth/htpasswd "$ADMIN_USER" "$ADMIN_PASSWORD"
    # Ensure it is readable by other containers
    chmod 644 /auth/htpasswd
else
    echo "htpasswd already exists. Skipping."
fi

# 2. Generate Self-Signed Certs if missing
if [ ! -f /certs/domain.key ] || [ ! -f /certs/domain.crt ]; then
    echo "Generating self-signed certificate for: $REGISTRY_DOMAIN"
    openssl req -newkey rsa:4096 -nodes -sha256 \
        -keyout /certs/domain.key \
        -x509 -days 365 \
        -out /certs/domain.crt \
        -subj "/CN=$REGISTRY_DOMAIN"
    # Ensure readable
    chmod 644 /certs/domain.key /certs/domain.crt
else
    echo "Certificates already exist. Skipping."
fi

echo "Initialization complete."



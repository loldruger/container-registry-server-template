## Step 1: Prepare your .env
```sh
cp .env.example .env
```

## Step 2: Set the .env:
```sh
REGISTRY_DOMAIN=example.com #your own domain
REGISTRY_PORT=443 #custom port number for secure access to registry server
ADMIN_USER=admin
ADMIN_PASSWORD=admin
DATA_ROOT=/registry # Directory where generated data persists.
CERTBOT_EMAIL=admin@example.com
CERTBOT_DOMAIN=example.com
```

## Step 3: Execute deploy.sh
```sh
./deploy.sh
```

## Step 4: Login to your Registry
After successful deployment and Certbot certificate issuance, you can log in to your registry. 
**IMPORTANT**: Once Certbot has successfully configured HTTPS, you should NOT use `--tls-verify=false`.

```sh
docker login ${REGISTRY_DOMAIN}:${REGISTRY_PORT} -u ${ADMIN_USER} -p ${ADMIN_PASSWORD}
# If you are using self-signed certificates or Certbot is not yet configured, 
# you might temporarily need to use --tls-verify=false (NOT RECOMMENDED for production):
# docker login ${REGISTRY_DOMAIN}:${REGISTRY_PORT} --tls-verify=false -u ${ADMIN_USER} -p ${ADMIN_PASSWORD}
```

Done

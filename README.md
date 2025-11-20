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
```

## Step 3: Execute deploy.sh
```sh
./deploy.sh
```

Done

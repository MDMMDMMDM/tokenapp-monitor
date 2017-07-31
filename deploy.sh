#!/bin/bash

#servers to deploy to and jumphost for the tunnel
SERVERS=( "tokenapp1.modum.intern" )
JUMP_HOST="jump.modum.io"

#if only one key is provided, both servers have the same key
PRIV_PROXY=$1
if [ "$#" -gt 1 ]; then
   PRIV_APP=$2
else
   PRIV_APP=$1
fi

if [ ! -f "$PRIV_PROXY" ]; then
    echo "Proxy private key not found! Please make sure you have the valid private key: deploy.sh private_proxy.key private_app.key"
    exit 1
fi

if [ ! -f "$PRIV_APP" ]; then
    echo "App private key not found! Please make sure you have the valid private key: deploy.sh private_proxy.key private_app.key"
    exit 1
fi

#Build and install of the frontend
if ! gradle clean distTar; then
    echo "gradle build failed"
    exit 1
fi

# Deployment
#
# Make sure to have a systemd init script as found in: https://docs.spring.io/spring-boot/docs/current/reference/html/deployment-install.html

for i in "${SERVERS[@]}"
do
    #http://www.g-loaded.eu/2006/11/24/auto-closing-ssh-tunnels/
    ssh -f -L 1234:"$i":22 -i "$PRIV_PROXY" ubuntu@"$JUMP_HOST" sleep 25; \
    #access the tokenapp server
    #ssh -i priv.key -p 1234 ubuntu@localhost
    scp -r -i "$PRIV_APP" -P 1234 build/distributions/monitoring-1.0-SNAPSHOT.tar ubuntu@localhost:/var/lib/monitoring/monitoring.tar
    ssh -i "$PRIV_APP" -p 1234 ubuntu@localhost tar xf /var/lib/monitoring/monitoring.tar -C /var/lib/monitoring
    ssh -i "$PRIV_APP" -p 1234 ubuntu@localhost sudo systemctl restart monitoring.service
done

#!/bin/bash

set -e

up () {
  docker network create ocvt-net || true
  
  docker run \
    --name nginx \
    --detach \
    --restart unless-stopped \
    --env PUID=1000 \
    --env PGID=1000 \
    --env TZ=US/Eastern \
    --env URL=ocvt.club \
    --env SUBDOMAINS=www,api \
    --env VALIDATION=http \
    --env STAGING=true \
    --volume $PWD/nginx.conf:/config/nginx/nginx.conf:ro \
    --volume $PWD/site-confs:/config/nginx/site-confs:ro \
    --publish 443:443 \
    --publish 80:80 \
    --network ocvt-net \
    linuxserver/swag:1.7.0-ls7
  
  docker run \
    --name ocvt-api \
    --detach \
    --restart unless-stopped \
    --env-file $PWD/dolabra.env \
    --volume $PWD/data:/go/src/app/data:rw \
    --network ocvt-net \
    ocvt/dolabra:1.0.1
  
  docker run \
    --name ocvt-site \
    --detach \
    --restart unless-stopped \
    --env-file $PWD/ocvt-site.env \
    --network ocvt-net \
    ocvt/ocvt-site:1.0.1
}

down () {
  docker stop nginx ocvt-api ocvt-site
  docker rm -f nginx ocvt-api ocvt-site
}

logs () {
  sudo su -c 'multitail --mergeall /var/lib/docker/containers/*/*.log'
}

$@

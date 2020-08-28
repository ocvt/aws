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
    --env SUBDOMAINS=www,api,stats \
    --env VALIDATION=http \
    --volume $PWD/nginx.conf:/config/nginx/nginx.conf:ro \
    --volume $PWD/site-confs:/config/nginx/site-confs:ro \
    --publish 443:443 \
    --publish 80:80 \
    --add-host=host.docker.internal:$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+') \
    --network ocvt-net \
    linuxserver/swag:1.7.0-ls7
  
  docker run \
    --name ocvt-api \
    --detach \
    --restart unless-stopped \
    --env-file $PWD/dolabra.env \
    --volume $PWD/data:/go/src/app/data:rw \
    --network ocvt-net \
    ocvt/dolabra:1.0.5
  
  docker run \
    --name ocvt-site \
    --detach \
    --restart unless-stopped \
    --env-file $PWD/ocvt-site.env \
    --network ocvt-net \
    ocvt/ocvt-site:1.0.5

  nohup ./goatcounter/goatcounter-v1.4.0-linux-amd64 serve -db sqlite://goatcounter/goatcounter.sqlite3 -listen :8081 -tls none >> ./goatcounter/goatcounter.log 2>&1 &
}

down () {
  docker stop nginx ocvt-api ocvt-site
  docker rm -f nginx ocvt-api ocvt-site
  pkill goatcounter
}

logs () {
  sudo su -c 'multitail --mergeall /var/lib/docker/containers/*/*.log'
}

### goatcounter

gc_create () {
  ./goatcounter/goatcounter-v1.4.0-linux-amd64 create -db sqlite://goatcounter/goatcounter.sqlite3 -domain stats.ocvt.club -email ocvt.webmaster@gmail.com
}


$@

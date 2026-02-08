#!/bin/bash
set -eu
# ZFS setup
if ! [ "$(jq -r '.full_init' $1)" = "true" ]; then
  VELDA_INST=$(jq -r '.instance_id' $1) /opt/velda/bin/reload_config
fi

if [ "$(jq -r '.full_init' $1)" = "true" ]; then
  CONFIGDIR=/etc/velda
  MARKER=/etc/velda/installed
else
  CONFIGDIR=/run/velda
  MARKER=/opt/velda/installed
fi

if [ "$(jq -r '.full_init' $1)" = "true" ]; then
  VELDA_VERSION=$(jq -r '.velda_version' $1)
  if ! (command -v velda) || [ "$(velda version)" != "${VELDA_VERSION}" ]; then
    curl "https://velda-release.s3.us-west-1.amazonaws.com/velda-${VELDA_VERSION}-linux-amd64" -o /tmp/velda
    chmod +x /tmp/velda
    mv /tmp/velda /usr/bin/velda
  fi
fi
[[ -e ${MARKER} ]] && exit 0

zfs_disks=$(jq -r '.zfs_disks[]' $1)
timeout=300
interval=2
start_time=$(date +%s)
for disk in $zfs_disks; do
  while [ ! -b "$disk" ]; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "Timeout waiting for disk $disk to appear."
      exit 1
    fi
    sleep $interval
  done
done
zpool import -f zpool || zpool create zpool $zfs_disks || zpool status zpool
zfs create zpool/images || zfs wait zpool/images

if [ "$(jq -r '.full_init' $1)" = "true" ]; then

  DOMAIN=$(jq -r '.domain' $1)
  # Create default config if not exists
  [ ! -e /etc/velda/config.yaml ] && cat << EOF > /etc/velda/config.yaml
server:
  grpc_address: ":50051"
  http_address: ":8081"
  host: ${DOMAIN}

database:
  sql:
    driver: "pgx"
    url: "<LOCAL_POSTGRES_URL>"

user_auth:
  access_token_private_key: "/etc/velda/auth_keys"
  access_token_public_key: "/etc/velda/auth_keys.pub"

  saml:
    sp_key_path: "/etc/velda/saml.key"
    sp_cert_path: "/etc/velda/saml.cert"

storage:
  zfs:
    pool: "zpool"

jump_server:
  listen_address: ":2222"
  host_private_key: "/etc/velda/jumphost"

  public_address: "${DOMAIN}:2222"
  host_public_key: "/etc/velda/jumphost.pub"
EOF

  if grep -q '<LOCAL_POSTGRES_URL>' /etc/velda/config.yaml; then
    POSTGRES_PASSWORD=$(openssl rand -hex 20)
    docker ps -a | grep -q pg || docker run -d \
      --restart=always \
      --name pg \
      -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
      -p 127.0.0.1:5432:5432 \
      -v pg-data:/var/lib/postgresql/data \
      postgres:17-alpine
    sed -i "s|<LOCAL_POSTGRES_URL>|postgres://postgres:${POSTGRES_PASSWORD}@localhost:5432/postgres?sslmode=disable|g" /etc/velda/config.yaml
  fi

  # Generate SSH ED25519 key pair for jumphost
  mkdir -p /etc/velda/envoy
  ssh-keygen -t ed25519 -f /etc/velda/jumphost -N "" -C "velda-jumphost"

  # Generate P256 key in PEM format for auth token
  openssl ecparam -name prime256v1 -genkey -noout -out /etc/velda/auth_keys
  openssl ec -in /etc/velda/auth_keys -pubout -out /etc/velda/auth_keys.pub

  # Generate self-signed SAML key (ECDSA P256, 10 years)
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/velda/saml.key -out /etc/velda/saml.cert \
    -subj "/CN=$DOMAIN"

  cat << EOF > /etc/systemd/system/velda-apiserver.service
[Unit]
Description=Velda API server
Requires=docker.service

[Service]
Type=forking
ExecStart=/usr/bin/velda apiserver --config /etc/velda/config.yaml --pidfile /etc/velda/apiserver.pid
PIDFile=/etc/velda/apiserver.pid
Restart=always
RestartSec=5
Environment="PATH=/usr/bin:/usr/sbin:/bin:/sbin:/snap/bin"
Environment="HOME=/root"
StandardError=journal

[Install]
WantedBy=default.target
EOF
  cat << EOF > /etc/systemd/system/velda-proxyserver.service
[Unit]
Description=Velda Proxy server
Requires=velda-apiserver.service

[Service]
ExecStart=/usr/bin/velda proxyserver --config /etc/velda/config.yaml
Restart=always
RestartSec=5
Environment="PATH=/usr/bin:/bin:/snap/bin"
Environment="HOME=/root"
StandardError=journal

[Install]
WantedBy=default.target
EOF

  systemctl daemon-reload

  cat << EOF > /etc/velda/envoy/envoy.yaml
admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9901 }

static_resources:
  listeners:
  - name: listener_http
    address:
      socket_address: { address: 0.0.0.0, port_value: 80 }
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          codec_type: AUTO
          route_config:
            name: local_route
            virtual_hosts:
              - name: grpc_web
                domains: ["${DOMAIN}"]
                routes:
                  - match:
                      prefix: "/api/"
                    route:
                      timeout: 0s
                      cluster: grpc_service
                      prefix_rewrite: "/"
                  - match:
                      prefix: "/velda."
                    route:
                      timeout: 0s
                      cluster: grpc_service
                  # Route all to localhost:8080
                  - match:
                      prefix: "/"
                    route:
                      cluster: apiserver_web_service
              - name: reverse_proxy
                domains: ["*.${DOMAIN}"]
                routes:
                  # Route all other requests to localhost:3000
                  - match:
                      prefix: "/"
                    route:
                      timeout: 0s
                      cluster: proxy_service
                      upgrade_configs:
                      - upgrade_type: "websocket"

          http_filters:
          - name: envoy.filters.http.grpc_web
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.grpc_web.v3.GrpcWeb
          - name: envoy.filters.http.cors
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.cors.v3.Cors
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    # gRPC Backend (localhost:50051)
    - name: grpc_service
      connect_timeout: 0.25s
      type: LOGICAL_DNS
      lb_policy: ROUND_ROBIN

      # HTTP/2 support
      typed_extension_protocol_options:
        envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
          "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
          explicit_http_config:
            http2_protocol_options: {}
      load_assignment:
        cluster_name: grpc_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address: { address: host.docker.internal, port_value: 50051 }

    # Proxy Service (localhost:8080)
    - name: proxy_service
      connect_timeout: 0.25s
      type: LOGICAL_DNS
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: proxy_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address: { address: host.docker.internal, port_value: 8080 }

    # Apiserver web Service (localhost:8081)
    - name: apiserver_web_service
      connect_timeout: 0.25s
      type: LOGICAL_DNS
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: apiserver_web_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address: { address: host.docker.internal, port_value: 8081 }
EOF

  # Setup envoy
  docker rm -f envoy || true
  docker run -d --name envoy --restart=always --add-host=host.docker.internal:host-gateway -p 80:80 -p 443:443 -v /etc/velda/envoy/:/etc/envoy/ envoyproxy/envoy:v1.26.0
else
  # Setup envoy
  docker rm -f envoy || true
  docker run -d --name envoy --restart=always --add-host=host.docker.internal:host-gateway -p 80:80 -p 443:443 -v /run/velda/envoy/:/etc/envoy/ envoyproxy/envoy:v1.26.0
fi

init_agent_image() {
  DOCKER_NAME=$1
  IMAGE_NAME=$2
  [ -d /zpool/images/$IMAGE_NAME ] && {
    echo "Image $IMAGE_NAME already exists, skipping"
    return 0
  }

  docker image pull $DOCKER_NAME
  container=$(docker create $DOCKER_NAME)
  zfs destroy -r zpool/images/$IMAGE_NAME 2> /dev/null || true
  zfs create zpool/images/$IMAGE_NAME
  docker export $container | tar -x -C /zpool/images/$IMAGE_NAME
  docker rm $container
  zfs snapshot zpool/images/$IMAGE_NAME@image
  echo "Successfully create image $IMAGE_NAME from $DOCKER_NAME"
}


# Initializing base images
for images in $(jq -c '.base_instance_images[]' $1); do
  name=$(echo "$images" | jq -r '.name')
  docker=$(echo "$images" | jq -r '.docker_name')
  init_agent_image "$docker" "$name"
done

exportfs -a
systemctl enable velda-apiserver
systemctl enable velda-proxyserver
systemctl start velda-apiserver &
systemctl start velda-proxyserver &
touch ${MARKER}

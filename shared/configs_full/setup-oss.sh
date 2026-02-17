#!/bin/bash
set -eux
# ZFS setup

CONFIGDIR=/etc/velda
MARKER=/etc/velda/installed

VELDA_VERSION=$(jq -r '.velda_version' $1)
if ! (command -v velda) || [ "$(velda version)" != "${VELDA_VERSION}" ]; then
  curl -fsSL -o /tmp/velda "https://releases.velda.io/velda-${VELDA_VERSION}-linux-amd64"
  chmod +x /tmp/velda
  mv /tmp/velda /usr/bin/velda
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

# Create default config if not exists
[ ! -e /etc/velda/config.yaml ] && cat << EOF > /etc/velda/config.yaml
server:
  grpc_address: ":50051"
  http_address: ":8081"

storage:
  zfs:
    pool: "zpool"
EOF

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
systemctl daemon-reload

exportfs -a
systemctl enable velda-apiserver
systemctl start velda-apiserver &
touch ${MARKER}

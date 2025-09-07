podman run --name kea-server -d --privileged  \
  --network vyos-internet  \
  --network vyos-wan  \
  -v kea.config:/etc/kea:z \
  -v kea.leases:/var/lib/kea:z kea-server
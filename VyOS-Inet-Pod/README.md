# VyOS Test - Internet Pod

The Kea server container will be moved to a Pod configured with both the vyod-internet and the basic podman network.

```bash
podman pod create --name vyos-wan-pod --network vyos-internet --network vyos-wan
```

```bash
podman run --pod vyos-wan-pod --name kea-server -d --privileged -v kea.config:/etc/kea:z   -v kea.leases:/var/lib/kea:z kea-server

podman run -d --pod vyos-wan-poe --name practical_clarke --privileged
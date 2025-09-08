# DMZ network

This LAN segment is needed to match the production configuration.

```bash
podman network create --internal --ipam-driver=none vyos-dmz
```
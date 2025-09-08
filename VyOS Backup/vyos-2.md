``` bash
podman run -d  --name vyos-2 --hostname gwbackup --privileged \
  --network vyos-wan:interface-name=eth0 \
  --network vyos-lan:interface-name=eth1 \
  --network vyos-dmz:interface-name=eth2 \
  -v vyos-2.config:/opt/vyatta/etc/config:z \
  -v /lib/modules:/lib/modules localhost/vyos:latest /sbin/init
  ```
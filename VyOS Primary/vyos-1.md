``` bash
podman run -d  --name vyos-1 --hostname bfnetgw --privileged \
  --network vyos-wan:interface-name=eth0 \
  --network vyos-lan:interface-name=eth1 \
  --network vyos-dmz:interface-name=eth2 \
  -v vyos-1.config:/opt/vyatta/etc/config:z \
  -v /lib/modules:/lib/modules localhost/vyos:latest /sbin/init
```
``` bash
podman run -d  --name vyos-1 --hostname bfnetgw --privileged \
  --network vyos-wan \
  --network vyos-lan \
  --network vyos-dmz \
  -v vyos-1.config:/opt/vyatta/etc/config:z \
  -v /lib/modules:/lib/modules localhost/vyos:latest /sbin/init
```
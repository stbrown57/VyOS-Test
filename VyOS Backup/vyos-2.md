``` bash
podman run -d  --name vyos-2 --hostname gwbackup --privileged \
  --network vyos-wan \
  --network vyos-lan \
  -v vyos-2.config:/opt/vyatta/etc/config:z \
  -v /lib/modules:/lib/modules localhost/vyos:latest /sbin/init
  ```
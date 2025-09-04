# Notes

## Production

### September 2, 2-25

Two VyOS podman container instances are running on two fan-less devices, (Merckx and BMC). The WAN failover is not working, however the router/firewall will work for a while when the primary WAN port is connected directly to the ISP's ethernet connection. Unfortunately, the renew does will fail on some subsequent renewal attempt. So there are two current problems with the configuration.

* Lease renewal [problem](DHCP-WAN-Renewal.md)

* WAN interface failover
  This may have been a problem with a semi-smart switch and two different VLANs. I replaced it with a unmanaged switch, we will see if that works.

## Test Environment

Initial notes

I stared with the drawing to describe the environment. Custom containers where adde to provide functionally and diagnosing the initial setup.

The configurations of both the primary and secondary VyOS instance on the proposed production devices were exported and copied to the repository.

```bash
show configuration command > [filename.conf]
```

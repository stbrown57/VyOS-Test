 # DHCP Client renewal failure
 
It looks like the lease was renewed twice on the WAN interface and failed on the third renewal (nothing magical on third attempt). This is the error:

```
Sep 01 14:37:12 dhclient[10134]: send_packet: please consult README file regarding broadcast address.

Sep 01 14:37:12 dhclient[10134]: dhclient.c:3124: Failed to send 300 byte long packet over fallback interface.

Sep 01 14:37:12 dhclient[10134]: DHCPRELEASE of 173.71.195.11 on eth0 to 173.71.195.1 port 67

Sep 01 14:37:12 dhclient[10134]: send_packet: Network is unreachable
```

Possible fixes according to Gemini are to change the dhclient-script-vyos script, the systemd file or modify the lease time. Changing the server is not an option. I haven't found the dhclient-script-vyos, I can only find the Debian default dhclient-script. If there is a modified VyOS script, an newer version of the rolling release may fix the problem.  Find the script on the running instance if possible, and review the systemd file.

Find *dhclient*

```bash
root@bfnetgw:/# find . -name "*dhclient*"
./etc/apparmor.d/local/sbin.dhclient
./etc/apparmor.d/sbin.dhclient
./etc/dhcp/dhclient-enter-hooks.d
./etc/dhcp/dhclient-enter-hooks.d/02-vyos-stopdhclient
./etc/dhcp/dhclient-exit-hooks.d
./etc/dhcp/dhclient-exit-hooks.d/03-vyos-dhclient-hook
./etc/dhcp/dhclient-exit-hooks.d/99-ipsec-dhclient-hook
./etc/dhcp/dhclient.conf
./run/dhclient
./run/dhclient/dhclient_eth0.lease
./run/dhclient/dhclient_eth0.leases
./run/dhclient/dhclient_eth0.conf
./run/systemd/system/dhclient@eth0.service.d
./sys/fs/cgroup/system.slice/system-dhclient.slice
./usr/lib/systemd/system/dhclient@.service
./usr/sbin/dhclient
./usr/sbin/dhclient-script
./usr/share/bash-completion/completions/dhclient
```

# Gemini AI says:

>
The DHCP client is failing because the network becomes unreachable when it tries to send a **DHCPRELEASE** packet. This happens because the system is attempting to stop and restart the DHCP client, likely due to a scheduled renewal. During this process, the **IP address and the default route are removed from the interface before the DHCPRELEASE packet can be successfully sent**, causing the `Network is unreachable` error.

***

## Analysis of the Logs

### Initial Success

The initial log shows the **`dhclient`** successfully acquiring an IP address (`173.71.195.11`) from the DHCP server (`173.71.195.1`). It then correctly configures the network interface, adds the search domain, and sets the nameservers. The lease is valid and set to expire, with a renewal time in 2988 seconds.

### The Failure

At the time of failure, the `systemd` process tries to stop the `dhclient` service. The logs show a sequence of events:

1. **`systemd[1]: Stopping DHCP client on eth0...`** is initiated.
2. A new `dhclient` process is started to handle the shutdown and release.
3. The new process attempts to send a **`DHCPRELEASE`** packet to the server (`173.71.195.1`).
4. Crucially, the next lines show the **`dhclient-script-vyos`** running commands to **flush the IP address** (`ip -4 addr flush dev eth0`) and **delete the default route** (`no ip route 0.0.0.0/0 173.71.195.1`).
5. This removal of network configuration happens **before** the `DHCPRELEASE` packet can be sent, resulting in the error **`send_packet: Network is unreachable`**.
6. The `dhclient` process fails to send the packet and reports a final error.
7. The service then successfully stops, but the IP address lease was not properly released, which can cause issues with the DHCP server.

### Why It's Happening

This is a classic race condition or a poor design in the network configuration script. The cleanup script is executed too early in the shutdown process, removing the necessary network configuration (the IP address and default gateway) that the DHCP client needs to communicate with the server to release the IP. Because the network interface no longer has a route to the DHCP server, the packet cannot be sent, and the release fails.

***

## Potential Solutions

To fix this, you need to modify the script or service configuration to ensure the network stack remains configured until the DHCPRELEASE packet has been successfully sent.

### Modify the DHCP Client Script

The most robust solution is to modify the `dhclient-script-vyos` to ensure the **`ip addr flush`** and **`ip route del`** commands are executed **only after** the DHCPRELEASE packet has been confirmed as sent or after the dhclient process has terminated.

### Systemd Service Configuration

If modifying the script isn't an option, you could try to adjust the `systemd` service file for `dhclient@eth0.service` (or its equivalent in VyOS). You might need to check if there are any `ExecStopPre` commands that are cleaning up the network too early.

### DHCP Lease Time

A temporary workaround would be to set a very long DHCP lease time on your DHCP server. This would minimize how often the client has to renew, thus reducing the frequency of this failure. While this doesn't fix the underlying problem, it makes it happen less often.
>

The dhclient.config could help this problem, but the problem could also be related to the MAC address configuration on the failover device.  Setting a static default route could also help.

***

## systemd file

**The systemd file looks like it may be suspect, in Gemini's opinion.**

```bash
 ### Autogenerated by interface.py ###



[Service]

ExecStart=

ExecStart=/sbin/dhclient -4 -d -nw -cf /run/dhclient/dhclient_eth0.conf -pf /run/dhclient/dhclient_eth0.pid -lf /run/dhclient/dhclient_eth0.leases -e IF_METRIC=210 eth0

ExecStop=

ExecStop=/sbin/dhclient -4 -r -d -nw -cf /run/dhclient/dhclient_eth0.conf -pf /run/dhclient/dhclient_eth0.pid -lf /run/dhclient/dhclient_eth0.leases -e IF_METRIC=210 eth0

WorkingDirectory=/run/dhclient

PIDFile=/run/dhclient/dhclient_%i.pid

/run/systemd/system/dhclient@eth0.service.d/10-override.conf (END)
```


Yes, the provided `systemd` configuration is the root cause of the problem. Specifically, the `ExecStop` line is causing the network to become unreachable, leading to the DHCP client failure.

***

### Why `ExecStop` is the Problem

The `ExecStop` line, `ExecStop=/sbin/dhclient -4 -r -d -nw -cf /run/dhclient/dhclient_eth0.conf -pf /run/dhclient/dhclient_eth0.pid -lf /run/dhclient/dhclient_eth0.leases -e IF_METRIC=210 eth0`, is designed to explicitly send a **DHCPRELEASE** packet. The **`-r`** flag stands for "release."

However, the sequence of events is incorrect. When `systemd` stops a service, it first executes the `ExecStop` command. Then, after the stop command is completed, a separate script (the `dhclient-script-vyos`) is called to flush the network configuration, including the IP address and the default route.

Based on the logs you provided, it's clear that the IP address and route are removed **before** the `dhclient -r` command can successfully send the release packet. This creates a race condition where the `ExecStop` command fails because the network is torn down from underneath it. This is why you see the `Network is unreachable` error.

Essentially, the system is telling the DHCP client to release its IP, but at the same time, it's removing the IP address and routing information that the client needs to do so. 

### Solution

The fix involves modifying the `systemd` unit file to avoid this race condition. Instead of having a dedicated `ExecStop` command to release the lease, you can let the normal service shutdown process handle it. A better approach is to not manually call `dhclient -r` in the `ExecStop` and instead rely on the `dhclient` script to handle a clean exit.

You should modify the file `/run/systemd/system/dhclient@eth0.service.d/10-override.conf` and comment out or remove the `ExecStop` lines. This would allow `systemd` to simply kill the `dhclient` process without attempting to send a release packet. The VyOS scripts are typically designed to handle this graceful termination and cleanup.
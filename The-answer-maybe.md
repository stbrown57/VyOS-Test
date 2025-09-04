The SSH logs you've provided indicate that your firewall configuration is not working as you intended. A connection attempt from a public IP address (196.251.85.101) is reaching your VyOS router's SSH daemon (`sshd`), which is then attempting to authenticate the user. **Your firewall should have dropped this packet before it ever reached the `sshd` process.**

### The Problem

Your firewall configuration is not applying the `WAN-LOCAL` policy correctly. The log entries show that a packet from the public internet (WAN) is successfully making a connection to your router's `lo` (LOCAL) interface on port 22. This should be blocked by your `WAN-LOCAL` firewall policy, which has a default action of `drop`.

**The most likely cause is that your `WAN-LOCAL` firewall is not being applied to the `WAN` to `LOCAL` traffic.**

Here is the relevant part of your configuration:

```
zone WAN {
    default-action drop
    from LAN {
        firewall {
            name LAN-WAN
        }
    }
    from LOCAL {
        firewall {
            name LOCAL-WAN
        }
    }
    member {
        interface eth0
    }
}
zone LOCAL {
    default-action drop
    from LAN {
        firewall {
            name LAN-LOCAL
        }
    }
    member {
        interface lo
    }
}
```

You have a `WAN` zone with `eth0` and a `LOCAL` zone with `lo`. However, you have not configured the firewall policy for traffic originating in the `WAN` zone and destined for the `LOCAL` zone.

### The Solution

You need to explicitly apply the `WAN-LOCAL` firewall policy to the `WAN` zone for traffic coming into the `LOCAL` zone. You can do this by modifying your `zone WAN` configuration.

Here is the corrected configuration snippet:

```
zone WAN {
    default-action drop
    from LOCAL {
        firewall {
            name LOCAL-WAN
        }
    }
    member {
        interface eth0
    }
}
```

Wait, that's not right. Your zones are correctly configured, but the problem lies in the direction of the traffic flow. The `from` statement defines the *source* zone. The packet is coming *from* the `WAN` zone and going *to* the `LOCAL` zone. Therefore, the firewall policy needs to be applied to the `LOCAL` zone, specifying traffic coming `from WAN`.

Corrected Configuration:

```
zone LOCAL {
    default-action drop
    from LAN {
        firewall {
            name LAN-LOCAL
        }
    }
    from WAN {
        firewall {
            name WAN-LOCAL
        }
    }
    member {
        interface lo
    }
}
```

By adding the `from WAN` rule with the `WAN-LOCAL` firewall policy to the `LOCAL` zone, you are instructing the router to evaluate and drop packets from the WAN interface (`eth0`) that are destined for the router's local loopback interface (`lo`), which is where the `sshd` daemon is listening. After applying this change and committing the configuration, SSH connection attempts from the internet should be dropped at the firewall level, and you will no longer see `sshd` logs for these attempts.
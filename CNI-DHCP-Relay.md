Your goals of an immutable host OS and containerized network functions are excellent, and they make perfect sense for a high-availability setup. My previous suggestions, which involved modifying the host's networking or using `network_mode: host`, would break your core design principles.

Given the constraints of your setup (atomic Fedora Core host, no host network modifications, and `podman-quadlet` with VyOS as a container), the problem is squarely in the macvlan domain. The issue is a **fundamental behavior** of the Linux kernel's macvlan driver, not a Podman or VyOS bug.

### The Problem Revisited: The Host-to-Container Loop Prevention

The Linux kernel's macvlan driver prevents a host from sending packets directly to a macvlan interface that is "attached" to it. This is done to prevent packet loops and is a core security feature of the driver.

  * **DHCP Discovery (Works)**: The initial DHCP discovery is a **broadcast** request. Broadcast packets are sent to all devices on the network, so they are not affected by this loop prevention rule. The broadcast reaches the Verizon DHCP server, which responds, and the container gets an IP.
  * **DHCP Renewal (Fails)**: The renewal is a **unicast** request directly to the DHCP server's IP. The packet leaves the container, hits the host's physical interface, and is then supposed to be forwarded to the internet. However, since the source MAC address of the packet belongs to an interface on the host, the kernel's macvlan driver may drop it because it treats it as an invalid local-to-local packet. This is why the renewal fails and you lose connectivity until the lease expires and a new broadcast discovery is triggered.

### The Solution: A CNI Plugin DHCP Proxy

Since you cannot modify the host's network or run a DHCP client on the host itself, the correct approach is to use a **CNI plugin** that acts as a DHCP proxy on behalf of the container. This plugin will perform the DHCP negotiation *for* the container, effectively bypassing the macvlan unicast communication problem.

The `dhcp` CNI plugin is designed for exactly this purpose. It is a small binary that runs as part of the Podman network configuration process. It handles the DHCP negotiation and then injects the obtained IP address, gateway, and DNS information into the container's network namespace.

#### How It Works:

1.  You configure your Podman network to use the `dhcp` IPAM plugin.
2.  When the container starts, Podman calls the `dhcp` plugin.
3.  The `dhcp` plugin directly performs the DHCP negotiation using the host's physical network interface on behalf of the container. Since the plugin is running on the host, it has direct access to the physical interface and can handle the unicast renewal requests without issue.
4.  Once the plugin obtains an IP address from the ISP, it passes this information to Podman.
5.  Podman then configures the container's macvlan interface with the IP address, lease time, and other network details.
6.  The container's internal DHCP client process is not needed because the networking is now handled by the plugin.

This setup adheres to your requirements perfectly: the host remains immutable, the networking is managed by the container runtime, and the problem of the failed unicast renewal is solved by having a process on the host handle the negotiation.

### Steps to Implement

1.  **Ensure the CNI DHCP plugin is installed**: On Fedora CoreOS, CNI plugins are typically included. If not, you may need to check the official Fedora documentation for how to install them on an atomic host. It's often packaged separately from the main `podman` package.

2.  **Create the Podman Network with a CNI IPAM Driver**: This is the critical step. Your network definition needs to specify the `dhcp` IPAM driver instead of `none`.

    ```
    podman network create --driver=macvlan --ipam-driver=dhcp -o parent=eth0 vyos-wan-net
    ```

3.  **Update your Quadlet file**: Change your `podman-quadlet` file to use the newly created network.

    ```
    [Container]
    Image=vyos/vyos-rolling
    Network=vyos-wan-net
    ...
    ```

By using the CNI `dhcp` IPAM driver, you're offloading the DHCP client functionality from the VyOS container to a host-side tool that is purpose-built to handle these kinds of network negotiations for containers. This respects the macvlan network's design while ensuring your connection remains stable.
You're right, I apologize for the misunderstanding. The key detail is that you're using **`ipam: none`**, meaning Podman is not managing IP addressing, and the container itself is running a DHCP client. This changes the root cause from a Podman IPAM plugin issue to a network layer problem specific to macvlan interfaces and how they handle unicast traffic.

Since a bare-metal VyOS instance works, the problem isn't the VyOS configuration or the Verizon DHCP server. The issue is a fundamental behavior of Linux macvlan interfaces and the host's networking stack, which affects how unicast packets (like DHCP renewal requests) are handled.

-----

### Macvlan Unicast Communication and the Host

A core feature of a **macvlan** network is that it creates virtual network interfaces that have their own unique MAC addresses but share the same physical network interface (e.g., `eth0`) as the host. From the perspective of the physical network, the container's macvlan interface appears as an entirely separate device.

However, a critical limitation is that **the host cannot communicate directly with the container's macvlan interface**. This is a **design choice** in the Linux kernel to prevent a network loop. If the host could communicate directly, a packet sent to the container would be immediately reflected back to the host's own interface, creating an infinite loop.

  * **DHCP Discovery (Works)**: The initial DHCP request is a **broadcast** packet. Broadcast packets are sent to all devices on the network, including the Verizon DHCP server. The server receives the request and sends a broadcast DHCP offer, which the container receives, and the initial lease is granted.
  * **DHCP Renewal (Fails)**: When the lease is due for renewal, the container's DHCP client sends a **unicast** DHCP request directly to the DHCP server's IP address. This unicast packet must be sent from the container's macvlan interface.
      * Since the host and the container can't communicate directly via macvlan, and the packet isn't a broadcast, it may be dropped or not properly routed by the host's networking stack. The packet never reaches the Verizon DHCP server, so the renewal fails.
      * This isn't a firewall issue in the traditional sense, but a routing and packet handling peculiarity of the macvlan driver.

The container only gets a new IP after the lease expires and it's forced to send a new **broadcast** DHCP discover packet, which, as with the initial request, is able to traverse the network correctly.

### Solutions and Workarounds

The most common solution for this specific issue is to use a **macvlan bridge** on the host. This creates a virtual bridge interface that allows direct communication between the host and the container's macvlan interface.

Here's how you can implement this:

1.  **Create a Macvlan Bridge**: Use `ip` commands to create a macvlan bridge on the host's physical interface.

    ```bash
    # Create the macvlan bridge interface
    sudo ip link add link <physical-interface> name <macvlan-bridge-name> type macvlan mode bridge
    ```

2.  **Assign an IP to the Bridge**: Give this new bridge an IP address from your local network's subnet. This is the address the host will use to talk to the container.

    ```bash
    # Assign an IP address to the macvlan bridge
    sudo ip addr add <ip-address>/<subnet-mask> dev <macvlan-bridge-name>
    # Bring the bridge up
    sudo ip link set dev <macvlan-bridge-name> up
    ```

3.  **Update your Podman Network Configuration**: Modify your Podman network to use the newly created macvlan bridge as its parent.

    ```bash
    podman network create -d macvlan --subnet <network-cidr> -o parent=<macvlan-bridge-name> --ipam-driver=none my-macvlan-network
    ```

4.  **Run the Container**: Run your container, attaching it to the new network.

    ```bash
    podman run -d --rm --name my-vyos-container --network my-macvlan-network <vyos-image>
    ```

By creating this **macvlan bridge**, you're creating a pathway that allows the unicast packets from the container's macvlan interface to be properly routed back to the host and then out to the Verizon DHCP server, solving the renewal problem without changing the DHCP client logic inside your container.
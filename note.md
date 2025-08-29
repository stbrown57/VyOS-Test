how do you simulate a basic layer 2 switch in podman environments

The best way to simulate a basic Layer 2 (L2) switch in a Podman environment is to create a custom, user-defined bridge network. Podman's default networking, which provides separate subnets for containers, is not suitable for L2 simulation. A custom bridge, however, behaves like a virtual switch, allowing containers attached to it to communicate directly using MAC addresses, much like physical devices on the same LAN segment. 
This guide uses the podman network create command, which configures the virtual networking via the netavark and aardvark-dns backends by default. 
Step 1: Create a custom Podman network
First, define a custom bridge network for your containers. The key is to run this command with the --disable-dns flag, as this creates a network that only supports L2 communication and does not provide IP address resolution. 
bash
podman network create --disable-dns l2-switch
Use code with caution.

Step 2: Run containers on the custom network
Next, launch your containers and attach them to the l2-switch network. You will also need to manually assign them a static IP address, as DHCP will not be provided on this network. 
For this example, we will use a basic Alpine Linux image and manually configure the IP addresses. 
Container 1
bash
podman run -it --network=l2-switch --name=host1 alpine sh
Use code with caution.

Inside the container, assign the IP address. 
bash
# ip addr add 192.168.1.10/24 dev eth0
# ip link set eth0 up
Use code with caution.

Container 2
Open a new terminal and launch the second container. 
bash
podman run -it --network=l2-switch --name=host2 alpine sh
Use code with caution.

Inside the container, assign a different IP address on the same subnet. 
bash
# ip addr add 192.168.1.11/24 dev eth0
# ip link set eth0 up
Use code with caution.

Step 3: Verify L2 communication
To confirm that the containers are on the same L2 segment and behaving like they are connected to a switch, you can use the ping command and inspect the ARP cache. 
From Container 1:
Ping Host 2: Ping the IP of the second container. The first packet will use ARP to resolve the MAC address.
bash
# ping -c 1 192.168.1.11
Use code with caution.

Inspect the ARP cache: Check the Address Resolution Protocol (ARP) table to see if it has learned the MAC address of Host 2.
bash
# arp -n
Use code with caution.

The output should show the MAC address of 192.168.1.11, demonstrating that the communication occurred at Layer 2.
From the host machine:
You can also inspect the network configuration from the host to see the virtual switch configuration created by Podman.
Find the bridge: Run podman network inspect to find the bridge name.
bash
podman network inspect l2-switch
Use code with caution.

Inspect the bridge: Use a tool like brctl or ip to see the virtual interfaces attached to the bridge. The host-side veth pairs for each container will be listed as ports on the virtual bridge. 
Handling rootless Podman
If you are running Podman in a rootless environment, the macvlan and ipvlan drivers have limited access to host interfaces. However, the standard bridge network created by podman network create works seamlessly in both rootful and rootless modes with the netavark backend. The simulation steps outlined above will work for both scenarios. 
AI responses may include mistakes. Learn more




Elaborate on how to inspect the bridge device created by Podman

What are the limitations of simulating a Layer 2 switch using Podman?

Show me how to set up DHCP for containers on a custom bridge network
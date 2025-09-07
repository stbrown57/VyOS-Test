Installing and configuring Kea on an Alpine-based container image is a straightforward process that involves using Alpine's package manager, **apk**, to install the necessary Kea packages and then creating a configuration file. The installation and setup are typically done within a Dockerfile to create a reproducible image.

-----

### Step 1: Create the Dockerfile

You'll start by creating a Dockerfile that uses an Alpine base image and installs Kea. You'll then add the necessary configuration files and set the command to start the Kea DHCP server.

```dockerfile
# Use a recent Alpine Linux base image
FROM alpine:latest

# Install Kea DHCP server packages
# kea-dhcp4 and kea-dhcp6 are the core DHCP server packages
# kea-ctrl-agent is the control agent for API-based management
RUN apk update && \
    apk add kea-dhcp4 kea-dhcp6 kea-ctrl-agent

# Create necessary directories for Kea
RUN mkdir -p /etc/kea /var/lib/kea /var/log/kea

# Copy the configuration files into the container
COPY kea-dhcp4.conf /etc/kea/kea-dhcp4.conf
COPY kea-dhcp6.conf /etc/kea/kea-dhcp6.conf
COPY kea-ctrl-agent.conf /etc/kea/kea-ctrl-agent.conf

# Set the command to start the Kea services
# This example uses 'keactrl' to manage the services
# It is important to run this on the host network for DHCP to function
CMD ["keactrl", "start"]
```

💡 **Note:** DHCP is a broadcast-based protocol that needs to run on the **host network** to function correctly. This is done by adding `--network host` when you run the container, which lets the container access the host machine's network stack directly.

-----

### Step 2: Create the Kea Configuration Files

Kea uses JSON files for its configuration. You'll need to create a separate configuration file for each service you want to run (DHCPv4, DHCPv6, Control Agent, etc.).

#### `kea-dhcp4.conf`

This is a basic example for an IPv4 DHCP server. Adjust the subnet, pool, and interface settings to match your network.

```json
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "eth0" ]
    },
    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/kea-dhcp4.leases"
    },
    "subnet4": [
      {
        "subnet": "192.168.1.0/24",
        "pools": [
          {
            "pool": "192.168.1.100 - 192.168.1.200"
          }
        ],
        "option-data": [
          {
            "name": "routers",
            "data": "192.168.1.1"
          },
          {
            "name": "domain-name-servers",
            "data": "8.8.8.8, 8.8.4.4"
          }
        ]
      }
    ]
  }
}
```

#### `kea-dhcp6.conf`

A basic example for an IPv6 DHCP server.

```json
{
  "Dhcp6": {
    "interfaces-config": {
      "interfaces": [ "eth0" ]
    },
    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/kea-dhcp6.leases"
    },
    "subnet6": [
      {
        "subnet": "2001:db8:1::/64",
        "pools": [
          {
            "pool": "2001:db8:1::10 - 2001:db8:1::100"
          }
        ],
        "option-data": [
          {
            "name": "dns-servers",
            "data": "2001:4860:4860::8888, 2001:4860:4860::8844"
          }
        ]
      }
    ]
  }
}
```

#### `kea-ctrl-agent.conf`

A basic example for the Control Agent, which allows management via an API.

```json
{
  "Control-agent": {
    "http-host": "0.0.0.0",
    "http-port": 8000
  }
}
```

-----

### Step 3: Build and Run the Docker Image

1.  **Build the image**: In the directory where your Dockerfile and configuration files are located, run the following command:

    ```bash
    docker build -t kea-dhcp-server .
    ```

2.  **Run the container**: Start the container using the built image. Remember to use `--network host` for the DHCP server to work properly.

    ```bash
    docker run --name kea-server --rm -d --network host kea-dhcp-server
    ```

This command will start the Kea services as a background process. To verify that the services are running, you can check the logs:

```bash
docker logs kea-server
```

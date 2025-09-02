# Use a recent Alpine Linux base image
FROM alpine:latest

# Install Kea DHCP server packages and IP routing tools
RUN apk update && \
    apk add kea-dhcp4 kea-dhcp6 kea-ctrl-agent iproute2 iptables

# Create necessary directories for Kea
RUN mkdir -p /etc/kea /var/lib/kea /var/log/kea /run/kea && chown -R kea:kea /run/kea

# Create necessary directories for iptables rules, set masquerading rule
RUN mkdir -p /etc/iptables && iptables-save > /etc/iptables/rules.v4
RUN iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Copy the configuration files and the startup script into the container
COPY startup.sh /usr/local/bin/startup.sh

# Make the startup script executable
RUN chmod +x /usr/local/bin/startup.sh

# Set the entrypoint to the startup script
ENTRYPOINT ["/usr/local/bin/startup.sh"]

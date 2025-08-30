FROM docker.io/alpine:latest

# Install necessary network utilities
RUN apk add --no-cache curl iproute2 iputils-ping tcpdump

# Set the entrypoint to keep the container running
ENTRYPOINT ["sleep", "infinity"]

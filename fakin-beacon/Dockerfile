FROM alpine:latest

# Install required packages
RUN apk add --no-cache curl jq

# Copy beacon script
COPY beacon.sh /beacon.sh
RUN chmod +x /beacon.sh

# Set up environment
ENV C2_SERVER="example.com"
ENV BASE_INTERVAL=15
ENV MAX_JITTER=5

# Run the beacon
CMD ["/beacon.sh"]
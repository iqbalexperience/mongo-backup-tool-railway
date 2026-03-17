# Use a slim Debian image
FROM debian:stable-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libgssapi-krb5-2 \
    zip \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Create data directory for backups
RUN mkdir -p /data && chmod 777 /data

# Copy the database tools (assuming they are in the context)
COPY mongodb-database-tools ./mongodb-database-tools

# Ensure tools are executable
RUN chmod -R +x ./mongodb-database-tools/bin/

# Copy the start script
COPY start.sh ./start.sh

# Ensure script is executable
RUN chmod +x ./start.sh

# Expose port for the zip server
EXPOSE 8080

# Run the script when the container starts
CMD ["./start.sh"]

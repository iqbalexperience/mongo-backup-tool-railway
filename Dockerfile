# Use a slim Debian image
FROM debian:stable-slim

# Install dependencies if any (none required for static bin but good for debugging)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy the database tools (assuming they are in the context)
COPY mongodb-database-tools ./mongodb-database-tools

# Ensure tools are executable
RUN chmod -R +x ./mongodb-database-tools/bin/

# Copy the start script
COPY start.sh ./start.sh

# Ensure script is executable
RUN chmod +x ./start.sh

# Run the script when the container starts
CMD ["./start.sh"]

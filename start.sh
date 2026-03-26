#!/bin/bash

# Load environment variables if .env file exists (local development)
if [ -f .env ]; then
  # Use a safer way to export variables
  set -a
  source .env
  set +a
fi

# Ensure backup and migration URLs are provided
if [ -z "$SOURCE_URL" ] || [ -z "$DESTINATION_URL" ]; then
  echo "Error: SOURCE_URL and DESTINATION_URL must be set as environment variables."
  exit 1
fi

# Define tool paths
DUMP_TOOL="./mongodb-database-tools/bin/mongodump"
RESTORE_TOOL="./mongodb-database-tools/bin/mongorestore"

# Ensure tools exist
if [ ! -f "$DUMP_TOOL" ] || [ ! -x "$DUMP_TOOL" ]; then
  echo "Error: mongodump not found or not executable at $DUMP_TOOL"
  exit 1
fi

if [ ! -f "$RESTORE_TOOL" ] || [ ! -x "$RESTORE_TOOL" ]; then
  echo "Error: mongorestore not found or not executable at $RESTORE_TOOL"
  exit 1
fi

# Create a directory for the dump in /data
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="/data/backup_$TIMESTAMP.archive"

echo "Step 1: Dumping data from backup database (Archive mode)..."
if "$DUMP_TOOL" --uri="$SOURCE_URL" --archive="$DUMP_FILE" --gzip; then
  echo "✅ Dump successful."
else
  echo "❌ Dump failed."
  exit 1
fi

echo "Step 2: Restoring data to migration database..."
# --archive: restore from archive file
# --gzip: decompress on the fly
# --drop: overwrite existing collections
# --nsFrom/--nsTo: ensures data maps to the DB in DESTINATION_URL regardless of source DB name
if "$RESTORE_TOOL" --uri="$DESTINATION_URL" --archive="$DUMP_FILE" --gzip --drop --nsFrom='*' --nsTo='*'; then
  echo "✅ Restore successful."
else
  echo "❌ Restore failed."
  exit 1
fi
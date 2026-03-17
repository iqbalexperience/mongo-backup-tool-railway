#!/bin/bash

# Load environment variables if .env file exists (local development)
if [ -f .env ]; then
  # Use a safer way to export variables
  set -a
  source .env
  set +a
fi

# Ensure backup and migration URLs are provided
if [ -z "$BACKUP_URL" ] || [ -z "$MIGRATION_URL" ]; then
  echo "Error: BACKUP_URL and MIGRATION_URL must be set as environment variables."
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
if "$DUMP_TOOL" --uri="$BACKUP_URL" --archive="$DUMP_FILE" --gzip; then
  echo "✅ Dump successful."
else
  echo "❌ Dump failed."
  exit 1
fi

echo "Step 2: Restoring data to migration database..."
# --archive: restore from archive file
# --gzip: decompress on the fly
# --drop: overwrite existing collections
# --nsFrom/--nsTo: ensures data maps to the DB in MIGRATION_URL regardless of source DB name
if "$RESTORE_TOOL" --uri="$MIGRATION_URL" --archive="$DUMP_FILE" --gzip --drop --nsFrom='*' --nsTo='*'; then
  echo "✅ Restore successful."
else
  echo "❌ Restore failed."
  exit 1
fi

# Step 3: Create zip of the dump
echo "Step 3: Creating zip of dump..."
ZIP_NAME="backup_$TIMESTAMP.zip"
ZIP_PATH="/data/$ZIP_NAME"
# Zip the archive file
zip -j "$ZIP_PATH" "$DUMP_FILE"

echo "✅ Zip created: $ZIP_PATH"
echo "✨ Migration completed successfully!"
echo ""
echo "--------------------------------------------------"
echo "Backup available for download at:"
echo "http://localhost:8080/$ZIP_NAME"
echo "--------------------------------------------------"
echo ""

# Step 4: Start web server to serve the zip file
echo "Starting web server to serve /data on port 8080..."
# We serve /data directory so the zip file is accessible
cd /data
python3 -m http.server 8080

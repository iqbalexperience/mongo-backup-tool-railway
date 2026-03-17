#!/bin/bash

# Load environment variables if .env file exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Ensure backup and migration URLs are provided
if [ -z "$BACKUP_URL" ] || [ -z "$MIGRATION_URL" ]; then
  echo "Error: BACKUP_URL and MIGRATION_URL must be set in your .env file."
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

# Create a temporary directory for the dump
DUMP_DIR="./tmp_dump_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DUMP_DIR"

echo "Step 1: Dumping data from backup database..."
if "$DUMP_TOOL" --uri="$BACKUP_URL" --out="$DUMP_DIR"; then
  echo "✅ Dump successful."
else
  echo "❌ Dump failed."
  rm -rf "$DUMP_DIR"
  exit 1
fi

echo "Step 2: Restoring data to migration database..."
# Use --drop to overwrite existing collections in the destination if they exist
if "$RESTORE_TOOL" --uri="$MIGRATION_URL" "$DUMP_DIR"; then
  echo "✅ Restore successful."
else
  echo "❌ Restore failed."
  # Cleanup is still good even on failure
  rm -rf "$DUMP_DIR"
  exit 1
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$DUMP_DIR"

echo "✨ Migration completed successfully!"

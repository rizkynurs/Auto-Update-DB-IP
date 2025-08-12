#!/bin/bash

# Set variables
DB_FILE="/data/dbip/dbip-full.mmdb"                     # Path to your DB-IP .mmdb file
PHP_PATH="/opt/php7/bin/php"                            # Path to PHP binary
SCRIPT_PATH="/opt/new-ip/dbip-update.php"               # Path to your DB-IP update script
REVIVE_PREFIX="revive"                                  # Prefix for revive servers
REVIVE_COUNT=12                                         # Number of revive servers

# Print current date and time
echo "Date: $(date)"

# Get old checksum
old_checksum=$(md5sum "$DB_FILE" | awk '{ print $1 }')
echo "Old checksum: $old_checksum"

# Run the DB-IP update script
echo "Updating DB-IP database..."
$PHP_PATH $SCRIPT_PATH -d ip-to-location-isp -w -q

# Get new checksum
new_checksum=$(md5sum "$DB_FILE" | awk '{ print $1 }')
echo "New checksum: $new_checksum"

# Compare checksums
if [[ "$old_checksum" != "$new_checksum" ]]; then
    echo "Database has been updated."
    echo ""
    sleep 2s

    echo "Copying to revive servers..."
    for i in $(seq 1 $REVIVE_COUNT); do
        server="${REVIVE_PREFIX}${i}"
        echo "Syncing to $server..."
        rsync -avhW --no-compress $DB_FILE rsync://$server:12000/dbip/
    done

    echo "All transfers complete."
    echo ""
    exit 0
else
    echo "Database is already up to date."
    echo ""
    exit 1
fi


# Auto-Update-DB-IP

This repository provides an automated solution for synchronizing DB-IP databases from a primary (main) server to one or more secondary (slave) servers. It ensures that all target servers are consistently updated with the latest DB-IP data, minimizing manual intervention and reducing the risk of outdated or inconsistent database information across systems.

## Features

- Automatic retrieval and transfer of DB-IP database files
- Scheduled or on-demand updates
- Support for syncing to multiple destination servers
- Simple configuration and deployment

Ideal for environments requiring up-to-date IP geolocation data across distributed systems.

## Automate Update and Distribute the MMDB File with Cron

To automate daily updates at 2:00 AM, add the following to your crontab:
```
0 2 * * * /opt/new-ip/update.sh >> /opt/new-ip/fileip.log 2>&1
```
This ensures that the update process runs regularly and logs output to /opt/new-ip/fileip.log.

### Bash Script: update.sh

You can find the Bash script used for updating the database in this repository: update.sh

This script checks if the DB-IP .mmdb file has changed (using md5sum).
If updated, it copies the file to a central server and multiple remote (slave) servers using rsync.

⚠️ Note:
Ensure that all destination (slave) servers have rsync properly set up to listen on port 12000 and that this port is accessible from the main server.

### Rsync Configuration on Slave Servers

Each slave server must have rsyncd configured and running with the following settings (typically in /etc/rsyncd.conf):
```
[dbip]
path = /data/dbip
comment = RSYNC FILES
read only = false
timeout = 300
hosts allow = INSERT_YOUR_MAIN_SERVER
hosts deny = *
uid = INSERT_YOUR_USER
gid = INSERT_YOUR_GROUP
```
- Replace INSERT_YOUR_MAIN_SERVER with the IP or hostname of your main server
- Replace INSERT_YOUR_USER and INSERT_YOUR_GROUP with the appropriate system user/group
- Make sure the /data/dbip path exists and has proper permissions

Also ensure the rsync daemon is running and listening on port 12000. You can do this by starting rsync like so:
```
rsync --daemon --port=12000
```
Or via a systemd unit or init script depending on your OS setup.


## How to Import DB-IP CSV into MySQL or MariaDB
### Prerequisites
The recommended PHP version for dbip-update is PHP 7.

### Create a Database Table

The first step is to create a new database table to hold the imported data.
If you're updating an existing production database, it's recommended to create a new table and use an atomic rename after import completes.

The table structure depends on the database edition you have (e.g., Country, City, ISP, Location + ISP).
Refer to the official schema documentation:
[Scheme documentation DB-IP](https://db-ip.com/db/)

### Use dbip-update.php to Load the Database

This script is the preferred method for downloading and loading DB-IP data into your database.
Command Line Arguments
```
-l  list available items and exit  
-n  request new items only  
-z  fetch uncompressed file (default for mmdb format)  
-Z  fetch compressed file (default for csv format)  
-w  overwrite destination file if it already exists  
-b  PDO DSN for database update (e.g., "mysql:host=localhost;dbname=dbip")  
-u  database username (default: root)  
-p  database password (default: '')  
-t  table name (default: dbip_lookup)  
-q  quiet mode  
```

for example in this repository for automated updates:
```bash
./dbip-update.php -d ip-to-location-isp -w -q
```

### Use import.php to Manually Import CSV

This is an alternative to using dbip-update.php, suitable for manual imports.
Arguments
```
-f <filename.csv[.gz]>            Required: the downloaded database file  
-d <country-lite|city-lite|location|isp|full>    Optional  
-b <database_name>                Optional (default: dbip)  
-t <table_name>                   Optional (default: dbip_lookup)  
-u <username>                     Optional (default: root)  
-p <password>                     Optional  
```
Example

./import.php -f dbip-country.csv.gz -d country -b myapp -t dbip_lookup

💡 Note: Importing the full Location + ISP database typically takes under 20 minutes depending on your system’s performance.

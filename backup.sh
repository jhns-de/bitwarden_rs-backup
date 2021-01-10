#!/bin/sh

# Check if db file is accessible and exit otherwise
if [ ! -e "$DB_FILE" ]
then
  echo "Database $DB_FILE not found!\nPlease check if you mounted the bitwarden_rs volume with '--volumes-from=bitwarden'"!
  exit 1;
fi

DB_DIR=$(dirname "$DB_FILE")
BACKUP_DIR=$(dirname "$BACKUP_FILE")

echo "Starting rsync backup of attachments and icon_cache folders"
if [ $TIMESTAMP = true ]
then
  FINAL_BACKUP_FILE="$(echo "$BACKUP_FILE")_$(date "+%F-%H%M%S")"
  /usr/bin/rsync -abi --backup-dir="$BACKUP_DIR/$(date +%F-%H%M%S)" $DB_DIR/attachments $DB_DIR/icon_cache $BACKUP_DIR
else
  FINAL_BACKUP_FILE=$BACKUP_FILE
  /usr/bin/rsync -ai $DB_DIR/attachments $DB_DIR/icon_cache $BACKUP_DIR
fi

if [ $? -eq 0 ]
then
  echo "$(date "+%F %T") - rsync Backup successfull"
else
  echo "$(date "+%F %T") - rsync Backup unsuccessfull"
fi


/usr/bin/sqlite3 $DB_FILE ".backup $FINAL_BACKUP_FILE"
if [ $? -eq 0 ]
then
  echo "$(date "+%F %T") - sqlite Backup successfull"
else
  echo "$(date "+%F %T") - sqlite Backup unsuccessfull"
fi

cd $BACKUP_DIR
/opt/duplicacy -log backup -stats -threads 15

if [ $? -eq 0 ]
then
  echo "$(date "+%F %T") - duplicacy Backup successfull"
else
  echo "$(date "+%F %T") - duplicacy Backup unsuccessfull"
fi


if [ ! -z $DELETE_AFTER ] && [ $DELETE_AFTER -gt 0 ]
then
  find $BACKUP_DIR -name "$(basename "$BACKUP_FILE")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
fi

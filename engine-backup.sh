#!/bin/bash
set -euo pipefail
BACKUP_DIR="/opt/engine-backup"
BACKUP_FILE="$BACKUP_DIR/engine-backup-main.tar.gz"
CIFS_MOUNT="/mnt/backup-srv-engine-backup"
CIFS_SHARE="//backup-srv/engine-backup$"
CIFS_USER="backupuser"
CIFS_PASS="***********"
mkdir -p "$BACKUP_DIR"
mkdir -p "$CIFS_MOUNT"

rm -f "$BACKUP_FILE"
engine-backup --mode=backup \
--scope=all \
--file="$BACKUP_FILE" \
--log="$BACKUP_DIR/engine-backup-main.log"

mount -t cifs "$CIFS_SHARE" "$CIFS_MOUNT" \
-o username="$CIFS_USER",password="$CIFS_PASS"


cp -f "$BACKUP_FILE" "$CIFS_MOUNT/engine-backup-main.tar.gz"
cp -f "$BACKUP_DIR/engine-backup-main.log" "$CIFS_MOUNT/engine-backup-main.log"
umount "$CIFS_MOUNT"

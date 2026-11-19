#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/engine-backup"
BACKUP_FILE="$BACKUP_DIR/engine-backup-main.tar.gz"

CIFS_MOUNT="/mnt/backup-srv-engine-backup"
CIFS_SHARE='//backup-srv/engine-backup$'
CIFS_USER="backupuser"
CIFS_PASS="***********"

mkdir -p "$BACKUP_DIR"
mkdir -p "$CIFS_MOUNT"

# Nyilvantartjuk, hogy a script csatolta-e a megosztast
MOUNTED_BY_SCRIPT=0

# Automatikus lecsatolas a script befejezesekor
cleanup() {
    if [ "$MOUNTED_BY_SCRIPT" -eq 1 ] && mountpoint -q "$CIFS_MOUNT"; then
        umount "$CIFS_MOUNT" || \
            echo "Figyelem: a CIFS megosztas lecsatolasa sikertelen!" >&2
    fi
}

trap cleanup EXIT

# Elozo helyi mentes torlese
rm -f "$BACKUP_FILE"

# OLVM Engine mentes
engine-backup --mode=backup \
    --scope=all \
    --file="$BACKUP_FILE" \
    --log="$BACKUP_DIR/engine-backup-main.log"

# CIFS megosztas csatolasa, ha meg nincs csatolva
if ! mountpoint -q "$CIFS_MOUNT"; then
    mount -t cifs "$CIFS_SHARE" "$CIFS_MOUNT" \
        -o "username=$CIFS_USER,password=$CIFS_PASS"

    MOUNTED_BY_SCRIPT=1
fi

# Mentes es naplofajl masolasa
cp -f "$BACKUP_FILE" \
    "$CIFS_MOUNT/engine-backup-main.tar.gz"

cp -f "$BACKUP_DIR/engine-backup-main.log" \
    "$CIFS_MOUNT/engine-backup-main.log"

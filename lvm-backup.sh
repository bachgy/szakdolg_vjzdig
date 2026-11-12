#!/bin/bash

BACKUP_DIR="/opt/backup/lvm"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Multipath eszközök lekérdezése
for WWID in $(multipath -ll 2>/dev/null | awk '$2 ~ /^dm-[0-9]+$/ {print $1}'); do

    DEV="/dev/mapper/$WWID"

    # Ellenőrzés: található-e LVM PV az eszközön
    PV=$(pvs --readonly \
        --devices "$DEV" \
        --noheadings \
        -o pv_name 2>/dev/null | xargs)

    [ -z "$PV" ] && continue

    # A PV-hez tartozó volume group lekérdezése
    VG=$(vgs --readonly \
        --devices "$DEV" \
        --noheadings \
        -o vg_name 2>/dev/null | xargs)

    [ -z "$VG" ] && continue

    BACKUP_FILE="$BACKUP_DIR/${VG}_${DATE}.vgcfg"

    echo "Multipath device: $DEV"
    echo "PV: $PV"
    echo "VG: $VG"
    echo "Backup: $BACKUP_FILE"

    # LVM metaadat mentése
    vgcfgbackup \
        --readonly \
        --devices "$DEV" \
        -f "$BACKUP_FILE" \
        "$VG"

    echo

done

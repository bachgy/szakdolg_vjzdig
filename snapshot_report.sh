#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------------
# Konfiguracio
# -------------------------------------------------------------------

SNAPSHOT_SCRIPT="/usr/share/doc/python3.11-ovirt-engine-sdk4/examples/list_vm_snapshots.py"

SMTP_SERVER="emailszerver"
SMTP_PORT="25"

MAIL_FROM="felado@vallalat.hu"
MAIL_SUBJECT="OLVM napi snapshot riport"

MAIL_TO=(
    "cimzett@vallalat.hu"
)

# -------------------------------------------------------------------
# Riport generalasa
# -------------------------------------------------------------------

REPORT_FILE=$(mktemp /tmp/olvm-snapshot-report.XXXXXX)
trap 'rm -f "$REPORT_FILE"' EXIT
cd /usr/share/doc/python3.11-ovirt-engine-sdk4/examples/
/usr/bin/python3.11 "$SNAPSHOT_SCRIPT" > "$REPORT_FILE"

# Ha nincs snapshot, az email akkor is menjen ki
if [ ! -s "$REPORT_FILE" ]; then
    echo "Nincs snapshot az OLVM kornyezetben." > "$REPORT_FILE"
fi

# -------------------------------------------------------------------
# Email kuldese
# -------------------------------------------------------------------

export SMTP_SERVER
export SMTP_PORT
export MAIL_FROM
export MAIL_SUBJECT
export REPORT_FILE

MAIL_TO_CSV=$(IFS=, ; echo "${MAIL_TO[*]}")
export MAIL_TO_CSV

/usr/bin/python3 <<'PY'
import os
import smtplib
from email.message import EmailMessage

smtp_server = os.environ["SMTP_SERVER"]
smtp_port = int(os.environ["SMTP_PORT"])

mail_from = os.environ["MAIL_FROM"]
mail_to = os.environ["MAIL_TO_CSV"].split(",")
subject = os.environ["MAIL_SUBJECT"]
report_file = os.environ["REPORT_FILE"]

with open(report_file, "r", encoding="utf-8", errors="replace") as f:
    report = f.read()

msg = EmailMessage()
msg["From"] = mail_from
msg["To"] = ", ".join(mail_to)
msg["Subject"] = subject
msg.set_content(report)

with smtplib.SMTP(smtp_server, smtp_port, timeout=30) as smtp:
    smtp.send_message(msg)
PY

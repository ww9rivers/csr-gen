#!/bin/sh

CONF=~"/.etc/splunk-api.rc"
. "$CONF" >/dev/null 2>&1
if [ "$SPLUNKPW" = "" ]; then
	cat > "$CONF" <<EOF
SPLUNKUSER=admin
SPLUNKPW=changeme
EOF
fi
if [ "$SPLUNKPW" = "" -o "$SPLUNKPW" = "changeme" ]; then
	echo "Configure this script in '$CONF'."
	exit
fi

HOST=$1 || HOST=localhost
wget --user=${SPLUNKUSER:-admin} --password=${SPLUNKPW:-changeme} --no-check-certificate -O - https://"$HOST":8089/services/server/info 2>/dev/null \
	| grep -w generator

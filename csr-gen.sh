#!/bin/sh

usage() {
	cat <<EOF

	Usage:	$0 "<hostname"> ["<alternative-names>"]

	Alternative-names may be provided optionally (Defaults to none), in this format:

	"/subjectAltName=DNS.1=<alt-name-1>,DNS.2=<alt-name-2>,DNS.3=<alt-name-3>..."

EOF
	exit 2
}

HOSTNAME=$1
if [ "$HOSTNAME" = "" ]; then
	echo "Expecting hostname in FQDN." >&2
	usage
fi

# SUBJECTALTNAME="/subjectAltName=DNS.1=<alt-name-1>,DNS.2=<alt-name-2>,DNS.3=<alt-name-3>..."
SUBJECTALTNAME=${2-""}
KEYSIZE=${KEYSIZE:-2048}
KEYFILE="${HOSTNAME}.key"
CSRFILE="${HOSTNAME}.csr"

COMMONNAME="/C=US/ST=Michigan/L=Ann Arbor/O=University of Michigan/OU=HITS-TI/CN=$HOSTNAME"
GROUPEMAIL="emailAddress=HITS-Performance@umich.edu"
cat <<EOF

Generating TLS key and certification request for:

  HOSTNAME = ${HOSTNAME}
  AltNames = ${SUBJECTALTNAME}
  Kei size = ${KEYSIZE}

     Email = ${GROUPEMAIL}
COMMONNAME = ${COMMONNAME}

  Key file = ${KEYFILE}
  CSR file = ${CSRFILE}
EOF

openssl genrsa -out "$KEYFILE" "$KEYSIZE"
if openssl req -new -nodes -key "$KEYFILE" -out "$CSRFILE" -subj "${COMMONNAME}/${GROUPEMAIL}${SUBJECTALTNAME}"; then
cat <<EOM

------	CSR created successfully. Submit the request here for InCommon certification:

	https://webservices.itcs.umich.edu/index.php?screen=request&service=ssl_certificate

EOM
	exit 0
fi
exit 1

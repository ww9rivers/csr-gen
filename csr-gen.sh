#!/bin/sh

usage() {
	cat <<EOF

	Usage:	$0 "<hostname>" ["<alternative-names>"]

	Alternative-names may be provided optionally (Defaults to none), in this format:

	"/subjectAltName=DNS.1=<alt-name-1>,DNS.2=<alt-name-2>,DNS.3=<alt-name-3>..."

	Where, <alt-name-1>, <alt-name-2>, <alt-name-3>, etc. are aliases (CNAMEs) of
	the <hostname>.

DEPENDENCY

	openssl		This script assumes that the openssl package is installed.

EOF
	exit 2
}

HOSTNAME=$1
if [ "$HOSTNAME" = "" ]; then
	echo "Expecting hostname in FQDN." >&2
	usage
fi
if [ "$1" = "-h" -o "$1" = '--help' ]; then
	usage
fi

#	Allow this script to be configured:
CONF="$HOME/.etc/csr-gen.rc"
if [ -r "$CONF" ]; then . "$CONF"; fi
if [ "$OU" = "" -o "$GROUPEMAIL" = "" ]; then
    mkdir -p "$HOME/.etc"
    echo '#
#	Organizational Unit, with these components:
#
#		C	Country name
#		ST	State name
#		L	Name of your locale (city)
#		O	Name of your organization
#		OU	Nmae of your unit within the organizational
if [ "$OU" = "" ]; then
    OU="/C=US/ST=Michigan/L=Ann Arbor/O=University of Michigan/OU=UMHS-HITS-EI"
fi

#
#	Group email as contact for certificates.
#
#	For InCommon certificates, ITS requires that the group exists in the
#	UMICH.EDU directory.
if [ "$GROUPEMAIL" = "" ]; then
    GROUPEMAIL="emailAddress=HITS-Performance@umich.edu"
fi
' >>"$CONF" && cat <<EOF

A configuration file "$CONF" has been created for you.

Please chack and make sure that the contents are correct for your needs.
EOF
    exit 3
fi

# SUBJECTALTNAME="/subjectAltName=DNS.1=<alt-name-1>,DNS.2=<alt-name-2>,DNS.3=<alt-name-3>..."
SUBJECTALTNAME=${2-""}
KEYSIZE=${KEYSIZE:-2048}
KEYFILE="${HOSTNAME}.key"
CSRFILE="${HOSTNAME}.csr"

COMMONNAME="$OU/CN=$HOSTNAME"
cat <<EOF

Generating TLS key and certification request for:

  HOSTNAME = ${HOSTNAME}
  AltNames = ${SUBJECTALTNAME}
  Key size = ${KEYSIZE}

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

#!/bin/sh

##	Defaults:	----------------------------------------------------------
KEYSIZE=${KEYSIZE:-4096}
DIGEST=${DIGEST:-"sha256"}
C=${C:-US}
ST=${ST:-Michigan}
L=${L:-Ann Arbor}
O=${O:-Michigan Medicine}
OU=${OU:-HITS}
GROUPEMAIL=${GROUPEMAIL:-"HITS-Performance@umich.edu"}
CONFVER=version002

##	Variables & parameters:
HOSTNAME=''
CSRCONF=''
opt_old_conf=''
opt_old_key=''
args=''

##--------------------------------------------------------------------------------
##	Display a help message for the script
##--------------------------------------------------------------------------------
usage() {
	cat <<EOF

TLS Key & Certificate Signing Request Generator
VERSION	2.0

	Usage:	$0 [<OPTIONS>] "<hostname>" ["<alternative-names>"]

	The given hostname (first parameter on the command line) is taken as the name
	of the subject to be certified. Key and CSR files are named with the hostname
	with .key and .csr extensions.

	Alternative-names may be provided optionally (Defaults to none), in FQDN format:

		<alt-name-1> <alt-name-2> <alt-name-3> ...

	Where, <alt-name-1>, <alt-name-2>, <alt-name-3>, etc. are aliases (CNAMEs) of
	the <hostname> -- This allows the certificate-key pair to be used on all these
	hosts.

	Optionally, a CSR config file is generated for the CSR, which may be used in the
	future to add more host names to the certificate. If no alternative-name is given
	and a config file exists, it will be left unchanged and used to create the CSR.

OPTIONS

	-h --help		Print this help message.
	-k --old-key		Use existing old key, rather than create new (default).
	-o --old-config		Use existing old config, rather than create new (default).

ENVIRONMENT VARIABLES

	C		Country name
	ST		State name
	L		Name of your locale (city)
	O		Name of your organization
	OU		Nmae of your unit within the organizational
	GROUPEMAIL	The email address to receive notification regarding the cert
	KEYSIZE		Size of key to generate
	DIGEST		Message Digest Method

FILES

	Configuration files in ~/.etc or ~/.config folder are used:

	csr-gen.rc		Environment variable settings for this script.

	csr/<hostname>.conf	Per-host CSR configuration.

DEPENDENCY

	openssl		This script assumes that the openssl package is installed.

EOF
	exit 2
} # usage

no_hostname() {
	echo "Expecting hostname in FQDN." >&2
	usage
}

##--------------------------------------------------------------------------------
##	Process command line options:
##--------------------------------------------------------------------------------
get_opts() {
    local xvar
    for xvar in $@; do
	case "$xvar" in
	    ("-o"|"--old-config")	opt_old_conf='x';;
	    ("-k"|"--old-key")		opt_old_key='x';;
	    ("-h"|'--help')		usage;;
	    (*)
		if [ "$HOSTNAME" = "" ]; then
		    HOSTNAME="$xvar"
		    CSRCONF="${xvar}.conf"
		elif [ "$args" = "" ]; then
		    args="$xvar"
		else
		    args="${args} ${xvar}"
		fi;;
	esac
    done
} # get_opts
get_opts $@
if [ "$HOSTNAME" = "" ]; then no_hostname; fi

#	Allow this script to be configured, either in ~/.config/ or ~/.etc/:
CONFDIR="$HOME/.etc"
if [ ! -d "$CONFDIR" ]; then CONFDIR="$HOME/.config"; fi
CONF="$CONFDIR/csr-gen.rc"
csr_dir="${CONFDIR}/csr"
csr_cf="${csr_dir}/${CSRCONF}"
if [ -r "$CONF" ]; then . "$CONF"; fi
if [ "$CSR_GEN_RC" != "$CONFVER" -o "$GROUPEMAIL" = "" ]; then
    mkdir -p "$CONFDIR"
    echo "CSR_GEN_RC=${CONFVER}"'
#
#	Organizational Unit, with these components:
#
#		C	Country name
#		ST	State name
#		L	Name of your locale (city)
#		O	Name of your organization
#		OU	Nmae of your unit within the organizational
C=${C:-US}
ST=${ST:-Michigan}
L=${L:-Ann Arbor}
O=${O:-University of Michigan}
OU=${OU:-HITS}

#
#	Group email as contact for certificates.
#
#	For InCommon certificates, ITS requires that the group exists in the
#	UMICH.EDU directory.
GROUPEMAIL="${GROUPEMAIL:-HITS-Performance@umich.edu}"

#
#	Options: Default values are shown below.
#
#KEYSIZE=${KEYSIZE:-4096}
#DIGEST="${DIGEST:-sha256}"

#
#	Extra success / failure Messages
#
SUCCESS_MESSAGE="
------	CSR created successfully. Submit the request here for InCommon certification:

	https://cert-manager.com/customer/InCommon/ssl
"' >"$CONF" && cat <<EOF

A configuration file "$CONF" has been created / updated for you.

Please chack and make sure that the contents are correct for your needs.

EOF
    exit 3
fi

##--------------------------------------------------------------------------------
##	Generate a CSR configuration file.
##--------------------------------------------------------------------------------
config_csr() {
    if [ "$opt_old_config" = 'x' -o "$args" = '' ]; then
	if [ -f "$csr_cf" ]; then
	    echo Using existing/old CSR configuration.\n
	    return
	fi
    fi
    mkdir -p "${csr_dir}"
    cat >"${csr_cf}" <<EOF
#	Config file for ${HOSTNAME}.csr
[req]
default_bits		= ${KEYSIZE}
default_md		= ${DIGEST}
req_extensions		= req_ext
distinguished_name	= dn
prompt			= no
encrypt_key		= no

[dn]
C="$C"
ST="$ST"
L="$L"
O="$O"
OU="$OU"
emailAddress="$GROUPEMAIL"
CN="${HOSTNAME}"

[req_ext]
subjectAltName = @alt_names

[alt_names]
EOF
    shift
    local ix=0
    for xvar in $args; do
	echo DNS.${ix} = ${xvar} >>"${csr_cf}"
	ix=`expr ${ix} + 1`
    done
} # config_csr

KEYFILE="${HOSTNAME}.key"
CSRFILE="${HOSTNAME}.csr"

COMMONNAME="$ORGANIZATIONALUNIT/CN=$HOSTNAME"
cat <<EOF

Generating TLS key and certification request for:

  HOSTNAME = ${HOSTNAME}
  Key size = ${KEYSIZE}

     Email = ${GROUPEMAIL}
COMMONNAME = ${COMMONNAME}

  Key file = ${KEYFILE}
  CSR file = ${CSRFILE}

Find more details in "${csr_cf}".
EOF

config_csr $@
if [ "$HOSTNAME" = '' ]; then no_hostname; fi

echo opt_old_key = $opt_old_key
if [ -f "$KEYFILE" -a "$opt_old_key" = 'x' ]; then
    echo "Using existing key file: [$KEYFILE]"
else
    openssl genrsa -out "$KEYFILE" "$KEYSIZE"
fi
if openssl req -new -nodes -key "$KEYFILE" -out "$CSRFILE" -config "$csr_cf"
then
	cat <<EOM

------	Run command below to see the contents of the CSR:
	openssl req -text -noout -in "${CSRFILE}"

${SUCCESS_MESSAGE}
EOM
	exit 0
fi
echo ${FAILURE_MESSAGE}
exit 1

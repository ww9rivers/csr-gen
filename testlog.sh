#!/bin/sh

SERVER=${SERVER:-syslog4splunk.med.umich.edu}

proto="$1"
case "$1" in
    "tcp")
	port=601
	test="TCP"
	;;
    "tls")
	port=6514
	test=TLS
	;;
    "udp")
	port=514
	test=UDP
	;;
    *)
	cat <<EOF

	Usage: $0 {tcp|tls|udp}

	Sending a test syslog message to $SERVER.

EOF
	exit 1
	;;
esac

logger --$proto --port $port --tag TEST --server "$SERVER" "Testing syslog via $test"

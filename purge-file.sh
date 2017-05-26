#!/bin/sh
#	$Id: purge-file.sh,v 1.1 2016/05/19 22:16:40 weiwang Exp $
##
##	A shell script to:
##
##	Purge files in a given folder that have not changed for a given number of days.

APPNAME=`basename "$0"`
DEFAULT_DAYS=60

WORK_DIR=$1
PATTERN=$2
DAYS_OLD=${3:-$DEFAULT_DAYS}

usage () {
    cat <<EOF

Usage:	$0 work-dir pattern [days]

    This is a shell script intended to be run as a cron job to archive files. It is
    assumed that these files are no longer being written into -- this utility does
    NOT check that for a fact, besides checking that the files have not been modified
    in the last "days".

Mandatory arguments:

	work-dir	Work folder: A directory for this utility to work in.

	pattern		A pattern for matching files.

Options:

	days		Number of days. A file must not have been modified for so
			long before it is to be purged. Default is $DEFAULT_DAYS.

EOF
    exit 1
}

if [ ! -d "$WORK_DIR" ]; then
    echo "'$WORK_DIR' is not a folder. Exiting!" >2
    exit 3
fi

if [ $# -lt 2 ]; then
    usage
fi

find "$WORK_DIR/" -type f -name "${PATTERN}" -mtime +"${DAYS_OLD}"\
	-delete\
	-exec logger -p user.info -t "$APPNAME" "${HOST}: file '{}' purged after ${DAYS_OLD} days." \;\
	|| logger -p user.alert -t "$APPNAME" "${HOST}: Error purging '${WORK_DIR}/${PATTERN}' files."
exit 0

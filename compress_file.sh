#!/bin/sh
#	$Id: compress_file.sh,v 1.2 2016/05/19 22:16:40 weiwang Exp $

if [ $# -lt 3 ]; then
    cat <<EOF

Usage:	$0 SOURCE ARCHIVE_DIR PROGRAM [APPNAME]

    This script is intended for archive-file.sh to call to compress
    individual files.

Arguments:

	SOURCE		Source file path.

	ARCHIVE_DIR	Archive file folder. A value of '.' means the same
			folder as the SOURCE.

	PROGRAM		Program to use to compress source to target.

	APPNAME		Main app name, for logging purpose only.

EOF
    exit 1
fi
 
SOURCE="$1"
ARCHIVE_DIR="$2"
PROGRAM="$3"

PROG=`basename "$PROGRAM"`
case "$PROG" in
    'xz')
	ZEXT='xz'
	;;
    'bzip2')
	ZEXT='bz2'
	;;
    'gzip')
	ZEXT='gz'
	;;
    *)
	ZEXT='zip'
	;;
esac

APPNAME="$4"
if [ "$APPNAME" = "" ]; then
    APPNAME=`basename "$0"`
fi

#	Set LOGGER accordingly, for Splunk or cron:
if [ "$LOGGER" = "" ]; then
    if [ "$SPLUNK_HOME" = "" ]; then
	LOGGER="logger -p user.alert -t"
    else
	LOGGER="echo"
    fi
fi

#	Check if file is current:
#		logfile-%F-%H	is the pattern for current hour;
#		logfile-%F	is the pattern for current day.
TODAY=`date +%F`
HOUR=`date +%H`
THEHOUR="${TODAY}-${HOUR}"
bn=`basename "$SOURCE"`
bn2=`basename "$bn" $TODAY`
if [ "$bn" != "$bn2" ]; then exit 0; fi
bn2=`basename "$bn" $THEHOUR`
if [ "$bn" != "$bn2" ]; then exit 0; fi

FNAME=`basename "$SOURCE"`
if [ "$ARCHIVE_DIR" = '.' ]; then
    ARCHIVE_DIR=`dirname "$SOURCE"`
fi
TARGET="$ARCHIVE_DIR/$FNAME.$ZEXT"
if test -s "$TARGET"; then exit 2; fi
{ "${PROGRAM}" -z9c "$SOURCE" > "$TARGET"; }\
	&& touch "$TARGET" -r "$SOURCE"\
	&& ${LOGGER} "${APPNAME}" "Compressed '$SOURCE' to '$TARGET'"\
	&& /bin/rm "$SOURCE"\
	&& exit 0
exit 1

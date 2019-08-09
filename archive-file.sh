#!/bin/sh
#	$Id: archive-file.sh,v 1.3 2016/05/20 15:15:11 weiwang Exp $
##
##	A shell script to:
##
##	1.  Find files in a given folder that are older than a given number of minutes;
##	2.  Compress the files, optionally to another specified folder;

APPNAME=`basename "$0"`
DEFAULT_OLD=240
DEFAULT_ZIP=`which xz`

WORK_DIR="$1"
ARCHIVE_DIR="$2"		# To be passed to COMPRESS_SCRIPT
ARCHIVE_TO="$2"			# For display
PATTERN="$3"
COMPRESS_AFTER_SO_MANY_MINUTES=${4:-$DEFAULT_OLD}
PROGRAM=${5:-$DEFAULT_ZIP}
COMPRESS_SCRIPT="`dirname $0`/compress_file.sh"

#	Set LOGGER accordingly, for Splunk or cron:
if [ "$LOGGER" = "" ]; then
    if [ "$SPLUNK_HOME" = "" ]; then
	LOGGER="logger -p user.alert -t"
    else
	LOGGER="echo"
    fi
fi
export LOGGER

usage () {
    cat <<EOF

Usage:	$0 work-dir archive-dir pattern [minutes] [program]

    This is a shell script intended to be run as a cron job to archive files. It is
    assumed that these files are no longer being written into -- this utility does
    NOT check that for a fact, besides checking that the files have not been modified
    in the last "minutes".

    Files found in or under the work-dir folder matching the pattern that have not
    been modified in the last [minutes] are archived (compressed) into the dest-dir
    folder.

    The script may also be run as a Splunk input script: It checks for the variable
    SPLUNK_HOME and sets LOGGER to send outputs to stdout for Splunk to pick up as
    input events.

Mandatory arguments:

	work-dir	Work folder: A directory for this utility to work in.

	archive-dir	Destination folder: A directory for files to be archive into.
			A value of "." means the same folder as work-dir. This folder
			must exist at the time this utility runs. Otherwise, the
			work-dir will be used instead.

			If this is ".", files under the "work_dir" will be archived
			where the source is found.

	pattern		A pattern for matching files.

Options:

	minutes		Number of minutes. A file must not have been modified for so
			long before it is to be archived. Default is $DEFAULT_OLD.

			Consideration is needed for this argument: For example, if a
			log file is rotated daily with the naming pattern "log-%F",
			it may be necessary to wait a full day (1440 minutes) before
			archivng them.

	program		Program to use to compress files.
			Default is "$DEFAULT_ZIP".

DEBUGGING

    Set environment variable ARCHIVE_FILE_DEBUG to see more output.

EOF
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

if [ ! -d "$WORK_DIR" ]; then
    echo "'$WORK_DIR' is not a folder. Exiting!" >2
    exit 3
fi

if [ ! -x "$COMPRESS_SCRIPT" ]; then
    echo "Missing script for compressing file '$COMPRESS_SCRIPT'. Exiting!" >2
    exit 2
fi

if [ "$ARCHIVE_TO" = '.' ]; then
    ARCHIVE_TO="$WORK_DIR"
fi

if [ ! -d "$ARCHIVE_TO" ]; then
    echo "Folder '$ARCHIVE_DIR' does not exist. Archiving to '$WORK_DIR' instead."
    ARCHIVE_TO="$WORK_DIR"
    ARCHIVE_DIR="$WORK_DIR"
fi

if [ "$ARCHIVE_FILE_DEBUG" != '' ]; then
    cat <<EOF
Archiving '$WORK_DIR/$PATTERN' that are older than $COMPRESS_AFTER_SO_MANY_MINUTES minutes,"
    ... to folder '$ARCHIVE_TO',"
    ... using '$PROGRAM'"
EOF
fi

##	Find old uncompressed file; compress the file to archive; retain timestamp;
##	test OK the archive; then delete original:
##.	Assumptions on file naming: Daily rotating log files are named with YYYY-MM-DD as suffix, and
##	hourly rotating files are named with YYYY-MM-DD-HH as suffix.
CUR_UMASK=`umask`
umask 0137
find "$WORK_DIR/" -name "${PATTERN}" -mmin +"${COMPRESS_AFTER_SO_MANY_MINUTES}"\
	-exec /bin/sh -c "'${COMPRESS_SCRIPT}' '{}' '$ARCHIVE_DIR' '$PROGRAM' '$APPNAME'" \;\
	|| ${LOGGER} "$APPNAME" "${HOST}: Error compressing '${WORK_DIR}/${PATTERN}' files."
umask ${CUR_UMASK}

##	Email admin if old uncompressed file still exists:
ALERT_TIMER=`expr ${COMPRESS_AFTER_SO_MANY_MINUTES} + 60`
more_files=`find "$WORK_DIR/" -name "$PATTERN" -mmin +$ALERT_TIMER 2>/dev/null`
if [ "$more_files" != "" ]; then
    old_file_list="$old_file_list $more_files"
fi
if [ "$old_file_list" != "" -a "$HOUR" = "06" ]; then
    ADMIN=${ADMIN:-$USER}
    cat <<EOF | mail -s "Un-archived log files on $HOST" -r "${ADMIN}" "${ADMIN}"
In folder "'$WORK_DIR'":

$old_file_list

====

Likely cause is that file(s) exist in the archive folder "'$ARCHIVE_DIR'" preventing
these files from being compressed into that folder.
EOF
fi

exit 0

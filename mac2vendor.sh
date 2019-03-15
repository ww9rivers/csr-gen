#!/bin/bash
#
# script to get and put in place latest IEEE MAC assignments for Splunk Device Vendor lookup table
#
CONF=~/".etc/mac2vendor.rc"
if [ -r "$CONF" ]; then . "$CONF" 2>/dev/null; fi
if [ "$mailto" = "" ]; then
	cat > "$CONF" <<EOF
# variables
mailto="whoever@you.want"
#
# set http_proxy if you need to use a proxy to get out and retrieve the data
#export http_proxy="nn:nn:nn:nn:xxxx"

tmpa="tmp-a"
tmpb="tmp-b"
ieee="ieee-mac-oui.csv"
splunk_loc="/opt/splunk/etc/apps/search/lookups"
EOF
fi
if [ "$mailto" = "" -o "$mailto" = "whoever@you.want" ]; then
	echo "Configure this script in '$CONF'."
	exit
fi

function clean_up {
	trap "rm -f $tmpa $tmpb; exit" ERR EXIT INT TERM
}
function catch_errs {
	"$@"
	local status=$?
	if [ $status -ne 0 ]; then
		echo "Around here... $@" | mail -s "Problem with $0 on `hostname`" $mailto
		clean_up >/dev/null 2>&1
		exit
	fi
}
function copy_old {
	if [ -r ${splunk_loc}/${1} ]; then
		catch_errs cp ${splunk_loc}/${1} ${splunk_loc}/${1}.old
	fi
}
function move_new {
	catch_errs mv ${1} ${splunk_loc}/${1}
}
cd /tmp || exit 99
# download MA-L assignments (contains placeholders for MA-M and MA-S)
catch_errs wget -N http://standards.ieee.org/develop/regauth/oui/oui.txt >/dev/null 2>&1
# download MA-M assignments
catch_errs wget -N http://standards.ieee.org/develop/regauth/oui28/mam.txt >/dev/null 2>&1
# download MA-S assignments
catch_errs wget -N http://standards.ieee.org/develop/regauth/oui36/oui36.txt >/dev/null 2>&1
# remove MA-M and MA-S placeholders in MA-L (oui.txt) file
# remove (hex) fields as it's superfluous
grep "(hex)" oui.txt | grep -v "public listing" | awk '{$2=""; print}' > $tmpa
# get rest of the ranges from the other files (MA-M and MA-S) and append
grep "(hex)" mam.txt | awk '{$2=""; print}' >> $tmpa
grep "(hex)" oui36.txt | awk '{$2=""; print}' >> $tmpa
# UPPERCASE everything makes searches easier
tr 'a-z' 'A-Z' < $tmpa >$tmpb
# clean up = get rid of spaces and replace with , separator
# replace - MAC octet separator with :
sed -i '1i\'"Vendor_MAC,Manufacturer" $tmpb
sed -e 's/ /,/' -re 's/([0-9]+)-([0-9]+)-/\1:\2:/' < $tmpb > $ieee
# move new file in proper Splunk lookup location and make an old copy
copy_old $ieee
move_new $ieee
# final clean up just in case
clean_up >/dev/null 2>&1

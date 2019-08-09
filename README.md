# Scripts

## archive-file.sh

Usage: ```archive-file.sh _work-dir_ _archive-dir_ _pattern_ [_minutes_] [_program_]```

The script may be used in a cron job to archive files that matches a given _pattern_ in and under the given
_word-dir_, to the _archive-dir_ folder, which may be specified as "." to mean the same folder as the
_work-dir_.

To run hourly with Splunk Forwarder, configure this as an input:
```
[script://$SPLUNK_HOME/bin/scripts/hits/archive-file.sh /log/syslogs . *-?? 1440]
source = archive-file
sourcetype = hits:run:scripts
start_by_shell = true
disabled = 0
index = test
interval = 3600
```
## purge-file.sh

Usage: ```purge-file.sh _work-dir_ _pattern_ [_days_]```

The script may be used in a cron job to purge files that matches a given _pattern_ in and under the given
_word-dir_.

To use with Splunk Forwarder, configure this as an input:
```
[script://$SPLUNK_HOME/bin/scripts/hits/purge-file.sh /log/syslogs *.xz 30]
source = purge-file
sourcetype = hits:run:scripts
start_by_shell = true
disabled = 0
index = test
interval = 3600
```
## Author

Wei Wang <weiwang@med.umich.edu>
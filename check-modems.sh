#!/bin/bash
#
# Note: Should be possible to use one modem session and hangup nicely after
# checking each number. I was unable to do this as +++ terminated the cu spawn
# session as well as hangs up line. Hence the only way I could get this to
# work was to invoke a new cu session for each number

NOTIFY=me@myemail.com

SESSION_LOG=log/session.log
ERROR_LOG=log/error.log
NUMBER_LIST=numbers.txt

> $SESSION_LOG
> $ERROR_LOG

failed_sites=()
working_sites=()

while read site phone_number; do
    site="$site $phone_number"
    ./call.exp $phone_number $site >> $SESSION_LOG 2>> $ERROR_LOG
    status=$?
    if [ $status -ne 0 ]; then
        failed_sites+=("$site")
    else
        working_sites+=("$site")
    fi
done < $NUMBER_LIST

working_sites_count=${#working_sites[@]}
failed_sites_count=${#failed_sites[@]}
total_sites_count=$(($working_sites_count + $failed_sites_count))

if [ $failed_sites_count -gt 0 -o $working_sites_count -lt 1 ]; then
    subject="Warning: $failed_sites_count (of $total_sites_count) OOB management modems down"
    {
        echo $subject
        echo
        echo "These remote modems could not be reached:"
        echo
        cat $ERROR_LOG
        echo
        echo "To manually check modem connectivity or for info on this monitoring script, see:"
        echo
        echo ""
        echo
        echo "These remote modems connected successfully:"
        echo
        for site in "${working_sites[@]}"; do
            echo $site
        done
    } | {
        if [ "$1" = "cron" ]; then
            mail -s "$subject" ${NOTIFY}
        else
            cat
        fi
    }
fi

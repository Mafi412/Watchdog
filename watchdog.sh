#!/bin/bash

help() {
        echo "Usage of $0:"
        echo

        # general description
        echo "DESCRIPTION:"
        echo "    Watches given site and in case of change in text of the site"
        echo "    reports that via email or saves the differences to file,"
        echo "    that depends on used options."
        echo "    (Defaultly: Sends mail notification"
        echo "    and saves the diff and time of change into file.)"

        echo
        echo "SYNOPSIS:"
        echo "    watchdog [options] address"

        # options
        echo
        echo "OPTIONS:"
        echo "    -t (--time)"
        echo "        length of interval between tests"
        echo "        format: -t qu, where q is quantity and u is time unit"
        echo "        accepted units: "\'s\'" (seconds),"\
        \'m\'" (minutes),"\
        \'h\'" (hours), "\'d\'" (days)"
        echo "        (default unit: seconds)"
        echo "        default: 1h"
        echo        
        echo "    -m (--mail)"
        echo "        email address(es), which the notification will be sent on"
        echo "        format: -m mail1@domain1 ... mailN@domainN"
        echo "        where can be N mail addresses separated by space"
        echo "        default: no mail will be send"
        echo
        echo "    -mc (--mail-content)"
        echo "        determines, what the mail notification will contain"
        echo "        format: -mc options"
        echo "        where options are either \"diff\" or \"time\" or"
        echo "        both separated by comma (without space!)"
        echo "        diff - the mail will contain diff of change"
        echo "        time - the mail will contain time of detection of change"
        echo "        default: just a short notification"
        echo
        echo "    -f (--file)"
        echo "        path to file, where the informations about the change will be stored"
        echo "        format: -f path"
        echo "        where path is either absolute (starts with \"/\"), or relative path"
        echo "        (doesn't start with \"/\") to the file, where the report of change"
        echo "        should be stored. The absolute way goes through unchanged,"
        echo "        to the relative path is added \"\~\" on the beginning."
        echo "        (so it's relative to the home directory of user starting the sript)"
        echo "        The whole path except the last part (the file itself) have to exist,"
        echo "        the file itself can (but don't have to) exist, but can not be a directory."
        echo "        In case of any problems like those above with the given path,"
        echo "        it will be changed to default."
        echo "        default: watchdog_\"address\"_changes in home directory"
        echo "        of user that starts the script (~/watchdog_address_changes)"
        echo "        where address is just the main part of the URL"
        echo "        (without protocol and what's behind the Top-Level-Domain)"
        echo "        (e.g. https://www.google.com/something -> www.google.com)"
        echo
        echo "    -fc (--file-content)"
        echo "        determines, what the created file will contain"
        echo "        format: -fc options"
        echo "        where options are either \"diff\" or \"time\" or"
        echo "        both separated by comma (without space!)"
        echo "        diff - the file will contain diff of change"
        echo "        time - the file will contain time of detection of change"
        echo "        default: time,diff (both oprions are set)"

        # exit codes
        echo
        echo "EXIT CODES:"
        echo "    1 - general fault"
        echo "    2 - wrong address (unable to establish first connection)"
        echo "    3 - input fault (error while processing parameters)"

        # examples
        echo
        echo "EXAMPLES:"
        echo "    watchdog -t 30m -m reciever1@mail.to www.address.domain"
        echo "        Watches address \"www.address.domain\" every 30 minutes"
        echo "        and in the case there will be any change it will send an email"
        echo "        containing just a notification to address \"reciever1@mail.to\""
        echo "        and will save diff and time of change (respectively"
        echo "        the time of discovery of the change) to the file"
        echo "        \"~/watchdog_www.address.domain_changes\"."
        echo
        echo "    watchdog -f path -m reciever1@mail.to reciever2@mail.to www.address.domain"
        echo "        Watches address \"www.address.domain\" every hour (default)"
        echo "        and in the case there will be any change it will send an email"
        echo "        containing just a notification to both addresses \"reciever1@mail.to\""
        echo "        and \"reciever2@mail.to\" and will safe diff and time of change"
        echo "        (respectively the time of discovery of the change) to the file"
        echo "        \"path\"."
        echo
        echo "    watchdog -fc diff -mc diff,time -m reciever1@mail.to www.address.domain"
        echo "        Watches address \"www.address.domain\" every hour (default)"
        echo "        and in the case there will be any change it will send an email"
        echo "        containing both diff and time of change to address \"reciever1@mail.to\""
        echo "        and will safe diff to the file \"~/watchdog_www.address.domain_changes\"."

        # author
        echo
        echo "AUTHOR:"
        echo "    Written by Matyáš Lorenc as semestral script for UNIX classes on MATFYZ."

        echo
        exit ${1:-1}
}

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo
        help
fi

adr=null
time=1h
file=uninicialized
mail=null
mailcont=null
filecont=diff,time


# Work with parameters
while [ -n "$1" ]; do
        # address
        if [ $# -eq 1 ]; then
                adr=$1
                shift
                break

        # input control
        elif [ "$1" != "-t" ] && [ "$1" != "--time" ] \
        && [ "$1" != "-m" ] && [ "$1" != "--mail" ] \
        && [ "$1" != "-mc" ] && [ "$1" != "--mail-context" ] \
        && [ "$1" != "-f" ] && [ "$1" != "--file" ] \
        && [ "$1" != "-fc" ] && [ "$1" != "--file-context" ] \
        ; then
                echo
                echo No such archument as "$1" exists!
                echo
                help 3
        fi

        # saving parameters
        # time
        if [ "$1" = "-t" ] || [ "$1" = "--time" ]; then
                shift

                echo "$1" | grep -E "[0-9]+[smhd]" &> /dev/null
                if [ -n "$1" ] && [ $? -eq 0 ]; then
                        time=$1
                        shift
                        continue
                else
                        echo
                        help 3
                fi
        fi

        # mail
        if [ "$1" = "-m" ] || [ "$1" = "--mail" ]; then
                mail=
                shift

                echo "$1" | grep "^-" &> /dev/null
                if [ $? -eq 1 ] && [ -n "$1" ]; then

                        mail="$1"
                        shift

                        while [ $# -gt 1 ] && echo "$1" | grep "^[^-]" &> /dev/null; do
                                mail="$mail $1"
                                shift
                        done

                        continue
                else
                        echo
                        echo "No mail given"
                        echo
                        help 3
                fi
        fi

        # mail content
        if [ "$1" = "-mc" ] || [ "$1" = "--mail-content" ]; then
                shift

                if echo "$1" | grep "diff" &> /dev/null \
                || echo "$1" | grep "time" &> /dev/null; then
                        mailcont="$1"
                else
                        echo
                        echo "Argument fault"
                        echo
                        help 3
                fi

                shift
                continue
        fi

        # file
        if [ "$1" = "-f" ] || [ "$1" = "--file" ]; then
                shift

                if [ -d $(echo "$1" | sed 's#/[^/]*$##') ]; then  #jestli je vůbec cesta validní
                        if [ ! -d "$1" ]; then
                                : #good
                        else
                              echo "Wrong path given. Inicialization by the default value."
                              shift
                              continue
                        fi
                else    
                      echo "Wrong path given. Inicialization by the default value."
                      shift
                      continue
                fi

                if echo "$1" | grep "^/" &> /dev/null \
                || echo "$1" | grep "^~" &> /dev/null; then
                        file="$1"
                elif echo "$1" | grep "^null" &> /dev/null; then
                        file="$1"
                else
                        file="~/$1"
                fi

                shift
                continue
        fi

        # file content
        if [ "$1" = "-fc" ] || [ "$1" = "--file-content  " ]; then
                shift

                if echo "$1" | grep "diff" &> /dev/null \
                || echo "$1" | grep "time" &> /dev/null; then
                        mailcont="$1"
                else
                        echo
                        echo "Argument fault"
                        echo
                        help 3
                fi

                shift
                continue
        fi
done

adr_tti=$adr # adr_try to improve - try to improve the address to a usable state

if [ "$(curl --compressed "$adr_tti" 2> /dev/null | wc -l)" -le 14 ]; then
        adr_tti=$adr/
fi

if [ "$(curl --compressed "$adr_tti" 2> /dev/null | wc -l)" -le 14 ]; then
        adr_tti=https://$adr
fi

if [ "$(curl --compressed "$adr_tti" 2> /dev/null | wc -l)" -le 14 ]; then
        adr_tti=https://$adr/
fi

if [ "$(curl --compressed "$adr_tti" 2> /dev/null | wc -l)" -gt 14 ]; then
        adr=$adr_tti
else
        echo
        echo "Wrong address"
        echo
        exit 2
fi


Inicialize() {

        cf1=~/watchdogcf$$   # control file 1 - here's saved last version of text of the file
        cf2=/tmp/watchdogcf$$   # control file 2 - here's downloaded actual version of text of the file

        w3m -dump "$adr" 2> /dev/null > "$cf1"

        if [ $file = "uninicialized" ]; then
                editedAddress=$(echo "$adr" | sed 's#^[^/]*//##' | sed 's#\([^/]*\.[^/]*\)/.*#\1#')
                file=~/watchdog_"$editedAddress"_changes
        fi

}

Compare() { # return values - 0 - no difference found; 1 - change has been made

        w3m -dump "$adr" > "$cf2"

        if diff -q "$cf1" "$cf2" &> /dev/null; then
                return 0
        else
                return 1
        fi

}

SendMail() {

        emailtext="/tmp/watchdogemail$$"
        echo -n > "$emailtext"

        echo "Report from watchdog script: website $adr has been changed." >> "$emailtext"

        if echo "$mailcont" | grep "time" &> /dev/null; then
            echo >> "$emailtext"
            echo "Time of change detection: $(date --rfc-3339=seconds)" >> "$emailtext"
        fi

        if echo "$mailcont" | grep "diff" &> /dev/null; then
            echo >> "$emailtext"
            echo >> "$emailtext"
            echo "Diff of the change:" >> "$emailtext"
            echo "(< - old; > - new)" >> "$emailtext"
            echo >> "$emailtext"
            diff "$cf1" "$cf2" >> "$emailtext"
        fi

        oldIFS="$IFS"
        IFS="
        "

        i=1
        n=$(echo "$mail" | wc -w)
        while [ $i -le $n ]; do
            mail -s "watchdog" $(echo "$mail" | cut -d ' ' -f $i ) < "$emailtext"
            i=$((i+1))
        done

        IFS="$oldIFS"

}

SetFile() {

        echo -n > "$file"

        if echo "$filecont" | grep "time" &> /dev/null; then
            echo >> "$file"
            echo "Time of change detection: $(date --rfc-3339=seconds)" >> "$file"
        fi

        if echo "$filecont" | grep "diff" &> /dev/null; then
            echo >> "$file"
            echo "Diff of the change:" >> "$file"
            echo '(< - old; > - new)' >> "$file"
            echo >> "$file"
            diff "$cf1" "$cf2" >> "$file"
        fi

}

Inicialize

while true; do
        sleep "$time"

        if Compare; then
                continue
        else
                if [ "$file" != "null" ]; then
                        SetFile
                fi

                if [ "$mail" != "null" ]; then
                        SendMail
                fi   

                mv -f -T "$cf2" "$cf1"
        fi
done

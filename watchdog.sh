#!/bin/bash

help() {
        echo "Usage of $0:"
        echo

        # general description
        echo "DESCRIPTION:"
        echo "    Watches given site and in case of change in html of the site"
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
        echo "        email address, which the notification will be sent on"
        echo
        echo "    -mc (--mail-content)"
        echo "        determines, what the mail notification will contain"
        echo
        echo "    -f (--file)"
        echo "        path to file, where the informations about the change will be stored"
        echo
        echo "    -fc (--file-content)"
        echo "        determines, what the created file will contain"

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
        echo "        Watches address "\""www.address.domain"\"" every 30 minutes"
        echo "        and in the case there will be any change it will send an email"
        echo "        containing just a notification to address "\""reciever1@mail.to"\"
        echo "        and will save diff and time of change (respectively"
        echo "        the time of discovery of the change) to the file"
        echo "        "\""~/watchdog_www.address.domain_changes"\""."
        echo
        echo "    watchdog -f path -m reciever1@mail.to reciever2@mail.to www.address.domain"
        echo "        Watches address "\""www.address.domain"\"" every hour (default)"
        echo "        and in the case there will be any change it will send an email"
        echo "        containing just a notification to both addresses "\""reciever1@mail.to"\"                                                                 
        echo "        and "\""reciever2@mail.to"\"" and will safe diff and time of change"
        echo "        (respectively the time of discovery of the change) to the file"
        echo "        "\""path"\""."
        echo
        echo "    watchdog -fc diff -mc diff,time -m reciever1@mail.to www.address.domain"
        echo "        Watches address "\""www.address.domain"\"" every hour (default)"
        echo "        and in the case there will be any change it will send an email"                                                                   
        echo "        containing both diff and time of change to address "\""reciever1@mail.to"\"
        echo "        and will safe diff to the file "\""~/watchdog_www.address.domain_changes"\""."

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


# Work kith parameters
while [ -n "$1" ]; do
        # adresa
        if [ $# -eq 1 ]; then
                adr=$1
                shift
                break

        # kontrola vstupu
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

        # ukládání optionů
        # time
        if [ "$1" = "-t" ] || [ "$1" = "--time" ]; then
                shift

                echo "$1" | grep -E "[0-9]+[smhd]" > /dev/null 2> /dev/null
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

                echo "$1" | grep "^-" > /dev/null 2> /dev/null
                if [ $? -eq 1 ] && [ -n "$1" ]; then

                        mail="$1"
                        shift

                        while [ $# -gt 1 ] && echo "$1" | grep "^[^-]" > /dev/null 2> /dev/null; do
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

                if echo "$1" | grep "diff" > /dev/null 2> /dev/null \
                || echo "$1" | grep "time" > /dev/null 2> /dev/null; then
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

                if echo "$1" | grep "diff" > /dev/null 2> /dev/null \
                || echo "$1" | grep "time" > /dev/null 2> /dev/null; then
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

        cf1="~/watchdogcf$$"   # control file 1 - here's saved last version of html file
        cf2="/tmp/watchdogcf$$"   # control file 2 - here's downloaded actual version of html

        curl --compressed "$adr" 2> /dev/null > "$cf1"

        if [ $file = "uninicialized" ]; then
                file="~/watchdog_""$adr""_changes"
        fi

}

Inicialize

Compare() { # return values - 0 - no difference found; 1 - change has been made

        curl --compressed "$adr" 2> /dev/null > "$cf2"

        diff -q "$cf1" "$cf2" &> /dev/null
        if [ $? -eq 0 ]; then
                return 0
        else
                return 1
        fi

}

SendMail() {
        
        emailtext="/tmp/watchdogemail$$"
        echo -n > "$emailtext"
        
        echo "Report from watchdog script: website $adr has been changed." > "$emailtext"
        
        if echo "$mailcont" | grep "time" &> /dev/null; then
            echo > "$emailtext"
            echo "Time of change detection: $(date --rfc-3339=seconds)" > "$emailtext"
        fi
        
        if echo "$mailcont" | grep "diff" &> /dev/null; then
            echo > "$emailtext"
            echo > "$emailtext"
            echo "Diff of the change:" > "$emailtext"
            echo "(< - old; > - new)" > "$emailtext"
            echo > "$emailtext"
            diff "$cf1" "$cf2" > "$emailtext"
        fi
        
        IFS="\n"
        
        i=1
        n=$(echo "$mail" | wc -w)
        while [ $i -le $n ]; do
            mail -s "watchdog" $(echo "$mail" | cut -d ' ' -f $i ) < "$emailtext"
            i=$((i+1))
        done

        IFS=" \t\n"
        rm "$emailtext"

}

SetFile() {

        echo -n > "$file"
        
        if echo "$filecont" | grep "time" &> /dev/null; then
            echo > "$file"
            echo "Time of change detection: $(date --rfc-3339=seconds)" > "$file"
        fi
        
        if echo "$filecont" | grep "diff" &> /dev/null; then
            echo > "$file"
            echo "Diff of the change:" > "$file"
            echo "(< - old; > - new)" > "$file"
            echo > "$file"
            diff "$cf1" "$cf2" > "$file"
        fi

}

while true; do
        sleep "$time"

        Compare

        if [ $? -eq 1 ]; then
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

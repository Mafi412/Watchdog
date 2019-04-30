# Watchdog

DESCRIPTION:

    Watches given site and in case of change in text of the site
    reports that via email or saves the differences to file,
    that depends on used options.
    (Defaultly: Sends mail notification
    and saves the diff and time of change into file.)

SYNOPSIS:

    watchdog [options] address

OPTIONS:

    -t (--time)
        length of interval between tests
        format: -t qu, where q is quantity and u is time unit
        accepted units: 's' (seconds),'m' (minutes), 'h' (hours), 'd' (days)
        (default unit: seconds)
        default: 1h
        
    -m (--mail)
        email address(es), which the notification will be sent on
        format: -m mail1@domain1 ... mailN@domainN
        where can be N mail addresses separated by space
        default: no mail will be send
        
    -mc (--mail-content)
        determines, what the mail notification will contain
        format: -mc options
        where options are either "diff" or "time" or
        both separated by comma (without space!)
        diff - the mail will contain diff of change
        time - the mail will contain time of detection of change
        default: just a short notification
        
    -f (--file)
        path to file, where the informations about the change will be stored
        format: -f path
        where path is either absolute (starts with "/"), or relative path
        (doesn't start with "/") to the file, where the report of change
        should be stored. The absolute way goes through unchanged,
        to the relative path is added "~" on the beginning.
        (so it's relative to the home directory of user starting the sript)
        The whole path except the last part (the file itself) have to exist,
        the file itself can (but don't have to) exist, but can not be a directory.
        In case of any problems like those above with the given path,
        it will be changed to default.
        default: watchdog_"address"_changes in home directory
        of user that starts the script (~/watchdog_address_changes)
        where address is just the main part of the URL
        (without protocol and what's behind the Top-Level-Domain)
        (e.g. https://www.google.com/something -> www.google.com)   
        
    -fc (--file-content)
        determines, what the created file will contain
        format: -fc options
        where options are either "diff" or "time" or
        both separated by comma (without space!)
        diff - the file will contain diff of change
        time - the file will contain time of detection of change
        default: time,diff (both oprions are set)

EXIT CODES:

    1 - general fault
    2 - wrong address (unable to establish first connection)
    3 - input fault (error while processing parameters)

EXAMPLES:

    watchdog -t 30m -m reciever1@mail.to www.address.domain
        Watches address "www.address.domain" every 30 minutes
        and in the case there will be any change it will send an email
        containing just a notification to address "reciever1@mail.to"
        and will save diff and time of change (respectively
        the time of discovery of the change) to the file
        "~/watchdog_www.address.domain_changes".

    watchdog -f path -m reciever1@mail.to reciever2@mail.to www.address.domain
        Watches address "www.address.domain" every hour (default)
        and in the case there will be any change it will send an email
        containing just a notification to both addresses "reciever1@mail.to"                                                              
        and "reciever2@mail.to" and will safe diff and time of change
        (respectively the time of discovery of the change) to the file
        "path".

    watchdog -fc diff -mc diff,time -m reciever1@mail.to www.address.domain
        Watches address "www.address.domain" every hour (default)
        and in the case there will be any change it will send an email
        containing both diff and time of change to address "reciever1@mail.to"
        and will safe diff to the file "~/watchdog_www.address.domain_changes".
        
AUTHOR:

    Written by Matyáš Lorenc as semestral script for UNIX classes on MATFYZ.

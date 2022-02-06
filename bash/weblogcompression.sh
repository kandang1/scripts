#!/bin/ksh
#################################################################################
#Authors: Foobar ACME Technical Architect Team                                #
#Date: 03/06/2012                                                               #
#Purpose: This basic script to compress apache web logs older than 30 days on   #
#UAT/PROD Web Servers. Script will also send e-mail to admins.                  #
#Revision  Date         Name           Description                              #
#--------  ----------   ------------   -------------                            #
#1.0       03/06/2012   Daniel Kang    First Release                            #
#1.1       03/07/2012   Daniel Kang    Cleaned up logic, added e-mailing        #
#1.2       04/02/2012   Daniel Kang    Re-Did Logic, Added Logging              #
#1.3       04/10/2012   Daniel Kang    Changed the way logging is done          #
#1.4.0a    04/17/2012   Daniel Kang   Logic changes & error checking suggested #
#1.4.1     04/17/2012   Daniel Kang    Implemented suggestions                  #
#################################################################################
####################################################
#Editable variables to change based on requirements#
####################################################
#Location of flat file with e-mail contacts
WEBHOME=/apps/webadmin/TA
ADMINSLIST=${WEBHOME}/adminslist.txt
#Log File Directory
ZIPPABLELOGSVO=/apps/apache2.2.21/https-vo/logs/
ZIPPABLELOGSVR=/apps/apache2.2.21/https-vr/logs/
#Archived Log File Directory
ZIPPEDLOGSVR=/apps/apache2.2.21/https-vr/logs/archive/
ZIPPEDLOGSVO=/apps/apache2.2.21/https-vo/logs/archive/
#Specify the log directory
LOGDIR=${WEBHOME}/logs/webcompress
LOGFILE=${LOGDIR}/compressed.`date "+%Y-%m-%d-%H-%M-%S"`.log
#Specify the maximum age of the log files
MAXLOGAGE=30
#Commands
GZIP=/usr/bin/gzip
MV=/usr/bin/mv
########################
#Hostnames for PROD/UAT#
########################
HOSTNAME=/usr/bin/hostname
ACMEVRAPP1=acmevrapp1
ACMEVRAPP2=acmevrapp2
ACMEWEB1=acmeweb1
ACMEWEB2=acmeweb2
UATACMEWEB1=uatacmeweb1
UATACMEWEB2=uatacmeweb2
UATVRAPP1=uatvrapp1
UATVRAPP2=uatvrapp2
#This function is used to rotate the logs that the script itself may generate
function rotateLogs {
find $LOGDIR -mtime +${MAXLOGAGE} -exec ${GZIP} -9 {} \;
}
#Main function that holds the logic for compression and archival
function compressWeb {
if [ ! -d "$2" ]; then
    #Create directory if it doesn't exist. If there's an error, log to the error log and then abort script and e-mail administrators
    mkdir -p $2 2>>${LOGFILE}
	if [ ! $? -eq "0" ] ; then
        echo "ERROR: Could not create log archive directory: ${2}" >> $LOGFILE
        echo "Aborting script!" >> $LOGFILE
        exit 1
    fi
    while read LINE
        do
            mailx -r $HOST -s "WARNING: $HOST Couldn't create log archive directory,
                            aborted archive job!" $LINE < $LOGFILE
        done < $ADMINSLIST
fi
if [ ! -d "$LOGDIR" ]; then
    #Create log directory if it doesn't exist and log STDERR to LOGFILE if a problem occurs
    mkdir -p $LOGDIR 2>>${LOGFILE} 
	if [ ! $? -eq "0" ] ; then
        echo "ERROR: Could not create script's log directory: ${2}" >> $LOGFILE
        echo "Aborting script!" >> $LOGFILE
        exit 1
    fi
    while read LINE
        do
            mailx -r $HOST -s "WARNING: $HOST Couldn't create script's log directory,
                            aborted archive job!" $LINE < $LOGFILE
        done < $ADMINSLIST
fi
if [[ -d "$2" && -d "$LOGDIR" ]]; then
    find ${1}* \( ! -name . -prune \) \( -type f -o -type l \) -mtime +${MAXLOGAGE} | while read OBJ
        do
            ${GZIP} -9 ${OBJ} 2>>${LOGFILE}
            #Log if command fails to work
			if [ ! $? -eq "0" ] ; then
                echo "ERROR: Gzip failed for ${OBJ}" >> $LOGFILE
                continue
            fi
            ${MV} ${OBJ}.gz $2 2>>${LOGFILE}
            #Log if command fails to work
			if [ ! $? -eq "0" ] ; then
                echo "ERROR: Log move failed for ${OBJ}.gz" >> $LOGFILE
                continue
            fi
            echo "Zipped and moved to archive: ${OBJ}" >> $LOGFILE
        done
    find ${1}* \( ! -name . -prune \) \( -type f -o -type l \) -name *.Z | while read OBJ
        do
            #Move all files which end in .Z and log all errors to log file
            ${MV} ${1}*.Z $2 2>>${LOGFILE}
            if [ ! $? -eq "0" ] ; then
                echo "ERROR: Log move failed for ${OBJ}.Z , skipping this file" >> $LOGFILE
                continue
            fi
            echo "Moved to archive: ${OBJ}" >> $LOGFILE
        done
fi
}

HOST=`${HOSTNAME}`

case "${HOST}" in
    ${ACMEVRAPP1})
                        HOST="VRWEB1@PROD.ACME"
                        compressWeb $ZIPPABLELOGSVR $ZIPPEDLOGSVR;;
    ${ACMEVRAPP2})
                        HOST="VRWEB2@PROD.ACME"
                        compressWeb $ZIPPABLELOGSVR $ZIPPEDLOGSVR;;
    ${ACMEWEB1})
                        HOST="VOWEB1@PROD.ACME"
                        compressWeb $ZIPPABLELOGSVO $ZIPPEDLOGSVO;;
    ${ACMEWEB2})
                        HOST="VOWEB2@PROD.ACME"
                        compressWeb $ZIPPABLELOGSVO $ZIPPEDLOGSVO;;
    ${UATACMEWEB1})
                        HOST="VOWEB1@TEST.ACME"
                        compressWeb $ZIPPABLELOGSVO $ZIPPEDLOGSVO;;
    ${UATACMEWEB2})
                        HOST="VOWEB2@TEST.ACME"
                        compressWeb $ZIPPABLELOGSVO $ZIPPEDLOGSVO;;
    ${UATVRAPP1})
                        HOST="VRWEB1@TEST.ACME"
                        compressWeb $ZIPPABLELOGSVR $ZIPPEDLOGSVR;;
    ${UATVRAPP2})
                        HOST="VRWEB2@TEST.ACME"
                        compressWeb $ZIPPABLELOGSVR $ZIPPEDLOGSVR;;
esac

rotateLogs

exit 0

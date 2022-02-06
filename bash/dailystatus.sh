#!/bin/ksh
#############################################################################
# Authors: Foobar ACME Technical Architect Team                           #
# Date: 02/28/2012                                                          #
# Purpose: This basic script to check running processes                     #
#          in the ACME PROD/UAT environments and send                        #
#          an e-mail after the result is found at 6:30 AM every day.        #
#          Results of the cronjob will be output                            #
#          to the corresponding log file.                                   #
#                                                                           #
# Rev    Date         Name           Description                            #
# -----  ----------   ------------   -------------                          #
# 1.0    02/28/2012   Daniel Kang    First Release                          #
# 1.1    02/29/2012   Daniel Kang    Cleaned up some variables,             #
#                                     added disk space monitoring           #
# 1.2    03/02/2012   Daniel Kang    Added spoofed e-mail addresses         #
#                                     and stripped hostnames                #
# 1.2.1  03/05/2012   Daniel Kang   Script cleanup                         #
# 1.3    03/05/2012   Daniel Kang   Logic changes to status checks         #
# 1.3.1  03/08/2012   Daniel Kang    Minor Bug Fixes                        #
# 1.4    03/09/2012   Daniel Kang    Added distribution list functionality  #
# 1.5    03/14/2012   Daniel Kang    Fixed log file logic and node names    #
# 1.6    03/15/2012   Daniel Kang    Added logic to e-mail at certain time  #
# 1.6.1  03/16/2012   Daniel Kang   Minor Bug Fixes in variables           #
# 1.6.2  03/21/2012   Daniel Kang   Minor change to some greps             #
# 1.6.3  03/30/2012   Daniel Kang    Tweak to database grep logic           # 
# 1.6.4  04/11/2012   Daniel Kang   Tweak to database grep logic           #
# 1.6.5  05/21/2012   Daniel Kang    More tweaks to database logic          #
# 1.6.6  05/30/2012   Daniel Kang    Added functionality to check  mounts   #
#############################################################################

##############
# Script vars#
##############
# Store current date
TIME=`date "+%Y-%m-%d-%H%M-%S"`
#When should the script should fire off the global morning check e-mails?
WHENTOALERT=630 #6:30 AM
CURRENTTIME=`date +%k%M`

# Hostnames for PROD/UAT
HOSTNAME=/usr/bin/hostname
HOST=`${HOSTNAME}`
ACME_VO_WEB1=acmeweb1
ACME_VO_WEB2=acmeweb2
ACME_VR_WEB1=acmevrapp1
ACME_VR_WEB2=acmevrapp2
ACME_VO_APP1=acmevoapp1
ACME_VO_APP2=acmevoapp2
ACME_VR_APP1=acmevrapp1
ACME_VR_APP2=acmevrapp2
ACME_DB1=acmedb1
ACME_DB2=acmedb2
UAT_VO_WEB1=uatacmeweb1
UAT_VO_WEB2=uatacmeweb2
UAT_VR_WEB1=uatvrapp1
UAT_VR_WEB2=uatvrapp2
UAT_VO_APP1=uatvoapp1
UAT_VO_APP2=uatvoapp2
UAT_VR_APP1=uatvrapp1
UAT_VR_APP2=uatvrapp2
UAT_DB1=uatacmedb1
UAT_DB2=uatacmedb2

#Disklog naming convention
DISKLOG=${HOST}.diskchecks.${TIME}.log

################
# Editable vars#
################
# Log Directory
LOGDIR=${HOME}/TA/logs/status
DIRDISK=${LOGDIR}/diskalerts
# Log File Locations
PROCLOG=${HOST}.procchecks.${TIME}.log
# Who to e-mail for alerts
ADMINSLIST=${HOME}/TA/adminslist.txt
# What percent should the disk space utilization be before send e-mail
ALERT=90

###########
#Functions#
###########
# Check if the proper volumes are mounted
function checkMounts {
grep /vrbase /etc/mnttab >> "$DIRDISK/$DISKLOG" && grep /tppsfeed /etc/mnttab >> "$DIRDISK/$DISKLOG"
if [ $? -eq 0 ]; then
	echo "[$TIME] Volumes OK: /vrbase and /tppsfeed are both mounted" >> "$DIRDISK/$DISKLOG"
else
	echo "[$TIME] WARNING: Check if /vrbase and /tppsfeed are mounted!" >> "$DIRDISK/$DISKLOG"
		while read LINE
			do 
				mailx -r $SENDER -s "${SENDER} WARNING: Check mount points /vrbase and /tppsfeed!" $LINE < "$DIRDISK/$DISKLOG"
			done < $ADMINSLIST
fi
}
# Check disk space utilization
function filesysSpaceUsage {
DISKISSUE=0     # Do not change. Default is 0
if [ ! -d "$DIRDISK" ]; then
    mkdir -p $DIRDISK
    echo "[$TIME] INFO: Log directory not found. Created directory." >> "$DIRDISK/$DISKLOG"
fi
# Get space info
df -ah |  grep -v '^Filesystem' | awk '{ print $5 " " $1 }' >> "$DIRDISK/$DISKLOG"
df -ah |  grep -v '^Filesystem' | awk '{ print $5 " " $1 }' | while read output
do
    # ignore any "Permission denied" lines
    echo $output | grep -i "Permission denied"
    if [ $? -eq 0 ]; then
        continue
    fi
    #Get space utilization number and location
    usedspace=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
    where=$(echo $output | awk '{ print $2 }' )
    # Check space utilization against alert value, set alert var if exceeded
    if [ $usedspace -gt $ALERT ]; then
        DISKISSUE=1
    else
        continue
    fi
done
# Send e-mail based on filesystem space utilization status
if [[ $CURRENTTIME -eq $WHENTOALERT && $DISKISSUE -eq 1 || $DISKISSUE -eq 1 ]]; then
    echo "[$TIME] ${SENDER} WARNING:  Filesystem space EXCEEDED threshold of $ALERT%!" >> "$DIRDISK/$DISKLOG"
    while read LINE
        do      
            mailx -r $SENDER -s "${SENDER} WARNING: Filesystem space EXCEEDED threshold of $ALERT%!" $LINE < "$DIRDISK/$DISKLOG"
        done < $ADMINSLIST
elif [[ $DISKISSUE -eq 0 && $CURRENTTIME -eq $WHENTOALERT ]]; then
    echo "[$TIME] ${SENDER} OK:  Filesystem space within threshold of $ALERT%" >> "$DIRDISK/$DISKLOG"
    while read LINE
        do 
            mailx -r $SENDER -s "${SENDER} OK: Filesystem utilization normal." $LINE < "$DIRDISK/$DISKLOG"
        done < $ADMINSLIST
fi
#Remove log files which aren't stored at 6:30 AM and don't contain warnings
if [[ $DISKISSUE -eq 0 && $CURRENTTIME -ne $WHENTOALERT ]]; then
    rm "$DIRDISK/$DISKLOG"
fi
}
# Rotate this script's logs
# Gzip this script's log files that are older than 30 days
function rotateLogs {
MAXLOGAGE=30
find $LOGDIR -mtime +${MAXLOGAGE} -exec gzip -9 {} \;
find $DIRDISK -mtime +${MAXLOGAGE} -exec gzip -9 {} \;    
}
# Check processes
function processCount {
PROCESSISSUE=0  # Do Not change. Default is 0.
LOGFILE=${HOST}.${1}.dailychecks.${TIME}.log
if [ ! -d "$LOGDIR" ]; then
    mkdir -p $LOGDIR
    echo "[$TIME] INFO: Log directory not found. Created directory." > "$LOGDIR/$LOGFILE"
fi
# Log the process status
/usr/ucb/ps -auxww | grep -v grep | grep "$1" >> "$LOGDIR/$LOGFILE"
NUMRUNPROC=`wc -l "$LOGDIR/$LOGFILE" | tr -s " " | cut -d" " -f 2`
if [ "${NUMRUNPROC}" -lt $NUMPROC ]; then
PROCESSISSUE=1
    echo "[$TIME] ${SENDER} WARNING:  Process counts below threshold!" >> "$LOGDIR/$LOGFILE"
fi
#Logic to e-mail or not based on status
if [[ $CURRENTTIME -eq $WHENTOALERT && $PROCESSISSUE -eq 1 || $PROCESSISSUE -eq 1 ]]; then
        while read LINE
            do 
                mailx -r $SENDER -s "${SENDER} WARNING:  process counts below threshold!" $LINE < "$LOGDIR/$LOGFILE"
            done < $ADMINSLIST 
elif [[ $PROCESSISSUE -eq 0 && $CURRENTTIME -eq $WHENTOALERT ]]; then
    echo "[$TIME] ${SENDER} OK:  Process counts are normal." >> "$LOGDIR/$LOGFILE"
        while read LINE
            do 
                mailx -r $SENDER -s "${SENDER} OK:  process counts normal." $LINE < "$LOGDIR/$LOGFILE"
            done < $ADMINSLIST
fi
#Remove log files which aren't stored at 6:30 AM and don't contain warnings
if [[ $PROCESSISSUE -eq 0 && $CURRENTTIME -ne $WHENTOALERT ]]; then
    rm "$LOGDIR/$LOGFILE"
fi
}

##########
# main() #
##########

# Rotate logs
rotateLogs

# Execute appropriate process checks based on the current hostname
case "${HOST}" in
    # PROD
    ${ACME_VO_WEB1})
                    SENDER="WEB.VOWEB1@PROD.ACME"
                    NUMPROC=5 #Minimum 5 httpd processes
                    processCount httpd
                    SENDER="DISK.VOWEB1@PROD.ACME"
                    ;;
    ${ACME_VO_WEB2})
                    SENDER="WEB.VOWEB2@PROD.ACME"
                    NUMPROC=5
                    processCount httpd
                    SENDER="DISK.VOWEB2@PROD.ACME"
                    ;;
    ${ACME_VO_APP1})
                    SENDER="APP1.VOAPP1@PROD.ACME"
                    NUMPROC=2 #run*.sh, java, and grep processes
                    processCount acmevoapp1
                    SENDER="APP2.VOAPP1@PROD.ACME"
                    processCount acmevoapp2
                    SENDER="DISK.VOAPP1@PROD.ACME"
                    ;;
    ${ACME_VO_APP2})
                    SENDER="APP3.VOAPP2@PROD.ACME"
                    NUMPROC=2
                    processCount acmevoapp3
                    SENDER="APP4.VOAPP2@PROD.ACME"
                    processCount acmevoapp4
                    SENDER="DISK.VOAPP2@PROD.ACME"
                    ;;
    ${ACME_VR_APP1})
					SENDER="MOUNTPOINTS.VRAPP1@PROD.ACME"
					checkMounts
                    SENDER="WEB.VRAPP1@PROD.ACME"
                    NUMPROC=5 #Minium 5 httpd processes
                    processCount httpd
                    SENDER="APP1.VRAPP1@PROD.ACME"
                    NUMPROC=2
                    processCount acmevrapp1
                    SENDER="APP2.VRAPP1@PROD.ACME"
                    processCount acmevrapp2
                    SENDER="DISK.VRAPP1@PROD.ACME"
                    ;;
    ${ACME_VR_APP2})
					SENDER="MOUNTPOINTS.VRAPP2@PROD.ACME"
					checkMounts
                    SENDER="WEB.VRAPP2@PROD.ACME"
	                NUMPROC=5
                    processCount httpd
                    SENDER="APP3.VRAPP2@PROD.ACME"
                    NUMPROC=2
                    processCount acmevrapp3
                    SENDER="APP4.VRAPP2@PROD.ACME"
                    processCount acmevrapp4
                    SENDER="DISK.VRAPP2@PROD.ACME"
                    ;;
    ${ACME_DB1})
					SENDER="MOUNTPOINTS.DB1@PROD.ACME"
					checkMounts
                    NUMPROC=1 #Listener
                    SENDER="DBLISTENER.DB1@PROD.ACME"
                    processCount "LISTENER "
                    NUMPROC=2 #2 mon DB processes
                    SENDER="MON.DB1@PROD.ACME"
                    processCount ora_[ps]mon_prodacme
                    SENDER="DISK.DB1@PROD.ACME"
                    ;;
    ${ACME_DB2})
					SENDER="MOUNTPOINTS.DB2@PROD.ACME"
					checkMounts
                    SENDER="DISK.DB2@PROD.ACME"
                    # Nothing to execute on 2nd global zone at this time
                    ;;
    # UAT
    ${UAT_VO_WEB1})
                    SENDER="WEB.VOWEB1@UAT.ACME"
                    NUMPROC=5 #Minimum 5 httpd processes
                    processCount httpd
                    SENDER="DISK.VOWEB1@UAT.ACME"
                    ;;
    ${UAT_VO_WEB2})
                    SENDER="WEB.VOWEB2@UAT.ACME"
                    NUMPROC=5
                    processCount httpd
                    SENDER="DISK.VOWEB2@UAT.ACME"
                    ;;
    ${UAT_VO_APP1})
                    SENDER="APP1.VOAPP1@UAT.ACME"
                    NUMPROC=2 #run*.sh, java, and grep processes
                    processCount acmevoapp1
                    SENDER="APP2.VOAPP1@UAT.ACME"
                    processCount acmevoapp2
                    SENDER="DISK.VOAPP1@UAT.ACME"
                    ;;
    ${UAT_VO_APP2})
                    SENDER="APP3.VOAPP2@UAT.ACME"
                    NUMPROC=2
                    processCount acmevoapp3
                    SENDER="APP4.VOAPP2@UAT.ACME"
                    processCount acmevoapp4
                    SENDER="DISK.VOAPP2@UAT.ACME"
                    ;;
    ${UAT_VR_APP1})
					SENDER="MOUNTPOINTS.VRAPP1@UAT.ACME"
					checkMounts
                    SENDER="APP1.VRAPP1@UAT.ACME"
                    NUMPROC=2 #For jboss VR app nodes
                    processCount acmevrapp1
                    SENDER="APP2.VRAPP1@UAT.ACME"
                    processCount acmevrapp2
                    NUMPROC=5 #For httpd processes
                    SENDER="WEB.VRAPP1@UAT.ACME"
                    processCount httpd
                    SENDER="DISK.VRAPP1@UAT.ACME"
                    ;;
    ${UAT_VR_APP2})
					SENDER="MOUNTPOINTS.VRAPP2@UAT.ACME"
					checkMounts
                    SENDER="APP3.VRAPP2@UAT.ACME"
                    NUMPROC=2 #For jboss VR app nodes
                    processCount acmevrapp3
                    SENDER="APP4.VRAPP2@UAT.ACME"
                    processCount acmevrapp4
                    NUMPROC=5 #For httpd processes
                    SENDER="WEB.VRAPP2@UAT.ACME"
                    processCount httpd
                    SENDER="DISK.VRAPP2@UAT.ACME"
                    ;;
    ${UAT_DB1})
					SENDER="MOUNTPOINTS.DB1@UAT.ACME"
					checkMounts
                    SENDER="DBLISTENER.DB1@UAT.ACME"
                    NUMPROC=1 #Listener Process
                    processCount "LISTENER "
                    SENDER="MON.DB1@UAT.ACME"
                    NUMPROC=2 #2 DB P/Smon processes
                    processCount ora_[ps]mon_uatacme
                    SENDER="DISK.DB1@UAT.ACME"
                    ;;
    ${UAT_DB2})
					SENDER="MOUNTPOINTS.DB2@UAT.ACME"
					checkMounts
                    SENDER="DISK.DB2@UAT.ACME"
                    # nothing to execute on 2nd global zone at this time
                    ;;
    # Template:
    # ${ZONE_VAR_NAME})
    #                    HOST="[WEB#|APP#|DB#].[SPOOFED-HOST]@[ENV].ACME"
    #                    NUMPROC=[expected number of processes]
    #                    processCheck [string to grep for in process]
    #                    any_other_code_here
    #                    ;;
esac

# Check filesystem utilization
# Must be ran after the above case
filesysSpaceUsage

# End of script
exit 0

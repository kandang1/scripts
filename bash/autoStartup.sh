#!/bin/ksh
############################################################
# Filename: autoStartup.ksh                                #
# Date Created: 02/18/2011                                 #
# Author: Daniel Kang                                      #
#                                                          #
# Use:  This script is used for starting the Application   # 
#       Servers and removing necessary file                # 
#						           #                    #	                                                   # 	
# Revision  Date      Author          Description          #
# --------  --------  --------------- -------------------- #
# 1.0       02/30/12  Daniel Kang      Initial Version     #
# 1.1       04/30/12  Daniel Kang     Removed Log Rotate   #
# 1.2       05/22/12  Daniel Kang     Added Cron Rotate    #
# 1.2.1     05/30/12  Daniel Kang  Added Mount Checks      #
############################################################
#*********************************
# Environmental Vars
#*********************************

RM=/usr/bin/rm
TAIL=/usr/bin/tail
ARP=/usr/sbin/arp
NOHUP=/usr/bin/nohup
NAWK=/usr/bin/nawk
HOSTNAME=/usr/bin/hostname
CRONTAB=/usr/bin/crontab
SED=/usr/bin/sed

#Temporary crontab file which the script will edit and reload
TMPFILE=/tmp/crontab.$$.tmp
#Location and name of crontab backup file
CRONBACKUP=crontab.backup.${TIME}
#Crontab backup directory
CRONDIR=${HOME}/TA/cronbackup
STATUS=0,15,30,45

#*********************************
# Startup Directories to be accessed
#*********************************
SERVER_DIR=/apps/jboss/jboss4/server/
LOGS_DIR=/logs/jboss4/
BIN=/apps/jboss/jboss4/bin
STARTUP_LOG=startup.log
ERROR_LOG=startup.err
TYPE="jboss.system:type=Server"
#*********************************
# Hostnames
#*********************************
DEV_VO_APP=acmedev03
DEV_VR_APP=acmedev04
UAT_VO_APP1=uatvoapp1
UAT_VO_APP2=uatvoapp2
UAT_VR_APP1=uatvrapp1
UAT_VR_APP2=uatvrapp2

UATVOAPP1_PORT=6182
UATVOAPP2_PORT=6122
UATVOAPP3_PORT=6132
UATVOAPP4_PORT=6142
UATVRAPP1_PORT=6213
UATVRAPP2_PORT=6223
UATVRAPP3_PORT=6233
UATVRAPP4_PORT=6243

ACME_VO_APP1=acmevoapp1
ACME_VO_APP2=acmevoapp2
ACME_VR_APP1=acmevrapp1
ACME_VR_APP2=acmevrapp2

ACMEVOAPP1_PORT=6182
ACMEVOAPP2_PORT=6122
ACMEVOAPP3_PORT=6132
ACMEVOAPP4_PORT=6142
ACMEVRAPP1_PORT=6213
ACMEVRAPP2_PORT=6223
ACMEVRAPP3_PORT=6233
ACMEVRAPP4_PORT=6243

#*********************************
# Users
#*********************************
JBOSS=jboss
WEBADMIN=webadmin

#*********************************
#Include common functions
#*********************************

#*********************************
#Include common functions
#*********************************
. /apps/jboss/jboss4/bin/lib.ksh

#*********************************
#These are temporary storage
#*********************************
VO_INSTANCE1=acmevoapp1
VO_INSTANCE2=acmevoapp2
VO_INSTANCE3=acmevoapp3
VO_INSTANCE4=acmevoapp4
VR_INSTANCE1=acmevrapp1
VR_INSTANCE2=acmevrapp2
VR_INSTANCE3=acmevrapp3
VR_INSTANCE4=acmevrapp4

function checkMounts {
grep /vrbase /etc/mnttab > /dev/null && grep /tppsfeed /etc/mnttab > /dev/null
	if [ $? -gt 0 ]; then
		echo "WARNING: Couldn't detect required mount points at /vrbase or /tppsfeed. Check them before starting up JBOSS app nodes!"
		echo "Aborting startup."
		exit 1
	fi
}

function removeDirectories {
	cd $1$2
	if [ $? -gt 0 ] 
		then
			logEvent ERROR -m "Directory Does not exist $1/$2..\n"
		else 
			${RM} -rf tmp
			if [ $? -gt 0 ]
				then
                    echo "ERROR: Unable to remove tmp directory at $1$2"
					logEvent ERROR -m "Unable to remove tmp directory at $1$2\n"
				else
                    echo "INFO: TMP directory has been removed at $1$2"
					logEvent INFO -m "Tmp Directory has been removed at $1$2\n"
			fi
			${RM} -rf work
			if [ $? -gt 0 ]
				then
                    echo "ERROR: Unable to remove work directory at $1$2" 
					logEvent ERROR -m "Unable to remove work directory at $1$2\n"
				else
                    echo "INFO: Work directory has been removed at $1$2"
					logEvent INFO -m "Work Directory has been removed at $1$2\n"
			fi
	fi
}

#function removeLogs { 
#	cd $1$2
#	if [ $? -gt 0 ]
#		then
#			logEvent ERROR -m "Directory Does not exist $1/$2.\n"
#		else
#			${RM} server.log* boot.log
#			if [ $? -gt 0 ]
#					then
#						logEvent ERROR -m "Unable to remove log files at $1/$2.\n"
#					else
#						logEvent INFO -m "Removed log files at $1/$2.\n"
#			fi
#	fi
#}

function startServer {
	cd $1
	if [ $? -gt 0 ]
		then
			logEvent ERROR -m "Directory Does not exist $1.\n"
		else
        echo "Starting up $4.. Please wait."
			`./$2 -b $3 -c $4 > nohup.out 2>&1 &`
			if [ $? -gt 0 ]
				then
					logEvent ERROR -m "Server startup command failed for instance $4.\n"
				else
					WAIT_MESSAGE="Please wait for $4 to start up before proceeding."
					echo ${WAIT_MESSAGE}
					while [[ `./twiddle.sh -s $3:$5 get "${TYPE}" Started` != "Started=true" ]]
					do
						# wait a couple of seconds between polling
						echo "."
						sleep 5
					done;
					echo "Server ${HOST} instance $4 startup was successfull.\n"
					logEvent INFO -m "Server ${HOST} instance $4 startup was successfull.\n"
			fi
	fi
}

#function mailLogFiles {

#if [ -a ${SCRIPT_LOG_DIR}/${PROCESSING_LOG} ]
#then
#        LOG_RET_VAL=`egrep '\|WARN\||\|ERROR\|' ${SCRIPT_LOG_DIR}/${PROCESSING_LOG} | wc -l`
#        if [ ${LOG_RET_VAL} -gt 0 ]
#        then
#                logEvent WARN -m "Received warning or error messages when encrypting & migrating PGP report for ${DATE} . Please review the ${SCRIPT_LOG_DIR}/${PROCESSING_ERROR_LOG} .\n"
#                cat ${SCRIPT_LOG_DIR}/${PROCESSING_LOG} | mailx -s "ERROR  - PGP Migration Report autoStatup ${DATE}" ${NOTIFICATION_LIST}
#        else
#        logEvent INFO -m "PGP Migration Report ${DATE} is successful.\n"
#                cat ${SCRIPT_LOG_DIR}/${PROCESSING_LOG} | mailx -s "PGP Migration Report autoStatup ${DATE}" ${NOTIFICATION_LIST}
#        fi
#fi
#}
#********************************
#Archive previous week's log files
#if they exist
#********************************

#********************************
#Setup logging
#********************************

setLogs -component autoStartup.ksh -logFile ${BIN}/${STARTUP_LOG} -errorFile ${BIN}/${ERROR_LOG} -logThreshold INFO -errorThreshold ERROR

#********************************
# Steps to Start the Servers
#********************************
HOST=`${HOSTNAME}`
IP=`${ARP} ${HOST} | ${NAWK} -F'[()]' '{print $2}'` 
case "${HOST}" in
	${DEV_VO_APP})
		RUN=run.sh;
		INSTANCE=${VO_INSTANCE1};
		removeDirectories $SERVER_DIR $INSTANCE;
		#removeLogs $LOGS_DIR $INSTANCE;
		startServer $BIN $RUN $IP $INSTANCE;;
	${DEV_VR_APP})
		RUN=run.sh;
		INSTANCE=${VR_INSTANCE1};
		removeDirectories $SERVER_DIR $INSTANCE;
		#removeLogs $LOGS_DIR $INSTANCE;
		startServer $BIN $RUN $IP $INSTANCE;;
	${UAT_VO_APP1})
		RUN1=run_voapp1.sh;
		RUN2=run_voapp2.sh;
		removeDirectories $SERVER_DIR ${VO_INSTANCE1};
		#removeLogs $LOGS_DIR ${VO_INSTANCE1};
		removeDirectories $SERVER_DIR ${VO_INSTANCE2};
		#removeLogs $LOGS_DIR ${VO_INSTANCE2};
		startServer $BIN $RUN1 $IP $VO_INSTANCE1 $UATVOAPP1_PORT;
		startServer $BIN $RUN2 $IP $VO_INSTANCE2 $UATVOAPP2_PORT;;
	${UAT_VO_APP2})
		RUN3=run_voapp3.sh;
		RUN4=run_voapp4.sh;
		removeDirectories $SERVER_DIR $VO_INSTANCE3;
		#removeLogs $LOGS_DIR $VO_INSTANCE3;
		removeDirectories $SERVER_DIR $VO_INSTANCE4;
		#removeLogs $LOGS_DIR $VO_INSTANCE4;
		startServer $BIN $RUN3 $IP $VO_INSTANCE3 $UATVOAPP3_PORT;
		startServer $BIN $RUN4 $IP $VO_INSTANCE4 $UATVOAPP4_PORT;;
	${UAT_VR_APP1})
		checkMounts
		RUN1=run_vrapp1.sh;
		RUN2=run_vrapp2.sh;
		removeDirectories $SERVER_DIR $VR_INSTANCE1;
		#removeLogs $LOGS_DIR $VR_INSTANCE1;
		removeDirectories $SERVER_DIR $VR_INSTANCE2;
		#removeLogs $LOGS_DIR $VR_INSTANCE2;
		startServer $BIN $RUN1 $IP $VR_INSTANCE1 $UATVRAPP1_PORT;
		startServer $BIN $RUN2 $IP $VR_INSTANCE2 $UATVRAPP2_PORT;;
	${UAT_VR_APP2})
		checkMounts
		RUN3=run_vrapp3.sh;
		RUN4=run_vrapp4.sh;
		removeDirectories $SERVER_DIR $VR_INSTANCE3;
		#removeLogs $LOGS_DIR $VR_INSTANCE3;
		removeDirectories $SERVER_DIR $VR_INSTANCE4;
		#removeLogs $LOGS_DIR $VR_INSTANCE4;
		startServer $BIN $RUN3 $IP $VR_INSTANCE3 $UATVRAPP3_PORT;
		startServer $BIN $RUN4 $IP $VR_INSTANCE4 $UATVRAPP4_PORT;;
	${ACME_VO_APP1})
		RUN=run.sh;
		removeDirectories $SERVER_DIR $VO_INSTANCE1;
		removeDirectories $SERVER_DIR $VO_INSTANCE2;
		startServer $BIN $RUN $IP $VO_INSTANCE1 ACMEVOAPP1_PORT;
		startServer $BIN $RUN $IP $VO_INSTANCE2 ACMEVOAPP2_PORT;;
	${ACME_VO_APP2})
		RUN=run.sh;
		INSTANCE=${VO_INSTANCE3};
		removeDirectories $SERVER_DIR $VO_INSTANCE4;
		startServer $BIN $RUN $IP $VO_INSTANCE3 $ACMEVOAPP3_PORT;
		startServer $BIN $RUN $IP $VO_INSTANCE4 $ACMEVOAPP4_PORT;;
	${ACME_VR_APP1})
		checkMounts
		RUN=run.sh;
		removeDirectories $SERVER_DIR $VR_INSTANCE1;
		removeDirectories $SERVER_DIR $VR_INSTANCE2;
		startServer $BIN $RUN $IP $VR_INSTANCE1 $ACMEVRAPP1_PORT;
		startServer $BIN $RUN $IP $VR_INSTANCE2 $ACMEVRAPP2_PORT;;
	${ACME_VR_APP2})
		checkMounts
		RUN=run.sh;
		removeDirectories $SERVER_DIR $VR_INSTANCE3;
		removeDirectories $SERVER_DIR $VR_INSTANCE4;
		startServer $BIN $RUN $IP $VR_INSTANCE3 $ACMEVRAPP3_PORT;
		startServer $BIN $RUN $IP $VR_INSTANCE4 $ACMEVRAPP4_PORT;;
esac
#Create the crontab backup directory
if [ ! -d $CRONDIR ]; then
    mkdir -p $CRONDIR
        if [ $? -eq 0 ]; then
            echo "Created a crontab backup dir at $CRONDIR"
        else
            echo "Couldn't create crontab backup dir, check permissions? Aborting script."
            exit 1
        fi
fi
#Backup/Edit/Swap crontab files
${CRONTAB} -l > ${CRONDIR}/${CRONBACKUP}
    if [ $? -eq 0 ]; then
        ${CRONTAB} -l > $TMPFILE
    else
        echo "WARNING: Couldn't uncomment crontab, check permissions?"
        exit 1
    fi
#Uncommenting the cron
${SED} "s/#${STATUS}/${STATUS}/g" ${CRONDIR}/${CRONBACKUP} > $TMPFILE
    if [ $? -eq 0 ]; then
        ${CRONTAB} $TMPFILE
            if [ $? -eq 0 ]; then
                echo "Successfully uncommented dailystatus crontab."
            else
                echo "WARNING: Couldn't uncomment out dailystatus crontab"             
            fi
    else
        echo "WARNING: Couldn't create uncommented crontab"
    fi		
#mailLogFiles
exit 0

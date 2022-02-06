#!/bin/ksh
################################################################################
# Filename: autoShutdown.ksh                                                   #                                            
# Date Created: 2/23/2011                                                      #
# Author: Daniel Kang                                                          #
#                                                                              #
# Use:  This script is used for automatically stopping                         #
#       The application server instances				       #
#						                               #
# Revision  Date      Author          Description                              #
# --------  --------  --------------- --------------------                     #
# 1.0       02/23/11  Daniel Kang      Initial Version                         #
# 1.1       04/18/12  Daniel Kang     Added log rotation and logic tweaks      #
# 1.1.1     04/19/12  Daniel Kang     Bug Fix in Log Rotation                  #
# 1.2       05/22/12  Daniel Kang     Added crontab edit functionality         #
# 1.2.1     05/31/12  Daniel Kang    Tweaked log rotation logic                #
################################################################################
#*********************************
TIME=`date "+%Y-%m-%d-%H-%M-%S"`
#Log File Locations and server.log directory
AXIS=/apps/jboss/jboss4/bin/axis.log
NOHUP=/apps/jboss/jboss4/bin/nohup.out
SERVERLOGDIR=/apps/jboss/jboss4/server

#Temporary crontab file which the script will edit and reload
TMPFILE=/tmp/crontab.$$.tmp
#Location and name of crontab backup file
CRONBACKUP=crontab.backup.${TIME}
#Crontab backup directory
CRONDIR=${HOME}/TA/cronbackup
STATUS=0,15,30,45

#*********************************
# Environmental Vars
#*********************************

CP=/usr/bin/cp
HOSTNAME=/usr/bin/hostname
GZIP=/usr/bin/gzip
MV=/usr/bin/mv
CRONTAB=/usr/bin/crontab
RM=/usr/bin/rm
SED=/usr/bin/sed

#Var for running app processes
RUNNINGPROC=`/usr/ucb/ps -auxww | grep -v grep | grep -v mstr | grep -v jdk | grep -i v[ro]app | wc -l`
#*********************************
#PGP SFTP USER ID
#*********************************
BIN=/apps/jboss/jboss4/bin/

#*********************************
#This are the temporary storage, archive and logging directories
#*********************************

DEV03=acmedev03
DEV03_PORT=8225
DEV04=acmedev04
DEV04_PORT=8230

UATVOAPP1=uatvoapp1
UATVOAPP2=uatvoapp2
UATVOAPP1_PORT=6182
UATVOAPP2_PORT=6122
UATVOAPP3_PORT=6132
UATVOAPP4_PORT=6142
UATVRAPP1=uatvrapp1
UATVRAPP2=uatvrapp2
UATVRAPP1_PORT=6213
UATVRAPP2_PORT=6223
UATVRAPP3_PORT=6233
UATVRAPP4_PORT=6243

VOAPP1=acmevoapp1
VOAPP2=acmevoapp2
VOAPP1_PORT=8182
VOAPP2_PORT=6122
VOAPP3_PORT=6132
VOAPP4_PORT=6142
VRAPP1=acmevrapp1
VRAPP2=acmevrapp2
VRAPP1_PORT=6213
VRAPP2_PORT=6223
VRAPP3_PORT=6233
VRAPP4_PORT=6243

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
        echo "Couldn't create a backup cron file, check permissions? Aborting script."
        exit 1
    fi
#Commenting out the cron
${SED} "s/${STATUS}/#${STATUS}/g" ${CRONDIR}/${CRONBACKUP} > $TMPFILE
    if [ $? -eq 0 ]; then
        ${CRONTAB} $TMPFILE
            if [ $? -eq 0 ]; then
                echo "Successfully commented dailystatus crontab."
            else
                echo "Couldn't comment out dailystatus crontab. Aborting"
                exit 1
            fi
    else
        echo "Couldn't create commented crontab, aborting script."
        exit 1
    fi

function serverShutdown {
    if [ $RUNNINGPROC -lt 1 ]; then
        echo "All JBOSS nodes are already shut down. Aborting."
        exit 1
    else
	./shutdown.sh -s $1:$2 -S
    fi
	if [ $? -gt 0 ] 
		then
			echo "Server $1 failed to shutdown.\n"
		else
            while [ `/usr/ucb/ps -auxww | grep -v grep | grep $3 | wc -l` -gt 0 ] 
            do
                echo "Shutdown script completed successfully.. waiting for remaining processes to die.."
                sleep 5
            done
            echo "Server $1 has been shutdown.\n"
            echo "App server $3 processes are dead... Beginning server.log rotation job.\n"
        if [ -f ${SERVERLOGDIR}/${3}/log/server.log ]; then
            ${MV} ${SERVERLOGDIR}/${3}/log/server.log ${SERVERLOGDIR}/${3}/log/server.log.${TIME}
            if [ $? -gt 0 ]; then
                    echo "Couldn't move SERVER.LOG file, check perms/space?"
                else
                    echo "Successfully rotated SERVER.LOG..."
            fi
        elif [ ! -f ${SERVERLOGDIR}/${3}/log/server.log ]; then
            echo "There doesn't appear to be a server.log file for $3.. skipping"
        fi
rotateLogs
fi
}
function rotateLogs {
        if [ -f $NOHUP ]; then
           ${MV} ${NOHUP} ${NOHUP}.${TIME}
           ${GZIP} -9 ${NOHUP}.${TIME} &
                if [ $? -gt 0 ]; then
                    echo "Couldn't start gzip job of NOHUP.OUT file!"
                else
                    echo "Successfully started gzip job of NOHUP.OUT!"
                fi
        elif [ -f ${NOHUP}.${TIME}.gz ]; then
           echo "Zipped NOHUP.OUT file already exists, skipping.."
        else 
            echo "There is no Nohup file to compress!"
        fi        
        if [ -f $AXIS ]; then
           ${MV} ${AXIS} ${AXIS}.${TIME}
           ${GZIP} -9 ${AXIS}.${TIME} &
                if [ $? -gt 0 ]; then
                    echo "Couldn't start gzip job of AXIS.LOG file!"
                else
                    echo "Successfully started gzip job of AXIS.LOG!"
                fi
        elif [ -f ${AXIS}.${TIME}.gz ]; then
            echo "Zipped AXIS.LOG file already exists, skipping.." 
        else
            echo "There is no axis log file to compress!"
        fi
}

#********************************
# Shutdown the Application Servers and Rotate Logs
#********************************

cd ${BIN}
if [ $? -gt 0 ] 
	then
		echo "Directory ${BIN} Does not exist.\n"
	else 
		HOST=`${HOSTNAME}`
		if [ $? -gt 0 ]
			then
				echo "Command HOSTNAME failed to Run.\n"
			else
				case "${HOST}" in 
					${DEV03}) 
						serverShutdown ${DEV03} ${DEV03_PORT} acmevoapp1;;
					${DEV04}) 
						serverShutdown ${DEV04} ${DEV04_PORT} acmevrapp1;;
					${UATVOAPP1}) 
                        serverShutdown ${UATVOAPP1} ${UATVOAPP1_PORT} acmevoapp1;
						serverShutdown ${UATVOAPP1} ${UATVOAPP2_PORT} acmevoapp2;;
					${UATVOAPP2}) 
						serverShutdown ${UATVOAPP2} ${UATVOAPP3_PORT} acmevoapp3;
						serverShutdown ${UATVOAPP2} ${UATVOAPP4_PORT} acmevoapp4;;
					${VOAPP1}) 
						serverShutdown ${VOAPP1} ${ACMEVOAPP1_PORT} acmevoapp1;
						serverShutdown ${VOAPP1} ${ACMEVOAPP2_PORT} acmevoapp2;;
					${VOAPP2}) 
						serverShutdown ${VOAPP2} ${ACMEVOAPP3_PORT} acmevoapp3;
						serverShutdown ${VOAPP2} ${ACMEVOAPP4_PORT} acmevoapp4;;
					${UATVRAPP1}) 
						serverShutdown ${UATVRAPP1} ${UATVRAPP1_PORT} acmevrapp1;
						serverShutdown ${UATVRAPP1} ${UATVRAPP2_PORT} acmevrapp2;;
					${UATVRAPP2}) 
						serverShutdown ${UATVRAPP2} ${UATVRAPP3_PORT} acmevrapp3;
						serverShutdown ${UATVRAPP2} ${UATVRAPP4_PORT} acmevrapp4;;
					${VRAPP1}) 
						serverShutdown ${VRAPP1} ${ACMEVRAPP1_PORT} acmevrapp1;
						serverShutdown ${VRAPP1} ${ACMEVRAPP2_PORT} acmevrapp2;;
					${VRAPP2}) 
						serverShutdown ${VRAPP2} ${ACMEVRAPP3_PORT} acmevrapp3;
						serverShutdown ${VRAPP2} ${ACMEVRAPP4_PORT} acmevrapp4;;
				esac
		fi
fi
exit 0

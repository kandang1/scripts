#!/bin/bash
################################################################################
# Authors: Foobar ACME Technical Architect Team                              #
# Date: 05/03/2012                                                             #
# Purpose: This script will be used to deploy code drops into UAT/PROD/DEV     #
# Usage: ./codeDrop.sh                                                         #
# Rev    Date         Name           Description                               #
# -----  ----------   ------------   -------------                             #
# 1.0    5/21/2012    Daniel Kang    Initial Release                           # 
# 1.1	 5/29/2012	  Daniel Kang    Logic Tweaks                              #         
# 1.1.1  5/31/2012    Daniel Kang    Bug Fix								   #
# 1.1.2  6/05/2012	  Daniel Kang	 Logic Fixes                               #
################################################################################
#Global Vars
RUNNINGPROC=`/usr/ucb/ps -auxww | grep -v grep | grep -v mstr | grep -v jdk | grep -i v[ro]app | wc -l`
TIME=`date "+%Y-%m-%d-%H-%M-%S"`
LOGDIR=${HOME}/TA/logs
LOGFILE=codedrop.log.${TIME}
HOSTNAME=/usr/bin/hostname
HOST=`${HOSTNAME}`
GZIP=/usr/bin/gzip
TAR=/usr/bin/tar
MV=/usr/bin/mv
LS=/usr/bin/ls
CP=/usr/bin/cp
NODEDIR=${HOME}/jboss4/server
BACKUPDIR=${HOME}/TA/codebackups
TACODEDIR=${HOME}/TA/staging
FOUNDCODE=0
validTmp=0
DROPCHOICE=0
#Sql drop reminder variable
SQL=0
#Default Code Drop Directory
CODEDIR=/tmp/codedrops
###########
#FUNCTIONS#
###########
#This function will take a backup of the current environment.
function takeBackup {
echo "Taking backup of $EARFILE from $1"
echo "[$TIME] INFO: Started backup of the $EARFILE of $1" >> $LOGDIR/$LOGFILE
if [ -d ${NODEDIR}/${1} ]; then
        if [ -w ${NODEDIR} ]; then
        ${TAR} cf ${NODEDIR}/${1}.${EARFILE}.${TIME}.tar ${NODEDIR}/${1}/deploy/${EARFILE}
            if [ $? -gt 0 ]; then
                echo "Error occured while trying to tar the EAR file, aborted."
                echo "ERROR: Couldn't tar archive ${NODEDIR}/${1}/deploy/$EARFILE, aborted script." >> $LOGDIR/$LOGFILE
                exit 1
            else    
                echo "OK: Successfully tarred ${NODEDIR}/${1}/deploy/$EARFILE"
                echo "INFO: Successfully tarred ${NODEDIR}/${1}/deploy/$EARFILE" >> $LOGDIR/$LOGFILE
                echo "Starting gzip operation of ${NODEDIR}/${1}/deploy/$EARFILE..."
                    ${GZIP} -9 ${NODEDIR}/${1}.${EARFILE}.${TIME}.tar
                        if [ $? -eq 0 ]; then
                            echo "OK: Successfully gzipped EAR FILE for ${1}"
                            echo "INFO: Successfully gzipped EAR file for $1" >> $LOGDIR/$LOGFILE
                            ${MV} ${NODEDIR}/${1}.${EARFILE}.${TIME}.tar.gz ${BACKUPDIR}
                            if [ $? -eq 0 ]; then
                                echo "OK: Successfully moved $1's EAR file into $BACKUPDIR"
                                echo "[$TIME] INFO: Successfully moved backup of $1 into $BACKUPDIR" >> $LOGDIR/$LOGFILE
                            else
                                echo "Couldn't move backup of $1's EAR file into $BACKUPDIR, aborted script!"
                                echo "[$TIME] ERROR: Couldn't move backup of $1's EAR file into $BACKUPIR!, aborted script!" >> $LOGDIR/$LOGFILE
                            fi
                        else
                            echo "Error occured while zipping ${NODEDIR}/${1}.${EARFILE}.${TIME}.tar, check disk space?"
                            echo "Aborted Script"
                            echo "ERROR: Couldn't gzip ${NODEDIR}/${1}.${EARFILE}.${TIME}.tar, check disk space?" >> $LOGDIR/$LOGFILE
                            exit 1
                        fi
            fi
        else
            echo "No write permission to ${NODEDIR}, aborting"
            echo "ERROR: No write permission to ${NODEDIR}, aborted." >> $LOGDIR/$LOGFILE
            exit 1
        fi    
else
    echo "Couldn't find the directory ${NODEDIR}/${1}, aborted script."
    echo "[$TIME] ERROR: Couldn't find the directory ${NODEDIR}/${1}, aborted during code backup." >> $LOGDIR/$LOGFILE
    exit 1
fi
}
function copyCode {
if [[ -f *${APPTYPE}*/*release*/*.sql ]]; then
SQL=1
	echo "WARNING: Detected SQL portion with drop. Please be sure that the DB portion is also completed."
	echo "[$TIME] INFO: Detected SQL script in addition to code drop files." >> $LOGDIR/$LOGFILE
fi
if [ -r *${APPTYPE}*/*release*/${FILETYPE} ]; then
	${CP} -p *${APPTYPE}*/*release*/${FILETYPE} ${NODEDIR}/${1}/deploy/.
        if [ $? -eq 0 ]; then
		validtheFile=1
            echo "OK: Successfully copied the $FILETYPE file into ${1} node."
            echo "[$TIME] INFO: Successfully copied $FILETYPE into ${1}" >> $LOGDIR/$LOGFILE
            chmod 700 ${NODEDIR}/${1}/deploy/${FILETYPE}
                if [ $? -eq 0 ]; then
                    echo "OK: Successfully changed perms of ${FILETYPE} to 700".
                    echo "[$TIME] INFO: Successfully changed permissions of ${FILETYPE} to 700." >> $LOGDIR/$LOGFILE
                    rm -rf ${NODEDIR}/${1}/tmp/
                        if [ $? -eq 0 ]; then
                            echo "OK: Removed tmp directory for $1"
                            echo "[$TIME] INFO: Removed tmp directory for $1" >> $LOGDIR/$LOGFILE
                        else
                            echo "Warning: Unable to remove tmp directory for $1"
                            echo "[$TIME] Warning: Unable to remove tmp directory for $1" >> $LOGDIR/$LOGFILE
                        fi
                    rm -rf ${NODEDIR}/${1}/work/
                        if [ $? -eq 0 ]; then
                            echo "OK: Removed work directory for $1"
                            echo "[$TIME] INFO: Removed work directory for $1"
                        else
                            echo "Warning: Unable to remove work directory for $1"
                            echo "[$TIME] Warning: Unable to remove work directory for $1" >> $LOGDIR/$LOGFILE
                        fi
                else
                    echo "Error: Couldn't assign proper permissions to $1's ${FILETYPE}"
                    echo "[$TIME] ERROR: Couldn't assign proper permissions to $1's ${FILETYPE}. Aborted Script." >> $LOGDIR/$LOGFILE
                    exit 1
                fi
        else
            echo "Couldn't copy $FILETYPE into ${1}. Check file space? Aborted!"
            echo "[$TIME] Error: Couldn't copy $FILETYPE into ${1}. Check file space? Aborted." >> $LOGDIR/$LOGFILE      
            exit 1
        fi
else
validtheFile=0
	echo "Can't find a valid ${FILETYPE} to drop in under *${APPTYPE}*/*release*, entering manual select mode."
	echo "Couldn't find valid ${FILETYPE} to drop into ${HOST}, went into manual select mode." >> $LOGDIR/$LOGFILE
until [ $validtheFile -eq 1 ]; do
	echo "Please specify a ${FILETYPE} to drop in."
		read -e THEFILE
			if [ -r $THEFILE ]; then
				case $THEFILE in
				${FILETYPE})
						validtheFile=1
							echo "Dropping $THEFILE into $1"
								${CP} -p $THEFILE ${NODEDIR}/${1}/deploy/.
									if [ $? -eq 0 ]; then
										echo "[$TIME] INFO: Dropped $THEFILE into node $1" >> $LOGDIR/$LOGFILE
									else
										echo "WARNING: Couldn't drop code drop file $THEFILE into $1, aborting script."
										echo "WARNING: Code wasn't dropped.. drop ear files manually!"
										echo "[$TIME] Error: Couldn't drop code (${THEFILE}) into $1, aborted." >> $LOGDIR/$LOGFILE
										exit 1
                                    fi;;
							*)
						validtheFile=0
							 echo "Invalid selection ($THEFILE)."
							 echo "[$TIME] Error: Invalid selection ($THEFILE).";;
				esac
			else
				echo "No read access to $THEFILE, please try again"
				echo "[$TIME] Error: No read access to $THEFILE. Asking for another file." >> $LOGDIR/$LOGFILE
				validtheFile=0
			fi
done
fi				
}
function specifyDrop {
validLocation=0
until [ $validLocation -eq 1 ]; do
echo "Please enter the location of the codedrop file (tar.gz file)"
read -e LOCATION
case $LOCATION in
    *${APPTYPE}.tar.gz)
            if [ -r $LOCATION ]; then
                validLocation=1
                uncompressDeploy $LOCATION
            else
                validLocation=0
            fi;;
            *) 
                validLocation=0
                echo "Invalid file, try again";;
esac
done
}
function uncompressDeploy {
mkdir -p $STAGEDIRECTORY/codedrop_$TIME
    if [ $? -eq 0 ]; then
        echo "INFO: Created code staging directory $STAGEDIRECTORY/CodeDrop_$TIME"
        echo "[$TIME] INFO: Successfully created staging directory ($STAGEDIRECTORY/CodeDrop_$TIME)" >> $LOGDIR/$LOGFILE
    else
        echo "Couldn't create staging directory! ($STAGEDIRECTORY/CodeDrop_$TIME) - Check permissions? Aborting Script!"
        echo "[$TIME] Error: Couldn't create staging directory ($STAGEDIRECTORY/CodeDrop_$TIME), aborted script." >> $LOGDIR/$LOGFILE
        exit 1
    fi
mv $1 $STAGEDIRECTORY/codedrop_$TIME
    if [ $? -eq 0 ]; then
        echo "OK: Successfully moved code drop file into staging directory"
        echo "[$TIME] INFO: Successfully moved code drop file into staging directory" >> $LOGDIR/$LOGFILE
    else
        echo "Error: Couldn't move code drop into staging directory! Aborted!"
        echo "[$TIME] Error: Couldn't move code drop file into staging directory" >> $LOGDIR/$LOGFILE
        exit 1
    fi    
cd $STAGEDIRECTORY/codedrop_$TIME
    if [ $? -eq 0 ]; then
        ${GZIP} -d *.gz
            if [ $? -eq 0 ]; then
            echo "OK: Successfully unzipped code drop file ($1)"
            echo "[$TIME] INFO: Successfully unzipped code drop file ($1)" >> $LOGDIR/$LOGFILE
                ${TAR} xf *.tar
                    if [ $? -eq 0 ]; then
                        echo "OK: Successfully untarred code drop file ($1)"
                        echo "[$TIME] INFO: Successfully untarred code drop file ($1)" >> $LOGDIR/$LOGFILE
                    else
                        echo "Error: Couldn't untar the code drop file ($1) Aborting!"
                        echo "[$TIME] Error: Couldn't untar the code drop file, check file space? Aborted Script." >> $LOGDIR/$LOGFILE
                        exit 1
                    fi
            else
                echo "Error: Couldn't unzip code drop files! Aborted."
                echo "[$TIME] Error: Couldn't unzip code drop files! Aborted script!" >> $LOGDIR/$LOGFILE
                exit 1
            fi
    else
        echo "Error: Couldn't change directory into ($STAGEDIRECTORY/CodeDrop_$TIME) to unzip files... aborting script!"
        echo "[$TIME] Error: Couldn't change directory to unzip files. Aborted." >> $LOGDIR/$LOGFILE
        exit 1
    fi
case "${HOST}" in
 *voapp1)
        copyCode acmevoapp1 
        copyCode acmevoapp2;;
 *voapp2)
        copyCode acmevoapp3 
        copyCode acmevoapp4;;
 *vrapp1)
        copyCode acmevrapp1 
        copyCode acmevrapp2;;
 *vrapp2)
        copyCode acmevrapp3 
        copyCode acmevrapp4;;
  *dev04)
        copyCode acmevrapp1;;
  *dev03)
        copyCode acmevoapp1;;
       *)
        echo "This does not appear to be the correct host to run this script on (${HOST})?."
        echo "[$TIME] ERROR: Detected wrong node (${HOST}), aborted script during code copy function" >> $LOGDIR/$LOGFILE
        exit 1;;
esac
echo "[$TIME] INFO: Code drop to both node(s) successful" >> $LOGDIR/$LOGFILE
echo "OK: Successfully dropped code into both application node(s)! Check your code drop log ($LOGDIR/$LOGFILE) for details."
}
function findCode {
case "${HOST}" in
        *vo*)
            APPTYPE=VO
            FILETYPE=datamart.ear;;
        *vr*)
            APPTYPE=VR
            FILETYPE=le5.ear;;
        *dev04)
            APPTYPE=VR
            FILETYPE=le5.ear;;
        *dev03)
            APPTYPE=VO
            FILETYPE=datamart.ear;;
           *)
                echo "Invalid host type, aborting script."
                echo "ERROR: Invalid host ${HOST} found during code staging function" >> $LOGDIR/$LOGFILE
                exit 1;;
esac
DROP1=`ls -t1 $HOME/TA/*${APPTYPE}.tar.gz 2>/dev/null | head -n1`
DROP1DATE=`ls -lrt $HOME/TA/*${APPTYPE}.tar.gz 2>/dev/null | head -n1 | awk '{print $6,$7,$8}'`
DROP2=`ls -t1 $CODEDIR/*${APPTYPE}.tar.gz 2>/dev/null | head -n1`
DROP2DATE=`ls -lrt $CODEDIR/*${APPTYPE}.tar.gz 2>/dev/null | head -n1 | awk '{print $6,$7,$8}'`
DROP3=`ls -t1 $HOME/*${APPTYPE}.tar.gz 2>/dev/null | head -n1`
DROP3DATE=`ls -lrt $HOME/*${APPTYPE}.tar.gz 2>/dev/null | head -n1 | awk '{print $6,$7,$8}'`
DROP4=`ls -t1 /tmp/*${APPTYPE}.tar.gz 2>/dev/null | head -n1`
DROP4DATE=`ls -lrt /tmp/*${APPTYPE}.tar.gz 2>/dev/null | head -n1 | awk '{print $6,$7,$8}'`
#Determine if it's a VO or VR tar gz file
until [ $FOUNDCODE -eq 1 ]; do
if [ -n "$DROP1" ]; then
    if [ -f $DROP1 ]; then
        echo "File found under ($HOME/TA/) Use this file?" 
        echo "File Name: $DROP1"
        echo "File Time Stamp: $DROP1DATE"
        until [ $DROPCHOICE -eq 1 ]; do
            read -p "Use this file? (Y/N) " CHOICE
                case $CHOICE in
                [yY] | [yY][Ee][Ss])
                        echo "[$TIME] INFO: User selected $DROP1 as code drop file" >> $LOGDIR/$LOGFILE
						FOUNDCODE=1
                        DROPCHOICE=1
                        uncompressDeploy $DROP1;;
                [nN] | [nN][Oo])
                        echo "[$TIME] INFO: User selected to skip $DROP1 as code drop file" >> $LOGDIR/$LOGFILE
                        break;;
                        *)
                        echo "Invalid selection, try again"
                        DROPCHOICE=0;;
                 esac
        done
    fi
else
    echo "No suitable files found in ($HOME/TA), moving on..."
fi
    echo "Searching for suitable files under ($CODEDIR)..."
if [ -n "$DROP2" ]; then
    if [ -f $DROP2 ]; then
        echo "File found under ($CODEDIR) Use this file?" 
        echo "File Name: $DROP2"
        echo "File Time Stamp: $DROP2DATE"
        DROPCHOICE=0
        until [ $DROPCHOICE -eq 1 ]; do
            read -p "Use this file? (Y/N) " CHOICE
                case $CHOICE in
                [yY] | [yY][Ee][Ss])
                        echo "[$TIME] INFO: User selected $DROP2 as code drop file" >> $LOGDIR/$LOGFILE
						FOUNDCODE=1
                        DROPCHOICE=1
                        uncompressDeploy $DROP2;;
                [nN] | [nN][Oo])
                        echo "[$TIME] INFO: User selected to skip $DROP2 as code drop file" >> $LOGDIR/$LOGFILE
                        break;;
                        *)
                        echo "Invalid selection, try again"
                        DROPCHOICE=0;;
                esac
        done
    else
        echo "No suitable files found in ($CODEDIR), moving on..."
    fi
fi
    echo "Searching for suitable files under ($HOME)..."
if [ -n "$DROP3" ]; then
    if [ -f $DROP3 ]; then
        echo "File found under ($HOME) Use this file?" 
        echo "File Name: $DROP3"
        echo "File Time Stamp: $DROP3DATE"
        DROPCHOICE=0
        until [ $DROPCHOICE -eq 1 ]; do
            read -p "Use this file? (Y/N) " CHOICE
                case $CHOICE in
                [yY] | [yY][Ee][Ss])
                        echo "[$TIME] INFO: User selected $DROP3 as code drop file" >> $LOGDIR/$LOGFILE
						FOUNDCODE=1
                        DROPCHOICE=1
                        uncompressDeploy $DROP3;;
                [nN] | [nN][Oo])
                        echo "[$TIME] INFO: User selected to skip $DROP3 as code drop file" >> $LOGDIR/$LOGFILE
                        break;;
                        *)
                        echo "Invalid selection, try again"
                        DROPCHOICE=0;;
                esac
        done
    fi
else
    echo "No suitable files found in ($HOME).. moving on.."
    echo "[$TIME] INFO: Couldn't find any suitable code drop files under $HOME" >> $LOGDIR/$LOGFILE
fi
if [ -n "$DROP4" ]; then
    if [ -f $DROP4 ]; then
        echo "File found under (/tmp/) Use this file?" 
        echo "File Name: $DROP4"
        echo "File Time Stamp: $DROP4DATE"
        DROPCHOICE=0
        until [ $DROPCHOICE -eq 1 ]; do
            read -p "Use this file? (Y/N) " CHOICE
                case $CHOICE in
                [yY] | [yY][Ee][Ss])
                        echo "[$TIME] INFO: User selected $DROP4 as code drop file" >> $LOGDIR/$LOGFILE
						FOUNDCODE=1
                        DROPCHOICE=1
                        uncompressDeploy $DROP4;;
                [nN] | [nN][Oo])
                        echo "[$TIME] INFO: User selected to skip $DROP4 as code drop file" >> $LOGDIR/$LOGFILE
                        break;;
                        *)
                        echo "Invalid selection, try again"
                        DROPCHOICE=0;;
                esac
        done
    fi
else
	FOUNDCODE=1
    echo "No suitable files found in (/tmp) either! Entering manual select mode."
    echo "[$TIME] INFO: Couldn't find any suitable code drop files under $HOME, $HOME/TA, $CODEDIR, or /tmp, going into custom select mode" >> $LOGDIR/$LOGFILE
    specifyDrop
fi
done
}
######
#MAIN#
######
#Check to see if any app nodes are up first, and abort if any are found
if [ ! -d $LOGDIR ]; then
	mkdir -p $LOGDIR
	echo "[$TIME] INFO: Created log directory $LOGDIR" >> $LOGDIR/$LOGFILE
fi
if [ $RUNNINGPROC -gt 0 ]; then
    echo "Detected running app nodes! Aborting!"
    echo "[$TIME] ERROR: Detected running app nodes, aborted script" >> $LOGDIR/$LOGFILE
    exit 1
fi
#Print warning message out to user and allow them to cancel
echo "This is an ACME JBOSS code drop script. press CTRL+C within 10 seconds to cancel...."
sleep 10
#Check to see if code backups directory exists or can be created
echo "Checking if code backup directory $BACKUPDIR exists.."
if [ ! -d $BACKUPDIR ]; then
    mkdir -p $BACKUPDIR
        if [ $? -gt 0 ]; then
            echo "Couldn't create code backup directory ($BACKUPDIR), check permissions/space?"
            echo "[$TIME] ERROR: Couldn't create code backup directory, aborted script" >> $LOGDIR/$LOGFILE    
            exit 1
        else
            echo "INFO: Created code backup directory. ($BACKUPDIR)"
            echo "[$TIME] INFO: Created code backup directory at $BACKUPDIR" >> $LOGDIR/$LOGFILE
        fi
fi
case "${HOST}" in
 *voapp1)
        EARFILE=datamart.ear
        takeBackup acmevoapp1
        takeBackup acmevoapp2;;
 *voapp2)
        EARFILE=datamart.ear
        takeBackup acmevoapp3
        takeBackup acmevoapp4;;
 *vrapp1)
        EARFILE=le5.ear
        takeBackup acmevrapp1
        takeBackup acmevrapp2;;
 *vrapp2)
        EARFILE=le5.ear
        takeBackup acmevrapp3
        takeBackup acmevrapp4;;
 *dev04)
        EARFILE=le5.ear
        takeBackup acmevrapp1;;
 *dev03)
        EARFILE=datamart.ear
        takeBackup acmevoapp1;;
       *)
        echo "This does not appear to be the correct host to run this script on."
        echo "[$TIME] ERROR: Detected wrong host, aborted script." >> $LOGDIR/$LOGFILE
        exit 1;;
esac
#Prompt the user and ask where they want to stage code drop files
echo "Where would you like to stage the code drop files?"
select CHOICE in $CODEDIR $TACODEDIR Custom Quit
    do
            case $CHOICE in
            $CODEDIR)
                    echo "[$TIME] INFO: User selected $CODEDIR as the staging directory" >> $LOGDIR/$LOGFILE
                    echo "Using $CODEDIR as staging directory."
                    STAGEDIRECTORY=$CODEDIR
                    findCode
                    break;;
            $TACODEDIR)
                    echo "[$TIME] INFO: User selected $TACODEDIR as the staging directory" >> $LOGDIR/$LOGFILE
                    echo "Using $TACODEDIR as staging directory."
                    STAGEDIRECTORY=$TACODEDIR
                    findCode
                    break;;
            Custom)
                   validTmp=0
                   while [ $validTmp -eq 0 ]
                        do
                        echo "Custom: Please enter the full path of your tmp/staging directory where the code will be staged"
                            read -e tmpDir
                        if [ -d $tmpDir ]; then
                                if [ -w $tmpDir ]; then
                                        validTmp=1
                                        echo "[$TIME] INFO: Selected $tmpDir as code drop staging directory" >> $LOGDIR/$LOGFILE
                                        echo "Using $tmpDir as staging directory."
                                elif [ ! -w $tmpDir ]; then
                                        echo "Error: No write permissions to $tmpDir, can't use this."
                                fi
                        else
                            validTmp=0
                            echo "ERROR: $tmpDir is not a valid directory, please try again"
                        fi
                        done
                    STAGEDIRECTORY=$tmpDir
                    findCode
                    break;;
            Quit)
                    echo "Good Bye Cruel World."
                    echo "[$TIME] INFO: Aborted upon user request during specification of staging directory." >> $LOGDIR/$LOGFILE
                    exit 1;;
               *)
                    echo "ERROR: Invalid selection, try again.";;
            esac
done
if [ $SQL -eq 1 ]; then
	echo "*****************************************"
	echo "Reminder! SQL Portion Detected With Drop!" 
	echo "*****************************************"
	echo "[$TIME] INFO: Script issued warning to user of SQL portion being included in the drop." >> $LOGDIR/$LOGFILE
fi
#End of Script
exit 0

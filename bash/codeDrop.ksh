#!/bin/bash
################################################################################
# Authors: Foobar ACME Technical Architect Team                              #
# Date: 05/03/2012                                                             #
# Purpose: This script will be used to deploy code drops into UAT/PROD         #
# Usage: ./codeDrop.ksh                                                        #
# Rev    Date         Name           Description                               #
# -----  ----------   ------------   -------------                             #
# 1.0                 Daniel Kang    Initial Release                           # 
#                                                                              #         
#                                                                              #
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
VR=le5.ear
VO=datamart.ear
#Where all of the jboss nodes should be installed under
NODEDIR=${HOME}/jboss4/server
BACKUPDIR=${HOME}/TA/codebackups
TACODEDIR=${HOME}/TA/staging
validTmp=0
#Default Code Drop Directory
CODEDIR=/tmp/codedrops

###########
#FUNCTIONS#
###########
#This function will first detect what node it's running on and take a backup of the current environment.
#Afterwards, it will unzip and deploy 
function backupCode {
if [ -d ${NODEDIR}/${1} ]
echo "Yes I found $NODEDIR/$1"

}
function stageCode {
case "${HOST}" in
 *voapp1)
        echo "Detected VO_1 Node Drop";;
 *voapp2)
        echo "Detected VO_2 Node Drop";;
 *vrapp1)
        echo "Detected VR_1 Node Drop";;
 *vrapp2)
        echo "Detected VR_2 Node Drop";;
   *)
        echo "This does not appear to be the correct host to run this script on."
        echo "ERROR: Detected wrong node, aborted script." >> $LOGDIR/$LOGFILE
        exit 1;;
esac
}

#Check to see if any app nodes are up first, and abort if any are found
if [ $RUNNINGPROC -gt 0 ]; then
    echo "Detected running app nodes! Aborting!"
    echo "[$TIME] ERROR: Detected running app nodes, aborted script" >> $LOGDIR/$LOGFILE
    exit 1
fi
#Check to see if code backups directory exists or can be created
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

#As a pre-deployment task, take a backup of the current jboss installation before proceeding.
case "${HOST}" in
 *voapp1)
        echo "Taking backup of acmevoapp1 node..."
        echo "[$TIME] INFO: Started backup of acmevoapp1 node" >> $LOGDIR/$LOGFILE
        backupCode acmevoapp1;;
 *voapp2)
        echo "Taking backup of acmevoapp3 node..."
        echo "[$TIME] INFO: Started backup of acmevoapp3 node" >> $LOGDIR/$LOGFILE
        backupCode acmevoapp3;;
 *vrapp1)
        echo "Taking backup of acmevrapp1 node..."
        echo "[$TIME] INFO: Started backup of acmevrapp1 node" >> $LOGDIR/$LOGFILE
        backupCode acmevrapp1
 *vrapp2)
        echo "Taking backup of acmevrapp3 node..."
        echo "[$TIME] INFO: Started backup of acmevrapp3 node" >> $LOGDIR/$LOGFILE
        backupCode acmevrapp3
       *)
        echo "This does not appear to be the correct host to run this script on."
        echo "[$TIME] ERROR: Detected wrong node, aborted script." >> $LOGDIR/$LOGFILE
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
                    stageCode $CODEDIR
                    break;;
            $TACODEDIR)
                    echo "[$TIME] INFO: User selected $CODEDIR as the staging directory" >> $LOGDIR/$LOGFILE
                    echo "Using $TACODEDIR as staging directory."
                    stageCode $TACODEDIR
                    break;;
            Custom)
                   validTmp=0
                   while [ $validTmp -eq 0 ]
                        do
                        echo "Custom: Please enter the full path of your tmp/staging directory where the code will be staged"
                            read -e tmpDir
                        if [ -d $tmpDir ]; then
                                if [ -w $tmpDir ]; then
                                    let validTmp++
                                        echo "[$TIME] INFO: Selected $tmpDir as code drop staging directory" >> $LOGDIR/$LOGFILE
                                        echo "Using $tmpDir as staging directory."
                                elif [ ! -w $tmpDir ]; then
                                        echo "Error: No write permissions to $tmpDir, try again"
                                fi
                        elif [ ! -d $tmpDir ]; then
                                        echo "ERROR: $tmpDir is not a valid directory"
                        fi
                        done
                    stageCode $tmpDir
                    break;;
            Quit)
                    echo "Good Bye Cruel World."
                    echo "[$TIME] INFO: Aborted upon user request." >> $LOGDIR/$LOGFILE
                    exit 1;;
               *)
                    echo "ERROR: Invalid selection, try again.";;
   esac
done







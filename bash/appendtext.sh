#!/bin/bash

#Quick and dirty script to append text to the end of each line of the file
RE='^[0-9]+$'
TEXTTOAPPEND=$1
FILETOAPPEND=$2
echo "Hello, you use the script like this.. ./appendtext.sh <TextToAppend> <File>"
if [ -z $TEXTTOAPPEND ]; then
	echo "what are you gonna append???"
	exit 1
fi
if [ -z $FILETOAPPEND ]; then
	echo "what file are you gonna append to???"
	exit 1
elif  [ ! -f $FILETOAPPEND ]; then
	echo "That file you specified, $FILETOAPPEND doesnt exist"
	exit 1
fi

#for hostnum in {300..500}; do
#	sed -i "s|$|    $1     oel-test-$hostnum    oel-test-$hostnum|" $FILETOAPPEND
#done
sed -i "s|$|    $1|" $FILETOAPPEND

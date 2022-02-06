#!/bin/bash

TIME=`date "+%Y-%m-%d-%H-%M-%S"`
VMSTARTCOUNT=300
DHCPDFILE=/root/dhcpd.conf.generated
RE='^[0-9]+$'
OVIRTFILE=/tmp/OVIRTFILE.$TIME
BASE_IP=192.16.
NET_IP=3
HOST=1

#Tells us how to use the thing
function usage {
cat << EOF
Usage: ovirthosts.sh -n, -h, -c  a script to create a file that can be run in the ovirt-shell
   -n   Specify how many hosts you want. Must be an integer!
   -c   Specify the cluster
   -h   displays basic help

Example: ./ovirthosts.sh -n 40 -c KC81-Ovirt-Cluster
EOF
exit 0
}
#This function will generate a mac address, and then make sure that it's unique before continuing on.
function validateMacSpace {
VALIDMAC=0
	until [ $VALIDMAC -eq 1 ]; do
	MACADDRESS=`printf '02:00:00:00:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))`
		grep $MACADDRESS $DHCPDFILE
			if [ $? -eq 0 ]; then
				# Generate a log entry if a duplicate mac was detected to syslog
				logger "duplicate mac detected, regenerating"
			else
				if [ -e /etc/dhcp/dhcpd.conf ]; then
					grep $MACADDRESS /etc/dhcp/dhcpd.conf 
						if [ $? -eq 0 ]; then
							$LOG "duplicate mac detected, regenerating"
						else
			 				VALIDMAC=1
						fi
				else
					VALIDMAC=1
				fi
			fi
	done
	addVm $MACADDRESS
}
# Add the VM and update the nic with this function
function addVm {
echo "add vm --name OEL-TEST-$c --template-name OEL-Base --cluster-name $CLUSTER" >> $OVIRTFILE
echo "update nic nic1 --parent-vm-name OEL-TEST-$c --mac-address $1" >> $OVIRTFILE
insertdhcpEntry $1
}
function insertdhcpEntry {
echo "host OEL-TEST-$c.foobartech.com {" >> $DHCPDFILE
echo "hardware ethernet $1;" >> $DHCPDFILE
echo "fixed-address is $BASE_IP$NET_IP.$HOST" >> $DHCPDFILE
echo "option host-name OEL-TEST-$c.foobartech.com;" >> $DHCPDFILE
echo "}" >> $DHCPDFILE
	if [ $HOST -eq 254 ]; then
		HOST=1
		echo "now the value of HOST is $HOST"
		((NET_IP=NET_IP+1))
	fi
	((HOST=HOST+1))
}

#Delete the existing dhcpd file if it exists so we can start clean
if [ -e $DHCPDFILE ]; then
	rm -f $DHCPDFILE
	touch $DHCPDFILE
else
	touch $DHCPDFILE
fi
#Get user input and do some error checking to make sure it really is an int
if [ "$#" -eq 4 ]; then
        while getopts "c:n:h" opt; do
                case $opt in
                n )
                        if [ -z $OPTARG ]; then
                                echo "Number of hosts you want is required!"
                                usage
                        else
				if ! [[ $OPTARG =~ $RE ]]; then
					echo "That's not a number, try again!"
					exit 1
				else		
					if [ $OPTARG -gt 4000 ]; then
						echo "That's too many hosts, need a number less than 4000"
						exit 1
					else
                                		NUM_HOSTS=$OPTARG
					fi
				fi
                        fi
		;;
		c )
			if [ -z $OPTARG ]; then
				echo "Cluster name is required!"
				usage
			else
				CLUSTER=$OPTARG
			fi
                ;;
                h )  usage; exit
                ;;
                \?)  usage ;;
                esac
        done
else
	usage
fi
#Loop over the NUM_HOSTS variable and make VMs, starting from 300. Then we pass the variable $c which contains the host number into the validateMacSpace function
TOTALHOSTS=$((NUM_HOSTS + VMSTARTCOUNT))
for (( c=$VMSTARTCOUNT; c<=$TOTALHOSTS; c++ )); do
	validateMacSpace $c
done
echo "Generated $NUM_HOSTS mac addresses and ip addresses. They are in file $OVIRTFILE"
echo "Generated corresponding hosts file for dhcpd in $DHCPDFILE"

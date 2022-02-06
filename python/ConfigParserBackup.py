import paramiko, datetime, gzip, smtplib, ConfigParser
from sys import exit
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

#Read that config file yo
config = ConfigParser.ConfigParser()
config.read("config.ini")

#Specify some hardcoded parameters here, convert to ConfigParser later.
HOST_IP = config.get('TARGET_HOST', 'SSH_IP')
HOST_PORT = config.getint('TARGET_HOST', 'SSH_PORT')
HOST_USER = config.get('TARGET_HOST', 'SSH_USERNAME')
HOST_PASSWORD = config.get('TARGET_HOST', 'SSH_PASSWORD')
COMMAND = config.get('TARGET_HOST', 'COMMAND')
LOG_COMPRESSION = config.getboolean('FILE_OPTIONS', 'LOG_COMPRESSION')
OPEN_RELAY = config.getboolean('EMAIL_OPTIONS', 'OPEN_RELAY')
ADMIN_EMAIL = config.get('EMAIL_OPTIONS', 'ADMIN_EMAIL')
SEND_EMAIL = config.getboolean('EMAIL_OPTIONS', 'SEND_EMAIL')
SENDER = config.get('EMAIL_OPTIONS', 'SENDER')
GMAIL_USER = config.get('EMAIL_OPTIONS', 'GMAIL_USER')
GMAIL_PWD = config.get('EMAIL_OPTIONS', 'GMAIL_PWD')


#This function we can call to add a timestamp to any file object we create
def timeStamped(fname, fmt='%m-%d-%Y-%H-%M-%S_{fname}'):
    return datetime.datetime.now().strftime(fmt).format(fname=fname)

def sendEmail(messageSubject, body):
    if OPEN_RELAY:
        try:
            smtpObj = smtplib.SMTP('192.168.1.52')
            msg = MIMEMultipart()
            msg['From'] = SENDER
            msg['To'] = ADMIN_EMAIL
            text = msg.as_string()
            smtpObj.sendmail(SENDER, ADMIN_EMAIL, text)
            smtpObj.close()
        except Exception as e:
            print "We have run into an issue and could not send the e-mail because of the following error:" + str(e)
            raise
    else:
        try:
            msg = MIMEMultipart()
            msg['From'] = SENDER
            msg['To'] = ADMIN_EMAIL
            msg['Subject'] = messageSubject
            msg.attach(MIMEText(body, 'plain'))
            smtpObj = smtplib.SMTP('smtp.gmail.com', 587)
            smtpObj.starttls()
            smtpObj.login(GMAIL_USER, GMAIL_PWD)
            text = msg.as_string()
            smtpObj.sendmail(SENDER, ADMIN_EMAIL, text)
            smtpObj.close()
            print "Sent the e-mail"
        except Exception as e:
            print "An error occured, didn't send e-mail"
            print "The exact exception was: " + str(e)

#Create the SSH client object
ssh = paramiko.SSHClient()
#The missing host key parameter is set here so we can automatically add it
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

#Try to establish a connection to the SSH server, if not then e-mail the admins
try:
    #print "HOST IP is %s, HOST_PORT is %s, HOST_PASSWORD is %s, HOST_USER is %s" %(HOST_IP,HOST_PORT,HOST_PASSWORD,HOST_USER)
    ssh.connect(HOST_IP, username=HOST_USER, password=HOST_PASSWORD, port=HOST_PORT)
    #ssh.connect(config.get('TARGET_HOST', 'SSH_IP'), username=HOST_USER, password=HOST_PASSWORD, port=HOST_PORT)
except Exception, error:
    print error
    if SEND_EMAIL:
        print "Sending an e-mail to %s that we had an issue with ssh connection" %ADMIN_EMAIL
        sendEmail("Error: Connection Failed", "Backup Failure, could not establish SSH connection")
        exit(1)
    else:
        print "Not sending an e-mail that we had an issue but still killing script"
        exit(1)

#Packing variables here with whatver we get from the command we ran
stdin, stdout, stderr = ssh.exec_command(COMMAND)

output = stdout.read()

'''If Log Compression is set to true, then we create gz files and if not we create raw files
If an error is found, then e-mail the admins'''
try:
    if LOG_COMPRESSION:
        with gzip.open(timeStamped('cmd_output.txt.gz'), 'w') as f:
            print "Compressing the log file...."
            f.write(output)
            sendEmail("Successfully generated gzipped log file", "Log file generated with compression!")
    else:
        with open(timeStamped('cmd_output.txt'), 'w') as f:
            print "Log Compression is disabled so I'm generating a raw file"
            f.write(output)
            sendEmail("Successfully generated log file without compression", "Log File Generated Without Compression!")
except:
    sendEmail("ERROR with DDN Backup!", "Could not compress log file!")
    print "There was an error with writing to the file, sending e-mail to %s" %ADMIN_EMAIL

#Tear down the SSH connection when we finish
if ssh:
    ssh.close()
    print "We closed the SSH connection bro"

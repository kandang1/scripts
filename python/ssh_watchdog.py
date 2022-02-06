#!/usr/bin/python
import time, subprocess, re, smtplib
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

class MyHandler(PatternMatchingEventHandler):
	count = 0
	fieldlist = ['0']
	namelist = ['Dan']
	def on_modified(self, event):
		tail = subprocess.Popen(["tail", "-2", "/var/log/secure"], stdout=subprocess.PIPE)
		p = tail.stdout.read()
		search_obj=re.search(r'Failed password for (\w+)', p)
		search_obj2=re.search(r'Failed password for invalid user (\w+)', p)
		if search_obj and not search_obj2:
			username = re.search(r"\w+$", search_obj.group())
			cmd = "pam_tally2 -u %s" % username.group()
			pamtally = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)
			text, err= pamtally.communicate()
			if pamtally.returncode == 0:
				lines = text.split('\n')
				fields = lines[1].split()
				self.count = self.count + 1
				fieldint = int(fields[1])
				self.fieldlist.append(fieldint)
				self.namelist.append(username.group())
				if fieldint >= 5:
					self.sendemail("LOCKED user ")
				else:
					self.sendemail("user ")
			else:
				print 'Error: %s' % err
		elif search_obj2 and search_obj: 
			username = re.search(r"\w+$", search_obj2.group())
			self.sendemail("invalid", username.group())
		else:
			pass
	def sendemail(self, str, username='John Doe'):
		server = smtplib.SMTP('192.17.1.52')
		fromaddr = "SSH-Watchdog@Bastion"
		toaddr = "tech@foobartech.com"
		msg = MIMEMultipart()
		msg['From'] = fromaddr
		msg['To'] = toaddr
		if self.fieldlist[self.count] == self.fieldlist[self.count - 1] and self.namelist[self.count] == self.namelist[self.count - 1] and str != 'invalid':
			pass
		elif str == 'invalid':
			msg['Subject'] = "Failed SSH Attempt to BASTION for non-existent user " + username
			text = msg.as_string()
                        server.sendmail(fromaddr, toaddr, text)
                        server.quit()
		else:
			msg['Subject'] = "Failed SSH Attempt to BASTION for " + str + self.namelist[self.count]
			text = msg.as_string()
			server.sendmail(fromaddr, toaddr, text)
                        server.quit()

if __name__ == "__main__":
    event_handler = MyHandler(patterns=['/var/log/secure'], ignore_patterns=None, ignore_directories=True, case_sensitive=True)
    observer = Observer()
    observer.schedule(event_handler, path='/var/log/', recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

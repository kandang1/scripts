#!/usr/bin/env python
import re

f = open('/root/dhcpclients')
text = f.read()
#m = re.findall(r'((?:[0-9a-f]{2}:){5}[0-9a-f]{2})', text, re.IGNORECASE) (For mac addresses)
m = re.findall(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}[^0-9]', text)
for i in m:
	print i.rstrip(';')

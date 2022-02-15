#!/usr/bin/python3
import os

d = "/Users/test/Downloads/"

for root, dirs, files in os.walk(d, topdown=False):
    for name in files:
        print(os.path.join(root, name))
    print (root)
    print (dirs)
    print (files)

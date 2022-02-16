#!/usr/bin/python3
MOD_LIST="Puppetfile"
software_name="AcmeDS"
GIT_REPO="git@github.com:kandang1/test.git"

environment = input("Enter the environment name and version eg: AcmeDS_1_0_0 ")

puppet_menu_option = {
    1: 'PuppetDev',
    2: 'PuppetProduction',
}

def askPuppetServer(f):
    print(f"yo i'm in this function with {f}")
    for key in puppet_menu_option.keys():
        print (key, '--', puppet_menu_option[key])

while(True):
    if software_name in environment:
        askPuppetServer(environment)
        break
    else:
        print("This isn't an AcmeDS software baseline. Try again.")

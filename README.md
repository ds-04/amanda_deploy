# amanda_deploy
Ansible roles to deploy Amanda backup, server and clients


**THIS ROLE SHOULD BE USED AT OWN RISK, AUTHOR HAS DONE TESTING WHILST IN DEVELOPMENT**<br>

Developed/tested on:
- Centos 7.9 and Debian 11 hosts
- Focus on server developement has been Debian and with vtapes
- For enhancments and TODOs see repo's issues
- Pull requests and enhancements are welcome

# TLDR; What this role will do:

- deploy amanda backup server **with SSH auth not bsdtcp**
- deploy amanda clients **with SSH auth not bsdtcp**
- copy ssh key from server to client
- install known hosts entries on server for clients
- work with both RHEL/Centos and Debian OS
- **it will disable xinetd** and avoid installing it where possible

# TLDR; What this role won't do:

- implement all of your security for your backup system - you are responsable for that
- bsdtcp auth or other non SSH auth methods

# TLDR; Amanda backup, tapes, vtapes

- physical [LTO] tapes are very much alive, lots of sites use them for active-archive, backup, vaulting etc.
- vtapes are virtual tapes (a tape is a file) on a filesystem that Amanda can work with
- Amanda backup has been around a long time, you can read about here https://en.wikipedia.org/wiki/Amanda_(software)
- Amanda's documentation is somewhat fragmented and in various states, a motivation of this role was to aid understanding and simplify deployment


# Background

This repo is comprised of multiple playbooks and roles.







# Inventory

This role relies upon the existence of two inventory groups, eithin in your main inventory or one you call when running the playbooks/tasks.
- amanda_server
- amanda_client


# Overrirding config


# Running tasks




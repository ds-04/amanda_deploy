## NOTE Documentation in progress before upload/release of code

# amanda_deploy
Ansible playbooks and roles to deploy Amanda backup server and clients

The motivation is to be able to reproduce an Amanda backup setup quickly, deploying both clients and server with idempotence.

**THIS CONTENT SHOULD BE USED AT OWN RISK:**<br><br>
**- AUTHOR HAS DONE TESTING WHILST IN DEVELOPMENT**<br>
**- YOUR SECURITY IN PRODUCTION IS YOUR RESPONSABILITY!**<br><br>

Developed/tested on:
- Centos 7.9 and Debian 11 hosts
- Focus on server developement has been Debian and with vtapes<br><br>
Future:<br>
- For enhancments and TODOs see repo's issues
- Pull requests and enhancements are welcome

# TLDR; What this repository's playbooks/roles will do:

- work with both RHEL/Centos (>7) and Debian OS (>10)
- install RPM/Deb for Amanda backup v3.5.1 (version defined in defaults)
- deploy Amanda backup server **with SSH auth not bsdtcp**
- deploy Amanda clients **with SSH auth not bsdtcp**
- generate (if needed) and copy ssh pub key from server to client for **SSH auth**
- install known hosts entries on server for clients (you can change the options for this, sensible defaults are provided) for **SSH auth**
- it will setup an ssh authentication route/method from the client back to the server - this is needed for amrecover invocation on the client itself (for **SSH auth**)
- **it will disable xinetd for now as bsdtcp auth isn't being used here** and avoid installing it where possible
- it will deploy a test vtape setup should you choose to do so

# TLDR; What this repository's playbooks/roles won't do:

- edit any firewall settings
- implement all of your security for your backup system - operators are responsable for their own security
- bsdtcp auth or other non SSH auth methods - bsdtcp auth could be implemented if a pull request is submitted etc.
- dormant bsdtcp systemd files are included though
- edit/setup any cron jobs for backup invocation
- run Amcheck, though a dormant task is included
- deploy your production server config or physical tape config - see section below

# TLDR; Amanda backup, tapes, vtapes

- physical [LTO] tapes are very much alive, lots of sites use them for active-archive, backup, vaulting etc.
- vtapes are virtual tapes (a tape is a file) on a filesystem that Amanda can work with
- Amanda backup has been around a long time, you can read about here https://en.wikipedia.org/wiki/Amanda_(software)
- Amanda's documentation is somewhat fragmented and in various states, a motivation of this role was to aid understanding and simplify deployment


# Background

This repo is comprised of multiple playbooks and roles.

Playbooks:

- amanda_client.yml (calls its namesake role to: install packages for client, disable xinetd, setup local user security/ssh, copy amanda-security.conf)
- amanda_copy_keys.yml (playbook; append public key from server to clients (server is also a client by default), use ssh-keyscan to add host-keys of clients to server)
- amanda_server_cfg.yml (calls its namesake role to: create/copy/update configuration files, directories and create vtapes for a test vtape environ)
- amanda_server.yml (calls its namesake role to: install server packages<sup>1</sup>, disable xinetd, setup server ssh user, setup server ssh user keys, copy amanda-security.conf<sup>2</sup>)

<sup>1</sup> Debian is direct from repo, RHEL/Centos via Zmanda RPM url/download<br>
<sup>2</sup> it is assumed the server will also be a client of itself, this can be disabled/overriden if desired


# Inventory

This role relies primarily upon the existence of two inventory groups, within your main inventory or an inventory file you call when running the playbooks/tasks. A third group is recommended to enable restore (amrecover) from the client.
- amanda_server
- amanda_client
- amanda_client_restore

A mimimal setup to simply test would be to have the server and client on the same system:
```
[amanda_server]
myhost.xx.yy

[amanda_client]
myhost.xx.yy

#make all clients restore clients
[amanda_client_restore:children]
amanda_client
```
# Amanda Debian and RHEL/Centos differences

- On RHEL/Centos the server RPM also provides the client functionality
- Users and groups provided by the packages are slightly different
- This code accounts for such differences

# Structure as seen from playbook dir

It is advised that you clone to another location or use a git submodule within your ansible configuration. The structure of what is provided by this repository is seen below. Note the relative symlinks for defaults and certain task yml files. This is to avoid duplication where a client role task can be performed by something which is the same in a server role or vice versa.

```
amanda_client_restore.yml
amanda_client.yml
amanda_copy_keys.yml
amanda_server_cfg.yml
amanda_server.yml

roles/amanda_client
├── defaults
│   └── main.yml -> ../../amanda_server/defaults/main.yml
├── tasks
│   ├── client_security.yml
│   ├── client_sshd_user.yml -> ../../amanda_server/tasks/server_sshd_user.yml
│   ├── client.yml
│   ├── disable_xinetd.yml -> ../../amanda_server/tasks/disable_xinetd.yml
│   └── main.yml
├── templates
│   ├── amanda-security.conf.j2
│   └── systemd -> ../../amanda_server/templates/systemd ** link to DORMANT templates, avoid duplication **
└── vars
    └── main.yml -> ../../amanda_server/vars/main.yml ** Provided to link client to server vars, which operator will override defaults with **
roles/amanda_server
├── defaults
│   └── main.yml
├── tasks
│   ├── client_security.yml -> ../../amanda_client/tasks/client_security.yml
│   ├── debian_server.yml
│   ├── disable_xinetd.yml
│   ├── main.yml
│   ├── rhel_centos_server.yml
│   ├── server_sshd_user.yml
│   ├── server_ssh_keys.yml
│   └── systemd.yml ** DORMANT **
└── templates
    ├── amanda-security.conf.j2 -> ../../amanda_client/templates/amanda-security.conf.j2
    └── systemd ** DORMANT **
        ├── amanda@.service
        └── amanda.socket
roles/amanda_server_cfg
├── defaults
│   └── main.yml
├── tasks
│   ├── amcheck.yml ** DORMANT **
│   ├── main.yml
│   └── server_config.yml
├── templates
│   ├── test_vtape_confs
│   │   ├── test_vtape_amanda.conf.j2
│   │   ├── test_vtape_dumps.conf.j2
│   │   ├── test_vtape_global.conf.j2
│   │   └── test_vtape_holding_disk.conf.j2
│   └── test_vtape_disklist.j2
└── vars

14 directories, 29 files

```



# Overriding config

You should use vars/main.yml within the relevant roles. E.g. server configuration role.

# Getting started and running playbooks/tasks

Firstly, decide if you are deploying the test vtape setup. If so, you probably want to override some settings (e.g. email) with use of the file *amanda_server_cfg/vars/main.yml* which you will create. Also pay attention to the holding directory defined. Then...

The expected order (on first setup) is:

- ```ansible-playbook amanda_server.yml```
- ```ansible-playbook amanda_client.yml```
- ```ansible-playbook amanda_copy_keys.yml``` (N.B. you will also need to run this, to enable the server to access itself as a client)
- ```ansible-playbook amanda_server_cfg.yml``` (remember by default the test vtape config won't be deployed, you need to enable that if/when you want it)
- ```ansible-playbook amanda_client_restore.yml```<br><br>
Then<br>
- ***your amanda_production_server_cfg.yml (you need to create this playbook and corresponding role)***

Specific/certain tasks can be run with tags. Please look inside the roles to identify these tags.

## Alternatively, run the provided master playbook:

You can run everything in one go like this:
```ansible-playbook amanda_master_playbook.yml -e deploy_test_vtape_cfg=True```          (N.B. this is enabling deployment of the test vtape config too)<br><br>

Then<br>
- ***your amanda_production_server_cfg.yml***

# Deploying the test/example vtape configuration

To avoid mishaps by default test/example vtape config is not set to be deployed (and to provide certainly), if you want to deploy the example test vtape config do:

```ansible-playbook amanda_server_cfg.yml -e deploy_test_vtape_cfg=True```

The test vtape config will deploy 9 vtapes of 100 megabytes each - as defined in the defaults file in *amanda_server_cfg/defaults/main.yml*.

# Running in a production environment or using Physical tapes

It is expected that you can create a role named amanda_server_prod_cfg (or similar) using what is here as a basis. That role could simply template out the configuration files, up to you.

# FAQ

*Could other auth methods be provided e.g. bsdtcp auth?*

Yes contributions are welcome to develope/test/integrate bsdtcp auth into this ansible code.

*How do I run commands as the Amanda user?*

That's up to you, but you can switch to it or use ```sudo -u amanda_user COMMAND```

*Test vtape configuration - How do I do a test restore using the local auth, of the */etc* disk list entry example (where the server is a client too)?*

- As the root user (on the server): ```amrecover DailySet1 -o auth=local -s localhost```
- then, sethost, check dles, set a dle... from there you should manage to restore (can use *help* command or see https://wiki.zmanda.com/index.php/How_To:Recover_Data)

```
root@MYHOST~# amrecover DailySet1 -o auth=local -s localhost
AMRECOVER Version 3.5.1. Contacting server on localhost ...
220 MYHOST AMANDA index server (3.5.1) ready.
Setting restore date to today (2021-09-10)
200 Working date set to 2021-09-10.
200 Config set to DailySet1.
200 Dump host set to MYHOST.
Use the setdisk command to choose dump disk to recover
amrecover> sethost localhost
200 Dump host set to localhost.
amrecover> listdisk
200- List of disk for host localhost
201- /etc/
200 List of disk for host localhost
amrecover> setdisk /etc/
200 Disk set to /etc/.
```



# Future work

- The server configuration implementation could be improved to create multiple vtape testing configurations on the same server.
- Probably other stuff too...

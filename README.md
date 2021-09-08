# amanda_deploy
Ansible playbooks and roles to deploy Amanda backup server and clients

The motivation is to be able to reproduce an Amanda backup setup quickly and deploy both clients and server quickly with idempotence.

**THIS CONTENT SHOULD BE USED AT OWN RISK, AUTHOR HAS DONE TESTING WHILST IN DEVELOPMENT**<br>

Developed/tested on:
- Centos 7.9 and Debian 11 hosts
- Focus on server developement has been Debian and with vtapes<br><br>
Future:<br>
- For enhancments and TODOs see repo's issues
- Pull requests and enhancements are welcome

# TLDR; What this repository's playbooks/roles will do:

- install RPM/Deb for Amanda backup v3.5.1 (version defined in defaults)
- deploy Amanda backup server **with SSH auth not bsdtcp**
- deploy Amanda clients **with SSH auth not bsdtcp**
- generate (if needed) and copy ssh pub key from server to client
- install known hosts entries on server for clients
- work with both RHEL/Centos (>7) and Debian OS (>10)
- **it will disable xinetd** and avoid installing it where possible
- it will deploy a test vtape setup should you choose to do so

# TLDR; What this repository's playbooks/roles won't do:

- edit any firewall settings
- implement all of your security for your backup system - operators are responsable for their own security
- bsdtcp auth or other non SSH auth methods 
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
- amanda_copy_keys.yml (playbook; append public key from server to clients, use ssh-keyscan to add host-keys of clients to server)
- amanda_server_cfg.yml (calls its namesake role to: create/copy/update configuration files, directories and create vtapes for a test vtape environ)
- amanda_server.yml (calls its namesake role to: install server packages<sup>1</sup>, disable xinetd, setup server ssh user, setup server ssh user keys, copy amanda-security.conf<sup>2</sup>)

<sup>1</sup> Debian is direct from repo, RHEL/Centos via Zmanda RPM url/download<br>
<sup>2</sup> it is assumed the server will also be a client of itself


# Inventory

This role relies upon the existence of two inventory groups, eithin in your main inventory or one you call when running the playbooks/tasks.
- amanda_server
- amanda_client

# Structure as seen from playbook dir

It is advised that you clone to another location or use a git submodule within your ansible configuration. The structure of what is provided by this repository is seen below. Note the relative symlinks for defaults and certain task yml files. This is to avoid duplication where a client role task can be performed by something which is the same in a server role or vice versa.

```
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
    └── systemd  ** DORMANT **
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
```



# Overriding config

You should use vars/main.yml within the relevant roles. E.g. server configuration role.

# Running tasks

Certain tasks can be run with tags. Please look inside the roles to identify these tags.

# Deploying the test/example vtape configuration



# Running in a production environment or using Physical tapes

It is expected that you can create a role named amanda_server_prod_cfg (or similar) using what is here as a basis. That role could simply template out the configuration files, up to you.

# Future work

- The server configuration implementation could be improved to create multiple vtape testing configurations on the same server.
- Probably other stuff too...

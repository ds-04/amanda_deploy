#!/bin/bash
#D Simpson 2023, ds-04
echo "Select Vagrant type for amanda_deploy"
echo "---------------------------------------"
PS3="\"multi\" (server+client(s)) OR \"single\" (server only)"

select Vagrantfile_link in multi single quit; do
case $Vagrantfile_link in
    multi)
      ln -fs Vagrantfile_multi Vagrantfile;
      ln -fs hosts.ini_multi hosts.ini;
      break
      ;;
    single)
      ln -fs Vagrantfile_single Vagrantfile;
      ln -fs hosts.ini_single hosts.ini;
      break
      ;;
    quit)
      echo "Selected option: quit, exiting now..."
      exit 1
      ;;
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done
echo "Selected Vagrantfile option: $Vagrantfile_link"

vagrant up;
vagrant ssh-config;
vagrant_ips=`egrep -o2 "ansible_host=(.*)" hosts.ini | grep -v "\-\-" | cut -d "=" -f 2`
#vagrant_hosts=
for ip in ${vagrant_ips}
do
    ssh-keygen -R ${ip};
    ssh-keyscan ${ip} >> ~/.ssh/known_hosts
done
vagrant global-status;
echo "-------------------------------------"
echo "Setup is done!..."
echo "Ansible playbook that was run:"
echo "ansible-playbook amanda_master_playbook.yml -e deploy_test_vtape_cfg=true"
echo "-------------------------------------"
echo "as the backup (backup/amandabackup) user test with: amcheck DailySet1, amdump DailySet1 etc..."

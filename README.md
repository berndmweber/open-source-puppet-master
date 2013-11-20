open-source-puppet-master
=========================

Open Source configuration for a puppet-master

For more information check this file -> [Readme.md](https://github.com/berndmweber/open-source-puppet-master/blob/master/modules/puppet/README.md)

Travis Build Status
-------------------
[![Build Status](https://travis-ci.org/berndmweber/open-source-puppet-master.png?branch=master)](https://travis-ci.org/berndmweber/open-source-puppet-master)


Steps to use this repo
----------------------

* Make sure you give your server a meaningful name before proceeding. This name will be used to configure the certificates for the Puppet Master. Later changes will result in all kinds of certification reconfigurations (basically hell...).
* Clone or better fork this repo so you can make changes to it.
 * Modify the repository path in [os_pm_instantiate.sh](https://github.com/berndmweber/open-source-puppet-master/blob/master/bootstrap/os_pm_instantiate.sh) and/or [ec2_os_pm_instantiate.sh](https://github.com/berndmweber/open-source-puppet-master/blob/master/bootstrap/ec2_os_pm_instantiate.sh)
 * If you use this on EC2 follow the steps in the [following chapter](https://github.com/berndmweber/open-source-puppet-master#ec2-support) ccreating a multi-mime-type configuration
 * Add the script or multi-mime-type file to the user-data section on your new EC2 instance or run the script from the commandline
* Once a basic Puppet Master is installed you have several options
 * Leave as is. You'll need to still add or remove the hiera-gpg support described [further down](https://github.com/berndmweber/open-source-puppet-master#gpg-password-usage)
 * Run the puppet agent to install a full master with dashboard setup
* If you install a full featured Puppet Master, after the initial script finishes it is advisible to disable the Puppet agent before proceeding:<br />
` ?> sudo service puppet stop`
* Now follow the guidlines below for the [gpg setup](https://github.com/berndmweber/open-source-puppet-master#gpg-password-usage). The `/etc/puppet/environments/production/hieradata/passwords.yaml` should be pre-populated. Change the passwords to safe passwords of you own choice. E.g. use http://strongpasswordgenerator.com/
* Once complete just run ` ?> sudo puppet agent -t` to finish the setup. After that finishes you should be able to log into the dashboard via:<br />
`https://<your_pm_instance_ip_or_dns>:3000` use `dashboard_admin` as user and `jona1234` as password. This can be changed via:<br />
`htpasswd -sb /var/lib/puppet-dashboard/config/htpasswords dashboard_admin <your_new_password>`

EC2 support
-----------

* Use [ec2_os_pm_instantiate.sh](https://github.com/berndmweber/open-source-puppet-master/blob/master/bootstrap/ec2_os_pm_instantiate.sh). It has a smaller footprint in order to fit into the 16384 Byte limit of the user data section.
* Modify [cloud-init.cfg]([ec2_os_pm_instantiate.sh](https://github.com/berndmweber/open-source-puppet-master/blob/master/bootstrap/cloud-init.cfg) to fit your setup. You can also leave this out if you just want to use the EC2 automatically assigned names.
* If you want to use cloud-init use a Ubuntu machine with the 'cloud-init' package installed:<br />
` ?> apt-get install cloud-init`
 * Use `write-mime-multipart` to generate a user-data file including both the configuration and the pm instantiation script:<br />
` ?> wrtie-mime-part --output=combined-userdata.txt cloud-init.cfg:text/cloud-config ec2_os_pm_instantiate.sh:text/x-shellscript`
* When creating an EC2 instance give this `combined-userdata.txt`-file to the user-data section

GPG password usage
------------------

This system is pre-configured to use GPG encrypted yaml files to protect passwords.
The following describes the process from scratch to be able to use this feature:

* Generate a GPG key:<br />
  ` $> sudo gpg --homedir /var/lib/puppet/.gnupg --gen-key`<br />
  Do NOT provide a passphrase otherwise hiera-gpg will be unable to decrypt the files.
  Otherwise follow the instructions and note the email address you provide for later, e.g. pm@testsystem.com.
  If you need to create additional entropy, just run `ls -R /`, or a grep command a couple times.
* Make sure the .gnupg directory is owned by Puppet:
  ```
  $> chown -R puppet:puppet /var/lib/puppet/.gnupg
  ```
* Import the public key to your puppet directory: <br />
  ```
  $> sudo gpg --homedir=/etc/puppet/gpgdata --import /var/lib/puppet/.gnupg/pubring.gpg
  ```
* Add data to password.yaml. E.g.<br />
  ```
  ---
  mysql::server::root_passwd: jona123
  
  ```
* Encrypt the yaml file:<br />
  ```
  $> sudo gpg --trust-model=always --homedir=/etc/puppet/gpgdata --encrypt -o /etc/puppet/environments/production/hieradata/gpgdata/passwords.gpg \
     -r pm@testsystem.com /etc/puppet/environments/production/hieradata/passwords.yaml
  ```
  It's important to mention that the encrypted file cannot be put into the hieradata directory
* Delete or move the plain text passwords.yaml file to a secure (root-only accessible) location
* You can test operation with:<br />
  ` $> sudo hiera -d -c hiera.yaml mysql::server::root_passwd environment=production`

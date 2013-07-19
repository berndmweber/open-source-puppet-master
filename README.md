open-source-puppet-master
=========================

Open Source configuration for a puppet-master

For more information check this file -> [Readme.md](https://github.com/berndmweber/open-source-puppet-master/blob/master/modules/puppet/README.md)

Travis Build Status
-------------------
[![Build Status](https://travis-ci.org/berndmweber/open-source-puppet-master.png?branch=master)](https://travis-ci.org/berndmweber/open-source-puppet-master)

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
  $> sudo gpg --homedir=/etc/puppet/gpgdata --import /root/.gnupg/pubring.gpg
  ```
* Add data to password.yaml. E.g.<br />
  ```
  ---
  mysql:server:root_passwd: jona123
  
  ```
* Encrypt the yaml file:<br />
  ```
  $> sudo gpg --trust-model=always --homedir=/etc/puppet/gpgdata --encrypt -o /etc/puppet/environments/production/hieradata/gpgdata/passwords.gpg \
     -r pm@testsystem.com /etc/puppet/environments/production/hieradata/passwords.yaml
  ```
  It's important to mention that the encrypted file cannot be put into the hieradata directory
* Delete or move the plain text passwords.yaml file to a secure (root-only accessible) location
* You can test operation with:<br />
  ` $> sudo hiera -d -c hiera.yaml mysql:server:root_passwd` environment=production

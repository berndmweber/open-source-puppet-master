#!/bin/bash
# This is for Ubuntu 12.04 LTS - Precise Pangolin only
#

# Escape code
esc=`echo -en "\033"`

# Set colors
cc_red="${esc}[0;31m"
cc_green="${esc}[0;32m"
cc_yellow="${esc}[0;33m"
cc_blue="${esc}[0;34m"
cc_normal=`echo -en "${esc}[m\017"`

# Configure Puppetlabs repo
echo -e " ${cc_blue}Downloading Puppetlabs repository information${cc_normal}"
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
echo " ${cc_green}Done.${cc_normal}"
echo

# Update the repository information
echo " ${cc_blue}Updaing APT with new information${cc_normal}"
apt-get update
echo " ${cc_green}Done.${cc_normal}"
echo

# Install a basic puppet master configuration
echo " ${cc_blue}Installing ${cc_yellow}puppet-common${cc_blue} and ${cc_yellow}git-core${cc_normal}"
apt-get install -y puppet-common git-core
echo " ${cc_green}Done.${cc_normal}"
echo

# Grab the GitHub puppet configuration
echo " ${cc_blue}Downloading puppet master configuration from ${cc_yellow}GitHub${cc_blue} for final provisioning.${cc_normal}"
cd /root
git clone https://github.com/bernd-copperfroghosting/open-source-puppet-master.git puppet
echo " ${cc_green}Done.${cc_normal}"
echo

# Install Puppet master through puppet base installation
echo " ${cc_blue}Install Puppet master through puppet base installation.${cc_normal}"
puppet apply --modulepath=/root/puppet/modules -e "include puppet"
echo " ${cc_green}Done.${cc_normal}"
echo

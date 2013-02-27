# == Class: puppet::master
#
# This is the Puppet Master configuration class. It configures a puppet master
# from scratch. It relies on puppet::params.
#
# === Parameters
# [*type*]
#   Define the type of Puppet Master installation to be performed.
#   Possible values include:
#   * 'self'   : Just a plain puppet master installation with internal WEBrick
#   * 'apache' : Install a puppet master using the Passenger module and Apache
#
# === Variables
#
# === Examples
#
#  class { puppet::master : type => 'apache' }
#
# === Authors
#
# Bernd Weber <bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 Copper Frog LLC.
#
class puppet::master::preinstall {
  augeas { "seed_fqdn_in_hosts_file" :
    context => '/files/etc/hosts',
    lens    => 'Hosts.lns',
    incl    => '/etc/hosts',
    changes => [
      "set 01/ipaddr ${::ipaddress}",
      "set 01/canonical ${::fqdn}",
      "set 01/alias ${::hostname}",
    ],
    onlyif  => "match *[ipaddr=\"${::ipaddress}\"] size == 0",
  }
}

class puppet::master::install (
  $type,
) inherits puppet::install {
  package { $puppet::params::master_packages[$type] :
    ensure  => present,
    require => Class [ "puppet::master::preinstall" ],
  }
}

define puppet::master::install_module (
  $contributer = 'puppetlabs',
  $ignore_dependencies = false,
) {
  if $ignore_dependencies == true {
    $params = "--ignore-dependencies"
  }
  exec { "install-${name}-module" :
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "puppet module install ${contributer}/${name} ${params}",
    creates => "${puppet::params::modulepath['production']}/${name}",
    require => Class [ "puppet::configure" ],
  }
}

class puppet::master::min_configure (
  $type,
) {
  file { "${puppet::params::vardir}/reports" :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => $puppet::params::group,
    recurse => true,
  }
  file { [
    $puppet::params::manifestpath['production'],
    $puppet::params::modulepath['production'],
  ] :
    ensure  => directory,
    owner  => 'root',
    group  => 'root',
    recurse => true,
    require => File [ $puppet::params::etcmaindir ],
  }
  # This will install some basic modules we need
  puppet::master::install_module { $puppet::params::puppet_modules[$type] : }
  file { "${puppet::params::manifestpath['production']}/site.pp" :
    ensure  => file,
    content => template ( "puppet/site.pp.erb" ),
    require => File [ $puppet::params::manifestpath['production'] ],
  }
}

class puppet::master::configure (
  $type,
) inherits puppet::configure {
  # Need this to overwrite the basic setting
  $is_master = true
  File [ $puppet::params::puppetconf ] {
    content => template ( "puppet/puppet.conf.erb" ),
    notify  => Class [ 'puppet::master::service' ],
  }
  file { "${puppet::params::etcmaindir}/fileserver.conf" :
    ensure  => file,
    content => template ( "puppet/fileserver.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
    notify  => Class [ 'puppet::master::service' ],
  }
  file { [
    $puppet::params::environmentspath['base'],
    $puppet::params::environmentspath['testing'],
    $puppet::params::modulepath['testing'],
    $puppet::params::manifestpath['testing'],
    $puppet::params::environmentspath['development'],
    $puppet::params::modulepath['development'],
    $puppet::params::manifestpath['development'],
  ] :
    ensure  => directory,
    require => File [ $puppet::params::etcmaindir ],
  }
  case $type {
    'apache' : {
      class { "puppet::master::apache" :
        require => Class [ 'puppet::master::install' ],
      }
    }
  }
}

class puppet::master::service (
  $type,
) inherits puppet::service {
  case $type {
    'apache' : {
      class { "puppet::master::apache::service" : }
    }
    default : {
      service { $puppet::params::puppetmasterservice[$type] :
        ensure  => running,
        enable  => true,
        require => Class [ 'puppet::master::install' ],
      }
    }
  }
}

class puppet::master (
  $type = 'self',
) inherits puppet::params {
  if $::puppet_type != undef {
    $l_type = $::puppet_type
  } else {
    $l_type = $type
  }

  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" :
    type => $l_type,
  }
  class { "puppet::master::min_configure" :
    type => $l_type,
  }
  class { "puppet::master::configure" :
    type => $l_type,
  }
  class { "puppet::master::service" :
    type => $l_type,
  }
}

class puppet::master::bootstrap (
  $type = 'self',
) inherits puppet::params {
  if $::puppet_type != undef {
    $l_type = $::puppet_type
  } else {
    $l_type = $type
  }

  class { "puppet" : }
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" :
    type => $l_type,
  }
  class { "puppet::master::min_configure" :
    type => $l_type,
  }
}

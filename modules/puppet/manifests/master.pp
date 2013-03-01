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

class puppet::master::install (
  $type,
) inherits puppet::install {
  package { $puppet::params::master_packages[$type] :
    ensure  => present,
  }
}

class puppet::master::configure (
  $type,
) inherits puppet::configure {
  # Need this to overwrite the basic setting
  $is_master = true
  File {
    require => Class [ 'puppet::master::install' ],
  }
  File [ $puppet::params::puppetconf ] {
    content => template ( "puppet/puppet.conf.erb" ),
    notify  => Service [ $puppet::params::masterservice[$type] ],
  }
  file { "${puppet::params::confdir}/fileserver.conf" :
    ensure  => file,
    content => template ( "puppet/fileserver.conf.erb" ),
    require => File [ $puppet::params::confdir ],
    notify  => Service [ $puppet::params::masterservice[$type] ],
  }
  file { $puppet::params::reportsdir :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => $puppet::params::group,
    recurse => true,
  }
  file { $puppet::params::ssldir :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => 'root',
    mode   => 0771,
  }
  file { [
    $puppet::params::manifestpath['production'],
    $puppet::params::modulepath['production'],
  ] :
    ensure  => directory,
    owner  => 'root',
    group  => 'root',
    recurse => true,
    require => File [ $puppet::params::confdir ],
  }
  file { "${puppet::params::manifestpath['production']}/site.pp" :
    ensure  => file,
    content => template ( "puppet/site.pp.erb" ),
    require => File [ $puppet::params::manifestpath['production'] ],
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
    require => File [ $puppet::params::confdir ],
  }
}

class puppet::master::service (
  $type,
) inherits puppet::service {
  if $type == 'self' {
    service { $puppet::params::masterservice[$type] :
      ensure  => running,
      enable  => true,
      require => Class [ 'puppet::master::install' ],
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

  class { "puppet::master::install" :
    type => $l_type,
  }
  class { "puppet::master::configure" :
    type => $l_type,
  }
  class { "puppet::master::service" :
    type => $l_type,
  }
}

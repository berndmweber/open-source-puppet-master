# == Class: puppet::master
#
# This is the Puppet Master wrapper class. It configures a puppet::master
# from scratch. It relies on puppet::params.
#
# === Parameters
#
# [*type*]
#   Define the type of Puppet Master installation to be performed.
#
#   Possible values include:
#   * 'self'   : Just a plain puppet::master installation with internal WEBrick
#   * 'apache' : Install a puppet::master using the passenger module and apache
#
# [*enable_hiera*]
#   Defines whether hiera should be installed and configured.
#
# === Variables
#
# [*puppet_type*]
#   See parameter *type*
#
# [*puppet_enable_hiera*]
#   See parameter *enable_hiera*
#
# === Examples
#
#  class { puppet::master : type => 'apache', enable_hiera => true }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master (
  $type         = 'self',
  $enable_hiera = true,
) inherits puppet::params {
  if $::puppet_type != undef {
    $l_type = $::puppet_type
  } else {
    $l_type = $type
  }
  if $::puppet_enable_hiera != undef {
    if (str2bool($::puppet_enable_hiera) == true) {
      $l_enable_hiera = true
    } else {
      $l_enable_hiera = false
    }
  } else {
    $l_enable_hiera = $enable_hiera
  }

  class { 'puppet' : }
  class { 'puppet::master::install' :
    type    => $l_type,
    require => Class [ 'puppet' ],
  }
  class { 'puppet::master::configure' :
    type         => $l_type,
    enable_hiera => $l_enable_hiera,
    require      => Class [ 'puppet::master::install' ],
  }
  class { 'puppet::master::service' :
    type    => $l_type,
    require => Class [ 'puppet::master::configure' ],
  }
}

# == Class: puppet::master::install
#
# This is the Puppet Master installation class. It installs the puppet::master
# necessities.
#
# === Parameters
#
# [*type*]
#   See puppet::master::type
#
class puppet::master::install (
  $type,
) inherits puppet::install {
  package { $puppet::params::master_packages[$type] :
    ensure  => present,
  }
}

# == Class: puppet::master::configure
#
# This is the Puppet Master configuration class. It configures the puppet::master
# and all associated files.
#
# === Parameters
#
# [*type*]
#   See puppet::master::type
#
# [*enable_hiera*]
#   See puppet::master::enable_hiera
#
class puppet::master::configure (
  $type,
  $enable_hiera,
) inherits puppet::configure {
  # Need this to overwrite the basic setting
  $is_master = true
  File {
    require => Class [ 'puppet::master::install' ],
  }
  File [ $puppet::params::puppetconf ] {
    content => template ( 'puppet/puppet.conf.erb' ),
    notify  => Service [ $puppet::params::masterservice[$type] ],
  }
  file { "${puppet::params::confdir}/fileserver.conf" :
    ensure  => file,
    content => template ( 'puppet/fileserver.conf.erb' ),
    require => File [ $puppet::params::confdir ],
    notify  => Service [ $puppet::params::masterservice[$type] ],
  }
  file { $puppet::params::vardir :
    ensure  => directory,
    owner   => $puppet::params::user,
    group   => $puppet::params::group,
  }
  file { $puppet::params::reportsdir :
    ensure  => directory,
    owner   => $puppet::params::user,
    group   => $puppet::params::group,
    recurse => true,
  }
  file { $puppet::params::ssldir :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => 'root',
    mode   => '0771',
  }
  file { [
    $puppet::params::manifestpath['production'],
    $puppet::params::modulepath['production'],
  ] :
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    recurse => true,
    require => File [ $puppet::params::confdir ],
  }
  file { "${puppet::params::manifestpath['production']}/site.pp" :
    ensure  => file,
    content => template ( 'puppet/site.pp.erb' ),
    require => File [ $puppet::params::manifestpath['production'] ],
  }
  file { [
    $puppet::params::environmentspath['base'],
    $puppet::params::environmentspath['production'],
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
  if $enable_hiera == true {
    class { 'puppet::master::hiera' : }
  }
}

# == Class: puppet::master::service
#
# This is the Puppet Master service class. It configures the puppet::master service.
#
# === Parameters
#
# [*type*]
#   See puppet::master::type
#
class puppet::master::service (
  $type,
) {
  if $type == 'self' {
    service { $puppet::params::masterservice[$type] :
      ensure  => running,
      enable  => true,
      require => Class [ 'puppet::master::install' ],
    }
  }
}

# == Class: puppet::master::hiera
#
# This is the Puppet Master class for the hiera configuration.
#
# === Examples
#
#  class { puppet::master::hiera : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master::hiera inherits puppet::params {
  class { 'puppet::master::hiera::install' :
    require => Class [ 'puppet::master' ],
  }
  class { 'puppet::master::hiera::configure' :
    require => Class [ 'puppet::master::hiera::install' ],
  }
}

# == Class: puppet::master::hiera::install
#
# This installs the hiera requirements.
#
# === Examples
#
#  class { puppet::master::hiera::install : }
#
class puppet::master::hiera::install {
  package { 'hiera-gpg' :
    ensure   => present,
    provider => 'gem',
  }
}

# == Class: puppet::master::hiera::configure
#
# This configures hiera for puppet masters.
#
# === Examples
#
#  class { puppet::master::hiera::configure : }
#
class puppet::master::hiera::configure {
  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file { $puppet::params::hieraconf :
    ensure  => file,
    content => template( 'puppet/hiera.yaml.erb' ),
    require => File [ $puppet::params::confdir ],
  }
  file { [
    $puppet::params::hierapath['production'],
    $puppet::params::hierapath['testing'],
    $puppet::params::hierapath['development'],
  ] :
    ensure => directory,
    require => File [ $puppet::params::hieraconf ],
  }
  file { "${puppet::params::hierapath['production']}/common.yaml" :
    ensure  => file,
    source  => "puppet:///modules/puppet/${puppet::params::hieradir}/common.yaml",
    require => File [ $puppet::params::hierapath['production'] ],
  }
  file { "${puppet::params::hierapath['production']}/${::fqdn}.yaml" :
    ensure  => file,
    source  => "puppet:///modules/puppet/${puppet::params::hieradir}/master.yaml",
    require => File [ $puppet::params::hierapath['production'] ],
  }
  file { [
    "${puppet::params::hierapath['testing']}/common.yaml",
    "${puppet::params::hierapath['development']}/common.yaml",
  ] :
    ensure  => file,
    replace => false,
    source  => "puppet:///modules/puppet/${puppet::params::hieradir}/common.yaml",
  }
  file { [
    "${puppet::params::hierapath['production']}/passwords.yaml",
    "${puppet::params::hierapath['testing']}/passwords.yaml",
    "${puppet::params::hierapath['development']}/passwords.yaml",
  ] :
    ensure  => file,
    replace => false,
    source  => "puppet:///modules/puppet/${puppet::params::hieradir}/passwords.yaml",
  }
  file { [
    "${puppet::params::hierapath['production']}/${puppet::params::gpgdir}",
    "${puppet::params::hierapath['testing']}/${puppet::params::gpgdir}",
    "${puppet::params::hierapath['development']}/${puppet::params::gpgdir}",
  ] :
    ensure  => directory,
  }
  file { $puppet::params::gpgpath :
    ensure  => directory,
    owner   => $puppet::params::user,
    group   => $puppet::params::group,
    mode    => '0700',
    require => File [ $puppet::params::vardir ],
  }
  file { "${puppet::params::confdir}/${puppet::params::gpgdir}" :
    ensure  => directory,
    owner   => $puppet::params::user,
    group   => $puppet::params::group,
    mode    => '0700',
    require => File [ $puppet::params::confdir ],
  }
}

define puppet::master::hiera::create_empty_file ()
{
  file { $name :
    ensure  => file,
    content => '---',
    replace => false,
    require => File [ dirname ($name) ],
  }
}

# == Define: puppet::master::module
#
# This is the method let's you install puppet modules from the {Puppet Forge}[forge.puppet.com].
#
# === Parameters
#
# [*ensure*]
#  +present+ will ensure the module to be installed
#
# [*contributor*]
#  Defines the contributor of the module. Defaults to +puppetlabs+
#
# [*ignore_dependencies*]
#  Forces the module installation disregarding any possible module dependencies.
#  Defaults to +false+
#
# === Examples
#
#  puppet::master::module { 'apache': ensure => present }
#
# === Authors
#
# Bernd Weber <mailto:bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 {Copper Frog LLC.}[copperfroghosting.com]
#
define puppet::master::module (
  $ensure,
  $contributor = 'puppetlabs',
  $ignore_dependencies = false,
) {
  require ( 'puppet::params' )

  if $ignore_dependencies == true {
    $params = '--ignore-dependencies'
  }
  if $ensure == 'present' {
    exec { "install-${name}-module" :
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => "puppet module install ${contributor}/${name} ${params}",
      creates => "${puppet::params::modulepath['production']}/${name}",
      require => Class [ 'puppet::configure' ],
    }
  }
}


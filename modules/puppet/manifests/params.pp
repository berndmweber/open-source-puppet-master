# == Class: puppet::params
#
# This is the Puppet parameters class. It holds all relevant modifiable parameters/
# variables for the puppet classes.
#
# === Examples
#
#  class { puppet::params : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::params {
  $confdir          = '/etc/puppet'
  $vardir           = '/var/lib/puppet'
  $yamldir          = "${vardir}/yaml"
  $rundir           = '/var/run/puppet'
  $logdir           = '/var/log/puppet'
  $ssldir           = "${confdir}/ssl"
  $reportsdir       = "${vardir}/reports"
  $factdir          = "${vardir}/lib/facter"
  $templatedir      = "${confdir}/templates"
  $rackdir          = '/usr/share/puppet/rack'
  $pmrackdir        = 'puppetmasterd'
  $pmrackpath       = "${rackdir}/${pmrackdir}"
  $pmconfigru       = 'config.ru'
  $environmentspath = {
    'base'        => "${confdir}/environments",
    'production'  => "${confdir}/environments/production",
    'testing'     => "${confdir}/environments/testing",
    'development' => "${confdir}/environments/development",
  }
  $modulepath       = {
    'production'  => "${confdir}/modules",
    'testing'     => "${$environmentspath['testing']}/modules",
    'development' => "${$environmentspath['development']}/modules",
  }
  $manifestpath     = {
    'production'  => "${confdir}/manifests",
    'testing'     => "${$environmentspath['testing']}/manifests",
    'development' => "${$environmentspath['development']}/manifests",
  }
  $user             = 'puppet'
  $group            = 'puppet'
  $puppetconf       = "${confdir}/puppet.conf"
  $hieraconf        = "${confdir}/hiera.yaml"
  $hieradir         = 'hieradata'
  $hierapath        = {
    'production'  => "${$environmentspath['production']}/${hieradir}",
    'testing'     => "${$environmentspath['testing']}/${hieradir}",
    'development' => "${$environmentspath['development']}/${hieradir}",
  }
  $gpgdir           = 'gpgdata'
  $gpgpath          = "${vardir}/.gnupg"
  $masterport       = '8140'
  $puppet_modules   = {
    'self'   => [ 'ruby' ],
    'apache' => [ 'apache', 'mysql', 'ruby' ],
  }
  $masterservice    = {
    'self'   => 'puppetmaster',
    'apache' => 'httpd',
  }

  case $::operatingsystem {
    'Ubuntu' : {
      $puppet_packages    = [ 'puppet' ]
      $master_packages    = {
        'self'   => 'puppetmaster',
        'apache' => 'puppetmaster-common',
      }
      $dashboard_packages = [ 'puppet-dashboard' ]

      $puppet_default   = '/etc/default/puppet'
      $puppet_service   = 'puppet'
    }
    default : {
      fail ( "Your Operating system ${::operatingsystem} is currently not supported by this class!")
    }
  }
}

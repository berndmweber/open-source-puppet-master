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

  $dashboard_version      = '1.2.23'
  $dashboard_base_name    = 'puppet-dashboard'
  $dashboard_package_name = "${dashboard_base_name}-${dashboard_version}"
  $dashboard_package      = "${dashboard_package_name}.tar.gz"
  $dashboard_location     = "http://downloads.puppetlabs.com/dashboard/${dashboard_package}"
  $dashboard_basedir      = '/var/lib'
  $dashboard_path         = "${dashboard_basedir}/${dashboard_base_name}"
  $dashboard_user         = 'puppet-dashboard'
  $dashboard_group        = 'puppet-dashboard'
  $dashboard_vhost_name   = 'dashboard'
  $dashboard_fqdn         = "${dashboard_vhost_name}.${::domain}"
  $dashboard_db           = {
    'production'  => 'dashboard_production',
    'development' => 'dashboard_development',
    'testing'     => 'dashboard_testing',
    'test'        => 'dashboard_test',
  }
  $dashboard_db_user        = 'pm_dashboard'
  $dashboard_db_encoding    = 'utf8'
  $dashboard_db_adapter     = 'mysql'
  $dashboard_report_port    = '3000'
  $dashboard_inventory_port = $masterport
  $dashboard_http_port      = $dashboard_report_port
  $dashboard_htpasswd_path  = "${puppet::params::dashboard_path}/config/htpasswords"

  case $::operatingsystem {
    'Ubuntu' : {
      $puppet_packages    = [ 'puppet' ]
      $master_packages    = {
        'self'   => 'puppetmaster',
        'apache' => 'puppetmaster-common',
      }

      $puppet_default   = '/etc/default/puppet'
      $puppet_service   = 'puppet'
    }
    default : {
      fail ( "Your Operating system ${::operatingsystem} is currently not supported by this class!")
    }
  }
}

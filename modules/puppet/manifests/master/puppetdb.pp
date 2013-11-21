# == Class: puppet::master::puppetdb
#
# This is the Puppet Master class for the puppetdb configuration.
#
# === Examples
#
#  class { puppet::master::puppetdb : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master::puppetdb inherits puppet::params {
  require ( '::puppetdb' )

  class { 'puppet::master::puppetdb::install' :
    require => Class [ 'puppet::master::apache', '::puppetdb' ],
    tag     => 'puppetdb',
  }
  class { 'puppet::master::puppetdb::configure' :
     require => Class [ 'puppet::master::puppetdb::install' ],
  }

}

# == Class: puppet::master::puppetdb::install
#
# This installs the puppetdb requirements.
#
# === Examples
#
#  class { puppet::master::puppetdb::install : }
#
class puppet::master::puppetdb::install {
#  package { 'puppetdb-terminus' :
#    ensure => present,
#  }
}

# == Class: puppet::master::puppetdb::configure
#
# This configures the puppetdb requirements.
#
# === Examples
#
#  class { puppet::master::puppetdb::configure : }
#
class puppet::master::puppetdb::configure {
  class { '::puppetdb::master::config' :
    puppetdb_server         => $puppet::params::puppetdb_server_name,
    puppet_service_name     => 'httpd',
    manage_storeconfigs     => false,
    manage_report_processor => false,
    manage_config           => true,
  }
}

# == Class: puppet::master::apache
#
# This is the Puppet Master class for a Passenger/Apache setup. It configures
# the puppet::master to work with passenger and apache instead of the internal
# WEBrick.
#
# === Examples
#
#  class { puppet::master::apache : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master::apache inherits puppet::params {
  $type = 'apache'

  class { 'puppet::master' : type => $type }
  class { 'puppet::master::apache::configure' :
    require => Class [ 'puppet::master' ],
  }
}

# == Class: puppet::master::apache::configure
#
# This configures the Puppet Master for apache. It configures all resources
# necessary for passenger operation and generates the necessary SSL certificates.
# It defines the apache and vhost settings necessary by providing a custom vhost
# configuration template.
#
# === Examples
#
#  class { puppet::master::apache::configure : }
#
class puppet::master::apache::configure {
  require ( 'apache', 'rvm::passenger::apache' )
  require apache::mod::headers
  require apache::mod::ssl

  file { [
      $puppet::params::rackdir,
      $puppet::params::pmrackpath,
      "${puppet::params::pmrackpath}/public",
      "${puppet::params::pmrackpath}/tmp",
    ] :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { "${puppet::params::pmrackpath}/${puppet::params::pmconfigru}" :
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    content => template ( "puppet/${puppet::params::pmconfigru}.erb" ),
    notify  => Service [ 'httpd' ],
    require => File [ $puppet::params::pmrackpath ],
  }

  exec { 'generate_master-cert' :
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    cwd       => $puppet::params::confdir,
    command   => 'puppet cert generate $(puppet master --configprint certname)',
    unless    => "test -e ${puppet::params::ssldir}/certs/${::fqdn}.pem",
    logoutput => on_failure,
    require   => Class [ 'puppet::master::configure' ],
  }

  apache::vhost { 'puppetmaster' :
    priority        => '10',
    vhost_name      => '*',
    port            => $puppet::params::masterport,
    docroot         => "${puppet::params::pmrackpath}/public",
    logroot         => $puppet::params::logdir,
    options         => [ 'None' ],
    custom_fragment => template( 'puppet/puppetmaster.conf.erb' ),
    require         => [ File [ "${puppet::params::pmrackpath}/${puppet::params::pmconfigru}" ],
                         Exec [ 'generate_master-cert' ],
                         Class [ 'apache::mod::ssl', 'apache::mod::headers' ],
                       ],
  }
}

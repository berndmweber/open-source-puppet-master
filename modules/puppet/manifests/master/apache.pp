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
# Bernd Weber <mailto:bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 {Copper Frog LLC.}[copperfroghosting.com]
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
# This configures the Puppet Master for apache. It defines the
# vhost settings necessary by providing a custom vhost configuration template.
#
# === Examples
#
#  class { puppet::master::apache::configure : }
#
class puppet::master::apache::configure {
  require ( 'apache' )

  apache::vhost { 'puppetmaster' :
    priority   => '10',
    vhost_name => '*',
    port       => $puppet::params::masterport,
    template   => 'puppet/puppetmaster.conf.erb',
    docroot    => "${puppet::params::rackdir}/puppetmasterd/",
    logroot    => $puppet::params::logdir,
  }
}

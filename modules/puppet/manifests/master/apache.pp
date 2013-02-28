# == Class: puppet::master::apache
#
# This is the Puppet Master class for a Passenger/Apache setup. It configures
# the puppet master to work with Passenger and Apache instead of the internal
# Webrick.
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { puppet::master::apache : }
#
# === Authors
#
# Bernd Weber <bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 Copper Frog LLC.
#

class puppet::master::apache::configure {
  require ( 'apache' )

  apache::vhost { 'puppetmaster' :
    priority   => '10',
    vhost_name => "*",
    port       => $puppet::params::masterport,
    template   => 'puppet/puppetmaster.conf.erb',
    docroot    => "${puppet::params::rackdir}/puppetmasterd/",
    logroot    => $puppet::params::logdir,
  }
}

class puppet::master::apache::service {
  Service <| title == 'httpd' |>
}

class puppet::master::apache inherits puppet::params {
  $type = 'apache'

  class { "puppet::master::apache::configure" : }
  class { "puppet::master" :
    type => $type,
    require => Class [ "puppet::master::apache::configure" ],
  }
}

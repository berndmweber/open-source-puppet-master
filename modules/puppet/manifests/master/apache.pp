
class puppet::master::apache {
  require ( "apache" )
  apache::vhost { 'puppetmaster' :
    priority => '1',
    port     => puppet::params::masterport,
    template => 'puppet/puppetmaster.conf.erb',
    docroot  => "${puppet::params::rackdir}/puppetmasterd/",
    logroot  => $puppet::params::logdir,
    require  => Class [ 'apache' ],
  }
}

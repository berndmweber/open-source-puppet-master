
class puppet::master::apache {
  require ( 'puppet::params' )
  apache::vhost { 'puppetmaster' :
    priority   => '1',
    vhost_name => "*",
    port       => $puppet::params::masterport,
    template   => 'puppet/puppetmaster.conf.erb',
    docroot    => "${puppet::params::rackdir}/puppetmasterd/",
    logroot    => $puppet::params::logdir,
  }
}

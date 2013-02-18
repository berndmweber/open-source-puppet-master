
class puppet::master::apache {
  require ( "apache" )
  apache::vhost { 'puppetmaster' :
    priority => '1',
    port => puppet::params::masterport,
    template => 'puppet/puppetmaster.conf.erb',
    require => Class [ 'apache' ],
  }
}

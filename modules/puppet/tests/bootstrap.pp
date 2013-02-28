class { 'apache' : }
class { 'ruby' : }
class { "puppet::params" : }
# This will install some basic modules we need
puppet::master::module { $puppet::params::puppet_modules[$type] :
  ensure => present,
}

augeas { "seed_fqdn_in_hosts_file" :
  context => '/files/etc/hosts',
  lens    => 'Hosts.lns',
  incl    => '/etc/hosts',
  changes => [
    "set 01/ipaddr ${::ipaddress}",
    "set 01/canonical ${::fqdn}",
    "set 01/alias ${::hostname}",
  ],
  onlyif  => "match *[ipaddr=\"${::ipaddress}\"] size == 0",
}

class { "puppet::master" : type => 'apache' }

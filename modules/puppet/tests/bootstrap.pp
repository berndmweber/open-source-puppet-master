class { "puppet::params" : }
class { "puppet::master::preinstall" : }
class { "puppet::master::install" : type => 'apache' }

class { "puppet" : }
class { "puppet::master::preinstall" : }
class { "puppet::master::install" : type => 'apache' }

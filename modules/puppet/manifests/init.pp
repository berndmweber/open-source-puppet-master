class puppet::install {
}

class puppet::configure {
  file { "/etc/puppet/puppet.conf" :
    ensure => file,
    content => template ( "puppet/puppet.conf.erb" ),
  }
}

class puppet {
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


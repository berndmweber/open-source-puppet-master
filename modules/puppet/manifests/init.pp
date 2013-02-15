class puppet::install {
}

class puppet::configure (
  $is_master = false,
) {
  file { "/etc/puppet/puppet.conf" :
    ensure => file,
    content => template ( "puppet/puppet.conf.erb" ),
  }
}

class puppet {
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


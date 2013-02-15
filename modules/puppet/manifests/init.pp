class puppet::install {
}

class puppet::configure (
  $is_master = false,
) {
  file { "/etc/puppet/puppet.conf" :
    ensure => file,
    content => template ( "puppet/puppet.conf.erb" ),
  }
  file { "/etc/puppet" :
    ensure => directory,
    owner => 'puppet',
    group => 'root',
  }
}

class puppet {
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


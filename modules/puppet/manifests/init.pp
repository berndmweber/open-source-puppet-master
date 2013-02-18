class puppet::install {
}

class puppet::configure (
  $is_master = false,
) {
  file { $puppet::params::etcmaindir :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => 'root',
  }
  file { $puppet::params::puppetconf :
    ensure  => file,
    content => template ( "puppet/puppet.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
  }
}

class puppet {
  class { "puppet::params" : }
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


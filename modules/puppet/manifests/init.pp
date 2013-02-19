class puppet::install {
  package { $puppet::params::puppet_packages :
    ensure => present,
  }
}

class puppet::configure {
  file { $puppet::params::etcmaindir :
    ensure  => directory,
    owner   => $puppet::params::user,
    group   => 'root',
    require => Class [ "puppet::install" ]
  }
  file { $puppet::params::puppetconf :
    ensure  => file,
    content => template ( "puppet/puppet.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
  }
  file { "${puppet::params::etcmaindir}/auth.conf" :
    ensure  => file,
    content => template ( "puppet/auth.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
  }
  file { $puppet::params::puppet_default :
    ensure  => file,
    require => Class [ "puppet::install" ]
  }
  augeas { $puppet::params::puppet_default :
    context => "/files/${puppet::params::puppet_default}",
    lens    => 'Shellvars.lns',
    incl    => $puppet::params::puppet_default,
    changes => [
      "set START \"yes\"",
    ],
    require => File [ $puppet::params::puppet_default ],
  }
}

class puppet::service {
  service { $puppet::params::puppet_service :
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
    require => Class [ "puppet::configure" ],
  }
}

class puppet {
  class { "puppet::params" : }
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


class puppet::install {
  package { [
    "puppetmaster-passenger",
  ] :
    ensure => present,
  }
}

class puppet::configure {}

class puppet {
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


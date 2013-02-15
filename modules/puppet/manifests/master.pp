class puppet::master::install {
  case $::operatingsystem {
    'Ubuntu' : {
      $packages = [
        "puppetmaster",
      ]
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
  package { $packages :
    ensure => present,
  }
}

class puppet::master {
  class { "puppet::master::install" : }
}

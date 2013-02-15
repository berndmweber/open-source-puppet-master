class puppet::master::preinstall {
  augeas { "seed_fqdn_in_hosts_file" :
    context => '/files/etc/hosts',
    lens => 'Hosts.lns',
    incl => '/etc/hosts',
    changes => [
      "set 01/ipaddr ${::ipaddress}",
      "set 01/canonical ${::fqdn}",
      "set 01/alias ${::hostname}",
    ],
    onlyif => "match *[ipaddr=\"${::ipaddress}\"] size == 0",
  }
}

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
    require => Class [ "puppet::master::preinstall" ],
  }
}

class puppet::master::configure inherits puppet::configure {
  $is_master = true
}

class puppet::master inherits puppet {
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" : }
  class { "puppet::master::configure" : }
}

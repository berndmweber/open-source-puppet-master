class puppet::master::preinstall {
  augeas { "seed_fqdn_in_hosts_file" :
    context => '/files/etc/hosts',
    lens    => 'Hosts.lns',
    incl    => '/etc/hosts',
    changes => [
      "set 01/ipaddr ${::ipaddress}",
      "set 01/canonical ${::fqdn}",
      "set 01/alias ${::hostname}",
    ],
    onlyif  => "match *[ipaddr=\"${::ipaddress}\"] size == 0",
  }
}

class puppet::master::install {
  case $::operatingsystem {
    'Ubuntu' : {
      $packages = [
        "puppetmaster-passenger",
      ]
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
  package { $packages :
    ensure  => present,
    require => Class [ "puppet::master::preinstall" ],
  }
}

class puppet::master::configure {
  $is_master = true
  class { "puppet::configure" :
    is_master => $is_master,
  }
  file { "/var/lib/puppet/reports" :
    ensure => directory,
    owner  => 'puppet',
    group  => 'root',
  }
  exec { 'install-apache-module' :
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "puppet module install puppetlabs/apache",
    creates => "/etc/puppet/modules/apache",
    require => Class [ "puppet::configure" ],
  }
  file { "/etc/puppet/manifests" :
    ensure  => directory,
    require => File [ "/etc/puppet" ],
  }
  file { "/etc/puppet/manifests/site.pp" :
    ensure  => file,
    content => template ( "puppet/site.pp.erb" ),
    require => File [ "/etc/puppet/manifests" ],
  }
}

class puppet::master {
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" : }
  class { "puppet::master::configure" : }
}

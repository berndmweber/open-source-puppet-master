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

class puppet::master::install inherits puppet::install {
  package { $puppet::params::master_packages :
    ensure  => present,
    require => Class [ "puppet::master::preinstall" ],
  }
}

class puppet::master::configure inherits puppet::configure {
  $is_master = true
  File [ $puppet::params::puppetconf ] {
    content => template ( "puppet/puppet.conf.erb" ),
  }

  file { "${puppet::params::vardir}/reports" :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => 'root',
  }
  file { "${puppet::params::etcmaindir}/fileserver.conf" :
    ensure  => file,
    content => template ( "puppet/fileserver.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
  }
  exec { 'install-apache-module' :
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "puppet module install puppetlabs/apache",
    creates => "${puppet::params::modulepath}/apache",
    require => Class [ "puppet::configure" ],
  }
  file { [
    $puppet::params::manifestpath,
    $puppet::params::modulepath,
  ] :
    ensure  => directory,
    require => File [ $puppet::params::etcmaindir ],
  }
  file { "${puppet::params::manifestpath}/site.pp" :
    ensure  => file,
    content => template ( "puppet/site.pp.erb" ),
    require => File [ $puppet::params::manifestpath ],
  }
  file { [
    "${puppet::params::environmentspath}",
    "${puppet::params::environment_testing}",
    "${puppet::params::environment_development}",
  ] :
    ensure  => directory,
    require => File [ $puppet::params::etcmaindir ],
  }
}

class puppet::master::service inherits puppet::service {}

class puppet::master {
  class { "puppet::params" : }
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" : }
  class { "puppet::master::configure" : }
  class { "puppet::master::service" : }
}


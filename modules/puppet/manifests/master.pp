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
  package { $puppet::params::master_packages :
    ensure  => present,
    require => Class [ "puppet::master::preinstall" ],
  }
}

class puppet::master::configure {
  $is_master = true
  class { "puppet::configure" :
    is_master => $is_master,
  }
  file { "${puppet::params::vardir}/reports" :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => 'root',
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
    "${puppet::params::modulepath}/${puppet::params::environmentspath}",
    "${puppet::params::modulepath}/${puppet::params::environment_testing}",
    "${puppet::params::modulepath}/${puppet::params::environment_development}",
  ] :
    ensure  => directory,
    require => File [ $puppet::params::etcmaindir ],
  }
}

class puppet::master {
  class { "puppet::params" : }
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" : }
  class { "puppet::master::configure" : }
}


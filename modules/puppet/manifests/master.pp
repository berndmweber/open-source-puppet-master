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

define puppet::master::install_module (
  $contributer = 'puppetlabs',
  $ignore_dependencies = false,
) {
  if $ignore_dependencies == true {
    $params = "--ignore-dependencies"
  }
  exec { "install-${name}-module" :
    path => "/bin:/sbin:/usr/bin:/usr/sbin",
    command => "puppet module install ${contributer}/${name} ${params}",
    creates => "${puppet::params::modulepath['production']}/${name}",
    require => Class [ "puppet::configure" ],
  }
}

class puppet::master::configure inherits puppet::configure {
  # Need this to overwrite the basic setting
  $is_master = true
  File [ $puppet::params::puppetconf ] {
    content => template ( "puppet/puppet.conf.erb" ),
  }
  file { "${puppet::params::vardir}/reports" :
    ensure => directory,
    owner  => $puppet::params::user,
    group  => $puppet::params::group,
    recurse => true,
  }
  file { "${puppet::params::etcmaindir}/fileserver.conf" :
    ensure  => file,
    content => template ( "puppet/fileserver.conf.erb" ),
    require => File [ $puppet::params::etcmaindir ],
  }
  file { [
    $puppet::params::manifestpath['production'],
    $puppet::params::modulepath['production'],
  ] :
    ensure  => directory,
    owner  => 'root',
    group  => 'root',
    recurse => true,
    require => File [ $puppet::params::etcmaindir ],
  }
  # This will install some basic modules we need
  puppet::master::install_module { $puppet::params::puppet_modules : }
  file { "${puppet::params::manifestpath['production']}/site.pp" :
    ensure  => file,
    content => template ( "puppet/site.pp.erb" ),
    require => File [ $puppet::params::manifestpath['production'] ],
  }
  file { [
    $puppet::params::environmentspath['base'],
    $puppet::params::environmentspath['testing'],
    $puppet::params::modulepath['testing'],
    $puppet::params::manifestpath['testing'],
    $puppet::params::environmentspath['development'],
    $puppet::params::modulepath['development'],
    $puppet::params::manifestpath['development'],
  ] :
    ensure  => directory,
    require => File [ $puppet::params::etcmaindir ],
  }
}

class puppet::master::service inherits puppet::service {}

class puppet::master inherits puppet::params {
  class { "puppet::master::preinstall" : }
  class { "puppet::master::install" : }
  class { "puppet::master::configure" : }
  class { "puppet::master::service" : }
}


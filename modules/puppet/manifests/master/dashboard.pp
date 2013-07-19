# == Class: puppet::master::dashboard
#
# This is the Puppet Master class for the dashboard configuration.
#
# === Examples
#
#  class { puppet::master::dashboard : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master::dashboard inherits puppet::params {
  require ( 'mysql', 'mysql::server', 'mysql::ruby' )
  
  class { 'puppet::master::dashboard::install' :
    require => Class [ 'puppet::master' ],
  }
  class { 'puppet::master::dashboard::configure' :
    require => Class [ 'puppet::master::dashboard::install' ],
  }
}

# == Class: puppet::master::dashboard::install
#
# This installs the dashboard requirements.
#
# === Examples
#
#  class { puppet::master::dashboard::install : }
#
class puppet::master::dashboard::install {
  user { $puppet::params::dashboard_user :
    ensure     => present,
    home       => $puppet::params::dashboard_path,
    gid        => $puppet::params::dashboard_group,
    managehome => false,
    shell      => '/bin/false',
  }
  group { $puppet::params::dashboard_group :
    ensure => present,
  }

  $pkg_download_location = "/tmp/${puppet::params::dashboard_package}"
  $pkg_extract_location = "${puppet::params::vardir}/${puppet::params::dashboard_package_name}"
  exec { 'download_dashboard_package' :
    cwd     => '/tmp',
    path    => ['/usr/bin', '/bin'],
    command => "curl -o ${puppet::params::dashboard_package} ${puppet::params::dashboard_location}",
    creates => $pkg_download_location,
  }
  exec { 'extract_dashboard_package' :
    cwd     => $puppet::params::vardir,
    path    => ['/usr/bin', '/bin'],
    command => "tar -xzf ${pkg_download_location}",
    creates => $pkg_extract_location,
    require => Exec [ 'download_dashboard_package' ],
  }
  file { $pkg_extract_location :
    ensure  => directory,
    owner   => $puppet::params::dashboard_user,
    group   => $puppet::params::dashboard_group,
    recurse => true,
    require => Exec [ 'extract_dashboard_package' ],
  }
  file { $puppet::params::dashboard_path :
    ensure  => link,
    target  => $pkg_extract_location,
    require => File [ $pkg_extract_location ],
  }
}

# == Class: puppet::master::dashboard::configure
#
# This configures the dashboard for puppet masters.
#
# === Examples
#
#  class { puppet::master::dashboard::configure : }
#
class puppet::master::dashboard::configure {
  
}


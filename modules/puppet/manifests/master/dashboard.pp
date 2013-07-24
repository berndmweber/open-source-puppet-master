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
    require => Class [ 'puppet::master::apache' ],
  }
  class { 'puppet::master::dashboard::configure' :
    require => Class [ 'puppet::master::dashboard::install' ],
  }
  class { 'puppet::master::dashboard::service' :
    require => Class [ 'puppet::master::dashboard::configure' ],
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
  require ( 'apache', 'passenger' )
  require apache::mod::headers
  require apache::mod::ssl

  File {
    owner => $puppet::params::dashboard_user,
    group => $puppet::params::dashboard_group,
  }
  
  $db_password = hiera ( 'puppet::master::dashboard::mysql::db::password' )
  mysql::db { [
    $puppet::params::dashboard_db['production'],
    $puppet::params::dashboard_db['development'],
    $puppet::params::dashboard_db['testing'],
  ] :
    user     => $puppet::params::dashboard_db_user,
    password => $db_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => $puppet::params::dashboard_db_encoding,
    before   => File [ "${puppet::params::dashboard_path}/config/database.yml" ],
  }
  file { "${puppet::params::dashboard_path}/config/database.yml" :
    ensure  => file,
    mode    => '0660',
    content => template ( 'puppet/dashboard/database.yml.erb' ),
  }
  exec { 'configure_production_db' :
    cwd         => $puppet::params::dashboard_path,
    path        => ['/usr/local/bin', '/usr/bin', '/bin'],
    command     => "rake RAILS_ENV=production db:migrate",
    unless      => "mysql -u${puppet::params::dashboard_db_user} -p${db_password} -e 'use ${puppet::params::dashboard_db['production']}; show tables;' | grep nodes",
    logoutput   => on_failure,
    require     => File [ "${puppet::params::dashboard_path}/config/database.yml" ],
  }
  exec { 'configure_development_db' :
    cwd         => $puppet::params::dashboard_path,
    path        => ['/usr/local/bin', '/usr/bin', '/bin'],
    command     => "rake db:migrate db:test:prepare",
    refreshonly => true,
    logoutput   => on_failure,
    subscribe   => Exec [ 'configure_production_db' ],
  }
  file { "${puppet::params::dashboard_path}/config/settings.yml" :
    ensure  => file,
    mode    => '0660',
    content => template ( 'puppet/dashboard/settings.yml.erb' ),
  }
  apache::vhost { 'dashboard' :
    priority        => '12',
    vhost_name      => '*',
    port            => $puppet::params::dashboard_http_port,
    docroot         => "${puppet::params::dashboard_path}/public",
    docroot_owner   => $puppet::params::dashboard_user,
    docroot_group   => $puppet::params::dashboard_group,
    logroot         => $puppet::params::logdir,
    options         => [ 'None' ],
    custom_fragment => template( 'puppet/dashboard/dashboard.conf.erb' ),
    require         => [ File [ "${puppet::params::dashboard_path}/config/settings.yml" ],
                         Exec [ 'configure_production_db' ],
                         Class [ 'apache::mod::ssl', 'apache::mod::headers' ],
                       ],
    tag             => 'dashboard',
  }
  file { '/etc/init.d/dashboard-workers' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template ( 'puppet/dashboard/dashboard-workers.erb' ),
    require => Apache::Vhost [ 'dashboard' ],
  }
}

# == Class: puppet::master::dashboard::service
#
# This configures the dashboard services for puppet masters.
#
# === Examples
#
#  class { puppet::master::dashboard::service : }
#
class puppet::master::dashboard::service {
  service { 'dashboard-workers' :
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    # TODO: Not sure why it isn't able to get the status without this?!
    status     => 'service dashboard-workers status',
    subscribe  => File [ '/etc/init.d/dashboard-workers' ],
  }
}


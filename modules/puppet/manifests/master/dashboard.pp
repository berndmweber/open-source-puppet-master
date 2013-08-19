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
class puppet::master::dashboard (
  $allowed_ip_ranges = [],
) inherits puppet::params {
  require ( 'mysql', 'mysql::server', 'mysql::ruby' )
  
  class { 'puppet::master::dashboard::install' :
    require => Class [ 'puppet::master::apache' ],
  }
  class { 'puppet::master::dashboard::configure' :
    allowed_ip_ranges => $allowed_ip_ranges,
    require           => Class [ 'puppet::master::dashboard::install' ],
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
  $pkg_extract_location = "${puppet::params::dashboard_basedir}/${puppet::params::dashboard_package_name}"
  exec { 'download_dashboard_package' :
    cwd     => '/tmp',
    path    => ['/usr/bin', '/bin'],
    command => "curl -o ${puppet::params::dashboard_package} ${puppet::params::dashboard_location}",
    creates => $pkg_download_location,
  }
  exec { 'extract_dashboard_package' :
    cwd     => $puppet::params::dashboard_basedir,
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
    owner   => $puppet::params::dashboard_user,
    group   => $puppet::params::dashboard_group,
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
class puppet::master::dashboard::configure (
  $allowed_ip_ranges,
) {
  require ( 'apache', 'passenger' )
  require apache::mod::headers
  require apache::mod::ssl

  File {
    owner => $puppet::params::dashboard_user,
    group => $puppet::params::dashboard_group,
  }
  Exec {
    cwd         => $puppet::params::dashboard_path,
    path        => ['/usr/local/bin', '/usr/bin', '/bin'],
    logoutput   => on_failure,
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
    command     => "rake RAILS_ENV=production db:migrate 2>/dev/null",
    unless      => "mysql -u${puppet::params::dashboard_db_user} -p${db_password} -e 'use ${puppet::params::dashboard_db['production']}; show tables;' | grep nodes",
    require     => File [ "${puppet::params::dashboard_path}/config/database.yml" ],
  }
#  exec { 'configure_development_db' :
#    command     => "rake db:migrate db:test:prepare 2>/dev/null",
#    refreshonly => true,
#    subscribe   => Exec [ 'configure_production_db' ],
#  }
  file { "${puppet::params::dashboard_path}/config/settings.yml" :
    ensure  => file,
    mode    => '0660',
    content => template ( 'puppet/dashboard/settings.yml.erb' ),
    require => Exec [ 'configure_production_db' ],
  }
  augeas { "seed_${puppet::params::dashboard_vhost_name}_in_hosts_file" :
    context => '/files/etc/hosts',
    lens    => 'Hosts.lns',
    incl    => '/etc/hosts',
    changes => [
      "set *[ipaddr=\"127.0.0.1\"]/alias[*] ${puppet::params::dashboard_vhost_name}",
      "set *[ipaddr=\"127.0.0.1\"]/alias[*] ${puppet::params::dashboard_fqdn}",
    ],
    onlyif  => "match *[alias=\"${puppet::params::dashboard_vhost_name}\"] size == 0",
    require => File [ "${puppet::params::dashboard_path}/config/settings.yml" ],
  }
  exec { 'create_dashboard_certificate' :
    user    => $puppet::params::dashboard_user,
    command => "rake cert:create_key_pair",
    creates => "${puppet::params::dashboard_path}/certs/${puppet::params::dashboard_fqdn}.private_key.pem",
    require => Augeas [ "seed_${puppet::params::dashboard_vhost_name}_in_hosts_file" ],
  }
  exec { 'create_dashboard_certificate_request' :
    user        => $puppet::params::dashboard_user,
    command     => "rake cert:request",
    refreshonly => true,
    subscribe   => Exec [ 'create_dashboard_certificate' ],
  }
  exec { 'accept_dashboard_certificate_request' :
    command => "puppet cert sign ${puppet::params::dashboard_fqdn}",
    onlyif  => "puppet cert list | grep ${puppet::params::dashboard_fqdn}",
    require => Exec [ 'create_dashboard_certificate_request' ],
  }
  exec { 'retrieve_dashboard_certificate' :
    user    => $puppet::params::dashboard_user,
    command => "rake cert:retrieve",
    creates => "${puppet::params::dashboard_path}/certs/${puppet::params::dashboard_fqdn}.cert.pem",
    require => Exec [ 'accept_dashboard_certificate_request' ],
  }
  exec { 'add_pm_to_dashboard' :
    user    => $puppet::params::dashboard_user,
    command => "rake RAILS_ENV=production node:add name=${::fqdn} 2>/dev/null",
    unless  => "rake RAILS_ENV=production node:list 2>/dev/null | grep ${fqdn}",
    require => Exec [ "retrieve_dashboard_certificate" ],
  }
  apache::vhost { $puppet::params::dashboard_vhost_name :
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
                         Exec [ 'accept_dashboard_certificate_request' ],
                         Class [ 'apache::mod::ssl', 'apache::mod::headers' ],
                       ],
    tag             => 'dashboard',
  }
  file { $puppet::params::dashboard_htpasswd_path :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => 'dashboard_admin:{SHA}L9YGd1FLvh/04IfSELcZxBcM7eI=',
    require => Apache::Vhost [ $puppet::params::dashboard_vhost_name ],
  }
  file { '/etc/init.d/dashboard-workers' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template ( 'puppet/dashboard/dashboard-workers.erb' ),
    require => Apache::Vhost [ $puppet::params::dashboard_vhost_name ],
  }
  cron { 'optimize_production_db' :
    command => "cd ${puppet::params::dashboard_path}; rake RAILS_ENV=production db:raw:optimize 2>/dev/null",
    user    => $puppet::params::dashboard_user,
    hour    => 1,
    minute  => 0,
    require => Exec [ 'configure_production_db' ],
  }
  cron { 'clean_reports_production_db' :
    command => "cd ${puppet::params::dashboard_path}; rake RAILS_ENV=production reports:prune upto=1 unit=mon 2>/dev/null",
    user    => $puppet::params::dashboard_user,
    hour    => 3,
    minute  => 0,
    weekday => 6,
    require => Exec [ 'configure_production_db' ],
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
    subscribe  => File [ '/etc/init.d/dashboard-workers' ],
  }
}


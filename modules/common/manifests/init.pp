# == Class: common
#
# This is the base class for common configurations
#
# === Examples
#
#  class { common : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class common (
  $accounts           = 'UNSET',
  $sshauth            = 'UNSET',
  $use_domain         = 'UNSET',
  $hosts              = 'UNSET',
  $mounts             = 'UNSET',
  $user_source_dir    = $common::params::user_source_dir,
  $package_source_dir = $common::params::package_source_dir,
  $base_packages      = $common::params::base_packages,
  $addl_packages      = 'UNSET',
  $absent_packages    = $common::params::absent_packages,
  $sudo_group         = $common::params::sudo_group,
  $sudo_addl_groups   = $common::params::sudo_addl_groups,
  $links              = 'UNSET',
) inherits common::params {

  $service_path       = $common::params::service_path
  $sudo_secure_path   = $common::params::sudo_secure_path
  $cron_svc           = $common::params::cron_svc
  $sshd_svc           = $common::params::sshd_svc

  if $use_domain == 'UNSET' {
    $domain = $::domain
  } else {
    $domain = $use_domain
  }

  class { 'common::install' : }
  class { 'common::configure' :
    require => Class [ 'common::install' ],
  }
  class { 'common::service' :
    require => Class [ 'common::configure' ],
  }
}

# == Class: common::install
#
# This installs common requirements.
#
# === Examples
#
#  class { common::install : }
#
class common::install {
  Package {
    ensure => present,
  }
  ensure_packages($common::base_packages)
  if $common::addl_packages != 'UNSET' {
    create_resources('package', $common::addl_packages)
  }
  package { $common::absent_packages :
    ensure => absent,
  }

  file { '/usr/local/bin/list-crontabs.sh' :
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0754',
    source => 'puppet:///modules/common/list-crontabs.sh'
  }
}

# == Class: common::configure
#
# This configures common requirements.
#
# === Examples
#
#  class { common::configure : }
#
class common::configure {
  File {
    owner => 'root',
    group => 'root'
  }

  file { [
    $common::user_source_dir,
    $common::package_source_dir,
  ] :
    ensure => directory,
    mode   => '0755'
  }

  case $::operatingsystem {
    'CentOS' : {
      if versioncmp ($::operatingsystemrelease, '6.0') >= 0 {
        file { '/etc/sudoers.d' :
          ensure => directory,
          mode   => '0750',
        }
      }
      common::configure::sudogroup { $common::sudo_group : }
    }
    'Ubuntu' : {
      file { '/etc/sudoers.d' :
        ensure => directory,
        mode   => '0440',
      }
      file { '/usr/bin/sudo' :
        mode => '4755',
      }
      common::configure::sudogroup { [
        $common::sudo_group,
        $common::sudo_addl_groups,
      ] : }
    }
    default : {
      fail ( "${::operatingsystem} is currently not supported." )
    }
  }

  augeas { 'sudo-set-securepaths' :
    context => '/files/etc/sudoers', # target file is /etc/sudoers
    lens    => 'Sudoers.lns',
    incl    => '/etc/sudoers',
    changes => [
      "set Defaults[secure_path]/secure_path \"${common::sudo_secure_path}\"",
    ],
  }

  augeas { '/etc/ssh/sshd_config-common' :
    context => '/files/etc/ssh/sshd_config',
    lens    => 'Sshd.lns',
    incl    => '/etc/ssh/sshd_config',
    changes => [
      "set ClientAliveInterval 540",
    ],
    notify  => Service [ $common::sshd_svc ],
  }

  exec { 'enable-colored-prompt' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'sed -i -e "s/#force_color_prompt=yes/force_color_prompt=yes/" /etc/skel/.bashrc',
    onlyif  => 'grep "#force_color_prompt" /etc/skel/.bashrc',
  }

  if $common::links != 'UNSET' {
    create_resources('common::configure::file::link', $common::links)
  }

  if $common::accounts != 'UNSET' {
    validate_hash($common::accounts)
    create_resources('account', $common::accounts)
  }
  if $common::sshauth != 'UNSET' {
    validate_hash($common::sshauth)
    create_resources('sshauth::client', $common::sshauth)
  }
  if $common::hosts != 'UNSET' {
    # Need to do this to utilize deeper merging
    if $common::hosts == hiera('common::hosts') {
      $temp_hosts = hiera_hash('common::hosts')
    } else {
      $temp_hosts = $common::hosts
    }
    validate_hash($temp_hosts)
    create_resources('common::configure::host', $temp_hosts)
  }
  if $common::mounts != 'UNSET' {
    validate_hash($common::mounts)
    create_resources('common::configure::mount', $common::mounts)
  }
}

define common::configure::sudogroup () {
  group { $name:
    ensure => present,
  }
  # Allow users belonging wheel group to use sudo
  augeas { "sudo${name}" :
    context => '/files/etc/sudoers', # target file is /etc/sudoers
    lens    => 'Sudoers.lns',
    incl    => '/etc/sudoers',
    changes => [
      # allow wheel users to use sudo
      "set spec[user = \"%${name}\"]/user %${name}",
      "set spec[user = \"%${name}\"]/host_group/host ALL",
      "set spec[user = \"%${name}\"]/host_group/command ALL",
      "set spec[user = \"%${name}\"]/host_group/command/runas_user ALL",
      "set spec[user = \"%${name}\"]/host_group/command/tag NOPASSWD",
    ],
  }
}

# == Class: common::service
#
# This controls common services.
#
# === Examples
#
#  class { common::service : }
#
class common::service {
  service { [
    $common::cron_svc,
    $common::sshd_svc,
  ] :
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
  }
}

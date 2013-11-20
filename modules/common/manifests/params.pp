# == Class: common::params
#
# This class holds all default parameters for common configurations
#
# === Examples
#
#  class { common : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class common::params {
  $user_source_dir    = '/usr/local/src'
  $package_source_dir = "${user_source_dir}/packages"
  $sudo_secure_path   = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

  $common_packages    = [
    'bzip2',
    'curl',
    'gzip',
    'openssh-server',
    'rsync',
    'sudo',
    'tar',
    'tree',
    'vim-common',
  ]
  case $::operatingsystem {
    'CentOS' : {
      $co_base_packages = [
        $common_packages,
        'file',
        'openssh',
        'openssh-clients',
        'patch',
        'vim-enhanced',
      ]
      if versioncmp ($::operatingsystemrelease, '6.0') >= 0 {
        $base_packages = [
          $co_base_packages,
          'ntpdate',
          'yum-plugin-changelog',
        ]
      } else {
        $base_packages = [
          $co_base_packages,
          'yum-changelog',
        ]
      }
      $absent_packages = [
        'caching-nameserver',
        'bind',
        'bind-chroot',
      ]
      $sudo_group   = 'wheel'
      $service_path = '/sbin/service'
      $cron_svc     = 'crond'
      $sshd_svc     = 'sshd'
    }
    'Ubuntu' : {
      $base_packages = [
        $common_packages,
        'apt-listchanges',
        'language-pack-en-base',
        'ntpdate',
        'openssh-client',
        'procinfo',
      ]
      $absent_packages = [
        'bind9',
        'firefox-locale-en',
      ]
      $sudo_group       = 'sudo'
      $sudo_addl_groups = 'staff'
      $service_path     = '/usr/sbin/service'
      $cron_svc         = 'cron'
      $sshd_svc         = 'ssh'
    }
    default : {
      fail ( "Operating system: ${::operatingsystem} is currently not supported!" )
    }
  }
}
class puppet::params {
  $etcmaindir       = "/etc/puppet"
  $vardir           = "/var/lib/puppet"
  $rundir           = "/var/run/puppet"
  $logdir           = "/var/log/puppet"
  $ssldir           = "${vardir}/ssl"
  $rackdir          = "/usr/share/puppet/rack"
  $environmentspath = {
    "base"        => "${etcmaindir}/environments",
    "testing"     => "${etcmaindir}/environments/testing",
    "development" => "${etcmaindir}/environments/development",
  }
  $modulepath       = {
    "production"  => "${etcmaindir}/modules",
    "testing"     => "${$environmentspath["testing"]}/modules",
    "development" => "${$environmentspath["development"]}/modules",
  }
  $manifestpath     = {
    "production"  => "${etcmaindir}/manifests",
    "testing"     => "${$environmentspath["testing"]}/manifests",
    "development" => "${$environmentspath["development"]}/manifests",
  }
  $user             = 'puppet'
  $group            = 'puppet'
  $puppetconf       = "${etcmaindir}/puppet.conf"
  $masterport       = '8140'
  $puppet_modules   = [ 'apache', 'mysql' ]

  case $::operatingsystem {
    'Ubuntu' : {
      $puppet_packages    = [ "puppet" ]
      $master_packages    = [ "puppetmaster-passenger" ]
      $dashboard_packages = [ "puppet-dashboard" ]
      $puppet_modules    += [ 'ruby' ]

      $puppet_default   = "/etc/default/puppet"
      $puppet_service   = "puppet"
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
}

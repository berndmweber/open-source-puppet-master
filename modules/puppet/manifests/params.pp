class puppet::params {
  $etcmaindir       = "/etc/puppet"
  $vardir           = "/var/lib/puppet"
  $rundir           = "/var/run/puppet"
  $logdir           = "/var/log/puppet"
  $ssldir           = "${vardir}/ssl"
  $rackdir          = "/usr/share/puppet/rack"
  $modulepath       = "${etcmaindir}/modules"
  $manifestpath     = "${etcmaindir}/manifests"
  $environmentspath = "${etcmaindir}/environments"
  $user             = 'puppet'
  $group            = 'puppet'
  $puppetconf       = "${etcmaindir}/puppet.conf"
  $masterport       = '8140'

  $environment_testing = "${environmentspath}/testing"
  $modulepath_testing   = "${environment_testing}/modules"
  $manifestpath_testing = "${environment_testing}/manifests"

  $environment_development  = "${environmentspath}/development"
  $modulepath_development   = "${environment_development}/modules"
  $manifestpath_development = "${environment_development}/manifests"

  case $::operatingsystem {
    'Ubuntu' : {
      $master_packages = [ "puppetmaster-passenger" ]
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
}

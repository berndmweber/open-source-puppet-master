class puppet::params {
  $etcmaindir   = "/etc/puppet"
  $vardir       = "/var/lib/puppet"
  $rundir       = "/var/run/puppet"
  $logdir       = "/var/log/puppet"
  $ssldir       = "${vardir}/ssl"
  $rackdir      = "/usr/share/puppet/rack"
  $modulepath   = "${etcmaindir}/modules"
  $manifestpath = "${etcmaindir}/manifests"
  $user         = 'puppet'
  $group        = 'puppet'
  $puppetconf   = "${etcmaindir}/puppet.conf"
  $masterport   = '8140'

  $environment_testing = "environments/testing"
  $modulepath_testing   = "${etcmaindir}/${environment_testing}/modules"
  $manifestpath_testing = "${etcmaindir}/${environment_testing}/manifests"

  $environment_development  = "environments/development"
  $modulepath_development   = "${etcmaindir}/${environment_development}/modules"
  $manifestpath_development = "${etcmaindir}/${environment_development}/manifests"

  case $::operatingsystem {
    'Ubuntu' : {
      $master_packages = [ "puppetmaster-passenger" ]
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
}

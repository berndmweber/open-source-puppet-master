class puppet::params {
  $etcmaindir   = "/etc/puppet"
  $vardir       = "/var/lib/puppet"
  $rundir       = "/var/run/puppet"
  $logdir       = "/var/log/puppet"
  $ssldir       = "${vardir}/ssl"
  $rackdir      = "/usr/shar/puppet/rack"
  $modulepath   = "${etcmaindir}/modules"
  $manifestpath = "${etcmaindir}/manifests"
  $user         = 'puppet'
  $group        = 'puppet'
  $puppetconf   = "${etcmaindir}/puppet.conf"
  $masterport   = '8140'

  case $::operatingsystem {
    'Ubuntu' : {
      $master_packages = [ "puppetmaster-passenger" ]
    }
    default : {
      fail ( "Your Operating system $::operatingsystem is currently not supported by this class!")
    }
  }
}

# == Class: puppet::test::cucumber
#
# This is the Puppet test clas for cucumber-puppets.
#
# === Examples
#
#  class { puppet::test::cucumber : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 {Copper Frog LLC.}[copperfroghosting.com]
#
class puppet::test::cucumber inherits puppet::params {
  $featuredir  = "${puppet::params::confdir}/features"
  $stepspath   = 'steps'
  $stepsdir    = "${featuredir}/${stepspath}"
  $supportpath = 'support'
  $supportdir  = "${featuredir}/${supportpath}"
  $hooksfile   = 'hooks.rb'
  $worldfile   = 'world.rb'
  $catalogpath = 'catalog'
  $catalogdir  = "${featuredir}/${catalogpath}"
  $policyfile  = 'policy.feature'
  $yamldir     = "${featuredir}/yaml"

  class { 'puppet::test::cucumber::install' : }
  class { 'puppet::test::cucumber::configure' : }
}

class puppet::test::cucumber::install {
  require ( 'ruby' )

  exec { 'install-cucumber-puppet' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'gem install rdoc && gem install cucumber-puppet',
    creates => '/usr/local/bin/cucumber-puppet',
    require => Class [ 'ruby' ],
  }
}

class puppet::test::cucumber::configure inherits puppet::params {
  file { [
    $puppet::test::cucumber::featuredir,
    $puppet::test::cucumber::catalogdir,
    $puppet::test::cucumber::supportdir,
    $puppet::test::cucumber::yamldir,
  ] :
    ensure  => directory,
    require => Class [ 'puppet', 'puppet::test::cucumber::install' ],
  }
  file { "${puppet::test::cucumber::supportdir}/${puppet::test::cucumber::hooksfile}" :
    ensure  => file,
    content => template ("puppet/test/${puppet::test::cucumber::supportpath}/${puppet::test::cucumber::hooksfile}.erb"),
    require => File [ $puppet::test::cucumber::supportdir ],
  }
  file { "${puppet::test::cucumber::supportdir}/${puppet::test::cucumber::worldfile}" :
    ensure  => file,
    content => template ("puppet/test/${puppet::test::cucumber::supportpath}/${puppet::test::cucumber::worldfile}.erb"),
    require => File [ $puppet::test::cucumber::supportdir ],
  }
  file { $puppet::test::cucumber::stepsdir :
    ensure  => directory,
    recurse => true,
    source  => "puppet:///modules/puppet/test/${puppet::test::cucumber::stepspath}",
    require => File [ $puppet::test::cucumber::featuredir ],
  }
  file { "${puppet::test::cucumber::catalogdir}/${puppet::test::cucumber::policyfile}" :
    ensure  => file,
    content => template ("puppet/test/${puppet::test::cucumber::catalogpath}/${puppet::test::cucumber::policyfile}.erb"),
    require => File [ $puppet::test::cucumber::catalogdir ],
  }
  file { "${puppet::test::cucumber::yamldir}/${::fqdn}.yaml" :
    ensure  => file,
    source  => "${puppet::params::yamldir}/node/${::fqdn}.yaml",
    require => File [ $puppet::test::cucumber::yamldir ],
  }
}

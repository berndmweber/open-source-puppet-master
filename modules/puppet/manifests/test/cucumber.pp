# == Class: puppet::test::cucumber
#
# This is the Puppet test class for cucumber-puppet.
#
# === Examples
#
#  class { puppet::test::cucumber : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
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

# == Class: puppet::test::cucumber::install
#
# This is the install class for cucumber-puppet installing the basic
# requirements for the cucumber-puppet gem
#
# === Examples
#
#  class { puppet::test::cucumber::install : }
#
class puppet::test::cucumber::install {
  require ( 'ruby' )

  exec { 'install-cucumber-puppet' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'gem install rdoc && gem install cucumber-puppet',
    creates => '/usr/local/bin/cucumber-puppet',
    require => Class [ 'ruby' ],
  }
}

# == Class: puppet::test::cucumber::configure
#
# This is the configuration class for cucumber-puppet. It configures the
# basic directories and files required for puppet testing via cucumber-puppet.
#
# === Examples
#
#  class { puppet::test::cucumber::configure : }
#
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

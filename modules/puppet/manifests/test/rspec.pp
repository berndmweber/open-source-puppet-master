# == Class: puppet::test::rspec
#
# This is the Puppet test class for rspec-puppet.
#
# === Examples
#
#  class { puppet::test::rspec : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 {Copper Frog LLC.}[copperfroghosting.com]
#
class puppet::test::rspec inherits puppet::params {
  class { 'puppet::test::rspec::install' : }
  class { 'puppet::test::rspec::configure' : }
}

# == Class: puppet::test::rspec
#
# This is the installation class for rspec-puppet. It installs the rspec-puppet
# gem packages necessary to run rspec tests.
#
# === Examples
#
#  class { puppet::test::rspec : }
#
class puppet::test::rspec::install {
  require ( 'ruby' )

  exec { 'install-rspec-puppet' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'gem install rdoc && gem install rspec-puppet puppetlabs_spec_helper',
    creates => '/usr/local/bin/rspec-puppet-init',
    require => Class [ 'ruby' ],
  }
}

class puppet::test::rspec::configure inherits puppet::params {
}

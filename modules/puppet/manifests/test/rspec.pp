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
# Bernd Weber <mailto:bernd@nvisionary.com>
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
    command => 'gem install rdoc && gem install rspec-puppet',
    creates => '/usr/local/bin/rspec-puppet-init',
    require => Class [ 'ruby' ],
  }
  exec { 'install-rspec-puppetlabs_spec_helper' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'gem install puppetlabs_spec_helper',
    unless => 'gem list --local | grep puppetlabs_spec_helper',
    require => Exec [ 'install-rspec-puppet' ],
  }
  exec { 'install-rspec-puppet-augeas' :
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => 'gem install rspec-puppet-augeas',
    unless => 'gem list --local | grep rspec-puppet-augeas',
    require => Exec [ 'install-rspec-puppetlabs_spec_helper' ],
  }
}

class puppet::test::rspec::configure inherits puppet::params {
}

# == Class: puppet::master::cloud_provisioner
#
# This is the Puppet Master class for the cloud_provisioner configuration.
#
# === Examples
#
#  class { puppet::master::cloud_provisioner : }
#
# === Authors
#
# Bernd Weber <mailto:bernd@nvisionary.com>
#
class puppet::master::cloud_provisioner inherits puppet::params {

  class { 'puppet::master::cloud_provisioner::install' : }
  class { 'puppet::master::cloud_provisioner::configure' :
    require           => Class [ 'puppet::master::cloud_provisioner::install' ],
  }
}

# == Class: puppet::master::cloud_provisioner::install
#
# This installs the cloud_provisioner requirements.
#
# === Examples
#
#  class { puppet::master::cloud_provisioner::install : }
#
class puppet::master::cloud_provisioner::install {
  Package {
    ensure   => present,
    provider => 'gem',
  }
  package { 'nokogiri' :
    ensure => '1.4.4',
  }
  package { 'fog' :
    ensure  => '0.7.2',
    require => Package [ 'nokogiri' ],
  }
  package { 'guid' : }
}

# == Class: puppet::master::cloud_provisioner::configure
#
# This configures the cloud_provisioner requirements.
#
# === Examples
#
#  class { puppet::master::cloud_provisioner::configure : }
#
class puppet::master::cloud_provisioner::configure {
  file { '/etc/profile.d/cloud_provisioner.sh' :
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "export RUBYLIB=${puppet::params::modulepath['production']}/cloud_provisioner/lib:\$RUBYLIB",
  }
}

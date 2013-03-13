# == Class: puppet::test
#
# This is the Puppet test class. It creates a puppet test environment.
#
# === Parameters
#
# [*type*]
#   Define the type of Puppet test to be installed.
#
#   Possible values include:
#   * 'cucumber' : cucumber-puppet ruby gem installation
#
# === Variables
#
# [*puppet_test_type*]
#   See parameter *type*
#
# === Examples
#
#  class { puppet::test : type => 'cucumber' }
#
# === Authors
#
# Bernd Weber <mailto:bernd@copperfroghosting.com>
#
# === Copyright
#
# Copyright 2013 {Copper Frog LLC.}[copperfroghosting.com]
#
class puppet::test (
  $type = 'cucumber',
) {
  if $::puppet_type != undef {
    $l_type = $::puppet_test_type
  } else {
    $l_type = $type
  }

  case $l_type {
    'cucumber' : {
      class { 'puppet::test::cucumber' : }
    }
  }
}

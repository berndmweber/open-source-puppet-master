  class { 'apache' : }
  class { 'ruby' : }
  class { 'puppet::master::apache' : }
  class { 'puppet::test' : type => 'cucumber' }

class puppet::master::dashboard::install {

}

class puppet::master::dashboard::configure {}

class puppet::master::dashboard {
  require ( 'puppet::params' )

  class { 'puppet::master::dashboard::install' : }
  class { 'puppet::master::dashboard::configure' : }
}

class puppet::install {
}

class puppet::configure {}

class puppet {
  class { "puppet::install" : }
  class { "puppet::configure" : }
}


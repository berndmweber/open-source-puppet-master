define puppet::master::module (
  $ensure,
  $contributer = 'puppetlabs',
  $ignore_dependencies = false,
) {
  require ( "puppet::params" )

  if $ignore_dependencies == true {
    $params = "--ignore-dependencies"
  }
  if $ensure == 'present' {
    exec { "install-${name}-module" :
      path => "/bin:/sbin:/usr/bin:/usr/sbin",
      command => "puppet module install ${contributer}/${name} ${params}",
      creates => "${puppet::params::modulepath['production']}/${name}",
      require => Class [ "puppet::configure" ],
    }
  }
}


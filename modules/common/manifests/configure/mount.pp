define common::configure::mount (
  $ensure = 'mounted',
  $device,
  $fstype,
  $options,
) {
  exec { "create-${name}" :
    cwd       => "/",
    path      => ['/usr/local/bin', '/usr/bin', '/bin'],
    logoutput => on_failure,
    command   => "mkdir -p ${name}",
    creates   => $name,
  }
  mount { $name:
    ensure  => $ensure,
    atboot  => true,
    device  => $device,
    fstype  => $fstype,
    options => $options,
    pass    => 0,
    dump    => 0,
    require => Exec [ "create-${name}" ],
  }
}

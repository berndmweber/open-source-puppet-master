define common::configure::host (
  $ensure       = present,
  $host         = $title,
  $host_aliases = [],
  $ip           = '127.0.0.1',
) {
  if $ip == 'localhost' {
    $ipaddress = '127.0.0.1'
  } else {
    $ipaddress = $ip
  }

  host { $host :
    ensure        => $ensure,
    host_aliases  => $host_aliases,
    ip            => $ip,
  }

# TODO: The ec2 facts still don't work within puppet.
#  if $::ec2_ami_id != undef {
    ec2host { $host :
      ensure        => $ensure,
      host_aliases  => $host_aliases,
      ip            => $ip,
    }
#  }
}

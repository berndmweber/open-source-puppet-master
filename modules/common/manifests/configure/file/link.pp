define common::configure::file::link (
  $source = $name,
  $target,
) {
  file { $source :
    ensure  => link,
    target  => $target,
  }
}

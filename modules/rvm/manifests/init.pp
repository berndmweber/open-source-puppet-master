class rvm(
  $version =        undef,
  $install_rvm =    true,
  $ruby_versions =  undef,
  $ruby_gemsets =   undef,
  $ruby_gems =      undef,
) {

  if $install_rvm {
    class { 'rvm::dependencies': }

    class { 'rvm::system':
      version => $version;
    }

    if $ruby_versions != undef {
      validate_hash ( $ruby_versions )
      create_resources ( 'rvm_system_ruby', $ruby_versions)
    }

    if $ruby_gemsets != undef {
      validate_hash ( $ruby_gemsets )
      create_resources ( 'rvm_gemset', $ruby_gemsets)
    }

    if $ruby_gems != undef {
      validate_hash ( $ruby_gems )
      create_resources ( 'rvm_gem', $ruby_gems)
    }

    # NOTE: This relationship is also handled by
    # Rvm::System/Exec['rvm::dependencies']
    Class['rvm::dependencies'] -> Class['rvm::system']
  }
}

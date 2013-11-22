class apache::mod::passenger (
  $passenger_high_performance     = undef,
  $passenger_pool_idle_time       = undef,
  $passenger_max_requests         = undef,
  $passenger_stat_throttle_rate   = undef,
  $passenger_max_pool_size        = undef,
  $passenger_enabled              = undef,
  $rack_autodetect                = undef,
  $rails_autodetect               = undef,
  $passenger_root                 = $apache::params::passenger_root,
  $passenger_ruby                 = $apache::params::passenger_ruby,
  $passenger_lib_path             = undef,
) {
  apache::mod { 'passenger':
    lib_path =>  $passenger_lib_path
  }
  # Template uses:
  # - $passenger_root
  # - $passenger_ruby
  # - $passenger_max_pool_size
  # - $passenger_high_performance
  # - $passenger_max_requests
  # - $passenger_stat_throttle_rate
  # - $rack_autodetect
  # - $rails_autodetect
  # - $passenger_enabled
  file { 'passenger.conf':
    ensure  => file,
    path    => "${apache::mod_dir}/passenger.conf",
    content => template('apache/mod/passenger.conf.erb'),
    require => Exec["mkdir ${apache::mod_dir}"],
    before  => File[$apache::mod_dir],
    notify  => Service['httpd'],
  }
}

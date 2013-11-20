define common::configure::download::file (
  $file_name          = $name,
  $url,
  $destination_path   = $common::package_source_dir,
  $download_provider  = 'curl',
  $unpack             = false,
  $unpack_destination = '/usr/local/share',
  $link_target        = 'UNSET',
  $sub_dir_to_copy    = 'UNSET',
  $copy_target        = 'UNSET',
  $owner              = 'root',
  $group              = 'root',
) {
  case $download_provider {
    'curl' : {
      $download_command = "curl -o ${file_name} ${url}/${file_name}"
    }
    'wget' : {
      $download_command = "wget ${url}/${file_name}"
    }
    default: {
      fail ("download-provider ${download_provider} not supported!")
    }
  }
  
  exec { "Downloading ${file_name} to ${destination_path}" :
    cwd     => $destination_path,
    path    => '/bin:/usr/bin:/usr/local/bin',
    command => $download_command,
    user    => 'root',
    group   => 'root',
    creates => "${destination_path}/${file_name}",
    require => Package [ 'curl' ],
  }

  if $unpack {
    $tmpSource = "${destination_path}/${file_name}"
    $extArray  = split($file_name, '\.')
    $ext       = $extArray[-1]
    $ext_full  = $extArray[-2]
  
    if $ext != $file_name {
      case $ext_full {
        'tar' : {
            $basename = inline_template ( "<%= File.basename('${file_name}', '.${ext_full}.${ext}') %>" )
        }
        default : {
            $basename = inline_template ( "<%= File.basename('${file_name}', '.${ext}') %>" )
        }
      }
    } else {
      $basename = $file_name
    }

    $tmpDestination = "${unpack_destination}/${basename}"

    case $ext {
      'bz2' : {
        $command = 'tar -xjf'
      }
      'tgz' : {
        $command = 'tar -xzf'
      }
      'gz' : {
        $command = 'tar -xzf'
      }
      'tar' : {
        $command = 'tar -xf'
      }
      default: {
        fail ( "Extension ${ext} not supported!" )
      }
    }

    exec { "Extracting ${file_name} to ${tmpDestination}" :
      cwd     => $unpack_destination,
      path    => '/bin:/usr/bin:/usr/local/bin',
      command => "${command} ${tmpSource}",
      user    => 'root',
      group   => 'root',
      creates => $tmpDestination,
      require => Exec [ "Downloading ${file_name} to ${destination_path}" ],
    }

    if $copy_target != 'UNSET' {
      if $sub_dir_to_copy != 'UNSET' {
        $copy_source = "${tmpDestination}/${sub_dir_to_copy}"
      } else {
        $copy_source = $tmpDestination
      }
      file { "Copying ${copy_source} to ${copy_target}" :
        path    => $copy_target,
        owner   => $owner,
        group   => $group,
        source  => $copy_source,
        recurse => true,
        replace => false,
        require => Exec [ "Extracting ${file_name} to ${tmpDestination}" ],
      }
    }
    if $link_target != 'UNSET' {
      file { "Linking ${basename} to ${link_target}" :
        ensure  => link,
        path    => $tmpDestination,
        owner   => $owner,
        group   => $group,
        target  => "${destination_path}/${link_target}",
        require => Exec [ "Extracting ${file_name} to ${tmpDestination}" ],
      }
    }
  }
}

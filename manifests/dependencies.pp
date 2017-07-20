/**
 * Setup our dependency graphs & resource defaults.
 */
class provision::dependencies  {

  # remove timeout (otherwise installing node_modules times out on Magento)
  Exec { timeout => 0 }

  if $::osfamily == 'Debian' {
    contain ::apt

    # ensure apt updated before every package
    Class['Apt::Update'] -> Package <| title != 'apt-transport-https'
                                       and title != 'ca-certificates' |>
  }

  $server = hiera_hash('server', {})
  $lamp   = hiera_hash('lamp', {})
  $nodejs = hiera_hash('nodejs', {})

  if (!empty($server['exec'])) {
    $server['exec'].each |$name,$val| {
      if (is_hash($val)) {
        $exec_name = $name
      } else {
        $exec_name = $val
      }

      Package['git'] -> Exec["server_exec_${exec_name}"]

      # ensure LAMP setup before Execs
      if (!empty($lamp)) {
        Class['Lamp'] -> Exec["server_exec_${exec_name}"]
      }

      # ensure Node.JS setup before Execs
      if (!empty($nodejs['modules'])) {
        $nodejs['modules'].each |$module| {
          Package[$module] -> Exec["server_exec_${exec_name}"]
        }
      }
      if (!empty($nodejs['install'])) {
        $nodejs['install'].each |$key,$val| {
          if (is_hash($val)) {
            Nodejs::Npm[$key] -> Exec["server_exec_${exec_name}"]
          } else {
            Nodejs::Npm[$val] -> Exec["server_exec_${exec_name}"]
          }
        }
      }
    }
  }

}

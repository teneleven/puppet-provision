/**
 * Setup our supervisord programs & refresh them when necessary.
 */
class provision::supervisor {

  # global supervisord setup for containers
  class { '::supervisord':
    install_pip    => true,
    install_init   => false,
    service_manage => false,
    executable_ctl => '/usr/bin/supervisorctl',
  }

  /* refresh supervisord for each program */
  Supervisord::Program <| |> -> exec { 'reload-supervisord':
    command => '/usr/bin/supervisorctl reload'
  }

  /* TODO disable services such as apache/fpm/nginx */
  /* TODO perhaps look into Puppet 4 + data-in-modules */

  if (defined(Class['lamp::server::apache'])) {
    Class['lamp::server::apache'] ~> supervisord::program { 'apache':
      command     => 'apache2ctl -DFOREGROUND',
      autorestart => true,
      killasgroup => true,
      stopasgroup => true,
    }
    Lamp::Vhost::Apache <| |> ~> Supervisord::Program['apache']
  } else {
    supervisord::program { 'apache':
      ensure  => absent,
      command => undef,
    }
  }

  if (defined(Class['lamp::server::nginx'])) {
    Class['lamp::server::nginx'] ~> supervisord::program { 'nginx':
      command     => 'nginx -g "daemon off;"',
      autorestart => true,
    }
    Lamp::Vhost::Nginx <| |> ~> Supervisord::Program['nginx']
  } else {
    supervisord::program { 'nginx':
      ensure  => absent,
      command => undef,
    }
  }

  if (defined(Class['lamp::php'])) {
    /* create symlink to php-fpm dependending on available FPM executable */
    Class['lamp::php'] ~> exec { "php-fpm-7-link":
      command => 'ln -s /usr/sbin/php-fpm7.0 /usr/sbin/php-fpm',
      onlyif  => 'test -x /usr/sbin/php-fpm7.0',
      unless  => 'test -e /usr/sbin/php-fpm',
      path    => ['/bin', '/usr/bin'],
    } ~> exec { "php-fpm-5-link":
      command => 'ln -s /usr/sbin/php5-fpm /usr/sbin/php-fpm',
      onlyif  => 'test -x /usr/sbin/php5-fpm',
      unless  => 'test -x /usr/sbin/php-fpm7.0 || test -e /usr/sbin/php-fpm',
      path    => ['/bin', '/usr/bin'],
    } ~> exec { "mk-var-run-php":
      command => 'mkdir -p /var/run/php',
      unless  => 'test -d /var/run/php',
      path    => ['/bin', '/usr/bin'],
    }

    Class['lamp::php'] ~> supervisord::program { 'fpm':
      command     => 'php-fpm -F',
      autorestart => true,
    }
    Php::Extension <| |> ~> Supervisord::Program['fpm']
  } else {
    supervisord::program { 'fpm':
      ensure  => absent,
      command => undef,
    }
  }

}

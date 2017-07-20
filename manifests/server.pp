/**
 * Provision our basic server configuration.
 */
class provision::server {

  Service { provider => 'base' }

  $server = hiera_hash('server', {})

  if (empty($server['packages'])) {
    $server_packages = ['git']
  } elsif (is_array($server['packages'])) {
    $server_packages = unique(concat($server['packages'], 'git'))
  } elsif (is_hash($server['packages'])) {
    $server_packages = merge({ 'git' => {} }, $server['packages'])
  }

  # provision server
  if (!empty($server)) {
    create_resources('class', { '::server' => merge({ 'packages' => $server_packages }, $server) })
  }

}

class provision::nodejs (
  $modules = [],
  $install = [],
) {

  contain ::nodejs

  package { $modules:
    provider => npm
  }

  $install.each |$key,$val| {
    if (is_hash($val)) {
      create_resources('nodejs::npm', { $key => $val })
    } else {
      nodejs::npm { $val:
        target => $val
      }
    }
  }

}

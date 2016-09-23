class wordpress_app::web_profile {
  class {'apache':
    default_vhost => false,
    mpm_module    => 'prefork',
  }

  include apache::mod::prefork
  include apache::mod::php
  include wordpress_app::ruby
  include mysql::client
  include mysql::bindings
  include mysql::bindings::php

  package {'wget':
    ensure => 'present'
  }
}

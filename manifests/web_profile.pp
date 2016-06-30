class wordpress_app::web_profile {
  class {'apache':
    default_vhost => false,
  }
  include apache::mod::php
  include wordpress_app::ruby
  include mysql::client
  include mysql::bindings
  include mysql::bindings::php

  package {'wget':
    ensure => 'present'
  }
}

class wordpress_app::web_profile(
  $manage_selinux = true,
){
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
  if $manage_selinux {
    # selinux needs to be configured for wordpress and for this example,
    # jfryman/selinux is used to disable it on the web component nodes
    class { selinux:
      mode => 'disabled',
    }
  }
}

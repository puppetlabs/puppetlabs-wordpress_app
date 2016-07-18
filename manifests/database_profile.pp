class wordpress_app::database_profile (
  String $bind_address = '0.0.0.0',
) {
  class { 'mysql::server':
    override_options => {
      'mysqld'       => {
        'bind_address' => '0.0.0.0',
        'port'         => '3306',
      },
    },
  }
  firewall { '3306 allow apache-mysql':
    dport  => ['3306'],
    proto  => tcp,
    action => accept,
  }
}

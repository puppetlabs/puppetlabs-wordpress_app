define wordpress_app::database(
  String $database = 'wordpress',
  String $user     = 'wordpress',
  String $password = 'wordpress',
){
  include wordpress_app::database_profile
  $user_host = "${user}@%"

  mysql_database { $database:
    name    => $database,
    charset => 'utf8',
    require => Class[Mysql::Server],
  } ->

  mysql_user { $user_host:
    ensure        => 'present',
    password_hash => mysql_password($password),
  } ->

  mysql_grant { "${user_host}/${database}.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => "${database}.*",
    user       => $user_host,
  } ->
  mysql_user { "${user}@localhost":
    ensure        => 'present',
    password_hash => mysql_password($password),
  } ->
  mysql_grant { "${user}@localhost/${database}.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => "${database}.*",
    user       => "${user}@localhost",
  }
}
Wordpress_app::Database produces Database {
  host     => $::fqdn,
  port     => '3306',
  provider => 'tcp',
}

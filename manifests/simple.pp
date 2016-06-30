application wordpress_app::simple(
  String $database = 'wordpress',
  String $db_user  = 'wordpress',
  String $db_pass  = 'wordpress',
  String $web_port = '8080',
  String $lb_port  = '80',
) {
  wordpress_app::database { $name:
    database => $database,
    user     => $db_user,
    password => $db_pass,
    export   => Database["db-${name}"]
  }
  wordpress_app::web { $name:
    apache_port => $web_port,
    export      => Http["web-${name}"],
    consume     => Database["db-${name}"],
  }
  wordpress_app::lb { $name:
    balancermembers => [Http["web-${name}"]],
    port            => $lb_port,
    require         => Http["web-${name}"],
    export          => Http["lb-${name}"],
  }
}

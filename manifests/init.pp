application wordpress_app (
  String $database        = 'wordpress',
  String $db_user         = 'wordpress',
  String $db_pass         = 'wordpress',
  String $web_int         = '',
  String $web_port        = '8080',
  String $lb_ipaddress    = '0.0.0.0',
  String $lb_port         = '80',
  String $lb_balance_mode = 'roundrobin',
  Array  $lb_options      = ['forwardfor','http-server-close','httplog'],
){
  $db_components = collect_component_titles($nodes, Wordpress_app::Database)
  if (size($db_components) != 1) {
    $db_size = size($db_components)
    fail("There must be one database component for wordpress_app. found: ${db_size}")
  }
  wordpress_app::database { $db_components[0]:
    database => $database,
    user     => $db_user,
    password => $db_pass,
    export   => Database["wdp-${name}"]
  }

  # Collect the titles of all Web components declared in nodes.
  $web_components = collect_component_titles($nodes, Wordpress_app::Web)
  # Verify there is at least one web.
  if (size($web_components) == 0) {
    fail("Found no web component for Wordpress_app[${name}]. At least one is required")
  }
  # For each of these declare the component and create an array of the exported
  # Http resources from them for the load balancer.
  $web_https = $web_components.map |$comp_name| {
    # Compute the Http resource title for export and return.
    $http = Http["web-${comp_name}"]
    # Declare the web component.
    wordpress_app::web { $comp_name:
      apache_port => $web_port,
      interface   => $web_int,
      consume     => Database["wdp-${name}"],
      export      => $http,
    }
    # Return the $http resource for the array.
    $http
  }

  # Create an lb component for each declared load balancer.
  $lb_components = collect_component_titles($nodes, Wordpress_app::Lb)
  $lb_components.each |$comp_name| {
    wordpress_app::lb { $comp_name:
      balancermembers => $web_https,
      lb_options      => $lb_options,
      ipaddress       => $lb_ipaddress,
      port            => $lb_port,
      balance_mode    => $lb_balance_mode,
      require         => $web_https,
      export          => Http["lb-${comp_name}"],
    }
  }
}

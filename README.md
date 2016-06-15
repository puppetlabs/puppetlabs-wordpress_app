# wordpress_app

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with wordpress_app](#setup)
    * [What [modulename] affects](#what-[modulename]-affects)
        * [Setup requirements](#setup-requirements)
            * [Beginning with [modulename]](#beginning-with-[modulename])
            3. [Usage - Configuration options and additional functionality](#usage)
            4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
            5. [Limitations - OS compatibility, etc.](#limitations)
            6. [Development - Guide for contributing to the module](#development)

## Description

The Puppet wordpress_app is a module that demonstrates example application module. The module contains application components you can use to  to set up a WordPress database, a PHP application server, and an HAProxy load balancer. With these components, you can build two WordPress applications: a simple LAMP stack or a stack that uses complex load-balancing.

## Setup

### Setup Requirements

To use this module, you must enable application management on the Puppet master. If you've already installed PE, you can [enable this setting via the console](./orchestrator_install.html#enable-the-application-orchestration-service-and-orchestrator-client) or by adding  `app_management = true` to the `puppet.conf` file on your Puppet master. You also need to enable plug in sync on any agents you want to use to host application components.

The [Puppet orchestrator documentation](./orchestrator_intro.html) provides commands and API endpoints you can use to deploy the wordpress_app. 

### Getting started with wordpress_app

The most basic use of the wordpress_app module is to install Wordpress on a single node. For example, you can add the application declaration to your `site.pp`:

```puppet
  wordpress_app::simple { 'all_in_one':
    nodes => {
      Node['kermit-1.example.com'] => [
        Wordpress_app::Database['all_in_one'],
        Wordpress_app::Web['all_in_one'],
      ]
    }
  }
```

After deploying this application, you can access it at `http://kermit-1.example.com`.

## Patterns

### `wordpress_app::simple`

This is a simple Wordpress application model. The three components are defined statically in the application definition with their names expected to match the name of the application. The database component produces a database resource. The web component consumes that database resource, and produces an HTTP resource. The load balancer component consumes this HTTP resource.

You should use this style of declaration if every instance of the application has the same components. Such declarations make it easier to assign components to a single node or to spread them across multiple nodes in different instances.

### `wordpress_app`

This is a more complex application definition. It uses functions to dynamically discover what components have been declared, and then it validates and connects them. You should use this type of definition if you have a varying number of components, or if some components are optional. By discovering the component names dynamically, you don't have to worry about matching statically declared component names. 

In the following example, the `collect_component_titles` function searches through the applications nodes and finds all resources matching a certain component type and returns a list of their titles. In the previous example case, the function verifies that there is one database, and it then declares that resource. Since the name of the exported database capability resource is set for internal consumption, you shouldn't have to track the name.

```puppet
  $db_components = collect_component_titles($nodes, Wordpress_app::Database)
  if (size($db_components) != 1){
    $db_size = size($db_components)
    fail("There must be one database component for wordpress_app. found: ${db_size}")
  }
  wordpress_app::database { $db_components[0]:
    database   => $database,
    user       => $db_user,
    password   => $db_pass,
    export     => Database["wdp-${name}"]
  }
```
For the web components, the function collects all resources assigned to nodes in the application. The map function loops over the resources and declares the components, and it then collects the HTTP resources they export for later consumption. This allows you to declare one or more web components to scale their application dynamically through the declaration.

For example:

```puppet
  $web_components = collect_component_titles($nodes, Wordpress_app::Web)
  # Verify there is at least one web.
  if (size($web_components) == 0) {
    fail("Found no web component for Wordpress_app[${name}]. At least one is required")
  }
  # For each of these declare the component and create an array of the exported
  # Http resources from them for the load balancer.
  $web_https = $web_components.map |$comp_name| {
    # Compute the Http resource title for export and return.
    $http = Http["web-$comp_name"]
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
```

The load balancer component of the application is optional and you may have any number of instances of it. In some cases you may have no need for a load balancer, or you may require several in a high availability configurations. Each load balancer requires the `web-https` resources exported by the web components to ensure ordering. The `web-https` resources are also passed in via the `balancermembers` parameter. This allows the load balancer to collect an number of HTTP resources.

For example:

```puppet
  $lb_components = collect_component_titles($nodes, Wordpress_app::Lb)
  $lb_components.each |$comp_name| {
    wordpress_app::lb { $comp_name:
      balancermembers => $web_https,
      lb_options      => $lb_options,
      ipaddress       => $lb_listen_ip,
      port            => $lb_listen_port,
      balance_mode    => $lb_balance_mode,
      require         => $web_https,
      export          => Http["lb-${name}"],
    }
  }
```


The following example, shows a declaration of an instance of the WordPress application with two web nodes and a single load balancer. The resource titles used here are arbitrary, but they must be unique in this environment.

```puppet
  wordpress_app { 'tiered':
    nodes => {
      # The titles of these don't matter as long as they're unique per component
      Node['kermit-1.example.com'] => Wordpress_app::Database['wordpress-db'],
      Node['kermit-2.example.com'] => Wordpress_app::Lb['tiered'],
      Node['kermit-3.example.com'] => Wordpress_app::Web['tiered-web01'],
      Node['kermit-4.example.com'] => Wordpress_app::Web['wordpress-web02'],
    }
  }
```

### Components vs Profiles

If you are already organizing your code into roles and profiles, the application components are probably very similiar to your profiles. If
all your nodes serve a single purpose, you may be able to just convert your profile classes into component defined types. However, if you need to put multiple components on a single node that share resources, this may resut in conflicts. For example if you have one database node that provides databases for multiple WordPress application instances,  MySQL Puppet resources may be shared. Or, if you have multiple HTTP components in your stack, Apache resources might be shared. If this is the case, you should turn the components into profile classes that can then be included in the component. Consider `wordpress_app:database` and `workpress_app::database_profile`: the underlying MySQL server and firewall rules are configured in the profile while the specific datbase, user, and permissions are managed in the component.

## Reference

### Applications

#### `wordpress_app::simple`

This is a simple WordPress application.

##### Components

* `Wordpress_app::Database[$name]`
* `Wordpress_app::Web[$name]`
   - consumes from Database
* `Wordpress_app::Lb[$name]`
   - consumes from Web

##### Parameters

* `database` - The database name to use (default 'wordpress')
* `db_user` - The database user for the application (default: 'wordpress')
* `db_pass` - The password for the database (default: wordpress)
* `web_port` - the port the webserver should listen on (default: '8080')
* `lb_port` - the port ha proxy should listen on when load balancing (default: '80')


#### `wordpress_app`

This is a more complex WordPress application with the following components. Use of the collect component titles function means that the names of the components don't matter as long as they are unique per component through the environment.

##### Components

* `Wordpress_app::Database[.*]`
   - There must be one of these
* `Wordpress_app::Web[.*]`
   - There must be one or more of these.
   - consumes from Database
* `Wordpress_app::Lb[.*]`
   - There may be any number of LB components
   - each consumes all Web components

###### Parameters

* `database` - The database name to use (default 'wordpress')
* `db_user` - The database user for the application (default: 'wordpress')
* `db_pass` - The password for the database (default: wordpress)
* `web_int` - the interface the webserver should listen on.
* `web_port`: the port the webserver should listen on (default: '80')
* `lb_ipaddress` - The ip the load balancer will listen on(default: '0.0.0.0')
* `lb_port` - The port the load balancer will listen on (default: '8080')
* `lb_balance_mode` - The loadbalancer mode to use (default: 'roundrobin')
* `lb_options` - the haproxy options to pass (default: ['forwardfor','http-server-close','httplog'] )

### Component Types

#### `word_press_app::database`

##### Capabilities

- Produces a `Database` capabality resource for the mysql database

##### Parameters

* `database` - the database name for this WordPress application (default: 'wordpress')
* `user` - the user WordPress should connect to the database as (default: 'wordpress')
* `password` - the password WordPress should connect to the database as (default: 'wordpress')


#### `wordpress_app::web`

Manages WordPress and apache

##### Capabilities

- Consumes Database for mysql database
- Produces Http for WordPress

##### Parameters

* `db_host` - the database host
* `db_port` - the database port
* `db_name` - the database name
* `db_user` - the database user
* `db_password` - the database password
* `apache_port` - The apache port WordPress should listen on
* `interface` - The interface apache should listen on

#### `wordpress::lb`

Application component to manage haproxy load balancing.

##### Capabilities

- Consumes `Array [Http]` for WordPress nodes
- Produces `Http` of haproxy

##### Parameters

* `balancermembers` - Array of `Http` resources of WordPress nodes to loadbalance
* `lb_options` - Array of options to pass to haproxy (default: ['forwardfor', 'http-server-close', 'httplog'])
* `balance_mode` - load balancing mode to use (default: 'roundrobin')
* `ipaddress` - ipaddress for haproxy to listen on (default: '0.0.0.0)
* `port` - port for haproxy to listen on (default: '80')

### Classes

#### `wordpress_app::ruby`

Manages ruby package for puppetlabs-concat. Set manage to false if you are managing the ruby package elsewhere.

##### Parameters

* `manage` - Should this manage the ruby package (default: true)

#### `wordpress_app::database_profile`

Manages the mysql server and firewall rules

##### Parameters

* `bind_address` - the address mysql should listen on (default: '0.0.0.0')

#### `wordpress_app::web_profile`

Manages apache, selinux, mysql client libraries and wget for wordpress.

##### Parameters

* `manage_selinux` - Should this manage selinux and disable it (default: true)

none

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

Wordpress_app an example application modeling module. It has
application components for setting up a wordpress database, php app server and
HAproxy load balancer. These are used to build two wordpress applications a
simple LAMP stack and more complex load balanced version.


## Setup

### Setup Requirements

In order to use this module you will need the `app_management` setting on on your puppet master and plugin sync enable on the agents.

### Beginning with wordpress_app

The simplest use of wordpress app is to install wordpress on a single node. To do add an application declaration to your site.pp like:

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

After deploying this application you should be able to access wordpress at
`http://kermit-1.example.com`.

## Patterns

### `wordpress_app::simple`

This is a simple wordpress application model. The three components are defined
staticly in the application definition with their name expected to match the
applications. The ddatbase component produces a database resource, the web
component consumes that resource and produces and Http resource which in turn
is consumed by the Lb. component.

This style of declaration works well if every instance of the application has
the same components. It makes it easier to assign components to a single node
or spread them across multiple nodes in different instances.

### `wordpress_app`

This is a more complex application definition. It uses functions to dynamically
discover what components have been declared, validate them and wire them
together. This type of definition works well when there may be a varying number
of components or some components are optional. By discovering the compontent
names dynamically the user doesn't have to worry about matching staticly
declared component names.

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

The `collect_component_titles` function searches through the applications nodes
and finds all resources matching a certain component type and returns a list of
their titles. In this case we verify that there is one and only one database
and then declare that resource. The name of the exported Database capability
resource is set for internal consumption the user shouldn't have to know it.

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

For the web components we collect all resources assigned to nodes in the
application. We then use the map function to loop over them declaring the
components and collecting the Http resources they export for later consumption.
This allows the user to declare one or more web components to scale their
application dynamically through the declaration.

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

The load balancer component for the application is optional and their may be
any number of instances of it. This allows users to not use a load balancer in
instances of the application where one isn't necessary or use multiple load
balancers if required for availability. Each load balancer requires the
web-http resources exported by the webs to ensure ordering and also passes
those resources in via the `balancermembers` parameter. This allows the load
balancer to collect an number of Http resources.


The following declares an instance of the wordpress application with two web
nodes and a single load balancer. Note that the resource titles used here are
arbitrary but much be unique in this environment.

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

If you are already organizing your code into roles and profiles the application
components are probably very similiar to your profiles. If all your nodes serve
a single purpose you may be able to just convert your profile classes into
component defined types. If you need to put multiple components on a single
node that share resources this may resut in conflicts.  For example if you have
one database node that provide datbases for multiple wordpress application
instances mysql puppet resources may be shared or if you had multiple http
components in your stack apache resources might be shared. In this case the
shared resources should be factored out of the components into profile classes
which can then be included in the component. An example of this is
`wordpress_app:database` and `workpress_app::database_profile`. The underlying
mysql server and firewall rules are configured in the profile while the
specific datbase, user, and permissions are managed in the component.

## Reference

### Applications

#### `wordpress_app::simple`

This is a simple wordpress application.

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

This is a more complex wordpress application with the following components. Use of the collect component titles function means that the names of the components don't matter as long as they are unique per component through the environment.

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

* `database` - the database name for this wordpress application (default: 'wordpress')
* `user` - the user wordpress should connect to the database as (default: 'wordpress')
* `password` - the password wordpress should connect to the database as (default: 'wordpress')


#### `wordpress_app::web`

Manages wordpress and apache

##### Capabilities

- Consumes Database for mysql database
- Produces Http for wordpress

##### Parameters

* `db_host` - the database host
* `db_port` - the database port
* `db_name` - the database name
* `db_user` - the database user
* `db_password` - the database password
* `apache_port` - The apache port wordpress should listen on
* `interface` - The interface apache should listen on

#### `wordpress::lb`

Application component to manage haproxy load balancing.

##### Capabilities

- Consumes `Array [Http]` for wordpress nodes
- Produces `Http` of haproxy

##### Parameters

* `balancermembers` - Array of `Http` resources of wordpress nodes to loadbalance
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

# chef_eye

Cookbook for setup [eye](https://github.com/kostya/eye) service and applications

## Supported Platforms

* Ubuntu 12.04
* Ubuntu 14.04

## Attributes


| Key | Type | Description | Default |
|-----|------|-------------|---------|
| chef_eye.eye_bin | String  |  Path to eye executable file | /usr/local/bin/eye |
| chef_eye.leye_bin | String  |  Path to local eye executable file | /usr/local/bin/leye |
| chef_eye.services | Hash or Array  |  Array of users or Hash with users as keys and service options as value | ['root'] | 
| chef_eye.applications | Hash  | Applications configurations | {} | 
| chef_eye.install_ruby | Boolean  | Try to install ruby packages `ruby`, `ruby-dev`. If you want to install ruby using another way, you should set this value to `false` | true | 


## Usage

This cookbook provides two strategies. "Eye" per user and "eye" per project (local eye).
First strategy run one eye daemon for all configurations and load it.

Eye per user file structure:

    /etc/init.d/eye_vagrant # Eye service for user vagrant (generated by chef_eye::service recipe)
    /etc/eye/vagrant/_config.eye # Main service configuration (generated by chef_eye::service recipe)
    /etc/eye/vagrant/application1.eye # Application config (generated by chef_eye_application lwrp)
    /etc/eye/vagrant/application2.eye
    /etc/eye/vagrant/*.eye



Eye per project (local eye) file structure (generated by `chef_eye_application_local` lwrp):

    /etc/init.d/leye_application1
    /var/www/application1/.eye # Eye home
    /var/www/application1/.eye/Eyefile # Local eye configuration
    /var/www/application1/.eye/leye # Wrapper for leye with environment variables
    /var/www/application1/.eye/sock
    /var/www/application1/.eye/pid

## Recipes

### chef_eye::default

Include `chef_eye` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[chef_eye::default]"
  ]
}
```

### chef_eye::ruby

Cookbook used system ruby and try to install `ruby`, `ruby-dev` packages if `node['chef_eye']['install_ruby']` set to `true`
If  you want to use custom system ruby, you need set `node['chef_eye']['install_ruby']` to `false` and install custom ruby before
before this cookbook. For example, if you want to use `uid` and `gid` [application options](https://github.com/kostya/eye/issues/50),
you need install ruby 2.0.0 as system ruby. Its installation is your concern.

## chef_eye::service

This recipe generate service for eye daemons per users

Services named by `eye_` prefix and username. For example, service for user vagrant, well be named as `eye_vagrant`, service for user root as `eye_root`, etc.

If you need to reload service for user `vagrant`, you can use

    some_resource do
      ...
      notifies :reload, 'service[eye_vagrant]'
    end

if you want to configure service fore some user, you can setup it

    default['chef_eye']['services'] = {
      ubuntu: {
        'logger' => '/var/log/eye/ubuntu.log'
        'mail' => {
          'host' => 'mx.some.host',
          'port' => 25,
          'domain' => 'some.host'
        },
        contacts: {
          'errors' => {
            'type' => 'mail',
            'contact' => 'error@some.host'
          },
          'dev' => {
            'type' => 'mail',
            'contact' => 'error@some.host',
            'opts' => {}
          },
        }
      }
    }

### chef_eye::applications

This service generate `chef_eye_application` or `chef_eye_application_local` LWRP's using `node['chef_eye']['applications']` attributes. 
You can use any valid eye [options](https://github.com/kostya/eye/tree/master/examples). For example:

    default['chef_eye']['applications']['my_app'] = {
      owner: 'vagrant', # required
      group: 'vagrant',
      working_dir: '/var/www/my_app',
      checks: {
        cpu: {
          :every => 30,
          :below => 80,
          :times => 3
        },
        memory:{
          :every => 30,
          :below => 73400320,
          :times => [ 3, 5 ]
        }
      },
      process: {
        unicorn: {
          daemonize:  true,
          pid_file: 'puma.pid',
          stdall: 'puma.log',
          start_command: 'bundle exec puma --port 33280 --environment production Config.ru',
          stop_signals: ['TERM', 5, 'KILL']
        },
        resque: {
          pid_file: 'tmp/pids/resque.pid',
          start_command: 'bin/resque work --queue=high',
          checks: {
            cpu: {
              :every => 30,
              :below => 80,
              :times => 3
            }
          }
        }
      }
    }

This cookbook will install the eye service for user 'vagrant' (`/etc/init.d/eye_vagrant`) and generate valid '.eye' configuration file
(`/etc/eye/vagrant/my_app.eye`).

Application used local eye version have additional attributes.


      {
        type: 'local' # <- Configure application using leye
        eye_home: '/var/www/my_app/shared/.eye', #eye home, default eye_home = working_dir
        eye_config: {}, # leye daemon configuration
        eye_pid: 'pid', # absolute or relative path to pidfile
        eye_socket:'sock', # absolute or relative path to socket

        owner: 'vagrant', # required
        group: 'vagrant',
        working_dir: '/var/www/my_app',
        ....
      }

## LWRP

### chef_eye_application

#### Attributes:

|  Name       |  Type  | Description  |  Default Value |
|-------------|--------|--------------|----------------|
|  owner      | String | Username. This is required attribute |    None, *required*    |
|  config     | Hash or Block | Application configuration, see example    |    None, *required*  |
|  group      | String | Group    |     |
|  cookbook   | String | Cookbook name for searching templates    | "chef_eye"    |
|  helper   | TrueClass,FalseClass | This flag enable creation of helper script     | true    |
|  helper_prefix   | String, NilClass | Prefix of helper script    | nil    |


Cookbook provide `chef_eye_application` resource. This is a main resource for generate eye configuration.

    chef_eye_application 'name_of_my_app' do
      owner 'ubuntu'
      group 'ubuntu'
      working_dir '/var/www/my_app'
      config do
        env 'RAILS_ENV' => 'production'
        working_dir '/var/www/my_app'
        trigger :flapping, :times => 10, :within => 1.minute
        process :puma do
          daemonize true
          pid_file "puma.pid"
          stdall "puma.log"
          start_command "bundle exec puma --port 33280 --environment production thin.ru"
          stop_signals [:TERM, 5.seconds, :KILL]
          restart_command "kill -USR2 {PID}"
          restart_grace 10.seconds
          check :cpu, :every => 30, :below => 80, :times => 3
          check :memory, :every => 30, :below => 70.megabytes, :times => [3,5]
        end
      end
      action :configure # or :delete
      notifies :reload, 'service[eye_ubuntu]' # you need notify service for reload
    end

or as hash

    chef_eye_application 'name_of_my_app' do
      owner 'ubuntu'
      group 'ubuntu'
      config({
          env: {
            RAILS_ENV: 'production'
          },
          working_dir: '/var/www/my_app',
          triggers: {
            flapping: {
              :times => 10,
              :within => 1.minute
            }
          },
          processes: {
            puma: {
              daemonize: true,
              pid_file: "puma.pid",
              stdall: "puma.log",
              start_command: "bundle exec puma --port 33280 --environment production thin.ru",
              stop_signals: [:TERM, 5.seconds, :KILL],
              restart_command: "kill -USR2 {PID}",
              restart_grace: 10.seconds,
              checks: {
                cpu: {:every => 30, :below => 80, :times => 3},
                memory: {:every => 30, :below => 70.megabytes, :times => [3, 5]}
              }
            }
          }
        })
      action :configure # or :delete
      notifies :reload, 'service[eye_ubuntu]' # you need notify service for reload
    end

### chef_eye_application_local

This lwrp generate config for leye and create init.d service for local eye daemon.
Configuration for application writes to Eyefile.

#### Attributes:


|  Name       |  Type  | Description  |  Default Value |
|-------------|--------|--------------|----------------|
|  owner      | String | Username. This is required attribute |    None, *required*    |
|  config     | Hash or Block | Application configuration, see example    |    None, *required*  |
|  group      | String | Group    |     |
|  cookbook   | String | Cookbook name for searching templates    | "chef_eye"    |
|  eye_config     | Hash or Block | leye daemon configuration     |    nil  |
|  eye_home   | String |               |  woring_dir              |
|  eye_file   | String |  Name or path to Eyefile | "Eyefile"                |
|  eye_pid    | String |  Name or path to pidfile  | "pid"               |
|  eye_socket | String |  Name or path to eye socket | "sock"                |
|  log_file   | String |  Relative or absolute path to logfile | "/var/log/eye/**owner**/eye.log" |


### Helpers

`chef_eye_application` resource have `helper` (String) and `helper_prefix` (String, default: owner name) attributes. If helper is true, resource will generate `/usr/local/sbin/<prefix>_<application_name>` executable scripts. By default for `my_app` helper is `/usr/local/sbin/vagrant_my_app`. This script run all command only for `my_app` namespace. `chef_eye_application_local` have helper too. For `my_app` this helper will be named like  `/usr/local/sbin/leye_my_app` but this is symlink to `leye` wrapper from `<eye_home>/leye`

## License and Authors

Author:: Nikolay Murga (nikolay.m@randrmusic.com)



# chef_eye

Cookbook for setup [eye](https://github.com/kostya/eye) service and applications

## Supported Platforms

* Ubuntu 12.04
* Ubuntu 14.04

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['chef_eye']['services']</tt></td>
    <td>Hash or Array</td>
    <td>Array of users or Hash with users as keys and service options as value</td>
    <td><tt>['root']</tt></td>
  </tr>
  <tr>
    <td><tt>['chef_eye']['applications']</tt></td>
    <td>Hash</td>
    <td>Applications configurations</td>
    <td><tt>{}</tt></td>
  </tr>
</table>

## Usage

You can use any valid eye [options](https://github.com/kostya/eye/tree/master/examples). For example:

    default['eye']['applications']['my_app'] = {
      owner: 'vagrant', # required
      group: 'vagrant',
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


##Service

Services named by `eye_` prefix and username. For example, service for user vagrant, well be named as `eye_vagrant`.
service for user root as `eye_root`, etc.

If you need to reload service for user `vagrant`, you can use

    some_resource do
      ...
      notifies :reload, 'service[eye_vagrant]'
    end

## LWRP

### chef_eye_application

Cookbook provide `chef_eye_application` resource. This is a main resource for generate eye configuration.

    chef_eye_application 'name_of_my_app' do
      owner 'ubuntu'
      group 'ubuntu'
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


#### Important! If you use LWRP, you need to add owner of application to `node['eye']['services']` attribute manually.


### chef-eye::default

Include `chef_eye` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[chef_eye::default]"
  ]
}
```

## License and Authors

Author:: Nikolay Murga (nikolay.m@randrmusic.com)



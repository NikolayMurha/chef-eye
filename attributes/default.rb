default['chef_eye']['bin'] = '/usr/local/bin/eye'
default['chef_eye']['version'] = '0.6.3'
default['chef_eye']['install_ruby'] = true
default['chef_eye']['services'] = ['root']

default['chef_eye']['applications'] = {}


default['chef_eye']['services'] = [ 'root' ]

default['chef_eye']['applications']['tmm'] = {
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

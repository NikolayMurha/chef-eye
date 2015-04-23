include_recipe 'chef_eye::default'
include_recipe 'chef_eye::eye'

module Test
  class << self
    attr_accessor :app

    def test
      sleep 5
      puts '************* Start test resource'
      puts '************* Stop Action'
      app.run_action(:stop)
      sleep 10
      puts '************* Start Action'
      app.run_action(:start)
      sleep 10
      puts '************* Restart Action'
      app.run_action(:restart)
      sleep 10
      puts '************* Delete Action'
      app.run_action(:delete)
      puts '************* Test completed'
    end
  end
end

b = ruby_block 'test_resource' do
  block do
    Test.test
  end
  action :nothing
  notifies :restart, 'chef_eye_service[eye_vagrant]'
end

chef_eye_application 'rails_sample2' do
  owner 'vagrant'
  group 'vagrant'
  config do
    working_dir '/var/www/rails_sample2/current'
    process 'unicorn' do
      pid_file 'tmp/pids/unicorn.pid'
      stdall 'log/eye.log'
      start_command '/home/vagrant/.rvm/bin/rvm ruby-2.0.0-p643@rails-base do bundle exec unicorn_rails -D -E development -c config/unicorn.rb'
      stop_signals [:TERM, 10.seconds, :KILL]
      start_timeout 10
      restart_grace 10
      restart_command 'kill -USR2 {PID}'
      monitor_children do
        stop_command 'kill -QUIT {PID}'
        check :cpu, :every => 30, :below => 80, :times => 3
        check :memory, :every => 30, :below => 150.megabytes, :times => [3, 5]
      end
    end
  end
  notifies :restart, 'chef_eye_service[eye_vagrant]'
  action [:configure]
end

app = chef_eye_application 'rails_sample' do
  owner 'vagrant'
  group 'vagrant'
  config({
      working_dir: '/var/www/rails_sample/current',
      process: {
        'unicorn' => {
          'pid_file' => 'tmp/pids/unicorn.pid',
          'stdall' => 'log/eye.log',
          'start_command' => "/home/vagrant/.rvm/bin/rvm ruby-2.0.0-p643@rails-base do bundle exec unicorn_rails -D -E development -c config/unicorn.rb",
          'stop_signals' => [
            'TERM',
            5,
            'KILL'
          ],
          'start_timeout' => 10,
          'restart_grace' => 10,
          'restart_command' => 'kill -USR2 {PID}',
          'monitor_children' => {
            'stop_command' => 'kill -QUIT {PID}',
            'check' => {
              'cpu' => {
                'every' => 30,
                'below' => 80,
                'times' => 30
              },
              'memory' => {
                'every' => 30,
                'below' => 157286400,
                'times' => [
                  3,
                  5
                ]
              }
            }
          }
        }
      }
    })
  action [:configure]
  notifies :restart, 'chef_eye_service[eye_vagrant]'
  notifies :run, b
end

Test.app = app

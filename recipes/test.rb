node.default['chef_eye']['services'].push('ubuntu')

%w(vagrant ubuntu).each do |user|
  user user do
    system true
    home "/home/#{user}"
    shell '/bin/bash'
    supports manage_home: true
  end
end


include_recipe 'chef_eye::default'
include_recipe 'chef_eye::eye'

#cretae applications
package 'nodejs-legacy'
package 'git'
package 'curl'
class EyeTest
  attr_accessor :resource
  def run
    sleep 5
    puts "************* Test resource #{resource.name}"
    puts "************* Stop Action for #{resource.name}"
    resource.run_action(:stop)
    sleep 5
    puts "************* Start Action for #{resource.name}"
    resource.run_action(:start)
    sleep 5
    puts "************* Restart Action for #{resource.name}"
    resource.run_action(:restart)
    sleep 5
    # puts "************* Delete Action for #{resource.name}"
    # resource.run_action(:delete)
    puts "************* Test completed for #{resource.name}"
  end
end

%w(vagrant ubuntu).each do |user|

  rvm = ruby_rvm user do
    rubies '2.0.0'
  end

  2.times do |i|
    app_name = "rails_sample_#{user}_#{i}"

    %W(/var/www/#{app_name} /var/www/#{app_name}/shared /var/www/#{app_name}/config /var/www/#{app_name}/shared/log).each do |dir|
      directory dir do
        recursive true
        owner user
        group user
      end
    end

    bash "#{app_name}_bundle" do
      code <<EOF
/home/#{user}/.rvm/bin/rvm 2.0.0@default do gem install bundler
/home/#{user}/.rvm/bin/rvm 2.0.0@default do bundle install --jobs 2
EOF
      user user
      group user
      env 'HOME' => "/home/#{user}"
      cwd "/var/www/#{app_name}/current"
      action :nothing
    end

    git "/var/www/#{app_name}/current" do
      user user
      group user
      repository 'https://github.com/MurgaNikolay/rails-base.git'
      revision 'master'
      action :sync
      notifies :run, "bash[#{app_name}_bundle]", :immediately
    end

    test = EyeTest.new
    test_block = ruby_block "run_test_for_#{app_name}" do
      block do
        test.run
      end
      action :nothing
      notifies :restart, "chef_eye_service[eye_#{user}]"
    end


    test.resource = chef_eye_application app_name do
      owner user
      group user
      config do
        working_dir "/var/www/#{app_name}/current"
        process 'unicorn' do
          pid_file 'tmp/pids/unicorn.pid'
          stdall 'log/eye.log'
          start_command "/home/#{user}/.rvm/bin/rvm 2.0.0@default do bundle exec unicorn_rails -D -E development -c config/unicorn.rb"
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
      if i == 0
        provider Chef::Provider::ChefEyeApplicationLocal
        eye_home "/var/www/#{app_name}/shared"
      else
        notifies :restart, "chef_eye_service[eye_#{user}]", :immediately
      end
      notifies :run, test_block
      action :configure
    end
  end
end

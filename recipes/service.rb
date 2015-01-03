#
# Cookbook Name:: chef-eye
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

directory '/etc/eye' do
  owner 'root'
  group 'root'
  action :create
end

#create service per users
EyeCookbook::Utils.services(node).each do |user_name, config|
  service_name = "eye_#{user_name}"
  config_dir = "/etc/eye/#{user_name}"
  log_dir = "/var/log/eye/#{user_name}"
  [config_dir, log_dir].each do |dir|
    directory dir do
      recursive true
      owner user_name
      group user_name
      action :create
    end
  end


  #service config
  template "#{config_dir}/_config.eye" do
    source 'config.eye.erb'
    owner user_name
    group user_name
    mode '0600'
    helpers ::EyeCookbook::ConfigRender::Methods
    variables(
      config: config
    )
  end

  template "/etc/init.d/#{service_name}" do
    source 'init.d.sh.erb'
    owner 'root'
    group 'root'
    mode '0755'

    variables(
      node: node,
      user: user_name,
      service_name: service_name,
      config_dir: config_dir,
      log_file: ::File.join(log_dir, 'eye.log')
    )
  end

  #create service pr user
  service service_name do
    supports :status => true, :restart => true, :start => true, :reload => true
  end
end

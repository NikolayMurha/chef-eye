#
# Cookbook Name:: chef-eye
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'realpath'

directory '/etc/eye' do
  owner 'root'
  group 'root'
  action :create
  mode '755'
end

ChefEyeCookbook::Utils.services(node).each do |user_name, config|
  directory config['config_dir'] do
    recursive true
    owner user_name
    group user_name
    action :create
  end

  file config['config']['logger'] do
    owner user_name
    group user_name
    action :create
  end

  # main config
  eye_file = chef_eye_config config['eye_file'] do
    cookbook config['cookbook'] || 'chef_eye'
    owner user_name
    group user_name
    config config['config']
    config_dir config['config_dir']
  end

  chef_eye_service config['service_name']do
    owner user_name
    group user_name
    eye_file config['eye_file']
    service_provider config.delete('service_provider') || 'upstart'
    cookbook config['cookbook'] || 'chef_eye'
    subscribes :reload, eye_file
  end

end

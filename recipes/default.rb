#
# Cookbook Name:: chef-eye
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute


include_recipe 'chef_eye::ruby'
user 'ubuntu' do
  home '/home/ubuntu'
  supports :manage_home => true
end

include_recipe 'chef_eye::service'
include_recipe 'chef_eye::applications'



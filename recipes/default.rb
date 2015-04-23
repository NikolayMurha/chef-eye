#
# Cookbook Name:: chef-eye
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
include_recipe 'chef_eye::ruby'
include_recipe 'chef_eye::eye'
include_recipe 'chef_eye::service'
include_recipe 'chef_eye::applications'

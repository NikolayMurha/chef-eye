gem_package 'eye' do
  version node['chef_eye']['version']
end.run_action(:install)

chef_gem 'eye' do
  version node['chef_eye']['version']
end.run_action(:install)

require 'eye'
require 'eye/utils/mini_active_support'

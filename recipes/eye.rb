include_recipe 'apt'
include_recipe 'build-essential'

gem_package 'eye' do
  version node['chef_eye']['version']
end

eye = chef_gem 'eye' do
  version node['chef_eye']['version']
end

require_eye = ruby_block 'require_eye' do
  block do
    begin
      require 'eye'
      require 'eye/utils/mini_active_support'
    rescue e
      Chef::Log.debug(e.message)
    end
  end
  subscribes :run, eye, :immediately
end
require_eye.run_action(:run)

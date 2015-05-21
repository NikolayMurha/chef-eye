include_recipe 'apt'
include_recipe 'build-essential'

gem_package 'eye' do
  version node['chef_eye']['version']
end

eye = chef_gem 'eye' do
  version node['chef_eye']['version']
end

ruby_block 'require_eye' do
  block do
    begin
      require 'eye'
      require 'eye/utils/mini_active_support'
      ::Eye::Dsl::PureOpts.send(:include, Eye::Logger::ObjectExt)
    rescue e
      Chef::Log.debug(e.message)
    end
  end
  subscribes :run, eye, :immediately
end.run_action(:run)

node['chef_eye']['plugins'].each do |gem, options|
  gem_package gem do
    version options['version'] if options['version']
  end

  plugin = chef_gem gem do
    version options['version'] if options['version']
  end
  # need for config validation
  ruby_block "require_#{gem}" do
    block do
      begin
        Array(options['require']).each {|file| require file}
      rescue e
        Chef::Log.debug(e.message)
      end
    end
    subscribes :run, plugin, :immediately
  end.run_action(:run)
end


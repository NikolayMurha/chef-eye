include_recipe 'apt'
include_recipe 'build-essential'


execute 'fix_system_gems_permissions' do
  command 'find /var/lib/gems/ -type f -name \'*.rb\' -exec chmod a+r {} \;'
  only_if 'test -d /var/lib/gems'
end

gem_package 'eye' do
  version node['chef_eye']['version']
  notifies :run, 'execute[fix_system_gems_permissions]'
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
  notifies :run, 'execute[fix_system_gems_permissions]'
end.run_action(:run)

node['chef_eye']['plugins'].each do |gem, options|
  gem_package gem do
    version options['version'] if options['version']
    notifies :run, 'execute[fix_system_gems_permissions]'
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




include_recipe 'chef_eye::service'

node['chef_eye']['applications'].each do |name, options|
  name = options['name'] if options['name']
  type = options['type']
  service_config = ChefEyeCookbook::Utils.services(node)[options['owner']]

  chef_eye_application name do
    provider Chef::Provider::ChefEyeApplicationLocal if type == 'local'
    owner options['owner']
    group options['group'] || 'root'
    cookbook options['cookbook'] || cookbook_name
    config options['config']
    config_dir options['config_dir']
    if type != 'local' && service_config
      notifies :restart, "chef_eye_service[#{service_config['service_name']}]"
    else
      service_provider options['service_provider'] || 'upstart'
      eye_home options['eye_home']
      eye_config options['eye_config']
      eye_file options['eye_file']
    end
  end
end

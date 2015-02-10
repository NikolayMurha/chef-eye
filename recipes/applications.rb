
gem = chef_gem 'eye' do
  version node['chef_eye']['version']
end
gem.run_action(:install)

require 'eye'
require 'eye/utils/mini_active_support'

node['chef_eye']['applications'].each do |name, options|
  options = options.to_hash
  owner = options.delete('owner') || 'root'
  group = options.delete('group')
  type = options.delete('type')
  cookbook = options.delete('cookbook') || 'chef_eye'

  if type == 'local'
    # fetch local params
    eye_home = options.delete('eye_home')
    eye_home = options['working_dir'] unless eye_home
    eye_config = options.delete('eye_config') || {}
    eye_pid = options.delete('eye_pid') || 'pid'
    eye_socket = options.delete('eye_socket') || 'sock'
    config_dir = options.delete('config_dir')

    chef_eye_application_local name do
      owner owner
      group group
      cookbook cookbook
      config options
      config_dir config_dir
      eye_home eye_home
      eye_config eye_config
      eye_pid eye_pid
      eye_socket eye_socket
    end
  else
    chef_eye_application name do
      owner owner
      group group
      cookbook cookbook
      config options
      notifies :reload, "service[eye_#{owner}]"
    end
  end
end

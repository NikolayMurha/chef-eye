require 'pathname'
use_inline_resources

attr_reader :service_resource, :eye_process

def load_current_resource
  validate_resource!
  @service_resource = chef_eye_service "leye_#{new_resource.name}" do
    type 'local'
    service_provider new_resource.service_provider
    owner new_resource.owner
    group new_resource.group
    cookbook new_resource.cookbook
    eye_home new_resource.eye_home_path
    eye_file new_resource.eye_file_path
  end
  @eye_process = ChefEyeCookbook::EyeProcess.form_service_resource(@service_resource)
end

action :configure do
  [new_resource.eye_home_path, config_dir_path].compact.each do |dir|
    directory dir do
      recursive true
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  end

  application_config = "#{::File.join(config_dir_path, new_resource.name)}.eye"
  # Eyefile
  chef_eye_config new_resource.eye_file_path do
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    config eye_config
    # config_dir new_resource.config_dir
    config_files application_config
    plugins new_resource.eye_plugins
    notifies :restart, service_resource
  end

  # Application config
  chef_eye_application_config new_resource.name do
    path application_config
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    config new_resource.config
    notifies :restart, service_resource
  end
end

action :delete do
  run_action(:stop)
  service_resource.run_action(:destroy)

  file "#{::File.join(config_dir_path, new_resource.name)}.eye" do
    action :delete
    only_if "test -f #{::File.join(config_dir_path, new_resource.name)}.eye"
  end

  file "eye_file_#{new_resource.name}" do
    path new_resource.eye_file_path
    action :delete
    only_if "test -f #{new_resource.eye_file_path}"
  end
end

action :start do
  @eye_process.send_command!('start', 'all')
end

action :stop do
  @eye_process.send_command!('stop', 'all')
  @eye_process.wait_stop
end

action :restart do
  @eye_process.send_command!('restart', 'all')
end

def validate_resource!
  raise 'eye_home or absolute path to Eyefile is required for local eye application!' unless new_resource.eye_home || (new_resource.eye_file && Pathname.new(new_resource.eye_file).absolute?)
end

def eye_config
  eye_config = new_resource.eye_config
  eye_config.merge!(
    'logger' => ::File.join(new_resource.eye_home_path, 'log', 'eye.log')
  ) if eye_config.is_a?(Hash) && !eye_config['logger']
  eye_config
end

def config_dir_path
  @config_dir_path ||= new_resource.config_dir || ::File.join(new_resource.eye_home_path, 'config')
end

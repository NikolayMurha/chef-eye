require 'pathname'
use_inline_resources

attr_reader :service_config, :eye_process

def load_current_resource
  @service_config = ChefEyeCookbook::Utils.services(node)[new_resource.owner]
  raise "You must define eye service configuration for application #{new_resource.name}; Read README.md;" unless @service_config
  @eye_process = ChefEyeCookbook::EyeProcess.from_service_config(node, @service_config)
end

action :configure do
  [new_resource.config_dir, @service_config['config_dir']].compact.uniq.each do |dir|
    directory dir do
      recursive true
      owner new_resource.owner
      group new_resource.group
    end
  end

  chef_eye_config config_loader do
    config_dir new_resource.config_dir
    # config_files config_file
  end if config_loader

  chef_eye_application_config new_resource.name do
    path config_file
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    config new_resource.config
  end
end

action :delete do
  run_action(:stop)
  eye_send_command('delete')
  file config_file do
    action :delete
  end

  file config_loader do
    action :delete
  end if config_loader
end

action :start do
  eye_send_command('start')
end

action :stop do
  eye_send_command('stop')
  eye_process.wait_stop(new_resource.name)
end

action :restart do
  eye_send_command('restart')
end

def custom_config_dir?
  new_resource.config_dir && new_resource.config_dir != @service_config['config_dir']
end

def config_file
  if custom_config_dir?
    "#{::File.join(new_resource.config_dir, new_resource.name)}.eye"
  else
    "#{::File.join(@service_config['config_dir'], new_resource.name)}.eye"
  end
end

def config_loader
  return false if !new_resource.config_dir || new_resource.config_dir == @service_config['config_dir']
  "#{::File.join(@service_config['config_dir'], new_resource.name)}.eye"
end

def eye_send_command(command)
  eye_process.send_command(command, new_resource.name) if eye_process.application?(new_resource.name)
end

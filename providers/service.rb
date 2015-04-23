use_inline_resources

attr_reader :eye_process

def load_current_resource
  @eye_process = ChefEyeCookbook::EyeProcess.form_service_resource(new_resource)
  if new_resource.service_provider == 'upstart'
    config = "/etc/init/#{new_resource.service_name}.conf"
    source = 'upstart.erb'
  else
    config = "/etc/init.d/#{new_resource.service_name}"
    source = 'init.d.bash.erb'
  end

  @template = template config do
    action :nothing
    source source
    cookbook new_resource.cookbook.to_s
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      service_name: new_resource.service_name,
      eye_process: eye_process
    )
  end

  @current_resource = service new_resource.service_name do
    provider Chef::Provider::Service::Upstart if new_resource.service_provider == 'upstart'
    supports start: true, restart: true, reload: true
  end
end

action :create do
  @template.run_action(:create)
end

action :destroy do
  @current_resource.run_action(:stop)
  @template.run_action(:delete)
end

action :start do
  update_template
  @current_resource.run_action(:start)
end

action :stop do
  @current_resource.run_action(:stop)
end

action :restart do
  update_template
  @current_resource.run_action(:restart)
end

action :reload do
  run_action(:restart)
end

action :stop_all do
  @eye_process.send_command!('stop', 'all')
end

action :start_all do
  @eye_process.send_command!('start', 'all')
end

action :restart_all do
  @eye_process.send_command!('restart', 'all')
end

def update_template
  return if @template_updated
  @template.run_action(:create)
  @template_updated = true
end

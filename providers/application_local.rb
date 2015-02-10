
require 'pathname'
use_inline_resources

action :configure do
  log_file = new_resource.eye_config.config[:logger] ? new_resource.eye_config.config[:logger].first : 'eye.log'
  log_file = Pathname.new(log_file)
  log_file = ::File.join(new_resource.eye_home, log_file) if log_file.relative?

  log_dir = ::File.dirname(log_file)
  eye_file = ::File.join(new_resource.eye_home, new_resource.eye_file)
  config_dir = new_resource.config_dir || new_resource.eye_home
  eye_bin = ::File.join(new_resource.eye_home, 'leye')

  [new_resource.eye_home, log_dir].each do |dir|
    directory dir do
      recursive true
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  end

  # Service configuration
  template eye_file do
    source 'config.eye.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0600'
    helpers ::EyeCookbook::ConfigRender::Methods
    variables(
      name: new_resource.name,
      config: new_resource.eye_config.config
    )
    notifies :reload, service_resource
  end

  chef_eye_application_config new_resource.name do
    owner new_resource.owner
    group new_resource.group
    config new_resource.config
    config_dir config_dir
    notifies :reload, service_resource
  end

  # leye wrapper
  template eye_bin do
    source 'leye.bash.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0744'
    variables(
      eye_bin: node['chef_eye']['leye_bin'],
      eye_home: new_resource.eye_home,
      eye_pid: new_resource.eye_pid,
      eye_socket: new_resource.eye_socket,
      eye_file: eye_file
    )
  end

  # leye helper
  helper_file = ::File.join('/usr/local/sbin', "leye_#{new_resource.name}")
  template helper_file do
    source 'helper.bash.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0744'
    variables(
      config_dir: config_dir,
      # application_name: new_resource.name,
      user: new_resource.owner,
      eye_bin: eye_bin,
      log_file: log_file
    )
  end

  # Service
  template "/etc/init.d/#{service_name}" do
    source 'init.d.bash.erb'
    cookbook new_resource.cookbook
    owner 'root'
    group 'root'
    mode '0755'
    variables(
      service_name: service_name,
      eye_bin: eye_bin,
      config_dir: config_dir,
      user: new_resource.owner,
      group: new_resource.group,
      name: new_resource.name,
      log_file: log_file
    )
    notifies :enable, service_resource
  end
end

action :restart do
  service_resource.run_action(:restart)
end

action :stop do
  service_resource.run_action(:stop)
end

action :start do
  service_resource.run_action(:start)
end

action :reload do
  service_resource.run_action(:reload)
end

action :delete do
  service_name = "leye_#{new_resource.name}"
  helper_name = "#{new_resource.helper_prefix || 'leye'}_#{new_resource.name}"
  service_resource.run_action(:disable)

  file "/etc/init.d/#{service_name}" do
    action :delete
  end

  file "/usr/local/sbin/#{helper_name}" do
    action :delete
  end
end

def service_name
  "leye_#{new_resource.name}"
end

def service_resource
  @service_resource ||= service service_name do
    supports status: true, restart: true, start: true, reload: true
    action :nothing
  end
end

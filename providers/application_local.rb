
require 'pathname'
use_inline_resources

action :configure do
  log_file = Pathname.new(new_resource.log_file || "/var/log/eye/#{new_resource.owner}/eye.log")
  log_file = ::File.join(new_resource.eye_home, log_file) if log_file.relative?
  log_dir = ::File.dirname(log_file)
  eye_file = ::File.join(new_resource.eye_home, new_resource.eye_file)
  eye_bin = ::File.join(new_resource.eye_home, 'leye')

  [ new_resource.eye_home, log_dir ].each do |dir|
    directory dir do
      recursive true
      owner new_resource.owner
      group new_resource.group
      action :create
    end
  end

  # Main configuration
  template eye_file do
    source 'eyefile.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0600'
    helpers ::EyeCookbook::ConfigRender::Methods
    variables(
      name: new_resource.name,
      application_config: new_resource.config.config,
      eye_config: new_resource.eye_config.config
    )

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

  link "/usr/local/sbin/leye_#{new_resource.name}" do
    to eye_bin
  end

  # Service
  service_name = "leye_#{new_resource.name}"
  template "/etc/init.d/#{service_name}" do
    source 'init.d.local.bash.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(
      service_name: service_name,
      eye_bin: eye_bin,
      eye_file: eye_file,
      user: new_resource.owner,
      group: new_resource.group,
      name: new_resource.name,
      log_file: log_file
    )
  end

  service service_name do
    supports :status => true, :restart => true, :start => true, :reload => true
    action :enable
    subscribes :reload, "template[#{eye_file}]"
  end
end

action :delete do
  service_name = "leye_#{new_resource.name}"
  helper_name = "#{new_resource.helper_prefix || 'leye'}_#{new_resource.name}"
  service service_name do
    action :disable
  end

  file "/etc/init.d/#{service_name}" do
    action :delete
  end

  file "/usr/local/sbin/#{helper_name}" do
    action :delete
  end
end

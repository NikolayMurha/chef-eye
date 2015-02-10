
use_inline_resources

action :configure do
  validate_name
  config_dir = ::File.join('/etc/eye', new_resource.owner)
  chef_eye_application_config new_resource.name do
    owner new_resource.owner
    group new_resource.group
    config_dir config_dir
    config new_resource.config
  end

  if new_resource.helper
    helper_name = "#{new_resource.helper_prefix || new_resource.owner}_#{new_resource.name}"
    template "/usr/local/sbin/#{helper_name}" do
      source 'helper.bash.erb'
      cookbook new_resource.cookbook
      owner new_resource.owner
      group new_resource.group
      mode '0744'
      variables(
        config_dir: config_dir,
        application_name: new_resource.name,
        eye_bin: node['chef_eye']['eye_bin'],
        user: new_resource.owner,
        log_file: ::File.join('/var/log/eye', new_resource.owner, 'eye.log')
      )
    end
  end
end

action :delete do
  validate_name
  file "/etc/eye/#{new_resource.owner}/#{new_resource.name}.eye" do
    action :delete
  end
end

def validate_name
  fail "Name '_config' is reserved and not allowed as application_name!" if new_resource.name == '_config'
end


use_inline_resources

action :configure do
  validate_name
  template "/etc/eye/#{new_resource.owner}/#{new_resource.name}.eye" do
    source 'application.eye.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0600'
    helpers ::EyeCookbook::ConfigRender::Methods
    variables(
      resource: new_resource
    )
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
        user: new_resource.owner,
        application_name: new_resource.name,
        eye_bin: node['eye']['bin']
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
  raise "Name '_config' is reserved and not allowed as application_name!" if new_resource.name == '_config'
end

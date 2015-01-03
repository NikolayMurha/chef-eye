
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

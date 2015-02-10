
use_inline_resources

action :create do
  validate_name
  template new_resource.config_file do
    source 'application.eye.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode '0600'
    helpers ::EyeCookbook::ConfigRender::Methods
    variables(
      name: new_resource.name,
      application_config: new_resource.config.config
    )
  end
end

action :delete do
  validate_name
  file new_resource.config_file do
    action :delete
  end
end

def validate_name
  fail "Name '_config' is reserved and not allowed as application_name!" if new_resource.name == '_config'
end

include ChefEyeCookbook::ConfigProvider

def template_variables
  {
    name: new_resource.name,
    config: new_resource.config.config,
    config_dir: new_resource.config_dir,
    config_files: new_resource.config_files
  }
end

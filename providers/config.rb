include ChefEyeCookbook::ConfigProvider

def template_variables
  plugins = new_resource.plugins.map do |plugin|
    opts = node['chef_eye']['plugins'][plugin]
    raise "Eye Plugin #{plugin} is not found in plugin list. Setup it to default['chef_eye']['plugins']" unless opts
    Array(opts['require'] || plugin)
  end.flatten

  {
    name: new_resource.name,
    config: new_resource.config.config,
    config_dir: new_resource.config_dir,
    config_files: new_resource.config_files,
    plugins: plugins
  }
end

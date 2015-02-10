actions :create, :delete
default_action :create

attribute :config_dir, kind_of: [String]
attribute :owner, kind_of: [String]
attribute :group, kind_of: [String]
attribute :cookbook, kind_of: [String], default: 'chef_eye'


def config_file
  ::File.join(config_dir, "#{name}.eye")
end

# local
def config(config = nil, &block)
  opts = nil
  if config
    opts = Eye::Dsl::ApplicationOpts.new(name)
    code = ::EyeCookbook::ConfigRender.render_config(config)
    opts.instance_eval(code)
  elsif block
    opts = Eye::Dsl::ApplicationOpts.new(name)
    opts.instance_eval(&block)
  end

  set_or_return(
    :config,
    opts,
    kind_of: [Object],
    default: Eye::Dsl::ApplicationOpts.new(name)
  )
end

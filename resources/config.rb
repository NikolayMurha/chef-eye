# Main Eye configuration
include ChefEyeCookbook::ConfigResource
default_action :create
attribute :source, kind_of: [String], default: 'config.erb'
attribute :config_dir, kind_of: [String, NilClass], default: nil
attribute :config_files, kind_of: [Array, String, NilClass], default: nil

def config(config = nil, &block)
  opts = nil
  if config.is_a?(Proc)
    block = config
    config = nil
  end

  if config
    opts = ::Eye::Dsl::ConfigOpts.new
    code = ::ChefEyeCookbook::ConfigRender.render_config(config)
    opts.instance_eval(code)
  elsif block
    opts = ::Eye::Dsl::ConfigOpts.new
    opts.instance_eval(&block)
  end

  set_or_return(
    :config,
    opts,
    kind_of: [Object],
    default: ::Eye::Dsl::ConfigOpts.new
  )
end

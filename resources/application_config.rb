include ChefEyeCookbook::ConfigResource

default_action :create
def config(config = nil, &block)
  opts = nil
  if config.is_a?(Proc)
    block = config
    config = nil
  end

  if config
    opts = ::Eye::Dsl::ApplicationOpts.new(name)
    code = ::ChefEyeCookbook::ConfigRender.render_config(config)
    opts.instance_eval(code)
  elsif block
    opts = ::Eye::Dsl::ApplicationOpts.new(name)
    opts.instance_eval(&block)
  end

  set_or_return(
    :config,
    opts,
    kind_of: [Object],
    default: ::Eye::Dsl::ApplicationOpts.new(name)
  )
end

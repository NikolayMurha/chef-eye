actions :configure, :delete
default_action :configure

attribute :owner, :kind_of => [String]
attribute :group, :kind_of => [String]
attribute :cookbook, :kind_of => [String], default: 'chef_eye'
attribute :helper, :kind_of => [TrueClass,FalseClass], default: true
attribute :helper_prefix, :kind_of => [String, NilClass], default: nil

def config(config = nil, &block )
  opts = nil
  if config
    opts = Eye::Dsl::ApplicationOpts.new self.name
    code = ::EyeCookbook::ConfigRender.render_config(config)
    opts.instance_eval(code)
  elsif block
    opts = Eye::Dsl::ApplicationOpts.new self.name
    opts.instance_eval(&block)
  end

  set_or_return(
    :config,
    opts,
    :kind_of => [Object]
  )
end

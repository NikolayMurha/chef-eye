actions :configure, :delete
default_action :configure

attribute :owner, kind_of: [String]
attribute :group, kind_of: [String]
attribute :cookbook, kind_of: [String], default: 'chef_eye'

#local
attribute :log_file, kind_of: [String]
attribute :eye_home, kind_of: [String]
attribute :eye_file, kind_of: [String], default: 'Eyefile'
attribute :eye_pid, kind_of: [String], default: 'pid'
attribute :eye_socket, kind_of: [String], default: 'sock'

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
    kind_of: [Object]
  )
end

def eye_config(config = nil, &block )
  opts = nil
  if config
    opts = Eye::Dsl::ConfigOpts.new
    code = ::EyeCookbook::ConfigRender.render_config(config)
    opts.instance_eval(code)
  elsif block
    opts = Eye::Dsl::ConfigOpts.new
    opts.instance_eval(&block)
  end

  set_or_return(
    :eye_config,
    opts,
    kind_of: [Object]
  )
end



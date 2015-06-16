actions :configure, :delete, :start, :stop, :restart
default_action :configure

attribute :owner, kind_of: [String]
attribute :group, kind_of: [String]
attribute :cookbook, kind_of: [Symbol, String, NilClass], default: :chef_eye
# local
attribute :config_dir, kind_of: [String], default: nil
attribute :service_provider, kind_of: [String], default: node['chef_eye']['service_type']
attribute :eye_home, kind_of: [String]
attribute :eye_file, kind_of: [String], default: 'Eyefile'
attribute :eye_plugins, kind_of: [Array], default: []

def config(config = nil, &block)
  set_or_return(
    :config,
    (config || block),
    kind_of: [Hash, Proc],
    default: {}
  )
end

def eye_config(config = nil, &block)
  set_or_return(
    :eye_config,
    (config || block),
    kind_of: [Hash, Proc],
    default: {}
  )
end

def eye_home_path
  return eye_home unless eye_file
  eye_file_path = Pathname.new(eye_file)
  if !eye_home && eye_file_path.absolute?
    eye_file_path.parent.to_s
  else
    eye_home
  end
end

def eye_file_path
  if eye_home && eye_file && Pathname.new(eye_file).relative?
    ::File.join(eye_home, eye_file)
  else
    eye_file
  end
end

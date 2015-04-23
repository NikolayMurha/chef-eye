default_action :nothing
actions :create, :destroy, :start, :stop, :restart

attribute :service_name, name_attribute: true, kind_of: [String]
attribute :type, kind_of: [String], default: 'user'
attribute :service_provider, kind_of: [String], default: node['chef_eye']['service_type']
attribute :owner, kind_of: [String], default: 'root'
attribute :group, kind_of: [String], default: 'root'
attribute :cookbook, kind_of: [Symbol, String, NilClass], default: nil
attribute :eye_home, kind_of: [String, NilClass], default: nil
attribute :eye_file, kind_of: [String, NilClass], default: nil

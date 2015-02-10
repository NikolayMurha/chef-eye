actions :configure, :delete
default_action :configure

attribute :owner, kind_of: [String]
attribute :group, kind_of: [String]
attribute :cookbook, kind_of: [String], default: 'chef_eye'
attribute :config, kind_of: [Hash], default: {}
attribute :helper, kind_of: [TrueClass, FalseClass], default: true
attribute :helper_prefix, kind_of: [String, NilClass], default: nil

module ChefEyeCookbook
  module ConfigResource
    def self.included(base)
      base.class_eval do
        actions :create, :delete, :touch
        attribute :path, name_attribute: true, kind_of: [String], required: true
        attribute :source, kind_of: [String], default: 'application.eye.erb'
        attribute :owner, kind_of: [String], default: 'root'
        attribute :group, kind_of: [String], default: 'root'
        attribute :mode, kind_of: [String], default: '0644'
        attribute :cookbook, kind_of: [Symbol, String,  NilClass], default: :chef_eye

        def require_eye
          require 'eye'
        end
      end
    end
  end
end

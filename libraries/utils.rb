module EyeCookbook
  module Utils
    class << self
      def services(node)
        services = node['chef_eye']['services']
        services = services.is_a?(Array) ? Hash[services.zip(Array.new(services.size, {}))] : services.to_hash
        node['chef_eye']['applications'].each do |_, options|
          services[options['owner']] ||= {} if options['type'] != 'local'
        end
        services
      end
    end
  end
end
